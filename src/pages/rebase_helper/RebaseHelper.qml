// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.Gamepad

FC.FormCardPage {
    id: page

    title: Gamepad.labels.b + Gamepad.labels.space_large + i18n("Rebase Helper")

    // Handle most navigation throughout page
    GamepadPageNavigation { 
        targetWindow: page.Window.window 
        targetScrollable: page
    }

    function handleInput(buttonId, button_down) {
        // Use normal navigation for everything on the main page

        if (consoleDrawer.drawerOpen) {
            consoleDrawer.handleInput(buttonId, button_down);
            return;
        }

        if (!button_down) return;

        switch (buttonId) {
            case 3: // Y
                toggleConsole.trigger();
                // Closes up to 5 passive notifications
                for (let i = 0; i < 5; ++i) {
                    hidePassiveNotification();
                }
                break;
        }   
    }

    actions: [
        Kirigami.Action {
            id: toggleConsole
            text: "Toggle Console" + Gamepad.labels.space + Gamepad.labels.y
            shortcut: "F12"
            onTriggered: consoleDrawer.drawerOpen = !consoleDrawer.drawerOpen
        }
    ]

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
                    RebaseHelperBackend.rollbackImage(function(callback) {
                        if (callback != 0) {
                            showPassiveNotification(i18n("Rollback Failed."), 
                                Kirigami.long,
                                i18n("Open console") + Gamepad.labels.space + Gamepad.labels.y,
                                function() {
                                    errorDisplayDialog.open();
                                }
                            );
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
            text: RebaseHelperBackend.recommendedDriver
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
                if (RebaseHelperBackend.currentImage.name.indexOf("-gnome") !== -1) {
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
                    if (modelData === RebaseHelperBackend.currentImage.name) {
                        checked = true;
                        additional_text = i18n(" (Current)");
                    }
                }
                
                font.bold: modelData === RebaseHelperBackend.currentImage.name
                
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
            font.bold: text === RebaseHelperBackend.currentImage.branch
            Component.onCompleted: {
                if (RebaseHelperBackend.currentImage.branch == "stable")
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
            font.bold: text === RebaseHelperBackend.currentImage.branch
            Component.onCompleted: {
                if (RebaseHelperBackend.currentImage.branch == "testing")
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
            text: i18n("do not change") + " (" + RebaseHelperBackend.currentImage.branch + ")"
            font.bold: true

            enabled: false
            visible: false
            Component.onCompleted: {
                if (RebaseHelperBackend.currentImage.branch != "stable" 
                && RebaseHelperBackend.currentImage.branch != "testing") 
                {
                    checked = true;
                    enabled = true;
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
                
                text: i18n("Rebase")
                enabled: AppState.allowCommands && (RebaseHelperBackend.currentImage.name != rebase_selection.name || RebaseHelperBackend.currentImage.branch != rebase_selection.branch)

                onClicked: { 
                    showPassiveNotification("Rebase started", Kirigami.short);
                    console.log("Rebasing to: " + rebase_selection.image);
                    RebaseHelperBackend.rebaseImage(rebase_selection.image, function (callback) {  
                        if (callback) {
                            showPassiveNotification(
                                "Rebase failed...", 
                                Kirigami.long, 
                                i18n("Open console") + Gamepad.labels.space + Gamepad.labels.y,
                                function() {
                                    errorDisplayDialog.open();
                                }
                            );
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
            text: RebaseHelperBackend.currentImage.name + ":" + RebaseHelperBackend.currentImage.branch

            description: i18n("Current Image")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            textItem.wrapMode: Text.WordWrap
            text: {
                RebaseHelperBackend.currentImage.datePretty["day"] 
                + " " 
                + RebaseHelperBackend.currentImage.datePretty["month"] 
                + ", " 
                + RebaseHelperBackend.currentImage.datePretty["year"];
            }

            description: i18n("Last Update") 
        }
    }



    FC.FormCard {
        Layout.topMargin: Kirigami.Units.largeSpacing * 4
        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.name
            description: i18n("Image")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.vendor
            description: i18n("Vendor")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.ref
            description: i18n("Ref")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.tag
            description: i18n("Tag")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.branch
            description: i18n("Branch")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.baseName
            description: i18n("Base Name")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.fedoraVersion
            description: i18n("Fedora Version")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.version
            description: i18n("Version")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.versionPretty
            description: i18n("Version (Pretty)")
        }

        FC.FormDelegateSeparator { }

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.datePretty["day"] + " " + RebaseHelperBackend.currentImage.datePretty["month"] + ", " + RebaseHelperBackend.currentImage.datePretty["year"]
            description: i18n("Release Date")
        }
    }

    ConsoleDrawer {
        id: consoleDrawer
        model: RebaseHelperBackend.consoleModel
    }
}
