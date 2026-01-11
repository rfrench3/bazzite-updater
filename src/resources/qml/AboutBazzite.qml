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

Kirigami.Page {
    id: page

    title: Gamepad.labels.b + Gamepad.labels.space_large + i18n("About Bazzite")

    GamepadPageNavigation {
        targetWindow: page.Window.window
    }

    Kirigami.FormLayout {
        id: page_content

        anchors.fill: parent


        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Resources"
        }

        QQC2.Button {
            Layout.fillWidth: true
            text: i18n("Bazzite Website")
            onClicked: Qt.openUrlExternally("https://bazzite.gg/")
        }

        QQC2.Button {
            Layout.fillWidth: true
            text: i18n("Bazzite Documentation")
            onClicked: Qt.openUrlExternally("https://docs.bazzite.gg/")
        }

        QQC2.Button {
            Layout.fillWidth: true
            text: i18n("Bazzite Github")
            onClicked: Qt.openUrlExternally("https://github.com/ublue-os/bazzite/")
        }

        QQC2.Button {
            Layout.fillWidth: true
            text: i18n("Universal Blue Website")
            onClicked: Qt.openUrlExternally("https://universal-blue.org/")
        }

        QQC2.Button {
            Layout.fillWidth: true
            text: i18n("Universal Blue Discourse")
            onClicked: Qt.openUrlExternally("https://universal-blue.discourse.group/")
        }

        QQC2.Button {
            Layout.fillWidth: true
            text: i18n("Universal Blue Mastodon")
            onClicked: Qt.openUrlExternally("https://fosstodon.org/@UniversalBlue")
        }
    }
}
