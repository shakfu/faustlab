
cdef extern from "faust/dsp/libfaust-signal-c.h":
    ctypedef struct CTree
    ctypedef CTree* Signal
    ctypedef CTree* Box

cdef extern from "faust/gui/Cinterface.h":
    ctypedef float FAUSTFLOAT
    ctypedef struct UIGlue
    ctypedef struct MetaGlue

cdef extern from "faust/dsp/interpreter-dsp-c.h":

    ctypedef struct interpreter_dsp_factory
    ctypedef struct interpreter_dsp

    const char* getCLibFaustVersion()

    # interpreter_dsp_factory
    interpreter_dsp_factory* getCInterpreterDSPFactoryFromSHAKey(const char* sha_key)
    interpreter_dsp_factory* createCInterpreterDSPFactoryFromFile(const char* filename, int argc, const char* argv[], char* error_msg)
    interpreter_dsp_factory* createCInterpreterDSPFactoryFromString(const char* name_app, const char* dsp_content, int argc, const char* argv[], char* error_msg)
    interpreter_dsp_factory* createCInterpreterDSPFactoryFromSignals(const char* name_app, Signal* signals, int argc, const char* argv[], char* error_msg)
    interpreter_dsp_factory* createCInterpreterDSPFactoryFromBoxes(const char* name_app, Box box, int argc, const char* argv[], char* error_msg)
    bint deleteCInterpreterDSPFactory(interpreter_dsp_factory* factory)
    const char** getCInterpreterDSPFactoryLibraryList(interpreter_dsp_factory* factory)
    void deleteAllCInterpreterDSPFactories()
    const char** getAllCInterpreterDSPFactories()
    bint startMTDSPFactories()
    void stopMTDSPFactories()
    interpreter_dsp_factory* readCInterpreterDSPFactoryFromBitcode(const char* bitcode, char* error_msg)
    char* writeCInterpreterDSPFactoryToBitcode(interpreter_dsp_factory* factory)
    interpreter_dsp_factory* readCInterpreterDSPFactoryFromBitcodeFile(const char* bit_code_path, char* error_msg)
    bint writeCInterpreterDSPFactoryToBitcodeFile(interpreter_dsp_factory* factory, const char* bit_code_path)

    # instance functions.
    int getNumInputsCInterpreterDSPInstance(interpreter_dsp* dsp)
    int getNumOutputsCInterpreterDSPInstance(interpreter_dsp* dsp)
    void buildUserInterfaceCInterpreterDSPInstance(interpreter_dsp* dsp, UIGlue* interface)
    int getSampleRateCInterpreterDSPInstance(interpreter_dsp* dsp)
    void initCInterpreterDSPInstance(interpreter_dsp* dsp, int sample_rate)
    void instanceInitCInterpreterDSPInstance(interpreter_dsp* dsp, int sample_rate)
    void instanceConstantsCInterpreterDSPInstance(interpreter_dsp* dsp, int sample_rate)
    void instanceResetUserInterfaceCInterpreterDSPInstance(interpreter_dsp* dsp)
    void instanceClearCInterpreterDSPInstance(interpreter_dsp* dsp)
    interpreter_dsp* cloneCInterpreterDSPInstance(interpreter_dsp* dsp)
    void metadataCInterpreterDSPInstance(interpreter_dsp* dsp, MetaGlue* meta)
    void computeCInterpreterDSPInstance(interpreter_dsp* dsp, int count, FAUSTFLOAT** input, FAUSTFLOAT** output)
    interpreter_dsp* createCInterpreterDSPInstance(interpreter_dsp_factory* factory)
    void deleteCInterpreterDSPInstance(interpreter_dsp* dsp)
