// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.formcard as FormCard

import io.github.rfrench3.bazzite_updater
import app.Gamepad 1.0
import app.SysUpd 1.0

Kirigami.Page {
    id: page

    // HACK: Global drawer gamepad labels are placed in the page titles
    title: Gamepad.labels.b + Gamepad.labels.space_large + i18n("System Update")

    Connections {
        target: Gamepad

        function onButtonPressed(buttonId) {
            if (appGlobalDrawer.drawerOpen == true)
                return;
            switch (buttonId) {
                case 0: // A
                    updateButton.animateClick();
                    break;
                case 3: // Y
                    toggleConsole.trigger();
                    // TODO: Close passive notifications
                    break;
            }
        }
    }

    Kirigami.Action {
        id: updateAction
        text: i18n("Update System Image and Software") + Gamepad.labels.space + Gamepad.labels.a
        shortcut: "Return"
        enabled: !SysUpd.blockUpdate && !SysUpd.updateRunning

        onTriggered: {
            showPassiveNotification(i18n("Update Started"), Kirigami.short);
            SysUpd.runUpdate(function(callback) {
                if (callback != 0) {
                    showPassiveNotification(
                        i18n("Update Failed. Check console for more details."),
                                            Kirigami.long,
                                            i18n("Open console") + Gamepad.labels.space + Gamepad.labels.y,
                                            function() {consoleDrawer.drawerOpen = true;}
                    );
                }
                else {
                    showPassiveNotification(i18n("Update Succeeded!"), Kirigami.short);
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
                    source: 'qrc:/resources/images/bazzite-logo.svg'
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

        QQC2.Button {
            id: updateButton
            focus: true
            Layout.alignment: Qt.AlignHCenter

            action: updateAction
        }

        Item {
            Layout.alignment: Qt.AlignCenter
            width: Kirigami.Units.gridUnit * 19
            height: Kirigami.Units.gridUnit * 2

            QQC2.ProgressBar {
                anchors.fill: parent
                from: 0
                to: 100
                //TODO: get progress tracker working (system_update.cpp, runUpdate, connect journalctl lambda)
                // value: SysUpd.progressLevel
                // use indeterminate until then
                indeterminate: SysUpd.updateRunning
            }
        }

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
            text: i18n("Current Status: ") + SysUpd.statusText
        }


        Item { Layout.fillHeight: true }

    }
    actions: [
        Kirigami.Action {
            id: toggleConsole
            text: "Toggle Console" + Gamepad.labels.space + Gamepad.labels.y
            shortcut: "F12"
            onTriggered: { consoleDrawer.drawerOpen = !consoleDrawer.drawerOpen; }
        }
    ]

    //TODO: allow the console to expand vertically to fill empty space
    Kirigami.OverlayDrawer {
        id: consoleDrawer
        edge: Qt.BottomEdge

        modal: false
        drawerOpen: false

        contentItem: RowLayout {

            height: parent.height

            QQC2.ScrollView {
                Layout.horizontalStretchFactor: 1
                width: parent.width
                height: parent.height
                Layout.fillWidth: true
                Layout.fillHeight: true

                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                QQC2.TextArea {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    text: SysUpd.consoleText
                    font.family: 'monospace'
                    wrapMode: Text.WordWrap
                    readOnly: true

                    // Scrolls the TextArea to the bottom
                    onTextChanged: { cursorPosition = length; }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop

                QQC2.Button {
                    Layout.fillWidth: true
                    text: i18n("Copy to Clipboard")
                    onClicked: {
                        SysUpd.copyToClipboard(SysUpd.consoleText);
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
