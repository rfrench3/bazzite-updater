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

    ColumnLayout {
        anchors.fill: parent

        Kirigami.AbstractCard {            
            Layout.fillWidth: false
            Layout.preferredWidth: card_test.preferredWidth
            Layout.preferredHeight: card_test.preferredHeight + card_header.preferredHeight
            Layout.alignment: Qt.AlignHCenter

            header: Kirigami.Heading {
                id: card_header
                horizontalAlignment: Text.AlignHCenter
                text: i18n("System Image Information")
                level: 2
            }
            contentItem: GridLayout {
                id: card_test
                columns: 2
                uniformCellWidths: true

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Current Image:")
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    text: RebaseHelper.currentImage.name + ":" + RebaseHelper.currentImage.tag
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Last Update:")
                }
                QQC2.Label {
                    Layout.fillWidth: true
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

        Kirigami.AbstractCard {            
            header: Kirigami.Heading {
                horizontalAlignment: Text.AlignHCenter
                text: i18n("Rollback Last Update")
                level: 2
            }
            contentItem: GridLayout {
                columns: 2
                uniformCellWidths: true

                QQC2.Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.columnSpan: 2
                    // attempt to fill 3 rows, if set to exactly 3 then a word usually overhangs into a 4th row
                    Layout.preferredWidth: implicitWidth / 2.5

                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignJustify
                    text: i18n("This will return your base system to before its current update. Your user files will not be affected, and the system will not automatically update until told to do so again.")
                }

                QQC2.CheckBox {
                    id: confirmRollback
                    Layout.alignment: Qt.AlignRight
                    text: i18n("Confirm")

                    enabled: false
                }

                QQC2.Button {
                    id: rollbackButton
                    text: i18n("Rollback")
                    // enabled: confirmRollback.checked

                    enabled: false
                }
            }
        }

        Kirigami.AbstractCard {            
            header: Kirigami.Heading {
                horizontalAlignment: Text.AlignHCenter
                text: i18n("Rebase to New Image")
                level: 2
            }
            contentItem: ColumnLayout {
                Layout.alignment: Qt.AlignHCenter

                QQC2.CheckBox {
                    // Layout.alignment: Qt.AlignHCenter
                    text: i18n("Steam Gaming Mode")
                }

                QQC2.CheckBox {
                    // Layout.alignment: Qt.AlignHCenter
                    text: i18n("Developer eXperience")
                }


                QQC2.ButtonGroup {
                    id: gpu_drivers
                }
                Kirigami.Heading {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("GPU Drivers")
                    level: 4
                }

                QQC2.RadioButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("Not Nvidia")
                    QQC2.ButtonGroup.group: gpu_drivers
                }

                QQC2.RadioButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("Nvidia")
                    QQC2.ButtonGroup.group: gpu_drivers
                }

                QQC2.RadioButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("Nvidia Open")
                    QQC2.ButtonGroup.group: gpu_drivers
                }

                QQC2.ButtonGroup {
                    id: desktop_environment
                }
                Kirigami.Heading {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("Desktop Environment")
                    level: 4
                }

                QQC2.RadioButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("KDE")
                    QQC2.ButtonGroup.group: desktop_environment
                }

                QQC2.RadioButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("GNOME")
                    QQC2.ButtonGroup.group: desktop_environment
                }

                QQC2.Button {
                    id: rebaseButton
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("Rebase")
                    // enabled: rebaseValid && !newIsCurrent

                    enabled: false
                }

            }
        }

        Kirigami.AbstractCard {            
            header: Kirigami.Heading {
                horizontalAlignment: Text.AlignHCenter
                text: i18n("Current Image Information (Detailed)")
                level: 2
            }
            contentItem: GridLayout {
                columns: 2
                uniformCellWidths: true

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Image:")
                }
                QQC2.Label {
                    text: RebaseHelper.currentImage.name
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Vendor:")
                }
                QQC2.Label {
                    text: RebaseHelper.currentImage.vendor
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Ref:")
                }
                QQC2.Label {
                    text: RebaseHelper.currentImage.ref
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Tag:")
                }
                QQC2.Label {
                    text: RebaseHelper.currentImage.tag
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Branch:")
                }
                QQC2.Label {
                    text: RebaseHelper.currentImage.branch
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Base Name:")
                }
                QQC2.Label {
                    text: RebaseHelper.currentImage.baseName
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Fedora Version:")
                }
                QQC2.Label {
                    text: RebaseHelper.currentImage.fedoraVersion
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Version:")
                }
                QQC2.Label {
                    text: RebaseHelper.currentImage.version
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Version (Pretty):")
                }
                QQC2.Label {
                    text: RebaseHelper.currentImage.versionPretty
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Release Date:")
                }
                QQC2.Label {
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
    }    
}
