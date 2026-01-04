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

// NOTE: ControllerManager.labels.* automatically show/hide themselves depending on the presence of a controller

StatefulApp.StatefulWindow {
    id: root

    title: i18nc("@title:window", "Bazzite Updater")

    windowName: "Bazzite Updater"

    minimumWidth: Kirigami.Units.gridUnit * 20
    minimumHeight: Kirigami.Units.gridUnit * 20

    visibility: Window.FullScreen

    // Start and stop polling for controller inputs when the window gains/loses focus
    onActiveChanged: ControllerManager.setPollController(active)


    Component { // <==== Component that instantiates the Kirigami.AboutPage
        id: aboutApp

        Kirigami.AboutPage {
            aboutData: About
            title: ControllerManager.labels.b + ControllerManager.labels.space + i18nc("@title", "Bazzite Updater")
        }
    }

    // Handle global drawer navigation
    Connections {
        target: ControllerManager

        function onButtonPressed(buttonId) {
            switch (buttonId) {
                case 1: // B
                case 4: // view, minus
                case 6: // pause, plus
                    appGlobalDrawer.drawerOpen = !appGlobalDrawer.drawerOpen;
                    // send focus to global drawer when it opens
                    if (appGlobalDrawer.drawerOpen == true)
                        focusGrabber.forceActiveFocus();
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

        property list<Kirigami.Action> navActions: [
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
                id: actionQuit
                text: i18n("Quit") + ControllerManager.labels.space + ControllerManager.labels.x
                icon.name: "application-exit"
                shortcut: StandardKey.Quit
                onTriggered: Qt.quit()

                property bool skipNavigation: true
            }
        ]

        function navigateGlobalDrawer(direction) {

            var currentIndex = -1;
            for (var i = 0; i < navActions.length; i++) {
                if (navActions[i].checked) {
                    currentIndex = i;
                    break;
                }
            }

            var newIndex = currentIndex;
            var found = false;

            for (var j = 0; j < navActions.length; j++) {
                newIndex += direction;

                // Do not wrap around
                if (newIndex < 0 || newIndex >= navActions.length)
                    return;

                var item = navActions[newIndex];

                // Check if it's a valid navigation target
                // It must NOT be a separator, and it must be checkable/enabled
                if (!item.separator
                    && item.enabled
                    && item.visible
                    && item.skipNavigation != true)
                {
                    found = true;
                    break;
                }
            }

            // 3. Apply change
            if (found && newIndex !== currentIndex) {
                if (currentIndex >= 0) navActions[currentIndex].checked = false;
                navActions[newIndex].triggered();
                navActions[newIndex].checked = true;
            }
        }




        // HACK: Actions do not have the forceActiveFocus() function needed to focus them when the global drawer opens,
        // so I am using an invisible Item header to initially grab that focus. Not a perfect solution
        // Once tab has been pressed once, up/down arrow keys can navigate through the global drawer
        header: Item { id: focusGrabber }

        actions: navActions

    }

    pageStack.initialPage: Qt.resolvedUrl("SystemUpdate.qml")
}
