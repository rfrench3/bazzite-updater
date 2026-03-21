// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import app.Gamepad

import QtQuick.Controls

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

    property ScrollBar targetScrollbar: null
    
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
        interval: Math.abs(270000 / Gamepad.rStickMagnitude)
        running: root.targetScrollbar && (Math.abs(Gamepad.rStickMagnitude) > Gamepad.deadzone)
        repeat: true
        onTriggered: {
            if (Gamepad.rStickMagnitude > 0)
                targetScrollbar.increase();
            else
                targetScrollbar.decrease();
        }
    }
}
