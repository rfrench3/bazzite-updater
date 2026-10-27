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

            function filterSortTags(list: list<string>, tag: string): list<string> {
                let result = list.filter(x => x.startsWith(tag) && x !== tag);

                // non-dated tags should be listed first
                const dateRe = /\d{4}-?\d{2}-?\d{2}/;
                const undated = result.filter(x => !dateRe.test(x)).sort().reverse();
                const dated = result.filter(x => dateRe.test(x)).sort().reverse();
                result = [tag].concat(undated, dated);

                return result;
            }

            tagsSorted = newSorted;
        });
    }

    FormDelegateCollapsible {
        text: root.features.join(", ")
        description: `${root.url}/${root.name}`

        Repeater {
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
                    }
                }

                Component {
                    id: groupTagButton
                    FC.FormButtonDelegate {
                        readonly property bool isCurrent: delegateRoot.groupTag === root.currentTag
                        text: isCurrent ? delegateRoot.groupTag + " " + i18n("(Current Tag)") : delegateRoot.groupTag
                        enabled: AppState.allowCommands && !isCurrent
                        onClicked: root.tagClicked(delegateRoot.groupTag)
                    }
                }

                Component {
                    id: tagsCollapsible
                    FormDelegateCollapsible {
                        text: i18nc("List of tags classified as stable, testing, etc", "List of %1 tags".arg(delegateRoot.groupTag))

                        // TODO: This looks bad, but clearly differentiates lists from buttons
                        button.trailing: KG.Icon {
                            source: "cursor-arrow"
                            implicitHeight: 24
                            implicitWidth: 24
                        }
                        button.trailingLogo.visible: false

                        ListView {
                            id: tagsView
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(contentHeight, root.maxListHeight)
                            clip: true
                            model: delegateRoot.groupList

                            KG.WheelHandler {
                                target: tagsView
                            }

                            QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                                id: vbar
                                policy: QQC2.ScrollBar.AlwaysOn
                            }
                            readonly property real scrollbarWidth: vbar.visible ? vbar.width : 0

                            delegate: FC.FormButtonDelegate {
                                required property string modelData
                                readonly property bool isCurrent: modelData === root.currentTag

                                width: tagsView.width - tagsView.scrollbarWidth
                                text: isCurrent ? modelData + " " + i18n("(Current Tag)") : modelData
                                enabled: AppState.allowCommands && !isCurrent
                                onClicked: root.tagClicked(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
