import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

FC.FormCardPage {
    id: root
    function grabScrollbar(item: Item): ScrollBar {
        if (item.contentItem?.ScrollBar?.vertical)
            return item.contentItem.ScrollBar.vertical;

        if (item.parent)
            return grabScrollbar(item.parent);

        console.warn("Parent scrollbar not found, controller scrolling will not function!");
    }
    readonly property ScrollBar scrollBar: grabScrollbar(root)

    property Item drawer: null
    property Item actionToggleDrawer: null

    // Allow additional actions to be implemented when necessary
    function moreHandleInput(buttonId: int, button_down: bool): void {
    }

    function handleInput(buttonId: int, button_down: bool): void {
        if (button_down) {
            if (root.drawer?.drawerOpen) {
                root.drawer.handleInput(buttonId, button_down);
                return;
            }

            if (root.actionToggleDrawer?.trigger && buttonId == 3) {
                root.actionToggleDrawer.trigger();
                // Closes up to 5 passive notifications
                for (let i = 0; i < 5; ++i) {
                    hidePassiveNotification();
                }
            }
        }
        moreHandleInput(buttonId, button_down);
    }
}
