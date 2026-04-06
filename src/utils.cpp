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

// Returns true if program is found
bool Utils::isProgramPresent(const QString &cmd)
{
    QProcess process;
    startProcess(process, u"which"_s, {cmd});
    process.waitForFinished();
    return process.exitCode() == 0;
}

// Returns true if service is found
bool Utils::isServicePresent(const QString &service)
{
    QProcess check_process;

    Utils::startProcess(check_process, u"systemctl"_s, {u"list-unit-files"_s, u"--no-legend"_s, u"--no-pager"_s, service});
    check_process.waitForFinished();

    return check_process.exitCode() == 0;
}

// Connects QProcess output to stdout and stderr of application and stores a copy
void Utils::connectQProcessOutputs(QProcess *process, QByteArray &stored_out, QByteArray &stored_err)
{
    if (process->processChannelMode() != QProcess::SeparateChannels) {
        qWarning() << "cannot connect to outputs unless QProcess channel mode is default (SeparateChannels)!";
        return;
    }

    QObject::connect(process, &QProcess::readyReadStandardOutput, process, [process, &stored_out]() {
        QByteArray data_out = process->readAllStandardOutput();
        stored_out.append(data_out);
        std::cout.write(data_out.constData(), data_out.size());
        std::cout.flush();
    });

    QObject::connect(process, &QProcess::readyReadStandardError, process, [process, &stored_err]() {
        QByteArray data_out = process->readAllStandardError();
        stored_err.append(data_out);
        std::cerr.write(data_out.constData(), data_out.size());
        std::cerr.flush();
    });
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
