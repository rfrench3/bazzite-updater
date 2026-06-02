// SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

ScrollingPage {
    id: page

    title: GP.Labels.east + GP.Labels.spacer_large + i18n("Other Utilities")

    function handleInput(buttonId, button_down) {
        if (button_down == false)
            return;

        if (consoleDrawer.drawerOpen) {
            consoleDrawer.handleInput(buttonId, button_down);
            return;
        }

        switch (buttonId) {
        case 3: // Y
            toggleConsole.trigger();
            // Closes up to 5 passive notifications
            for (let i = 0; i < 5; ++i) {
                hidePassiveNotification();
            }
            break;
        }
    }

    actions: [
        Kirigami.Action {
            id: toggleConsole
            text: "Toggle Console" + GP.Labels.spacer + GP.Labels.north
            shortcut: "F12"
            onTriggered: consoleDrawer.drawerOpen = !consoleDrawer.drawerOpen
        }
    ]

    GP.PageNavigation {
        targetScrollbar: consoleDrawer.drawerOpen ? null : page.scrollBar
        active: !globalDrawer.drawerOpen
    }

    FC.FormHeader {
        title: i18n("Rollback Last Update")
        enabled: rollbackFC.enabled
    }

    FC.FormCard {
        id: rollbackFC

        enabled: AppState.isBrhPresent && AppState.allowCommands || (typeof TestingMode !== "undefined" && TestingMode)

        FC.FormTextDelegate {
            text: i18n("This will return your base system to before its current update. Your user files will not be affected, and the system will not automatically update until told to do so again.")
            textItem.wrapMode: Text.Wrap
        }

        FC.FormDelegateSeparator {}

        FC.FormCheckDelegate {
            id: rollbackConfirm
            text: i18n("Confirm")

            enabled: !AppState.rollbackRunning && !AppState.commandSucceeded
        }

        FC.FormDelegateSeparator {}

        FC.FormButtonDelegate {
            text: i18n("Initiate Rollback")
            enabled: rollbackConfirm.checked && rollbackConfirm.enabled

            onClicked: {
                showPassiveNotification(i18n("Rollback Started"), Kirigami.short);
                RebaseHelperBackend.rollbackImage(function (callback) {
                    if (callback != 0) {
                        showPassiveNotification(i18n("Rollback Failed."), Kirigami.long, i18n("Open console") + GP.Labels.spacer + GP.Labels.north, consoleDrawer.open);
                    } else {
                        showPassiveNotification(i18n("Rollback Succeeded!"), Kirigami.short);
                    }
                });
            }

            trailing: QQC2.BusyIndicator {
                id: rollbackBusyIndicator
                running: AppState.rollbackRunning
            }
            trailingLogo.visible: !rollbackBusyIndicator.running
        }
    }


    Loader {
        active: !AppState.isBrhPresent // || AppState.isGamescopeSession 
        Layout.fillWidth: true
        
        sourceComponent: FC.FormCard {
            visible: brhPresentMessage.visible
            FC.FormTextDelegate {
                id: brhPresentMessage
    
                visible: text !== ""
    
                font.bold: true
                textItem.wrapMode: Text.WordWrap
    
                text: {
                    if (!AppState.isBrhPresent)
                        return i18n("Bazzite Rollback Helper is not present on the system. It is required to perform a System Rollback or Rebase.");
                    // else if (AppState.isGamescopeSession) // NOTE: Re-add this when Rebasing is re-added
                    //     return i18n("The app is being run in Steam's Gamescope Session. Switch to Desktop mode to use the System Rebase feature.");
                    else
                        return "";
                }
            }
        }
    }

    FC.FormHeader {
        title: i18n("System Image Information")
    }

    FC.FormCard {
        FC.FormTextDelegate {
            textItem.wrapMode: Text.WordWrap
            text: RebaseHelperBackend.currentImage.name + ":" + RebaseHelperBackend.currentImage.branch

            description: i18n("Current Image")
        }

        FC.FormDelegateSeparator {}

        FC.FormTextDelegate {
            textItem.wrapMode: Text.WordWrap
            text: RebaseHelperBackend.currentImage.datePretty["day"] + " " + RebaseHelperBackend.currentImage.datePretty["month"] + ", " + RebaseHelperBackend.currentImage.datePretty["year"]

            description: i18n("Last Update")
        }
    
        FC.FormDelegateSeparator {
            visible: RebaseHelperBackend.bestDriver != Gpu.Drivers.UNKNOWN
        }
        
        Loader {
            active: RebaseHelperBackend.bestDriver != Gpu.Drivers.UNKNOWN
            Layout.fillWidth: true
            
            sourceComponent: FC.FormTextDelegate {
                text: {
                    switch (RebaseHelperBackend.bestDriver) 
                    {
                        case Gpu.Drivers.BASE:          return i18n("The best drivers for your GPU are provided by the Linux kernel.");
                        case Gpu.Drivers.NVIDIA:        return i18n("The best drivers for your GPU are ") + "nvidia.";
                        case Gpu.Drivers.NVIDIA_OPEN:   return i18n("The best drivers for your GPU are ") + "nvidia-open.";
                        case Gpu.Drivers.UNSUPPORTED:   return i18n("Your GPU is unsupported.");
                        case Gpu.Drivers.UNKNOWN:       return "";
                        default:                            return "Report to the app developer if you see this!";
                    }
                }

                readonly property int __current: {
                    if (RebaseHelperBackend.currentImage.name.endsWith("nvidia-open")) return Gpu.Drivers.NVIDIA_OPEN
                    else if (RebaseHelperBackend.currentImage.name.endsWith("nvidia")) return Gpu.Drivers.NVIDIA
                    else return Gpu.Drivers.BASE
                }

                description: {
                    if (RebaseHelperBackend.bestDriver == __current) return i18n("You have the best drivers installed.");
                    
                    switch (current) 
                    {
                        case Gpu.Drivers.BASE:          return i18n("You do not have any nvidia drivers installed.");
                        case Gpu.Drivers.NVIDIA:        return i18n("You currently have nvidia installed.");
                        case Gpu.Drivers.NVIDIA_OPEN:   return i18n("You currently have nvidia-open installed.");
                    }
                }
            }
        }

    }

    FCSystemInfo {}

    ConsoleDrawer {
        id: consoleDrawer
        model: RebaseHelperBackend.consoleModel
    }
}
