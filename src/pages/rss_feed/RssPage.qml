// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

import QtQml.XmlListModel

FC.FormCardPage {
    id: page

    topPadding: Kirigami.Units.largeSpacing * 4

    title: GP.Labels.east + GP.Labels.spacer_large + i18n("Changelogs")

    function grabScrollbar(item) {
        if (item.contentItem?.ScrollBar?.vertical)
            return item.contentItem.ScrollBar.vertical;

        if (item.parent)
            return grabScrollbar(item.parent);

        console.warn("Parent scrollbar not found, controller scrolling will not function!");
    }

    GP.PageNavigation {
        targetScrollbar: page.grabScrollbar(page)
    }

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

        Item {
            Layout.fillHeight: true
        }
    }

    Repeater {
        id: repeater
        enabled: modelLoader.item?.status === XmlListModel.Ready
        model: modelLoader.item

        delegate: ColumnLayout {
            id: delegate
            required property int index
            required property string updated
            required property string link
            required property string title
            required property string content

            Layout.fillWidth: true

            // TODO: This might not be needed with the switch to a normal FormCardPage.
            // Tab navigation must manually be tracked because it is based on load order. Moving down and then back up can load things in a strange order
            // KeyNavigation.backtab: (delegate.index > 0) ? repeater.itemAt(delegate.index - 1) : delegate.forceActiveFocus(delegate.nextItemInFocusChain(false))
            // KeyNavigation.tab: (delegate.index < repeater.count - 1) ? repeater.itemAt(delegate.index + 1) : delegate.forceActiveFocus(delegate.nextItemInFocusChain(true))

            Item {
                implicitHeight: Kirigami.Units.mediumSpacing
                visible: delegate.index > 0
            }

            FCRssDelegate {
                updated: delegate.updated
                link: delegate.link
                title: delegate.title
                content: delegate.content
            }
        }
    }

    Loader {
        id: modelLoader
        source: "RssModel.qml"
    }
}
