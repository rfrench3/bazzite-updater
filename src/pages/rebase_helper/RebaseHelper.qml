// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

ScrollingPage {
    id: page

    title: GP.Labels.east + GP.Labels.spacer_large + i18n("Rebase Helper")

    function handleInput(buttonId, button_down) {
        if (button_down == false)
            return;

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

    actions: [
        Kirigami.Action {
            id: toggleConsole
            text: "Toggle Console" + GP.Labels.spacer + GP.Labels.north
            shortcut: "F12"
            onTriggered: consoleDrawer.drawerOpen = !consoleDrawer.drawerOpen
        }
    ]

    GP.PageNavigation {
        targetScrollbar: consoleDrawer.drawerOpen ? null : page.scrollBar
        active: !globalDrawer.drawerOpen
    }

    Kirigami.FormLayout {

        // Rollback Last Update
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Rollback Last Update")
            enabled: AppState.isBrhPresent
        }

        FontMetrics {
            id: sysFont
            font: Qt.application.font
        }

        QQC2.Label {
            // Prevent the form from forcing this into the right-side
            Kirigami.FormData.isSection: true

            // Roughly fit text into 3 rows
            Layout.preferredWidth: sysFont.advanceWidth(text) / 3.0
            wrapMode: Text.Wrap

            text: i18n("This will return your base system to before its current update. Your user files will not be affected, and the system will not automatically update until told to do so again.")
            enabled: AppState.isBrhPresent
        }

        QQC2.CheckBox {
            id: confirmRollback
            // Layout.alignment: Qt.AlignRight
            text: i18n("Confirm")

            enabled: !AppState.rollbackRunning && !AppState.commandSucceeded && AppState.isBrhPresent
        }

        Item {
            Layout.alignment: Qt.AlignHCenter

            implicitWidth: rollbackButton.implicitWidth + (rollbackBusyIndicator.running ? rollbackBusyIndicator.implicitWidth : 0)
            implicitHeight: rollbackButton.implicitHeight

            QQC2.Button {
                id: rollbackButton
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                text: i18n("Rollback") + (AppState.isBrhPresent ? "" : i18n(" (Unavailable)"))

                onClicked: {
                    showPassiveNotification(i18n("Rollback Started"), Kirigami.short);
                    RebaseHelperBackend.rollbackImage(function (callback) {
                        if (callback != 0) {
                            showPassiveNotification(i18n("Rollback Failed."), Kirigami.long, i18n("Open console") + GP.Labels.spacer + GP.Labels.north, consoleDrawer.open);
                        } else {
                            showPassiveNotification(i18n("Rollback Succeeded!"), Kirigami.short);
                        }
                    });
                }

                enabled: AppState.allowCommands && AppState.isBrhPresent && confirmRollback.checked
            }

            QQC2.BusyIndicator {
                id: rollbackBusyIndicator
                anchors.left: rollbackButton.right
                anchors.leftMargin: Kirigami.Units.smallSpacing
                anchors.verticalCenter: rollbackButton.verticalCenter
                running: AppState.rollbackRunning
            }
        }

        // TODO: Make the rebase section intuitive before adding it
        // RebasePart {}
    }

    FC.FormCard {
        visible: brhPresentMessage.visible
        FC.FormTextDelegate {
            id: brhPresentMessage

            visible: text !== ""

            font.bold: true
            textItem.wrapMode: Text.WordWrap

            text: {
                if (!AppState.isBrhPresent)
                    return i18n("Bazzite Rollback Helper is not present on the system. This page's information is still available, but it is otherwise nonfunctional.");
                else if (AppState.isGamescopeSession)
                    return i18n("The app is being run in Steam's Gamescope Session. Switch to Desktop mode to use the System Rebase feature.");
                else
                    return "";
            }
        }
    }

    FC.FormHeader {
        title: i18n("System Image Information")
    }

    FC.FormCard {
        FC.FormTextDelegate {
            textItem.wrapMode: Text.WordWrap
            text: RebaseHelperBackend.currentImage.name + ":" + RebaseHelperBackend.currentImage.branch

            description: i18n("Current Image")
        }

        FC.FormDelegateSeparator {}

        FC.FormTextDelegate {
            textItem.wrapMode: Text.WordWrap
            text: RebaseHelperBackend.currentImage.datePretty["day"] + " " + RebaseHelperBackend.currentImage.datePretty["month"] + ", " + RebaseHelperBackend.currentImage.datePretty["year"]

            description: i18n("Last Update")
        }
    }

    FCSystemInfo {}

    ConsoleDrawer {
        id: consoleDrawer
        model: RebaseHelperBackend.consoleModel
    }
}
