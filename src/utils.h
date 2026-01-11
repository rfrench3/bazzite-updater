// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#pragma once

#include <QFileInfo>
#include <QProcess>

using namespace Qt::Literals::StringLiterals;

class Utils
{
public:
    static bool isFlatpak();
    static void startProcess(QProcess *process, const QString &cmd, const QStringList &args);
    static void startProcess(QProcess &process, const QString &cmd, const QStringList &args);
};
