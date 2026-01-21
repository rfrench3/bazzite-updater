// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.formcard as FormCard

import io.github.rfrench3.bazzite_updater
import app.Gamepad 1.0
import app.RebaseHelper 1.0

Kirigami.ScrollablePage {
    id: page

    title: Gamepad.labels.b + Gamepad.labels.space_large + i18n("Rebase Helper (WORK-IN-PROGRESS)")

    GamepadPageNavigation {
        targetWindow: page.Window.window
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        // System Image Information
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            // horizontalAlignment: Text.AlignHCenter
            Kirigami.FormData.label: i18n("System Image Information")
            // level: 2
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Current Image:")
            text: RebaseHelper.currentImage.name + ":" + RebaseHelper.currentImage.tag
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Last Update:")
            text: {
                RebaseHelper.currentImage.datePretty["day"]
                + " "
                + RebaseHelper.currentImage.datePretty["month"]
                + ", "
                + RebaseHelper.currentImage.datePretty["year"];
            }
        }

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

            enabled: !rollbackButton.activated
        }

        QQC2.Button {
            id: rollbackButton
            property bool activated: false
            text: i18n("Rollback")
            
            onClicked: {
                rollbackButton.activated = true;
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

            enabled: confirmRollback.checked && !rollbackButton.activated
        }

        // System Rebase
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Rebase to New Image")
            // level: 2
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: gaming_mode
            text: i18n("Steam Gaming Mode")
        }

        QQC2.CheckBox {
            id: developer_mode
            text: i18n("Developer eXperience")
        }

        QQC2.ButtonGroup {
            id: gpu_drivers
        }
        Kirigami.Heading {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Nvidia Drivers")
            level: 4
        }

        QQC2.RadioButton {
            id: nvidia_none
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Not Needed")
            QQC2.ButtonGroup.group: gpu_drivers
        }

        QQC2.RadioButton {
            id: nvidia_closed
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Nvidia")
            QQC2.ButtonGroup.group: gpu_drivers
        }

        QQC2.RadioButton {
            id: nvidia_open
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Nvidia Open")
            QQC2.ButtonGroup.group: gpu_drivers
        }

        QQC2.Button {
            id: rebaseButton
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Rebase")
            // enabled: rebaseValid && !newIsCurrent

            enabled: false
        }

        // Current Image Information (Detailed)
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Current Image Information (Detailed)")
            Kirigami.FormData.isSection: true
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Image:")
            text: RebaseHelper.currentImage.name
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Vendor:")
            text: RebaseHelper.currentImage.vendor
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Ref:")
            text: RebaseHelper.currentImage.ref
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Tag:")
            text: RebaseHelper.currentImage.tag
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Branch:")
            text: RebaseHelper.currentImage.branch
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Base Name:")
            text: RebaseHelper.currentImage.baseName
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Fedora Version:")
            text: RebaseHelper.currentImage.fedoraVersion
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Version:")
            text: RebaseHelper.currentImage.version
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Version (Pretty):")
            text: RebaseHelper.currentImage.versionPretty
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Release Date:")
            text: {
                RebaseHelper.currentImage.datePretty["day"]
                + " "
                + RebaseHelper.currentImage.datePretty["month"]
                + ", "
                + RebaseHelper.currentImage.datePretty["year"];
            }
        }
    }
}
