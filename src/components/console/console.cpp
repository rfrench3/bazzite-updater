// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "console.h"

using namespace Console;

void Model::newLine(QString content, LogLevel level)
{
    lines.append(new Entry(content, level));
    Q_EMIT linesChanged();
}
