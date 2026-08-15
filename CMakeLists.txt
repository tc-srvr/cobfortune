cmake_minimum_required(VERSION 3.10)
project(cobfortune LANGUAGES C)

# Define build directories
set(BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/build)
set(BUILD_LIB_DIR ${BUILD_DIR}/lib)

# Create the build/lib directory
file(MAKE_DIRECTORY ${BUILD_LIB_DIR})

# Check for the gnucobol compiler (cobc)
message(STATUS "Looking for GNU COBOL compiler (cobc)...")
find_program(COBCC_EXECUTABLE NAMES cobc)
if(NOT COBCC_EXECUTABLE)
    message(FATAL_ERROR "GNU COBOL compiler (cobc) not found!")
else()
    message(STATUS "Found GNU COBOL compiler: ${COBCC_EXECUTABLE}")
endif()

# Find libcob (the COBOL runtime library)
message(STATUS "Looking for COBOL runtime library (libcob)...")
find_library(LIBCOB_LIBRARY NAMES cob libcob)
if(NOT LIBCOB_LIBRARY)
    message(FATAL_ERROR "libcob not found!")
else()
    message(STATUS "Found libcob: ${LIBCOB_LIBRARY}")
endif()

# On Windows, find the actual runtime DLLs
if(WIN32)
    # Get the directory of LIBCOB_LIBRARY and search for the runtime DLL
    get_filename_component(LIBCOB_DIR ${LIBCOB_LIBRARY} DIRECTORY)
    find_file(LIBCOB_DLL NAMES "libcob-4.dll" HINTS ${LIBCOB_DIR} PATH_SUFFIXES bin)
    if(NOT LIBCOB_DLL)
        message(WARNING "Could not find libcob-4.dll, runtime dependency may be missing!")
    else()
        message(STATUS "Found libcob runtime DLL: ${LIBCOB_DLL}")
    endif()
endif()

# List your COBOL source files (adjust paths as needed)
set(COBOL_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/FORTUNEC.COB
)

# For each COBOL file, compile to an object file using a custom command
set(COBOL_OBJECTS "")
foreach(SRC ${COBOL_SOURCES})
    get_filename_component(OBJ_NAME ${SRC} NAME_WE)
    set(OBJ_FILE ${CMAKE_CURRENT_BINARY_DIR}/${OBJ_NAME}.o)
    list(APPEND COBOL_OBJECTS ${OBJ_FILE})
    add_custom_command(
        OUTPUT ${OBJ_FILE}
        COMMAND ${COBCC_EXECUTABLE} -c ${SRC} -o ${OBJ_FILE} -std=ibm
        DEPENDS ${SRC}
        COMMENT "Compiling ${SRC}"
    )
endforeach()

# Create a custom target to build all COBOL object files
add_custom_target(cobol_objects ALL DEPENDS ${COBOL_OBJECTS})

# Build the shared library from the compiled object files
add_library(TEST SHARED ${COBOL_OBJECTS})
add_dependencies(TEST cobol_objects)

# Set output directory for the shared library
set_target_properties(TEST PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${BUILD_LIB_DIR}
    RUNTIME_OUTPUT_DIRECTORY ${BUILD_LIB_DIR}  # For Windows DLLs
    OUTPUT_NAME "TEST"
    LINKER_LANGUAGE C
)

# Link against sqlite3 and libcob
target_link_libraries(TEST PRIVATE ${SQLite3_LIBRARIES} ${LIBCOB_LIBRARY})
target_include_directories(TEST PRIVATE ${SQLite3_INCLUDE_DIRS})

# Custom command to copy dependency libraries to build/lib
if(WIN32 AND LIBCOB_DLL AND SQLITE3_DLL)
    # Copy the runtime DLLs on Windows
    add_custom_command(TARGET TEST POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${LIBCOB_DLL}
            ${BUILD_LIB_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${SQLITE3_DLL}
            ${BUILD_LIB_DIR}
        COMMENT "Copying runtime DLLs to ${BUILD_LIB_DIR}"
    )
else()
    # Copy the libraries as found (for non-Windows or if DLLs not found)
    add_custom_command(TARGET TEST POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${LIBCOB_LIBRARY}
            ${BUILD_LIB_DIR}
        COMMENT "Copying dependency libraries to ${BUILD_LIB_DIR}"
    )
endif()

# Custom target to clean up object files after successful build
add_custom_command(TARGET TEST POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E remove ${COBOL_OBJECTS}
    COMMENT "Cleaning up COBOL object files"
)