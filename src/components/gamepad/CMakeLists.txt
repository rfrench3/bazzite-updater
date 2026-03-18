# SPDX-License-Identifier: BSD-2-Clause
# SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>

add_library(gamepad-support)

ecm_add_qml_module(gamepad-support
    URI "app.Gamepad" # in the QML: import (the URI)
    GENERATE_PLUGIN_SOURCE
)

target_sources(gamepad-support
    PRIVATE
    controllers.cpp
    controllers.h
)

ecm_target_qml_sources(gamepad-support
    SOURCES
    GamepadPageNavigation.qml
)

target_link_libraries(gamepad-support
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
    SDL3::SDL3
)

ecm_finalize_qml_module(gamepad-support)

install(TARGETS gamepad-support ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
