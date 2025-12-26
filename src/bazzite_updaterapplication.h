// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QQmlEngine>
#include <AbstractKirigamiApplication>

using namespace Qt::StringLiterals;

class Bazzite_UpdaterApplication : public AbstractKirigamiApplication
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit Bazzite_UpdaterApplication(QObject *parent = nullptr);

Q_SIGNALS:
    void incrementCounter();

private:
    void setupActions() override;
};
