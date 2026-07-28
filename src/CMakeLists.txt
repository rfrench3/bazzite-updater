# SPDX-License-Identifier: BSD-2-Clause
# SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>

add_executable(bazzite-updater)

ecm_add_qml_module(bazzite-updater
    URI
    io.github.rfrench3.bazzite_updater
)

target_sources(bazzite-updater
    PRIVATE
    main.cpp
    utils.h
    utils.cpp
    resources.qrc
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/system_update/system_update.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/system_update/system_update.h
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/rebase_helper/rebase_helper.h
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/rebase_helper/rebase_helper.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/components/console/console.h
    ${CMAKE_CURRENT_SOURCE_DIR}/components/console/console.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/components/kConfig/k_config.h
    ${CMAKE_CURRENT_SOURCE_DIR}/components/kConfig/k_config.cpp
)

target_include_directories(bazzite-updater
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/system_update
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/rebase_helper
    ${CMAKE_CURRENT_SOURCE_DIR}/components/console
    ${CMAKE_CURRENT_SOURCE_DIR}/components/kConfig
)

# adds the licenses into the About files without making a huge mess in the source code
set(ABOUTAPP_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/pages/AboutDataApp.qml")
set(ABOUTAPP_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/pages/AboutDataApp.qml")
configure_file(${ABOUTAPP_INPUT} ${ABOUTAPP_OUTPUT} @ONLY)

ecm_target_qml_sources(bazzite-updater
    SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/Main.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/system_update/SystemUpdate.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/rebase_helper/RebaseHelper.qml
    # ${CMAKE_CURRENT_SOURCE_DIR}/pages/rebase_helper/RebasePart.qml # remove until implemented
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/rss_feed/RssPage.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/rss_feed/FCRssDelegate.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/AboutDataOS.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/components/console/ConsoleView.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/components/console/ConsoleDrawer.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/components/AppDialog.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/components/ScrollingPage.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/components/FCSystemInfo.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/components/kConfig/FCOsRelease.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/components/FormDelegateSeparatorFixed.qml
    ${ABOUTAPP_OUTPUT}
)

target_link_libraries(bazzite-updater
    PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Widgets
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
    # qt6-controllable
)

add_subdirectory(components)

install(TARGETS bazzite-updater ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
