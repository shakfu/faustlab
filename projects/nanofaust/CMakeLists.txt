set(PROJECT_NAME nanofaust)

# Detect the installed nanobind package and import it into CMake
execute_process(
    COMMAND "${Python_EXECUTABLE}" -m nanobind --cmake_dir
    OUTPUT_STRIP_TRAILING_WHITESPACE OUTPUT_VARIABLE NB_DIR)
list(APPEND CMAKE_PREFIX_PATH "${NB_DIR}")
find_package(nanobind CONFIG REQUIRED)


set(NANOFAUST_LIB ${CMAKE_SOURCE_DIR}/lib)
set(NANOFAUST_INCLUDE ${CMAKE_SOURCE_DIR}/include)


find_package(pybind11 REQUIRED)


nanobind_add_module(
    ${PROJECT_NAME} 
    nanofaust.cpp
)


target_include_directories(
    ${PROJECT_NAME} 
    PUBLIC
    ${NANOFAUST_INCLUDE}
)

target_link_directories(
    ${PROJECT_NAME} 
    PUBLIC
    ${NANOFAUST_LIB}
)

target_link_libraries(
    ${PROJECT_NAME}    
    PUBLIC
    ${NANOFAUST_LIB}/libfaust.a
)