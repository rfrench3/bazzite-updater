// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls
import io.github.rfrench3.Gamepad

// Only one of the available components is expected to be used
Item {
    id: root

    property Flickable flickable: null
    property ScrollBar scrollBar: null
    property bool active: true
    property real sensitivity: 1

    Timer {
        interval: Gamepad.pollingRate
        running: root.active 
                && (root.scrollBar || root.flickable)
                && (Math.abs(Gamepad.rStickMagnitude) > Gamepad.deadzone)
        repeat: true
        onTriggered: {

            const clamp = (val, min, max) => Math.min(Math.max(val, min), max);

            if (root.scrollBar) 
            {
                const min_pos = 0;
                const max_pos = 1 - root.scrollBar.size;
                const new_pos = root.scrollBar.position + (Gamepad.rStickMagnitude * root.sensitivity / 2700000);

                root.scrollBar.position = clamp(new_pos, min_pos, max_pos);
            }
            else if (root.flickable && root.flickable.contentHeight > root.flickable.height) 
            {
                const min_pos = root.flickable.originY;
                const max_pos = min_pos + root.flickable.contentHeight - root.flickable.height;
                const new_pos = root.flickable.contentY + (Gamepad.rStickMagnitude * root.sensitivity / 2700);

                root.flickable.contentY = clamp(new_pos, min_pos, max_pos);
            }           
            
        }
    }

    Component.onCompleted: {
        if (flickable && scrollBar) 
            console.log("Multiple elements are set at the same time. Only one should be set!");
    }
}
