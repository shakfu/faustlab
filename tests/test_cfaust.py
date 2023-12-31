import os, sys
BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
os.chdir(BUILD_PATH); sys.path.insert(0, BUILD_PATH)


import time
import cfaust

from testutils import print_section

# ---------------------------------------------------------------------------
# interpreter tests

def test_param_array():
    params = cfaust.ParamArray(["abc", "def"])
    params.dump()

def test_create_interpreter_dsp_factory_from_string():
    code = """\
        import("stdfaust.lib");
        f0 = hslider("[foo:bar]f0", 110, 110, 880, 1);
        n = 2;
        inst = par(i, n, os.oscs(f0 * (n+i) / n)) :> /(n);
        process = inst, inst;
    """
    factory = cfaust.InterpreterDspFactory.from_string("score", code)
    print("OK: test_create_interpreter_dsp_factory_from_string")


def test_audio():
    print("faust version:", cfaust.get_version())

    factory = cfaust.InterpreterDspFactory.from_file('noise.dsp')

    # print("compile options:", factory.get_compile_options())
    # print("library list:", factory.get_library_list())
    # print("sha key", factory.get_sha_key())

    dsp = factory.create_dsp_instance()

    # FIXME: doesn't work!!
    # ui = pyfaust.PrintUI()
    # dsp.build_user_interface(ui)
    
    dsp.build_default_user_interface()

    audio = cfaust.RtAudioDriver(48000, 256)

    audio.init(dsp)

    audio.start()
    time.sleep(1)
    # audio.stop() # not needed here


    # cleanup
    # del dsp
    # pyfaust.delete_interpreter_dsp_factory(factory)
    print("OK: test_create_interpreter_dsp_factory_from_file")


if __name__ == '__main__':
    print_section("testing cfaust")
    test_audio()

