import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

FC.FormCard {
    id: root
    readonly property var osRelease: AppConfig.osReleaseVarMap()

    Component {
        id: textDelegateComponent
        FC.FormTextDelegate {
            // Use a property to pass the dynamic key
            property string key
            text: osRelease[key]
            description: key
        }
    }

    Component {
        id: separatorComponent
        FC.FormDelegateSeparator {}
    }

    Component.onCompleted: {
        let keys = Object.keys(osRelease);

        for (let i = 0; i < keys.length; i++) {
            let key = keys[i];

            // Create the delegate and parent it directly to root
            let textcomp = textDelegateComponent.createObject(null, {
                "key": key
            });

            root.delegates = [...root.delegates, textcomp];

            // Create the separator and parent it directly to root
            // (Adding a check here prevents a trailing separator at the very end)
            if (i < keys.length - 1) {
                let sepcomp = separatorComponent.createObject(null);
                root.delegates = [...root.delegates, sepcomp];
            }
        }
    }
}
