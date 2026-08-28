// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

Kirigami.OverlayDrawer {
    id: root

    required property var model
    property alias extraColumnItems: columnAdditional.data

    edge: Qt.BottomEdge

    modal: false
    drawerOpen: UserSettings.preferConsole

    interactiveResizeEnabled: true

    maximumSize: parent.height - Kirigami.Units.gridUnit * 2.5
    preferredSize: parent.height * 0.5

    function handleInput(buttonId, button_down) {
        if (!button_down)
            return;

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

        GP.ScrollHandler {
            target: consoleView.scrollBar
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
                text: i18n("Copy to Clipboard") + GP.Labels.spacer + GP.Labels.west
                onClicked: {
                    root.model.copyToClipboard();
                    showPassiveNotification(i18n("Text Copied"), Kirigami.short);
                }
            }

            Button {
                id: close
                Layout.fillWidth: true
                text: i18n("Close") + GP.Labels.spacer + GP.Labels.north
                onClicked: root.close()
            }

            ColumnLayout {
                id: columnAdditional
            }
        }
    }
}
