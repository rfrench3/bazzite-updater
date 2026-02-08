import org.kde.kirigamiaddons.formcard as FormCard
import app.Gamepad 1.0
import app.RebaseHelper 1.0
import QtQuick

// TODO: improve scrolling support (currently, it only scrolls when an off-screen item is focused)

/* TODO: replace this AboutPage with a custom reimplementation to solve the following issues:
    - remove the app-specific information sections (flatpak packaging, qt runtime versions, etc)
    - use the correct icon in a way that is stable
    - make the license popup more intuitively escapable
    - use the proper Bazzite logo on the About Bazzite page
*/ 
FormCard.AboutPage {
    id: page
    title: Gamepad.labels.b + Gamepad.labels.space_large + i18nc("@title", "About Bazzite")

    GamepadPageNavigation {
        targetWindow: page.Window.window
    } // TODO: make it easy to escape the License popup

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
            {
                "name" : "Kyle Gospodnetich",
                "task" : "Maintainer",
                "emailAddress" : "",
                "webAddress" : "https://kylegospodneti.ch/"
            },
            {
                "name": "EyeCantCU",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/EyeCantCU"
            },
            {
                "name": "HikariKnight",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/HikariKnight"
            },
            {
                "name": "aarron-lee",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/aarron-lee"
            },
            {
                "name": "castrojo",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/castrojo"
            },
            {
                "name": "bsherman",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/bsherman"
            },
            {
                "name": "noelmiller",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/noelmiller"
            },
            {
                "name": "nicknamenamenick",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/nicknamenamenick"
            },
            {
                "name": "Zeglius",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/Zeglius"
            },
            {
                "name": "BoukeHaarsma23",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/BoukeHaarsma23"
            },
            {
                "name": "matte-schwartz",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/matte-schwartz"
            },
            {
                "name": "gerblesh",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/gerblesh"
            },
            {
                "name": "abanna",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/abanna"
            },
            {
                "name": "ameliasvg",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/ameliasvg"
            },
            {
                "name": "SuperRiderTH",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/SuperRiderTH"
            },
            {
                "name": "CharlieBros",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/CharlieBros"
            },
            {
                "name": "xXJSONDeruloXx",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/xXJSONDeruloXx"
            },
            {
                "name": "m2Giles",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/m2Giles"
            },
            {
                "name": "fiftydinar",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/fiftydinar"
            },
            {
                "name": "EPOCHvoyager",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/EPOCHvoyager"
            },
            {
                "name": "RodoMa92",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/RodoMa92"
            },
            {
                "name": "renner0e",
                "task": "Maintainer",
                "emailAddress" : "",
                "webAddress": "https://github.com/renner0e"
            },
            {
                "name" : i18nc("context: many more people have contributed to bazzite", "And many more!"),
                "task" : "Maintainer",
                "emailAddress" : "",
                "webAddress" : "https://github.com/ublue-os/bazzite/graphs/contributors"
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
        "copyrightStatement" : "© 2023-@CURRENT_YEAR@"
    }

    donateUrl: "https://bazzite.gg/#sponsor"
    getInvolvedUrl: "https://bazzite.gg/#contribute"
}
