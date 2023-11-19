# faustlab

A clean code attempt to wrap the Faust interpreter for use by python via

- [x] cython
- [x] pybind11
- [ ] nanobind
- [ ] cffi

## Usage

1. `./scripts/setup.sh`

	- This will download faust into the `build` directory, configure it build install the build into a local `prefix`. 

	- The faust executable, staticlib, headers and stdlib from the newly installed local prefix will be copied into the project directory and overwrite the corresponding files in the `bin`, `include`, `lib` and `share` folders.

2. `make` 
	
	- is an interface to the cmake build system

	- will build the `cython` and `pybind11` versions



