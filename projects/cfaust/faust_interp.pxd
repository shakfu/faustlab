
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

    char* CprintBox(Box box, bint shared, int max_size)
    char* CprintSignal(Signal sig, bint shared, int max_size)
    void createLibContext()
    void destroyLibContext()
    bint CisNil(Signal s)
    const char* Ctree2str(Signal s)
    void* CgetUserData(Signal s)
    Signal CsigInt(int n)
    Signal CsigReal(double n)
    Signal CsigInput(int idx)
    Signal CsigDelay(Signal s, Signal delay)
    Signal CsigDelay1(Signal s)
    Signal CsigIntCast(Signal s)
    Signal CsigFloatCast(Signal s)
    Signal CsigReadOnlyTable(Signal n, Signal init, Signal ridx)
    Signal CsigWriteReadTable(Signal n, Signal init, Signal widx, Signal wsig, Signal ridx)
    Signal CsigWaveform(Signal* wf)
    Signal CsigSoundfile(const char* label)
    Signal CsigSoundfileLength(Signal sf, Signal part)
    Signal CsigSoundfileRate(Signal sf, Signal part)
    Signal CsigSoundfileBuffer(Signal sf, Signal chan, Signal part, Signal ridx)
    Signal CsigSelect2(Signal selector, Signal s1, Signal s2)
    Signal CsigSelect3(Signal selector, Signal s1, Signal s2, Signal s3)
    # Signal CsigFConst(enum SType type, const char* name, const char* file)
    # Signal CsigFVar(enum SType type, const char* name, const char* file)
    # Signal CsigBinOp(enum SOperator op, Signal x, Signal y)

    Signal CsigAdd(Signal x, Signal y)
    Signal CsigSub(Signal x, Signal y)
    Signal CsigMul(Signal x, Signal y)
    Signal CsigDiv(Signal x, Signal y)
    Signal CsigRem(Signal x, Signal y)
        
#     Signal CsigLeftShift(Signal x, Signal y)
#     Signal CsigLRightShift(Signal x, Signal y)
#     Signal CsigARightShift(Signal x, Signal y)
        
#     Signal CsigGT(Signal x, Signal y)
#     Signal CsigLT(Signal x, Signal y)
#     Signal CsigGE(Signal x, Signal y)
#     Signal CsigLE(Signal x, Signal y)
#     Signal CsigEQ(Signal x, Signal y)
#     Signal CsigNE(Signal x, Signal y)
        
#     Signal CsigAND(Signal x, Signal y)
#     Signal CsigOR(Signal x, Signal y)
#     Signal CsigXOR(Signal x, Signal y)
        
    Signal CsigAbs(Signal x)
#     Signal CsigAcos(Signal x)
#     Signal CsigTan(Signal x)
#     Signal CsigSqrt(Signal x)
#     Signal CsigSin(Signal x)
#     Signal CsigRint(Signal x)
#     Signal CsigLog(Signal x)
#     Signal CsigLog10(Signal x)
#     Signal CsigFloor(Signal x)
#     Signal CsigExp(Signal x)
#     Signal CsigExp10(Signal x)
#     Signal CsigCos(Signal x)
#     Signal CsigCeil(Signal x)
#     Signal CsigAtan(Signal x)
#     Signal CsigAsin(Signal x)

    Signal CsigRemainder(Signal x, Signal y)
#     Signal CsigPow(Signal x, Signal y)
#     Signal CsigMin(Signal x, Signal y)
#     Signal CsigMax(Signal x, Signal y)
#     Signal CsigFmod(Signal x, Signal y)
#     Signal CsigAtan2(Signal x, Signal y)
        
#     Signal CsigSelf()
        
    Signal CsigRecursion(Signal s)
    Signal CsigSelfN(int id)
    Signal* CsigRecursionN(Signal* rf)
    Signal CsigButton(const char* label)
    Signal CsigCheckbox(const char* label)
    Signal CsigVSlider(const char* label, Signal init, Signal min, Signal max, Signal step)
    Signal CsigHSlider(const char* label, Signal init, Signal min, Signal max, Signal step)
    Signal CsigNumEntry(const char* label, Signal init, Signal min, Signal max, Signal step)
    Signal CsigVBargraph(const char* label, Signal min, Signal max, Signal s)
    Signal CsigHBargraph(const char* label, Signal min, Signal max, Signal s)
    Signal CsigAttach(Signal s1, Signal s2)
