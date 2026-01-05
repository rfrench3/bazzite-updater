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

    title: Gamepad.labels.b + Gamepad.labels.space_large + i18n("Rebase Helper")

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.Label {
            Kirigami.FormData.label: "Current Image:"
            text: RebaseHelper.currentImage.name + ":" + RebaseHelper.currentImage.tag
        }

        QQC2.Label {
            Kirigami.FormData.label: "Last Update:"
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
