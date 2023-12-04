import cyfaust


## ---------------------------------------------------------------------------
## interpreter tests
##

def test_param_array():
    xs = ParamArray(["abc", "def"])
    xs.dump()

def test_create_interpreter_dsp_factory_from_string():
    cdef char error_msg[4096]

    code = """\
        import("stdfaust.lib");
        f0 = hslider("[foo:bar]f0", 110, 110, 880, 1);
        n = 2;
        inst = par(i, n, os.oscs(f0 * (n+i) / n)) :> /(n);
        process = inst, inst;
    """
    cdef fi.interpreter_dsp_factory* factory = fi.createCInterpreterDSPFactoryFromString(
        "score", code.encode('utf8'), 0, NULL, error_msg)

    if factory is NULL:
        print(error_msg.decode())
    else:
        fi.deleteCInterpreterDSPFactory(factory)
        print("OK: test_create_interpreter_dsp_factory_from_string")


def test_create_dsp_factory_from_string():
    code = """\
        import("stdfaust.lib");
        f0 = hslider("[foo:bar]f0", 110, 110, 880, 1);
        n = 2;
        inst = par(i, n, os.oscs(f0 * (n+i) / n)) :> /(n);
        process = inst, inst;
    """
    factory = create_dsp_factory_from_string("score", code)
    print("OK: test_create_interpreter_dsp_factory_from_string")




def test_create_interpreter_dsp_factory_from_file():
    print("faust version:", get_version())

    factory = InterpreterDspFactory.from_file('noise.dsp')

    print("compile options:", factory.get_compile_options())
    print("library list:", factory.get_library_list())
    print("sha key", factory.get_sha_key())

    dsp = factory.create_dsp_instance()

    # # FIXME: doesn't work!!
    # # ui = pyfaust.PrintUI()
    # # dsp.build_user_interface(ui)
    
    # # bypass
    dsp.build_user_interface()

    # audio = pyfaust.RtAudioDriver(48000, 256)

    # # audio.init("FaustDSP", dsp)
    # audio.init(dsp)

    # audio.start()
    # time.sleep(1)
    # # audio.stop() # not needed here


    # # cleanup
    # del dsp
    # pyfaust.delete_interpreter_dsp_factory(factory)
    print("OK: test_create_interpreter_dsp_factory_from_file")


