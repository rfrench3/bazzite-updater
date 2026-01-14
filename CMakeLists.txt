# SPDX-FileCopyrightText: 2025 Robert French <frenchrobertm@outlook.com>
# SPDX-License-Identifier: BSD-3-Clause

# TODO: implement the proper/modern standard https://doc.qt.io/qt-6/qt6-port-to-qt-add-qml-module.html

cmake_minimum_required(VERSION 3.22)

project(bazzite_updater VERSION 0.2.1)


find_package(SDL3 QUIET)

if (NOT SDL3_FOUND)
    message(STATUS "SDL3 not found on system, downloading via FetchContent...")
    include(FetchContent)
    FetchContent_Declare(
        SDL3
        GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
        GIT_TAG release-3.2.28 # Latest stable release at time of adding this
    )
    FetchContent_MakeAvailable(SDL3)
else()
    message(STATUS "Found system SDL3")
endif()

include(FeatureSummary)

set(QT6_MIN_VERSION 6.7.0)
set(KF6_MIN_VERSION 6.12.0)
set(KIRIGAMI_ADDONS_MIN_VERSION 1.2.40)

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${ECM_MODULE_PATH})

include(FeatureSummary)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

include(ECMSetupVersion)
include(ECMFindQmlModule)
include(ECMQmlModule)
include(ECMAddAndroidApk)

include(KDEGitCommitHooks)
include(KDEClangFormat)

ecm_setup_version(${PROJECT_VERSION}
    VARIABLE_PREFIX BAZZITE_UPDATER
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/src/version-bazzite_updater.h"
)

set(QT_EXTRA_COMPONENTS)
#list(APPEND QT_EXTRA_COMPONENTS Widgets)

find_package(Qt6 ${QT6_MIN_VERSION} REQUIRED COMPONENTS Core Gui Qml Widgets QuickControls2 Svg ${QT_EXTRA_COMPONENTS})
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS Kirigami CoreAddons Config I18n IconThemes)

find_package(KF6KirigamiAddons ${KIRIGAMI_ADDONS_MIN_VERSION} REQUIRED)
set_package_properties(KF6KirigamiAddons PROPERTIES
    TYPE REQUIRED
    PURPOSE "Required application components and runtime dependency"
)

ecm_find_qmlmodule(org.kde.kirigamiaddons.formcard)
ecm_find_qmlmodule(org.kde.kirigamiaddons.statefulapp)


add_subdirectory(src)

string(TIMESTAMP TODAY_DATE "%Y-%m-%d")

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

