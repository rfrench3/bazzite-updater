// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import app.Gamepad 1.0

// Component that adds basic controller support to a page.
// (Xbox Layout for example) A selects, dpad up emulates shift+tab, dpad down emulates tab.

Item {
    id: root
    
    required property Window targetWindow
    
    Connections {
        target: Gamepad

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
