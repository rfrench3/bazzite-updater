// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.formcard as FormCard

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.Gamepad


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

    // Handle global drawer navigation for controllers

    property var activeDialog: null

    Connections {
        target: Gamepad

        function onButtonPressed(buttonId, button_down) {

            if (activeDialog) {
                activeDialog.handleInput(buttonId, button_down);
                return;    
            }

            switch (buttonId) {
                case 1: // B
                case 4: // view, minus
                case 6: // pause, plus
                    if (button_down) 
                        appGlobalDrawer.drawerOpen = !appGlobalDrawer.drawerOpen;
                    return;
            }

            if (appGlobalDrawer.drawerOpen) {
                appGlobalDrawer.handleInput(buttonId, button_down);
                return;
            }

            if (typeof pageStack.currentItem.handleInput === "function") {
                pageStack.currentItem.handleInput(buttonId, button_down);
                return;
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

                onTriggered: pageStack.initialPage = Qt.resolvedUrl("AboutDataBazzite.qml")
            },
            Kirigami.Action {
                text: i18n("About Bazzite Updater")
                icon.name: "help-about"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                onTriggered: pageStack.initialPage = Qt.resolvedUrl("AboutDataApp.qml")
            },

            Kirigami.Action { separator: true },

            Kirigami.Action {
                id: actionReboot
                text: i18n("Reboot System") + Gamepad.labels.space + Gamepad.labels.y
                icon.name: AppState.commandSucceeded ? "system-shutdown-update" : "system-shutdown" 
                
                onTriggered: {
                    rebootDialog.open();
                }
            },

            Kirigami.Action {
                id: actionQuit
                text: i18n("Quit") + Gamepad.labels.space + Gamepad.labels.x
                icon.name: "application-exit"
                shortcut: StandardKey.Quit
                onTriggered: {
                    if (AppState.commandRunning) {
                        exitDialog.open(); 
                    }
                    else
                        Qt.quit();
                }
            }
        ]

        function __navigateGlobalDrawer(direction) {
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

        function handleInput(buttonId, button_down) {
            if (!button_down) return;

            switch (buttonId) {
                case 0: // A
                    drawerOpen = false;
                    break;
                
                case 2: // X
                    actionQuit.triggered();
                    break;

                case 3: // Y
                    actionReboot.triggered();
                    break;

                case 11: // Dpad Up
                    __navigateGlobalDrawer(-1);
                    break;

                case 12: // Dpad Down
                    __navigateGlobalDrawer(1);
                    break;
            }
        }
    }

    AppDialog {
        id: rebootDialog
        title: i18nc("@title:window", "Reboot System")
        standardButtons: Kirigami.Dialog.NoButton

        subtitle: AppState.commandRunning
            ? i18n("This will reboot the system,\nbut %1 is still in progress!\nRebooting now will cause it to not apply.",
                AppState.rollbackRunning
                    ? i18n("a rollback")
                    : AppState.rebaseRunning
                        ? i18n("a rebase")
                        : AppState.updateRunning
                            ? i18n("an update")
                            : i18n("a command"))
            : i18n("This will reboot the system.")

        customFooterActions: [
            Kirigami.Action {
                id: confirmReboot
                text: i18n("Confirm") + Gamepad.labels.space + Gamepad.labels.a
                
                onTriggered: rebootDialog.accept()
            },
            Kirigami.Action {
                id: cancelReboot
                text: i18n("Cancel") + Gamepad.labels.space + Gamepad.labels.b
                onTriggered: rebootDialog.reject()
            }
        ]

        onAccepted: {
            AppState.rebootSystem(function (callback) {
                if (AppState.commandSucceeded)
                    showPassiveNotification(i18n("The system reboot has failed. Reboot manually to apply changes."), Kirigami.short);
                else
                    showPassiveNotification(i18n("The system reboot has failed."), Kirigami.short);
            
                console.log("Reboot callback: " + callback);
            });
        }

        function handleInput(buttonId, button_down) {
            if (!button_down) return;
            switch (buttonId) {
                case 0: // A
                    confirmReboot.triggered();    
                    break;

                case 1: // B
                    cancelReboot.triggered();
                    break;
            }
        }

    }

    AppDialog {
        id: exitDialog
        title: i18n("Exit Application")
        standardButtons: Kirigami.Dialog.NoButton

        subtitle: {
            if (!AppState.commandRunning)
                return i18n("It is safe to exit.");

            let statusText;

            if (AppState.rollbackRunning) {
                statusText = i18n("A rollback is still in progress!");
            } else if (AppState.rebaseRunning) {
                statusText = i18n("A rebase is still in progress!");
            } else if (AppState.updateRunning) {
                statusText = i18n("An update is still in progress!");
            } else {
                statusText = i18n("A command is still in progress!");
            }

            return i18n(
                "%1 %2",
                statusText,
                i18n("A system update will continue on exit, but a rollback or rebase will be cancelled.")
            );
        }

        customFooterActions: [
            Kirigami.Action {
                id: confirmExit
                text: i18n("Confirm") + Gamepad.labels.space + Gamepad.labels.a
                
                onTriggered: exitDialog.accept()
            },
            Kirigami.Action {
                id: cancelExit
                text: i18n("Cancel") + Gamepad.labels.space + Gamepad.labels.b
                onTriggered: exitDialog.reject()
            }
        ]

        onAccepted: Qt.quit()

        function handleInput(buttonId, button_down) {
            if (!button_down) return;
            
            switch (buttonId) {
                case 0: // A
                    confirmExit.triggered();    
                    break;

                case 1: // B
                    cancelExit.triggered();
                    break;
            }
        }

    }

    AppDialog {
        id: errorDisplayDialog
        title: i18nc("@title:window", "Error Message")
        standardButtons: Kirigami.Dialog.Ok

        QQC2.Label {
            id: errorDisplayDialogText
            text: AppState.commandError
        }        

        function handleInput(buttonId, button_down) {
            if (!button_down) return;
            
            switch (buttonId) {
                case 0: // A
                case 1: // B
                    accept();    
                    break;

                case 2: // X
                    Qt.application.clipboard.setText(errorDisplayDialogText.text);
                    showPassiveNotification(i18n("Copied error message to clipboard."), Kirigami.short);
                    break;
            }
        }
    }

    pageStack.initialPage: Qt.resolvedUrl("SystemUpdate.qml")
}
