/*
 *  SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
 *  SPDX-FileCopyrightText: 2022 Nate Graham <nate@kde.org>
 *  SPDX-FileCopyrightText: 2024 Oliver Beard <olib141@outlook.com>
 *  SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Robert French: This was initially based on the Plasma Welcome page code. It has little to no resemblance in its current state

#pragma once

#include <KLocalizedString>
#include <QFileInfo>
#include <QJSValue>
#include <QProcess>
#include <QQmlEngine>

#ifdef TESTING_BUILD
#include <QTimer>
#endif

#include "console.h"
#include "utils.h"

using namespace Qt::Literals::StringLiterals;

class SystemUpdateBackend : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(Console::Model *consoleModel MEMBER m_console CONSTANT)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(int progressLevel READ progressLevel NOTIFY progressLevelChanged)
    Q_PROPERTY(bool blockUpdate READ blockUpdate NOTIFY blockUpdateChanged)

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

    void logToConsole();
    QString m_placeholderTextColor;

public:
    SystemUpdateBackend(QObject *parent = nullptr);

    Console::Model *m_console;

    Q_INVOKABLE void runUpdate(QJSValue callback = QJSValue(), QJSValue callbackErrors = QJSValue());

    QString getServiceState(const QString &service) const;
    QString getServiceResult(const QString &service) const;

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
        return appState()->updateRunning();
    }
    Q_SIGNAL void updateRunningChanged();

#ifdef TESTING_BUILD
private:
    Q_PROPERTY(int testConsoleLinesPerSecond READ testConsoleLinesPerSecond WRITE setTestConsoleLinesPerSecond NOTIFY testConsoleLinesPerSecondChanged)
public:
    int m_testConsoleLinesPerSecond = 0;
    int m_testConsoleLineCounter = 0;
    QTimer m_testConsoleTimer;

    int testConsoleLinesPerSecond() const
    {
        return m_testConsoleLinesPerSecond;
    }
    void setTestConsoleLinesPerSecond(int linesPerSecond);
    Q_SIGNAL void testConsoleLinesPerSecondChanged();
#endif
};
