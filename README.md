# faustlab

An exploratory project to wrap the Faust *interpreter* for use by python via the following wrapping frameworks using the RtAudio cross-platform audio driver:

- cfaust:   cython      (faust c   interface)
- cyfaust:  cython      (faust c++ interface)
- nanobind: nanobind    (faust c++ interface)
- pyfaust:  pybind11    (faust c++ interface)

## Current Status

All of the above subprojects pass a minimal functional test which produces noise given a faust dsp file (`noise.dsp`).

CAVEAT: the code is currently only in a proof of concept stage and is likely to contain a variety of bug, memory leaks and other irritants...

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

3. `make test` will test all of the externals for audio or individual via:

    `make test_cyfaust` or
    
    `make test_cfaust` or

    `make test_pyfaust` or

    `make test_nanofaust`


