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
    settings.showRebootReminder = m_group.readEntry("showRebootReminder", defaults.showRebootReminder);
    settings.preferFullscreen = m_group.readEntry("preferFullscreen", defaults.preferFullscreen);
    settings.preferConsole = m_group.readEntry("preferConsole", defaults.preferConsole);
}

void UserSettings::setShowRebootReminder(bool show)
{
    if (settings.showRebootReminder == show)
        return;

    settings.showRebootReminder = show;
    m_group.writeEntry("showRebootReminder", show);
    m_group.sync();

    Q_EMIT showRebootReminderChanged();
    Q_EMIT isDefaultChanged();
}

void UserSettings::setPreferFullscreen(bool prefer)
{
    if (settings.preferFullscreen == prefer)
        return;

    settings.preferFullscreen = prefer;
    m_group.writeEntry("preferFullscreen", prefer);
    m_group.sync();

    Q_EMIT preferFullscreenChanged();
    Q_EMIT isDefaultChanged();
}

void UserSettings::setPreferConsole(bool prefer)
{
    if (settings.preferConsole == prefer)
        return;

    settings.preferConsole = prefer;
    m_group.writeEntry("preferConsole", prefer);
    m_group.sync();

    Q_EMIT preferConsoleChanged();
    Q_EMIT isDefaultChanged();
}

void UserSettings::restoreDefaults()
{
    setShowRebootReminder(defaults.showRebootReminder);
    setPreferFullscreen(defaults.preferFullscreen);
    setPreferConsole(defaults.preferConsole);
}
