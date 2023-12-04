
cdef extern from "faust/dsp/libfaust.h":
    void freeCMemory(void* ptr)



cdef extern from "faust/gui/CInterface.h":
    ctypedef float FAUSTFLOAT

    ctypedef void (* openTabBoxFun) (void* ui_interface, const char* label)
    ctypedef void (* openHorizontalBoxFun) (void* ui_interface, const char* label)
    ctypedef void (* openVerticalBoxFun) (void* ui_interface, const char* label)
    ctypedef void (* closeBoxFun) (void* ui_interface)
    # -- active widgets
    ctypedef void (* addButtonFun) (void* ui_interface, const char* label, FAUSTFLOAT* zone)
    ctypedef void (* addCheckButtonFun) (void* ui_interface, const char* label, FAUSTFLOAT* zone)
    ctypedef void (* addVerticalSliderFun) (void* ui_interface, const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step)
    ctypedef void (* addHorizontalSliderFun) (void* ui_interface, const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step)
    ctypedef void (* addNumEntryFun) (void* ui_interface, const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step)
    # -- passive widgets
    ctypedef void (* addHorizontalBargraphFun) (void* ui_interface, const char* label, FAUSTFLOAT* zone, FAUSTFLOAT min, FAUSTFLOAT max)
    ctypedef void (* addVerticalBargraphFun) (void* ui_interface, const char* label, FAUSTFLOAT* zone, FAUSTFLOAT min, FAUSTFLOAT max)
    # -- soundfiles
    # ctypedef void (* addSoundfileFun) (void* ui_interface, const char* label, const char* url, struct Soundfile** sf_zone)

    ctypedef void (* declareFun) (void* ui_interface, FAUSTFLOAT* zone, const char* key, const char* value)

    ctypedef struct UIGlue:
        openTabBoxFun openTabBox
        openHorizontalBoxFun openHorizontalBox
        openVerticalBoxFun openVerticalBox
        closeBoxFun closeBox
        addButtonFun addButton
        addCheckButtonFun addCheckButton
        addVerticalSliderFun addVerticalSlider
        addHorizontalSliderFun addHorizontalSlider
        addNumEntryFun addNumEntry
        addHorizontalBargraphFun addHorizontalBargraph
        addVerticalBargraphFun addVerticalBargraph
        # addSoundfileFun addSoundfile
        declareFun declare

    ctypedef void (* metaDeclareFun) (void* ui_interface, const char* key, const char* value)

    ctypedef struct MetaGlue:
        void* metaInterface
        metaDeclareFun declare

    ctypedef char dsp_imp

    ctypedef dsp_imp* (* newDspFun) ()
    ctypedef void (* destroyDspFun) (dsp_imp* dsp)
    ctypedef int (* getNumInputsFun) (dsp_imp* dsp)
    ctypedef int (* getNumOutputsFun) (dsp_imp* dsp)
    ctypedef void (* buildUserInterfaceFun) (dsp_imp* dsp, UIGlue* ui)
    ctypedef int (* getSampleRateFun) (dsp_imp* dsp)
    ctypedef void (* initFun) (dsp_imp* dsp, int sample_rate)
    ctypedef void (* classInitFun) (int sample_rate)
    ctypedef void (* instanceInitFun) (dsp_imp* dsp, int sample_rate)
    ctypedef void (* instanceConstantsFun) (dsp_imp* dsp, int sample_rate)
    ctypedef void (* instanceResetUserInterfaceFun) (dsp_imp* dsp)
    ctypedef void (* instanceClearFun) (dsp_imp* dsp)
    ctypedef void (* computeFun) (dsp_imp* dsp, int len, FAUSTFLOAT** inputs, FAUSTFLOAT** outputs)
    ctypedef void (* metadataFun) (MetaGlue* meta)
     
    # DSP memory manager functions

    ctypedef void* (* allocateFun) (void* manager_interface, size_t size)
    ctypedef void (* destroyFun) (void* manager_interface, void* ptr)

    ctypedef struct MemoryManagerGlue:
        void* managerInterface
        allocateFun allocate
        destroyFun destroy

cdef extern from "faust/gui/PrintCUI.h":
    cdef UIGlue uglue
    ctypedef struct PrintCUI:
        int fVar1
        float fVar2

cdef extern from "faust/dsp/libfaust-signal-c.h":
    ctypedef struct CTree
    ctypedef CTree* Signal
    ctypedef CTree* Box


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

cdef extern from "faust/dsp/dsp.h":
    cdef cppclass dsp_memory_manager
    cdef cppclass dsp

cdef extern from "faust/audio/rtaudio-dsp.h":
    cdef cppclass rtaudio:    
        rtaudio(int srate, int bsize) except +
        # bint init(const char* name, dsp* DSP)
        bint init(const char* name, int numInputs, int numOutputs)
        void setDsp(dsp* DSP)
        bint start() 
        void stop() 
        int getBufferSize() 
        int getSampleRate()
        int getNumInputs()
        int getNumOutputs()


