// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.formcard as FormCard

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

Kirigami.Page {
    id: page

    // HACK: Global drawer gamepad labels are placed in the page titles
    title: GP.Labels.east + GP.Labels.spacer_large + i18n("System Update")

    function handleInput(buttonId, button_down) {
        if (button_down == false)
            return;

        switch (buttonId) {
        case 0: // A
            updateButton.animateClick();
            return;
        }

        if (consoleDrawer.drawerOpen) {
            consoleDrawer.handleInput(buttonId, button_down);
            return;
        }

        switch (buttonId) {
        case 3: // Y
            toggleConsole.trigger();
            // Closes up to 5 passive notifications
            for (let i = 0; i < 5; ++i) {
                hidePassiveNotification();
            }
            break;
        }
    }

    Kirigami.Action {
        id: updateAction
        text: i18n("Update System Image and Software") + GP.Labels.spacer + GP.Labels.south
        shortcut: "Return"
        enabled: AppState.allowCommands && !SystemUpdateBackend.blockUpdate

        onTriggered: {
            showPassiveNotification(i18n("Update Started"), Kirigami.short);
            SystemUpdateBackend.runUpdate(callback => {
                if (callback != 0) {
                    showPassiveNotification(i18n("Update Failed. Check console for more details."), Kirigami.long, i18n("Open console") + GP.Labels.spacer + GP.Labels.north, () => {
                        consoleDrawer.drawerOpen = true;
                    });
                    return;
                }

                showPassiveNotification(i18n("Update Succeeded!"), Kirigami.short);
            });
        }
    }

    Kirigami.Action {
        id: updateFlatpakNVRuntime
        text: i18n("Update Nvidia Flatpak Runtime") + GP.Labels.spacer + GP.Labels.south
        shortcut: "Return"
        enabled: AppState.allowCommands && !SystemUpdateBackend.blockUpdate && SystemUpdateBackend.hasNvidiaGpu

        onTriggered: {
            showPassiveNotification(i18n("Update Started"), Kirigami.short);
            SystemUpdateBackend.runNvidiaFlatpakUpdate(callback => {
                if (callback != 0) {
                    showPassiveNotification(i18n("Update Failed. Check console for more details."), Kirigami.long, i18n("Open console") + GP.Labels.spacer + GP.Labels.north, () => {
                        consoleDrawer.drawerOpen = true;
                    });
                    return;
                }

                showPassiveNotification(i18n("Update Succeeded!"), Kirigami.short);
            });
        }
    }

    ColumnLayout {
        id: pageContents
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        spacing: Kirigami.Units.gridUnit

        RowLayout {
            Layout.alignment: Qt.AlignHCenter

            Item {
                implicitWidth: Kirigami.Units.gridUnit * 5
                implicitHeight: implicitWidth

                Image {
                    anchors.fill: parent

                    antialiasing: true
                    source: (AppConfig.osAboutData.programLogo) ? "file:/" + AppConfig.osAboutData.programLogo : "qrc:/fallbackLogo"
                    sourceSize.width: 1024
                    sourceSize.height: 1024
                }
            }

            Kirigami.Heading {
                text: i18n("System Update")
            }
        }

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
            Layout.alignment: Qt.AlignHCenter

            visible: SystemUpdateBackend.hasNvidiaGpu
            implicitWidth: updateFlatpakNVRuntimeButton.implicitWidth + (busyIndicator2.running ? busyIndicator2.implicitWidth : 0)
            implicitHeight: updateFlatpakNVRuntimeButton.implicitHeight
            QQC2.Button {
                id: updateFlatpakNVRuntimeButton
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                action: updateFlatpakNVRuntime
            }

            QQC2.BusyIndicator {
                id: busyIndicator2
                anchors.left: updateFlatpakNVRuntimeButton.right
                anchors.leftMargin: Kirigami.Units.smallSpacing
                anchors.verticalCenter: updateFlatpakNVRuntimeButton.verticalCenter
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
            text: {
                i18n("Last Update: ") + RebaseHelperBackend.currentImage.datePretty["day"] + " " + RebaseHelperBackend.currentImage.datePretty["month"] + ", " + RebaseHelperBackend.currentImage.datePretty["year"];
            }
        }
    }

    actions: [
        Kirigami.Action {
            id: toggleConsole
            text: "Toggle Console" + GP.Labels.spacer + GP.Labels.north
            shortcut: "F12"
            onTriggered: consoleDrawer.drawerOpen = !consoleDrawer.drawerOpen
        }
    ]

    ConsoleDrawer {
        id: consoleDrawer
        model: SystemUpdateBackend.consoleModel
    }
}
