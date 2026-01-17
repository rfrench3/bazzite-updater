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
    system_update.cpp
    system_update.h
    resources.qrc
    controllers.cpp
    controllers.h
    rebase_helper.h
    rebase_helper.cpp
)

set(ABOUTAPP_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/resources/qml/AboutDataApp.qml")
set(ABOUTAPP_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/resources/qml/AboutDataApp.qml")
configure_file(${ABOUTAPP_INPUT} ${ABOUTAPP_OUTPUT} @ONLY)

set(ABOUTBAZZITE_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/resources/qml/AboutDataBazzite.qml")
set(ABOUTBAZZITE_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/resources/qml/AboutDataBazzite.qml")
configure_file(${ABOUTBAZZITE_INPUT} ${ABOUTBAZZITE_OUTPUT} @ONLY)

ecm_target_qml_sources(bazzite_updater
    SOURCES
    resources/qml/Main.qml
    resources/qml/SystemUpdate.qml
    resources/qml/RebaseHelper.qml
    ${ABOUTBAZZITE_OUTPUT}
    ${ABOUTAPP_OUTPUT}
    resources/qml/components/GamepadPageNavigation.qml
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
    SDL3::SDL3
)

install(TARGETS bazzite_updater ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
