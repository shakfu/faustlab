set(PROJECT_NAME nanofaust)

set(PROJECT_SRC ${CMAKE_CURRENT_SOURCE_DIR}/nanofaust.cpp)

# Detect the installed nanobind package and import it into CMake
execute_process(
    COMMAND "${Python_EXECUTABLE}" -m nanobind --cmake_dir
    OUTPUT_STRIP_TRAILING_WHITESPACE OUTPUT_VARIABLE NB_DIR)
list(APPEND CMAKE_PREFIX_PATH "${NB_DIR}")
find_package(nanobind CONFIG REQUIRED)

nanobind_add_module(
    ${PROJECT_NAME}
    ${RTAUDIO_SRC}
    ${PROJECT_SRC}
)

target_include_directories(
    ${PROJECT_NAME} 
    PUBLIC
    ${PROJECT_INCLUDES}
)

target_compile_definitions(
    ${PROJECT_NAME}
    PUBLIC
    ${RTAUDIO_COMPILE_DEFS}
    # ${FAUST_COMPILE_DEFS}
)

target_link_directories(
    ${PROJECT_NAME} 
    PUBLIC
    ${PROJECT_LIB_DIRS}
)

target_link_libraries(
    ${PROJECT_NAME}    
    PUBLIC
    ${RTAUDIO_LINK_LIBS}
    ${FAUST_STATICLIB}
)
