import QtQuick
import QtQuick.Controls // Required for grabScrollbar to find a scrollbar
import org.kde.kirigamiaddons.formcard as FormCard
import io.github.rfrench3.controllable as GP

FormCard.AboutPage {
    id: page
    title: GP.Labels.east + GP.Labels.spacer_large + i18n("About") + " " + AppConfig.osAboutData.displayName

    GP.PageNavigation {
        targetScrollbar: page.grabScrollbar(page)
        active: !globalDrawer.drawerOpen
    }

    function grabScrollbar(item) {
        if (item.contentItem?.ScrollBar?.vertical)
            return item.contentItem.ScrollBar.vertical;

        if (item.parent)
            return grabScrollbar(item.parent);

        console.log("Parent scrollbar not found, controller scrolling will not function!");
    }

    showLibraries: false

    aboutData: AppConfig.osAboutData
}
