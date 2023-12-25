from setuptools import Extension, setup
from Cython.Build import cythonize

import os
os.environ['LDFLAGS'] = '-framework CoreFoundation -framework CoreAudio'


extensions = [
    Extension("cyfaust", 
        [
            "projects/cyfaust/cyfaust.pyx", 
            "include/rtaudio/RtAudio.cpp",
            # "include/rtaudio/RtAudio.h",
            "include/rtaudio/rtaudio_c.cpp",
            # "include/rtaudio/rtaudio_c.h",
        ],
        define_macros = [
            ("INTERP_DSP", 1),
            ("__MACOSX_CORE__", None)
        ],
        include_dirs = [
            "include",
        ],
        libraries = [
            "pthread",
        ],
        library_dirs = [
            'lib',
        ],
        extra_objects=[
            'lib/libfaust.a'
        ],
        extra_compile_args = ['-std=c++11'],
        extra_link_args = [
            '-mmacosx-version-min=13.6',
        ],
    ),
]


setup(
    name='cyfaust',
    ext_modules=cythonize(
        extensions,
        language_level="3str",
    ),
)
