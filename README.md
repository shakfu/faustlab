# faustlab

An exploratory project to wrap the [Faust](https://github.com/grame-cncm/faust) *interpreter* for use by python via the following wrapping frameworks using the [RtAudio](https://github.com/thestk/rtaudio) cross-platform audio driver:

- cfaust:   cython      (faust c   interface)
- cyfaust:  cython      (faust c++ interface)
- nanobind: nanobind    (faust c++ interface)
- pyfaust:  pybind11    (faust c++ interface)

## Current Status

All of the above implementations pass a minimal functional test which produces audio given a faust dsp file (`noise.dsp`).

CAVEAT: project code is currently only at a proof of concept stage and is likely to contain a variety of bugs, memory leaks and other irritants...

**Isn't it redundant to do the same thing four different ways?**

Probably, but it proved to be a nice way to learn the faust interpreter api and also learn about the idiosyncracies and strengths and weaknesses of each wrapper framework.

**What else did you learn?**

Faust is c++ centric so it's best not to use the c-api if you can avoid it.



## Usage

Reequires:

- `cmake` (main buildsystem)

- `make` (build frontend)

- `python3` with dev libraries installed

Tested only on macOS x86_64 and arm64 system

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


## Prior Art of Faust + Python

- [DawDreamer](https://github.com/DBraun/DawDreamer) by David Braun: Digital Audio Workstation with Python; VST instruments/effects, parameter automation, FAUST, JAX, Warp Markers, and JUCE processors.

- [faust_python](https://github.com/marcecj/faust_python) by Marc Joliet: A Python FAUST wrapper implemented using the CFFI. There's a more recent [fork](https://github.com/hrtlacek/faust_python]) by Patrik Lechner.

- [faust-ctypes](https://gitlab.com/adud2/faust-ctypes): a port of Marc Joliet's FaustPy from CFFI to Ctypes.

- [faustpp](https://github.com/jpcima/faustpp): A post-processor for faust, which allows to generate with more flexibility


