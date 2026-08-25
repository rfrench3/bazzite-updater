// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "user_settings.h"
#include <kconfig.h>
#include <kconfiggroup.h>
#include <ksharedconfig.h>
#include <qtmetamacros.h>

UserSettings::UserSettings()
    : m_group(KSharedConfig::openConfig(u"bazzite-updaterrc"_s), u"Settings"_s)
{
    m_showRebootReminder = m_group.readEntry("showRebootReminder", true);
}

void UserSettings::setShowRebootReminder(bool show)
{
    if (m_showRebootReminder == show)
        return;

    m_showRebootReminder = show;
    m_group.writeEntry("showRebootReminder", show);
    m_group.sync();

    Q_EMIT showRebootReminderChanged();
}

void UserSettings::restoreDefaults()
{
    setShowRebootReminder(true);
}
