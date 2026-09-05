import QtQuick
// import QtQuick.Layouts
import org.kde.kirigamiaddons.formcard as FC

FC.FormCard {
    id: root
    property string url: ""
    property string image: ""
    property string tag: ""

    FC.FormTextDelegate {
        id: urlFD
        visible: root.url
        enabled: visible
        text: i18n("Source: %1", root.url)
    }

    FormDelegateSeparatorFixed {
        visible: urlFD.visible && imgFD.visible
    }

    FC.FormTextDelegate {
        id: imgFD
        visible: root.image
        text: i18n("Image: %1", root.image)
    }

    FormDelegateSeparatorFixed {
        visible: imgFD.visible && tagFD.visible
    }

    FC.FormTextDelegate {
        id: tagFD
        visible: root.tag
        text: i18n("Tag: %1", root.tag)
    }
}
