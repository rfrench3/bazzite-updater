// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater

Loader {
    // TODO: don't rely so heavily on ublue-specific information
    active: OtherUtilsBackend.currentImage.load_successful && AppData.ostree.valid
    visible: active

    Layout.fillWidth: true

    sourceComponent: FC.FormCard {
        FC.FormTextDelegate {
            id: stagedImageInfo
            visible: !AppData.ostree.onLatestDeployment()
            text: i18n("There is a pending system update. You must reboot to apply it.")
            font.bold: true
        }

        FormDelegateSeparatorFixed {
            visible: stagedImageInfo.visible
        }

        FC.FormTextDelegate {
            textItem.wrapMode: Text.WordWrap
            text: OtherUtilsBackend.currentImage.name + ":" + OtherUtilsBackend.currentImage.branch
            description: i18n("Current Image")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            textItem.wrapMode: Text.WordWrap
            text: {
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

            description: i18n("Last Update")
        }

        FormDelegateSeparatorFixed {
            visible: driverInfo.visible
        }

        FC.FormTextDelegate {
            id: driverInfo
            visible: AppData.gpu.best !== Gpu.Drivers.UNKNOWN

            text: {
                switch (AppData.gpu.best) {
                case Gpu.Drivers.BASE:
                    return i18n("The best drivers for your GPU are provided by the Linux kernel.");
                case Gpu.Drivers.NVIDIA:
                    return i18n("The best drivers for your GPU are ") + "nvidia.";
                case Gpu.Drivers.NVIDIA_OPEN:
                    return i18n("The best drivers for your GPU are ") + "nvidia-open.";
                case Gpu.Drivers.UNSUPPORTED:
                    return i18n("Your GPU is unsupported.");
                case Gpu.Drivers.UNKNOWN:
                    return "";
                default:
                    return "Report to the app developer if you see this!";
                }
            }

            readonly property int __current: {
                // Directly check for the few images that have the legacy drivers
                if (["bazzite-nvidia", "bazzite-gnome-nvidia"].includes(OtherUtilsBackend.currentImage.name))
                    return Gpu.Drivers.NVIDIA;
                else if (OtherUtilsBackend.currentImage.name.includes("nvidia"))
                    return Gpu.Drivers.NVIDIA_OPEN;
                else
                    return Gpu.Drivers.BASE;
            }

            description: {
                if (AppData.gpu.best == __current)
                    return i18n("You have the best drivers installed.");

                switch (__current) {
                case Gpu.Drivers.BASE:
                    return i18n("You do not have any nvidia drivers installed.");
                case Gpu.Drivers.NVIDIA:
                    return i18n("You currently have nvidia installed.");
                case Gpu.Drivers.NVIDIA_OPEN:
                    return i18n("You currently have nvidia-open installed.");
                }
            }
        }

        FormDelegateSeparatorFixed {
            visible: detailedInfo.visible
            below: detailedInfo.itemBelowPrev
        }

        FormDelegateCollapsible {
            id: detailedInfo

            text: expanded ? i18n("Display less information") : i18n("Display more information")

            FC.FormTextDelegate {
                text: OtherUtilsBackend.currentImage.name || i18n("loading...")
                description: i18n("Image")
            }

            FormDelegateSeparatorFixed {}

            FC.FormTextDelegate {
                text: OtherUtilsBackend.currentImage.vendor || i18n("loading...")
                description: i18n("Vendor")
            }

            FormDelegateSeparatorFixed {}

            FC.FormTextDelegate {
                text: OtherUtilsBackend.currentImage.ref || i18n("loading...")
                description: i18n("Ref")
            }

            FormDelegateSeparatorFixed {}

            FC.FormTextDelegate {
                text: OtherUtilsBackend.currentImage.tag || i18n("loading...")
                description: i18n("Tag")
            }

            FormDelegateSeparatorFixed {}

            FC.FormTextDelegate {
                text: OtherUtilsBackend.currentImage.branch || i18n("loading...")
                description: i18n("Branch")
            }

            FormDelegateSeparatorFixed {}

            FC.FormTextDelegate {
                text: OtherUtilsBackend.currentImage.baseName || i18n("loading...")
                description: i18n("Base Name")
            }

            FormDelegateSeparatorFixed {}

            FC.FormTextDelegate {
                text: OtherUtilsBackend.currentImage.fedoraVersion || i18n("loading...")
                description: i18n("Fedora Version")
            }

            FormDelegateSeparatorFixed {}

            FC.FormTextDelegate {
                text: OtherUtilsBackend.currentImage.version || i18n("loading...")
                description: i18n("Version")
            }

            FormDelegateSeparatorFixed {}

            FC.FormTextDelegate {
                text: OtherUtilsBackend.currentImage.versionPretty || i18n("loading...")
                description: i18n("Version (Pretty)")
            }

            FormDelegateSeparatorFixed {}

            FC.FormTextDelegate {
                text: OtherUtilsBackend.currentImage.datePretty["day"] + " " + OtherUtilsBackend.currentImage.datePretty["month"] + ", " + OtherUtilsBackend.currentImage.datePretty["year"] || i18n("loading...")
                description: i18n("Release Date")
            }
        }
    }
}
