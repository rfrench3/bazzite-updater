// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#include "utils.h"

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
