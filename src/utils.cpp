// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#include "utils.h"
#include <qcontainerfwd.h>
#include <qlogging.h>
#include <qprocess.h>

namespace Utils
{

void startProcess(QProcess *process, const QStringList &command)
{
    qInfo() << "> " << command.join(u" ");
    process->start(command.at(0), command.mid(1));
}
}

namespace SingletonInternals
{

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

void AppState::rebootSystem(QJSValue callback)
{
    QProcess reboot;
    Utils::startProcess(&reboot, {u"systemctl"_s, u"reboot"_s});
    reboot.waitForFinished();
    callback.call({1});
}

void AppState::appendCommandError(QByteArray error)
{
    cmd_out.append(error);
    Q_EMIT commandErrorChanged();
}

}
