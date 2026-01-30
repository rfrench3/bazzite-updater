import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.about 1.0
import app.Gamepad 1.0
import QtQuick

FormCard.AboutPage {
    id: page_scrollable
    title: Gamepad.labels.b + Gamepad.labels.space_large + i18nc("@title", "About Application")

    Component.onCompleted: {
        Gamepad.setPageScrollable(page_scrollable.contentItem);
    }

    aboutData: {
        "displayName" : i18nc("@title:window", "Bazzite Updater"),
        "componentName" : "bazzite_updater",
        "shortDescription" : "Updating and rebasing utility for Bazzite",
        "homepage" : "https://github.com/rfrench3/bazzite_updater",
        "bugAddress" : "https://github.com/rfrench3/bazzite_updater/issues",
        "version" : "@PROJECT_VERSION@",
        "otherText" : i18n("This interface can be used to update Bazzite, rollback from a bad update, and rebase to entirely separate versions of Bazzite!"),
        "authors" : [
            {
                "name" : "Robert French",
                "task" : "Developer",
                "emailAddress" : "frenchrobertm@outlook.com",
                "webAddress" : "https://rfrench3.github.io/personal-site/",
                "ocsUsername" : "rfrench3"
            },
            {
                "name" : "Gareth Widlansky",
                "task" : "Developer",
                "emailAddress" : "",
                "webAddress" : "https://github.com/gerblesh"
            }
        ],
        "credits" : [],
        "translators" : [],
        "licenses" : [
            {
                "name" : "GPL v2",
                "text" : "@GPL2_ONLY_LICENSE@",
                "spdx" : "GPL-2.0"
            },
            {
                "name" : "GPL v3",
                "text" : "@GPL3_ONLY_LICENSE@",
                "spdx" : "GPL-3.0"
            },
            {
                "name" : "KDE Accepted",
                "text" : "@KDE_ACCEPTED_GPL_LICENSE@",
                "spdx" : "LicenseRef-KDE-Accepted-GPL"
            }
        ],
        "copyrightStatement" : "© 2025-2026",
        "desktopFileName" : "io.github.rfrench3.bazzite_updater"
    }
}
