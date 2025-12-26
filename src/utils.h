/*
 *  SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
 *  SPDX-FileCopyrightText: 2022 Nate Graham <nate@kde.org>
 *  SPDX-FileCopyrightText: 2024 Oliver Beard <olib141@outlook.com>
 *  SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <QJSValue>
#include <QQmlEngine>

// There are some checks for if current == default
#define DEFAULT_CONSOLE_TEXT i18n("No output")

// org.kde.plasma.welcome, Utils
// Provides utility functionality for Welcome Center, intended for distro pages

class Utils : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString consoleText READ consoleText WRITE setConsoleText NOTIFY consoleTextChanged)
    Q_PROPERTY(QString statusText READ statusText WRITE setStatusText NOTIFY statusTextChanged)
    Q_PROPERTY(int progressLevel READ progressLevel WRITE setProgressLevel NOTIFY progressLevelChanged)
    Q_PROPERTY(bool updateError READ updateError WRITE setUpdateError NOTIFY updateErrorChanged)
    Q_PROPERTY(bool updateRunning READ updateRunning WRITE setUpdateRunning NOTIFY updateRunningChanged)
    QML_ELEMENT
    QML_SINGLETON

    QString m_consoleText = DEFAULT_CONSOLE_TEXT;
    QString m_statusText = i18n("None");
    int m_progressLevel = 0;
    bool m_updateRunning = false;
    bool m_updateError = false;

public:
    Utils(QObject *parent = nullptr);

    Q_INVOKABLE void runUpdate(QJSValue callback = QJSValue());

    Q_INVOKABLE void copyToClipboard(const QString &content) const;

    QString consoleText() const;
    void setConsoleText(const QString &consoleText);
    Q_SIGNAL void consoleTextChanged();

    QString statusText() const;
    void setStatusText(const QString &statusText);
    Q_SIGNAL void statusTextChanged();

    int progressLevel() const;
    void setProgressLevel( int progressLevel);
    Q_SIGNAL void progressLevelChanged();

    bool updateError() const;
    void setUpdateError(bool updateError);
    Q_SIGNAL void updateErrorChanged();

    bool updateRunning() const;
    void setUpdateRunning(bool updateRunning);
    Q_SIGNAL void updateRunningChanged();
};
