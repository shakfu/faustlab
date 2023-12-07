import os, sys
BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
os.chdir(BUILD_PATH); sys.path.insert(0, BUILD_PATH)

import time
import pyfaust

from testutils import print_section

def test_pyfaust():
    print("faust version:", pyfaust.get_version())

    factory = pyfaust.create_interpreter_dsp_factory_from_file('noise.dsp')

    print("compile options:", factory.get_compile_options())
    print("library list:", factory.get_library_list())
    print("sha key", factory.get_sha_key())

    dsp = factory.create_dsp_instance()

    # FIXME: doesn't work!!
    # ui = pyfaust.PrintUI()
    # dsp.build_user_interface(ui)
    
    # bypass
    dsp.build_user_interface()

    audio = pyfaust.RtAudioDriver(48000, 256)

    # audio.init("FaustDSP", dsp)
    audio.init(dsp)

    audio.start()
    time.sleep(1)
    # audio.stop() # not needed here


    # cleanup
    del dsp
    pyfaust.delete_interpreter_dsp_factory(factory)


if __name__ == '__main__':
    print_section("testing pyfaust")
    test_pyfaust()
