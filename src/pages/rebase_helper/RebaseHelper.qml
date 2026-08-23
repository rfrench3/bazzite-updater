// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

FC.FormCardPage {
    id: page

    function grabScrollbar(item) {
        if (item.contentItem?.ScrollBar?.vertical)
            return item.contentItem.ScrollBar.vertical;

        if (item.parent)
            return grabScrollbar(item.parent);

        console.warn("Parent scrollbar not found, controller scrolling will not function!");
    }
    property ScrollBar scrollbar: page.grabScrollbar(page)

    title: GP.Labels.east + GP.Labels.spacer_large + i18n("Other Utilities")

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
        targetScrollbar: consoleDrawer.drawerOpen ? null : page.scrollbar
        active: !globalDrawer.drawerOpen
    }

    FC.FormHeader {
        title: i18n("Rollback Last Update")
        visible: rollbackFC.visible
    }

    FC.FormCard {
        id: rollbackFC

        visible: AppConfig.ini.Commands.systemRollbackCommand

        FC.FormTextDelegate {
            text: i18n("This will revert the last update to your system. Your user-level files such as documents and games will not be affected.")
            textItem.wrapMode: Text.Wrap
        }

        FormDelegateSeparatorFixed {}

        FC.FormCheckDelegate {
            id: rollbackConfirm
            text: i18n("Confirm")

            enabled: AppState.allowCommands
        }

        FormDelegateSeparatorFixed {}

        FC.FormButtonDelegate {
            text: i18n("Initiate Rollback")
            enabled: rollbackConfirm.checked && rollbackConfirm.enabled

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

            trailing: BusyIndicator {
                id: rollbackBusyIndicator
                running: AppState.rollbackRunning
            }
            trailingLogo.visible: !rollbackBusyIndicator.running
        }
    }

    FC.FormHeader {
        title: i18n("System Image Information")
        visible: RebaseHelperBackend.currentImage.load_successful
    }
    FCSystemInfo {}

    FC.FormHeader {
        title: i18nc("card to display info from os-release", "Additional Information")
    }
    FCOsRelease {}

    ConsoleDrawer {
        id: consoleDrawer
        model: RebaseHelperBackend.consoleModel
    }
}
