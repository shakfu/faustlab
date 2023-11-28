import time

import pyfaust

def test_pyfaust():
	print("faust version:", pyfaust.get_version())

	factory = pyfaust.create_interpreter_dsp_factory_from_file('noise.dsp')

	print("compile options:", factory.get_compile_options())
	print("library list:", factory.get_library_list())
	print("sha key", factory.get_sha_key())

	dsp = factory.create_dsp_instance()

	ui = pyfaust.PrintUI()

	dsp.build_user_interface(ui)

	audio = RtAudioDriver(44800, 256)

	audio.init(dsp)

	audio.start()

	time.sleep(1000)

	audio.stop()
        audio.start();
        usleep(1000000);
        audio.stop();
    

   # cleanup
   del dsp
   pyfaust.delete_interpreter_dsp_factory(factory)
