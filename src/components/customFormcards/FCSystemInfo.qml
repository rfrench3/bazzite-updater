import QtQuick
import QtQuick.Layouts
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater

Loader {
    active: OtherUtilsBackend.currentImage.load_successful
    visible: active

    Layout.fillWidth: true

    sourceComponent: FormCardCollapsible {

        buttonText: expanded ? i18n("Display less information") : i18n("Display more information")

        topComponent: ColumnLayout {
            clip: true
            spacing: 0
            Layout.fillWidth: true

            FC.FormTextDelegate {
                textItem.wrapMode: Text.WordWrap
                text: OtherUtilsBackend.currentImage.name + ":" + OtherUtilsBackend.currentImage.branch

                description: i18n("Current Image")
            }

            FormDelegateSeparatorFixed {}

            FC.FormTextDelegate {
                textItem.wrapMode: Text.WordWrap
                text: OtherUtilsBackend.currentImage.datePretty["day"] + " " + OtherUtilsBackend.currentImage.datePretty["month"] + ", " + OtherUtilsBackend.currentImage.datePretty["year"]

                description: i18n("Last Update")
            }

            FormDelegateSeparatorFixed {
                visible: OtherUtilsBackend.bestDriver != Gpu.Drivers.UNKNOWN
            }

            Loader {
                active: OtherUtilsBackend.bestDriver != Gpu.Drivers.UNKNOWN
                Layout.fillWidth: true

                sourceComponent: FC.FormTextDelegate {
                    text: {
                        switch (OtherUtilsBackend.bestDriver) {
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
                        if (OtherUtilsBackend.currentImage.name.endsWith("nvidia-open"))
                            return Gpu.Drivers.NVIDIA_OPEN;
                        else if (OtherUtilsBackend.currentImage.name.endsWith("nvidia"))
                            return Gpu.Drivers.NVIDIA;
                        else
                            return Gpu.Drivers.BASE;
                    }

                    description: {
                        if (OtherUtilsBackend.bestDriver == __current)
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
