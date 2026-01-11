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
    const bool resultHandled = callback.isCallable();
    if (!resultHandled) {
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

    // TODO: if an update is being detected, ideally the app would link to that update and show its progress.
    //       for now, anything but "inactive" will give an error.
    if (!isServiceInactive(u"uupd.service"_s)) {
        QString state = getServiceState(u"uupd.service"_s);

        setConsoleText(i18n("The status of uupd.service is not inactive!"));
        appendConsoleText(i18n("State of uupd.service: ") + state);
        setStatusText(i18n("ERROR!"));
        setBlockUpdate(true);
        setUpdateRunning(true);

        const QString finalOutput = u"uupd.service state: "_s + state;
        callback.call({1, finalOutput});
        return;
    }

    // No update is currently running, proceed

    QProcess *systemctl = new QProcess(this);
    Utils::startProcess(systemctl, u"systemctl"_s, {u"start"_s, u"uupd.service"_s});

    QProcess *journalctl = new QProcess(this);
    Utils::startProcess(journalctl, u"journalctl"_s, {u"--follow"_s, u"--unit=uupd.service"_s, u"--lines=0"_s, u"-o"_s, u"json"_s});

    SystemUpdate::setProgressLevel(0);

    // When the "systemctl start uupd.service" process completes,
    // check the service result and update the UI accordingly.
    connect(systemctl, &QProcess::finished, [=]() {
        journalctl->terminate();

        const QString result = getServiceResult(u"uupd.service"_s);
        if (result == u"success"_s) {
            SystemUpdate::setUpdateRunning(false);
            SystemUpdate::setStatusText(i18n("Success!"));
            callback.call({0, result});
            return;
        } else if (result == u"start-limit-hit"_s) {
            SystemUpdate::setStatusText(i18n("Updating too fast! ") + result);
            SystemUpdate::appendConsoleText(i18n("You are updating too many times in a short period!"));
        } else {
            SystemUpdate::setStatusText(i18n("Error -- ") + result);
            qDebug() << "Result of uupd.service was not success: " << result;
        }
        SystemUpdate::setBlockUpdate(true);
        SystemUpdate::setUpdateRunning(false);
        callback.call({1, result});
        return;
    });

    // Read the messages of uupd.service
    connect(journalctl, &QProcess::readyReadStandardOutput, [journalctl, this]() {
        while (journalctl->canReadLine()) {
            const QByteArray rawLine = journalctl->readLine();

            // Parse the Journald Wrapper
            QJsonDocument journalDoc = QJsonDocument::fromJson(rawLine);
            if (!journalDoc.isObject())
                continue;

            QJsonObject journalObj = journalDoc.object();

            QString message = journalObj.value(u"MESSAGE"_s).toString();

            // read the uupd json output
            if (message.trimmed().startsWith(QLatin1Char('{'))) {
                QJsonDocument sysDoc = QJsonDocument::fromJson(message.toUtf8());
                if (sysDoc.isObject()) {
                    QJsonObject obj = sysDoc.object();
                    QString level = obj.value(u"level"_s).toString();
                    QString msg = obj.value(u"msg"_s).toString();
                    QString overall = obj.value(u"overall"_s).toString();
                    QString error_msg = obj.value(u"error"_s).toString();
                    QString formattedLine;

                    if (!overall.isEmpty()) {
                        // Make sure the progress bar only reaches 100% when the update completes
                        if (overall.toInt() < 95)
                            SystemUpdate::setProgressLevel(overall.toInt());
                        else
                            SystemUpdate::setProgressLevel(95);
                    }

                    if (level == QStringLiteral("INFO")) {
                        formattedLine = msg;
                    } else if (level == QStringLiteral("DEBUG")) {
                        formattedLine = QStringLiteral("DEBUG: ") + msg;
                    } else if (level == QStringLiteral("ERROR")) {
                        // The update has failed

                        SystemUpdate::setStatusText(i18n(("ERROR!")));
                        SystemUpdate::setProgressLevel(0);
                        SystemUpdate::setBlockUpdate(true);
                        formattedLine = QStringLiteral("ERROR: ") + msg;

                        if (!error_msg.isEmpty()) {
                            formattedLine += QStringLiteral(": ") + error_msg;
                        }
                    }

                    if (!formattedLine.isEmpty()) {
                        if (SystemUpdate::consoleText() == DEFAULT_CONSOLE_TEXT)
                            SystemUpdate::setConsoleText(formattedLine);
                        else
                            SystemUpdate::setConsoleText(SystemUpdate::consoleText() + formattedLine);

                        qDebug().noquote() << formattedLine;
                        continue;
                    }

                    continue;
                }
            }

            SystemUpdate::appendConsoleText(message);
        }
    });
}

// Return false unless service is inactive.
bool SystemUpdate::isServiceInactive(const QString &service) const
{
    // Non-zero means it is NOT active (therefore, inactive).
    int exitCode = QProcess::execute(u"systemctl"_s, {u"is-active"_s, u"--quiet"_s, service});

    return exitCode != 0;
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

    // We do NOT use "--quiet" because we want the text output
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
