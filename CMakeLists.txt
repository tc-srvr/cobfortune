cmake_minimum_required(VERSION 3.10)
project(cobfortune LANGUAGES C)

# Check for the GNU COBOL compiler (cobc)
message(STATUS "Looking for GNU COBOL compiler (cobc)...")
find_program(COBCC_EXECUTABLE NAMES cobc)
if(NOT COBCC_EXECUTABLE)
    message(FATAL_ERROR "GNU COBOL compiler (cobc) not found!")
endif()

# Find libcob (the COBOL runtime library)
find_library(LIBCOB_LIBRARY NAMES cob libcob)
if(NOT LIBCOB_LIBRARY)
    message(FATAL_ERROR "libcob not found!")
endif()

# COBOL source files
set(FORTUNEC_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/FORTUNEC.COB
)

# Compile COBOL sources to .o files
set(FORTUNEC_OBJECTS "")
foreach(SRC ${FORTUNEC_SOURCES})
    get_filename_component(OBJ_NAME ${SRC} NAME_WE)
    set(OBJ_FILE ${CMAKE_CURRENT_BINARY_DIR}/${OBJ_NAME}.o)
    list(APPEND FORTUNEC_OBJECTS ${OBJ_FILE})

    add_custom_command(
        OUTPUT ${OBJ_FILE}
        COMMAND ${COBCC_EXECUTABLE} -x -c ${SRC} -std=ibm -o ${OBJ_FILE}
        DEPENDS ${SRC}
        COMMENT "Compiling COBOL source ${SRC} to ${OBJ_FILE}"
    )
endforeach()

# Create executable from object files
add_executable(FORTUNEC ${FORTUNEC_OBJECTS})

# Configure output directory and link runtime
set_target_properties(FORTUNEC PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build/bin"
    OUTPUT_NAME "FORTUNEC"
    LINKER_LANGUAGE C
)

target_link_libraries(FORTUNEC PRIVATE ${LIBCOB_LIBRARY})

# Custom target to clean up object files after successful build
add_custom_command(TARGET FORTUNEC POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E remove ${FORTUNEC_OBJECTS}
    COMMENT "Cleaning up COBOL object files"
)