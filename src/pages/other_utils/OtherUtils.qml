// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

AppPage {
    id: page

    title: GP.Labels.east + GP.Labels.spacer_large + i18n("Other Utilities")

    drawer: consoleDrawer
    actionToggleDrawer: toggleConsole

    actions: [
        Kirigami.Action {
            id: toggleConsole
            text: i18n("Toggle Console") + GP.Labels.spacer + GP.Labels.north
            shortcut: "F12"
            onTriggered: consoleDrawer.drawerOpen = !consoleDrawer.drawerOpen
        }
    ]

    GP.ScrollHandler {
        target: page.focusedViewCard ? getScrollbar(page.focusedViewCard) : page.scrollBar
        active: !globalDrawer.drawerOpen && !consoleDrawer.drawerOpen

        function getScrollbar(item) {
            if (!item)
                return page.scrollBar;
            if (item instanceof ListView)
                return item.scrollbar;
            if (item.parent)
                return getScrollbar(item.parent);
        }
    }

    // If a ScrollView of a FCSystemImage is focused, it is stored here
    property Item focusedViewCard: null

    // TODO: Fully replace this when possible
    Item {
        id: gamepadRoot

        property bool active: visible

        Connections {
            target: GP.Gamepad

            function keyEvent(button_down, key) {
                let item = gamepadRoot.Window.window.activeFocusItem;
                if (button_down == true) {
                    // console.log("button down");
                    GP.Gamepad.sendButtonPressed(item, key);
                } else {
                    // console.log("button up");
                    GP.Gamepad.sendButtonReleased(item, key);
                }
            }

            function mouseEvent(button_down, item = gamepadRoot.Window.window.activeFocusItem) {
                if (button_down == true) {
                    GP.Gamepad.sendMousePressed(item);
                    // console.log("mouse down");
                } else {
                    GP.Gamepad.sendMouseReleased(item);
                    // console.log("mouse up");
                }
            }

            function onButtonEvent(buttonId, pressed) {
                if (!gamepadRoot.active)
                    return;

                if (globalDrawer.drawerOpen || consoleDrawer.drawerOpen)
                    return;

                let item = gamepadRoot.Window.window.activeFocusItem;

                switch (buttonId) {
                case 0: // A
                    mouseEvent(pressed);
                    break;
                }
            }
        }

        function __descendantOfParent(item) {
            let cursor = item;
            while (cursor) {
                if (cursor === gamepadRoot.parent)
                    return true;
                cursor = cursor.parent;
            }
            return false;
        }

        function __nextItemInScope(item, forward) {
            if (!item)
                return null;

            let next = item.nextItemInFocusChain(forward);

            for (let i = 0; i < 512; i++) {
                if (__descendantOfParent(next))
                    return next;
                next = next.nextItemInFocusChain(forward);
            }

            console.log("Next item in focus scope not found after 512 tries, returning original item.");

            return item;
        }
    }

    function moreHandleInput(buttonId: int, button_down: bool): bool {
        if (!button_down)
            return false;

        if (globalDrawer.drawerOpen || consoleDrawer.drawerOpen)
            return false;

        const focused = Window.activeFocusItem;
        let card = QmlUtils.getParentOfType(focused, FC.FormCard);
        if (typeof card?.closeActiveListView !== "function")
            card = null;

        switch (buttonId) {
        case 1: // B
            return card ? card.closeActiveListView() : false;
        case 11: // Dpad Up
        case 12:
            { // Dpad Down
                const down = buttonId === 12;
                if (card && (down ? card.incrementListView() : card.decrementListView()))
                    return true;

                const grid = QmlUtils.getParentOfType(focused, NavGrid);
                let start = focused;
                if (grid) {
                    if (grid.moveVertical(focused, down))
                        return true;
                    // Start the focus-chain search from the grid's first/last button so we
                    // exit the grid instead of stepping to the next button in the same row
                    start = grid.edgeChild(down);
                }

                // List absent or at its end: move focus normally
                const next = gamepadRoot.__nextItemInScope(start, down);
                if (next)
                    next.forceActiveFocus(Qt.TabFocusReason);
                return true;
            }
        case 13:
        case 14:
            { // Dpad left/right
                const right = buttonId === 14;

                const grid = QmlUtils.getParentOfType(focused, NavGrid);
                if (grid) {
                    grid.moveHorizontal(focused, right);
                    return true;
                }

                const next = gamepadRoot.__nextItemInScope(focused, right);
                if (next)
                    next.forceActiveFocus(Qt.TabFocusReason);
                return true;
            }
        }
        return false;
    }

    AsyncLoader {
        sourceComponent: PageContentLayout {

            FC.FormHeader {
                title: i18n("Rollback Last Update")
                visible: rollbackFC.visible
            }

            FC.FormCard {
                id: rollbackFC

                visible: AppConfig.ini.Commands.systemRollbackCommand || ""

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
                        OtherUtilsBackend.rollbackImage(function (callback) {
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
                title: i18n("Layered Packages")
                visible: layeredPackagesFC.visible
            }
            FCLayeredPackages {
                id: layeredPackagesFC

                onListViewFocused: item => {
                    page.focusedViewCard = item;
                }

                onRpmOstreeRemoveClicked: packages => {
                    OtherUtilsBackend.rpmOstreeRemove(packages, exit => {
                        if (exit === 0)
                            showPassiveNotification(i18n("If those layered packages caused updates to fail, you should now be able to update successfully."), Kirigami.short);
                        else
                            showPassiveNotification(i18n("Removing layered packages failed. Check console for more details."), Kirigami.long, i18n("Open console") + GP.Labels.spacer + GP.Labels.north, () => {
                                toggleConsole.trigger();
                            });
                    });
                }

                onRpmOstreeResetClicked: {
                    OtherUtilsBackend.rpmOstreeReset(exit => {
                        if (exit === 0)
                            showPassiveNotification(i18n("If layered packages caused updates to fail, you should now be able to update successfully."), Kirigami.short);
                        else
                            showPassiveNotification(i18n("Removing layered packages failed. Check console for more details."), Kirigami.long, i18n("Open console") + GP.Labels.spacer + GP.Labels.north, () => {
                                toggleConsole.trigger();
                            });
                    });
                }
            }

            FC.FormHeader {
                title: i18n("System Image Information")
                visible: OtherUtilsBackend.currentImage.load_successful
            }
            FCSystemInfo {}

            FC.FormHeader {
                title: i18n("General Utilities")
                visible: addToSteamFC.visible
            }
            FC.FormCard {
                id: addToSteamFC

                visible: OtherUtilsBackend.addToSteamAvailable

                FC.FormButtonDelegate {
                    id: steamButton
                    text: i18n("Add Bazzite Updater to your Steam library")
                    description: i18n("You will need to restart Steam if it is running for Bazzite Updater to appear in your library.")
                    enabled: !OtherUtilsBackend.consoleModel.processRunning && !__ran
                    property bool __ran: false

                    onClicked: {
                        OtherUtilsBackend.addToSteam(function (callback) {
                            __ran = true;
                            if (callback != 0) {
                                showPassiveNotification(i18n("Adding Bazzite Updater to Steam Failed."), Kirigami.long, i18n("Open console") + GP.Labels.spacer + GP.Labels.north, consoleDrawer.open);
                            } else {
                                showPassiveNotification(i18n("Adding Bazzite Updater to Steam Succeeded!"), Kirigami.short);
                            }
                        });
                    }

                    trailing: BusyIndicator {
                        id: steamBusy
                        running: !steamButton.enabled && !steamButton.__ran
                    }
                    trailingLogo.visible: !steamBusy.running
                }
            }

            FC.FormHeader {
                title: i18nc("card to display info from os-release", "Additional Information")
            }
            FCOsRelease {}
        }
    }

    ConsoleDrawer {
        id: consoleDrawer
        model: OtherUtilsBackend.consoleModel
    }
}
