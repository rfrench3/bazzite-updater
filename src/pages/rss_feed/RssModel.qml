// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml
import QtQml.Models
import QtQml.XmlListModel
import io.github.rfrench3.bazzite_updater

ListModel {
    id: root

    // Expose status and reload() so external views can treat this like XmlListModel
    readonly property int status: xmlModel.status
    function reload(): void {
        xmlModel.reload();
    }

    // Input a list of [atom, rss1, rss2], output the correct option
    function chooseType(options: list<string>): string {
        const feedType = AppConfig.ini.General?.rssFeedType;
        if (feedType === "atom")
            return options[0];
        if (feedType === "rss1")
            return options[1];
        else
            return options[2];
    }

    property XmlListModel _xmlModel: XmlListModel {
        id: xmlModel

        source: AppConfig.ini.General?.rssFeed
        query: root.chooseType(["/feed/entry", "/RDF/item", "/rss/channel/item"])

        XmlListModelRole {
            name: "title"
            elementName: "title"
        }

        XmlListModelRole {
            name: "content"
            elementName: root.chooseType(["content", "description", "description"])
        }

        XmlListModelRole {
            name: "link"
            elementName: "link"
            attributeName: root.chooseType(["href", "", ""])
        }

        XmlListModelRole {
            name: "updated"
            elementName: root.chooseType(["updated", "date", "pubDate"])
        }

        onStatusChanged: {
            if (status === XmlListModel.Loading) {
                root.clear();
            } else if (status === XmlListModel.Ready) {
                root.rebuildSortedModel();
            }
        }
    }

    // Sort by date/time by using javascript's Date()
    function rebuildSortedModel(): void {
        const roleTitle = Qt.UserRole;
        const roleContent = Qt.UserRole + 1;
        const roleLink = Qt.UserRole + 2;
        const roleUpdated = Qt.UserRole + 3;

        let items = [];
        const rowCount = xmlModel.count;

        for (let i = 0; i < rowCount; ++i) {
            const idx = xmlModel.index(i, 0);
            const updatedStr = String(xmlModel.data(idx, roleUpdated) ?? "");
            const timestamp = new Date(updatedStr).getTime();

            items.push({
                title: String(xmlModel.data(idx, roleTitle) ?? ""),
                content: String(xmlModel.data(idx, roleContent) ?? ""),
                link: String(xmlModel.data(idx, roleLink) ?? ""),
                updated: updatedStr,
                _timestamp: isNaN(timestamp) ? 0 : timestamp
            });
        }

        // Sort descending (newest first)
        items.sort((a, b) => b._timestamp - a._timestamp);

        root.clear();
        for (const item of items) {
            root.append(item);
        }
    }
}
