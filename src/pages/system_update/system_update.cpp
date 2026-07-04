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
}

void SystemUpdateBackend::runUpdate(QJSValue callback = QJSValue())
{
    if (!callback.isCallable()) {
        qDebug() << "Callback is not callable, command run refused";
        return;
    }

    auto onFinish = [=](int exit_code) {
        const auto conclude = [=](int code, bool command) {
            callback.call({code});
            appState()->setUpdateRunning(false);
            appState()->setCommandSucceeded(command);
            return;
        };

        // Check for errors
        if (exit_code != 0) {
            conclude(1, false);
            qWarning() << "Update failed with exit code " << exit_code;
            m_console->newLine(u"The update has failed: exit code %1"_s.arg(exit_code), Console::LogLevel::Error);
            return;
        }

        conclude(0, true);
    };

    auto onError = [=](QProcess::ProcessError error) {
        qWarning() << "Update errored with ProcessError " << error;
        callback.call({1});
        appState()->setUpdateRunning(false);
        appState()->setCommandSucceeded(false);
    };

    auto parser = [=](QString line, Console::LogLevel lvl) {
        if (line.isEmpty())
            return;

        if (!line.startsWith(u'{')) {
            auto out = formatForConsole(line);
            if (!out.trimmed().isEmpty())
                m_console->newLine(out.trimmed(), lvl);
            return;
        }

        auto json = QJsonDocument::fromJson(line.toUtf8()).object();

        if (!(json.contains(u"level"_s) && json.contains(u"msg"_s)))
            return;

        QString level = json.value(u"level"_s).toString();
        QString msg = json.value(u"msg"_s).toString();

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

        auto out = formatForConsole(msg);
        if (!out.trimmed().isEmpty())
            m_console->newLine(out, log_level);
    };

    appState()->setUpdateRunning(true);
    m_console->runProcess(configIni.getValue(u"Commands"_s, u"systemUpdateCommand"_s).split(u' '), onFinish, onError, parser);
}

void SystemUpdateBackend::setProgressLevel(int progressLevel)
{
    m_progressLevel = progressLevel;
    Q_EMIT progressLevelChanged();
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
