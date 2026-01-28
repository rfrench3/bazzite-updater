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

void SystemUpdate::runUpdate(QJSValue callback)
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
    connect(systemctl, &QProcess::finished, [=]() {
        const QString result = getServiceResult(u"uupd-manual.service"_s);
        if (result == u"success"_s) {
            m_appState->setUpdateRunning(false);
            m_appState->setCommandSucceeded(true);

            setStatusText(i18n("Success!"));
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
                else if (level == u"INFO"_s)
                    log_level = LogLevel::INFO;
                else if (level == u"WARN"_s)
                    log_level = LogLevel::WARN;
                else if (level == u"ERROR"_s) {
                    log_level = LogLevel::ERROR;

                    setStatusText(i18n(("ERROR!")));

                    if (msg == u"module_fail"_s) {
                        QJsonObject output = obj.value(u"output"_s).toObject();
                        QString context = output.value(u"Context"_s).toString();
                        msg = i18n("Module Failed: ") + context;

                        // TODO: make sure one of these is correct
                        if (context.contains(u"system"_s, Qt::CaseInsensitive) || context.contains(u"ostree"_s, Qt::CaseInsensitive)
                            || context.contains(u"bootc"_s, Qt::CaseInsensitive)) {
                            setBlockUpdate(true);
                            log_level = LogLevel::ERROR_CRITICAL;
                            setStatusText(i18n(("CRITICAL ERROR!")));
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
    QApplication::clipboard()->setText(content);
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
    auto formatBold = [](const QString &text) {
        return u"<b>"_s + text + u"</b>"_s;
    };

    auto formatColorPlaceholder = [this](const QString &text) {
        return u"<font color='"_s + m_placeholderTextColor + u"'>"_s + text + u"</font>"_s;
    };

    QString tempText;
    // display debug lines in placeholder text color
    switch (level) {
    case LogLevel::DEBUG:
        tempText.append(formatColorPlaceholder(u"debug: "_s + consoleText));
        break;
    case LogLevel::INFO:
        tempText.append(consoleText);
        break;
    case LogLevel::WARN:
        tempText.append(formatBold(u"WARNING: "_s + consoleText));
        break;
    case LogLevel::ERROR:
        tempText.append(formatBold(u"ERROR: "_s + consoleText));
        break;
    case LogLevel::ERROR_CRITICAL:
        tempText.append(formatBold(u"CRITICAL ERROR: "_s + consoleText));
        break;
    default:
        // Should never happen
        tempText.append(formatBold(u"UNKNOWN LOG LEVEL: "_s + consoleText));
        break;
    }

    if (m_consoleText == DEFAULT_CONSOLE_TEXT)
        m_consoleText = tempText;
    else
        m_consoleText += tempText;

    if (!m_consoleText.endsWith(u"<br>"_s))
        m_consoleText.append(u"<br>"_s);

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
