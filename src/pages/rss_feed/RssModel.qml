// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml.XmlListModel
import io.github.rfrench3.bazzite_updater

XmlListModel {
    query: "/rss/channel/item"
    source: AppConfig.ini.General.rssFeed

    XmlListModelRole {
        name: "title"
        elementName: "title"
    }
    XmlListModelRole {
        name: "content"
        elementName: "content"
    }
    XmlListModelRole {
        name: "link"
        elementName: "link"
    }
    XmlListModelRole {
        name: "updated"
        elementName: "pubDate"
    }
}
