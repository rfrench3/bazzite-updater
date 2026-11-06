// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

Kirigami.Page {
    id: page

    // Global drawer gamepad labels are placed in the page titles
    title: GP.Labels.east + GP.Labels.spacer_large + i18n("System Update")

    function handleInput(buttonId: int, button_down: bool): void {
        if (button_down == false)
            return;

        switch (buttonId) {
        case 0: // A
            updateButton.animateClick();
            return;
        }

        if (consoleDrawer.drawerOpen) {
            consoleDrawer.handleInput(buttonId, button_down);
            return;
        }

        switch (buttonId) {
        case 3: // Y
            toggleConsole.trigger();
            break;
        }
    }

    actions: [
        Kirigami.Action {
            id: updateAction
            text: i18n("Start update") + GP.Labels.spacer + GP.Labels.south
            shortcut: "Return"
            enabled: AppState.allowCommands && !SystemUpdateBackend.blockUpdate && (AppConfig.ini.Commands?.systemUpdateCommand || "")

            onTriggered: {
                sessionStorage.mainText = i18n("System Updating");

                showPassiveNotification(i18n("Update Started"), Kirigami.short);
                SystemUpdateBackend.runUpdate(callback => {
                    if (callback != 0) {
                        if (consoleDrawer.drawerOpen) {
                            showPassiveNotification(i18n("Update Failed."), Kirigami.short);
                        } else {
                            showPassiveNotification(i18n("Update Failed. Check console for more details."), Kirigami.long, i18n("Open console") + GP.Labels.spacer + GP.Labels.north, () => {
                                toggleConsole.trigger();
                            });
                        }
                        sessionStorage.mainText = "";
                        return;
                    }

                    showPassiveNotification(i18n("Update Succeeded!"), Kirigami.short);
                    sessionStorage.updateCompleted = true;
                    sessionStorage.mainText = i18n("System Updated!");

                    AppData.reloadOstree(() => {
                        if (!AppData.ostree.onLatestDeployment())
                            showPassiveNotification(i18n("You must reboot to apply changes."), Kirigami.short);
                        else
                            showPassiveNotification(i18n("No reboot necessary."), Kirigami.short);
                    });
                }, errorMessage => {
                    errorDialog.subtitle = errorMessage;
                    AppDialogManager.show(errorDialog);
                });
            }
        },
        Kirigami.Action {
            id: toggleConsole
            text: i18n("Toggle Console") + GP.Labels.spacer + GP.Labels.north
            shortcut: "F12"
            onTriggered: {
                // hide notifications when opening the drawer
                if (!consoleDrawer.drawerOpen) {
                    for (let i = 0; i < 5; ++i) {
                        hidePassiveNotification();
                    }
                }

                consoleDrawer.drawerOpen = !consoleDrawer.drawerOpen;
            }
        }
    ]

    AppDialog {
        id: errorDialog
        titleStart: i18n("Update Error")
        standardButtons: Kirigami.Dialog.NoButton

        subtitle: i18n("This will reboot the system.")

        customFooterActions: [
            Kirigami.Action {
                id: errorDialogConfirm
                text: i18n("Ok") + GP.Labels.spacer + GP.Labels.south

                onTriggered: errorDialog.accept()
            }
        ]

        function handleInput(buttonId, button_down) {
            if (!button_down)
                return;
            switch (buttonId) {
            case 0: // A
                errorDialogConfirm.triggered();
                break;
            case 1: // B
                errorDialogConfirm.triggered();
                break;
            }
        }
    }

    ColumnLayout {
        id: pageContents
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        spacing: Kirigami.Units.gridUnit

        RowLayout {
            Layout.alignment: Qt.AlignHCenter

            Item {
                implicitWidth: Kirigami.Units.gridUnit * 5
                implicitHeight: implicitWidth

                Image {
                    anchors.fill: parent

                    source: (AppData.aboutDataOs.programLogo) ? "file:/" + AppData.aboutDataOs.programLogo : "qrc:/fallbackLogo"

                    sourceSize: Qt.size(width, height)
                    antialiasing: true
                }
            }

            Kirigami.Heading {
                text: sessionStorage.mainText || i18n("System Update")
            }
        }

        FC.FormCard {
            id: updateFC

            // Ensures the card does not act like it is width-constrained
            // NOTE: The card's real width is currently bound by the fixed-width progress bar below this FC
            maximumWidth: pageContents.implicitWidth - Kirigami.Units.smallSpacing

            FC.FormButtonDelegate {
                id: updateButton
                text: i18n("Click to update System Image and Software")
                enabled: updateAction.enabled

                onClicked: {
                    updateAction.trigger();
                }

                trailing: Loader {
                    sourceComponent: {
                        if (AppState.updateRunning)
                            return busyComponent;
                        if (AppState.commandSucceeded)
                            return checkmarkComponent;
                        return labelComponent;
                    }

                    Component {
                        id: busyComponent
                        QQC2.BusyIndicator {
                            id: busyIndicator
                            running: AppState.updateRunning
                        }
                    }

                    Component {
                        id: checkmarkComponent
                        Kirigami.Icon {
                            source: "checkmark-symbolic"
                            visible: sessionStorage.updateCompleted || false
                        }
                    }

                    Component {
                        id: labelComponent
                        Kirigami.Heading {
                            text: GP.Labels.south
                        }
                    }
                }

                trailingLogo.visible: !AppState.updateRunning && !AppState.commandSucceeded

                description: {
                    const last_update = i18nc("label, last update to the system.", "Last Update") + ": ";
                    if (sessionStorage.updateCompleted)
                        return last_update + i18n("Right now!");

                    const date = getDate();

                    if (date)
                        return last_update + date;

                    return "";
                }

                function getDate(): string {
                    // 8 digits starting with 202 or 203, not part of a longer digit run
                    // TODO: fix this before the year 2040
                    let match = /(?:^|\D)(20[23]\d{5})(?!\d)/.exec(AppData.osRelease["VERSION"]);
                    if (!match)
                        match = /(?:^|\D)(20[23]\d{5})(?!\d)/.exec(AppData.osRelease["VERSION_ID"]);

                    if (!match)
                        return "";

                    const year = parseInt(match[1].slice(0, 4), 10);
                    const month = parseInt(match[1].slice(4, 6), 10);
                    const day = parseInt(match[1].slice(6, 8), 10);

                    // Make sure the result is a valid date, not any 8-digit string that happens to start with 202/203
                    const date = new Date(year, month - 1, day);
                    if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day)
                        return "";

                    return Qt.formatDate(date, "d MMMM yyyy");
                }
            }

            FormDelegateSeparatorFixed {
                visible: errorUpdateNotFound.visible
            }

            FC.FormTextDelegate {
                id: errorUpdateNotFound
                visible: !(AppConfig.ini.Commands?.systemUpdateCommand || "")
                enabled: visible
                text: i18n("The System Update command is not defined.")
                description: i18n("Make sure the config file (/etc/bazzite-updater/config.ini) is present.")
            }
        }
        UpdateSteps {}
        Item {
            implicitWidth: Kirigami.Units.gridUnit * 19
        }
    }

    // Resolves https://github.com/rfrench3/bazzite-updater/issues/56
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Kirigami.Units.gridUnit

        QQC2.Label {
            id: storageLabel
            // the double arg keeps the confusing "%1%" out of a translation string
            text: i18nc("progress bar displaying used storage space vs total available space", "System Drive Used (%1)", "%1%".arg(Math.floor(AppData.storageSpace.used * 100 / AppData.storageSpace.total)))

            // Putting colors here instead of just in the progress bar to avoid "binding loop detected" spam
            readonly property color okColor: Kirigami.Theme.highlightColor
            readonly property color warnColor: Kirigami.Theme.neutralTextColor
            readonly property color critColor: Kirigami.Theme.negativeTextColor
        }
        QQC2.ProgressBar {
            id: storageBar
            from: 0
            to: AppData.storageSpace.total
            value: AppData.storageSpace.used

            property color barColor: {
                const ratio = AppData.storageSpace.used / Math.max(1, AppData.storageSpace.total);
                if (ratio > 0.9)
                    return storageLabel.critColor;
                if (ratio > 0.7)
                    return storageLabel.warnColor;
                return storageLabel.okColor;
            }

            Behavior on barColor {
                ColorAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }

            Behavior on value {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }

            Behavior on to {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }

            Kirigami.Theme.inherit: false
            Kirigami.Theme.highlightColor: barColor
            Kirigami.Theme.focusColor: barColor
            Kirigami.Theme.alternateBackgroundColor: barColor

            palette.highlight: barColor
            palette.dark: barColor
        }
    }

    ConsoleDrawer {
        id: consoleDrawer
        model: SystemUpdateBackend.consoleModel

        readonly property ostreeDeployment __img: AppData.ostree.deployments.find(img => img.isCurrent)
        readonly property int __layeredCount: __img.layeredPackages?.length || 0

        includeAtStart: {
            const list = ["Bazzite Updater %1".arg(ApplicationVersion)];

            if (RebaseModel.currentImage.name && RebaseModel.currentImage.currentTag)
                list.push(`${RebaseModel.currentImage.name}:${RebaseModel.currentImage.currentTag}`);

            if (OtherUtilsBackend.currentImage.version)
                list.push(OtherUtilsBackend.currentImage.version);

            if (__layeredCount !== 0)
                list.push(i18np("%1 Layered package", "%1 Layered packages", __layeredCount));

            return list.join('\n');
        }

        Item {
            Layout.fillHeight: true
        }

        // displays useful information in a page users usually screenshot when something goes wrong
        QQC2.Label {
            text: consoleDrawer.includeAtStart
            color: systemPalette.placeholderText
        }

        SystemPalette {
            id: systemPalette
            colorGroup: SystemPalette.Active
        }
    }
}
