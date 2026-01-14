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

import org.kde.about 1.0

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

    Component {
        id: aboutApp

        // Kirigami.AboutPage {
        FormCard.AboutPage {
            id: aboutPage
            aboutData: About
            title: Gamepad.labels.b + Gamepad.labels.space_large + i18nc("@title", "Bazzite Updater")
            
            GamepadPageNavigation {
                targetWindow: aboutPage.Window.window
            }
        }
    }

    // Handle global drawer navigation for controllers
    // The GamePadNavigation class cannot be used because actions don't have the required properties
    Connections {
        target: Gamepad

        function onButtonPressed(buttonId) {
            switch (buttonId) {
                case 1: // B
                case 4: // view, minus
                case 6: // pause, plus
                    appGlobalDrawer.drawerOpen = !appGlobalDrawer.drawerOpen;
                    break;
            }
            
            if (appGlobalDrawer.drawerOpen != true)
                return;

            switch (buttonId) {
                case 0: // A
                    appGlobalDrawer.drawerOpen = false;
                    break;
                
                case 2: // X
                    Qt.quit();
                    break;

                case 11: // Dpad Up
                    appGlobalDrawer.navigateGlobalDrawer(-1);
                    break;

                case 12: // Dpad Down
                    appGlobalDrawer.navigateGlobalDrawer(1);
                    break;
            }
        }
    }

    globalDrawer: Kirigami.GlobalDrawer {

        id: appGlobalDrawer

        Shortcut {
            sequences: ["F1", "Ctrl+M", "Escape"]
            context: Qt.ApplicationShortcut
            onActivated: appGlobalDrawer.drawerOpen = !appGlobalDrawer.drawerOpen
        }

        QQC2.ActionGroup {
            id: pageSelector
        }

        actions: [
            Kirigami.Action {

                text: i18n("System Update")
                icon.name: "system-software-update"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                checked: true

                onTriggered: pageStack.initialPage = Qt.resolvedUrl("SystemUpdate.qml")
            },
            Kirigami.Action {

                text: i18n("System Rebase Tool")
                icon.name: "system-reboot"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                onTriggered: pageStack.initialPage = Qt.resolvedUrl("RebaseHelper.qml")
            },

            Kirigami.Action { separator: true },

            Kirigami.Action {
                text: i18n("About Bazzite")
                icon.name: "help-about"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                // onTriggered: pageStack.initialPage = Qt.resolvedUrl("AboutBazzite.qml")
                onTriggered: pageStack.initialPage = Qt.resolvedUrl("AboutDataBazzite.qml")
            },
            Kirigami.Action {
                text: i18n("About Bazzite Updater")
                icon.name: "help-about"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                // onTriggered: pageStack.initialPage = aboutApp
                onTriggered: pageStack.initialPage = Qt.resolvedUrl("AboutDataApp.qml")
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
            // direction = +1 or -1, used to navigate with a controller

            // Find the current page
            let currentIndex = -1;
            for (let i = 0; i < appGlobalDrawer.actions.length; i++) {
                if (appGlobalDrawer.actions[i].checked) {
                    currentIndex = i;
                    break;
                }
            }

            let newIndex = currentIndex;

            // Find the next page (skip non-page elements of the list)
            for (let j = 0; j < appGlobalDrawer.actions.length; j++) {
                newIndex += direction;

                // Do not wrap around
                if (newIndex < 0 || newIndex >= appGlobalDrawer.actions.length)
                    return;

                let item = appGlobalDrawer.actions[newIndex];
                if (item.checkable)
                    break;
            }

            // The next page was found, naviagte to it
            if (newIndex !== currentIndex) {
                if (currentIndex >= 0) appGlobalDrawer.actions[currentIndex].checked = false;
                appGlobalDrawer.actions[newIndex].triggered();
                appGlobalDrawer.actions[newIndex].checked = true;
            }
        }

    }

    pageStack.initialPage: Qt.resolvedUrl("SystemUpdate.qml")
}
