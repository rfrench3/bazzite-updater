// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml.XmlListModel
import io.github.rfrench3.bazzite_updater

XmlListModel {
    id: root

    // Input a list of [atom, rss1, rss2], output the correct option
    function chooseType(options) {
        const feedType = AppConfig.ini.General?.rssFeedType;
        if (feedType === "atom")
            return options[0];
        if (feedType === "rss1")
            return options[1];
        else
            return options[2];
    }

    source: AppConfig.ini.General?.rssFeed

    query: chooseType(["/feed/entry", "/RDF/item", "/rss/channel/item"])

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
}
