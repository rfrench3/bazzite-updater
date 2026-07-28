import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater

FC.FormCard {
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
