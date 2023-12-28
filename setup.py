import os
import platform
from setuptools import Extension, setup, find_packages
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
    Extension("cyfaust.interp", 
        [
            "projects/cyfaust/interp.pyx", 
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
    Extension("cyfaust.common", 
        [
            "projects/cyfaust/common.pyx", 
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
    Extension("cyfaust.signal", 
        [
            "projects/cyfaust/signal.pyx", 
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
    Extension("cyfaust.box", 
        [
            "projects/cyfaust/box.pyx", 
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
    version='0.0.1',
    ext_modules=cythonize(
        extensions,
        language_level="3str",
    ),
    package_dir = {"cyfaust": "projects/cyfaust"},
    packages=['cyfaust']
)
