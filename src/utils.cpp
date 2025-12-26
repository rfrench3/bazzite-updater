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
    systemctl->start(QStringLiteral("systemctl"), {QStringLiteral("start"), QStringLiteral("uupd.service")});

    QProcess *journalctl = new QProcess(this);
    journalctl->start(QStringLiteral("journalctl"), {QStringLiteral("--follow"), QStringLiteral("--unit=uupd.service"), QStringLiteral("--lines=0")});

    Utils::setProgressLevel(0);

    // Get line-by-line output in real time, useful for updating progress bar
    connect(journalctl, &QProcess::readyReadStandardOutput, [journalctl, this]() {
        journalctl->deleteLater();

        while (journalctl->canReadLine()) {
            const QString rawLine = QString::fromUtf8(journalctl->readLine());

            int jsonStart = rawLine.toUtf8().indexOf('{');

            // If we found a '{', assume the rest of the line is JSON
            if (jsonStart != -1) {
                QByteArray jsonData = rawLine.mid(jsonStart).toUtf8();
                QJsonDocument doc = QJsonDocument::fromJson(jsonData);

                if (doc.isObject()) {
                    QJsonObject obj = doc.object();
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
                } else {
                    qDebug() << "DEBUG: QJsonDocument doc = QJsonDocument::fromJson(jsonData); resulted in doc.isObject() == False"
                             << "Falling back to standard output...";
                }
            }

            // Example of what this is doing:
            // Dec 23 17:33:36 computername systemd[1]: uupd.service: Deactivated successfully.
            //    ->   uupd.service: Deactivated successfully.
            int standardStart = rawLine.toUtf8().indexOf("]: ") + 3; // + 3 to start at the actual message
            QString standardData = rawLine.mid(standardStart);

            Utils::appendConsoleText(standardData);
            if (standardData.contains(QStringLiteral("Finished uupd.service")) == true)
                Utils::setUpdateRunning(false);
        }
    });

    // Check the exit code of systemctl start uupd.service
    // TODO: I am unsure how to use the exit code of the service itself, this should be looked at further
    connect(systemctl, &QProcess::finished, [=](int exitCode, QProcess::ExitStatus exitStatus) {
        systemctl->deleteLater();

        const QString stdout = QString::fromUtf8(systemctl->readAllStandardOutput().trimmed());

        // Successful exit (not successful update)
        if (exitCode == 0 && exitStatus == QProcess::NormalExit) {
            return;
        }

        Utils::setProgressLevel(0);
        // Failure
        QString intermediateText = QString::fromUtf8(systemctl->readAllStandardError().trimmed());
        if (intermediateText.isEmpty()) {
            intermediateText = stdout;
            if (intermediateText.isEmpty()) {
                intermediateText = i18nc("@info:progress", "No error message provided");
            }
        }
        const QString finalOutputText = xi18nc("@info:progress %1 is the command being run, and %2 is the human-readable error text returned by the command",
                                               "The command <command>%1</command> failed: %2",
                                               QStringLiteral("systemctl start uupd.service"),
                                               intermediateText);

        qWarning() << "The command systemctl start uupd.service failed:" << intermediateText;
        qWarning() << finalOutputText;
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

    check_process.start(QStringLiteral("systemctl"), {QStringLiteral("list-unit-files"), QStringLiteral("--no-legend"), QStringLiteral("--no-pager"), service});

    check_process.waitForFinished();

    const QByteArray output = check_process.readAllStandardOutput().trimmed();

    return !output.isEmpty();
}

QString Utils::getServiceState(const QString &service) const
{
    QProcess process;

    // We do NOT use "--quiet" because we want the text output
    process.start(QStringLiteral("systemctl"), {QStringLiteral("is-active"), service});

    process.waitForFinished();

    // Read the output (e.g., "active\n", "failed\n", "activating\n")
    QString state = QString::fromUtf8(process.readAllStandardOutput()).trimmed();

    return state;
}

void Utils::copyToClipboard(const QString &content) const
{
    QApplication::clipboard()->setText(content);
}

QString Utils::consoleText() const
{
    return m_consoleText;
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

int Utils::progressLevel() const
{
    return m_progressLevel;
}

void Utils::setProgressLevel(int progressLevel)
{
    m_progressLevel = progressLevel;
    Q_EMIT progressLevelChanged();
}

QString Utils::statusText() const
{
    return m_statusText;
}

void Utils::setStatusText(const QString &statusText)
{
    m_statusText = statusText;
    Q_EMIT statusTextChanged();
}

bool Utils::blockUpdate() const
{
    return m_blockUpdate;
}

void Utils::setBlockUpdate(bool updateError)
{
    m_blockUpdate = updateError;
    Q_EMIT blockUpdateChanged();
}

bool Utils::updateRunning() const
{
    return m_updateRunning;
}

void Utils::setUpdateRunning(bool updateRunning)
{
    m_updateRunning = updateRunning;
}

#include "moc_utils.cpp"
