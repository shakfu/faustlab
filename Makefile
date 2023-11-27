# set path so `faust` be queried for the path to stdlib
export PATH := $(PWD)/bin:$(PATH)

MIN_OSX_VER := -mmacosx-version-min=13.6

FAUST_STATICLIB := ./lib/libfaust.a
INTERP_TESTS := tests/test_faust_interp

.PHONY: clean test test_cpp test_c pyfaust cyfaust cyfaust_inplace

all: pyfaust # cyfaust


pyfaust:
	@mkdir -p build && cd build && cmake .. && make

cyfaust:
	@python3 setup.py build

cyfaust_inplace:
	@python3 setup.py build_ext --inplace
	@rm -rf build

test_cpp:
	@g++ -std=c++11 $(MIN_OSX_VER) -O3 \
		-DINTERP_DSP=1 \
		$(INTERP_TESTS)/interp-test.cpp \
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

test_c:
	@g++ -O3 $(MIN_OSX_VER) \
		-DINTERP_DSP=1 \
		$(INTERP_TESTS)/interp-test.c \
		-I./include \
		-L./lib -L`brew --prefix`/lib $(FAUST_STATICLIB) \
		-o /tmp/interp-test
	@/tmp/interp-test tests/noise.dsp

test:
	@cp tests/test_cyfaust.py build/
	@python3 build/test_cyfaust.py

clean:
	@rm projects/cyfaust/cyfaust.cpp
	@rm -rf cyfaust.*.so build
