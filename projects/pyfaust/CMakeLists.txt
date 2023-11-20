set(PYFAUST_LIB ${CMAKE_SOURCE_DIR}/lib)
set(PYFAUST_INCLUDE ${CMAKE_SOURCE_DIR}/include)


find_package(pybind11 REQUIRED)


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