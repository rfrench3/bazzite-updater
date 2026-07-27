// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

FC.FormCard {
    id: delegate
    required property string updated
    required property string link
    required property string title
    required property string content

    FC.FormTextDelegate {
        text: "Title: %1\nDate: %2\nLink: %3".arg(delegate.title).arg(delegate.updated).arg(delegate.link)
    }

    FC.FormDelegateSeparator {}

    FC.AbstractFormDelegate {

        // disable hover/click feedback
        background: Item {}

        contentItem: ColumnLayout {
            Text {
                id: contentText
                text: delegate.content
                textFormat: Text.RichText

                // 3. Force the RichText to constrain to the remaining width and wrap
                Layout.fillWidth: true
                wrapMode: Text.Wrap

                onLinkActivated: url => Qt.openUrlExternally(url)

                HoverHandler {
                    cursorShape: contentText.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
        }
    }
}
