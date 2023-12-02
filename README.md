# faustlab

A exploratory project to wrap the Faust *interpreter* for use by python via the following wrapping frameworks

- [ ] cyfaust: 	cython 		(faust c++ interface)
- [ ] cfaustt: 	cython 		(faust c interface)
- [x] pyfaust: 	pybind11 	(faust c++ interface)
- [ ] nanobind: nanobind 	(faust c++ interface)

The tick in the box means that wrapper has passed a minimal functional test to produce audio given a faust dsp file.

## Usage


1. `./scripts/setup.sh`

	- This will download faust into the `build` directory, configure it, build it, and install the build into a local `prefix` inside the `build` directory/

	- The faust executable, staticlib, headers and stdlib from the newly installed local prefix will be copied into the project directory and and will create (and overwrite) the corresponding files in the `bin`, `include`, `lib` and `share` folders.

2. `make`
	
	- will build all variants {cython, pybind11, nanobind}

