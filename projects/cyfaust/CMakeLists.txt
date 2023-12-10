include(${CMAKE_CURRENT_SOURCE_DIR}/scripts/add_cyfaust_module.cmake)


add_cyfaust_module(
    NAME cyfaust
    SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/cyfaust.cpp
)

