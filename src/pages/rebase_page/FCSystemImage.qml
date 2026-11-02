// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as KG
import org.kde.kirigamiaddons.formcard as FC
import io.github.rfrench3.bazzite_updater

FC.FormCard {
    id: root
    required property string url
    required property string name
    required property list<string> features
    required property list<string> tags
    property string currentTag: ""

    property bool fetching: false
    property bool hasFetched: false
    property real maxListHeight: KG.Units.gridUnit * 16

    property string fetchTagsButtonText: i18n("Fetch all tags")

    // Entry one: the "fetch tags" button, all other entries are actual tags.
    // Start with the pre-defined tags, use skopeo to add list entries for each tag afterwards
    property list<var> tagsSorted: {
        let sort = [
            {
                "fetch": true,
                "tag": "",
                "list": []
            }
        ];
        for (let tag of tags) {
            sort.push({
                "tag": tag,
                "list": []
            });
        }
        return sort;
    }

    signal tagClicked(string tag)

    signal listViewFocused(Item item)

    function closeActiveListView(): bool {
        const item = Window.activeFocusItem;
        if (!QmlUtils.isDescendentOf(item, root))
            return false;

        const collapsible = QmlUtils.getParentOfType(item.parent, FormDelegateCollapsible);
        if (collapsible) {
            if (collapsible.expanded !== true)
                return false;
            collapsible.expanded = false;
            collapsible.button.forceActiveFocus(Qt.TabFocusReason);
            return true;
        }
        return false;
    }

    function incrementListView(): bool {
        const view = activeListView();
        if (!view || view.currentIndex >= view.count - 1)
            return false;
        view.incrementCurrentIndex();
        return true;
    }

    function decrementListView(): bool {
        const view = activeListView();
        if (!view || view.currentIndex <= 0)
            return false;
        view.decrementCurrentIndex();
        return true;
    }

    function activeListView(): ListView {
        const item = Window.activeFocusItem;

        if (!QmlUtils.isDescendentOf(item, root))
            return null;

        if (item instanceof ListView)
            return item;

        return QmlUtils.getParentOfType(item, ListView);
    }

    function fetchAllTags(): void {
        fetching = true;
        root.fetchTagsButtonText = i18n("Fetching tags");
        RebaseModel.getAllTags(`${url}/${name}`, result => {
            fetching = false;
            hasFetched = true;
            if (result === 1) {
                console.log("skopeo error");
                root.fetchTagsButtonText = i18n("Failed to fetch tags.");
                return;
            }
            let allTags = JSON.parse(result);

            // [{tag: stable, list: [stable*, ...]}, {tag: testing, list: [testing*, ...]}]
            let newSorted = [];
            for (let tag of tags) {
                newSorted.push({
                    "tag": tag,
                    "list": filterSortTags(allTags, tag)
                });
            }

            newSorted.push({
                "tag": i18nc("all tags, used in 'List of {tag} tags' string.", "all"),
                "list": filterSortTags(allTags, "")
            });

            // pass an empty string as tag to only sort elements
            function filterSortTags(list: list<string>, tag: string): list<string> {
                let result = list.filter(x => x.startsWith(tag) && x !== tag);

                // non-dated tags should be listed first
                const dateRe = /\d{4}-?\d{2}-?\d{2}/;
                const undated = result.filter(x => !dateRe.test(x)).sort().reverse();
                const dated = result.filter(x => dateRe.test(x)).sort().reverse();

                if (tag !== "")
                    result = [tag].concat(undated, dated);
                else
                    result = undated.concat(dated);

                return result;
            }

            tagsSorted = newSorted;
        });
    }

    FormDelegateCollapsible {
        id: collapsible
        text: root.features.join(", ")
        description: `${root.url}/${root.name}`

        Repeater {
            id: collapsibleRepeater
            model: root.tagsSorted

            delegate: Loader {
                id: delegateRoot

                /* { tag: string, list: list<string>, fetch?: true } */
                required property var modelData

                readonly property bool isFetch: modelData.fetch === true
                readonly property string groupTag: modelData.tag
                readonly property list<string> groupList: modelData.list

                Layout.fillWidth: true

                sourceComponent: {
                    if (isFetch)
                        return fetchTagsButton;
                    if (groupList.length === 0)
                        return groupTagButton;
                    return tagsCollapsible;
                }

                Component {
                    id: fetchTagsButton
                    FC.FormButtonDelegate {
                        text: root.fetchTagsButtonText
                        enabled: !root.hasFetched && !root.fetching
                        onClicked: root.fetchAllTags()
                        description: i18n("Tags marked with a date or version will not receive security or feature updates. You should only use them temporarily if you are waiting for a critical bug to be fixed in the latest version.")
                    }
                }

                Component {
                    id: groupTagButton
                    FC.FormButtonDelegate {
                        readonly property bool isCurrent: delegateRoot.groupTag === root.currentTag
                        text: isCurrent ? i18n("%1 (Current Tag)".arg(delegateRoot.groupTag)) : delegateRoot.groupTag
                        enabled: AppState.allowCommands && !isCurrent
                        onClicked: root.tagClicked(delegateRoot.groupTag)
                    }
                }

                Component {
                    id: tagsCollapsible
                    FormDelegateCollapsible {
                        text: i18nc("List of tags classified as stable, testing, etc", "List of %1 tags".arg(delegateRoot.groupTag))

                        button.leading: KG.Icon {
                            source: "application-menu"
                            implicitHeight: 24
                            implicitWidth: 24
                        }

                        property alias listView: tagsView
                        ListView {
                            id: tagsView
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(contentHeight, root.maxListHeight)
                            clip: true
                            model: delegateRoot.groupList

                            currentIndex: 0
                            highlightFollowsCurrentItem: true
                            highlightMoveDuration: 0
                            highlightRangeMode: ListView.NoHighlightRange
                            activeFocusOnTab: true

                            onActiveFocusChanged: activeFocus ? root.listViewFocused(this) : root.listViewFocused(null)

                            // TODO: this just matches the current onHover appearance of a formcard button,
                            //  ideally the button would just act like it's being hovered over
                            highlight: Rectangle {
                                color: KG.Theme.textColor
                                opacity: tagsView.activeFocus ? 0.07 : 0
                            }

                            // Keep the current item scrolled into view whenever it changes,
                            // regardless of what changed it (Tab, arrows, mouse).
                            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                            KG.WheelHandler {
                                target: tagsView
                            }

                            QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                                id: vbar
                                policy: QQC2.ScrollBar.AlwaysOn
                            }
                            readonly property real scrollbarWidth: vbar.visible ? vbar.width : 0
                            readonly property var scrollbar: vbar

                            delegate: FC.FormButtonDelegate {
                                required property string modelData
                                readonly property bool isCurrent: modelData === root.currentTag

                                width: tagsView.width - tagsView.scrollbarWidth
                                text: isCurrent ? i18n("%1 (Current Tag)".arg(modelData)) : modelData
                                enabled: AppState.allowCommands && !isCurrent

                                // The ListView owns focus
                                focusPolicy: Qt.NoFocus

                                onClicked: root.tagClicked(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
