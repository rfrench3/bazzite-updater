// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.formcard as FormCard

import io.github.rfrench3.bazzite_updater

Kirigami.Page {
    id: page

    title: ControllerManager.labels.b + ControllerManager.labels.space + ControllerManager.labels.space + ControllerManager.labels.space + i18n("Rebase Helper")

    ColumnLayout {
        width: page.width

        anchors.centerIn: parent

        Kirigami.Heading {
            Layout.alignment: Qt.AlignCenter
            text: i18n("Not Yet Implemented!")
        }
    }
}
