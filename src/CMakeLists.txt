# SPDX-License-Identifier: BSD-2-Clause
# SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>

add_executable(bazzite_updater)

ecm_add_qml_module(bazzite_updater
    URI
    io.github.rfrench3.bazzite_updater
)

target_sources(bazzite_updater
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
)

target_include_directories(bazzite_updater
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/system_update
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/rebase_helper
    ${CMAKE_CURRENT_SOURCE_DIR}/components/console
)

set(ABOUTAPP_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/pages/AboutDataApp.qml")
set(ABOUTAPP_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/pages/AboutDataApp.qml")
configure_file(${ABOUTAPP_INPUT} ${ABOUTAPP_OUTPUT} @ONLY)

set(ABOUTBAZZITE_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/pages/AboutDataBazzite.qml")
set(ABOUTBAZZITE_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/pages/AboutDataBazzite.qml")
configure_file(${ABOUTBAZZITE_INPUT} ${ABOUTBAZZITE_OUTPUT} @ONLY)

ecm_target_qml_sources(bazzite_updater
    SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/Main.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/system_update/SystemUpdate.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/rebase_helper/RebaseHelper.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/pages/rebase_helper/RebasePart.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/components/console/ConsoleView.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/components/console/ConsoleDrawer.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/components/AppDialog.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/components/ScrollingPage.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/components/FCSystemInfo.qml
    ${ABOUTBAZZITE_OUTPUT}
    ${ABOUTAPP_OUTPUT}
)

target_link_libraries(bazzite_updater
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

install(TARGETS bazzite_updater ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
