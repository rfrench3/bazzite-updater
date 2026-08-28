import QtQuick
import QtQuick.Controls // Required for grabScrollbar to find a scrollbar
import org.kde.kirigamiaddons.formcard as FormCard
import io.github.rfrench3.controllable as GP

FormCard.AboutPage {
    id: page
    title: GP.Labels.east + GP.Labels.spacer_large + i18nc("@title", "About Application")

    GP.PageNavigation {
        targetScrollbar: page.grabScrollbar(page)
        active: !globalDrawer.drawerOpen
    }

    function grabScrollbar(item) {
        if (item.contentItem?.ScrollBar?.vertical)
            return item.contentItem.ScrollBar.vertical;

        if (item.parent)
            return grabScrollbar(item.parent);

        console.warn("Parent scrollbar not found, controller scrolling will not function!");
    }
}
