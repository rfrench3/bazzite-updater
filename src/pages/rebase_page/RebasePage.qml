// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.controllable as GP
import io.github.rfrench3.bazzite_updater

// TODO:
// - improve controller support for selections. It can be navigated, but left/right should move to buttons to the left/right
// - formcard separators are weird and need to be fixed
// - make sure controller scrolling works in the tag list
// - figure out the best way to display "tag" button vs "list of tags" dropdown
// - controller/tab navigation order and scrolling and ensuring selected item stays displayed
// - the buttons on the rebase tag vs rebase tags list should be significantly different

AppPage {
    id: page

    readonly property var currentImage: ({
            url: RebaseModel.currentImage.url,
            name: RebaseModel.currentImage.name,
            tags: RebaseModel.currentImage.tags,
            features: RebaseModel.currentImage.features,
            currentTag: RebaseModel.currentImage.currentTag,
            ref: `${RebaseModel.currentImage.url}/${RebaseModel.currentImage.name}`
        })

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
                id: currentImage

                url: page.currentImage.url
                name: page.currentImage.name
                tags: page.currentImage.tags
                features: page.currentImage.features

                currentTag: page.currentImage.currentTag

                onTagClicked: tag => {
                    if (tag === currentTag)
                        return;
                    rebaseDialog.imageRef = page.currentImage.ref;
                    rebaseDialog.tag = tag;
                    AppDialogManager.show(rebaseDialog);
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

            FC.FormHeader {
                title: i18n("Filter by Features")
                visible: content.allFeatures.length > 0
            }
            FC.FormCard {
                visible: content.allFeatures.length > 0

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4

                    Repeater {

                        // If
                        readonly property var filteredModel: {
                            if (currentImage.features.includes("kde") || currentImage.features.includes("gnome"))
                                return content.allFeatures.filter(f => (f !== "kde" && f !== "gnome"));
                            else
                                return content.allFeatures;
                        }

                        model: filteredModel
                        delegate: Button {
                            required property string modelData
                            text: modelData
                            Layout.fillWidth: true
                            checkable: true
                            flat: true
                            visible: enabled

                            onCheckedChanged: {
                                if (checked) {
                                    RebaseModel.features = RebaseModel.features.concat([modelData]);
                                } else {
                                    RebaseModel.features = RebaseModel.features.filter(f => f !== modelData);
                                }
                            }
                        }
                    }
                }
            }

            FC.FormHeader {
                title: i18n("Results (%1)", RebaseModel.filtered.length)
            }

            Repeater {
                model: RebaseModel.filtered

                delegate: FCSystemImage {
                    id: imageCard
                    Layout.topMargin: Kirigami.Units.mediumSpacing

                    onTagClicked: tag => {
                        rebaseDialog.imageRef = `${imageCard.url}/${imageCard.name}`;
                        rebaseDialog.tag = tag;
                        AppDialogManager.show(rebaseDialog);
                    }
                }
            }
        }
    }

    AppDialog {
        id: rebaseDialog

        property string imageRef: ""
        property string tag: ""

        readonly property string subtitleImage: {
            if (imageRef === page.currentImage.ref)
                return tag;
            else
                return `${imageRef}:${tag}`;
        }

        titleStart: i18n("Confirm rebase")
        subtitle: i18n("Rebase to %1? This will take a long time, and you will need to restart afterwards to apply the changes.\n\nYou may need to input your password multiple times to proceed.", subtitleImage)
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        onAccepted: {
            RebaseModel.runRebase(`${imageRef}:${tag}`, exit_code => {
                if (exit_code === 0)
                    showPassiveNotification(i18n("The rebase succeeded! Restart to apply changes."));
                else
                    showPassiveNotification(i18n("The rebase failed. Check the console for more information."));
            });
        }

        function handleInput(buttonId, button_down) {
            if (!button_down)
                return;
            switch (buttonId) {
            case 0: // A
                rebaseDialog.accept();
                break;
            case 1: // B
                rebaseDialog.reject();
                break;
            }
        }
    }

    ConsoleDrawer {
        id: consoleDrawer
        model: RebaseModel.consoleModel
    }
}