#     bint CisSigInt(Signal t, int* i)
#     bint CisSigReal(Signal t, double* r)
#     bint CisSigInput(Signal t, int* i)
#     bint CisSigOutput(Signal t, int* i, Signal* t0)
#     bint CisSigDelay1(Signal t, Signal* t0)
#     bint CisSigDelay(Signal t, Signal* t0, Signal* t1)
#     bint CisSigPrefix(Signal t, Signal* t0, Signal* t1)
#     bint CisSigRDTbl(Signal s, Signal* t, Signal* i)
#     bint CisSigWRTbl(Signal u, Signal* id, Signal* t, Signal* i, Signal* s)
#     bint CisSigGen(Signal t, Signal* x)
#     bint CisSigGen1(Signal t)
#     bint CisSigDocConstantTbl(Signal t, Signal* n, Signal* sig)
#     bint CisSigDocWriteTbl(Signal t, Signal* n, Signal* sig, Signal* widx, Signal* wsig)
#     bint CisSigDocAccessTbl(Signal t, Signal* tbl, Signal* ridx)
#     bint CisSigSelect2(Signal t, Signal* selector, Signal* s1, Signal* s2)
#     bint CisSigAssertBounds(Signal t, Signal* s1, Signal* s2, Signal* s3)
#     bint CisSigHighest(Signal t, Signal* s)
#     bint CisSigLowest(Signal t, Signal* s)

#     bint CisSigBinOp(Signal s, int* op, Signal* x, Signal* y)
#     bint CisSigFFun(Signal s, Signal* ff, Signal* largs)
#     bint CisSigFConst(Signal s, Signal* type, Signal* name, Signal* file)
#     bint CisSigFVar(Signal s, Signal* type, Signal* name, Signal* file)
        
#     bint CisProj(Signal s, int* i, Signal* rgroup)
#     bint CisRec(Signal s, Signal* var, Signal* body)
        
#     bint CisSigIntCast(Signal s, Signal* x)
#     bint CisSigFloatCast(Signal s, Signal* x)
        
#     bint CisSigButton(Signal s, Signal* lbl)
#     bint CisSigCheckbox(Signal s, Signal* lbl)
        
#     bint CisSigWaveform(Signal s)
        
#     bint CisSigHSlider(Signal s, Signal* lbl, Signal* init, Signal* min, Signal* max, Signal* step)
#     bint CisSigVSlider(Signal s, Signal* lbl, Signal* init, Signal* min, Signal* max, Signal* step)
#     bint CisSigNumEntry(Signal s, Signal* lbl, Signal* init, Signal* min, Signal* max, Signal* step)
        
#     bint CisSigHBargraph(Signal s, Signal* lbl, Signal* min, Signal* max, Signal* x)
#     bint CisSigVBargraph(Signal s, Signal* lbl, Signal* min, Signal* max, Signal* x)
        
#     bint CisSigAttach(Signal s, Signal* s0, Signal* s1)
        
#     bint CisSigEnable(Signal s, Signal* s0, Signal* s1)
#     bint CisSigControl(Signal s, Signal* s0, Signal* s1)
        
#     bint CisSigSoundfile(Signal s, Signal* label)
#     bint CisSigSoundfileLength(Signal s, Signal* sf, Signal* part)
#     bint CisSigSoundfileRate(Signal s, Signal* sf, Signal* part)
#     bint CisSigSoundfileBuffer(Signal s, Signal* sf, Signal* chan, Signal* part, Signal* ridx)

    # Signal CsimplifyToNormalForm(Signal s)
    # Signal* CsimplifyToNormalForm2(Signal* siglist)
    # char* CcreateSourceFromSignals(const char* name_app, Signal* osigs, const char* lang, int argc, const char* argv[], char* error_msg)


