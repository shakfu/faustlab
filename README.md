# faustlab

A clean code attempt to wrap the Faust *interpreter* for use by python via

- [x] cython
- [x] pybind11
- [x] nanobind
- [ ] cffi

## Usage


1. `./scripts/setup.sh`

	- This will download faust into the `build` directory, configure it, build it, and install the build into a local `prefix` inside the `build` directory/

	- The faust executable, staticlib, headers and stdlib from the newly installed local prefix will be copied into the project directory and and will create (and overwrite) the corresponding files in the `bin`, `include`, `lib` and `share` folders.

2. `make`
	
	- will build all variants {cython, pybind11, nanobindm ..}





