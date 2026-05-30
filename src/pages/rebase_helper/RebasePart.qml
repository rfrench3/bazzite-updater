import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

Kirigami.FormLayout {

    enabled: AppState.isBrhPresent && !AppState.isGamescopeSession

    Kirigami.Separator {
        Kirigami.FormData.label: i18nc("Image, such as referring to Bazzite vs Bazzite-deck", "Rebase to New Image")
        Kirigami.FormData.isSection: true
    }

    QQC2.Label {
        Kirigami.FormData.label: i18n("Recommended images:")
        text: RebaseHelperBackend.recommendedDriver
        // visible: AppState.isBrhPresent && RebaseHelperBackend.recommendedDriver != ""
        visible: RebaseHelperBackend.recommendedDriver != ""
    }

    QtObject {
        id: rebase_selection
        property string name: RebaseHelperBackend.currentImage.name
        property string branch: RebaseHelperBackend.currentImage.branch
        property string image: name + ":" + branch
    }

    // TODO: this works, but ideally it would be a combobox
    QtObject {
        id: imageOptions
        property var allImages: ["bazzite", "bazzite-deck", "bazzite-nvidia", "bazzite-nvidia-open", "bazzite-deck-nvidia", "bazzite-gnome", "bazzite-gnome-nvidia", "bazzite-gnome-nvidia-open", "bazzite-deck-gnome", "bazzite-dx", "bazzite-dx-gnome", "bazzite-dx-nvidia", "bazzite-dx-nvidia-gnome"]
        property var filteredImages: []

        Component.onCompleted: {
            if (RebaseHelperBackend.currentImage.name.indexOf("-gnome") !== -1) {
                filteredImages = allImages.filter(function (img) {
                    return img.indexOf("-gnome") !== -1;
                });
            } else {
                filteredImages = allImages.filter(function (img) {
                    return img.indexOf("-gnome") === -1;
                });
            }
        }
    }

    QQC2.ButtonGroup {
        id: images
    }

    Repeater {
        model: imageOptions.filteredImages

        QQC2.RadioButton {
            Kirigami.FormData.label: index === 0 ? i18nc("Image, such as referring to Bazzite vs Bazzite-deck", "Image Options:") : ""
            text: modelData + additional_text
            QQC2.ButtonGroup.group: images

            property string additional_text: ""

            Component.onCompleted: {
                if (modelData === RebaseHelperBackend.currentImage.name) {
                    checked = true;
                    additional_text = i18n(" (Current)");
                }
            }

            font.bold: modelData === RebaseHelperBackend.currentImage.name

            onClicked: {
                rebase_selection.name = modelData;
            }
            enabled: AppState.isBrhPresent && !AppState.isGamescopeSession
        }
    }

    Item {
        height: Kirigami.Units.smallSpacing
    }

    QQC2.ButtonGroup {
        id: branches
    }

    QQC2.RadioButton {
        id: rebase_branch_stable
        QQC2.ButtonGroup.group: branches
        Kirigami.FormData.label: i18n("Branch:")
        text: i18n("stable")
        font.bold: text === RebaseHelperBackend.currentImage.branch
        Component.onCompleted: {
            if (RebaseHelperBackend.currentImage.branch == "stable")
                checked = true;
        }
        onClicked: {
            rebase_selection.branch = "stable";
        }
        enabled: AppState.isBrhPresent && !AppState.isGamescopeSession
    }
    QQC2.RadioButton {
        id: rebase_branch_testing
        QQC2.ButtonGroup.group: branches
        text: i18n("testing")
        font.bold: text === RebaseHelperBackend.currentImage.branch
        Component.onCompleted: {
            if (RebaseHelperBackend.currentImage.branch == "testing")
                checked = true;
        }
        onClicked: {
            rebase_selection.branch = "testing";
        }
        enabled: AppState.isBrhPresent && !AppState.isGamescopeSession
    }

    // Fallback for misc. other branches
    QQC2.RadioButton {
        id: rebase_branch_unknown
        QQC2.ButtonGroup.group: branches
        text: i18n("do not change") + " (" + RebaseHelperBackend.currentImage.branch + ")"
        font.bold: true

        enabled: false
        visible: false
        Component.onCompleted: {
            if (RebaseHelperBackend.currentImage.branch != "stable" && RebaseHelperBackend.currentImage.branch != "testing") {
                checked = true;
                enabled = AppState.isBrhPresent && !AppState.isGamescopeSession;
                visible = true;
            }
        }

        onClicked: {
            rebase_selection.branch = RebaseHelperBackend.currentImage.branch;
        }
    }

    Item {
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: rebaseButton.implicitWidth + (rebaseBusyIndicator.running ? rebaseBusyIndicator.implicitWidth : 0)
        implicitHeight: rebaseButton.implicitHeight

        QQC2.Button {
            id: rebaseButton
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            text: i18n("Rebase") + (AppState.isBrhPresent ? "" : i18n(" (Unavailable)"))
            enabled: AppState.allowCommands && AppState.isBrhPresent && (RebaseHelperBackend.currentImage.name != rebase_selection.name || RebaseHelperBackend.currentImage.branch != rebase_selection.branch)

            onClicked: {
                showPassiveNotification("Rebase started", Kirigami.short);
                console.log("Rebasing to: " + rebase_selection.image);
                RebaseHelperBackend.rebaseImage(rebase_selection.image, function (callback) {
                    if (callback) {
                        showPassiveNotification(i18n("Rebase failed."), Kirigami.long, i18n("Open console") + GP.Labels.spacer + GP.Labels.north, consoleDrawer.open);
                    } else {
                        showPassiveNotification("Rebase success! Reboot to apply changes.", Kirigami.long);
                    }
                });
            }
        }

        QQC2.BusyIndicator {
            id: rebaseBusyIndicator
            anchors.left: rebaseButton.right
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.verticalCenter: rebaseButton.verticalCenter
            running: AppState.rebaseRunning
        }
    }
}
