// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>

#include "bazzite_updaterapplication.h"
#include <KAuthorized>
#include <KLocalizedString>

using namespace Qt::StringLiterals;

Bazzite_UpdaterApplication::Bazzite_UpdaterApplication(QObject *parent)
    : AbstractKirigamiApplication(parent)
{
    setupActions();
}

void Bazzite_UpdaterApplication::setupActions()
{
    AbstractKirigamiApplication::setupActions();

    auto actionName = "increment_counter"_L1;
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mainCollection()->addAction(actionName, this, &Bazzite_UpdaterApplication::incrementCounter);
        action->setText(i18nc("@action:inmenu", "Increment"));
        action->setIcon(QIcon::fromTheme(u"list-add-symbolic"_s));
        mainCollection()->addAction(action->objectName(), action);
        mainCollection()->setDefaultShortcut(action, Qt::CTRL | Qt::Key_I);
    }

    readSettings();
}

#include "moc_bazzite_updaterapplication.cpp"
