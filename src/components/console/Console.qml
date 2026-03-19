// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import io.github.rfrench3.bazzite_updater

Frame {
    property alias currentIndex: view.currentIndex
    property alias length: view.length
    property alias model: view.model

    ListView {
        id: view
        anchors.fill: parent
        
        // This vertically cuts off the text slightly too early
        clip: true
        
        highlightFollowsCurrentItem: true
        highlightRangeMode: ListView.StrictlyEnforceRange

        highlightMoveDuration: 100
        highlightMoveVelocity: -1

        
        model: new Console.Model

        delegate: Item {
            required property string itemText
            required property var logLevel
            

            height: sysFont.lineSpacing
            Layout.fillWidth: true
            
            Text { 
                text: __setText(itemText, logLevel)
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
                            return content;
                        
                        case Console.LogLevel.Error:
                            return content;
                        
                        case Console.LogLevel.Debug:
                            return content;
                        
                        case Console.LogLevel.ErrorCritical:
                            return content;
                    }
                }
            }
        }
    }

    FontMetrics {
        id: sysFont
        font: Qt.application.font
    }
}
