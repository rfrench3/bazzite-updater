// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#include "utils.h"
#include <qlogging.h>
#include <qprocess.h>

namespace Utils
{

bool isFlatpak()
{
    return QFileInfo::exists(u"/.flatpak-info"_s);
}

void startProcess(QProcess *process, const QString &cmd, const QStringList &args)
{
    if (isFlatpak()) {
        QStringList hostArgs;
        hostArgs << u"--host"_s << cmd << args;
        qInfo() << "starting flatpak-spawn with the arguments: " << args;
        process->start(u"flatpak-spawn"_s, hostArgs);
    } else {
        qInfo() << "starting " << cmd << " with the arguments: " << args;
        process->start(cmd, args);
    }
}

void startProcess(QProcess &process, const QString &cmd, const QStringList &args)
{
    startProcess(&process, cmd, args);
}

// Returns true if program is found
bool isProgramPresent(const QString &cmd)
{
    QProcess process;
    startProcess(process, u"which"_s, {cmd});
    process.waitForFinished();
    return process.exitCode() == 0;
}

// Returns true if service is found
bool isServicePresent(const QString &service)
{
    QProcess check_process;

    startProcess(check_process, u"systemctl"_s, {u"list-unit-files"_s, u"--no-legend"_s, u"--no-pager"_s, service});
    check_process.waitForFinished();

    return check_process.exitCode() == 0;
}

// Sets process channel mode to MergedChannels,
// stores a copy of QProcess output using storeOutput and forwards output to main application
void connectQProcessOutputs(QProcess *process, const std::function<void(const QByteArray &)> &storeOutput)
{
    process->setProcessChannelMode(QProcess::MergedChannels);

    QObject::connect(process, &QProcess::readyReadStandardOutput, process, [process, storeOutput]() {
        QByteArray data_out = process->readAllStandardOutput();
        storeOutput(data_out);
        std::cout.write(data_out.constData(), data_out.size());
        std::cout.flush();
    });
}
}

// AppState

AppState *AppState::m_instance = nullptr;

AppState::AppState()
{
    if (m_instance == nullptr)
        m_instance = this;
    else
        qWarning() << "AppState was constructed when an instance already exists!";
}

AppState *AppState::instance()
{
    return m_instance;
}

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
    Utils::startProcess(reboot, u"systemctl"_s, {u"reboot"_s});
    reboot.waitForFinished();
    callback.call({1});
}

void AppState::appendCommandError(QByteArray error)
{
    cmd_out.append(error);
    Q_EMIT commandErrorChanged();
}
