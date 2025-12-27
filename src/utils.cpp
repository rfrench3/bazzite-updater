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

#include "utils.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QtDebug>

Utils::Utils(QObject *parent)
    : QObject(parent)
{
}

void Utils::runUpdate(QJSValue callback)
{
    const bool resultHandled = callback.isCallable();
    if (!resultHandled) {
        qDebug() << "Callback is not callable, command run refused";
        return;
    }
    Utils::setUpdateRunning(true);
    Utils::setStatusText(i18n("Running (This may take a while!)"));

    if (!isServicePresent(QStringLiteral("uupd.service"))) {
        setConsoleText(i18n("The uupd service was not found on the system."));
        setStatusText(i18n("ERROR!"));
        setBlockUpdate(true);
        setUpdateRunning(false);

        const QString finalOutput = QStringLiteral("uupd.service was not found");
        callback.call({1, finalOutput});
        return;
    }

    // TODO: if an update is being detected, ideally the app would link to that update and show its progress.
    //       for now, anything but "inactive" will give an error.
    if (!isServiceInactive(QStringLiteral("uupd.service"))) {
        QString state = getServiceState(QStringLiteral("uupd.service"));

        setConsoleText(i18n("The status of uupd.service is not inactive!"));
        appendConsoleText(i18n("State of uupd.service: ") + state);
        setStatusText(i18n("ERROR!"));
        setBlockUpdate(true);
        setUpdateRunning(true);

        const QString finalOutput = QStringLiteral("uupd.service state: ") + state;
        callback.call({1, finalOutput});
        return;
    }

    // No update is currently running, proceed

    QProcess *systemctl = new QProcess(this);
    startProcess(systemctl, QStringLiteral("systemctl"), {QStringLiteral("start"), QStringLiteral("uupd.service")});

    QProcess *journalctl = new QProcess(this);
    startProcess(
        journalctl,
        QStringLiteral("journalctl"),
        {QStringLiteral("--follow"), QStringLiteral("--unit=uupd.service"), QStringLiteral("--lines=0"), QStringLiteral("-o"), QStringLiteral("json")});

    Utils::setProgressLevel(0);

    connect(journalctl, &QProcess::readyReadStandardOutput, [journalctl, this]() {
        while (journalctl->canReadLine()) {
            const QByteArray rawLine = journalctl->readLine();

            // Parse the Journald Wrapper
            QJsonDocument journalDoc = QJsonDocument::fromJson(rawLine);
            if (!journalDoc.isObject())
                continue;

            QJsonObject journalObj = journalDoc.object();

            QString message = journalObj.value(QStringLiteral("MESSAGE")).toString();

            // read the uupd json output
            if (message.trimmed().startsWith(QLatin1Char('{'))) {
                QJsonDocument sysDoc = QJsonDocument::fromJson(message.toUtf8());
                if (sysDoc.isObject()) {
                    QJsonObject obj = sysDoc.object();
                    QString level = obj.value(QStringLiteral("level")).toString();
                    QString msg = obj.value(QStringLiteral("msg")).toString();
                    QString overall = obj.value(QStringLiteral("overall")).toString();
                    QString error_msg = obj.value(QStringLiteral("error")).toString();
                    QString formattedLine;

                    if (!overall.isEmpty()) {
                        // Make sure the progress bar only reaches 100% when the update completes
                        if (overall.toInt() < 95)
                            Utils::setProgressLevel(overall.toInt());
                        else
                            Utils::setProgressLevel(95);
                    }

                    if (level == QStringLiteral("INFO")) {
                        formattedLine = msg;
                    } else if (level == QStringLiteral("DEBUG")) {
                        formattedLine = QStringLiteral("DEBUG: ") + msg;
                    } else if (level == QStringLiteral("ERROR")) {
                        // The update has failed

                        Utils::setStatusText(i18n(("ERROR!")));
                        Utils::setProgressLevel(0);
                        Utils::setBlockUpdate(true);
                        formattedLine = QStringLiteral("ERROR: ") + msg;

                        if (!error_msg.isEmpty()) {
                            formattedLine += QStringLiteral(": ") + error_msg;
                        }
                    }

                    if (!formattedLine.isEmpty()) {
                        if (Utils::consoleText() == DEFAULT_CONSOLE_TEXT)
                            Utils::setConsoleText(formattedLine);
                        else
                            Utils::setConsoleText(Utils::consoleText() + formattedLine);

                        qDebug().noquote() << formattedLine;
                        continue;
                    }

                    continue;
                }
            }

            Utils::appendConsoleText(message);
        }
    });

    // When the "systemctl start uupd.service" process completes,
    // check the service result and update the UI accordingly.
    connect(systemctl, &QProcess::finished, [=]() {
        const QString result = getServiceResult(QStringLiteral("uupd.service"));

        if (result == QStringLiteral("success")) {
            Utils::setUpdateRunning(false);
            Utils::setStatusText(i18n("Success!"));
            callback.call({0, result});
            return;
        } else if (result == QStringLiteral("start-limit-hit")) {
            Utils::setStatusText(i18n("Updating too fast! ") + result);
            Utils::appendConsoleText(i18n("You are updating too many times in a short period!"));
        } else {
            Utils::setStatusText(i18n("Error -- ") + result);
            qDebug() << "Result of uupd.service was not success: " << result;
        }
        Utils::setBlockUpdate(true);
        Utils::setUpdateRunning(false);
        callback.call({1, result});
        return;
    });
}

