/*
 *  SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
 *  SPDX-FileCopyrightText: 2022 Nate Graham <nate@kde.org>
 *  SPDX-FileCopyrightText: 2024 Oliver Beard <olib141@outlook.com>
 *  SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include <QApplication>
#include <QClipboard>
#include <QFile>
#include <QFileInfo>
#include <QIODevice>
#include <QProcess>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>

#include <KLocalizedString>

#include "console.h"
#include "k_config.h"
#include "system_update.h"
#include "update_steps_model.h"
#include "utils.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QtDebug>
#include <qcontainerfwd.h>
#include <qfuture.h>
#include <qjsondocument.h>
#include <qjsvalue.h>
#include <qlogging.h>
#include <qnumeric.h>
#include <qobject.h>
#include <qprocess.h>
#include <qstringview.h>

using namespace Qt::Literals::StringLiterals;

SystemUpdateBackend::SystemUpdateBackend(QObject *parent)
    : QObject(parent)
{
    m_console = new Console::Model(this);
    m_updateStepsModel = new UpdateStepsNS::Model(this);
}

void SystemUpdateBackend::runUpdate(QJSValue callback = QJSValue(), QJSValue messageCallback = QJSValue())
{
    m_updateStepsModel->clearData();

    // parse the console output to determine if the update has failed, always initialize to false
    static bool moduleFail;
    moduleFail = false;

    auto onFinish = [=, this](int exit_code) {
        const auto conclude = [=](int code, bool command) {
            callback.call({code});
            appState.setUpdateRunning(false);
            appState.setCommandSucceeded(command);
            return;
        };

        // Ensure modules are not left as "running", an exit status of error will not be overwritten
        m_updateStepsModel->setAllRunningExitStatus(UpdateStepsNS::ExitStatus::SUCCESS);

        // Check for errors
        if (exit_code != 0 || moduleFail == true) {
            conclude(1, false);
            qWarning() << "Update failed with exit code " << exit_code;
            m_console->newLine(u"The update has failed. Read the above output for more details."_s, Console::LogLevel::Error);
            return;
        }
        conclude(0, true);
    };

    auto onError = [=, this](QProcess::ProcessError error) {
        qWarning() << "Update errored with ProcessError " << error;
        m_updateStepsModel->setAllRunningExitStatus(UpdateStepsNS::ExitStatus::ERROR);
        callback.call({1});
        appState.setUpdateRunning(false);
        appState.setCommandSucceeded(false);
    };

    auto parser = [=, this](QString line, Console::LogLevel lvl) {
        if (line.isEmpty())
            return;

        if (!line.startsWith(u'{')) {
            auto out = formatForConsole(line);
            if (!out.trimmed().isEmpty())
                m_console->newLine(out.trimmed(), lvl);
            return;
        }

        auto json = QJsonDocument::fromJson(line.toUtf8()).object();

        if (!(json.contains(u"level"_s) && json.contains(u"msg"_s) && json.contains(u"module"_s)))
            return;

        QString level = json.value(u"level"_s).toString();
        QString msg = json.value(u"msg"_s).toString();
        QString module = json.value(u"module"_s).toString();
        QString output = json.value(u"output"_s).toString();

        QString consoleOutput = (output.isEmpty()) ? msg : output;

        // Parse the exit code
        UpdateStepsNS::ExitStatus status = UpdateStepsNS::ExitStatus::NO_CHANGE;
        if (const QJsonValue exitVal = json.value(u"exit_code"_s); exitVal.isDouble())
            status = exitVal.toInt() == 0 ? UpdateStepsNS::ExitStatus::SUCCESS : UpdateStepsNS::ExitStatus::ERROR;

        if (module == u"system"_s) {
            if (output.contains(u"Insufficient free space"_s) || output.contains(u"min-free-space-percent"_s)) {
                messageCallback.call({i18n("There is not enough free space available for system updates.")});
                m_updateStepsModel->updateData(module, -2, -2, UpdateStepsNS::ExitStatus::NO_CHANGE, false);
            }
        }

        {
            int progress_current = UpdateStepsNS::ProgressNoChange;
            int progress_total = UpdateStepsNS::ProgressNoChange;

            static const QRegularExpression regex(QStringLiteral(R"(\[(\d+)/(\d+)\])"));
            auto match = regex.match(output);
            if (match.hasMatch()) {
                progress_current = match.captured(1).toInt();
                progress_total = match.captured(2).toInt();
            }
            m_updateStepsModel->updateData(module, progress_current, progress_total, status);
        }

        using namespace Console;
        LogLevel log_level = LogLevel::Warn;

        if (level == u"INFO"_s)
            log_level = LogLevel::Info;
        else if (level == u"DEBUG"_s)
            log_level = LogLevel::Debug;
        else if (level == u"WARN"_s)
            log_level = LogLevel::Warn;
        else if (level == u"ERROR"_s)
            log_level = LogLevel::Error;

        if (msg == u"Command output"_s)
            log_level = LogLevel::Debug;

        // don't send output from module_fail, the output is the entire output of the command (very large)
        if (msg == u"module_fail"_s) {
            moduleFail = true;
            return;
        }

        auto out = formatForConsole(consoleOutput);
        if (!out.trimmed().isEmpty())
            m_console->newLine(out, log_level);
    };

    appState.setUpdateRunning(true);
    m_console->runProcess(configIni.getValue(u"Commands"_s, u"systemUpdateCommand"_s).split(u' '), onFinish, onError, parser);
}

void SystemUpdateBackend::setBlockUpdate(bool updateError)
{
    m_blockUpdate = updateError;
    Q_EMIT blockUpdateChanged();
}

QString formatForConsole(const QByteArray &bytes)
{
    return formatForConsole(QString::fromUtf8(bytes));
}

QString formatForConsole(QString line)
{
    // TODO: lots of this is uupd-specific, but shouldn't break other update commands

    { // Do not send specific unhelpful lines that get spammed a lot
        const QStringList list = {u"Updating"_s, u"scanned progress"_s};

        for (const auto &spam : list) {
            if (line.trimmed() == spam)
                return u""_s;
        }
    }

    { // Remove ANSI escape patterns
        static QRegularExpression ansiEscapePattern(QStringLiteral(R"(\x1b\[[0-9;]*m)"));
        line.replace(ansiEscapePattern, u""_s);
    }

    return line;
}

#include "moc_system_update.cpp"
