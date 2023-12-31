# set path so `faust` be queried for the path to stdlib
export PATH := $(PWD)/bin:$(PATH)

WITH_DYLIB=0

MIN_OSX_VER := -mmacosx-version-min=13.6

FAUST_STATICLIB := ./lib/libfaust.a
INTERP_TESTS := tests/test_faust_interp

.PHONY: cmake clean setup setup_inplace wheel

all: cmake

cmake:
	@mkdir -p build && cd build && cmake .. -DFAUST_SHAREDLIB=$(WITH_DYLIB) && make

setup:
	@python3 setup.py build

setup_inplace:
	@python3 setup.py build_ext --inplace
	@rm -rf build

wheel:
	@echo "WITH_DYLIB=$(WITH_DYLIB)"
	@python3 setup.py bdist_wheel
ifeq ($(WITH_DYLIB),1)
	delocate-wheel -v dist/*.whl 
endif

.PHONY: test test_cpp test_c test_audio test_cyfaust test_cfaust test_pyfaust test_nanofaust


test_cpp:
	@g++ -std=c++11 $(MIN_OSX_VER) -O3 \
		-DINTERP_DSP=1 \
		$(INTERP_TESTS)/interp-test.cpp \
		-I./include \
		-L./lib -L`brew --prefix`/lib $(FAUST_STATICLIB) \
		-o /tmp/interp-test
	@/tmp/interp-test tests/noise.dsp

test_c:
	@g++ -O3 $(MIN_OSX_VER) \
		-DINTERP_DSP=1 \
		$(INTERP_TESTS)/interp-test.c \
		-I./include \
		-L./lib -L`brew --prefix`/lib $(FAUST_STATICLIB) \
		-o /tmp/interp-test
	@/tmp/interp-test tests/noise.dsp

test_audio:
	@g++ -std=c++11 $(MIN_OSX_VER) -O3 \
		-DINTERP_DSP=1 -D__MACOSX_CORE__ \
		$(INTERP_TESTS)/interp-audio-min.cpp ./include/rtaudio/RtAudio.cpp \
		-I./include \
		-L./lib -L`brew --prefix`/lib $(FAUST_STATICLIB) \
		-framework CoreFoundation -framework CoreAudio -lpthread \
		-o /tmp/audio-test
	@/tmp/audio-test tests/noise.dsp
# 	@/tmp/audio-test tests/test_faust_interp/foo.dsp


test: test_cyfaust test_cfaust test_pyfaust test_nanofaust prep_tests
	@echo "DONE"

build/noise.dsp:
	@cp tests/noise.dsp ./build/

prep_tests: build/noise.dsp

test_cyfaust: cmake prep_tests
	@python3 tests/test_cyfaust.py

test_cfaust: cmake prep_tests
	@python3 tests/test_cfaust.py

test_pyfaust: cmake prep_tests
	@python3 tests/test_pyfaust.py

test_nanofaust: cmake prep_tests
	@python3 tests/test_nanofaust.py

clean:
	@rm -rf build dist *.egg-info

