// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include <QApplication>
#include <QtGlobal>

#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QUrl>

#include "version-bazzite_updater.h"
#include <KAboutData>
#include <KIconTheme>
#include <KLocalizedQmlContext>
#include <KLocalizedString>

#include "console.h"
#include "rebase_helper.h"
#include "system_update.h"
#include "utils.h"

using namespace Qt::Literals::StringLiterals;

int main(int argc, char *argv[])
{
    KIconTheme::initTheme();
    QIcon::setFallbackThemeName("breeze"_L1);
    QApplication app(argc, argv);

    // Default to org.kde.desktop style unless the user forces another style
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(u"org.kde.desktop"_s);
        // TODO: setFallbackStyle is not used because it prevents the System Update console's monospace font from working,
        // but ideally it would fall back to Material
    }

    KLocalizedString::setApplicationDomain("bazzite_updater");
    QCoreApplication::setOrganizationName(u"UniversalBlue"_s);

    QGuiApplication::setWindowIcon(QIcon::fromTheme(u"io.github.rfrench3.bazzite_updater"_s));

    QQmlApplicationEngine engine;

    // NOTE: This is a weird way to register and link singletons, but it works for now
    AppState app_state;
    qmlRegisterSingletonInstance<AppState>("app.State", 1, 0, "AppState", &app_state);

    SystemUpdate system_update;
    system_update.setAppState(&app_state);
    qmlRegisterSingletonInstance<SystemUpdate>("app.SysUpd", 1, 0, "SysUpd", &system_update);

    RebaseHelper rebase_helper;
    rebase_helper.setAppState(&app_state);
    qmlRegisterSingletonInstance<RebaseHelper>("app.RebaseHelper", 1, 0, "RebaseHelper", &rebase_helper);

    KLocalization::setupLocalizedContext(&engine);
    engine.loadFromModule("io.github.rfrench3.bazzite_updater", u"Main"_s);

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
