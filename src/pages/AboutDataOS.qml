import org.kde.kirigamiaddons.formcard as FormCard
import QtQuick
import QtQuick.Controls // Required so grabScrollbar knows what a scrollbar is
import org.kde.kirigami as Kirigami

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

FormCard.AboutPage {
    id: page
    title: GP.Labels.east + GP.Labels.spacer_large + i18n("About") + " " + AppConfig.configIni.osName

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
