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

#ifdef TESTING_BUILD
#include <algorithm>
#endif

using namespace Qt::Literals::StringLiterals;

// Returns a lambda that logs the update output into the in-app console
auto SystemUpdateBackend::makeLogger(QProcess *updater, UpdateCommand command_data)
{
    QProcess *program = (command_data.type == UpdateCommand::SYSTEMD) ? &m_journalctlProcess : updater;

    return [=]() {
        while (program->canReadLine()) {
            const QByteArray line = program->readLine();

            if (line.isEmpty())
                continue;

            if (!line.startsWith(u'{')) {
                auto out = formatForConsole(line);
                if (!out.trimmed().isEmpty())
                    m_console->newLine(out.trimmed(), Console::LogLevel::Info);
                continue;
            }

            auto json = QJsonDocument::fromJson(line).object();

            if (json.contains(u"level"_s) && json.contains(u"msg"_s)) {
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
                    m_console->newLine(out.trimmed(), log_level);
            }
        }
    };
}

SystemUpdateBackend::SystemUpdateBackend(QObject *parent)
    : QObject(parent)
{
    m_console = new Console::Model(this);

#ifdef TESTING_BUILD
    connect(&m_testConsoleTimer, &QTimer::timeout, this, [this]() {
        m_console->newLine(i18n("Test console line %1", ++m_testConsoleLineCounter), Console::LogLevel::Debug);
    });
#endif
}

void SystemUpdateBackend::runUpdate(QJSValue callback = QJSValue())
{
    if (!callback.isCallable()) {
        qDebug() << "Callback is not callable, command run refused";
        return;
    }

    auto command_data = UpdateCommand(configIni.getValue(u"Commands"_s, u"systemUpdateCommand"_s).split(u' '));

    QProcess *updater = new QProcess(this);

#ifdef TESTING_BUILD
    qInfo() << "TESTING_BUILD: Skipping check for program";
    qInfo() << "TESTING_BUILD: Program is " << command_data.base << command_data.args;
    m_console->newLine(u"Skipping program check"_s, Console::LogLevel::Info);
#else
    if (command_data.type == command_data.SYSTEMD) {
        if (!Utils::isServicePresent(command_data.service)) {
            setBlockUpdate(true);
            m_console->newLine(i18n("The service \"%1\" used for this application was not found on the system.", command_data.service),
                               Console::LogLevel::ErrorCritical);
            callback.call({127});

            return;
        }
    } else {
        if (!Utils::isProgramPresent(command_data.base)) {
            setBlockUpdate(true);
            m_console->newLine(i18n("The program \"%1\" used for this application was not found on the system.").arg(command_data.base),
                               Console::LogLevel::ErrorCritical);
            callback.call({127});
            return;
        }
    }
#endif

    updater->setProcessChannelMode(QProcess::MergedChannels);

    const auto logger = makeLogger(updater, command_data);

    if (command_data.type == UpdateCommand::SYSTEMD) {
        connect(&m_journalctlProcess, &QProcess::readyReadStandardOutput, this, logger);
#ifdef TESTING_BUILD
        qInfo() << "TESTING_BUILD: Using example output text instead of real logging";
        Utils::startProcess(&m_journalctlProcess, u"/workspaces/bazzite-updater/tests/update.sh"_s, {});
#else
        Utils::startProcess(&m_journalctlProcess, u"journalctl"_s, {u"--follow"_s, u"--unit=%1"_s.arg(service), u"--lines=0"_s, u"-o"_s, u"cat"_s});
#endif
    } else {
        connect(updater, &QProcess::readyReadStandardOutput, this, logger);
    }

    connect(updater, &QProcess::finished, [=]() {
        const auto conclude = [=](int code, bool command) {
            callback.call({code});
            appState()->setUpdateRunning(false);
            appState()->setCommandSucceeded(command);
            return;
        };

        // Check for errors
        if (updater->exitStatus() != QProcess::ExitStatus::NormalExit || updater->exitCode() != 0) {
            conclude(1, false);
            qWarning() << "Update failed with exit code " << updater->exitCode();
            return;
        }

        if (command_data.type == UpdateCommand::SYSTEMD) {
            const QString result = getServiceResult(command_data.service);

            if (result != u"success"_s) {
                conclude(1, false);
                qWarning() << "Update failed with exit code " << updater->exitCode() << " and exit status " << result;
                return;
            }
        }

        conclude(0, true);
    });

    appState()->setUpdateRunning(true);

#ifdef TESTING_BUILD
    // Utils::startProcess(updater, u"sleep"_s, {u"3"_s});
    Utils::startProcess(updater, u"/workspaces/bazzite-updater/tests/update.sh"_s, {});
#else
    Utils::startProcess(updater, command_data.base, command_data.args);
#endif
}

QString SystemUpdateBackend::getServiceState(const QString &service) const
{
    QProcess process;
    Utils::startProcess(process, u"systemctl"_s, {u"is-active"_s, service});
    process.waitForFinished();
    QString state = QString::fromUtf8(process.readAllStandardOutput()).trimmed();

    return state;
}

// Return the result of systemctl show {service} -p Result --value.
// For example, may return "start-limit-hit" or "success"
QString SystemUpdateBackend::getServiceResult(const QString &service) const
{
    QProcess check;
    Utils::startProcess(check, u"systemctl"_s, {u"show"_s, service, u"-p"_s, u"Result"_s, u"--value"_s});

    check.waitForFinished();

    const QString output = QString::fromUtf8(check.readAllStandardOutput()).trimmed();

    return output;
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

#ifdef TESTING_BUILD
void SystemUpdateBackend::setTestConsoleLinesPerSecond(int linesPerSecond)
{
    if (linesPerSecond < 0) {
        linesPerSecond = 0;
    }

    if (m_testConsoleLinesPerSecond == linesPerSecond) {
        return;
    }

    m_testConsoleLinesPerSecond = linesPerSecond;

    if (m_testConsoleLinesPerSecond == 0) {
        m_testConsoleTimer.stop();
    } else {
        const int intervalMs = std::max(1, 1000 / m_testConsoleLinesPerSecond);
        m_testConsoleTimer.start(intervalMs);
    }

    Q_EMIT testConsoleLinesPerSecondChanged();
}
#endif

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

UpdateCommand::UpdateCommand(QStringList command)
{
    base = command[0];
    command.removeFirst();
    args = command;

    if (base == u"systemctl"_s) {
        type = SYSTEMD;

        // systemctl, { start, the.service }
        service = args[1];
    } else {
        type = COMMAND;
    }
}
#include "moc_system_update.cpp"
