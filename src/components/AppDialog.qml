import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import io.github.rfrench3.Gamepad

Kirigami.PromptDialog {
    id: root
    
    property var activeDialogParent: applicationWindow()
    
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
