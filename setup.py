from setuptools import Extension, setup
from Cython.Build import cythonize

extensions = [
    Extension("cyfaust", ["projects/cyfaust/cyfaust.pyx"],
        define_macros = [
            ("INTERP_DSP", 1),
        ],
        include_dirs = [
            "include",
        ],
        libraries = [],
        library_dirs = [
            'lib',
        ],
        extra_objects=[
            'lib/libfaust.a'
        ],
        extra_compile_args = ['-std=c++11'],
        extra_link_args = ['-mmacosx-version-min=13.6'],
    ),
]


setup(
    name='cyfaust',
    ext_modules=cythonize(
        extensions,
        language_level="3str",
    ),
)
