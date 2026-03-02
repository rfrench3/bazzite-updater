# SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
# SPDX-License-Identifier: BSD-3-Clause

# Test executable for SystemUpdate class
add_executable(test_system_update
    test_system_update.cpp
    # Include the source files we're testing
    ${CMAKE_SOURCE_DIR}/src/system_update.cpp
    ${CMAKE_SOURCE_DIR}/src/system_update.h
    ${CMAKE_SOURCE_DIR}/src/utils.cpp
    ${CMAKE_SOURCE_DIR}/src/utils.h
)

target_include_directories(test_system_update PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_BINARY_DIR}/src
)

target_link_libraries(test_system_update
    PRIVATE
    Qt6::Test
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Widgets
    KF6::I18n
    KF6::CoreAddons
)

# Add test to CTest
add_test(NAME SystemUpdateTests COMMAND test_system_update)
