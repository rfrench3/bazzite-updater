import QtQuick
import QtQuick.Layouts
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater

Loader {
    active: RebaseHelperBackend.currentImage.load_successful
    visible: active

    Layout.fillWidth: true

    sourceComponent: FCDropdown {

        buttonText: i18n("Display more information")
        buttonTextExpanded: i18n("Display less information")

        topComponent: ColumnLayout {
            clip: true
            spacing: 0
            Layout.fillWidth: true

            FC.FormTextDelegate {
                textItem.wrapMode: Text.WordWrap
                text: RebaseHelperBackend.currentImage.name + ":" + RebaseHelperBackend.currentImage.branch

                description: i18n("Current Image")
            }

            FormDelegateSeparatorFixed {}

            FC.FormTextDelegate {
                textItem.wrapMode: Text.WordWrap
                text: RebaseHelperBackend.currentImage.datePretty["day"] + " " + RebaseHelperBackend.currentImage.datePretty["month"] + ", " + RebaseHelperBackend.currentImage.datePretty["year"]

                description: i18n("Last Update")
            }

            FormDelegateSeparatorFixed {
                visible: RebaseHelperBackend.bestDriver != Gpu.Drivers.UNKNOWN
            }

            Loader {
                active: RebaseHelperBackend.bestDriver != Gpu.Drivers.UNKNOWN
                Layout.fillWidth: true

                sourceComponent: FC.FormTextDelegate {
                    text: {
                        switch (RebaseHelperBackend.bestDriver) {
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
                        if (RebaseHelperBackend.currentImage.name.endsWith("nvidia-open"))
                            return Gpu.Drivers.NVIDIA_OPEN;
                        else if (RebaseHelperBackend.currentImage.name.endsWith("nvidia"))
                            return Gpu.Drivers.NVIDIA;
                        else
                            return Gpu.Drivers.BASE;
                    }

                    description: {
                        if (RebaseHelperBackend.bestDriver == __current)
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
            }
        }

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.name || i18n("loading...")
            description: i18n("Image")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.vendor || i18n("loading...")
            description: i18n("Vendor")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.ref || i18n("loading...")
            description: i18n("Ref")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.tag || i18n("loading...")
            description: i18n("Tag")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.branch || i18n("loading...")
            description: i18n("Branch")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.baseName || i18n("loading...")
            description: i18n("Base Name")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.fedoraVersion || i18n("loading...")
            description: i18n("Fedora Version")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.version || i18n("loading...")
            description: i18n("Version")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.versionPretty || i18n("loading...")
            description: i18n("Version (Pretty)")
        }

        FormDelegateSeparatorFixed {}

        FC.FormTextDelegate {
            text: RebaseHelperBackend.currentImage.datePretty["day"] + " " + RebaseHelperBackend.currentImage.datePretty["month"] + ", " + RebaseHelperBackend.currentImage.datePretty["year"] || i18n("loading...")
            description: i18n("Release Date")
        }
    }
}
