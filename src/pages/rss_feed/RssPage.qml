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

    title: GP.Labels.east + GP.Labels.spacer_large + i18n("Changelogs")

    GP.ScrollHandler {
        target: feed
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing * 4

        FC.FormCard {

            visible: modelLoader.item?.status !== XmlListModel.Ready

            FC.FormPlaceholderMessageDelegate {
                id: nullMsg
                text: i18nc("@info:placeholder", "No changelogs have been provided.")
                visible: modelLoader.item?.status === XmlListModel.Null
            }

            FC.FormPlaceholderMessageDelegate {
                id: loadingMsg
                text: i18nc("@info:placeholder", "Loading changelog") + dots
                visible: modelLoader.item?.status === XmlListModel.Loading

                // loading dots
                property string dots: "."
                property int dotIndex: 0

                Timer {
                    interval: 500
                    running: true
                    repeat: true
                    onTriggered: {
                        parent.dotIndex = (parent.dotIndex % 3) + 1;
                        parent.dots = ".".repeat(parent.dotIndex);
                    }
                }
            }

            FC.FormPlaceholderMessageDelegate {
                id: errorMsg
                text: i18nc("@info:placeholder", "Error loading changelogs:") + modelLoader.item?.errorString()
                visible: modelLoader.item?.status === XmlListModel.Error
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
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.right: feedVBar.left

        visible: modelLoader.item?.status === XmlListModel.Ready

        spacing: Kirigami.Units.largeSpacing

        model: modelLoader.item
        clip: true
        delegate: FCRssDelegate {
            width: feed.width - feed.leftMargin - feed.rightMargin
        }

        QQC2.ScrollBar.vertical: feedVBar

        header: Item {
            implicitHeight: Kirigami.Units.largeSpacing * 4
        }

        footer: Item {
            implicitHeight: Kirigami.Units.largeSpacing * 4
        }
    }

    QQC2.ScrollBar {
        id: feedVBar
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }

    Loader {
        id: modelLoader
        source: (AppConfig.ini.General.rssFeedType === "atom") ? "AtomModel.qml" : "RssModel.qml"
    }
}
