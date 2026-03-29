# SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
# SPDX-License-Identifier: BSD-3-Clause

cmake_minimum_required(VERSION 3.22)

file(READ "version.txt" APP_VERSION)
project(bazzite_updater VERSION ${APP_VERSION})

option(TESTING_BUILD "Enable testing features like filler text in the console view." OFF)

if(TESTING_BUILD)
    add_compile_definitions(TESTING_BUILD=1)
endif()

### Install SDL3 ###

find_package(SDL3 REQUIRED)

### Set up and install Qt/KDE dependencies ###

set(QT6_MIN_VERSION 6.7.0)
set(KF6_MIN_VERSION 6.12.0)
set(KIRIGAMI_ADDONS_MIN_VERSION 1.2.40)

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${ECM_MODULE_PATH})

include(FeatureSummary)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMFindQmlModule)
include(ECMQmlModule)

find_package(Qt6 ${QT6_MIN_VERSION} REQUIRED COMPONENTS 
    Core 
    Gui 
    Qml 
    Widgets 
    QuickControls2 
    Svg
    Test
)

find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS 
    Kirigami 
    CoreAddons 
    Config 
    I18n 
    IconThemes
)

find_package(KF6KirigamiAddons ${KIRIGAMI_ADDONS_MIN_VERSION} REQUIRED)

include(KDEGitCommitHooks)
include(KDEClangFormat)

include(ECMSetupVersion)
ecm_setup_version(${PROJECT_VERSION}
    VARIABLE_PREFIX BAZZITE_UPDATER
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/src/version-bazzite_updater.h"
)

ecm_find_qmlmodule(org.kde.kirigamiaddons.formcard REQUIRED)
ecm_find_qmlmodule(org.kde.kirigamiaddons.statefulapp REQUIRED)

### Define macros for later use ###

string(TIMESTAMP TODAY_DATE "%Y-%m-%d")
string(TIMESTAMP CURRENT_YEAR "%Y")

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/LICENSES/GPL-2.0-only.txt" GPL2_ONLY_LICENSE_RAW)
string(REPLACE "\n" "\\n" GPL2_ONLY_LICENSE "${GPL2_ONLY_LICENSE_RAW}")
string(REPLACE "\"" "\\\"" GPL2_ONLY_LICENSE "${GPL2_ONLY_LICENSE}")

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/LICENSES/LicenseRef-KDE-Accepted-GPL.txt" KDE_ACCEPTED_GPL_LICENSE_RAW)
string(REPLACE "\n" "\\n" KDE_ACCEPTED_GPL_LICENSE "${KDE_ACCEPTED_GPL_LICENSE_RAW}")
string(REPLACE "\"" "\\\"" KDE_ACCEPTED_GPL_LICENSE "${KDE_ACCEPTED_GPL_LICENSE}")

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/LICENSES/GPL-3.0-only.txt" GPL3_ONLY_LICENSE_RAW)
string(REPLACE "\n" "\\n" GPL3_ONLY_LICENSE "${GPL3_ONLY_LICENSE_RAW}")
string(REPLACE "\"" "\\\"" GPL3_ONLY_LICENSE "${GPL3_ONLY_LICENSE}")

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/LICENSES/APACHELICENSE-2.0.txt" APACHE2_LICENSE_RAW)
string(REPLACE "\n" "\\n" APACHE2_LICENSE "${APACHE2_LICENSE_RAW}")
string(REPLACE "\"" "\\\"" APACHE2_LICENSE "${APACHE2_LICENSE}")


add_subdirectory(src)

# TODO: create proper tests
# enable_testing()
# add_subdirectory(tests)

### Install desktop files ###

set(METAINFO_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/io.github.rfrench3.bazzite_updater.metainfo.xml.in")
set(METAINFO_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/io.github.rfrench3.bazzite_updater.metainfo.xml")
configure_file(${METAINFO_INPUT} ${METAINFO_OUTPUT} @ONLY)

set(DESKTOP_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/io.github.rfrench3.bazzite_updater.desktop.in")
set(DESKTOP_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/io.github.rfrench3.bazzite_updater.desktop")
configure_file(${DESKTOP_INPUT} ${DESKTOP_OUTPUT} @ONLY)

install(FILES ${DESKTOP_OUTPUT} DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES io.github.rfrench3.bazzite_updater.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/apps/)
install(FILES ${METAINFO_OUTPUT} DESTINATION ${KDE_INSTALL_METAINFODIR})
ki18n_install(po)

feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)

file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES src/*.cpp src/*.h)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})
kde_configure_git_pre_commit_hook(CHECKS CLANG_FORMAT)

