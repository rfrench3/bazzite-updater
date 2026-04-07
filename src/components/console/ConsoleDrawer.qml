// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.Gamepad


Kirigami.OverlayDrawer {

    id: root

    required property var model
    property var page: parent

    edge: Qt.BottomEdge

    modal: false
    drawerOpen: false

    height: page.height / 2

    function handleInput(buttonId, button_down) {
        if (!button_down) return;

        switch (buttonId) {
            case 2: // X
                copy.animateClick();
                break;
            case 3: // Y
                close.animateClick();
                break;

        }
    }
    
    contentItem: RowLayout {

        ScrollHandler {
            scrollBar: consoleView.scrollBar
        }
        
        ConsoleView {
            id: consoleView
            model: root.model
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.horizontalStretchFactor: 1
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop

            Button {
                id: copy
                Layout.fillWidth: true
                text: i18n("Copy to Clipboard") + Gamepad.labels.space + Gamepad.labels.x
                onClicked: {
                    root.model.copyToClipboard();
                    showPassiveNotification(i18n("Text Copied"), Kirigami.short);
                }
            }

            Button {
                id: close
                Layout.fillWidth: true
                text: i18n("Close") + Gamepad.labels.space + Gamepad.labels.y
                onClicked: root.close()
            }
        }

    }
}
