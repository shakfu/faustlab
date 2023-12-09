find_package(Python 3.8 COMPONENTS Interpreter Development Development.Module REQUIRED)

if(DEBUG)
message(STATUS "Python_FOUND: ${Python_FOUND}")
message(STATUS "Python_Development_FOUND: ${Python_Development_FOUND}")
message(STATUS "Python_Development.Embed_FOUND: ${Python_Development.Embed_FOUND}")
message(STATUS "Python_Development.SABIModule_FOUND: ${Python_Development.SABIModule_FOUND}")
message(STATUS "Python_Interpreter_FOUND: ${Python_Interpreter_FOUND}")
message(STATUS "Python_INTERPRETER_ID: ${Python_INTERPRETER_ID}")
message(STATUS "Python_EXECUTABLE: ${Python_EXECUTABLE}")
message(STATUS "Python_INCLUDE_DIRS: ${Python_INCLUDE_DIRS}")
message(STATUS "Python_LIBRARIES: ${Python_LIBRARIES}")
message(STATUS "Python_LIBRARY_DIRS: ${Python_LIBRARY_DIRS}")
message(STATUS "Python_LINK_OPTIONS: ${Python_LINK_OPTIONS}")
message(STATUS "Python_NumPy_FOUND: ${Python_NumPy_FOUND}")
message(STATUS "Python_NumPy_INCLUDE_DIRS: ${Python_NumPy_INCLUDE_DIRS}")
message(STATUS "Python_NumPy_VERSION: ${Python_NumPy_VERSION}")
message(STATUS "Python_RUNTIME_LIBRARY_DIRS: ${Python_RUNTIME_LIBRARY_DIRS}")
message(STATUS "Python_RUNTIME_SABI_LIBRARY_DIRS: ${Python_RUNTIME_SABI_LIBRARY_DIRS}")
message(STATUS "Python_SABI_LIBRARIES: ${Python_SABI_LIBRARIES}")
message(STATUS "Python_SABI_LIBRARY_DIRS: ${Python_SABI_LIBRARY_DIRS}")
message(STATUS "Python_SITEARCH: ${Python_SITEARCH}")
message(STATUS "Python_SITELIB: ${Python_SITELIB}")
message(STATUS "Python_SOABI: ${Python_SOABI}")
message(STATUS "Python_SOSABI: ${Python_SOSABI}")
message(STATUS "Python_STDARCH: ${Python_STDARCH}")
message(STATUS "Python_STDLIB: ${Python_STDLIB}")
message(STATUS "Python_VERSION: ${Python_VERSION}")
message(STATUS "Python_VERSION_MAJOR: ${Python_VERSION_MAJOR}")
message(STATUS "Python_VERSION_MINOR: ${Python_VERSION_MINOR}")
message(STATUS "Python_VERSION_PATCH: ${Python_VERSION_PATCH}")
endif()

# common variables

set(PROJECT_LIB_DIRS ${CMAKE_SOURCE_DIR}/lib)
set(PROJECT_INCLUDES ${CMAKE_SOURCE_DIR}/include)

set(FAUST_STATICLIB 
	${PROJECT_LIB_DIRS}/libfaust${CMAKE_STATIC_LIBRARY_SUFFIX})

set(FAUST_COMPILE_DEFS
	-DINTERP_DSP=1
)

set(RTAUDIO_SRC
    ${PROJECT_INCLUDES}/rtaudio/RtAudio.cpp
    ${PROJECT_INCLUDES}/rtaudio/RtAudio.h
)
set(RTAUDIO_LINK_LIBS
	"$<$<PLATFORM_ID:Darwin>:-lpthread>"
	"$<$<PLATFORM_ID:Darwin>:-framework CoreFoundation>"
	"$<$<PLATFORM_ID:Darwin>:-framework CoreAudio>"
)
set(RTAUDIO_COMPILE_DEFS
	$<$<PLATFORM_ID:Darwin>:__MACOSX_CORE__>
)


if(Python_FOUND)
	add_subdirectory(cfaust)
	add_subdirectory(cyfaust)
	add_subdirectory(nanofaust)
	add_subdirectory(pyfaust)
endif()
