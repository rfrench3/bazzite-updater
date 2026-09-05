# SPDX-License-Identifier: BSD-2-Clause
# SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>

add_executable(bazzite-updater)

ecm_add_qml_module(bazzite-updater
    URI
    io.github.rfrench3.bazzite_updater
)

set(PG_DIR "${CMAKE_CURRENT_SOURCE_DIR}/pages")
set(COMP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/components")

target_sources(bazzite-updater
    PRIVATE
    main.cpp
    utils.h
    utils.cpp
    resources.qrc
    ${PG_DIR}/system_update/system_update.cpp
    ${PG_DIR}/system_update/system_update.h
    ${PG_DIR}/other_utils/other_utils.h
    ${PG_DIR}/other_utils/other_utils.cpp
    ${COMP_DIR}/console/console.h
    ${COMP_DIR}/console/console.cpp
    ${COMP_DIR}/kConfig/k_config.h
    ${COMP_DIR}/kConfig/k_config.cpp
    ${COMP_DIR}/kConfig/user_settings.h
    ${COMP_DIR}/kConfig/user_settings.cpp
)

target_include_directories(bazzite-updater
    PRIVATE
    ${PG_DIR}/system_update
    ${PG_DIR}/other_utils
    ${COMP_DIR}/console
    ${COMP_DIR}/kConfig
)

ecm_target_qml_sources(bazzite-updater
    SOURCES
    ${PG_DIR}/Main.qml
    ${PG_DIR}/system_update/SystemUpdate.qml
    ${PG_DIR}/other_utils/OtherUtils.qml
    ${PG_DIR}/rss_feed/RssPage.qml
    ${PG_DIR}/rss_feed/FCRssDelegate.qml
    ${PG_DIR}/rss_feed/RssModel.qml
    ${PG_DIR}/AboutDataApp.qml
    ${PG_DIR}/AboutDataOS.qml
    ${PG_DIR}/settings/Settings.qml
    ${PG_DIR}/rebase_page/RebasePage.qml
    ${COMP_DIR}/AppDialog.qml
    ${COMP_DIR}/AppPage.qml
    ${COMP_DIR}/AsyncLoader.qml
    ${COMP_DIR}/PageContentLayout.qml
    ${COMP_DIR}/console/ConsoleView.qml
    ${COMP_DIR}/console/ConsoleDrawer.qml
    ${COMP_DIR}/customFormcards/FormCardCollapsible.qml
    ${COMP_DIR}/customFormcards/FCOsRelease.qml
    ${COMP_DIR}/customFormcards/FCSystemInfo.qml
    ${COMP_DIR}/customFormcards/FCSystemImage.qml
    ${COMP_DIR}/customFormcards/FormDelegateSeparatorFixed.qml
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
    Qt6::DBus
    KF6::I18n
    KF6::I18nQml
    KF6::IconThemes
    KF6::CoreAddons
    KF6::ConfigCore
    KF6::ConfigGui
    KF6::ColorScheme
    KirigamiApp
    KirigamiAddonsStatefulApp
)

add_subdirectory(components)

install(TARGETS bazzite-updater ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