# cdef extern from "faust/dsp/libfaust-box-c.h":
#     char* CprintBox(Box box, bool shared, int max_size)
#     char* CprintSignal(Signal sig, bool shared, int max_size)
#     void createLibContext()
#     void destroyLibContext()
#     bint CisNil(Box b)
#     const char* Ctree2str(Box b)
#     int Ctree2int(Box b)
#     void* CgetUserData(Box b)
#     Box CboxInt(int n)
#     Box CboxReal(double n)
#     Box CboxWire()
#     Box CboxCut()
#     Box CboxSeq(Box x, Box y)
#     Box CboxPar(Box x, Box y)
#     Box CboxPar3(Box x, Box y, Box z)
#     Box CboxPar4(Box a, Box b, Box c, Box d)
#     Box CboxPar5(Box a, Box b, Box c, Box d, Box e) 

#     Box CboxSplit(Box x, Box y)
#     Box CboxMerge(Box x, Box y)
#     Box CboxRec(Box x, Box y)
#     Box CboxRoute(Box n, Box m, Box r)
#     Box CboxDelay()
#     Box CboxDelayAux(Box b, Box del)
#     Box CboxIntCast()
#     Box CboxIntCastAux(Box b)
#     Box CboxFloatCast()
#     Box CboxFloatCastAux(Box b)
#     Box CboxReadOnlyTable()
#     Box CboxReadOnlyTableAux(Box n, Box init, Box ridx)
#     Box CboxWriteReadTable()
#     Box CboxWriteReadTableAux(Box n, Box init, Box widx, Box wsig, Box ridx)
#     Box CboxWaveform(Box* wf)
#     Box CboxSoundfile(const char* label, Box chan)

#     Box CboxSelect2()
#     Box CboxSelect2Aux(Box selector, Box b1, Box b2)
#     Box CboxSelect3()
#     Box CboxSelect3Aux(Box selector, Box b1, Box b2, Box b3)
#     Box CboxFConst(SType type, const char* name, const char* file)
#     Box CboxFVar(SType type, const char* name, const char* file)
#     Box CboxBinOp(SOperator op)
#     Box CboxBinOpAux(SOperator op, Box b1, Box b2)

#     Box CboxAdd()
#     Box CboxAddAux(Box b1, Box b2)
#     Box CboxSub()
#     Box CboxSubAux(Box b1, Box b2)
#     Box CboxMul()
#     Box CboxMulAux(Box b1, Box b2)
#     Box CboxDiv()
#     Box CboxDivAux(Box b1, Box b2)
#     Box CboxRem()
#     Box CboxRemAux(Box b1, Box b2)

#     Box CboxLeftShift()
#     Box CboxLeftShiftAux(Box b1, Box b2)
#     Box CboxLRightShift()
#     Box CboxLRightShiftAux(Box b1, Box b2)
#     Box CboxARightShift()
#     Box CboxARightShiftAux(Box b1, Box b2)

#     Box CboxGT()
#     Box CboxGTAux(Box b1, Box b2)
#     Box CboxLT()
#     Box CboxLTAux(Box b1, Box b2)
#     Box CboxGE()
#     Box CboxGEAux(Box b1, Box b2)
#     Box CboxLE()
#     Box CboxLEAux(Box b1, Box b2)
#     Box CboxEQ()
#     Box CboxEQAux(Box b1, Box b2)
#     Box CboxNE()
#     Box CboxNEAux(Box b1, Box b2)

#     Box CboxAND()
#     Box CboxANDAux(Box b1, Box b2)
#     Box CboxOR()
#     Box CboxORAux(Box b1, Box b2)
#     Box CboxXOR()
#     Box CboxXORAux(Box b1, Box b2)

#     Box CboxAbs()
#     Box CboxAbsAux(Box x)
#     Box CboxAcos()
#     Box CboxAcosAux(Box x)
#     Box CboxTan()
#     Box CboxTanAux(Box x)
#     Box CboxSqrt()
#     Box CboxSqrtAux(Box x)
#     Box CboxSin()
#     Box CboxSinAux(Box x)
#     Box CboxRint()
#     Box CboxRintAux(Box x)
#     Box CboxRound()
#     Box CboxRoundAux(Box x)
#     Box CboxLog()
#     Box CboxLogAux(Box x)
#     Box CboxLog10()
#     Box CboxLog10Aux(Box x)
#     Box CboxFloor()
#     Box CboxFloorAux(Box x)
#     Box CboxExp()
#     Box CboxExpAux(Box x)
#     Box CboxExp10()
#     Box CboxExp10Aux(Box x)
#     Box CboxCos()
#     Box CboxCosAux(Box x)
#     Box CboxCeil()
#     Box CboxCeilAux(Box x)
#     Box CboxAtan()
#     Box CboxAtanAux(Box x)
#     Box CboxAsin()
#     Box CboxAsinAux(Box x)

