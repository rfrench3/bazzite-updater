// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
// import org.kde.kirigamiaddons.formcard as FormCard

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

// NOTE: Gamepad.labels.* automatically show/hide themselves depending on the presence of a controller

StatefulApp.StatefulWindow {
    id: root

    title: i18nc("@title:window", "Bazzite Updater")

    windowName: "Bazzite Updater"

    minimumWidth: Kirigami.Units.gridUnit * 20
    minimumHeight: Kirigami.Units.gridUnit * 20

    visibility: (UseFullscreen || UserSettings.preferFullscreen) ? Window.FullScreen : Window.Windowed

    onClosing: close => {
        close.accepted = false;
        actionQuit.triggered();
    }

    Shortcut {
        sequences: ["F11"]
        context: Qt.ApplicationShortcut
        enabled: !UseFullscreen

        onActivated: {
            if (root.visibility === Window.Windowed)
                root.visibility = Window.FullScreen;
            else if (root.visibility === Window.FullScreen)
                root.visibility = Window.Windowed;
        }
    }

    // Handle global drawer navigation for controllers

    property var activeDialog: null

    Connections {
        target: GP.Gamepad

        function onButtonEvent(buttonId, button_down) {
            if (root.activeDialog) {
                root.activeDialog.handleInput(buttonId, button_down);
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

            if (typeof root.pageStack.currentItem.handleInput === "function") {
                root.pageStack.currentItem.handleInput(buttonId, button_down);
                return;
            }
        }
    }

    globalDrawer: Kirigami.GlobalDrawer {
        id: globalDrawer

        Behavior on width {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.InOutQuad
            }
        }

        // In some versions of Kirigami, the drawer width does not function properly. Therefore it must be manually set
        FontMetrics {
            id: actionFontMetrics
            font: Kirigami.Theme.defaultFont
        }
        function getMaxActionTextWidth() {
            let maxWidth = 0;
            for (let i = 0; i < actions.length; i++) {
                if (actions[i].text) {
                    // Measure the actual pixel width of this specific string
                    let currentWidth = actionFontMetrics.advanceWidth(actions[i].text);
                    if (currentWidth > maxWidth) {
                        maxWidth = currentWidth;
                    }
                }
            }
            return maxWidth;
        }
        width: getMaxActionTextWidth() + Kirigami.Units.iconSizes.medium + (Kirigami.Units.largeSpacing * 4)

        Shortcut {
            sequences: [StandardKey.Back, StandardKey.Close, "F1", "Ctrl+M", "Escape"]
            context: Qt.ApplicationShortcut
            onActivated: {
                if (root.activeDialog)
                    root.activeDialog.reject();
                else
                    globalDrawer.drawerOpen = !globalDrawer.drawerOpen;
            }
        }

        Shortcut {
            sequences: ["Return"]
            context: Qt.ApplicationShortcut
            enabled: globalDrawer.drawerOpen || root.activeDialog
            onActivated: {
                if (root.activeDialog) {
                    root.activeDialog.accept();
                } else
                    globalDrawer.drawerOpen = false;
            }
        }

        Shortcut {
            sequences: ["Up"]
            context: Qt.ApplicationShortcut
            enabled: globalDrawer.drawerOpen
            onActivated: globalDrawer.__navigateGlobalDrawer(-1)
        }

        Shortcut {
            sequences: ["Down"]
            context: Qt.ApplicationShortcut
            enabled: globalDrawer.drawerOpen
            onActivated: globalDrawer.__navigateGlobalDrawer(1)
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

                onTriggered: root.pageStack.initialPage = Qt.resolvedUrl("SystemUpdate.qml")
            },
            Kirigami.Action {

                text: i18n("Other Utilities")
                icon.name: "applications-accessories-symbolic"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                onTriggered: root.pageStack.initialPage = Qt.resolvedUrl("OtherUtils.qml")
            },
            Kirigami.Action {

                text: i18n("Rebase Helper")
                icon.name: "system-reboot-symbolic"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                onTriggered: root.pageStack.initialPage = Qt.resolvedUrl("RebasePage.qml")
            },
            Kirigami.Action {

                text: i18n("Changelogs")
                icon.name: "feed-subscribe-symbolic"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                onTriggered: root.pageStack.initialPage = Qt.resolvedUrl("RssPage.qml")
            },
            Kirigami.Action {
                separator: true
            },
            Kirigami.Action {
                text: i18n("Settings")
                icon.name: "settings-configure-symbolic"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                onTriggered: pageStack.initialPage = Qt.resolvedUrl("Settings.qml")
            },
            Kirigami.Action {
                text: i18nc("About (user's OS)", "About %1", AppConfig.osAboutData.displayName)
                icon.name: "help-about-symbolic"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                onTriggered: root.pageStack.initialPage = Qt.resolvedUrl("AboutDataOS.qml")
            },
            Kirigami.Action {
                text: i18n("About Bazzite Updater")
                icon.name: "help-about-symbolic"

                checkable: true
                QQC2.ActionGroup.group: pageSelector

                onTriggered: root.pageStack.initialPage = Qt.resolvedUrl("AboutDataApp.qml")
            },
            Kirigami.Action {
                separator: true
            },
            Kirigami.Action {
                id: actionReboot
                text: i18n("Reboot System") + GP.Labels.spacer + GP.Labels.north
                icon.name: AppState.commandSucceeded ? "system-shutdown-update-symbolic" : "system-shutdown-symbolic"

                enabled: !AppState.commandRunning

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
                    // A running command is always worth warning about, only the reminder is optional.
                    if (AppState.commandRunning || (AppState.commandSucceeded && UserSettings.showRebootReminder)) {
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

        enabled: !AppState.commandRunning

        activeDialogParent: root

        subtitle: i18n("This will reboot the system.")

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
            interval: 5000
            repeat: false
            onTriggered: root.showPassiveNotification(i18n("The app was unable to reboot. Reboot through your system menu to apply changes."))
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

        activeDialogParent: root

        subtitle: {
            if (!AppState.commandRunning)
                return AppState.commandSucceeded ? i18n("You must reboot to apply changes.") : i18n("No command is running, you may exit.");

            if (AppConfig.ini.Commands?.allowEarlyExit !== "true")
                return i18n("You should not exit the application until the running command completes. If you exit early, it may break your system.");
            else
                return i18n("If you exit the application before the running command completes, it may not apply its changes.");
        }

        QQC2.CheckBox {
            id: skipRebootReminder

            // Only the reminder can be silenced, not the warning about a running command.
            visible: !AppState.commandRunning
            enabled: visible

            text: i18n("Do not show this again") + GP.Labels.spacer + GP.Labels.north

            checked: !UserSettings.showRebootReminder

            onToggled: {
                UserSettings.showRebootReminder = !checked;

                // Assigning to checked drops the binding, put it back
                checked = Qt.binding(() => !UserSettings.showRebootReminder);
            }

            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
        }

        customFooterActions: [
            Kirigami.Action {
                id: confirmExit
                text: i18nc("dialog to exit the application", "Exit") + GP.Labels.spacer + GP.Labels.south
                enabled: AppConfig.ini.Commands?.allowEarlyExit === "true" || !AppState.commandRunning

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
            case 3: // Y
                if (skipRebootReminder.visible)
                    skipRebootReminder.animateClick();
                break;
            }
        }
    }

    pageStack.initialPage: Qt.resolvedUrl("SystemUpdate.qml")
}
