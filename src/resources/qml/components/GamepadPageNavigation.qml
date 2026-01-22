// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import app.Gamepad 1.0
import QtTest

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
    
    // Use QtTest functions to implement controller inputs
    TestCase {
        id: inputSimulator
        name: "InputSimulator"
        when: false // Prevents this from running as an actual unit test on startup
        visible: false
    }

    // TODO: (minor) instead of just simulating a click, simulate the press and release
    
    Connections {
        target: Gamepad

        /**
         * @brief onButtonPressed - Reimplement this separately from GamepadPageNavigation for custom controller navigation.
         * @param buttonId - SDL3 mapping for controller buttons.
         */
        function onButtonPressed(buttonId) {
            if (appGlobalDrawer.drawerOpen == true)
                return;

            let item = root.targetWindow.activeFocusItem;

            switch (buttonId) {
                case 0: // A
                    if (_isItemOpenCombobox(item)) {
                        inputSimulator.keyClick(Qt.Key_Enter);
                        break;
                    }


                    if (typeof item.animateClick === "function") {
                        item.animateClick();
                    } else {
                        inputSimulator.mouseClick(item);
                    }
                    break;
                

                //TODO: Display tooltips
                case 11: // Dpad Up

                    if (_isItemOpenCombobox(item)) {
                        inputSimulator.keyClick(Qt.Key_Up)
                        break;
                    }

                    let itemUp = item.nextItemInFocusChain(false);
                    itemUp.forceActiveFocus(Qt.TabFocusReason);
                    break;

                case 12: // Dpad Down

                    if (_isItemOpenCombobox(item)) {
                        inputSimulator.keyClick(Qt.Key_Down)
                        break;
                    }

                    let itemDown = item.nextItemInFocusChain(true);
                    itemDown.forceActiveFocus(Qt.TabFocusReason);
                    break;
            }

            function _isItemOpenCombobox(item) {
                return "currentIndex" in item 
                        && "down" in item
                        && item.down == true;
                }
        }
    }
}