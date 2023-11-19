# distutils: language = c++

from libc.stdlib cimport malloc, free

cimport faust_interp as fi

## ---------------------------------------------------------------------------
## python c-api functions
##

cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)



## ---------------------------------------------------------------------------
## type aliases 
##

ctypedef fi.interpreter_dsp_factory dsp_factory


## ---------------------------------------------------------------------------
## utility functions
##

def get_version():
    """Get the version of the library.

    returns the library version as a static string.
    """
    return fi.getCLibFaustVersion().decode()

## ---------------------------------------------------------------------------
## interpreter_dsp_factory functions
##

# ctypedef struct ParamArray:
#     const char ** argv
#     int argc

# cdef ParamArray* paramarray_from_list(list plist):
#     cdef ParamArray* params = <ParamArray*>malloc(sizeof(ParamArray))
#     params.argc = len(plist)
#     params.argv = <const char **>malloc(params.argc * sizeof(char *))
#     for i in range(params.argc):
#         params.argv[i] = PyUnicode_AsUTF8(plist[i])
#     return params

# cdef free_paramarray(ParamArray* params):
#     if params.argv:
#         free(params.argv)
#     free(params)


cdef class ParamArray:
    cdef const char ** argv
    cdef int argc

    def __cinit__(self, list plist):
        self.argc = len(plist)
        self.argv = <const char **>malloc(self.argc * sizeof(char *))
        for i in range(self.argc):
            self.argv[i] = PyUnicode_AsUTF8(plist[i])

    def __dealloc__(self):
        if self.argv:
            free(self.argv)


cdef class InterpreterDspFactory:
    cdef fi.interpreter_dsp_factory* ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            delete_interpreter_dsp_factory(self.ptr)

    @staticmethod
    def from_sha(str sha_key) -> InterpreterDspFactory:
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        factory.ptr_owner = True
        factory.ptr = <dsp_factory*>get_interpreter_dsp_factory_from_sha_key(sha_key)
        return factory

    @staticmethod
    def from_file(str filepath, str args) -> InterpreterDspFactory:
        cdef char error_msg[4096]
        error_msg[0] = 0
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        cdef ParamArray params = ParamArray(args)
        # cdef ParamArray *params = paramarray_from_list(args)
        factory.ptr_owner = True
        factory.ptr = <dsp_factory*>create_interpreter_dsp_factory_from_file(
            filepath.encode('utf8'),
            params.argc,
            params.argv,
            error_msg,
        )
        if error_msg[0] != 0:
            print(error_msg.decode())
            return
        return factory

    @staticmethod
    def from_string(str name_app, str code, str args) -> InterpreterDspFactory:
        cdef char error_msg[4096]
        error_msg[0] = 0
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        cdef ParamArray params = ParamArray(args)
        # cdef ParamArray *params = paramarray_from_list(args)
        factory.ptr_owner = True
        factory.ptr = <dsp_factory*>create_interpreter_dsp_factory_from_string(
            name_app.encode('utf8'),
            code.encode('utf8'),
            params.argc,
            params.argv,
            error_msg,
        )
        if error_msg[0] != 0:
            print(error_msg.decode())
            return
        return factory



cdef dsp_factory* get_interpreter_dsp_factory_from_sha_key(str sha_key):
    """Get the Faust DSP factory associated with a given SHA key if already allocated
    in the factories cache and increment its reference counter.
    
    You will have to explicitly to use deleteInterpreterDSPFactory to properly 
    decrement reference counter when the factory is not needed.
     
    sha_key - the SHA key for an already created factory, kept in the factory cache

    returns a valid DSP factory if one is associated with the SHA key,
    otherwise a null pointer.
    """
    return fi.getCInterpreterDSPFactoryFromSHAKey(sha_key.encode('utf8'))

