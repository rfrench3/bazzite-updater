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

    visibility: Window.FullScreen

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

    // NOTE: I change the page by editing pageStack.initialPage instead of using pageStack.layers.push,
    // it is simpler for getting functional controller/keyboard-only navigation
    globalDrawer: Kirigami.GlobalDrawer {

        id: appGlobalDrawer
        isMenu: false // Even on desktop, side drawer looks better here

        Shortcut {
            sequences: ["F1", "Ctrl+M", "Escape"]
            context: Qt.ApplicationShortcut
            onActivated: {
                appGlobalDrawer.drawerOpen = !appGlobalDrawer.drawerOpen;
                // send focus to global drawer when it opens
                if (appGlobalDrawer.drawerOpen == true)
                    focusGrabber.forceActiveFocus();
            }
        }

        // HACK: Actions do not have the forceActiveFocus() function needed for nice controller navigation,
        // so I am using an invisible Item header to initially grab that focus. Not a perfect solution
        // Once tab has been pressed once, up/down arrow keys can navigate through the global drawer
        header: Item { id: focusGrabber }

        actions: [
            Kirigami.Action {
                id: actionSystemUpdate
                text: i18n("System Update")
                icon.name: "list-add"

                QQC2.ActionGroup.group: selectedPage
                checkable: true
                enabled: !checked
                checked: true

                onTriggered: pageStack.initialPage = Qt.resolvedUrl("SystemUpdate.qml")
            },
            Kirigami.Action {
                id: actionRebaseTool
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

                QQC2.ActionGroup.group: selectedPage
                checkable: true
                enabled: !checked
                checked: true

                // onTriggered:
            },
            Kirigami.Action {
                text: i18n("About Bazzite")
                icon.name: "help-about"

                QQC2.ActionGroup.group: selectedPage
                checkable: true
                enabled: !checked
                checked: true

                onTriggered: pageStack.initialPage = Qt.resolvedUrl("AboutBazzite.qml")
            },
            Kirigami.Action {
                text: i18n("About Bazzite Updater")
                icon.name: "help-about"

                QQC2.ActionGroup.group: selectedPage
                checkable: true
                enabled: !checked
                checked: true

                onTriggered: pageStack.initialPage = aboutApp
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
