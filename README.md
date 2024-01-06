# faustlab

An exploratory project to wrap the [Faust](https://github.com/grame-cncm/faust) *interpreter* and the [RtAudio](https://github.com/thestk/rtaudio) cross-platform audio driver for use by python code.

## Implementation Strategy

To get there, the plan *was* to experiment with several implementations using different wrapping frameworks ([cython](https://github.com/cython/cython), [pybind11](https://github.com/pybind/pybind11), and [nanobind](https://github.com/wjakob/nanobind)) which could eventually be compared for code size, binary size, performance, etc.

This led to the current implementation status:

| subproject   | framework  | api   |  audio test | interp api    |
| :---         | :---       | :---: |     :---:   |    :---:      |
| cyfaust      | cython     | c++   |      yes    |     95%       |
| cfaust       | cython     | c     |      yes    |     80%       |            
| nanofaust    | nanobind   | c++   |      yes    |     80%       |
| pbfaust      | pybind11   | c++   |      yes    |     80%       |

All of the above implementations pass a minimal functional test which produces audio given a faust dsp file (`noise.dsp`).

The `cyfaust` implementation has 'graduated' to its own [github project](https://github.com/shakfu/cyfaust) with support for the box and signal api and a more modular package organization and additional tests.

The current thinking is not develop the extensions in this project further and to exclusively focus on refining the `cyfaust` cpp implementation as the [DawDreamer](https://github.com/DBraun/DawDreamer) project already has a mature and full featured pybind11-based faust implementation, `nanobind` still needs a bit of time to mature, and the faust c api feels a bit like a second-class citizen compared to the c++ api

So in summary, this project will not be developed further from now on. You can visit the [cyfaust](https://github.com/shakfu/cyfaust) project for further work on the faust interpreter and the [DawDreamer] project for a more practical python faust implementation with with Daw-like features.

## Usage

Reequires:

- `cmake` (main buildsystem)

- `make` (build frontend)

- `python3` with dev libraries installed

Developed and tested only on macOS x86_64 and arm64 for the time being.

1. `./scripts/setup.sh`

    - This will download faust into the `build` directory, configure it, build it, and install the build into a local `prefix` inside the `build` directory/

    - The faust executable, staticlib, headers and stdlib from the newly installed local prefix will be copied into the project directory and and will create (and overwrite) the corresponding files in the `bin`, `include`, `lib` and `share` folders.

2. `make`
    
    - will build all variants {cython, pybind11, nanobind}

3. `make test` will test all of the externals for audio or you can test them individually via:

    `make test_cyfaust` or
    
    `make test_cfaust` or

    `make test_pyfaust` or

    `make test_nanofaust`

## FAQ

**Isn't it redundant to do the same thing four different ways?**

Probably, but it proved to be a nice way to learn the faust interpreter api and also learn about the idiosyncracies, strengths and weaknesses of each wrapper framework.

Current focus will be on the `cyfaust-c++` implementation.


**What else did you learn?**

Faust is c++ centric so it's best not to use the c-api if you can avoid it.


## Prior Art of Faust + Python

- [DawDreamer](https://github.com/DBraun/DawDreamer) by David Braun: Digital Audio Workstation with Python; VST instruments/effects, parameter automation, FAUST, JAX, Warp Markers, and JUCE processors. Full-featured and well-maintained. Use this for actual work! (pybind11)

- [faust_python](https://github.com/marcecj/faust_python) by Marc Joliet: A Python FAUST wrapper implemented using the CFFI. There's a more recent [fork](https://github.com/hrtlacek/faust_python]) by Patrik Lechner. (cffi)

- [pyfaust](https://github.com/amstan/pyfaust) by Alexandru Stan: Embed Faust DSP Programs in Python. (cffi)

- [faust-ctypes](https://gitlab.com/adud2/faust-ctypes): a port of Marc Joliet's FaustPy from CFFI to Ctypes. (ctypes)

- [faustpp](https://github.com/jpcima/faustpp): A post-processor for faust, which enables more flexible code generation.

