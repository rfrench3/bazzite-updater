// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include <KirigamiAddons/App/kirigamiappdefaults.h>
#include <QApplication>
#include <QtGlobal>

#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QScreen>
#include <QStyleHints>
#include <QUrl>

#include "version-bazzite-updater.h"
#include <KAboutData>
#include <KColorSchemeManager>
#include <KIconTheme>
#include <KLocalizedQmlContext>
#include <KLocalizedString>
#include <KirigamiAddons/App/KirigamiAppDefaults>
#include <cstdlib>
#include <iostream>
#include <kaboutdata.h>
#include <kcolorschememanager.h>
#include <ostream>
#include <qapplication.h>
#include <qcommandlineoption.h>
#include <qcommandlineparser.h>
#include <qcoreapplication.h>
#include <qguiapplication.h>
#include <qlogging.h>
#include <qnamespace.h>
#include <qobject.h>
#include <qqml.h>

#include <qqmlpropertymap.h>
#include <unistd.h>

#include "k_config.h"
#include "utils.h"

inline constexpr float BASE_HEIGHT = 1080.0;

using namespace Qt::Literals::StringLiterals;

// Handle non-gui functionality: Replace the bazzite-updater process with the selected process defined by the config.ini
void commandLine(int argc, char *argv[], QCoreApplication &app);

int main(int argc, char *argv[])
{
    const QString FULL_APP_DOMAIN = u"io.github.rfrench3.bazzite-updater"_s;
    bool UseFullscreen = false;

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

        UseFullscreen = true;
    }

    QApplication app(argc, argv);
    KirigamiAppDefaults::apply(&app);

    // exits early if the command line options are used
    commandLine(argc, argv, app);

    if (Utils::KDE_SESSION) {
        if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
            QQuickStyle::setStyle(u"org.kde.desktop"_s);
        }
    } else {
        bool useBreeze = false;
        if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
            QQuickStyle::setStyle(u"org.kde.breeze"_s);
            useBreeze = true;
        }

        if (qEnvironmentVariableIsEmpty("QT_STYLE_OVERRIDE")) {
            QApplication::setStyle(u"breeze"_s);
            useBreeze = true;
        }

        if (useBreeze) {
            auto manager = KColorSchemeManager::instance();

            // Respect desktop color scheme, but force breeze dark for gamescope session
            if (app.styleHints()->colorScheme() == Qt::ColorScheme::Dark || Utils::GAMESCOPE_SESSION)
                manager->activateSchemeId(u"BreezeDark"_s);
            else
                manager->activateSchemeId(u"BreezeLight"_s);
        }
    }

    KLocalizedString::setApplicationDomain("bazzite-updater");
    QCoreApplication::setOrganizationName(u"UniversalBlue"_s);

    KAboutData aboutData(u"bazzite-updater"_s,
                         i18n("Bazzite Updater"),
                         QStringLiteral(BAZZITE_UPDATER_VERSION_STRING),
                         i18n("Updating and rebasing utility for Bazzite"),
                         KAboutLicense::Unknown, // Can't directly set v2-or-later here
                         i18n("© 2025-2026 Robert French"),
                         i18n("This application can be used through a controller or keyboard to perform various update-related system tasks!"),
                         u"https://github.com/rfrench3/bazzite_updater"_s,
                         u"https://github.com/rfrench3/bazzite_updater/issues"_s);
    aboutData.setLicense(KAboutLicense::GPL_V2, KAboutLicense::OrLaterVersions);
    aboutData.addCredit(u"Gareth Widlansky"_s, u"Uupd integration"_s, u""_s, u"https://github.com/gerblesh"_s);
    aboutData.setDesktopFileName(FULL_APP_DOMAIN);
    KAboutData::setApplicationData(aboutData);

    QGuiApplication::setWindowIcon(QIcon::fromTheme(FULL_APP_DOMAIN));
    QGuiApplication::setDesktopFileName(FULL_APP_DOMAIN);

    QQmlApplicationEngine engine;
    KLocalization::setupLocalizedContext(&engine);
    engine.loadFromModule("io.github.rfrench3.bazzite_updater", u"Main"_s);

    if (engine.rootObjects().isEmpty()) {
        return EXIT_FAILURE;
    }

    // For non-critical data storage
    auto sessionStorage = QQmlPropertyMap::create(&app);
    engine.rootContext()->setContextProperty(u"sessionStorage"_s, sessionStorage);

    engine.rootContext()->setContextProperty(u"UseFullscreen"_s, UseFullscreen);

    return app.exec();
}

void commandLine(int argc, char *argv[], QCoreApplication &app)
{
    QCommandLineParser parser;
    parser.addHelpOption();

    QCommandLineOption update(u"update"_s, u"Performs the configured system update command."_s);
    QCommandLineOption rollback(u"rollback"_s, u"Performs the configured system rollback command."_s);

    parser.addOption(update);
    parser.addOption(rollback);

    parser.process(app);

    // Run the GUI normally if neither --update or --rollback are present
    if (!(parser.isSet(update) || parser.isSet(rollback))) {
        std::cout << "Note: you can run \"" << argv[0] << " --help\" to view command-line functionality for this application." << std::endl;
        return;
    }

    if (parser.isSet(update) && parser.isSet(rollback)) {
        std::cerr << "You cannot use --update and --rollback at the same time." << std::endl;
        exit(EXIT_FAILURE);
    }

    auto cmd = QString();

    if (parser.isSet(update))
        cmd = configIni.getValue(u"Commands"_s, u"systemUpdateCommand"_s);

    if (parser.isSet(rollback))
        cmd = configIni.getValue(u"Commands"_s, u"systemRollbackCommand"_s);

    if (cmd.isEmpty()) {
        std::cerr << "Command not defined." << std::endl;
        exit(EXIT_FAILURE);
    }

    const auto args = QProcess::splitCommand(cmd);

    // prepare arguments for execvp
    QList<char *> execArgs;
    execArgs.reserve(args.size() + 1);

    for (const QString &arg : args)
        execArgs.append(qstrdup(arg.toLocal8Bit().constData()));

    execArgs.append(nullptr);

    std::cout << ">" << args.join(u" "_s).toStdString() << std::endl;

    execvp(execArgs.first(), execArgs.data());

    perror("execvp failed");
    exit(EXIT_FAILURE);
}
