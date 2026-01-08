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

Kirigami.Page {
    id: page

    title: Gamepad.labels.b + Gamepad.labels.space_large + i18n("Rebase Helper (WORK-IN-PROGRESS)")

    ColumnLayout {
        anchors.fill: parent


        Kirigami.FormLayout {

            Kirigami.Separator {
                Kirigami.FormData.label: i18n("System Image Information")
                Kirigami.FormData.isSection: true
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

            Kirigami.Separator {
                Kirigami.FormData.label: i18n("Rollback Last Update")
                Kirigami.FormData.isSection: true
            }


            QQC2.Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                Kirigami.FormData.labelAlignment: Qt.AlignTop

                wrapMode: Text.WordWrap
                text: i18n("This will return your base system to before its current update. Your user files will not be affected, and the system will not automatically update until told to do so again.")
            }

            QQC2.CheckBox {
                id: confirmRollback
                text: i18n("Confirm")
                enabled: false
            }

            QQC2.Button {
                id: rollbackButton
                text: i18n("Rollback")
                // enabled: confirmRollback.checked
                enabled: false
            }



            Kirigami.Separator {
                Kirigami.FormData.label: i18n("Rebase to New Image")
                Kirigami.FormData.isSection: true
            }

            QQC2.CheckBox {
                Kirigami.FormData.label: i18n("Steam Gaming Mode")
            }

            QQC2.CheckBox {
                Kirigami.FormData.label: i18n("Developer eXperience")
            }




            QQC2.RadioButton {
                Kirigami.FormData.label: i18n("GPU Drivers")
                text: i18n("Not Nvidia")
            }

            QQC2.RadioButton {
                text: i18n("Nvidia")
            }

            QQC2.RadioButton {
                text: i18n("Nvidia Open")
            }

            Kirigami.Separator { Kirigami.FormData.isSection: false }
            Kirigami.Separator { Kirigami.FormData.isSection: false }

            QQC2.RadioButton {
                Kirigami.FormData.label: i18n("Desktop Environment")
                text: i18n("KDE")
            }

            QQC2.RadioButton {
                text: i18n("GNOME")
            }


            QQC2.Button {
                id: rebaseButton
                text: "Rebase"
                // enabled: rebaseValid && !newIsCurrent
                enabled: false
            }

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

        Item {
            Layout.fillHeight: true
        }

    }
}
