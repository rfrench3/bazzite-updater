// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater

FC.FormCard {
    id: delegate
    required property string updated
    required property string link
    required property string title
    required property string content

    property bool expanded: false

    FC.FormTextDelegate {
        text: "Title: %1<br>Date: %2<br>Link: %3".arg(delegate.title).arg(delegate.updated).arg(`<a href="${delegate.link}">${delegate.link}</a>`)
        textItem.textFormat: Text.RichText
        textItem.wrapMode: Text.Wrap

        textItem.onLinkActivated: url => Qt.openUrlExternally(url)
    }

    FormDelegateSeparatorFixed {}

    FC.FormButtonDelegate {
        id: buttonDelegate
        onClicked: delegate.expanded = !delegate.expanded

        text: i18n("Read more")
        trailingLogo.direction: Qt.ArrowType.DownArrow

        states: State {
            name: "open"
            when: delegate.expanded

            PropertyChanges {
                buttonDelegate.text: i18n("Read less")
                buttonDelegate.trailingLogo.direction: Qt.ArrowType.UpArrow
            }
        }
    }

    FormDelegateSeparatorFixed {
        visible: abstractDelegate.opacity > 0
    }

    FC.AbstractFormDelegate {
        id: abstractDelegate

        clip: true
        visible: opacity > 0
        opacity: 0

        // animation poorly handles using Layout.preferredHeight directly
        property real currentHeight: 0
        Layout.preferredHeight: currentHeight

        states: State {
            name: "open"
            when: delegate.expanded

            PropertyChanges {
                abstractDelegate.opacity: 1
                abstractDelegate.currentHeight: abstractDelegate.implicitHeight
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

        // disable hover/click feedback
        background: Item {
            visible: false
        }

        contentItem: ColumnLayout {
            Text {
                id: contentText
                text: delegate.content
                textFormat: Text.RichText

                Layout.fillWidth: true
                wrapMode: Text.Wrap

                onLinkActivated: url => Qt.openUrlExternally(url)

                HoverHandler {
                    cursorShape: contentText.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
        }
    }
}
