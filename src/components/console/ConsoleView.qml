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

    readonly property ScrollBar scrollBar: scrollView.ScrollBar.vertical
    readonly property Flickable flickable: view

ScrollView {
    id: scrollView
    anchors.fill: parent

    ListView {
        id: view
        anchors.fill: parent
        
        // This vertically cuts off the text slightly too early
        clip: true
        
        highlightFollowsCurrentItem: true
        highlightRangeMode: ListView.ApplyRange

        highlightMoveDuration: 100
        highlightMoveVelocity: -1
        
        model: root.model

        delegate: Item {
            required property string display
            required property int decoration

            height: textItem.implicitHeight
            width: view.width - scrollView.ScrollBar.vertical.width

            clip: true
            
            Text {
                readonly property int __margins: 5
                id: textItem
                text: __setText(display, decoration)
                font.family: "monospace"
                font.bold: decoration === Console.LogLevel.Error 
                        || decoration === Console.LogLevel.ErrorCritical 
                        ? true
                        : false 

                width: parent.width - __margins * 2
                wrapMode: Text.Wrap
                
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: __margins

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

        // The below section is dedicated to getting nice snapping behavior

        property bool __snap: true
        property real __prevContentY: 0

        onCountChanged: { if (__snap) view.positionViewAtEnd(); }

        // If user moves up, disable snapping. otherwise, update __snap when the end is reached
        onContentYChanged: { 
            
            if (__prevContentY > contentY)
                __snap = false; 
            else
                if (atYEnd)
                    __snap = true; 

            __prevContentY = contentY;
        }
    }

    SystemPalette {
        id: palette
        colorGroup: SystemPalette.Active 
    }
}

}