#     Box CboxRemainder()
#     Box CboxRemainderAux(Box b1, Box b2)
#     Box CboxPow()
#     Box CboxPowAux(Box b1, Box b2)
#     Box CboxMin()
#     Box CboxMinAux(Box b1, Box b2)
#     Box CboxMax()
#     Box CboxMaxAux(Box b1, Box b2)
#     Box CboxFmod()
#     Box CboxFmodAux(Box b1, Box b2)
#     Box CboxAtan2()
#     Box CboxAtan2Aux(Box b1, Box b2)

#     Box CboxButton(const char* label)
#     Box CboxCheckbox(const char* label)
#     Box CboxVSlider(const char* label, Box init, Box min, Box max, Box step)
#     Box CboxHSlider(const char* label, Box init, Box min, Box max, Box step)
#     Box CboxNumEntry(const char* label, Box init, Box min, Box max, Box step)
#     Box CboxVBargraph(const char* label, Box min, Box max)
#     Box CboxVBargraphAux(const char* label, Box min, Box max, Box x)
#     Box CboxHBargraph(const char* label, Box min, Box max)
#     Box CboxHBargraphAux(const char* label, Box min, Box max, Box x)
#     Box CboxVGroup(const char* label, Box group)
#     Box CboxHGroup(const char* label, Box group)
#     Box CboxTGroup(const char* label, Box group)
#     Box CboxAttach()
#     Box CboxAttachAux(Box b1, Box b2)

#     bint CisBoxAbstr(Box t, Box* x, Box* y)
#     bint CisBoxAccess(Box t, Box* exp, Box* id)
#     bint CisBoxAppl(Box t, Box* x, Box* y)
#     bint CisBoxButton(Box b, Box* lbl)
#     bint CisBoxCase(Box b, Box* rules)
#     bint CisBoxCheckbox(Box b, Box* lbl)
#     bint CisBoxComponent(Box b, Box* filename)
#     bint CisBoxCut(Box t)
#     bint CisBoxEnvironment(Box b)
#     bint CisBoxError(Box t)
#     bint CisBoxFConst(Box b, Box* type, Box* name, Box* file)
#     bint CisBoxFFun(Box b, Box* ff)
#     bint CisBoxFVar(Box b, Box* type, Box* name, Box* file)
#     bint CisBoxHBargraph(Box b, Box* lbl, Box* min, Box* max)
#     bint CisBoxHGroup(Box b, Box* lbl, Box* x)
#     bint CisBoxHSlider(Box b, Box* lbl, Box* cur, Box* min, Box* max, Box* step)
#     bint CisBoxIdent(Box t, const char** str)
#     bint CisBoxInputs(Box t, Box* x)
#     bint CisBoxInt(Box t, int* i)
#     bint CisBoxIPar(Box t, Box* x, Box* y, Box* z)
#     bint CisBoxIProd(Box t, Box* x, Box* y, Box* z)
#     bint CisBoxISeq(Box t, Box* x, Box* y, Box* z)
#     bint CisBoxISum(Box t, Box* x, Box* y, Box* z)
#     bint CisBoxLibrary(Box b, Box* filename)
#     bint CisBoxMerge(Box t, Box* x, Box* y)
#     bint CisBoxMetadata(Box b, Box* exp, Box* mdlist)
#     bint CisBoxNumEntry(Box b, Box* lbl, Box* cur, Box* min, Box* max, Box* step)
#     bint CisBoxOutputs(Box t, Box* x)
#     bint CisBoxPar(Box t, Box* x, Box* y)
#     bint CisBoxPatternMatcher(Box b)
#     bint CisBoxPatternVar(Box b, Box* id)
#     bint CisBoxPrim0(Box b)
#     bint CisBoxPrim1(Box b)
#     bint CisBoxPrim2(Box b)
#     bint CisBoxPrim3(Box b)
#     bint CisBoxPrim4(Box b)
#     bint CisBoxPrim5(Box b)
#     bint CisBoxReal(Box t, double* r)
#     bint CisBoxRec(Box t, Box* x, Box* y)
#     bint CisBoxRoute(Box b, Box* n, Box* m, Box* r)
#     bint CisBoxSeq(Box t, Box* x, Box* y)
#     bint CisBoxSlot(Box t, int* id)
#     bint CisBoxSoundfile(Box b, Box* label, Box* chan)
#     bint CisBoxSplit(Box t, Box* x, Box* y)
#     bint CisBoxSymbolic(Box t, Box* slot, Box* body)
#     bint CisBoxTGroup(Box b, Box* lbl, Box* x)
#     bint CisBoxVBargraph(Box b, Box* lbl, Box* min, Box* max)
#     bint CisBoxVGroup(Box b, Box* lbl, Box* x)
#     bint CisBoxVSlider(Box b, Box* lbl, Box* cur, Box* min, Box* max, Box* step)
#     bint CisBoxWaveform(Box b)
#     bint CisBoxWire(Box t)
#     bint CisBoxWithLocalDef(Box t, Box* body, Box* ldef)

