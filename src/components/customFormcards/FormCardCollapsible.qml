// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

FC.FormCard {
    id: root

    property Component topComponent: null
    property bool expanded: false

    property string buttonText: ""

    default property alias childElements: internalLayout.data

    Loader {
        id: topLoader
        Layout.fillWidth: true

        enabled: root.topComponent !== null
        visible: enabled

        sourceComponent: root.topComponent
    }

    FormDelegateSeparatorFixed {
        visible: topLoader.visible
    }

    FC.FormButtonDelegate {
        id: buttonDelegate
        onClicked: root.expanded = !root.expanded

        text: root.buttonText || i18n("Read more")
        trailingLogo.direction: Qt.ArrowType.DownArrow

        states: State {
            name: "open"
            when: root.expanded

            PropertyChanges {
                buttonDelegate.text: root.buttonText || i18n("Read less")
                buttonDelegate.trailingLogo.direction: Qt.ArrowType.UpArrow
            }
        }
    }

    FormDelegateSeparatorFixed {
        visible: internalLayout.opacity > 0
    }

    ColumnLayout {
        id: internalLayout
        clip: true
        visible: opacity > 0
        opacity: 0
        spacing: 0
        Layout.fillWidth: true

        // animation poorly handles using Layout.preferredHeight directly
        property real currentHeight: 0
        Layout.preferredHeight: currentHeight
        // implicitHeight

        states: State {
            name: "open"
            when: root.expanded

            PropertyChanges {
                internalLayout.opacity: 1
                internalLayout.currentHeight: internalLayout.implicitHeight
            }
        }

        transitions: Transition {
            to: "open"
            reversible: true

            ParallelAnimation {
                PropertyAnimation {
                    property: "currentHeight"
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
                PropertyAnimation {
                    property: "opacity"
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
