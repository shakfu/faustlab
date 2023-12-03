set(PROJECT_NAME cfaust)

set(CFAUST_LIB ${CMAKE_SOURCE_DIR}/lib)
set(CFAUST_INCLUDE ${CMAKE_SOURCE_DIR}/include)

set(PROJECT_SRC
    ${CMAKE_CURRENT_SOURCE_DIR}/cfaust.cpp
)

add_library( 
    ${PROJECT_NAME} 
    MODULE
    ${PROJECT_SRC}
)

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/cfaust.cpp
    COMMAND cythonize -3 cfaust.pyx
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    DEPENDS cfaust.pyx
    COMMENT "Generating cfaust.cpp"
)

add_custom_target(
    cfaust_c
    DEPENDS cfaust.pyx
)

add_dependencies(
    ${PROJECT_NAME} 
    cfaust_c
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
    ${CFAUST_INCLUDE}
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
    ${CFAUST_LIB}
)

target_link_libraries(
    ${PROJECT_NAME} 
    PUBLIC
    ${Python_LIBRARIES}
    "$<$<PLATFORM_ID:Darwin>:-ldl>"
    ${CFAUST_LIB}/libfaust.a
)


