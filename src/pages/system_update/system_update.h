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
#include <qcontainerfwd.h>
#include <qobject.h>
#include <qprocess.h>

#include "console.h"
#include "utils.h"

using namespace Qt::Literals::StringLiterals;

QString formatForConsole(const QByteArray &bytes);
QString formatForConsole(QString line);

class SystemUpdateBackend : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(Console::Model *consoleModel MEMBER m_console CONSTANT)
    Q_PROPERTY(int progressLevel READ progressLevel NOTIFY progressLevelChanged)
    Q_PROPERTY(bool blockUpdate READ blockUpdate NOTIFY blockUpdateChanged)
    Q_PROPERTY(bool hasNvidiaGpu READ hasNvidiaGpu NOTIFY hasNvidiaGpuChanged)

    int m_progressLevel = 0;
    bool m_blockUpdate = false;
    bool m_hasNvidiaGpu = false;
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

    QString m_placeholderTextColor;

public:
    SystemUpdateBackend(QObject *parent = nullptr);

    bool hasNvidiaGpu() const { return m_hasNvidiaGpu; }
    Q_INVOKABLE void checkNvidiaGpu();
    Q_INVOKABLE void runNvidiaFlatpakUpdate(QJSValue callback);
    Q_SIGNAL void hasNvidiaGpuChanged();

    Console::Model *m_console;

    Q_INVOKABLE void runUpdate(QJSValue callback);

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
        return appState.updateRunning();
    }
    Q_SIGNAL void updateRunningChanged();
};
