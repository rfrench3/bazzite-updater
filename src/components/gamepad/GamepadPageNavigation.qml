// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import io.github.rfrench3.Gamepad

import QtQuick.Controls
import org.kde.kirigami as Kirigami

/**
 * @brief GamepadPageNavigation - Adds very basic controller support to a page.
 * 
 * This support is applied by emulating tab navigation.
 * - Dpad/LStick up: shift+tab
 * - Dpad/Lstick down: tab
 * - Xbox A (or equivalent): select highlighted element
 * 
 * @note This is disabled when the global drawer is opened
 */
Item {
    id: root
    
    required property Window targetWindow

    // When given a scroll bar, the right stick will smoothly scroll through it
    property ScrollBar targetScrollbar: null

    property var targetScrollable: null

    Component.onCompleted: {
        if (targetScrollable && !targetScrollbar)
            grabScrollbar(targetScrollable);
    }

    // NOTE: If scrolling breaks in the future, its probably this
    function grabScrollbar(item) {
        if (item instanceof Kirigami.ScrollablePage) {

            if (
                item.contentItem
                && item.contentItem.ScrollBar
                && item.contentItem.ScrollBar.vertical
            ) {
                Qt.callLater(() => {root.targetScrollbar = item.contentItem.ScrollBar.vertical;});
            } 
            else
                console.log("Parent scrollbar not found, controller scrolling will not function!");
        }
        else {
            if (item.parent)
                grabScrollbar(item.parent);
            else 
                console.log("Parent Kirigami.ScrollablePage not found, controller scrolling will not function!");
        }
    }
    
    Connections {
        target: Gamepad

        function keyEvent(button_down, key) {
            let item = root.targetWindow.activeFocusItem;
            if (button_down == true) {
                // console.log("button down");
                Gamepad.sendButtonPressed(item, key);
            }
            else {
                // console.log("button up");
                Gamepad.sendButtonReleased(item, key);
            }
        }

        function mouseEvent(button_down, item = root.targetWindow.activeFocusItem) {
            if (button_down == true) {
                Gamepad.sendMousePressed(item);
                // console.log("mouse down");
            }
            else {
                Gamepad.sendMouseReleased(item);
                // console.log("mouse up");
            }
        }

        /**
         * @brief onButtonPressed - Reimplement this separately from GamepadPageNavigation for custom controller navigation.
         * @param buttonId - SDL3 mapping for controller buttons.
         * @param button_down - true is button is being pressed, false if button is being released.
         */
        function onButtonPressed(buttonId, button_down) {
            if (appGlobalDrawer.drawerOpen == true)
                return;

            let item = root.targetWindow.activeFocusItem;

            switch (buttonId) {
                case 0: // A
                    mouseEvent(button_down);
                    break;
                
                case 11: // Dpad Up
                    if (!button_down) break;

                    let itemUp = item.nextItemInFocusChain(false);
                    itemUp.forceActiveFocus(Qt.TabFocusReason);
                    break;

                case 12: // Dpad Down
                    if (!button_down) break;

                    let itemDown = item.nextItemInFocusChain(true);
                    itemDown.forceActiveFocus(Qt.TabFocusReason);
                    break;
            }
        }
    }

    Timer {
        interval: Gamepad.pollingRate
        running: root.targetScrollbar && (Math.abs(Gamepad.rStickMagnitude) > Gamepad.deadzone)
        repeat: true
        onTriggered: {

            const clamp = (val, min, max) => Math.min(Math.max(val, min), max);

            const min_pos = 0;
            const max_pos = 1 - root.targetScrollbar.size;
            const new_pos = root.targetScrollbar.position + (Gamepad.rStickMagnitude / 2700000);

            root.targetScrollbar.position = clamp(new_pos, min_pos, max_pos);
        }
    }
}
