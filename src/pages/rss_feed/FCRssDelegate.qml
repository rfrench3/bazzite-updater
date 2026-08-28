// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater

FormCardCollapsible {
    id: delegate
    required property string updated
    required property string link
    required property string title
    required property string content

    topComponent: FC.FormTextDelegate {
        text: "Title: %1<br>Date: %2<br>Link: %3".arg(delegate.title).arg(delegate.formatRssDate(delegate.updated)).arg(`<a href="${delegate.link}">${delegate.link}</a>`)
        textItem.textFormat: Text.RichText
        textItem.wrapMode: Text.Wrap

        textItem.onLinkActivated: url => Qt.openUrlExternally(url)
    }

    FC.AbstractFormDelegate {
        id: abstractDelegate

        clip: true

        // stops controllers/tabbing from selecting this item
        focusPolicy: Qt.NoFocus

        // disable hover/click feedback
        background: Item {
            visible: false
        }

        contentItem: ColumnLayout {
            Text {
                id: contentText

                visible: abstractDelegate.visible
                text: delegate.content

                textFormat: Text.RichText

                color: palette.text

                Layout.fillWidth: true
                wrapMode: Text.Wrap

                onLinkActivated: url => Qt.openUrlExternally(url)

                HoverHandler {
                    cursorShape: contentText.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
        }
    }

    function formatRssDate(dateString) {
        let date = new Date(dateString);

        // Fallback if the date string is malformed
        if (isNaN(date.getTime())) {
            return dateString;
        }

        const months = [i18n("January"), i18n("February"), i18n("March"), i18n("April"), i18n("May"), i18n("June"), i18n("July"), i18n("August"), i18n("September"), i18n("October"), i18n("November"), i18n("December")];

        let day = date.getDate();
        let month = months[date.getMonth()];
        let year = date.getFullYear();

        let now = new Date();
        let diffSeconds = Math.floor((now - date) / 1000);
        let relativeTime = "";

        let absoluteDate = day + " " + month;
        if (year !== now.getFullYear()) {
            absoluteDate += " " + year;
        }

        function createRes(relativeTime) {
            return absoluteDate + " (" + relativeTime + ")";
        }

        function minutesToSeconds(time) {
            return time * 60;
        }

        function hoursToSeconds(time) {
            return minutesToSeconds(time * 60);
        }

        function daysToSeconds(time) {
            return hoursToSeconds(time * 24);
        }

        function monthsToSeconds(time) {
            return daysToSeconds(time * 30);
        }

        function yearsToSeconds(time) {
            return daysToSeconds(time * 365);
        }

        if (diffSeconds < 0) {
            return createRes(i18n("in the future"));
        }

        if (diffSeconds < minutesToSeconds(1)) {
            return createRes(i18n("just now"));
        }

        if (diffSeconds < hoursToSeconds(1)) {
            let mins = Math.floor(diffSeconds / minutesToSeconds(1));
            let relativeTime = mins + (mins === 1 ? " " + i18n("minute ago") : " " + i18n("minutes ago"));
            return createRes(relativeTime);
        }

        if (diffSeconds < daysToSeconds(1)) {
            let hours = Math.floor(diffSeconds / hoursToSeconds(1));
            let relativeTime = hours + (hours === 1 ? " " + i18n("hour ago") : " " + i18n("hours ago"));
            return createRes(relativeTime);
        }

        if (diffSeconds < monthsToSeconds(1)) {
            let days = Math.floor(diffSeconds / daysToSeconds(1));
            let relativeTime = days + (days === 1 ? " " + i18n("day ago") : " " + i18n("days ago"));
            return createRes(relativeTime);
        }

        if (diffSeconds < yearsToSeconds(1)) {
            let mths = Math.floor(diffSeconds / monthsToSeconds(1));
            let relativeTime = mths + (mths === 1 ? " " + i18n("month ago") : " " + i18n("months ago"));
            return createRes(relativeTime);
        }

        let yrs = Math.floor(diffSeconds / yearsToSeconds(1));
        relativeTime = yrs + (yrs === 1 ? " " + i18n("year ago") : " " + i18n("years ago"));
        return createRes(relativeTime);
    }
}
