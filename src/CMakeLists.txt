# SPDX-License-Identifier: BSD-2-Clause
# SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>

add_subdirectory(settings)

qt_add_library(bazzite_updater_static STATIC)
ecm_add_qml_module(bazzite_updater_static
    URI org.kde.bazzite_updater
    GENERATE_PLUGIN_SOURCE
    QML_FILES
        qml/Main.qml
        qml/SystemUpdate.qml
        qml/RebaseHelper.qml
    DEPENDENCIES
        org.kde.kirigamiaddons.formcard
        org.kde.kirigamiaddons.statefulapp
        org.kde.kirigami
        org.kde.bazzite_updater.settings
)

target_sources(bazzite_updater_static PRIVATE
    bazzite_updaterapplication.cpp
    bazzite_updaterapplication.h
)

target_link_libraries(bazzite_updater_static PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Svg
    KF6::I18n
    KF6::I18nQml
    KF6::IconThemes
    KF6::CoreAddons
    KF6::ConfigCore
    KF6::ConfigGui
    KirigamiAddonsStatefulApp
)
target_include_directories(bazzite_updater_static PUBLIC ${CMAKE_BINARY_DIR})

target_link_libraries(bazzite_updater_static PUBLIC Qt::Widgets)

kconfig_add_kcfg_files(bazzite_updater_static GENERATE_MOC bazzite_updaterconfig.kcfgc)

add_executable(bazzite_updater
    main.cpp
    utils.h
    utils.cpp
    resources.qrc
)

target_link_libraries(bazzite_updater PUBLIC
    bazzite_updater_static
    bazzite_updater_staticplugin
    bazzite_updater_settings
    bazzite_updater_settingsplugin
)
install(TARGETS bazzite_updater ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
ecm_add_android_apk(bazzite_updater ANDROID_DIR ${CMAKE_SOURCE_DIR}/android)
