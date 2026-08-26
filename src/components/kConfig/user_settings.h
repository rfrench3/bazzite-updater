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

    bool showRebootReminder() const
    {
        return m_showRebootReminder;
    }

    void setShowRebootReminder(bool show);

    Q_INVOKABLE void restoreDefaults();

    Q_SIGNAL void showRebootReminderChanged();

private:
    KConfigGroup m_group;
    bool m_showRebootReminder = true;
};
