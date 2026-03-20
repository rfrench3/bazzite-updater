// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import io.github.rfrench3.bazzite_updater

Frame {
    id: root
    property alias currentIndex: view.currentIndex
    property alias length: view.count
    required property var model

ScrollView {
    id: scrollView
    anchors.fill: parent

    ListView {
        id: view
        anchors.fill: parent
        
        // This vertically cuts off the text slightly too early
        clip: true
        
        highlightFollowsCurrentItem: true
        highlightRangeMode: ListView.StrictlyEnforceRange

        highlightMoveDuration: 100
        highlightMoveVelocity: -1


        
        model: root.model.lines

        delegate: Item {
            required property var modelData

            height: textItem.implicitHeight
            width: view.width - scrollView.ScrollBar.vertical.width

            clip: true
            
            Text {
                id: textItem
                text: __setText(modelData.content, modelData.level)
                font: "monospace"
                width: parent.width - 10
                wrapMode: Text.Wrap
                
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 5

                function __setText(content, loglevel) {
                    switch(loglevel)
                    {
                        case Console.LogLevel.Info:
                            color = palette.text;
                            return content;
                            
                        case Console.LogLevel.Warn:
                            color = palette.text;
                            return i18n("Warning: ") + content;
                        
                        case Console.LogLevel.Error:
                            color = palette.text;
                            font.bold = true;
                            return i18n("Error: ") + content;
                        
                        case Console.LogLevel.Debug:
                            color = palette.placeholderText;
                            return i18n("Debug: ") + content;
                        
                        case Console.LogLevel.ErrorCritical:
                            color = palette.text;
                            font.bold = true;
                            return i18n("Critical Error: ") + content;

                        default:
                            color = palette.text;
                            return content || "";
                    }
                }
            }
        }
    }


    SystemPalette {
        id: palette
        colorGroup: SystemPalette.Active 
    }

    FontMetrics {
        id: sysFont
        font: Qt.application.font
    }
}

}
