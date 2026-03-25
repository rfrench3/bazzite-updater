// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.formcard as FormCard

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.Gamepad

Kirigami.Page {
    id: page

    // HACK: Global drawer gamepad labels are placed in the page titles
    title: Gamepad.labels.b + Gamepad.labels.space_large + i18n("System Update")

    Connections {
        target: Gamepad

        function onButtonPressed(buttonId, button_down) {
            if (button_down == false)
                return;

            if (appGlobalDrawer.drawerOpen == true)
                return;
            switch (buttonId) {
                case 0: // A
                    updateButton.animateClick();
                    break;
                case 2: // X
                    if (consoleDrawer.drawerOpen)
                        copy_button.animateClick();
                    break;
                case 3: // Y
                    toggleConsole.trigger();
                    // Closes up to 5 passive notifications
                    for (let i = 0; i < 5; ++i) {
                        hidePassiveNotification();
                    }
                    break;
            }
        }
    }

    

    Kirigami.Action {
        id: updateAction
        text: i18n("Update System Image and Software") + Gamepad.labels.space + Gamepad.labels.a
        shortcut: "Return"
        enabled: AppState.allowCommands && !SystemUpdateBackend.blockUpdate

        onTriggered: {
            showPassiveNotification(i18n("Update Started"), Kirigami.short);
            SystemUpdateBackend.runUpdate(function(callback) {
                if (callback == 0) {
                    showPassiveNotification(i18n("Update Succeeded!"), Kirigami.short);
                    return;
                }

                showPassiveNotification(
                    i18n("Update Failed. Check console for more details."),
                    Kirigami.long,
                    i18n("Open console") + Gamepad.labels.space + Gamepad.labels.y,
                    function() {consoleDrawer.drawerOpen = true;}
                    ); 
            }, function(errorJson) {
                // This function is only called if part of the update has failed
                try {
                    let errors = JSON.parse(errorJson);
                    let message = i18n("Some update modules failed:\n");
        
                    if (errors.System_Update) {
                        message += i18n("System Update\n");
                    }
                    if (errors.Brew_Update) {
                        message += i18n("Brew Update\n");
                    }
                    if (errors.System_Apps) {
                        message += i18n("System Flatpak Apps\n");
                    }
                    if (errors.Apps_for_User) {
                        message += i18n("User Flatpak Apps\n");
                    }
                    if (errors.Distroboxes_for_User) {
                        message += i18n("User Distroboxes\n");
                    }
                    if (errors.Unknown_Error) {
                        message += i18n("Unknown (Please send the error logs!)\n");
                    }
                    
                    if (message.endsWith("\n")) {
                        message = message.slice(0, -1);
                    }
                    showPassiveNotification(message, Kirigami.long);

                } catch (e) {
                    console.error("Failed to parse error JSON:", e);
                }
            });
        }
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {

            Layout.alignment: Qt.AlignHCenter

            Item {
                Layout.alignment: Qt.AlignCenter
                width: Kirigami.Units.gridUnit * 10
                height: Kirigami.Units.gridUnit * 10

                Image {
                    anchors.fill: parent

                    antialiasing: true
                    source: "qrc:/osLogo"
                    sourceSize.width: 1024
                    sourceSize.height: 1024
                }
            }

            Kirigami.Heading {
                Layout.alignment: Qt.AlignCenter
                text: i18n("System Update")
            }
        }

        Item { height: Kirigami.Units.gridUnit } // Vertical Spacer

        Item {
            Layout.alignment: Qt.AlignHCenter
            
            implicitWidth: updateButton.implicitWidth + (busyIndicator.running ? busyIndicator.implicitWidth : 0)
            implicitHeight: updateButton.implicitHeight
            QQC2.Button {
                id: updateButton
                focus: true
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                action: updateAction
            }

            QQC2.BusyIndicator {
                id: busyIndicator
                anchors.left: updateButton.right
                anchors.leftMargin: Kirigami.Units.smallSpacing
                anchors.verticalCenter: updateButton.verticalCenter
                running: AppState.updateRunning
            }
        }

        Item {
            Layout.alignment: Qt.AlignCenter
            width: Kirigami.Units.gridUnit * 19
            height: Kirigami.Units.gridUnit * 2

            QQC2.ProgressBar {
                anchors.fill: parent
                from: 0
                to: 100

                indeterminate: AppState.updateRunning
            }
        }

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
            text: i18n("Current Status: ") + SystemUpdateBackend.statusText
        }

        Item { height: Kirigami.Units.gridUnit } // Vertical Spacer

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
            text: {
                i18n("Last Update: ") 
                + RebaseHelperBackend.currentImage.datePretty["day"]
                + " "
                + RebaseHelperBackend.currentImage.datePretty["month"]
                + ", "
                + RebaseHelperBackend.currentImage.datePretty["year"];
            }
        }

        Item { Layout.fillHeight: true }

    }
    actions: [
        Kirigami.Action {
            id: toggleConsole
            text: "Toggle Console" + Gamepad.labels.space + Gamepad.labels.y
            shortcut: "F12"
            onTriggered: consoleDrawer.drawerOpen = !consoleDrawer.drawerOpen
        }
    ]

    Kirigami.OverlayDrawer {
        id: consoleDrawer
        edge: Qt.BottomEdge

        modal: false
        drawerOpen: false

        height: page.height / 2
        

        contentItem: RowLayout {
            Timer {
                interval: Gamepad.pollingRate
                running: consoleDrawer.drawerOpen && (Math.abs(Gamepad.rStickMagnitude) > Gamepad.deadzone)
                repeat: true
                onTriggered: {
                    let new_pos = consoleView.currentIndex + Math.round(Gamepad.rStickMagnitude / 27000);

                    if (new_pos < 0)
                        consoleView.currentIndex = 0;
                    else if (new_pos >= consoleView.length)
                        consoleView.currentIndex = consoleView.length - 1;
                    else
                        consoleView.currentIndex = new_pos;
                }
            }
            
            ConsoleView {
                id: consoleView
                model: SystemUpdateBackend.consoleModel
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.horizontalStretchFactor: 1
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop

                QQC2.Button {
                    id: copy_button
                    Layout.fillWidth: true
                    text: i18n("Copy to Clipboard") + Gamepad.labels.space + Gamepad.labels.x
                    onClicked: {
                        SystemUpdateBackend.copyToClipboard();
                        showPassiveNotification(i18n("Text Copied"), Kirigami.short);
                    }
                }

                QQC2.Button {

                    Layout.fillWidth: true
                    text: i18n("Close") + Gamepad.labels.space + Gamepad.labels.y
                    onClicked: consoleDrawer.close()
                }
            }

        }
    }

}
