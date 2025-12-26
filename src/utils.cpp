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
        return;
    }
    Utils::setUpdateRunning(true);
    Utils::setStatusText(i18n("Running (This may take a while!)"));

    // Make sure an update is not already running
    // TODO: if an update is being detected, ideally the app would link to that update and show its progress.
    //       for now, it just gives an error.
    QProcess *check_status = new QProcess(this);
    check_status->start(QStringLiteral("systemctl"), {QStringLiteral("is-active"), QStringLiteral("uupd.service")});

    connect(check_status, &QProcess::readyReadStandardOutput, [=]() {
        check_status->deleteLater();

        while (check_status->canReadLine()) {
            const QString rawLine = QString::fromUtf8(check_status->readLine());
            if (rawLine != QStringLiteral("inactive")) {
                Utils::setConsoleText(i18n("An update is already running, wait for it to complete!"));
                Utils::setStatusText(i18n("ERROR!"));
                Utils::setUpdateError(true);
                Utils::setUpdateRunning(true);

                const QString finalOutput = QStringLiteral("systemctl is-active uupd.service: ") + rawLine;
                Utils::setConsoleText(Utils::consoleText() + finalOutput);
                callback.call({1, finalOutput});
                return;
            }
        }
    });

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
                        Utils::setUpdateError(true);
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

            if (Utils::consoleText() == DEFAULT_CONSOLE_TEXT)
                Utils::setConsoleText(standardData);
            else
                Utils::setConsoleText(Utils::consoleText() + standardData);

            if (standardData.contains(QStringLiteral("Finished uupd.service")) == true)
                Utils::setUpdateRunning(false);
        }
    });

    connect(systemctl, &QProcess::finished, [=](int exitCode, QProcess::ExitStatus exitStatus) {
        systemctl->deleteLater();

        const QString stdout = QString::fromUtf8(systemctl->readAllStandardOutput().trimmed());

        // Successful exit (not successful update)
        if (exitCode == 0 && exitStatus == QProcess::NormalExit) {
            callback.call({exitCode, stdout});
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
        Utils::setConsoleText(QStringLiteral("The command systemctl start uupd.service failed:") + intermediateText);
        callback.call({exitCode, finalOutputText});
        return;
    });
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

bool Utils::updateError() const
{
    return m_updateError;
}

void Utils::setUpdateError(bool updateError)
{
    m_updateError = updateError;
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
