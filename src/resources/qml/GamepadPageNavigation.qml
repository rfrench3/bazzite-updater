// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import app.Gamepad 1.0

/**
 * @brief GamepadPageNavigation - Adds very basic controller support to a page.
 * 
 * This support is applied by emulating tab navigation.
 * - Dpad up: shift+tab
 * - Dpad down: tab
 * - Xbox A (or equivalent): select highlighted element
 * 
 * @note This is disabled when the global drawer is opened
 */
Item {
    id: root
    
    required property Window targetWindow
    
    Connections {
        target: Gamepad

        /**
         * @brief onButtonPressed - Reimplement this separately from GamepadPageNavigation for custom controller navigation.
         * 
         * @param buttonId - SDL3 mapping for controller buttons.
         */
        function onButtonPressed(buttonId) {
            if (appGlobalDrawer.drawerOpen == true)
                return;

            switch (buttonId) {
                case 0: // A
                    root.targetWindow.activeFocusItem.animateClick();
                    break;
                

                //TODO: Display tooltips
                case 11: // Dpad Up
                    let itemUp = root.targetWindow.activeFocusItem.nextItemInFocusChain(false);
                    itemUp.forceActiveFocus(Qt.TabFocusReason);
                    break;

                case 12: // Dpad Down
                    let itemDown = root.targetWindow.activeFocusItem.nextItemInFocusChain(true);
                    itemDown.forceActiveFocus(Qt.TabFocusReason);
                    break;
            }
        }
    }
}
