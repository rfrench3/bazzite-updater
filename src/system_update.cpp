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
    SystemUpdate::setUpdateRunning(true);
    SystemUpdate::setStatusText(i18n("Running (This may take a while!)"));

    if (!isServicePresent(u"uupd.service"_s)) {
        setConsoleText(i18n("The uupd service was not found on the system."));
        setStatusText(i18n("ERROR!"));
        setBlockUpdate(true);
        setUpdateRunning(false);

        const QString finalOutput = u"uupd.service was not found"_s;
        callback.call({1, finalOutput});
        return;
    }

    // If uupd.service is already running, use journalctl to display its progress
    if (!isServiceInactive(u"uupd.service"_s)) {
        QString state = getServiceState(u"uupd.service"_s);

        setConsoleText(i18n("uupd.service is not inactive! Linking console to running update..."));
        appendConsoleText(i18n("State of uupd.service: ") + state);
        setStatusText(i18n("Update already running!"));
        setBlockUpdate(true);

        logToConsole();

        const QString finalOutput = u"uupd.service state: "_s + state;
        callback.call({1, finalOutput});
        return;
    }

    // No update is currently running, proceed

    QProcess *systemctl = new QProcess(this);
    Utils::startProcess(systemctl, u"systemctl"_s, {u"start"_s, u"uupd.service"_s});

    // display progress of systemctl to in-GUI console
    logToConsole();

    // When the "systemctl start uupd.service" process completes,
    // check the service result and update the UI accordingly.
    connect(systemctl, &QProcess::finished, [=]() {
        const QString result = getServiceResult(u"uupd.service"_s);
        if (result == u"success"_s) {
            SystemUpdate::setUpdateRunning(false);
            SystemUpdate::setStatusText(i18n("Success!"));
            callback.call({0, result});
            return;
        } else if (result == u"start-limit-hit"_s) {
            setStatusText(i18n("Updating too fast! ") + result);
            appendConsoleText(i18n("You are updating too many times in a short period!"));
        } else {
            setStatusText(i18n("Error -- ") + result);
            qDebug() << "Result of uupd.service was not success: " << result;
        }
        SystemUpdate::setBlockUpdate(true);
        SystemUpdate::setUpdateRunning(false);
        callback.call({1, result});
        return;
    });
}

void SystemUpdate::logToConsole()
{
    // Journalctl only needs to be running once
    if (m_journalctlProcess.state() == QProcess::Running)
        return;

    Utils::startProcess(&m_journalctlProcess, u"journalctl"_s, {u"--follow"_s, u"--unit=uupd.service"_s, u"--lines=0"_s, u"-o"_s, u"json"_s});

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
                // handle strings like "Starting uupd.service - Universal Blue Update Oneshot Service..."
                appendConsoleText(message);
            } else {
                // handle json strings
                QJsonDocument sysDoc = QJsonDocument::fromJson(message.toUtf8());
                if (!sysDoc.isObject())
                    return;

                QJsonObject obj = sysDoc.object();
                QString level = obj.value(u"level"_s).toString();
                QString msg = obj.value(u"msg"_s).toString();
                QString error_msg = obj.value(u"error"_s).toString();
                QString formattedLine;

                if (level == u"INFO"_s) {
                    formattedLine = msg;
                } else if (level == u"DEBUG"_s) {
                    formattedLine = u"debug: "_s + msg;
                } else if (level == u"ERROR"_s) {
                    formattedLine = u"ERROR! "_s + msg;

                    setStatusText(i18n(("ERROR!")));
                    setBlockUpdate(true);

                    if (!error_msg.isEmpty()) {
                        formattedLine += u": "_s + error_msg;
                    }
                }

                if (!formattedLine.isEmpty()) {
                    appendConsoleText(formattedLine);
                    qDebug().noquote() << formattedLine;
                }
            }
        }
    });
}

// Return false unless service is inactive.
// FIXME: Make sure this works
bool SystemUpdate::isServiceInactive(const QString &service) const
{
    QProcess process;
    Utils::startProcess(process, u"systemctl"_s, {u"is-active"_s, u"--quiet"_s, service});
    process.waitForFinished();

    // Non-zero means it is NOT active (therefore, inactive).
    return process.exitCode() != 0;
}

// Return false if the service is not present.
bool SystemUpdate::isServicePresent(const QString &service) const
{
    QProcess check_process;

    Utils::startProcess(check_process, u"systemctl"_s, {u"list-unit-files"_s, u"--no-legend"_s, u"--no-pager"_s, service});

    check_process.waitForFinished();

    const QByteArray output = check_process.readAllStandardOutput().trimmed();

    return !output.isEmpty();
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

    if (!m_consoleText.endsWith(QLatin1Char('\n')))
        m_consoleText.append(QLatin1Char('\n'));

    Q_EMIT consoleTextChanged();
}

void SystemUpdate::appendConsoleText(const QString &consoleText)
{
    if (m_consoleText == DEFAULT_CONSOLE_TEXT)
        m_consoleText = consoleText;
    else
        m_consoleText += consoleText;

    if (!m_consoleText.endsWith(QLatin1Char('\n')))
        m_consoleText.append(QLatin1Char('\n'));

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

void SystemUpdate::setUpdateRunning(bool updateRunning)
{
    m_updateRunning = updateRunning;
    Q_EMIT updateRunningChanged();
}

#include "moc_system_update.cpp"