cdef dsp_factory* create_interpreter_dsp_factory_from_file(
        const char* filename, int argc, const char* argv[], char* error_msg):
    """Create a Faust DSP factory from a DSP source code as a file. 

    Note that the library keeps an internal cache of all allocated factories so that
    the compilation of same DSP code (that is same source code and same set of 'normalized'
    compilations options) will return the same (reference counted) factory pointer.

    You will have to explicitly use deleteInterpreterDSPFactory to properly decrement
    reference counter when the factory is no more needed.

    filename - the DSP filename
    argc - the number of parameters in argv array
    argv - the array of parameters
    error_msg - the error string to be filled, has to be 4096 characters long

    returns a DSP factory on success, otherwise a null pointer.
    """
    return fi.createCInterpreterDSPFactoryFromFile(
        filename, argc, argv, error_msg)

cdef dsp_factory* create_interpreter_dsp_factory_from_string(
        const char* name_app, const char* dsp_content, int argc, const char* argv[], char* error_msg):
    """Create a Faust DSP factory from a DSP source code as a string. 

    Note that the library keeps an internal cache of all allocated factories so 
    that the compilation of same DSP code (that is same source code and
    same set of 'normalized' compilations options) will return the same 
    (reference counted) factory pointer. You will have to explicitly
    use deleteInterpreterDSPFactory to properly decrement reference counter 
    when the factory is no more needed.

    name_app - the name of the Faust program
    dsp_content - the Faust program as a string
    argc - the number of parameters in argv array
    argv - the array of parameters
    error_msg - the error string to be filled, has to be 4096 characters long

    returns a DSP factory on success, otherwise a null pointer.
    """
    return fi.createCInterpreterDSPFactoryFromString(
        name_app, dsp_content, argc, argv, error_msg)

cdef dsp_factory* create_interpreter_dsp_ractory_from_signals(
        const char* name_app, fi.Signal* signals, int argc, const char* argv[],
        char* error_msg):
    """Create a Faust DSP factory from a vector of output signals.
     
    It has to be used with the signal API defined in libfaust-signal-c.h.

    name_app - the name of the Faust program
    signals - the vector of output signals (that will internally be converted
              in normal form, see CsimplifyToNormalForm in libfaust-signal-c.h)
    argc - the number of parameters in argv array
    argv - the array of parameters
    error_msg - the error string to be filled, has to be 4096 characters long

    returns a DSP factory on success, otherwise a null pointer.
    """
    return fi.createCInterpreterDSPFactoryFromSignals(
        name_app, signals, argc, argv, error_msg)

cdef dsp_factory* create_interpreter_dsp_factory_from_boxes(
        const char* name_app, fi.Box box, int argc, const char* argv[], char* error_msg):
    """Create a Faust DSP factory from a box expression.
      
     It has to be used with the box API defined in libfaust-box-c.h.
     
    name_app - the name of the Faust program
    box - the box expression
    argc - the number of parameters in argv array
    argv - the array of parameters
    error_msg - the error string to be filled, has to be 4096 characters long

    returns a DSP factory on success, otherwise a null pointer.
    """
    return fi.createCInterpreterDSPFactoryFromBoxes(
        name_app, box, argc, argv, error_msg)

cdef bint delete_interpreter_dsp_factory(dsp_factory* factory):
    """Delete a Faust DSP factory, that is decrements it's reference counter, possibly really deleting the internal pointer.

    Possibly also delete DSP pointers associated with this factory, if they were not explicitly deleted.
    Beware: all kept factories and DSP pointers (in local variables...) thus become invalid.

    factory - the DSP factory

    returns true if the factory internal pointer was really deleted, and false if only 'decremented'.
    """
    return fi.deleteCInterpreterDSPFactory(factory)


cdef const char** get_interpreter_dsp_factory_library_list(dsp_factory* factory):
    """Get the list of library dependancies of the Faust DSP factory.
     
    deprecated : use factory getInterpreterDSPFactoryLibraryList method.

    factory - the DSP factory

    returns the library dependancies (the array and it's content has to be deleted by the caller using freeCMemory).
    """
    return fi.getCInterpreterDSPFactoryLibraryList(factory)


