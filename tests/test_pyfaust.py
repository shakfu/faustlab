import time

import pyfaust

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
    test_pyfaust()
