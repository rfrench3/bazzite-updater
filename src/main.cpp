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

#include "controllers.h"
#include "rebase_helper.h"
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
    }

    KLocalizedString::setApplicationDomain("bazzite_updater");
    QCoreApplication::setOrganizationName(u"KDE"_s);

    KAboutData aboutDataApp(u"bazzite_updater"_s,
                            i18nc("@title", "Bazzite Updater"),
                            QStringLiteral(BAZZITE_UPDATER_VERSION_STRING),
                            i18n("Updating and rebasing utility for Bazzite"),
                            KAboutLicense::GPL,
                            i18n("(c) 2025"));

    aboutDataApp.addAuthor(i18nc("@info:credit", "Robert French"),
                           i18nc("@info:credit", "Maintainer"),
                           u"frenchrobertm@outlook.com"_s,
                           u"https://rfrench3.github.io/personal-site/"_s);

    aboutDataApp.setTranslator(i18nc("NAME OF TRANSLATORS", "Your names"), i18nc("EMAIL OF TRANSLATORS", "Your emails"));

    KAboutData::setApplicationData(aboutDataApp);

    QGuiApplication::setWindowIcon(QIcon::fromTheme(u"io.github.rfrench3.bazzite_updater"_s));

    QQmlApplicationEngine engine;

    qmlRegisterSingletonType("org.kde.example", // How the import statement should look like
                             1,
                             0, // Major and minor versions of the import
                             "About", // The name of the QML object
                             [](QQmlEngine *engine, QJSEngine *) -> QJSValue {
                                 return engine->toScriptValue(KAboutData::applicationData());
                             });

    Utils utils;
    qmlRegisterSingletonInstance<Utils>("app.Utils", 1, 0, "Utils", &utils);

    ControllerManager gamepad;
    qmlRegisterSingletonInstance<ControllerManager>("app.Gamepad", 1, 0, "Gamepad", &gamepad);

    RebaseHelper rebase_helper;
    qmlRegisterSingletonInstance<RebaseHelper>("app.RebaseHelper", 1, 0, "RebaseHelper", &rebase_helper);

    KLocalization::setupLocalizedContext(&engine);
    engine.loadFromModule("io.github.rfrench3.bazzite_updater", u"Main"_s);

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
