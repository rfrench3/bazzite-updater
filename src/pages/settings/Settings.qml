// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

ScrollingPage {
    id: page

    title: GP.Labels.east + GP.Labels.spacer_large + i18n("Settings")

    GP.PageNavigation {
        targetScrollbar: page.scrollBar
        active: !globalDrawer.drawerOpen
    }

    FC.FormHeader {
        title: i18n("Prompts")
    }

    FC.FormCard {
        FC.FormSwitchDelegate {
            text: i18n("Remind me to reboot on exit")
            description: i18n("After a command has finished, quitting the app asks for confirmation and reminds you that a reboot is needed to apply the changes.")

            checked: UserSettings.showRebootReminder

            onToggled: {
                UserSettings.showRebootReminder = checked;

                // Assigning to checked drops the binding, put it back
                checked = Qt.binding(() => UserSettings.showRebootReminder);
            }
        }
    }

    FC.FormCard {
        Layout.topMargin: Kirigami.Units.largeSpacing * 2

        FC.FormButtonDelegate {
            text: i18n("Restore Defaults")
            icon.name: "edit-undo-symbolic"

            onClicked: {
                UserSettings.restoreDefaults();
                showPassiveNotification(i18n("Default settings restored."), Kirigami.short);
            }
        }
    }
}