cdef void delete_all_interpreter_dsp_factories():
    """Delete all Faust DSP factories kept in the library cache. 

    Beware: all kept factory and DSP pointers (in local variables...) thus become invalid.
    """
    fi.deleteAllCInterpreterDSPFactories()


cdef const char** get_all_interpreter_dsp_factories():
    """Return Faust DSP factories of the library cache as a vector of their SHA keys.
     
    The array and it's content has to be deleted by the caller using freeCMemory.
    """
    return fi.getAllCInterpreterDSPFactories()


cdef bint start_multithreaded_access_mode():
    """Start multi-thread access mode (since by default the library is not 'multi-thread' safe).

    returns true if 'multi-thread' safe access is started.
    """
    return fi.startMTDSPFactories()

cdef void stop_multithreaded_access_mode():
    """Stop multi-thread access mode."""
    fi.stopMTDSPFactories()


cdef dsp_factory* read_interpreter_dsp_factory_from_bitcode(const char* bitcode, char* error_msg):
    """Create a Faust DSP factory from a bitcode string.

    Note that the library keeps an internal cache of all allocated factories so 
    that the compilation of the same DSP code (that is the same bitcode code string)
    will return the same (reference counted) factory pointer. You will have to explicitly
    use deleteInterpreterDSPFactory to properly decrement reference counter when
    the factory is no more needed.
    
    bitcode - the bitcode string
    error_msg - the error string to be filled, has to be 4096 characters long
    
    returns the DSP factory on success, otherwise a null pointer.
    """
    return fi.readCInterpreterDSPFactoryFromBitcode(bitcode, error_msg)

    
cdef char* write_interpreter_dsp_factory_to_bitcode(dsp_factory* factory):
    """Write a Faust DSP factory into a bitcode string.
    
    factory - the DSP factory
    
    returns the bitcode as a string (to be deleted by the caller using freeCMemory).
    """
    return fi.writeCInterpreterDSPFactoryToBitcode(factory)

cdef fi.interpreter_dsp_factory* read_interpreter_dsp_factory_from_bitcode_file(const char* bit_code_path, char* error_msg):
    """Create a Faust DSP factory from a bitcode file.

    Note that the library keeps an internal cache of all
    allocated factories so that the compilation of the same DSP code (that is the same Bitcode file) will return
    the same (reference counted) factory pointer. You will have to explicitly use deleteInterpreterDSPFactory to properly
    decrement reference counter when the factory is no more needed.

    bit_code_path - the bitcode file pathname
    error_msg - the error string to be filled, has to be 4096 characters long

    returns the DSP factory on success, otherwise a null pointer.
    """
    return fi.readCInterpreterDSPFactoryFromBitcodeFile(bit_code_path, error_msg)

cdef bint write_interpreter_dsp_factory_to_bitcode_file(dsp_factory* factory, const char* bit_code_path):
    """Write a Faust DSP factory into a bitcode file.

    factory - the DSP factory
    bit_code_path - the bitcode file pathname

    returns true if success, false otherwise.
    """
    return fi.writeCInterpreterDSPFactoryToBitcodeFile(factory, bit_code_path)

## ---------------------------------------------------------------------------
## instance functions.
##

cdef int get_numinputs_interpreter_dsp_instance(fi.interpreter_dsp* dsp):
    return fi.getNumInputsCInterpreterDSPInstance(dsp)

cdef int get_numoutputs_interpreter_dsp_instance(fi.interpreter_dsp* dsp):
    return fi.getNumOutputsCInterpreterDSPInstance(dsp)

cdef void build_userinterface_interpreter_dsp_instance(fi.interpreter_dsp* dsp, fi.UIGlue* interface):
    fi.buildUserInterfaceCInterpreterDSPInstance(dsp, interface)
    
