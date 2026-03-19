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
#include <QProcess>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>

#include <KLocalizedString>

#include "system_update.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QtDebug>

using namespace Qt::Literals::StringLiterals;

SystemUpdate::SystemUpdate(QObject *parent)
    : QObject(parent)
{
    m_console = new Console::Model();
}

void SystemUpdate::runUpdate(QJSValue callback, QJSValue callbackErrors)
{
    if (!callback.isCallable()) {
        qDebug() << "Callback is not callable, command run refused";
        return;
    }

    if (!Utils::isServicePresent(u"uupd-manual.service"_s)) {
        setBlockUpdate(true);
        m_console->newLine(i18n("The uupd-manual.service used for this application was not found on the system."), Console::LogLevel::ErrorCritical);
        setStatusText(i18n("ERROR!"));
        callback.call({127});
        return;
    }

    m_appState->setUpdateRunning(true);
    SystemUpdate::setStatusText(i18n("Running (This may take a while!)"));

    QProcess *systemctl = new QProcess(this);
    Utils::startProcess(systemctl, u"systemctl"_s, {u"start"_s, u"uupd-manual.service"_s});

    // display progress of systemctl to in-GUI console
    logToConsole();

    // When the "systemctl start uupd-manual.service" process completes,
    // check the service result and update the UI accordingly.
    // NOTE: A race condition can likely occur between this and the process in logToConsole()
    connect(systemctl, &QProcess::finished, [=]() {
        QTimer::singleShot(500, this, [=]() {
            if (m_updateErrorStatus.System_Update || m_updateErrorStatus.Brew_Update || m_updateErrorStatus.System_Apps || m_updateErrorStatus.Apps_for_User
                || m_updateErrorStatus.Distroboxes_for_User || m_updateErrorStatus.Unknown_Error) {
                // Used in QML to send notification of which part(s) of the update failed

                QJsonObject errorDetails;
                errorDetails[u"System_Update"_s] = m_updateErrorStatus.System_Update;
                errorDetails[u"Brew_Update"_s] = m_updateErrorStatus.Brew_Update;
                errorDetails[u"System_Apps"_s] = m_updateErrorStatus.System_Apps;
                errorDetails[u"Apps_for_User"_s] = m_updateErrorStatus.Apps_for_User;
                errorDetails[u"Distroboxes_for_User"_s] = m_updateErrorStatus.Distroboxes_for_User;
                errorDetails[u"Unknown_Error"_s] = m_updateErrorStatus.Unknown_Error;

                QJsonDocument errorDoc(errorDetails);
                QString errorJson = QString::fromUtf8(errorDoc.toJson(QJsonDocument::Compact));

                if (callbackErrors.isCallable()) {
                    callbackErrors.call({errorJson});
                }
            }

            const QString result = getServiceResult(u"uupd-manual.service"_s);
            if (result == u"success"_s) {
                m_appState->setUpdateRunning(false);
                m_appState->setCommandSucceeded(true);

                setStatusText(i18n("Complete"));
                callback.call({0, result});
                systemctl->deleteLater();
                return;
            } else if (result == u"start-limit-hit"_s) {
                setStatusText(i18n("Updating too fast! ") + result);
                m_console->newLine(i18n("You are updating too many times in a short period!"), Console::LogLevel::Error);
            } else {
                setStatusText(i18n("Error: ") + result);
                qDebug() << "Result of uupd-manual.service was not success: " << result;
            }
            m_appState->setUpdateRunning(false);
            callback.call({1, result});

            systemctl->deleteLater();
            return;
        });
    });
}

