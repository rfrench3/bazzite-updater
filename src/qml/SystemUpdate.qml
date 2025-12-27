// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.bazzite_updater
import org.kde.bazzite_updater.settings as Settings

Kirigami.Page {
    id: page

    title: i18n("Main Page")

    ColumnLayout {
        width: page.width

        anchors.centerIn: parent

        RowLayout {

            Layout.alignment: Qt.AlignHCenter

            Item {
                Layout.alignment: Qt.AlignCenter
                width: Kirigami.Units.gridUnit * 10
                height: Kirigami.Units.gridUnit * 10

                Image {
                    anchors.fill: parent

                    antialiasing: true
                    source: 'qrc:/images/bazzite-logo.svg'
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
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Update System Image and Software")
            onClicked: {
                showPassiveNotification(i18n("Update Started"), Kirigami.short);
                Utils.runUpdate(function(callback) {
                    if (callback != 0) {
                        showPassiveNotification(
                            i18n("Update Failed. Check console for more details."),
                            Kirigami.long,
                            i18n("Open console"),
                            function() {consoleDrawer.drawerOpen = true;}
                            );
                    }
                    else {
                        showPassiveNotification(i18n("Update Succeeded!"), Kirigami.short);
                    }
                });
            }
            enabled: !Utils.blockUpdate && !Utils.updateRunning
        }

        Item {
            Layout.alignment: Qt.AlignCenter
            width: Kirigami.Units.gridUnit * 19
            height: Kirigami.Units.gridUnit * 2

            QQC2.ProgressBar {
                anchors.fill: parent
                from: 0
                to: 100
                value: Utils.progressLevel
                // indeterminate: update_running
            }
        }

        QQC2.Label {
            Layout.alignment: Qt.AlignCenter
            // text: i18n("Current Status: ") + status
            text: i18n("Current Status: ") + Utils.statusText
        }

    }
    actions: [
        Kirigami.Action {
            text: "Toggle Console"
            onTriggered: {consoleDrawer.drawerOpen = !consoleDrawer.drawerOpen;}
        }
    ]

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

                    text: Utils.consoleText
                    font.family: 'monospace'
                    wrapMode: Text.WordWrap
                    readOnly: true
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop

                QQC2.Button {
                    Layout.fillWidth: true
                    text: "Copy to Clipboard"
                    onClicked: {
                        Utils.copyToClipboard(Utils.consoleText);
                        showPassiveNotification(i18n("Text Copied"), Kirigami.short);
                    }
                }

                QQC2.Button {

                    Layout.fillWidth: true
                    text: "Close"
                    onClicked: consoleDrawer.close()
                }
            }
        }
    }
}