cdef int get_samplerate_interpreter_dsp_instance(fi.interpreter_dsp* dsp):
    return fi.getSampleRateCInterpreterDSPInstance(dsp)
    
cdef void init_interpreter_dsp_instance(fi.interpreter_dsp* dsp, int sample_rate):
    fi.initCInterpreterDSPInstance(dsp, sample_rate)
    
cdef void intance_init_interpreter_dsp_instance(fi.interpreter_dsp* dsp, int sample_rate):
    fi.instanceInitCInterpreterDSPInstance(dsp, sample_rate)
    
cdef void instance_constants_interpreter_dsp_instance(fi.interpreter_dsp* dsp, int sample_rate):
    fi.instanceConstantsCInterpreterDSPInstance(dsp, sample_rate)
    
cdef void instance_reset_userinterface_interpreter_dsp_instance(fi.interpreter_dsp* dsp):
    fi.instanceResetUserInterfaceCInterpreterDSPInstance(dsp)
    
cdef void instance_clear_interpreter_dsp_instance(fi.interpreter_dsp* dsp):
    fi.instanceClearCInterpreterDSPInstance(dsp)
    
cdef fi.interpreter_dsp* clone_interpreter_dsp_instance(fi.interpreter_dsp* dsp):
    return fi.cloneCInterpreterDSPInstance(dsp)
    
cdef void metadata_interpreter_dsp_instance(fi.interpreter_dsp* dsp, fi.MetaGlue* meta):
    fi.metadataCInterpreterDSPInstance(dsp, meta)
    
cdef void compute_interpreter_dsp_instance(fi.interpreter_dsp* dsp, int count, float** input, float** output):
    fi.computeCInterpreterDSPInstance(dsp, count, input, output)

cdef fi.interpreter_dsp* create_interpreter_dsp_instance(dsp_factory* factory):
    fi.createCInterpreterDSPInstance(factory)

cdef void delete_interpreter_dsp_instance(fi.interpreter_dsp* dsp):
    fi.deleteCInterpreterDSPInstance(dsp)


## ---------------------------------------------------------------------------
## Extension Classes
##




cdef class InterpreterDsp:
    cdef fi.interpreter_dsp* ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False

    def __dealloc__(self):
        if self.ptr is not NULL and self.ptr_owner is True:
            delete_interpreter_dsp_instance(self.ptr)

    @staticmethod
    cdef InterpreterDsp from_factory(fi.interpreter_dsp_factory* factory):
        cdef InterpreterDsp dsp = InterpreterDsp.__new__(InterpreterDsp)
        dsp.ptr_owner = True
        dsp.ptr = <fi.interpreter_dsp*>create_interpreter_dsp_instance(factory)
        return dsp

    def get_numinputs(self) -> int:
        return get_numinputs_interpreter_dsp_instance(self.ptr)

    def get_numoutputs(self) -> int:
        return get_numoutputs_interpreter_dsp_instance(self.ptr)

    def get_samplerate(self) -> int:
        return get_samplerate_interpreter_dsp_instance(self.ptr)

    def init(self, int sample_rate):
        intance_init_interpreter_dsp_instance(self.ptr, sample_rate)

    def constants(self, int sample_rate):
        instance_constants_interpreter_dsp_instance(self.ptr, sample_rate)

    def reset(self):
        instance_reset_userinterface_interpreter_dsp_instance(self.ptr)

    def clear(self):
        instance_clear_interpreter_dsp_instance(self.ptr)

    cdef fi.interpreter_dsp* clone(self):
        return clone_interpreter_dsp_instance(self.ptr)

## ---------------------------------------------------------------------------
## interpreter tests
##

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
    assert factory is not NULL


## ---------------------------------------------------------------------------
## signal api
##

cdef char* print_box(fi.Box box, bint shared, int max_size):
    """Print the box."""
    return fi.CprintBox(box, shared, max_size)

cdef char* print_signal(fi.Signal sig, bint shared, int max_size):
    """Print the signal."""
    return fi.CprintSignal(sig, shared, max_size)

