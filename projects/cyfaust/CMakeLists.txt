set(PROJECT_NAME cyfaust)

set(CYFAUST_LIB ${CMAKE_SOURCE_DIR}/lib)
set(CYFAUST_INCLUDE ${CMAKE_SOURCE_DIR}/include)
set(CYFAUST_SRC ${CMAKE_CURRENT_SOURCE_DIR}/cyfaust.cpp)


add_library( 
    ${PROJECT_NAME} 
    MODULE
    ${RTAUDIO_SRC}
    ${CYFAUST_SRC}
)

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/cyfaust.cpp
    COMMAND cythonize -3 cyfaust.pyx
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    DEPENDS cyfaust.pyx
    COMMENT "Generating cyfaust.cpp"
)

add_custom_target(
    cyfaust_cpp
    DEPENDS cyfaust.pyx
)

add_dependencies(
    ${PROJECT_NAME}
    cyfaust_cpp
)

string(TOLOWER ${CMAKE_SYSTEM_NAME} platform)
set_target_properties(
    ${PROJECT_NAME}
    PROPERTIES
    PREFIX ""
    LIBRARY_OUTPUT_NAME "${PROJECT_NAME}.cpython-${Python_VERSION_MAJOR}${Python_VERSION_MINOR}-${platform}"
)
    
target_include_directories(
    ${PROJECT_NAME}
    PUBLIC
    ${Python_INCLUDE_DIRS}
    ${PROJECT_INCLUDE}
    ${CYFAUST_INCLUDE}
)

target_compile_definitions(
    ${PROJECT_NAME}
    PUBLIC
    -DNDEBUG
    -DINTERP_DSP=1
)

target_compile_options(
    ${PROJECT_NAME}
    PUBLIC
    -std=c++11 
    $<$<PLATFORM_ID:Darwin>:-Wno-unused-result>
    $<$<PLATFORM_ID:Darwin>:-Wsign-compare>
    $<$<PLATFORM_ID:Darwin>:-Wunreachable-code>
    $<$<PLATFORM_ID:Darwin>:-fno-common>
    $<$<PLATFORM_ID:Darwin>:-Wall>  
    $<$<PLATFORM_ID:Darwin>:-g>
    $<$<PLATFORM_ID:Darwin>:-fwrapv>
    $<$<PLATFORM_ID:Darwin>:-O3>
    $<$<PLATFORM_ID:Windows>:/O2>
    $<$<PLATFORM_ID:Windows>:/MD> # api module works with this
)

target_link_options(
    ${PROJECT_NAME}
    PUBLIC
    $<$<PLATFORM_ID:Darwin>:-dynamic>
)

target_link_directories(
    ${PROJECT_NAME} 
    PUBLIC
    ${Python_LIBRARY_DIRS}
    ${CYFAUST_LIB}
)

target_link_libraries(
    ${PROJECT_NAME} 
    PUBLIC
    ${Python_LIBRARIES}
    "$<$<PLATFORM_ID:Darwin>:-ldl>"
    ${RTAUDIO_LINK_LIBS}
    ${CYFAUST_LIB}/libfaust.a
)

# file(
#     COPY ${CMAKE_SOURCE_DIR}/tests/test_cyfaust.py 
#     DESTINATION ${CMAKE_BINARY_DIR}
# )


