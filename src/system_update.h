/*
 *  SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
 *  SPDX-FileCopyrightText: 2022 Nate Graham <nate@kde.org>
 *  SPDX-FileCopyrightText: 2024 Oliver Beard <olib141@outlook.com>
 *  SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <KLocalizedString>
#include <QBrush>
#include <QColor>
#include <QFileInfo>
#include <QJSValue>
#include <QPalette>
#include <QProcess>
#include <QQmlEngine>

#include "utils.h"

using namespace Qt::Literals::StringLiterals;

// There are some checks for if current == default
#define DEFAULT_CONSOLE_TEXT i18n("No output")

// Initially based on the Plasma Welcome page code
// org.kde.plasma.welcome, Utils
// Provides utility functionality for Welcome Center, intended for distro pages

class SystemUpdate : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString consoleText READ consoleText NOTIFY consoleTextChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(int progressLevel READ progressLevel NOTIFY progressLevelChanged)
    Q_PROPERTY(bool blockUpdate READ blockUpdate NOTIFY blockUpdateChanged)
    QML_ELEMENT
    QML_SINGLETON

    QString m_consoleText = DEFAULT_CONSOLE_TEXT;
    QString m_statusText = i18n("None");
    int m_progressLevel = 0;
    bool m_blockUpdate = false;
    QProcess m_journalctlProcess;

    struct UpdateErrors {
        bool System_Update = false;
        bool Brew_Update = false;
        bool System_Apps = false;
        bool Apps_for_User = false;
        bool Distroboxes_for_User = false;
        bool Unknown_Error = false;
    };

    UpdateErrors m_updateErrorStatus;

    QString getServiceState(const QString &service) const;
    QString getServiceResult(const QString &service) const;
    void logToConsole();
    QString m_placeholderTextColor;

    AppState *m_appState;

    enum class LogLevel {
        INFO,
        WARN,
        ERROR,
        DEBUG,
        ERROR_CRITICAL
    };

public:
    SystemUpdate(QObject *parent = nullptr);

    Q_INVOKABLE void runUpdate(QJSValue callback = QJSValue(), QJSValue callbackErrors = QJSValue());

    Q_INVOKABLE void copyToClipboard(const QString &content) const;

    void setPlaceholderColor(QString placeholderText);
    void setAppState(AppState *appState);

    QString consoleText() const
    {
        return m_consoleText;
    }
    void setConsoleText(const QString &consoleText);
    void appendConsoleText(const QString &consoleText, LogLevel level);
    Q_SIGNAL void consoleTextChanged();

    QString statusText() const
    {
        return m_statusText;
    }
    void setStatusText(const QString &statusText);
    Q_SIGNAL void statusTextChanged();

    int progressLevel() const
    {
        return m_progressLevel;
    }
    void setProgressLevel(int progressLevel);
    Q_SIGNAL void progressLevelChanged();

    bool blockUpdate() const
    {
        return m_blockUpdate;
    }
    void setBlockUpdate(bool updateError);
    Q_SIGNAL void blockUpdateChanged();

    bool updateRunning() const
    {
        return m_appState->updateRunning();
    }
    Q_SIGNAL void updateRunningChanged();
};
