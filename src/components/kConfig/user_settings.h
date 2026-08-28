// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <kconfiggroup.h>
#include <ksharedconfig.h>
#include <qjsengine.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>
#include <qtclasshelpermacros.h>
#include <qtmetamacros.h>
#include <qtpreprocessorsupport.h>

using namespace Qt::Literals::StringLiterals;

struct Settings {
    bool showRebootReminder = true;
    bool preferFullscreen = false;
    bool preferConsole = false;

    // allow settingsObj1 == settingsObj2 comparisons
    bool operator==(const Settings &) const = default;
};
static const Settings defaults = Settings();

/* Writable per-user preferences, stored in ~/.config/bazzite-updaterrc.
 * These only affect how the UI presents itself. Anything that decides which
 * command gets run stays in the read-only system config, see findConfigFile().
 */
class UserSettings : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_DISABLE_COPY_MOVE(UserSettings)
    UserSettings();

public: // singleton methods
    static UserSettings *instance()
    {
        static UserSettings *s_instance = new UserSettings();
        return s_instance;
    }

    static UserSettings *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
    {
        Q_UNUSED(jsEngine)
        UserSettings *instancePtr = instance();
        qmlEngine->setObjectOwnership(instancePtr, QQmlEngine::CppOwnership);
        return instancePtr;
    }

public:
    // Whether quitting reminds the user that a reboot is needed.
    Q_PROPERTY(bool showRebootReminder READ showRebootReminder WRITE setShowRebootReminder NOTIFY showRebootReminderChanged)

    // Whether the app should be in fullscreen mode (it will always use fullscreen in gamescope session)
    Q_PROPERTY(bool preferFullscreen READ preferFullscreen WRITE setPreferFullscreen NOTIFY preferFullscreenChanged)

    // Whether the console panels should start in the opened state
    Q_PROPERTY(bool preferConsole READ preferConsole WRITE setPreferConsole NOTIFY preferConsoleChanged)

    // Whether any settings differ from their default setting
    Q_PROPERTY(bool isDefault READ isDefault NOTIFY isDefaultChanged)

    bool showRebootReminder() const
    {
        return settings.showRebootReminder;
    }

    void setShowRebootReminder(bool show);

    bool preferFullscreen() const
    {
        return settings.preferFullscreen;
    }

    void setPreferFullscreen(bool prefer);

    bool preferConsole() const
    {
        return settings.preferConsole;
    }

    void setPreferConsole(bool prefer);

    bool isDefault() const
    {
        return settings == defaults;
    }

    Q_INVOKABLE void restoreDefaults();

    Q_SIGNAL void showRebootReminderChanged();

    Q_SIGNAL void preferFullscreenChanged();

    Q_SIGNAL void preferConsoleChanged();

    Q_SIGNAL void isDefaultChanged();

private:
    KConfigGroup m_group;
    Settings settings;
};
