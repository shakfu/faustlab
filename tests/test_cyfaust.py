import os, sys
BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
os.chdir(BUILD_PATH); sys.path.insert(0, BUILD_PATH)


import time
import cyfaust

from testutils import print_section


def test_cyfaust():
    print("faust version:", cyfaust.get_version())

    factory = cyfaust.create_dsp_factory_from_file('noise.dsp')

    print("compile options:", factory.get_compile_options())
    print("library list:", factory.get_library_list())
    print("sha key", factory.get_sha_key())

    dsp = factory.create_dsp_instance()

    # FIXME: doesn't work!!
    # ui = cyfaust.PrintUI()
    # dsp.build_user_interface(ui)
    
    # bypass
    dsp.build_user_interface()

    audio = cyfaust.RtAudioDriver(48000, 256)

    # audio.init("FaustDSP", dsp)
    audio.init(dsp)

    audio.start()
    time.sleep(1)
    # audio.stop() # not needed here


if __name__ == '__main__':
    print_section("testing cyfaust")
    test_cyfaust()
