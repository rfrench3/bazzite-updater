import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.about 1.0
// import app.Gamepad 1.0
import app.RebaseHelper 1.0

// TODO: Fix controller support, especially when the license is openend

FormCard.AboutPage {
    title: i18nc("@action:button", "About Bazzite")
    // title: Gamepad.labels.b + Gamepad.labels.space_large + i18nc("@action:button", "About Application")

    // GamepadPageNavigation {
    //     targetWindow: parent.Window.window
    // }

    aboutData: {
        "displayName" : "Bazzite",
        "productName" : "bazzite",
        "componentName" : "addonsexample",
        "shortDescription" : i18n("The operating system for the next generation of gamers"),
        "homepage" : "https://bazzite.gg/",
        "bugAddress" : "",
        "version" : RebaseHelper.currentImage.version,
        "otherText" : i18n("Bazzite makes gaming and everyday use smoother and simpler across desktop PCs, handhelds, tablets, and home theater PCs."),
        "authors" : [
            { // TODO: Make this an actual credits section
                "name" : "John Bazzite",
                "task" : "Developer",
                "emailAddress" : "",
                "webAddress" : "",
                "ocsUsername" : ""
            }
        ],
        "credits" : [],
        "translators" : [],
        "licenses" : [
            {
                "name" : "Apache License Version 2.0",
                "text" : "@APACHE2_LICENSE@",
                "spdx" : "Apache-2.0"
            }
        ],
        "copyrightStatement" : "© 2023-@CURRENT_YEAR@",
    }
}
