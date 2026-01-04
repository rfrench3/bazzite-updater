// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.formcard as FormCard

import io.github.rfrench3.bazzite_updater
import app.Gamepad 1.0

import org.kde.example 1.0

// NOTE: Gamepad.labels.* automatically show/hide themselves depending on the presence of a controller

StatefulApp.StatefulWindow {
    id: root

    title: i18nc("@title:window", "Bazzite Updater")

    windowName: "Bazzite Updater"

    minimumWidth: Kirigami.Units.gridUnit * 20
    minimumHeight: Kirigami.Units.gridUnit * 20

    visibility: Window.FullScreen

    // Start and stop polling for controller inputs when the window gains/loses focus
    onActiveChanged: Gamepad.setPollController(active)


    Component { // <==== Component that instantiates the Kirigami.AboutPage
        id: aboutApp

        Kirigami.AboutPage {
            aboutData: About
            title: Gamepad.labels.b + Gamepad.labels.space_large + i18nc("@title", "Bazzite Updater")
        }
    }

    // Handle global drawer navigation
    Connections {
        target: Gamepad

        function onButtonPressed(buttonId) {
            switch (buttonId) {
                case 1: // B
                case 4: // view, minus
                case 6: // pause, plus
                    appGlobalDrawer.drawerOpen = !appGlobalDrawer.drawerOpen;
                    break;

                case 2: // X
                    if (appGlobalDrawer.drawerOpen == true)
                        Qt.quit();
                    break;

                case 11: // Dpad Up
                    if (appGlobalDrawer.drawerOpen == true)
                        appGlobalDrawer.navigateGlobalDrawer(-1);
                    break;

                case 12: // Dpad Down
                    if (appGlobalDrawer.drawerOpen == true)
                        appGlobalDrawer.navigateGlobalDrawer(1);
                    break;

            }
        }
    }

    globalDrawer: Kirigami.GlobalDrawer {

        id: appGlobalDrawer
        isMenu: false // Even on desktop, side drawer looks better here

        Shortcut {
            sequences: ["F1", "Ctrl+M", "Escape"]
            context: Qt.ApplicationShortcut
            onActivated: appGlobalDrawer.drawerOpen = !appGlobalDrawer.drawerOpen
        }

        property list<Kirigami.Action> navActions: [
            Kirigami.Action {
                id: actionSystemUpdate
                text: i18n("System Update")
                icon.name: "list-add"

                checkable: true
                enabled: !checked
                checked: true

                property bool isPage: true
                onTriggered: pageStack.initialPage = Qt.resolvedUrl("SystemUpdate.qml")
            },
            Kirigami.Action {
                id: actionRebaseTool
                text: i18n("System Rebase Tool (TODO)")
                icon.name: "list-add"

                checkable: true
                enabled: !checked

                property bool isPage: true
                onTriggered: pageStack.initialPage = Qt.resolvedUrl("RebaseHelper.qml")
            },

            Kirigami.Action { separator: true },

            Kirigami.Action {
                text: i18n("About Bazzite")
                icon.name: "help-about"

                checkable: true
                enabled: !checked

                property bool isPage: true
                onTriggered: pageStack.initialPage = Qt.resolvedUrl("AboutBazzite.qml")
            },
            Kirigami.Action {
                text: i18n("About Bazzite Updater")
                icon.name: "help-about"

                checkable: true
                enabled: !checked

                property bool isPage: true
                onTriggered: pageStack.initialPage = aboutApp
            },

            Kirigami.Action { separator: true },

            Kirigami.Action {
                id: actionQuit
                text: i18n("Quit") + Gamepad.labels.space + Gamepad.labels.x
                icon.name: "application-exit"
                shortcut: StandardKey.Quit
                onTriggered: Qt.quit()
            }
        ]

        function navigateGlobalDrawer(direction) {

            // Find the current page
            let currentIndex = -1;
            for (let i = 0; i < navActions.length; i++) {
                if (navActions[i].checked) {
                    currentIndex = i;
                    break;
                }
            }

            let newIndex = currentIndex;

            // Find the next page (skip non-page elements of the list)
            for (let j = 0; j < navActions.length; j++) {
                newIndex += direction;

                // Do not wrap around
                if (newIndex < 0 || newIndex >= navActions.length)
                    return;

                let item = navActions[newIndex];
                if (item.isPage)
                    break;
            }

            // The next page was found, naviagte to it
            if (newIndex !== currentIndex) {
                if (currentIndex >= 0) navActions[currentIndex].checked = false;
                navActions[newIndex].triggered();
                navActions[newIndex].checked = true;
            }
        }

        actions: navActions

    }

    pageStack.initialPage: Qt.resolvedUrl("SystemUpdate.qml")
}
