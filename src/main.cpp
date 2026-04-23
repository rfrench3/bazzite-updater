// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include <QApplication>
#include <QtGlobal>

#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QScreen>
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

#define BASE_HEIGHT 1080.0

using namespace Qt::Literals::StringLiterals;

int main(int argc, char *argv[])
{
    if (Utils::GAMESCOPE_SESSION) {
        /*
            Gamescope-session does not apply any app scaling.
            This ensures it is scaled well on high-DPI, while respecting regular desktop settings.

            This may behave strangely in multi-monitor environments, but gamescope should keep those hidden from the app.
            Example: kde window rules to move the app to a certain display seem to break this scaling check
        */
        if (qEnvironmentVariableIsEmpty("QT_SCALE_FACTOR")) {
            QGuiApplication screenGetter(argc, argv);
            QScreen *screen = screenGetter.primaryScreen();
            const float height = screen->geometry().height();
            const float scale_factor = height / BASE_HEIGHT;

            // scale by a minimum of 2X for mobile and TV usage
            float final_scale = 2;
            if (scale_factor > 1.0)
                final_scale *= scale_factor;
            qputenv("QT_SCALE_FACTOR", QByteArray::number(final_scale));
        }

        // Use the Qt theme KDE uses (unthemed outside of KDE)
        if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORMTHEME"))
            qputenv("QT_QPA_PLATFORMTHEME", QByteArray::fromStdString("kde"));
    }

    KIconTheme::initTheme();
    QIcon::setFallbackThemeName("breeze"_L1);
    QApplication app(argc, argv);

    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE"))
        QQuickStyle::setStyle(u"org.kde.desktop"_s);

    KLocalizedString::setApplicationDomain("bazzite_updater");
    QCoreApplication::setOrganizationName(u"UniversalBlue"_s);

    QGuiApplication::setWindowIcon(QIcon::fromTheme(u"io.github.rfrench3.bazzite_updater"_s));

    QQmlApplicationEngine engine;

    KLocalization::setupLocalizedContext(&engine);
    engine.loadFromModule("io.github.rfrench3.bazzite_updater", u"Main"_s);

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

#ifdef TESTING_BUILD
    engine.rootContext()->setContextProperty(u"TestingMode"_s, true);
#else
    engine.rootContext()->setContextProperty(u"TestingMode"_s, false);
#endif

    return app.exec();
}
