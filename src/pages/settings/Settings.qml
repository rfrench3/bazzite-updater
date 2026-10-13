// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

FC.FormCardPage {
    id: page

    title: GP.Labels.east + GP.Labels.spacer_large + i18n("Settings")

    function grabScrollbar(item) {
        if (item.contentItem?.ScrollBar?.vertical)
            return item.contentItem.ScrollBar.vertical;

        if (item.parent)
            return grabScrollbar(item.parent);

        console.warn("Parent scrollbar not found, controller scrolling will not function!");
    }
    property ScrollBar scrollbar: page.grabScrollbar(page)

    GP.PageNavigation {
        targetScrollbar: page.scrollbar
        active: !globalDrawer.drawerOpen
    }

    FC.FormHeader {
        title: i18n("Interface Settings")
    }

    FC.FormCard {
        FC.FormSwitchDelegate {
            text: i18n("Reboot on exit reminder")
            description: i18n("Display a popup when exiting the app after a command completes, reminding you to reboot to apply changes.")

            checked: UserSettings.showRebootReminder

            onToggled: {
                UserSettings.showRebootReminder = checked;

                // Assigning to checked drops the binding, put it back
                checked = Qt.binding(() => UserSettings.showRebootReminder);
            }
        }

        FormDelegateSeparatorFixed {}

        FC.FormSwitchDelegate {
            text: i18n("Default fullscreen state")
            description: i18n("Should the application launch in fullscreen mode?")

            checked: UserSettings.preferFullscreen

            onToggled: {
                UserSettings.preferFullscreen = checked;

                // Assigning to checked drops the binding, put it back
                checked = Qt.binding(() => UserSettings.preferFullscreen);
            }
        }

        FormDelegateSeparatorFixed {}

        FC.FormSwitchDelegate {
            text: i18n("Default console state")
            description: i18n("Should the console panels start opened?")

            checked: UserSettings.preferConsole

            onToggled: {
                UserSettings.preferConsole = checked;

                // Assigning to checked drops the binding, put it back
                checked = Qt.binding(() => UserSettings.preferConsole);
            }
        }
    }

    FC.FormCard {
        Layout.topMargin: Kirigami.Units.mediumSpacing

        FC.FormButtonDelegate {
            text: i18n("Restore Defaults")
            icon.name: "edit-undo-symbolic"
            enabled: !UserSettings.isDefault

            onClicked: UserSettings.restoreDefaults()
        }
    }

    FC.FormHeader {
        title: i18n("OS Settings (read-only)")
    }

    FC.FormCard {
        FC.FormTextDelegate {
            text: AppConfig.ini.Commands?.systemUpdateCommand
            description: i18n("System Update Command")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            text: AppConfig.ini.Commands?.systemRollbackCommand || i18n("No system rollback command is defined.")
            description: i18n("System Rollback Command")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            text: AppConfig.ini.Commands?.allowEarlyExit
            description: i18n("Allow commands to be cancelled early?")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            text: AppConfig.ini.General?.rssFeed
            description: i18n("Changelogs RSS feed")
        }
    }
}
