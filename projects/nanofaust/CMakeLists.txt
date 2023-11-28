set(PROJECT_NAME nanofaust)

# Detect the installed nanobind package and import it into CMake
execute_process(
    COMMAND "${Python_EXECUTABLE}" -m nanobind --cmake_dir
    OUTPUT_STRIP_TRAILING_WHITESPACE OUTPUT_VARIABLE NB_DIR)
list(APPEND CMAKE_PREFIX_PATH "${NB_DIR}")
find_package(nanobind CONFIG REQUIRED)


set(PROJECT_LIB ${CMAKE_SOURCE_DIR}/lib)
set(PROJECT_INCLUDE ${CMAKE_SOURCE_DIR}/include)
set(RTAUDIO_SRC
    ${PROJECT_INCLUDE}/rtaudio/RtAudio.cpp
    ${PROJECT_INCLUDE}/rtaudio/RtAudio.h
)


find_package(pybind11 REQUIRED)


nanobind_add_module(
    ${PROJECT_NAME}
    ${RTAUDIO_SRC}
    nanofaust.cpp
)


target_include_directories(
    ${PROJECT_NAME} 
    PUBLIC
    ${PROJECT_INCLUDE}
)

target_link_directories(
    ${PROJECT_NAME} 
    PUBLIC
    ${PROJECT_LIB}
)

target_link_libraries(
    ${PROJECT_NAME}    
    PUBLIC
    ${PROJECT_LIB}/libfaust.a
)