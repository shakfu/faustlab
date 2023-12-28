import os
import platform
from setuptools import Extension, setup
from Cython.Build import cythonize

WITH_DYLIB = os.getenv("WITH_DYLIB", False)

INCLUDE_DIRS = []
LIBRARY_DIRS = []
EXTRA_OBJECTS = []
EXTRA_LINK_ARGS = ['-mmacosx-version-min=13.6']
LIBRARIES = ["pthread"]

if WITH_DYLIB:
    LIBRARIES.append('faust.2')
else:
    EXTRA_OBJECTS.append('lib/libfaust.a')

CWD = os.getcwd()
LIB = os.path.join(CWD, 'lib')
LIBRARY_DIRS.append(LIB)
INCLUDE_DIRS.append(os.path.join(CWD, 'include'))

# add local rpath
if platform.system() == 'Darwin':
    EXTRA_LINK_ARGS.append('-Wl,-rpath,'+LIB)

os.environ['LDFLAGS'] = '-framework CoreFoundation -framework CoreAudio'


extensions = [
    Extension("cyfaust", 
        [
            "projects/cyfaust/cyfaust.pyx", 
            "include/rtaudio/RtAudio.cpp",
            "include/rtaudio/rtaudio_c.cpp",
        ],
        define_macros = [
            ("INTERP_DSP", 1),
            ("__MACOSX_CORE__", None)
        ],
        include_dirs = INCLUDE_DIRS,
        libraries = LIBRARIES,
        library_dirs = LIBRARY_DIRS,
        extra_objects = EXTRA_OBJECTS,
        extra_compile_args = ['-std=c++11'],
        extra_link_args = EXTRA_LINK_ARGS,
    ),
    Extension("cyfaust_common", 
        [
            "projects/cyfaust/cyfaust_common.pyx", 
        ],
        define_macros = [
        ],
        include_dirs = INCLUDE_DIRS,
        libraries = LIBRARIES,
        library_dirs = LIBRARY_DIRS,
        extra_objects = EXTRA_OBJECTS,
        extra_compile_args = ['-std=c++11'],
        extra_link_args = EXTRA_LINK_ARGS,
    ),
    Extension("cyfaust_signal", 
        [
            "projects/cyfaust/cyfaust_signal.pyx", 
        ],
        define_macros = [
        ],
        include_dirs = INCLUDE_DIRS,
        libraries = LIBRARIES,
        library_dirs = LIBRARY_DIRS,
        extra_objects = EXTRA_OBJECTS,
        extra_compile_args = ['-std=c++11'],
        extra_link_args = EXTRA_LINK_ARGS,
    ),
    Extension("cyfaust_box", 
        [
            "projects/cyfaust/cyfaust_box.pyx", 
        ],
        define_macros = [
        ],
        include_dirs = INCLUDE_DIRS,
        libraries = LIBRARIES,
        library_dirs = LIBRARY_DIRS,
        extra_objects = EXTRA_OBJECTS,
        extra_compile_args = ['-std=c++11'],
        extra_link_args = EXTRA_LINK_ARGS,
    ),
]

setup(
    name='cyfaust',
    ext_modules=cythonize(
        extensions,
        language_level="3str",
    ),
)
