// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#pragma once

#include <QFileInfo>
#include <QJSValue>
#include <QModelIndex>
#include <QProcess>
#include <QQmlEngine>
#include <qlogging.h>
#include <qobject.h>
#include <qtclasshelpermacros.h>

using namespace Qt::Literals::StringLiterals;

namespace Utils
{

using namespace Qt::Literals::StringLiterals;

static const bool IN_FLATPAK = QFileInfo::exists(u"/.flatpak-info"_s);
const bool GAMESCOPE_SESSION = qEnvironmentVariable("XDG_CURRENT_DESKTOP").trimmed().toLower().contains(u"gamescope"_s);
const bool KDE_SESSION = qEnvironmentVariable("XDG_CURRENT_DESKTOP").trimmed().toLower().contains(u"kde"_s);

void startProcess(QProcess *process, const QStringList &command);
}

namespace SingletonInternals
{

class AppState : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_DISABLE_COPY_MOVE(AppState)
    AppState() = default;

public:
    static AppState &instance()
    {
        static AppState s_instance = AppState();
        return s_instance;
    }

    static AppState *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
    {
        Q_UNUSED(jsEngine)
        AppState *instancePtr = &instance();
        qmlEngine->setObjectOwnership(instancePtr, QQmlEngine::CppOwnership);
        return instancePtr;
    }

private:
    Q_PROPERTY(bool updateRunning READ updateRunning NOTIFY updateRunningChanged)
    Q_PROPERTY(bool rollbackRunning READ rollbackRunning NOTIFY rollbackRunningChanged)
    Q_PROPERTY(bool rebaseRunning READ rebaseRunning NOTIFY rebaseRunningChanged)

    Q_PROPERTY(bool commandRunning READ commandRunning NOTIFY commandRunningChanged)
    Q_PROPERTY(bool commandSucceeded READ commandSucceeded NOTIFY commandSucceededChanged)
    Q_PROPERTY(bool allowCommands READ allowCommands NOTIFY allowCommandsChanged)

    Q_PROPERTY(QString commandError READ commandError NOTIFY commandErrorChanged)

    Q_PROPERTY(bool isGamescopeSession MEMBER is_gamescope_session CONSTANT)

    enum sendSignals {
        UPDATE,
        REBASE,
        ROLLBACK
    };

    // Rebasing is not possible in gamescope session due to its required password input, which gamescope session fails to display.
    const bool is_gamescope_session = Utils::GAMESCOPE_SESSION;

public:
    bool updateRunning() const
    {
        return m_updateRunning;
    }
    bool rollbackRunning() const
    {
        return m_rollbackRunning;
    }
    bool rebaseRunning() const
    {
        return m_rebaseRunning;
    }
    bool commandRunning() const
    {
        return m_updateRunning || m_rollbackRunning || m_rebaseRunning;
    }
    bool commandSucceeded() const
    {
        return m_commandSucceeded;
    }
    bool allowCommands() const
    {
        return !m_commandSucceeded && !commandRunning();
    }
    QString commandError() const
    {
        return QString::fromUtf8(cmd_out);
    }

    void setUpdateRunning(bool running);
    void setRollbackRunning(bool running);
    void setRebaseRunning(bool running);
    void setCommandSucceeded(bool succeeded);

    Q_INVOKABLE void rebootSystem(QJSValue callback);

    Q_SIGNAL void updateRunningChanged();
    Q_SIGNAL void rollbackRunningChanged();
    Q_SIGNAL void rebaseRunningChanged();
    Q_SIGNAL void commandRunningChanged();
    Q_SIGNAL void commandSucceededChanged();
    Q_SIGNAL void allowCommandsChanged();
    Q_SIGNAL void commandErrorChanged();

    void sendUpdateSignals(sendSignals signal);

    // setter is not exposed to QML
    void appendCommandError(QByteArray error);
    QByteArray cmd_out;

private:
    bool m_updateRunning = false;
    bool m_rollbackRunning = false;
    bool m_rebaseRunning = false;
    bool m_commandSucceeded = false;
};

}

inline SingletonInternals::AppState &appState = SingletonInternals::AppState::instance();
