// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.PromptDialog {
    id: root

    required property var activeDialogParent

    maximumWidth: Kirigami.Units.gridUnit * 20

    Connections {
        target: root

        function onOpened() {
            activeDialogParent.activeDialog = root;
        }

        function onAccepted() {
            activeDialogParent.activeDialog = null;
        }

        function onRejected() {
            activeDialogParent.activeDialog = null;
        }
    }
}
