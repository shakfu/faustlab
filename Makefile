# set path so `faust` be queried for the path to stdlib
export PATH := $(PWD)/bin:$(PATH)

MIN_OSX_VER := -mmacosx-version-min=13.6

.PHONY: clean test_cpp test_c pyfaust cyfaust cyfaust_inplace

all: pyfaust # cyfaust


pyfaust:
	@mkdir -p build && cd build && cmake .. && make

cyfaust:
	@python3 setup.py build

cyfaust_inplace:
	@python3 setup.py build_ext --inplace
	@rm -rf build

test_cpp:
	g++ -DINTERP_DSP=1 $(MIN_OSX_VER) -std=c++11 -O3 tests/interp-test.cpp -I./include -L./lib -L`brew --prefix`/lib ./lib/libfaust.a -o /tmp/interp-test
	/tmp/interp-test tests/noise.dsp

test_c:
	g++ -DINTERP_DSP=1 -O3 $(MIN_OSX_VER) tests/interp-test.c -I./include -L./lib -L`brew --prefix`/lib ./lib/libfaust.a -o /tmp/interp-test
	/tmp/interp-test tests/noise.dsp

test:
	@cp tests/test_cyfaust.py build/lib.macosx-13-arm64-cpython-311/
	@python3 build/lib.macosx-13-arm64-cpython-311/test_cyfaust.py

clean:
	@rm -rf cyfaust.*.so build