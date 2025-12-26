# SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
# SPDX-License-Identifier: BSD-2-Clause

qt_add_library(bazzite_updater_settings STATIC)
ecm_add_qml_module(bazzite_updater_settings
    GENERATE_PLUGIN_SOURCE
    URI org.kde.bazzite_updater.settings
    QML_FILES
        Bazzite_UpdaterConfigurationView.qml
        GeneralPage.qml
)