void SystemUpdate::logToConsole()
{
    // Journalctl only needs to be running once
    if (m_journalctlProcess.state() == QProcess::Running)
        return;

    Utils::startProcess(&m_journalctlProcess, u"journalctl"_s, {u"--follow"_s, u"--unit=uupd-manual.service"_s, u"--lines=0"_s, u"-o"_s, u"json"_s});

    connect(&m_journalctlProcess, &QProcess::readyReadStandardOutput, [this]() {
        while (m_journalctlProcess.canReadLine()) {
            const QByteArray rawLine = m_journalctlProcess.readLine();

            // Parse the Journald Wrapper
            QJsonDocument journalDoc = QJsonDocument::fromJson(rawLine);
            if (!journalDoc.isObject())
                continue;

            QJsonObject journalObj = journalDoc.object();

            QString message = journalObj.value(u"MESSAGE"_s).toString();

            // read the output
            if (!message.trimmed().startsWith(QLatin1Char('{'))) {
                // handle strings like "Starting uupd-manual.service - Universal Blue Update Oneshot Service..."
                m_console->newLine(message, Console::LogLevel::Info);
            } else {
                // handle json strings
                QJsonDocument sysDoc = QJsonDocument::fromJson(message.toUtf8());
                if (!sysDoc.isObject())
                    return;

                QJsonObject obj = sysDoc.object();
                QString level = obj.value(u"level"_s).toString();
                QString msg = obj.value(u"msg"_s).toString();
                QString formattedLine;

                qDebug().noquote() << msg;

                // WARN by default in case the level wasn't accounted for
                Console::LogLevel log_level = Console::LogLevel::Warn;

                if (level == u"DEBUG"_s)
                    log_level = Console::LogLevel::Debug;
                else if (level == u"INFO"_s) {
                    log_level = Console::LogLevel::Info;
                    setProgressLevel(obj.value(u"overall"_s).toInt());
                } else if (level == u"WARN"_s)
                    log_level = Console::LogLevel::Warn;
                else if (level == u"ERROR"_s) {
                    log_level = Console::LogLevel::Error;

                    setStatusText(i18n(("ERROR!")));

                    if (msg == u"module_fail"_s) {
                        QJsonObject output = obj.value(u"output"_s).toObject();
                        QString context = output.value(u"Context"_s).toString();
                        msg = i18n("Module Failed: ") + context;

                        if (context.contains(u"System Update"_s, Qt::CaseInsensitive)) {
                            setBlockUpdate(true);
                            log_level = Console::LogLevel::ErrorCritical;
                            setStatusText(i18n(("CRITICAL ERROR!")));
                            m_updateErrorStatus.System_Update = true;
                        } else if (context.contains(u"Brew Update"_s, Qt::CaseInsensitive)) {
                            m_updateErrorStatus.Brew_Update = true;
                        } else if (context.contains(u"System Apps"_s, Qt::CaseInsensitive)) {
                            m_updateErrorStatus.System_Apps = true;
                        } else if (context.contains(u"Apps for User"_s, Qt::CaseInsensitive)) {
                            m_updateErrorStatus.Apps_for_User = true;
                        } else if (context.contains(u"Distroboxes for User"_s, Qt::CaseInsensitive)) {
                            m_updateErrorStatus.Distroboxes_for_User = true;
                        } else {
                            m_updateErrorStatus.Unknown_Error = true;
                        }
                    }
                }

                { // Remove ANSI color codes from msg (e.g. [0m[1;31m)
                    static QRegularExpression ansiEscapePattern(QStringLiteral(R"(\x1b\[[0-9;]*m)"));
                    msg.replace(ansiEscapePattern, u""_s);
                }

                if (!msg.isEmpty()) {
                    m_console->newLine(msg, log_level);
                }
            }
        }
    });
}

QString SystemUpdate::getServiceState(const QString &service) const
{
    QProcess process;
    Utils::startProcess(process, u"systemctl"_s, {u"is-active"_s, service});
    process.waitForFinished();
    QString state = QString::fromUtf8(process.readAllStandardOutput()).trimmed();

    return state;
}

// Return the result of systemctl show {service} -p Result --value.
// For example, may return "start-limit-hit" or "success"
QString SystemUpdate::getServiceResult(const QString &service) const
{
    QProcess check;
    Utils::startProcess(check, u"systemctl"_s, {u"show"_s, service, u"-p"_s, u"Result"_s, u"--value"_s});

    check.waitForFinished();

    const QString output = QString::fromUtf8(check.readAllStandardOutput()).trimmed();

    return output;
}

void SystemUpdate::copyToClipboard() const
{
    QString plainText;

    for (QObject *line : m_console->lines) {
        Console::Entry *entry = qobject_cast<Console::Entry *>(line);

        plainText += entry->m_content + u"\n"_s;
    }

    if (!plainText.isEmpty())
        QApplication::clipboard()->setText(plainText);
}

void SystemUpdate::setProgressLevel(int progressLevel)
{
    m_progressLevel = progressLevel;
    Q_EMIT progressLevelChanged();
}

void SystemUpdate::setStatusText(const QString &statusText)
{
    m_statusText = statusText;
    Q_EMIT statusTextChanged();
}

void SystemUpdate::setBlockUpdate(bool updateError)
{
    m_blockUpdate = updateError;
    Q_EMIT blockUpdateChanged();
}

void SystemUpdate::setAppState(AppState *appState)
{
    m_appState = appState;
}

#include "moc_system_update.cpp"
