// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.bazzite_updater
import org.kde.bazzite_updater.settings as Settings

import org.kde.example 1.0

StatefulApp.StatefulWindow {
    id: root

    title: i18nc("@title:window", "Bazzite Updater")

    windowName: "Bazzite Updater"

    minimumWidth: Kirigami.Units.gridUnit * 20
    minimumHeight: Kirigami.Units.gridUnit * 20

    application: Bazzite_UpdaterApplication {
        configurationView: Settings.Bazzite_UpdaterConfigurationView {}
    }

    Component { // <==== Component that instantiates the Kirigami.AboutPage
        id: aboutApp

        Kirigami.AboutPage {
            aboutData: About
        }
    }

    QQC2.ActionGroup { id: selectedPage }

    // Change the base page by editing pageStack.initialPage, show a popup page menu with pageStack.layers.push
    globalDrawer: Kirigami.GlobalDrawer {
        isMenu: false // Even on desktop, side drawer looks better here
        actions: [
            Kirigami.Action {
                text: i18n("System Update")
                icon.name: "list-add"

                QQC2.ActionGroup.group: selectedPage
                checkable: true
                enabled: !checked
                checked: true

                onTriggered: pageStack.initialPage = Qt.resolvedUrl("SystemUpdate.qml")
            },
            Kirigami.Action {
                text: i18n("System Rebase Tool (TODO)")
                icon.name: "list-add"

                QQC2.ActionGroup.group: selectedPage
                checkable: true
                enabled: !checked

                onTriggered: pageStack.initialPage = Qt.resolvedUrl("RebaseHelper.qml")
            },

            Kirigami.Action { separator: true },

            Kirigami.Action {
                text: i18n("Configure Application (TODO)")
                icon.name: "settings-configure"
                // onTriggered: pageStack.layers.push(aboutApp)
            },
            Kirigami.Action {
                text: i18n("About Bazzite (TODO)")
                icon.name: "help-about"
                // onTriggered: pageStack.layers.push(aboutApp)
            },
            Kirigami.Action {
                text: i18n("About Bazzite Updater")
                icon.name: "help-about"
                onTriggered: pageStack.layers.push(aboutApp)
            },

            Kirigami.Action { separator: true },

            Kirigami.Action {
                text: i18n("Quit")
                icon.name: "application-exit"
                shortcut: StandardKey.Quit
                onTriggered: Qt.quit()
            }
        ]
    }

    pageStack.initialPage: Qt.resolvedUrl("SystemUpdate.qml")
}
