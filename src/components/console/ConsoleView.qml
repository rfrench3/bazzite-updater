// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import io.github.rfrench3.bazzite_updater

Frame {
    id: consoleViewRoot
    property alias currentIndex: view.currentIndex
    property alias length: view.count
    required property var model

    ListView {
        id: view
        anchors.fill: parent
        
        // This vertically cuts off the text slightly too early
        clip: true
        
        highlightFollowsCurrentItem: true
        highlightRangeMode: ListView.StrictlyEnforceRange

        highlightMoveDuration: 100
        highlightMoveVelocity: -1

        
        model: consoleViewRoot.model.lines

        delegate: Item {
            required property var modelData

            height: sysFont.lineSpacing
            Layout.fillWidth: true
            
            Text { 
                text: __setText(modelData.content, modelData.level)
                font: "monospace"
                
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5

                function __setText(content, loglevel) {
                    switch(loglevel)
                    {
                        case Console.LogLevel.Info:
                            return content;
                            
                        case Console.LogLevel.Warn:
                            return i18n("Warning: ") + content;
                        
                        case Console.LogLevel.Error:
                            font.bold = true;
                            return i18n("Error: ") + content;
                        
                        case Console.LogLevel.Debug:
                            color = palette.placeholderText;
                            return i18n("Debug: ") + content;
                        
                        case Console.LogLevel.ErrorCritical:
                            font.bold = true;
                            return i18n("Critical Error: ") + content;

                        default:
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
