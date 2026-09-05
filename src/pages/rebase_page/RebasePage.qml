// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.controllable as GP

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
                title: i18n("Rebase System Image")
            }

            readonly property list<var> rebaseTargets: AppConfig.rebaseTargets || []

            Repeater {
                model: content.rebaseTargets
                delegate: ColumnLayout {
                    id: rebaseDelegate

                    clip: true
                    spacing: Kirigami.Units.gridUnit
                    Layout.fillWidth: true

                    required property string url
                    required property list<var> images

                    Repeater {
                        model: rebaseDelegate.images
                        delegate: FC.FormCard {
                            id: rebaseImgDelegate
                            required property string name
                            required property list<string> features
                            required property list<string> tags

                            FC.FormTextDelegate {
                                text: rebaseImgDelegate.name
                            }

                            FormDelegateSeparatorFixed {}

                            FC.FormTextDelegate {
                                text: {
                                    let txt = "Features: ";
                                    for (let idx in rebaseImgDelegate.features) {
                                        txt += rebaseImgDelegate.features[idx] + ", ";
                                    }
                                }
                            }

                            FormDelegateSeparatorFixed {}

                            FC.FormTextDelegate {
                                text: {
                                    let txt = "Tags: ";
                                    for (let idx in rebaseImgDelegate.tags) {
                                        txt += rebaseImgDelegate.tags[idx] + ", ";
                                    }
                                }
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
