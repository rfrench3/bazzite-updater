// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml.XmlListModel
import io.github.rfrench3.bazzite_updater

XmlListModel {
    query: "/feed/entry"
    source: AppConfig.ini.General.rssFeed

    XmlListModelRole {
        name: "updated"
        elementName: "updated"
    }
    XmlListModelRole {
        name: "link"
        elementName: "link"
        attributeName: "href"
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
