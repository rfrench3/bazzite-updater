// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

import QtQml.XmlListModel

Kirigami.Page {
    id: page
    padding: 0
    topPadding: Kirigami.Units.largeSpacing
    bottomPadding: Kirigami.Units.largeSpacing

    title: GP.Labels.east + GP.Labels.spacer_large + i18n("Changelogs")

    GP.ScrollHandler {
        target: feed
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing

        FC.FormCard {

            visible: atomModel.status !== XmlListModel.Ready

            FC.FormPlaceholderMessageDelegate {
                id: nullMsg
                text: i18nc("@info:placeholder", "No changelogs have been provided.")
                visible: atomModel.status === XmlListModel.Null
            }

            FC.FormPlaceholderMessageDelegate {
                id: loadingMsg
                text: i18nc("@info:placeholder", "Loading changelog.")
                visible: atomModel.status === XmlListModel.Loading
            }

            FC.FormPlaceholderMessageDelegate {
                id: errorMsg
                text: i18nc("@info:placeholder", "Error loading changelogs:") + atomModel.errorString()
                visible: atomModel.status === XmlListModel.Error
            }

            FC.FormPlaceholderMessageDelegate {
                text: i18nc("@info:placeholder", "An error has occurred loading changelogs.")
                visible: !(nullMsg.visible || loadingMsg.visible || errorMsg.visible)
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    ListView {
        id: feed
        anchors.fill: parent

        visible: atomModel.status === XmlListModel.Ready

        spacing: Kirigami.Units.largeSpacing

        model: atomModel
        clip: true
        delegate: FCRssDelegate {
            width: feed.width - feed.leftMargin - feed.rightMargin
        }

        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
            id: feedVBar
        }
    }

    // TODO: handle normal rss and atom
    XmlListModel {
        id: atomModel
        source: AppConfig.ini.General.rssFeed
        query: "/feed/entry"

        XmlListModelRole {
            name: "updated"
            elementName: "updated"
        }
        XmlListModelRole {
            name: "link"
            elementName: "link"
        }
        XmlListModelRole {
            name: "title"
            elementName: "title"
        }
        XmlListModelRole {
            name: "content"
            elementName: "content"
        }
    }
}
