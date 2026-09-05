# UpdateTranslations.cmake
set(POT_FILE "${SOURCE_DIR}/po/${PROJECT_NAME}.pot")
message(STATUS "Extracting messages for ${PROJECT_NAME}...")

file(GLOB_RECURSE SOURCE_FILES
    "${SOURCE_DIR}/src/*.cpp"
    "${SOURCE_DIR}/src/*.h"
    "${SOURCE_DIR}/src/*.qml"
)

# Create a temporary file for xgettext
set(FILES_LIST "${SOURCE_DIR}/po/source_files.txt")
file(WRITE "${FILES_LIST}" "")
foreach(F IN LISTS SOURCE_FILES)
  file(RELATIVE_PATH REL_F "${SOURCE_DIR}" "${F}")
  file(APPEND "${FILES_LIST}" "${REL_F}\n")
endforeach()

execute_process(
    COMMAND xgettext --from-code=UTF-8 -C -kde
        --files-from=${FILES_LIST}
        -ci18n -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3
        -ktr2i18n:1 -kI18N_NOOP:1 -kI18N_NOOP2:1c,2
        -kaliasLocale -kki18n:1 -kki18nc:1c,2 -kki18np:1,2 -kki18ncp:1c,2,3
        -o ${POT_FILE}
    WORKING_DIRECTORY ${SOURCE_DIR}
    RESULT_VARIABLE XGETTEXT_RES
)

file(REMOVE "${FILES_LIST}")
message(STATUS "Template generated at ${POT_FILE}")

# Update existing .po files
file(GLOB PO_FILES "${SOURCE_DIR}/po/*/${PROJECT_NAME}.po")
foreach(PO_FILE IN LISTS PO_FILES)
  message(STATUS "Updating ${PO_FILE}...")
  execute_process(
        COMMAND msgmerge -U "${PO_FILE}" "${POT_FILE}"
        WORKING_DIRECTORY ${SOURCE_DIR}
    )
endforeach()
message(STATUS "All translations updated!")
