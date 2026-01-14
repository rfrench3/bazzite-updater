import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.about 1.0
// import app.Gamepad 1.0

FormCard.AboutPage {
    title: i18nc("@action:button", "About Bazzite")
    // title: Gamepad.labels.b + Gamepad.labels.space_large + i18nc("@action:button", "About Application")

    // GamepadPageNavigation {
    //     targetWindow: parent.Window.window
    // }
    
    aboutData: {
        "displayName" : "Addons Example",
        "productName" : "product",
        "componentName" : "addonsexample",
        "shortDescription" : "This program shows how to use AboutKDE and AboutPage",
        "homepage" : "https://kde.org",
        "bugAddress" : "",
        "version" : "1.0",
        "otherText" : "Optional text shown in the About",
        "authors" : [
            {
                "name" : "John Bazzite",
                "task" : "Maintainer",
                "emailAddress" : "",
                "webAddress" : "",
                "ocsUsername" : ""
            }
        ],
        "credits" : [],
        "translators" : [],
        "licenses" : [
            {
                "name" : "GPL v3",
                "text" : "Long license text goes here",
                "spdx" : "GPL-3.0"
            }
        ],
        "copyrightStatement" : "© 2023",
        "desktopFileName" : ""
    }

}
