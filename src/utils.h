// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#pragma once

#include <QColor>
#include <QFileInfo>
#include <QJSValue>
#include <QModelIndex>
#include <QProcess>
#include <QQmlEngine>
#include <qcolor.h>
#include <qhashfunctions.h>
#include <qlogging.h>
#include <qobject.h>
#include <qtclasshelpermacros.h>
#include <qtmetamacros.h>

#include <QDBusVariant>
#include <qtypes.h>

inline constexpr uint NO_SCHEME = 99;

using namespace Qt::Literals::StringLiterals;

namespace Utils
{

using namespace Qt::Literals::StringLiterals;

const bool GAMESCOPE_SESSION = qEnvironmentVariable("XDG_CURRENT_DESKTOP").trimmed().toLower().contains(u"gamescope"_s);
const bool KDE_SESSION = qEnvironmentVariable("XDG_CURRENT_DESKTOP").trimmed().toLower().contains(u"kde"_s);

void startProcess(QProcess *process, const QStringList &command);

// TODO: This was necessary to force the app to respect color schemes outside of KDE.
//       Ideally, this entire class wouldn't need to exist.
class DbusListener : public QObject
{
    Q_OBJECT

    uint prevColorScheme = NO_SCHEME;

public:
    explicit DbusListener(QObject *parent = nullptr);

    // Make sure the color scheme is correct on launch
    void initSetColorScheme();

public:
    // Make sure the color scheme is correct when it changes mid-run
    Q_INVOKABLE void onPortalSettingChanged(const QString &nameSpace, const QString &key, const QDBusVariant &value);
};
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
    Q_PROPERTY(bool resetRunning READ resetRunning NOTIFY resetRunningChanged)
    Q_PROPERTY(bool removeRunning READ removeRunning NOTIFY removeRunningChanged)

    Q_PROPERTY(bool commandRunning READ commandRunning NOTIFY commandRunningChanged)
    Q_PROPERTY(bool commandSucceeded READ commandSucceeded NOTIFY commandSucceededChanged)
    Q_PROPERTY(bool allowCommands READ allowCommands NOTIFY allowCommandsChanged)

    Q_PROPERTY(bool isGamescopeSession MEMBER is_gamescope_session CONSTANT)

    enum sendSignals {
        UPDATE,
        REBASE,
        ROLLBACK,
        RESET,
        REMOVE
    };

    enum class Operation {
        NoOperation,
        Update,
        Rollback,
        Rebase,
        Reset,
        Remove
    };

    // Rebasing is not possible in gamescope session due to its required password input, which gamescope session fails to display.
    const bool is_gamescope_session = Utils::GAMESCOPE_SESSION;

public:
    bool updateRunning() const
    {
        return m_runningOperation == Operation::Update;
    }
    bool rollbackRunning() const
    {
        return m_runningOperation == Operation::Rollback;
    }
    bool rebaseRunning() const
    {
        return m_runningOperation == Operation::Rebase;
    }
    bool resetRunning() const
    {
        return m_runningOperation == Operation::Reset;
    }
    bool removeRunning() const
    {
        return m_runningOperation == Operation::Remove;
    }
    bool commandRunning() const
    {
        return m_runningOperation != Operation::NoOperation;
    }
    bool commandSucceeded() const
    {
        return m_commandSucceeded;
    }
    bool allowCommands() const
    {
        return !m_commandSucceeded && !commandRunning();
    }

    void setUpdateRunning(bool running);
    void setRollbackRunning(bool running);
    void setRebaseRunning(bool running);
    void setResetRunning(bool running);
    void setRemoveRunning(bool running);
    void setCommandSucceeded(bool succeeded);

    Q_INVOKABLE void rebootSystem(QJSValue callback);

    Q_SIGNAL void updateRunningChanged();
    Q_SIGNAL void rollbackRunningChanged();
    Q_SIGNAL void rebaseRunningChanged();
    Q_SIGNAL void resetRunningChanged();
    Q_SIGNAL void removeRunningChanged();
    Q_SIGNAL void commandRunningChanged();
    Q_SIGNAL void commandSucceededChanged();
    Q_SIGNAL void allowCommandsChanged();

    void sendUpdateSignals(sendSignals signal);

private:
    bool m_commandSucceeded = false;

    Operation m_runningOperation = Operation::NoOperation;
};

}

inline SingletonInternals::AppState &appState = SingletonInternals::AppState::instance();
