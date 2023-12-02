from libcpp.string cimport string
from libcpp.vector cimport vector

cdef extern from "faust/dsp/libfaust-signal.h":
    cdef cppclass CTree
    ctypedef vector[CTree*] tvec
    ctypedef CTree* Signal
    ctypedef CTree* Box

cdef extern from "faust/gui/CInterface.h":
    ctypedef float FAUSTFLOAT
    ctypedef struct UIGlue
    ctypedef struct MetaGlue

cdef extern from "faust/dsp/interpreter-dsp.h":
    const char* getCLibFaustVersion()

    # foreward declarations
    cdef cppclass interpreter_dsp_factory
    cdef cppclass interpreter_dsp

    cdef cppclass interpreter_dsp:
        interpreter_dsp() except +
        int getNumInputs()
        int getNumOutputs()
        # void buildUserInterface(UI* ui_interface)
        int getSampleRate()
        void init(int sample_rate)
        void instanceInit(int sample_rate)
        void instanceConstants(int sample_rate)
        void instanceResetUserInterface()
        void instanceClear()
        interpreter_dsp* clone()
        # void metadata(Meta* m)
        # void compute(int count, float** inputs, float** outputs)

    cdef cppclass interpreter_dsp_factory:
        # ~interpreter_dsp_factory()
        string getName()
        string getSHAKey()
        string getDSPCode()
        string getCompileOptions()
        vector[string] getLibraryList()
        vector[string] getIncludePathnames()
        vector[string] getWarningMessages()
        interpreter_dsp* createDSPInstance()
        # void setMemoryManager(dsp_memory_manager* manager)
        # dsp_memory_manager* getMemoryManager()

    # interpreter_dsp_factory
    interpreter_dsp_factory* getInterpreterDSPFactoryFromSHAKey(const string& sha_key)
    interpreter_dsp_factory* createInterpreterDSPFactoryFromFile(const string& filename, int argc, const char* argv[], string& error_msg)
    interpreter_dsp_factory* createInterpreterDSPFactoryFromString(const string& name_app, const string& dsp_content, int argc, const char* argv[], string& error_msg)

    interpreter_dsp_factory* createInterpreterDSPFactoryFromSignals(const string& name_app, tvec signals, int argc, const char* argv[], string& error_msg)
    interpreter_dsp_factory* createInterpreterDSPFactoryFromBoxes(const string& name_app, Box box, int argc, const char* argv[], string& error_msg)
    bint deleteInterpreterDSPFactory(interpreter_dsp_factory* factory)
    void deleteAllInterpreterDSPFactories()
    vector[string] getAllInterpreterDSPFactories()
    bint startMTDSPFactories()
    void stopMTDSPFactories()
    interpreter_dsp_factory* readInterpreterDSPFactoryFromBitcode(const string& bitcode, string& error_msg)
    string writeInterpreterDSPFactoryToBitcode(interpreter_dsp_factory* factory)
    interpreter_dsp_factory* readInterpreterDSPFactoryFromBitcodeFile(const string& bit_code_path, string& error_msg)
    bint writeInterpreterDSPFactoryToBitcodeFile(interpreter_dsp_factory* factory, const string& bit_code_path)