cdef void create_lib_context():
    """Create global compilation context, has to be done first."""
    fi.createLibContext()

cdef void destroy_lib_context():
    """Destroy global compilation context, has to be done last."""
    fi.destroyLibContext()

cdef bint is_nil(fi.Signal s):
    """Check if a signal is nil."""
    return fi.CisNil(s)

cdef const char* tree2str(fi.Signal s):
    """Convert a signal (such as the label of a UI) to a string."""
    return fi.Ctree2str(s)

cdef void* get_user_data(fi.Signal s):
    """Return the xtended type of a signal."""
    return fi.CgetUserData(s)

cdef fi.Signal sig_int(int n):
    """Constant integer : for all t, x(t) = n"""
    return fi.CsigInt(n)

cdef fi.Signal sig_real(double n):
    """Constant real : for all t, x(t) = n"""
    return fi.CsigReal(n)

cdef fi.Signal sig_input(int idx):
    """Create an input."""
    return fi.CsigInput(idx)

cdef fi.Signal sig_delay(fi.Signal s, fi.Signal delay):
    """Create a delayed signal."""
    return fi.CsigDelay(s, delay)

cdef fi.Signal sig_delay1(fi.Signal s):
    """Create a one sample delayed signal."""
    return fi.CsigDelay1(s)

cdef fi.Signal sig_int_cast(fi.Signal s):
    """Create a casted signal."""
    return fi.CsigIntCast(s)

cdef fi.Signal sig_float_cast(fi.Signal s):
    """Create a casted signal."""
    return fi.CsigFloatCast(s)

cdef fi.Signal sig_readonly_table(fi.Signal n, fi.Signal init, fi.Signal ridx):
    """Create a read only table."""
    return fi.CsigReadOnlyTable(n, init, ridx)

cdef fi.Signal sig_writeread_Table(fi.Signal n, fi.Signal init, fi.Signal widx, fi.Signal wsig, fi.Signal ridx):
    """Create a read/write table."""
    return fi.CsigWriteReadTable(n, init, widx, wsig, ridx)

cdef fi.Signal sig_waveform(fi.Signal* wf):
    """Create a waveform."""
    return fi.CsigWaveform(wf)

cdef fi.Signal sig_soundfile(const char* label):
    """Create a soundfile block."""
    return fi.CsigSoundfile(label)

# ----------------------------------------------------------------------------

cdef fi.Signal sig_soundfile_length(fi.Signal sf, fi.Signal part):
    """Create the length signal of a given soundfile in frames."""
    return fi.CsigSoundfileLength(sf, part)

cdef fi.Signal sig_soundfile_rate(fi.Signal sf, fi.Signal part):
    """Create the rate signal of a given soundfile in Hz."""
    return fi.CsigSoundfileRate(sf, part)

cdef fi.Signal sig_soundfile_buffer(fi.Signal sf, fi.Signal chan, fi.Signal part, fi.Signal ridx):
    """Create the buffer signal of a given soundfile."""
    return fi.CsigSoundfileBuffer(sf, chan, part, ridx)

cdef fi.Signal sig_select2(fi.Signal selector, fi.Signal s1, fi.Signal s2):
    """Create a selector between two signals."""
    return fi.CsigSelect2(selector, s1, s2)

cdef fi.Signal sig_select3(fi.Signal selector, fi.Signal s1, fi.Signal s2, fi.Signal s3):
    """Create a selector between three signals."""
    return fi.CsigSelect3(selector, s1, s2, s3)

# cdef fi.Signal sig_f_const(enum SType type, const char* name, const char* file):
#     """Create a foreign constant signal."""
#     return fi.CsigFConst(type, name, file)

# cdef fi.Signal sig_f_var(enum SType type, const char* name, const char* file):
#     """Create a foreign variable signal."""
#     return fi.CsigFVar(type, name, file)

