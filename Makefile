# set path so `faust` be queried for the path to stdlib
export PATH := $(PWD)/bin:$(PATH)

MIN_OSX_VER := -mmacosx-version-min=13.6

FAUST_STATICLIB := ./lib/libfaust.a
INTERP_TESTS := tests/test_faust_interp

.PHONY: cmake clean setup_py setup_py_inplace

all: cmake

cmake:
	@mkdir -p build && cd build && cmake .. && make

setup_py:
	@python3 setup.py build

setup_py_inplace:
	@python3 setup.py build_ext --inplace
	@rm -rf build


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


test: test_cyfaust test_cfaust test_pyfaust test_nanofaust
	@echo "DONE"


test_cyfaust: cmake
	@echo "testing cyfaust"
	@cp tests/noise.dsp ./build/
	@cp tests/test_cyfaust.py ./build/
	@cd build && python3 test_cyfaust.py

test_cfaust: cmake
	@echo "testing cfaust"
	@cp tests/noise.dsp ./build/
	@cp tests/test_cfaust.py ./build/
	@cd build && python3 test_cfaust.py

test_pyfaust: cmake
	@echo "testing pyfaust"
	@cp tests/noise.dsp ./build/
	@cp tests/test_pyfaust.py ./build/
	@cd build && python3 test_pyfaust.py

test_nanofaust: cmake
	@echo "testing nanofaust"
	@cp tests/noise.dsp ./build/
	@cp tests/test_nanofaust.py ./build/
	@cd build && python3 test_nanofaust.py

clean:
	@rm projects/cyfaust/cyfaust.cpp
	@rm -rf cyfaust.*.so build

