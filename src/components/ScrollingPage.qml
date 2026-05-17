// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

// Current scrollable pages do not expose the scrollbar, which I require for supporting controllers cleanly.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as KG

KG.Page {
    id: page

    default property alias content: innerLayout.data

    readonly property alias scrollBar: vbar

    padding: 0

    ScrollView {
        id: sview
        anchors.fill: parent

        contentWidth: availableWidth


        ScrollBar.vertical: ScrollBar {
            id: vbar
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }

        ColumnLayout {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            width: sview.availableWidth

            Item {
                implicitHeight: KG.Units.largeSpacing
            }

            ColumnLayout {
                id: innerLayout
            }

            Item {
                implicitHeight: KG.Units.largeSpacing
            }
        }
    }
}