// Return false unless service is inactive.
bool Utils::isServiceInactive(const QString &service) const
{
    // Non-zero means it is NOT active (therefore, inactive).
    int exitCode = QProcess::execute(QStringLiteral("systemctl"), {QStringLiteral("is-active"), QStringLiteral("--quiet"), service});

    return exitCode != 0;
}

// Return false if the service is not present.
bool Utils::isServicePresent(const QString &service) const
{
    QProcess check_process;

    startProcess(check_process,
                 QStringLiteral("systemctl"),
                 {QStringLiteral("list-unit-files"), QStringLiteral("--no-legend"), QStringLiteral("--no-pager"), service});

    check_process.waitForFinished();

    const QByteArray output = check_process.readAllStandardOutput().trimmed();

    return !output.isEmpty();
}

QString Utils::getServiceState(const QString &service) const
{
    QProcess process;

    // We do NOT use "--quiet" because we want the text output
    // process.start(QStringLiteral("systemctl"), {QStringLiteral("is-active"), service});
    startProcess(process, QStringLiteral("systemctl"), {QStringLiteral("is-active"), service});

    process.waitForFinished();

    // Read the output (e.g., "active\n", "failed\n", "activating\n")
    QString state = QString::fromUtf8(process.readAllStandardOutput()).trimmed();

    return state;
}

// Return the result of systemctl show {service} -p Result --value.
// For example, may return "start-limit-hit" or "success"
QString Utils::getServiceResult(const QString &service) const
{
    QProcess check;
    startProcess(check,
                 QStringLiteral("systemctl"),
                 {QStringLiteral("show"), service, QStringLiteral("-p"), QStringLiteral("Result"), QStringLiteral("--value")});

    check.waitForFinished();

    const QString output = QString::fromUtf8(check.readAllStandardOutput()).trimmed();

    return output;
}

// Handles sandboxing such as Flatpak
void Utils::startProcess(QProcess *process, const QString &cmd, const QStringList &args)
{
    if (isFlatpak()) {
        QStringList hostArgs;
        hostArgs << QStringLiteral("--host") << cmd << args;
        process->start(QStringLiteral("flatpak-spawn"), hostArgs);
    } else {
        process->start(cmd, args);
    }
}

void Utils::startProcess(QProcess &process, const QString &cmd, const QStringList &args)
{
    startProcess(&process, cmd, args);
}

void Utils::copyToClipboard(const QString &content) const
{
    QApplication::clipboard()->setText(content);
}

void Utils::setConsoleText(const QString &consoleText)
{
    m_consoleText = consoleText;

    if (!m_consoleText.endsWith(QLatin1Char('\n')))
        m_consoleText.append(QLatin1Char('\n'));

    Q_EMIT consoleTextChanged();
}

void Utils::appendConsoleText(const QString &consoleText)
{
    if (m_consoleText == DEFAULT_CONSOLE_TEXT)
        m_consoleText = consoleText;
    else
        m_consoleText += consoleText;

    if (!m_consoleText.endsWith(QLatin1Char('\n')))
        m_consoleText.append(QLatin1Char('\n'));

    Q_EMIT consoleTextChanged();
}

void Utils::setProgressLevel(int progressLevel)
{
    m_progressLevel = progressLevel;
    Q_EMIT progressLevelChanged();
}

void Utils::setStatusText(const QString &statusText)
{
    m_statusText = statusText;
    Q_EMIT statusTextChanged();
}

void Utils::setBlockUpdate(bool updateError)
{
    m_blockUpdate = updateError;
    Q_EMIT blockUpdateChanged();
}

void Utils::setUpdateRunning(bool updateRunning)
{
    m_updateRunning = updateRunning;
    Q_EMIT updateRunningChanged();
}

#include "moc_utils.cpp"
