// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.formcard as FC

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
        enabled: AppState.allowCommands && !SystemUpdateBackend.blockUpdate && (AppConfig.ini.Commands?.systemUpdateCommand || "")

        onTriggered: {
            sessionStorage.mainText = i18n("System Updating");

            showPassiveNotification(i18n("Update Started"), Kirigami.short);
            SystemUpdateBackend.runUpdate(callback => {
                if (callback != 0) {
                    showPassiveNotification(i18n("Update Failed. Check console for more details."), Kirigami.long, i18n("Open console") + GP.Labels.spacer + GP.Labels.north, () => {
                        consoleDrawer.drawerOpen = true;
                    });
                    sessionStorage.mainText = "";
                    return;
                }

                showPassiveNotification(i18n("Update Succeeded!"), Kirigami.short);
                sessionStorage.updateCompleted = true;
                sessionStorage.mainText = i18n("System Updated!");
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
                text: sessionStorage.mainText || i18n("System Update")
            }
        }

        FC.FormCard {
            id: updateFC

            // Ensures the card does not act like it is width-constrained
            // NOTE: The card's real width is currently bound by the fixed-width progress bar below this FC
            maximumWidth: pageContents.implicitWidth - Kirigami.Units.smallSpacing

            FC.FormButtonDelegate {
                id: updateButton
                text: i18n("Update System Image and Software")
                enabled: updateAction.enabled

                onClicked: updateAction.trigger()

                trailing: Loader {
                    sourceComponent: {
                        if (AppState.updateRunning)
                            return busyComponent;
                        if (AppState.commandSucceeded)
                            return checkmarkComponent;
                        return labelComponent;
                    }

                    Component {
                        id: busyComponent
                        QQC2.BusyIndicator {
                            id: busyIndicator
                            running: AppState.updateRunning
                        }
                    }

                    Component {
                        id: checkmarkComponent
                        Kirigami.Icon {
                            source: "checkmark-symbolic"
                            visible: sessionStorage.updateCompleted || false
                        }
                    }

                    Component {
                        id: labelComponent
                        Kirigami.Heading {
                            text: GP.Labels.south
                        }
                    }
                }

                trailingLogo.visible: !AppState.updateRunning && !AppState.commandSucceeded

                description: {
                    const last_update = i18nc("label, last update to the system.", "Last Update") + ": ";
                    if (sessionStorage.updateCompleted)
                        return last_update + i18n("Right now!");
                    if (RebaseHelperBackend.currentImage.load_successful)
                        return last_update + RebaseHelperBackend.currentImage.datePretty["day"] + " " + RebaseHelperBackend.currentImage.datePretty["month"] + ", " + RebaseHelperBackend.currentImage.datePretty["year"];

                    return "";
                }
            }

            FormDelegateSeparatorFixed {
                visible: errorUpdateNotFound.visible
            }

            FC.FormTextDelegate {
                id: errorUpdateNotFound
                visible: !(AppConfig.ini.Commands?.systemUpdateCommand || "")
                enabled: visible
                text: i18n("The System Update command is not defined.")
                description: i18n("Make sure the config file (/etc/bazzite-updater/config.ini) is present.")
            }
        }

        QQC2.ProgressBar {
            Layout.alignment: Qt.AlignCenter
            implicitWidth: Kirigami.Units.gridUnit * 19

            value: (AppState.commandSucceeded) ? 1.0 : 0.0
            indeterminate: AppState.updateRunning
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
