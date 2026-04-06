// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#pragma once

#include <QFileInfo>
#include <QJSValue>
#include <QProcess>
#include <QQmlEngine>
#include <iostream>

using namespace Qt::Literals::StringLiterals;

namespace Utils
{
bool isFlatpak();
void startProcess(QProcess *process, const QString &cmd, const QStringList &args);
void startProcess(QProcess &process, const QString &cmd, const QStringList &args);
bool isProgramPresent(const QString &cmd);
bool isServicePresent(const QString &service);
void connectQProcessOutputs(QProcess *process, QByteArray &stored_out, QByteArray &stored_err);
};

class AppState : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool updateRunning READ updateRunning NOTIFY updateRunningChanged)
    Q_PROPERTY(bool rollbackRunning READ rollbackRunning NOTIFY rollbackRunningChanged)
    Q_PROPERTY(bool rebaseRunning READ rebaseRunning NOTIFY rebaseRunningChanged)

    Q_PROPERTY(bool commandRunning READ commandRunning NOTIFY commandRunningChanged)
    Q_PROPERTY(bool commandSucceeded READ commandSucceeded NOTIFY commandSucceededChanged)
    Q_PROPERTY(bool allowCommands READ allowCommands NOTIFY allowCommandsChanged)

    enum sendSignals {
        UPDATE,
        REBASE,
        ROLLBACK
    };

    static AppState *m_instance;

public:
    AppState();

    // TODO: This method of accessing the sole instance of AppState would ideally be replaced by a more elegant solution.
    static AppState *instance();

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

    void sendUpdateSignals(sendSignals signal);

    QByteArray cmd_out;
    QByteArray cmd_err;

private:
    bool m_updateRunning = false;
    bool m_rollbackRunning = false;
    bool m_rebaseRunning = false;
    bool m_commandSucceeded = false;
};

inline AppState *appState()
{
    return AppState::instance();
}
