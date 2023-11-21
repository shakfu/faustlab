set(PYFAUST_LIB ${CMAKE_SOURCE_DIR}/lib)
set(PYFAUST_INCLUDE ${CMAKE_SOURCE_DIR}/include)

# Detect the installed pybind11 package and import it into CMake
execute_process(
    COMMAND "${Python_EXECUTABLE}" -m pybind11 --cmakedir
    OUTPUT_STRIP_TRAILING_WHITESPACE OUTPUT_VARIABLE PB_DIR)
list(APPEND CMAKE_PREFIX_PATH "${PB_DIR}")
find_package(pybind11 CONFIG REQUIRED)

# find_package(pybind11 REQUIRED)


pybind11_add_module(pyfaust pyfaust.cpp)


target_include_directories(pyfaust
    PUBLIC
    ${PYFAUST_INCLUDE}
)

target_link_directories(pyfaust
    PUBLIC
    ${PYFAUST_LIB}
)

target_link_libraries(pyfaust
    PUBLIC
    ${PYFAUST_LIB}/libfaust.a
)