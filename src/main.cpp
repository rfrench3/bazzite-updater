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

#include "bazzite_updaterconfig.h"
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
    QCoreApplication::setOrganizationName(QStringLiteral("KDE"));

    KAboutData aboutDataApp(QStringLiteral("bazzite_updater"),
                            i18nc("@title", "Bazzite Updater"),
                            QStringLiteral(BAZZITE_UPDATER_VERSION_STRING),
                            i18n("Updating and rebasing utility for Bazzite"),
                            KAboutLicense::GPL,
                            i18n("(c) 2025"));

    aboutDataApp.addAuthor(i18nc("@info:credit", "Robert French"),
                           i18nc("@info:credit", "Maintainer"),
                           QStringLiteral("frenchrobertm@outlook.com"),
                           QStringLiteral("https://rfrench3.github.io/personal-site/"));

    aboutDataApp.setTranslator(i18nc("NAME OF TRANSLATORS", "Your names"), i18nc("EMAIL OF TRANSLATORS", "Your emails"));

    KAboutData::setApplicationData(aboutDataApp);

    QGuiApplication::setWindowIcon(QIcon::fromTheme(u"io.github.rfrench3.bazzite_updater"_s));

    QQmlApplicationEngine engine;

    // auto config = Bazzite_UpdaterConfig::self();

    // qmlRegisterSingletonInstance("org.kde.bazzite_updater.private", 1, 0, "Config", config);

    qmlRegisterSingletonType("org.kde.example", // How the import statement should look like
                             1,
                             0, // Major and minor versions of the import
                             "About", // The name of the QML object
                             [](QQmlEngine *engine, QJSEngine *) -> QJSValue {
                                 return engine->toScriptValue(KAboutData::applicationData());
                             });

    Utils utils;
    engine.rootContext()->setContextProperty(QStringLiteral("Utils"), &utils);

    KLocalization::setupLocalizedContext(&engine);
    engine.loadFromModule("org.kde.bazzite_updater", u"Main"_s);

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
