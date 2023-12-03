
set(PROJECT_NAME pyfaust)

# Detect the installed pybind11 package and import it into CMake
execute_process(
    COMMAND "${Python_EXECUTABLE}" -m pybind11 --cmakedir
    OUTPUT_STRIP_TRAILING_WHITESPACE OUTPUT_VARIABLE PB_DIR)
list(APPEND CMAKE_PREFIX_PATH "${PB_DIR}")
find_package(pybind11 CONFIG REQUIRED)


pybind11_add_module(
    ${PROJECT_NAME}
    ${RTAUDIO_SRC}
    pyfaust.cpp
)


target_include_directories(
    ${PROJECT_NAME}
    PUBLIC
    ${PROJECT_INCLUDE}

)

target_compile_definitions(
    ${PROJECT_NAME}
    PUBLIC
    __MACOSX_CORE__
)

target_link_directories(
    ${PROJECT_NAME}
    PUBLIC
    ${PROJECT_LIB}
)

target_link_libraries(
    ${PROJECT_NAME}
    PUBLIC
    ${RTAUDIO_LINK_LIBS}
    ${PROJECT_LIB}/libfaust.a
)

# file(
#     COPY ${CMAKE_SOURCE_DIR}/tests/test_pyfaust.py 
#     DESTINATION ${CMAKE_BINARY_DIR}
# )