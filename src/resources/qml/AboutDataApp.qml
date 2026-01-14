import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.about 1.0
// import app.Gamepad 1.0

FormCard.AboutPage {
    title: i18nc("@action:button", "About Application")
    // title: Gamepad.labels.b + Gamepad.labels.space_large + i18nc("@action:button", "About Application")

    // GamepadPageNavigation {
    //     targetWindow: parent.Window.window
    // }

    aboutData: {
        "displayName" : i18nc("@title:window", "Bazzite Updater"),
        "componentName" : "bazzite_updater",
        "shortDescription" : "Updating and rebasing utility for Bazzite",
        "homepage" : "https://github.com/rfrench3/bazzite_updater",
        "bugAddress" : "https://github.com/rfrench3/bazzite_updater/issues",
        "version" : "@PROJECT_VERSION@",
        "authors" : [
            {
                "name" : "Robert French",
                "task" : "Maintainer",
                "emailAddress" : "frenchrobertm@outlook.com",
                "webAddress" : "https://rfrench3.github.io/personal-site/",
                "ocsUsername" : "rfrench3"
            }
        ],
        "credits" : [],
        "translators" : [],
        "licenses" : [
            {
                "name" : "GPL v2",
                "text" : "Long license text goes here",
                "spdx" : "GPL-2.0"
            },
            {
                "name" : "GPL v3",
                "text" : "Long license text goes here",
                "spdx" : "GPL-3.0"
            },
            {
                "name" : "KDE Accepted",
                "text" : "Long license text goes here",
                "spdx" : "LicenseRef-KDE-Accepted-GPL"
            }
        ],
        "copyrightStatement" : "© 2025-2026",
        "desktopFileName" : "automatethis Bazzite Updater (Nightly)"
    }

}
