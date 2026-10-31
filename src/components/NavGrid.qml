// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// TODO: replace/rework this when Controllable is overhauled
// Grid Layout with support for the controllable navigation
GridLayout {
    // `from` may be the button itself or a descendant of it
    function indexOfChild(from: Item): int {
        let cursor = from;
        while (cursor && cursor.parent !== this)
            cursor = cursor.parent;
        return visibleChildren.indexOf(cursor);
    }

    // First (up) or last (down) visible button, used as the exit point
    function edgeChild(down: bool): Item {
        return down ? visibleChildren[visibleChildren.length - 1] : visibleChildren[0];
    }

    // Move focus to the button left/right of `from`, staying within its row.
    function moveHorizontal(from: Item, right: bool): void {
        const index = indexOfChild(from);
        if (index < 0)
            return;

        const target = index + (right ? 1 : -1);
        if (target < 0 || target >= visibleChildren.length)
            return;

        // Don't wrap onto the previous/next row
        if (Math.floor(target / columns) !== Math.floor(index / columns))
            return;

        visibleChildren[target].forceActiveFocus(Qt.TabFocusReason);
    }

    // Move focus one row up/down in the same column.
    // Returns false when there is no row in that direction, so the caller can leave the grid.
    function moveVertical(from: Item, down: bool): bool {
        const index = indexOfChild(from);
        if (index < 0)
            return false;

        let target = index + (down ? columns : -columns);

        if (target < 0)
            return false;

        if (target >= visibleChildren.length) {
            // A shorter last row has no button directly below: land on its last button
            const lastRow = Math.floor((visibleChildren.length - 1) / columns);
            if (Math.floor(index / columns) >= lastRow)
                return false;
            target = visibleChildren.length - 1;
        }

        visibleChildren[target].forceActiveFocus(Qt.TabFocusReason);
        return true;
    }
}
