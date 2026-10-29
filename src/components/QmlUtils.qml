// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma Singleton
import QtQuick

QtObject {
    id: root

    /**
     * @brief getParentOfType - Return the first parent of item that is a type, or null.
     * @param item
     * @param type
     */
    function getParentOfType(item: Item, type: var, __first = true): Item {
        if (!__first && item instanceof type)
            return item;
        if (item.parent)
            return getParentOfType(item.parent, type, false);
        return null;
    }

    function isDescendentOf(item: Item, possible_parent: Item): bool {
        if (item === null)
            return false;
        if (item.parent === possible_parent)
            return true;
        return isDescendentOf(item.parent, possible_parent);
    }
}
