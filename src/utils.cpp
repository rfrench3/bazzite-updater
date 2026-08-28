// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#include "utils.h"
#include <qcontainerfwd.h>
#include <qguiapplication.h>
#include <qlogging.h>
#include <qprocess.h>

#include <KColorSchemeManager>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDBusVariant>
#include <QIcon>

#include <QPalette>

namespace Utils
{

void startProcess(QProcess *process, const QStringList &command)
{
    qInfo() << "> " << command.join(u" ");
    process->start(command.at(0), command.mid(1));
}

DbusListener::DbusListener(QObject *parent)
    : QObject(parent)
{
    // Set the theme initially
    initSetColorScheme();

    // Set the theme when it changes as the app is already open
    QDBusConnection::sessionBus().connect(u"org.freedesktop.portal.Desktop"_s,
                                          u"/org/freedesktop/portal/desktop"_s,
                                          u"org.freedesktop.portal.Settings"_s,
                                          u"SettingChanged"_s,
                                          this,
                                          SLOT(onPortalSettingChanged(QString, QString, QDBusVariant)));
}

void DbusListener::initSetColorScheme()
{
    QDBusInterface portal(u"org.freedesktop.portal.Desktop"_s,
                          u"/org/freedesktop/portal/desktop"_s,
                          u"org.freedesktop.portal.Settings"_s,
                          QDBusConnection::sessionBus());

    if (!portal.isValid()) {
        return;
    }

    QDBusReply<QDBusVariant> reply = portal.call(u"Read"_s, u"org.freedesktop.appearance"_s, u"color-scheme"_s);

    if (!reply.isValid()) {
        return;
    }

    // org.freedesktop.portal.Settings returns a variant containing another variant (v -> v -> uint)
    const auto colorScheme = reply.value().variant().value<QDBusVariant>().variant().toUInt();

    // Force dark theme for gamescope session
    if (colorScheme == 1 || GAMESCOPE_SESSION) {
        KColorSchemeManager::instance()->activateSchemeId(u"BreezeDark"_s);
    } else {
        KColorSchemeManager::instance()->activateSchemeId(u"BreezeLight"_s);
    }
    QIcon::setThemeName(u"breeze"_s);

    prevColorScheme = colorScheme;
}

void DbusListener::onPortalSettingChanged(const QString &nameSpace, const QString &key, const QDBusVariant &value)
{
    // Filter for the color-scheme setting
    if (nameSpace == u"org.freedesktop.appearance"_s && key == u"color-scheme"_s) {
        const auto colorScheme = value.variant().toUInt();
        if (colorScheme == prevColorScheme)
            return;

        prevColorScheme = colorScheme;

        if (colorScheme == 1) {
            KColorSchemeManager::instance()->activateSchemeId(u"BreezeDark"_s);
        } else {
            KColorSchemeManager::instance()->activateSchemeId(u"BreezeLight"_s);
        }
        QIcon::setThemeName(u"breeze"_s);
    }
}
}

namespace SingletonInternals
{

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
    Utils::startProcess(&reboot, {u"systemctl"_s, u"reboot"_s});
    reboot.waitForFinished();
    callback.call({1});
}

void AppState::appendCommandError(QByteArray error)
{
    cmd_out.append(error);
    Q_EMIT commandErrorChanged();
}

}
