pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater

FormCardCollapsible {

    // TODO: The dropdown does not open smoothly the first time

    id: root
    readonly property var osRelease: AppConfig.osReleaseVarMap()

    buttonText: expanded ? i18nc("button label", "Hide os-release") : i18nc("button label", "Display os-release")

    Component {
        id: textDelegateComponent
        FC.FormTextDelegate {
            // Use a property to pass the dynamic key
            property string key
            text: root.osRelease[key]
            description: key
        }
    }

    Component {
        id: separatorComponent
        FormDelegateSeparatorFixed {}
    }

    ColumnLayout {
        id: dataRoot
        spacing: 0
        clip: true
        Layout.fillWidth: true
    }

    Component.onCompleted: {
        let keys = Object.keys(osRelease);

        for (let i = 0; i < keys.length; i++) {
            let key = keys[i];

            // Create the delegate and parent it directly to root
            let textcomp = textDelegateComponent.createObject(null, {
                "key": key
            });

            dataRoot.data = [...dataRoot.data, textcomp];

            // Create the separator and parent it directly to root
            // (Adding a check here prevents a trailing separator at the very end)
            if (i < keys.length - 1) {
                let sepcomp = separatorComponent.createObject(null);
                dataRoot.data = [...dataRoot.data, sepcomp];
            }
        }
    }
}
