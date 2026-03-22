// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import app.Gamepad
import app.RebaseHelper 1.0
import app.State 1.0

FC.FormCardPage {
    id: page

    title: Gamepad.labels.b + Gamepad.labels.space_large + i18n("Rebase Helper")

    GamepadPageNavigation { 
        targetWindow: page.Window.window 
        targetScrollable: page
    }

    Layout.topMargin: Kirigami.Units.largeSpacing * 4

    // TODO: Fit the rest of this page into formcards
    Kirigami.FormLayout {

        // Rollback Last Update
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Rollback Last Update")
            // level: 2
        }

        QQC2.Label {
            Kirigami.FormData.isSection: true

            // attempt to fill 3 rows, if set to exactly 3 then a word usually overhangs into a 4th row
            Layout.preferredWidth: implicitWidth / 2.5

            wrapMode: Text.Wrap
            // horizontalAlignment: Text.AlignJustify
            text: i18n("This will return your base system to before its current update. Your user files will not be affected, and the system will not automatically update until told to do so again.")
        }

        QQC2.CheckBox {
            id: confirmRollback
            // Layout.alignment: Qt.AlignRight
            text: i18n("Confirm")

            enabled: !AppState.rollbackRunning
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            
            implicitWidth: rollbackButton.implicitWidth + (rollbackBusyIndicator.running ? rollbackBusyIndicator.implicitWidth : 0)
            implicitHeight: rollbackButton.implicitHeight
            
            QQC2.Button {
                id: rollbackButton
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                
                text: i18n("Rollback")
                
                onClicked: {
                    showPassiveNotification(i18n("Rollback Started"), Kirigami.short);
                    RebaseHelper.rollbackImage(function(callback) {
                        if (callback != 0) {
                            showPassiveNotification(i18n("Rollback Failed."), Kirigami.long);
                        }
                        else {
                            showPassiveNotification(i18n("Rollback Succeeded!"), Kirigami.short);
                        }
                    });
                }

                enabled: AppState.allowCommands && confirmRollback.checked
            }

            QQC2.BusyIndicator {
                id: rollbackBusyIndicator
                anchors.left: rollbackButton.right
                anchors.leftMargin: Kirigami.Units.smallSpacing
                anchors.verticalCenter: rollbackButton.verticalCenter
                running: AppState.rollbackRunning
            }
        }

        // System Rebase
        
        Kirigami.Separator {
            Kirigami.FormData.label: i18nc("Image, such as referring to Bazzite vs Bazzite-deck", "Rebase to New Image")
            Kirigami.FormData.isSection: true
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Recommended images:")
            text: RebaseHelper.recommendedDriver
            visible: RebaseHelper.recommendedDriver != ""
        }
        
        QtObject {
            id: rebase_selection
            property string name: RebaseHelper.currentImage.name
            property string branch: RebaseHelper.currentImage.branch
            property string image: name + ":" + branch
        }

        // TODO: this works, but ideally it would be a combobox 
        QtObject {
            id: imageOptions
            property var allImages: [
                "bazzite",
                "bazzite-deck",
                "bazzite-nvidia",
                "bazzite-nvidia-open",
                "bazzite-deck-nvidia",
                "bazzite-gnome",
                "bazzite-gnome-nvidia",
                "bazzite-gnome-nvidia-open",
                "bazzite-deck-gnome",
                "bazzite-dx",
                "bazzite-dx-gnome",
                "bazzite-dx-nvidia",
                "bazzite-dx-nvidia-gnome"
            ]
            property var filteredImages: []

            Component.onCompleted: {
                if (RebaseHelper.currentImage.name.indexOf("-gnome") !== -1) {
                    filteredImages = allImages.filter(function(img) { return img.indexOf("-gnome") !== -1; });
                } else {
                    filteredImages = allImages.filter(function(img) { return img.indexOf("-gnome") === -1; });
                }
            }
        }
        
        QQC2.ButtonGroup { id:images }

        Repeater {
            model: imageOptions.filteredImages

            QQC2.RadioButton {
                Kirigami.FormData.label: index === 0 ? i18nc("Image, such as referring to Bazzite vs Bazzite-deck", "Image Options:") : ""
                text: modelData + additional_text
                QQC2.ButtonGroup.group: images

                property string additional_text: ""
                
                Component.onCompleted: {
                    if (modelData === RebaseHelper.currentImage.name) {
                        checked = true;
                        additional_text = i18n(" (Current)");
                    }
                }
                
                font.bold: modelData === RebaseHelper.currentImage.name
                
                onClicked: {
                    rebase_selection.name = modelData;
                }
            }
        }

        Item { height: Kirigami.Units.smallSpacing }

        QQC2.ButtonGroup { id:branches }

        QQC2.RadioButton {
            id: rebase_branch_stable
            QQC2.ButtonGroup.group: branches
            Kirigami.FormData.label: i18n("Branch:")
            text: i18n("stable")
            font.bold: text === RebaseHelper.currentImage.branch
            Component.onCompleted: {
                if (RebaseHelper.currentImage.branch == "stable")
                    checked = true;
            }
            onClicked: {
                rebase_selection.branch = "stable";
            }
        }
        QQC2.RadioButton {
            id: rebase_branch_testing
            QQC2.ButtonGroup.group: branches
            text: i18n("testing")
            font.bold: text === RebaseHelper.currentImage.branch
            Component.onCompleted: {
                if (RebaseHelper.currentImage.branch == "testing")
                    checked = true;
            }
            onClicked: {
                rebase_selection.branch = "testing";
            }
        }

        // Fallback for misc. other branches
        QQC2.RadioButton {
            id: rebase_branch_unknown
            QQC2.ButtonGroup.group: branches
            text: i18n("do not change") + " (" + RebaseHelper.currentImage.branch + ")"
            font.bold: true

            enabled: false
            visible: false
            Component.onCompleted: {
                if (RebaseHelper.currentImage.branch != "stable" 
                && RebaseHelper.currentImage.branch != "testing") 
                {
                    checked = true;
                    enabled = true;
                    visible = true;
                }
            }

            onClicked: {
                rebase_selection.branch = RebaseHelper.currentImage.branch;
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
                
                text: i18n("Rebase")
                enabled: AppState.allowCommands && (RebaseHelper.currentImage.name != rebase_selection.name || RebaseHelper.currentImage.branch != rebase_selection.branch)

                onClicked: { 
                    showPassiveNotification("Rebase started", Kirigami.short);
                    console.log("Rebasing to: " + rebase_selection.image);
                    RebaseHelper.rebaseImage(rebase_selection.image, function (callback) {  
                        if (callback) {
                            showPassiveNotification("Rebase failed...", Kirigami.long);
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

    FC.FormHeader {
        title: i18n("System Image Information")
    }

    FC.FormCard {
        FC.FormTextDelegate {
            textItem.wrapMode: Text.WordWrap
            text: RebaseHelper.currentImage.name + ":" + RebaseHelper.currentImage.branch

            description: i18n("Current Image")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            textItem.wrapMode: Text.WordWrap
            text: {
                RebaseHelper.currentImage.datePretty["day"] 
                + " " 
                + RebaseHelper.currentImage.datePretty["month"] 
                + ", " 
                + RebaseHelper.currentImage.datePretty["year"];
            }

            description: i18n("Last Update") 
        }
    }



    FC.FormCard {
        Layout.topMargin: Kirigami.Units.largeSpacing * 4
        FC.FormTextDelegate {
            text: RebaseHelper.currentImage.name
            description: i18n("Image")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelper.currentImage.vendor
            description: i18n("Vendor")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelper.currentImage.ref
            description: i18n("Ref")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelper.currentImage.tag
            description: i18n("Tag")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelper.currentImage.branch
            description: i18n("Branch")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelper.currentImage.baseName
            description: i18n("Base Name")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelper.currentImage.fedoraVersion
            description: i18n("Fedora Version")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelper.currentImage.version
            description: i18n("Version")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelper.currentImage.versionPretty
            description: i18n("Version (Pretty)")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelper.currentImage.datePretty["day"] + " " + RebaseHelper.currentImage.datePretty["month"] + ", " + RebaseHelper.currentImage.datePretty["year"]
            description: i18n("Release Date")
        }
    }
}
