// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#include "utils.h"

// Utils

bool Utils::isFlatpak()
{
    return QFileInfo::exists(u"/.flatpak-info"_s);
}

void Utils::startProcess(QProcess *process, const QString &cmd, const QStringList &args)
{
    if (isFlatpak()) {
        QStringList hostArgs;
        hostArgs << u"--host"_s << cmd << args;
        process->start(u"flatpak-spawn"_s, hostArgs);
    } else {
        process->start(cmd, args);
    }
}

void Utils::startProcess(QProcess &process, const QString &cmd, const QStringList &args)
{
    startProcess(&process, cmd, args);
}

bool Utils::isProgramPresent(const QString &cmd)
{
    QProcess process;
    startProcess(process, u"command"_s, {u"-v"_s, cmd});
    process.waitForFinished();
    return process.exitCode() == 0;
}

bool Utils::isServicePresent(const QString &service)
{
    QProcess check_process;

    Utils::startProcess(check_process, u"systemctl"_s, {u"list-unit-files"_s, u"--no-legend"_s, u"--no-pager"_s, service});
    check_process.waitForFinished();

    return check_process.exitCode() == 0;
}

// AppState

void AppState::setUpdateRunning(bool running)
{
    m_updateRunning = running;
    sendUpdateSignals(UPDATE);
}

void AppState::setRollbackRunning(bool running)
{
    m_rollbackRunning = running;
    sendUpdateSignals(ROLLBACK);
}

void AppState::setRebaseRunning(bool running)
{
    m_rebaseRunning = running;
    sendUpdateSignals(REBASE);
}

void AppState::setCommandSucceeded(bool succeeded)
{
    m_commandSucceeded = succeeded;
    Q_EMIT commandSucceededChanged();
    Q_EMIT allowCommandsChanged();
}

void AppState::sendUpdateSignals(sendSignals signal)
{
    Q_EMIT commandRunningChanged();
    Q_EMIT allowCommandsChanged();
    switch (signal) {
    case UPDATE:
        Q_EMIT updateRunningChanged();
        break;
    case ROLLBACK:
        Q_EMIT rollbackRunningChanged();
        break;
    case REBASE:
        Q_EMIT rebaseRunningChanged();
        break;
    }
}