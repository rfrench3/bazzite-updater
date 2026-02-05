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
}

void SystemUpdate::runUpdate(QJSValue callback, QJSValue callbackErrors)
{
    if (!callback.isCallable()) {
        qDebug() << "Callback is not callable, command run refused";
        return;
    }
    if (!Utils::isServicePresent(u"uupd-manual.service"_s)) {
        setBlockUpdate(true);
        appendConsoleText(i18n("The uupd manual service was not found on the system."), LogLevel::ERROR_CRITICAL);
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
                appendConsoleText(i18n("You are updating too many times in a short period!"), LogLevel::ERROR);
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
                appendConsoleText(message, LogLevel::INFO);
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
                LogLevel log_level = LogLevel::WARN;

                if (level == u"DEBUG"_s)
                    log_level = LogLevel::DEBUG;
                else if (level == u"INFO"_s) {
                    log_level = LogLevel::INFO;
                    setProgressLevel(obj.value(u"overall"_s).toInt());
                } else if (level == u"WARN"_s)
                    log_level = LogLevel::WARN;
                else if (level == u"ERROR"_s) {
                    log_level = LogLevel::ERROR;

                    setStatusText(i18n(("ERROR!")));

                    if (msg == u"module_fail"_s) {
                        QJsonObject output = obj.value(u"output"_s).toObject();
                        QString context = output.value(u"Context"_s).toString();
                        msg = i18n("Module Failed: ") + context;

                        if (context.contains(u"System Update"_s, Qt::CaseInsensitive)) {
                            setBlockUpdate(true);
                            log_level = LogLevel::ERROR_CRITICAL;
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
                    appendConsoleText(msg, log_level);
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

void SystemUpdate::copyToClipboard(const QString &content) const
{
    // Remove HTML tags
    static QRegularExpression htmlTagPattern(QStringLiteral(R"(<[^>]*>)"));
    QString plainText = content;
    plainText.replace(u"<br>"_s, u"\n"_s);
    plainText.replace(htmlTagPattern, u""_s);

    QApplication::clipboard()->setText(plainText);
}

void SystemUpdate::setConsoleText(const QString &consoleText)
{
    m_consoleText = consoleText;

    if (!m_consoleText.endsWith(u"<br>"_s))
        m_consoleText.append(u"<br>"_s);

    Q_EMIT consoleTextChanged();
}

void SystemUpdate::appendConsoleText(const QString &consoleText, LogLevel level)
{
    // Start with this so that the final line isn't always empty
    if (!m_consoleText.endsWith(u"<br>"_s)) {
        m_consoleText.append(u"<br>"_s);
    }

    auto formatBold = [](const QString &text) {
        return u"<b>"_s + text + u"</b>"_s;
    };

    auto formatColorPlaceholder = [this](const QString &text) {
        return u"<font color='"_s + m_placeholderTextColor + u"'>"_s + text + u"</font>"_s;
    };

    QString newLine;
    QString temp;
    // display debug lines in placeholder text color
    switch (level) {
    case LogLevel::DEBUG:
        temp = u"debug: "_s + consoleText;
        newLine.append(formatColorPlaceholder(temp));
        break;
    case LogLevel::INFO:
        newLine.append(consoleText);
        break;
    case LogLevel::WARN:
        temp = u"WARNING: "_s + consoleText;
        newLine.append(formatBold(temp));
        break;
    case LogLevel::ERROR:
        temp = u"ERROR: "_s + consoleText;
        newLine.append(formatBold(temp));
        break;
    case LogLevel::ERROR_CRITICAL:
        temp = u"CRITICAL ERROR: "_s + consoleText;
        newLine.append(formatBold(temp));
        break;
    default:
        // Should never happen
        temp = u"UNKNOWN LOG LEVEL: "_s + consoleText;
        newLine.append(formatBold(temp));
        break;
    }

    // TODO: handle this with line length checker
    if (m_consoleText == DEFAULT_CONSOLE_TEXT)
        m_consoleText = newLine;
    else
        m_consoleText += newLine;

    Q_EMIT consoleTextChanged();
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

void SystemUpdate::setPlaceholderColor(QString placeholderText)
{
    m_placeholderTextColor = placeholderText;
}

void SystemUpdate::setAppState(AppState *appState)
{
    m_appState = appState;
}

#include "moc_system_update.cpp"
