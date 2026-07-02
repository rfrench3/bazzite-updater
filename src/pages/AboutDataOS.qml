import org.kde.kirigamiaddons.formcard as FormCard
import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

FormCard.AboutPage {
    id: page
    title: GP.Labels.east + GP.Labels.spacer_large + i18n("About") + " " + AppConfig.configIni.osName

    // The application's own icon fully overrides normal attempts to set the icon
    function findAboutLogoItem(item) {
        if (!item) {
            return null;
        }

        if (item instanceof Kirigami.Icon) {
            return item;
        }

        if (!item.children) {
            return null;
        }

        for (let i = 0; i < item.children.length; ++i) {
            const found = findAboutLogoItem(item.children[i]);
            if (found) {
                return found;
            }
        }

        return null;
    }

    Component.onCompleted: {
        const logoItem = findAboutLogoItem(page);
        if (logoItem) {
            logoItem.source = "qrc:/osLogo";
        }
    }

    GP.PageNavigation {
        targetScrollbar: page.grabScrollbar(page)
        active: !globalDrawer.drawerOpen
    }

    function grabScrollbar(item) {
        if (item instanceof Kirigami.ScrollablePage) {
            if (item.contentItem && item.contentItem.ScrollBar && item.contentItem.ScrollBar.vertical) {
                return item.contentItem.ScrollBar.vertical;
            } else
                console.log("Parent scrollbar not found, controller scrolling will not function!");
        } else {
            if (item.parent)
                return grabScrollbar(item.parent);
            else
                console.log("Parent Kirigami.ScrollablePage not found, controller scrolling will not function!");
        }
    }

    showLibraries: false

    aboutData: AppConfig.osAboutData
}
