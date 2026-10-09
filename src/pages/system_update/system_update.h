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
#include "update_steps_model.h"
#include "utils.h"

using namespace Qt::Literals::StringLiterals;

QString formatForConsole(const QByteArray &bytes);
QString formatForConsole(QString line);

// TODO: When uupd is easier to parse, the entire UpdateSteps backend should be redone
namespace UpdateStepsModules
{
inline const QString SYSTEM = u"System"_s;
inline const QString BREW = u"Brew"_s;
inline const QString FLATPAK = u"Flatpak"_s;
inline const QString USER_FLATPAK = u"User Flatpak"_s;
};

class SystemUpdateBackend : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(Console::Model *consoleModel MEMBER m_console CONSTANT)
    Q_PROPERTY(bool blockUpdate READ blockUpdate NOTIFY blockUpdateChanged)

    bool m_blockUpdate = false;

public:
    SystemUpdateBackend(QObject *parent = nullptr);

    Console::Model *m_console;

    UpdateStepsNS::Model *m_updateStepsModel;

    Q_PROPERTY(UpdateStepsNS::Model *updateStepsModel READ updateStepsModel CONSTANT)
    UpdateStepsNS::Model *updateStepsModel() const
    {
        return m_updateStepsModel;
    }

    Q_INVOKABLE void runUpdate(QJSValue callback);

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
