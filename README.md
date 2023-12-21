# faustlab

An exploratory project to wrap the [Faust](https://github.com/grame-cncm/faust) *interpreter* and the [RtAudio](https://github.com/thestk/rtaudio) cross-platform audio driver for use by python code.

The objective is to end up with a minimal, self-contained, cross-platform extension.

To get there, there will be several implementations using different wrapping frameworks (cython, pybind11, and nanobind) which can eventually be compared for code size, binary size, performance, etc.

## Current Status

| subproject   | framework  | api   |  audio test | interp api    | box api    | signal api |
| :---         | :---       | :---: |     :---:   |    :---:      | :---:      | :---:      |
| cyfaust      | cython     | c++   |      yes    |     98%       | 85%        | 850%        |
| cfaust       | cython     | c     |      yes    |     80%       |            |            |
| nanofaust    | nanobind   | c++   |      yes    |     80%       |            |            |
| pyfaust      | pybind11   | c++   |      yes    |     80%       |            |            |


All of the above implementations pass a minimal functional test which produces audio given a faust dsp file (`noise.dsp`).

The `cyfaust` implementation also includes `faust_box.pxd`, `faust_signal.pxd` and an attempt to wrap both the faust box api and the faust signal api using a dual object-oriented and functional approach. (This will likely evolve with actual usage). There are a couple of basic tests for the box api in the `tests` directory.

NOTE: this project's code is currently only at a proof of concept stage and is likely to contain a variety of bugs, memory leaks and other irritants...

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


**What else did you learn?**

Faust is c++ centric so it's best not to use the c-api if you can avoid it.


## Prior Art of Faust + Python

- [DawDreamer](https://github.com/DBraun/DawDreamer) by David Braun: Digital Audio Workstation with Python; VST instruments/effects, parameter automation, FAUST, JAX, Warp Markers, and JUCE processors. Full-featured and well-maintained. Use this for actual work! (pybind11)

- [faust_python](https://github.com/marcecj/faust_python) by Marc Joliet: A Python FAUST wrapper implemented using the CFFI. There's a more recent [fork](https://github.com/hrtlacek/faust_python]) by Patrik Lechner. (cffi)

- [pyfaust](https://github.com/amstan/pyfaust) by Alexandru Stan: Embed Faust DSP Programs in Python. (cffi)

- [faust-ctypes](https://gitlab.com/adud2/faust-ctypes): a port of Marc Joliet's FaustPy from CFFI to Ctypes. (ctypes)

- [faustpp](https://github.com/jpcima/faustpp): A post-processor for faust, which enables more flexible code generation.

