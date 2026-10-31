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

// TODO later
// - try to get the separators working

AppPage {
    id: page

    // If a ScrollView of a FCSystemImage is focused, it is stored here
    property Item focusedViewCard: null

    // TODO: Fully replace this when possible
    Item {
        id: gamepadRoot

        property bool active: visible

        Connections {
            target: GP.Gamepad

            function keyEvent(button_down, key) {
                let item = gamepadRoot.Window.window.activeFocusItem;
                if (button_down == true) {
                    // console.log("button down");
                    GP.Gamepad.sendButtonPressed(item, key);
                } else {
                    // console.log("button up");
                    GP.Gamepad.sendButtonReleased(item, key);
                }
            }

            function mouseEvent(button_down, item = gamepadRoot.Window.window.activeFocusItem) {
                if (button_down == true) {
                    GP.Gamepad.sendMousePressed(item);
                    // console.log("mouse down");
                } else {
                    GP.Gamepad.sendMouseReleased(item);
                    // console.log("mouse up");
                }
            }

            function onButtonEvent(buttonId, pressed) {
                if (!gamepadRoot.active)
                    return;

                if (globalDrawer.drawerOpen || consoleDrawer.drawerOpen)
                    return;

                let item = gamepadRoot.Window.window.activeFocusItem;

                switch (buttonId) {
                case 0: // A
                    mouseEvent(pressed);
                    break;
                }
            }
        }

        function __descendantOfParent(item) {
            let cursor = item;
            while (cursor) {
                if (cursor === gamepadRoot.parent)
                    return true;
                cursor = cursor.parent;
            }
            return false;
        }

        function __nextItemInScope(item, forward) {
            if (!item)
                return null;

            let next = item.nextItemInFocusChain(forward);

            for (let i = 0; i < 512; i++) {
                if (__descendantOfParent(next))
                    return next;
                next = next.nextItemInFocusChain(forward);
            }

            console.log("Next item in focus scope not found after 512 tries, returning original item.");

            return item;
        }
    }

    function moreHandleInput(buttonId: int, button_down: bool): bool {
        if (!button_down)
            return false;

        if (globalDrawer.drawerOpen || consoleDrawer.drawerOpen)
            return false;

        const focused = Window.activeFocusItem;
        const card = QmlUtils.getParentOfType(focused, FCSystemImage);

        switch (buttonId) {
        case 1: // B
            return card ? card.closeActiveListView() : false;
        case 11: // Dpad Up
        case 12:
            { // Dpad Down
                const down = buttonId === 12;
                if (card && (down ? card.incrementListView() : card.decrementListView()))
                    return true;

                const grid = QmlUtils.getParentOfType(focused, NavGrid);
                let start = focused;
                if (grid) {
                    if (grid.moveVertical(focused, down))
                        return true;
                    // Start the focus-chain search from the grid's first/last button so we
                    // exit the grid instead of stepping to the next button in the same row
                    start = grid.edgeChild(down);
                }

                // List absent or at its end: move focus normally
                const next = gamepadRoot.__nextItemInScope(start, down);
                if (next)
                    next.forceActiveFocus(Qt.TabFocusReason);
                return true;
            }
        case 13:
        case 14:
            { // Dpad left/right
                const right = buttonId === 14;

                const grid = QmlUtils.getParentOfType(focused, NavGrid);
                if (grid) {
                    grid.moveHorizontal(focused, right);
                    return true;
                }

                const next = gamepadRoot.__nextItemInScope(focused, right);
                if (next)
                    next.forceActiveFocus(Qt.TabFocusReason);
                return true;
            }
        }
        return false;
    }

    readonly property var currentImage: ({
            url: RebaseModel.currentImage.url,
            name: RebaseModel.currentImage.name,
            tags: RebaseModel.currentImage.tags,
            features: RebaseModel.currentImage.features,
            currentTag: RebaseModel.currentImage.currentTag,
            ref: `${RebaseModel.currentImage.url}/${RebaseModel.currentImage.name}`
        })

    title: GP.Labels.east + GP.Labels.spacer_large + i18n("Rebase Helper")

    actionToggleDrawer: toggleConsole
    actions: [
        Kirigami.Action {
            id: toggleConsole
            text: "Toggle Console" + GP.Labels.spacer + GP.Labels.north
            shortcut: "F12"
            onTriggered: consoleDrawer.drawerOpen = !consoleDrawer.drawerOpen
        }
    ]

    GP.ScrollHandler {
        target: page.focusedViewCard ? getScrollbar(page.focusedViewCard) : page.scrollBar
        active: !globalDrawer.drawerOpen && !consoleDrawer.drawerOpen

        function getScrollbar(item) {
            if (!item)
                return page.scrollBar;
            if (item instanceof ListView)
                return item.scrollbar;
            if (item.parent)
                return getScrollbar(item.parent);
        }
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

                onListViewFocused: item => {
                    page.focusedViewCard = item;
                }
            }

            FC.FormHeader {
                title: i18n("Available System Images")
                Layout.topMargin: Kirigami.Units.gridUnit
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

                NavGrid {
                    Layout.fillWidth: true
                    columns: 4

                    Repeater {
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

                    onListViewFocused: item => {
                        page.focusedViewCard = item;
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
        subtitle: i18n("This will take a long time, and you will need to restart afterwards to apply the changes.\nTarget: %1\n\nYou may need to input your password multiple times to proceed. If you rebase to a tag with a date or version, you will not get system-level security and feature updates until you return to a base tag.", subtitleImage)
        standardButtons: Kirigami.Dialog.NoButton

        onAccepted: {
            RebaseModel.runRebase(`${imageRef}:${tag}`, exit_code => {
                if (exit_code === 0)
                    showPassiveNotification(i18n("The rebase succeeded! Restart to apply changes."));
                else
                    showPassiveNotification(i18n("The rebase failed. Check the console for more information."));
            });
        }

        customFooterActions: [
            Kirigami.Action {
                id: confirmExit
                text: i18nc("Dialog confirmation", "Ok") + GP.Labels.spacer + GP.Labels.south
                onTriggered: rebaseDialog.accept()
            },
            Kirigami.Action {
                id: cancelExit
                text: i18n("Cancel") + GP.Labels.spacer + GP.Labels.east
                onTriggered: rebaseDialog.reject()
            }
        ]

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
