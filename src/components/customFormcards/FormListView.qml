// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as KG

// Contains code necessary for controller support to work.
// TODO: Redo controller support and then redo/remove most/all of this
ListView {
    id: root

    signal listViewFocused(ListView view)

    property real maxListHeight: KG.Units.gridUnit * 16
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(contentHeight, root.maxListHeight)
    clip: true

    currentIndex: 0
    highlightFollowsCurrentItem: true
    highlightMoveDuration: 0
    highlightRangeMode: ListView.NoHighlightRange
    activeFocusOnTab: true

    onActiveFocusChanged: activeFocus ? listViewFocused(this) : listViewFocused(null)

    // TODO: this just matches the current onHover appearance of a formcard button,
    //  ideally the button would just act like it's being hovered over
    highlight: Rectangle {
        color: KG.Theme.textColor
        opacity: root.activeFocus ? 0.07 : 0
    }

    // Keep the current item scrolled into view whenever it changes,
    // regardless of what changed it (Tab, arrows, mouse).
    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

    KG.WheelHandler {
        target: root
    }

    QQC2.ScrollBar.vertical: QQC2.ScrollBar {
        id: vbar
        policy: QQC2.ScrollBar.AlwaysOn
    }
    readonly property real scrollbarWidth: vbar.visible ? vbar.width : 0
    readonly property var scrollbar: vbar
}
