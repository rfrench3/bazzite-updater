// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.formcard as FormCard

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

// NOTE: Gamepad.labels.* automatically show/hide themselves depending on the presence of a controller

StatefulApp.StatefulWindow {
    id: root

    title: i18nc("@title:window", "Bazzite Updater")

    windowName: "Bazzite Updater"

    minimumWidth: Kirigami.Units.gridUnit * 20
    minimumHeight: Kirigami.Units.gridUnit * 20

    visibility: UseFullscreen ? Window.FullScreen : Window.Windowed

    onClosing: close => {
        close.accepted = false;
        actionQuit.triggered();
    }

    // Handle global drawer navigation for controllers

    property var activeDialog: null

    Connections {
        target: GP.Gamepad

        function onButtonEvent(buttonId, button_down) {
            if (activeDialog) {
                activeDialog.handleInput(buttonId, button_down);
                return;
            }

            switch (buttonId) {
            case 1: // B
            case 4: // view, minus
            case 6: // pause, plus
                if (button_down)
                    globalDrawer.drawerOpen = !globalDrawer.drawerOpen;
                return;
            }

            if (globalDrawer.drawerOpen) {
                globalDrawer.handleInput(buttonId, button_down);
                return;
            }

            if (typeof pageStack.currentItem.handleInput === "function") {
                pageStack.currentItem.handleInput(buttonId, button_down);
                return;
            }
        }
    }

    globalDrawer: Kirigami.GlobalDrawer {
        id: globalDrawer

        Shortcut {
            sequences: ["F1", "Ctrl+M", "Escape"]
            context: Qt.ApplicationShortcut
            onActivated: globalDrawer.drawerOpen = !globalDrawer.drawerOpen
        }

        QQC2.ActionGroup {
            id: pageSelector
        }

        actions: [
            Kirigami.Action {

                text: i18n("System Update")
                icon.name: "system-software-update-symbolic"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                checked: true

                onTriggered: pageStack.initialPage = Qt.resolvedUrl("SystemUpdate.qml")
            },
            Kirigami.Action {

                text: i18n("Other Utilities")
                icon.name: "system-reboot-symbolic"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                onTriggered: pageStack.initialPage = Qt.resolvedUrl("RebaseHelper.qml")
            },
            Kirigami.Action {
                separator: true
            },
            Kirigami.Action {
                text: i18n("About %1", AppConfig.ini.AboutInfo.name)
                icon.name: "help-about-symbolic"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                onTriggered: pageStack.initialPage = Qt.resolvedUrl("AboutDataOS.qml")
            },
            Kirigami.Action {
                text: i18n("About Bazzite Updater")
                icon.name: "help-about-symbolic"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                onTriggered: pageStack.initialPage = Qt.resolvedUrl("AboutDataApp.qml")
            },
            Kirigami.Action {
                separator: true
            },
            Kirigami.Action {
                id: actionReboot
                text: i18n("Reboot System") + GP.Labels.spacer + GP.Labels.north
                icon.name: AppState.commandSucceeded ? "system-shutdown-update-symbolic" : "system-shutdown-symbolic"

                onTriggered: {
                    rebootDialog.open();
                }
            },
            Kirigami.Action {
                id: actionQuit
                text: i18n("Quit") + GP.Labels.spacer + GP.Labels.west
                icon.name: "application-exit-symbolic"
                shortcut: StandardKey.Quit
                onTriggered: {
                    if (AppState.commandRunning || AppState.commandSucceeded) {
                        exitDialog.open();
                    } else
                        Qt.quit();
                }
            }
        ]

        function __navigateGlobalDrawer(direction) {
            // direction = +1 or -1, used to navigate with a controller

            // Find the current page
            let currentIndex = -1;
            for (let i = 0; i < globalDrawer.actions.length; i++) {
                if (globalDrawer.actions[i].checked) {
                    currentIndex = i;
                    break;
                }
            }

            let newIndex = currentIndex;

            // Find the next page (skip non-page elements of the list)
            for (let j = 0; j < globalDrawer.actions.length; j++) {
                newIndex += direction;

                // Do not wrap around
                if (newIndex < 0 || newIndex >= globalDrawer.actions.length)
                    return;

                let item = globalDrawer.actions[newIndex];
                if (item.checkable)
                    break;
            }

            // The next page was found, naviagte to it
            if (newIndex !== currentIndex) {
                if (currentIndex >= 0)
                    globalDrawer.actions[currentIndex].checked = false;
                globalDrawer.actions[newIndex].triggered();
                globalDrawer.actions[newIndex].checked = true;
            }
        }

        function handleInput(buttonId, button_down) {
            if (!button_down)
                return;

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

        subtitle: AppState.commandRunning ? i18n("This will reboot the system,\nbut %1 is still in progress!\nRebooting now will cause it to not apply.", AppState.rollbackRunning ? i18n("a rollback") : AppState.rebaseRunning ? i18n("a rebase") : AppState.updateRunning ? i18n("an update") : i18n("a command")) : i18n("This will reboot the system.")

        customFooterActions: [
            Kirigami.Action {
                id: confirmReboot
                text: i18n("Reboot") + GP.Labels.spacer + GP.Labels.south

                onTriggered: rebootDialog.accept()
            },
            Kirigami.Action {
                id: cancelReboot
                text: i18n("Cancel") + GP.Labels.spacer + GP.Labels.east
                onTriggered: rebootDialog.reject()
            }
        ]

        onAccepted: {
            AppState.rebootSystem(function (callback) {
                rebootTimer.start();
                console.log("Reboot callback: " + callback);
            });
        }

        // Wait a little while to ensure "your reboot has failed" isn't ever visible momentarily before rebooting succeeds
        Timer {
            id: rebootTimer
            interval: 2000
            repeat: false
            onTriggered: {
                if (AppState.commandSucceeded)
                    root.showPassiveNotification(i18n("The system reboot has failed. Reboot manually to apply changes."), Kirigami.short);
                else
                    root.showPassiveNotification(i18n("The system reboot has failed."), Kirigami.short);
            }
        }

        function handleInput(buttonId, button_down) {
            if (!button_down)
                return;
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
                return AppState.commandSucceeded ? i18n("You must reboot to apply changes.") : i18n("No command is running, you may exit.");

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

            return i18n("%1 %2", statusText, i18n("A system update will continue on exit, but a rollback or rebase will be cancelled."));
        }

        customFooterActions: [
            Kirigami.Action {
                id: confirmExit
                text: i18n("Exit") + GP.Labels.spacer + GP.Labels.south

                onTriggered: exitDialog.accept()
            },
            Kirigami.Action {
                id: cancelExit
                text: i18n("Cancel") + GP.Labels.spacer + GP.Labels.east
                onTriggered: exitDialog.reject()
            }
        ]

        onAccepted: Qt.quit()

        function handleInput(buttonId, button_down) {
            if (!button_down)
                return;

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

    pageStack.initialPage: Qt.resolvedUrl("SystemUpdate.qml")
}