#     Box CDSPToBoxes(const char* name_appp, const char* dsp_content, int argc, const char* argv[], int* inputs, int* outputs, char* error_msg)
#     bint CgetBoxType(Box box, int* inputs, int* outputs)
#     Signal* CboxesToSignals(Box box, char* error_msg)
#     char* CcreateSourceFromBoxes(const char* name_app, Box box, const char* lang, int argc, const char* argv[],  char* error_msg)
#     void freeCMemory(void* ptr)



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

cdef extern from "rtaudio/rtaudio_c.h":

    ctypedef unsigned long rtaudio_format_t

    cdef unsigned long RTAUDIO_FORMAT_SINT8 = 0x01
    cdef unsigned long RTAUDIO_FORMAT_SINT16 = 0x02
    cdef unsigned long RTAUDIO_FORMAT_SINT24 = 0x04
    cdef unsigned long RTAUDIO_FORMAT_SINT32 = 0x08
    cdef unsigned long RTAUDIO_FORMAT_FLOAT32 = 0x10
    cdef unsigned long RTAUDIO_FORMAT_FLOAT64 = 0x20

    ctypedef unsigned int rtaudio_stream_flags_t

    cdef unsigned int RTAUDIO_FLAGS_NONINTERLEAVED = 0x1
    cdef unsigned int RTAUDIO_FLAGS_MINIMIZE_LATENCY = 0x2
    cdef unsigned int RTAUDIO_FLAGS_HOG_DEVICE = 0x4
    cdef unsigned int RTAUDIO_FLAGS_SCHEDULE_REALTIME = 0x8
    cdef unsigned int RTAUDIO_FLAGS_ALSA_USE_DEFAULT = 0x10
    cdef unsigned int RTAUDIO_FLAGS_JACK_DONT_CONNECT = 0x20


    ctypedef unsigned int rtaudio_stream_status_t

    cdef unsigned int RTAUDIO_STATUS_INPUT_OVERFLOW = 0x1
    cdef unsigned int RTAUDIO_STATUS_OUTPUT_UNDERFLOW = 0x2


    ctypedef int (*rtaudio_cb_t)(
        void *out, 
        void *in_,
        unsigned int nFrames,
        double stream_time,
        rtaudio_stream_status_t status,
        void *userdata
    )


    ctypedef enum rtaudio_error:
        RTAUDIO_ERROR_NONE = 0
        RTAUDIO_ERROR_WARNING
        RTAUDIO_ERROR_UNKNOWN          
        RTAUDIO_ERROR_NO_DEVICES_FOUND 
        RTAUDIO_ERROR_INVALID_DEVICE   
        RTAUDIO_ERROR_DEVICE_DISCONNECT
        RTAUDIO_ERROR_MEMORY_ERROR     
        RTAUDIO_ERROR_INVALID_PARAMETER
        RTAUDIO_ERROR_INVALID_USE      
        RTAUDIO_ERROR_DRIVER_ERROR     
        RTAUDIO_ERROR_SYSTEM_ERROR     
        RTAUDIO_ERROR_THREAD_ERROR     

    ctypedef int rtaudio_error_t


    ctypedef void (*rtaudio_error_cb_t)(rtaudio_error_t err, const char *msg)

    ctypedef enum rtaudio_api:
        RTAUDIO_API_UNSPECIFIED
        RTAUDIO_API_MACOSX_CORE
        RTAUDIO_API_LINUX_ALSA
        RTAUDIO_API_UNIX_JACK
        RTAUDIO_API_LINUX_PULSE
        RTAUDIO_API_LINUX_OSS
        RTAUDIO_API_WINDOWS_ASIO
        RTAUDIO_API_WINDOWS_WASAPI
        RTAUDIO_API_WINDOWS_DS 
        RTAUDIO_API_DUMMY
        RTAUDIO_API_NUM          

    ctypedef int rtaudio_api_t

    cdef int NUM_SAMPLE_RATES = 16
    cdef int MAX_NAME_LENGTH = 512

    ctypedef struct rtaudio_device_info_t:
        unsigned int id
        unsigned int output_channels
        unsigned int input_channels
        unsigned int duplex_channels

        int is_default_output
        int is_default_input

        rtaudio_format_t native_formats

        unsigned int preferred_sample_rate
        unsigned int sample_rates[16]

        char name[512]

    ctypedef struct rtaudio_stream_parameters_t:
        unsigned int device_id
        unsigned int num_channels
        unsigned int first_channel


    ctypedef struct rtaudio_stream_options_t:
        rtaudio_stream_flags_t flags
        unsigned int num_buffers
        int priority
        char name[512]

    ctypedef struct rtaudio_t

    const char *rtaudio_version()

    unsigned int rtaudio_get_num_compiled_apis()
    const rtaudio_api_t *rtaudio_compiled_api()
    const char *rtaudio_api_name(rtaudio_api_t api_)
    const char *rtaudio_api_display_name(rtaudio_api_t api_)
    rtaudio_api_t rtaudio_compiled_api_by_name(const char *name)
    const char *rtaudio_error_fn "rtaudio_error" (rtaudio_t audio)
    rtaudio_error_t rtaudio_error_type(rtaudio_t audio)
    rtaudio_t rtaudio_create(rtaudio_api_t api_)
    void rtaudio_destroy(rtaudio_t audio)
    rtaudio_api_t rtaudio_current_api(rtaudio_t audio)
    int rtaudio_device_count(rtaudio_t audio)
    unsigned int rtaudio_get_device_id(rtaudio_t audio, int i)
    rtaudio_device_info_t rtaudio_get_device_info( rtaudio_t audio, unsigned int id)
    unsigned int rtaudio_get_default_output_device(rtaudio_t audio)
    unsigned int rtaudio_get_default_input_device(rtaudio_t audio)

    rtaudio_error_t rtaudio_open_stream(
        rtaudio_t audio, rtaudio_stream_parameters_t *output_params,
        rtaudio_stream_parameters_t *input_params,
        rtaudio_format_t format, unsigned int sample_rate,
        unsigned int *buffer_frames, rtaudio_cb_t cb,
        void *userdata, rtaudio_stream_options_t *options,
        rtaudio_error_cb_t errcb)

    void rtaudio_close_stream(rtaudio_t audio)
    rtaudio_error_t rtaudio_start_stream(rtaudio_t audio)
    rtaudio_error_t rtaudio_stop_stream(rtaudio_t audio)
    rtaudio_error_t rtaudio_abort_stream(rtaudio_t audio)
    int rtaudio_is_stream_open(rtaudio_t audio)
    int rtaudio_is_stream_running(rtaudio_t audio)
    double rtaudio_get_stream_time(rtaudio_t audio)
    void rtaudio_set_stream_time(rtaudio_t audio, double time)
    long rtaudio_get_stream_latency(rtaudio_t audio)
    unsigned int rtaudio_get_stream_sample_rate(rtaudio_t audio)
    void rtaudio_show_warnings(rtaudio_t audio, int show)