# cdef fi.Signal sig_bin_op(enum SOperator op, fi.Signal x, fi.Signal y):
#     """Generic binary mathematical functions."""
#     return fi.CsigBinOp(op, x, y)

cdef fi.Signal sig_add(fi.Signal x, fi.Signal y):
    """Specific binary mathematical functions."""
    return fi.CsigAdd(x, y)

cdef fi.Signal sig_sub(fi.Signal x, fi.Signal y):
    """Specific binary mathematical functions."""
    return fi.CsigSub(x, y)

cdef fi.Signal sig_mul(fi.Signal x, fi.Signal y):
    """Specific binary mathematical functions."""
    return fi.CsigMul(x, y)

cdef fi.Signal sig_div(fi.Signal x, fi.Signal y):
    """Specific binary mathematical functions."""
    return fi.CsigDiv(x, y)

cdef fi.Signal sig_rem(fi.Signal x, fi.Signal y):
    """Specific binary mathematical functions."""
    return fi.CsigRem(x, y)

cdef fi.Signal sig_abs(fi.Signal x):
    """Extended unary mathematical functions."""
    return fi.CsigAbs(x)

cdef fi.Signal sig_remainder(fi.Signal x, fi.Signal y):
    """Extended binary mathematical functions."""
    return fi.CsigRemainder(x, y)


cdef fi.Signal sig_recursion(fi.Signal s):
    """Create a recursive signal. Use CsigSelf() to refer to the"""
    return fi.CsigRecursion(s)

cdef fi.Signal sig_self_n(int id):
    """Create a recursive signal inside the CsigRecursionN expression."""
    return fi.CsigSelfN(id)

cdef fi.Signal* sig_recursion_n(fi.Signal* rf):
    """Create a recursive block of signals. Use CsigSelfN() to refer to the"""
    return fi.CsigRecursionN(rf)

cdef fi.Signal sig_button(const char* label):
    """Create a button signal."""
    return fi.CsigButton(label)

cdef fi.Signal sig_checkbox(const char* label):
    """Create a checkbox signal."""
    return fi.CsigCheckbox(label)

cdef fi.Signal sig_v_slider(const char* label, fi.Signal init, fi.Signal min, fi.Signal max, fi.Signal step):
    """Create a vertical slider signal."""
    return fi.CsigVSlider(label, init, min, max, step)

cdef fi.Signal sig_h_slider(const char* label, fi.Signal init, fi.Signal min, fi.Signal max, fi.Signal step):
    """Create an horizontal slider signal."""
    return fi.CsigHSlider(label, init, min, max, step)

cdef fi.Signal sig_num_entry(const char* label, fi.Signal init, fi.Signal min, fi.Signal max, fi.Signal step):
    """Create a num entry signal."""
    return fi.CsigNumEntry(label, init, min, max, step)

cdef fi.Signal sig_v_bargraph(const char* label, fi.Signal min, fi.Signal max, fi.Signal s):
    """Create a vertical bargraph signal."""
    return fi.CsigVBargraph(label, min, max, s)

cdef fi.Signal sig_h_bargraph(const char* label, fi.Signal min, fi.Signal max, fi.Signal s):
    """Create an horizontal bargraph signal."""
    return fi.CsigHBargraph(label, min, max, s)

cdef fi.Signal sig_attach(fi.Signal s1, fi.Signal s2):
    """Create an attach signal."""
    return fi.CsigAttach(s1, s2)

# cdef bint is_sig_int(fi.Signal t, int* i):
#     """Test each signal and fill additional signal specific parameters."""
#     return fi.CisSigInt(t, i)

# cdef fi.Signal simplify_to_normal_form(fi.Signal s):
#     """Simplify a signal to its normal form, where:"""
#     return fi.CsimplifyToNormalForm(s)

# cdef fi.Signal* simplify_to_normal_form2(fi.Signal* siglist):
#     """Simplify a null terminated array of signals to its normal form, where:"""
#     return fi.CsimplifyToNormalForm2(siglist)




