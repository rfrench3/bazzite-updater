// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.controllable as GP

// TODO:
// - improve controller support for selections. It can be navigated, but left/right should move to buttons to the left/right
// - finish frontend
// - begin/finish backend
// - move all system image formcards to FCSystemImage

AppPage {
    id: page

    title: GP.Labels.east + GP.Labels.spacer_large + i18n("Rebase Helper")

    actions: [
        Kirigami.Action {
            id: toggleConsole
            text: "Toggle Console" + GP.Labels.spacer + GP.Labels.north
            shortcut: "F12"
            onTriggered: consoleDrawer.drawerOpen = !consoleDrawer.drawerOpen
        }
    ]

    GP.PageNavigation {
        targetScrollbar: page.scrollBar
        active: !globalDrawer.drawerOpen && !consoleDrawer.drawerOpen
    }
    drawer: consoleDrawer

    AsyncLoader {
        sourceComponent: PageContentLayout {
            id: content

            FC.FormHeader {
                title: i18n("Current System Image")
            }

            FCSystemImage {
                url: OtherUtilsBackend.currentImage.ref
                image: OtherUtilsBackend.currentImage.name
                tag: OtherUtilsBackend.currentImage.branch

                // look for current image in rebase-targets.json
                features: {
                    let targets = AppConfig.rebaseTargets || [];
                    for (let t of targets) {
                        for (let img of (t.images || [])) {
                            if (`${t.url}/${img.name}` === OtherUtilsBackend.currentImage.ref)
                                return img.features;
                        }
                    }
                    return [i18n("Features are unknown")];
                }
            }

            FC.FormHeader {
                title: i18n("Available System Images")
            }

            property var allFeatures: {
                let set = new Set();
                let targets = AppConfig.rebaseTargets || [];
                for (let t of targets) {
                    for (let img of (t.images || [])) {
                        for (let f of (img.features || []))
                            set.add(f);
                    }
                }
                return Array.from(set).sort();
            }

            property var allTags: {
                let set = new Set();
                let targets = AppConfig.rebaseTargets || [];
                for (let t of targets) {
                    for (let img of (t.images || [])) {
                        for (let tag of (img.tags || []))
                            set.add(tag);
                    }
                }
                return Array.from(set).sort();
            }

            property var selectedFeatures: []
            property var selectedTags: []

            readonly property var filteredTargets: {
                const targets = AppConfig.rebaseTargets || [];
                const sFeatures = selectedFeatures;
                const sTags = selectedTags;

                if (sFeatures.length === 0 && sTags.length === 0)
                    return targets;

                return targets.map(target => {
                    const matchedImages = target.images.filter(img => {
                        const featuresMatch = sFeatures.length === 0 || sFeatures.every(f => img.features.includes(f));
                        const tagsMatch = sTags.length === 0 || sTags.every(t => img.tags.includes(t));

                        return featuresMatch && tagsMatch;
                    });

                    // Only keep target if it still has matching images
                    if (matchedImages.length > 0)
                        return {
                            url: target.url,
                            images: matchedImages
                        };

                    return null;
                }).filter(t => t !== null);
            }

            readonly property int filteredImagesCount: {
                if (!filteredTargets || filteredTargets.length === 0)
                    return 0;

                return filteredTargets.reduce((total, target) => total + target.images.length, 0);
            }

            FC.FormHeader {
                title: i18n("Filter by Features")
                visible: content.allFeatures.length > 0
            }
            FC.FormCard {
                visible: content.allFeatures.length > 0

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3

                    Repeater {
                        model: content.allFeatures
                        delegate: Button {
                            required property string modelData
                            text: modelData
                            Layout.fillWidth: true
                            checkable: true
                            flat: true

                            onCheckedChanged: {
                                if (checked) {
                                    content.selectedFeatures = content.selectedFeatures.concat([modelData]);
                                } else {
                                    content.selectedFeatures = content.selectedFeatures.filter(f => f !== modelData);
                                }
                            }
                        }
                    }
                }
            }

            FC.FormHeader {
                title: i18n("Filter by Tags")
                visible: content.allTags.length > 0
            }
            FC.FormCard {

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    visible: content.allTags.length > 0
                    Repeater {
                        model: content.allTags
                        delegate: Button {
                            required property string modelData
                            text: modelData
                            Layout.fillWidth: true
                            checkable: true
                            flat: true

                            onCheckedChanged: {
                                if (checked) {
                                    content.selectedTags = content.selectedTags.concat([modelData]);
                                } else {
                                    content.selectedTags = content.selectedTags.filter(t => t !== modelData);
                                }
                            }
                        }
                    }
                }
            }

            FC.FormHeader {
                title: i18n("Results (%1)", content.filteredImagesCount)
            }

            Repeater {
                model: content.filteredTargets
                delegate: ColumnLayout {
                    id: rebaseDelegate
                    clip: true
                    spacing: Kirigami.Units.gridUnit
                    Layout.fillWidth: true

                    required property string url
                    required property var images

                    Repeater {
                        model: rebaseDelegate.images
                        delegate: FC.FormCard {
                            id: rebaseImgDelegate
                            required property string name
                            required property var features
                            required property var tags

                            FC.FormTextDelegate {
                                text: rebaseImgDelegate.name
                            }

                            FormDelegateSeparatorFixed {}

                            FC.FormTextDelegate {
                                text: "Features: " + (rebaseImgDelegate.features ? rebaseImgDelegate.features.join(", ") : "")
                            }

                            FormDelegateSeparatorFixed {}

                            FC.FormTextDelegate {
                                text: "Tags: " + (rebaseImgDelegate.tags ? rebaseImgDelegate.tags.join(", ") : "")
                            }
                        }
                    }
                }
            }
        }
    }

    ConsoleDrawer {
        id: consoleDrawer
        model: null
    }
}
