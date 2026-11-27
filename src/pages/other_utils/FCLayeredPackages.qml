// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as KG
import org.kde.kirigamiaddons.formcard as FC
import io.github.rfrench3.bazzite_updater
import QtQml.Models

FC.FormCard {
    id: root

    property real maxListHeight: KG.Units.gridUnit * 16

    readonly property ostreeDeployment currentImage: AppData.ostree.currentDeployment
    readonly property ostreeDeployment stagedImage: AppData.ostree.stagedDeployment
    readonly property ostreeDeployment removeTarget: stagedImage.isValid ? stagedImage : currentImage

    // target: `rpm-ostree remove` will use the staged image if it exists, and will use the booted image otherwise.

    readonly property list<string> stagedLayered: stagedImage.layeredPackages
    readonly property list<string> currentLayered: currentImage.layeredPackages
    readonly property list<string> targetLayered: removeTarget.layeredPackages
    property list<string> selectedPackages: []

    onTargetLayeredChanged: {
        root.selectedPackages = [];
        root.removeCompleted = false;
    }

    visible: currentLayered.length !== 0 || stagedLayered.length !== 0

    signal listViewFocused(Item item)

    signal rpmOstreeRemoveClicked(list<string> packages)
    signal rpmOstreeResetClicked

    property bool removeRunning: false
    property bool removeCompleted: false

    property bool resetRunning: false
    property bool resetCompleted: false

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
            return item as ListView;

        return QmlUtils.getParentOfType(item, ListView);
    }

    FormDelegateCollapsible {
        id: layeredPackagesInfo

        text: expanded ? i18n("Close layered packages view") : i18n("View layered packages")

        FC.FormTextAreaDelegate {
            id: activeTextArea
            label: i18n("Active Layered Packages (%1):", root.currentLayered.length)
            readOnly: true
            text: root.currentLayered.join(", ") || i18nc("Displayed when a list of layered packages is empty", "None")
            description: stagedTextArea.visible ? i18n("Active Layered Packages are present on your running system, while Staged Layered Packages will become active only after you reboot. The controls apply to Staged Layered Packages") : stagedTextArea.description
        }

        FC.FormTextAreaDelegate {
            id: stagedTextArea
            visible: root.stagedImage.isValid
            label: i18n("Staged Layered Packages (%1):", root.stagedLayered.length)
            readOnly: true
            text: root.stagedLayered.join(", ") || i18nc("Displayed when a list of layered packages is empty", "None")
            description: i18n("Layering packages is a last-resort for when there is no other way to install a package. Avoid layering packages whenever possible, as it can cause system updates to fail.")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            visible: AppState.isGamescopeSession

            textItem.font.bold: true
            textItem.wrapMode: Text.WordWrap
            text: i18n("Certain features, such as managing layered packages and rebasing, require your password and are only available in desktop mode. Please open Bazzite Updater in desktop mode to access these features.")
        }

        FormDelegateSeparatorFixed {
            visible: AppState.isGamescopeSession
        }

        FormListView {
            id: tagsView

            // first two elements are just filler items to place first two DelegateChoices
            model: ["index0", "index1"].concat(root.targetLayered)

            onListViewFocused: x => root.listViewFocused(x)

            delegate: DelegateChooser {

                DelegateChoice {
                    index: 0
                    delegate: FC.FormButtonDelegate {
                        width: tagsView.width - tagsView.scrollbarWidth

                        focusPolicy: Qt.NoFocus

                        enabled: AppState.allowCommands && !AppState.isGamescopeSession && !root.resetCompleted && root.targetLayered.length > 0
                        text: i18n("Remove all layered packages")
                        onClicked: root.rpmOstreeResetClicked()

                        trailing: QQC2.BusyIndicator {
                            running: root.resetRunning
                        }
                        trailingLogo.visible: !root.resetRunning
                    }
                }

                DelegateChoice {
                    index: 1
                    delegate: FC.FormButtonDelegate {
                        id: buttonRemove
                        width: tagsView.width - tagsView.scrollbarWidth

                        focusPolicy: Qt.NoFocus

                        enabled: root.selectedPackages.length > 0 && AppState.allowCommands && !AppState.isGamescopeSession && !root.removeCompleted && !root.resetCompleted
                        text: i18n("Remove selected packages")
                        onClicked: root.rpmOstreeRemoveClicked(root.selectedPackages)

                        trailing: QQC2.BusyIndicator {
                            running: root.removeRunning
                        }
                        trailingLogo.visible: !root.removeRunning
                    }
                }

                DelegateChoice {
                    delegate: FC.FormCheckDelegate {
                        required property string modelData

                        width: tagsView.width - tagsView.scrollbarWidth
                        text: modelData

                        // The ListView owns focus
                        focusPolicy: Qt.NoFocus

                        enabled: !AppState.isGamescopeSession

                        checked: root.selectedPackages.includes(modelData)

                        onClicked: {
                            if (checked)
                                root.selectedPackages = root.selectedPackages.concat([modelData]);
                            else
                                root.selectedPackages = root.selectedPackages.filter(pkg => pkg !== modelData);
                        }
                    }
                }
            }
        }
    }
}
