import QtQuick
import QtQuick.Layouts
import org.kde.kirigamiaddons.formcard as FC

FC.FormCard {
    id: root
    property string url: ""
    property string image: ""
    property string tag: ""
    property list<string> features: []

    FC.FormTextDelegate {
        visible: root.image || root.tag
        text: i18n("Image: %1:%2", root.image, root.tag)
    }

    FormDelegateSeparatorFixed {
        visible: (root.image || root.tag) && root.url
    }

    FC.FormTextDelegate {
        text: root.features.join(", ")
        description: root.url
        visible: root.url
    }
}
