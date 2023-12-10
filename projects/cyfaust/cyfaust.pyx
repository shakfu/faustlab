# distutils: language = c++

from libc.stdlib cimport malloc, free
from libcpp.string cimport string
from libcpp.vector cimport vector

cimport faust_interp as fi
cimport faust_box as fb
cimport faust_signal as fs


## ---------------------------------------------------------------------------
## python c-api functions
##

cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)

## ---------------------------------------------------------------------------
## utility classes / functions
##

cdef class ParamArray:
    """wrapper classs around faust paramater array"""
    cdef const char ** argv
    cdef int argc

    def __cinit__(self, tuple ptuple):
        self.argc = len(ptuple)
        self.argv = <const char **>malloc(self.argc * sizeof(char *))
        for i in range(self.argc):
            self.argv[i] = PyUnicode_AsUTF8(ptuple[i])

    def dump(self):
        if self.argv:
            for i in range(self.argc):
                print(self.argv[i].decode())

    def __dealloc__(self):
        if self.argv:
            free(self.argv)


cdef class SignalVector:
    """wraps tvec: a std::vector<CTree*>"""
    cdef fs.tvec* ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr = new fs.tvec()
        self.ptr_owner = False

    cdef add(self, fs.Signal sig):
        self.ptr.push_back(sig)




## ---------------------------------------------------------------------------
## faust/dsp/libfaust

def generate_sha1(data: str) -> str:
    """Generate SHA1 key from a string."""
    return fi.generateSHA1(data.encode('utf8')).decode()

def expand_dsp_from_file(filename: str, *args) -> tuple(str, str):
    """Expand dsp in a file into a self-contained dsp string.
    
    Returns sha key for expanded dsp string and expanded dsp string
    """
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg, sha_key 
    error_msg.reserve(4096)
    sha_key.reserve(100) # sha1 is 40 chars
    cdef string result = fi.expandDSPFromFile(
        filename.encode('utf8'),
        params.argc,
        params.argv,
        sha_key,
        error_msg
    )
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return (sha_key.decode(), result.decode())

def expand_dsp_from_string(name_app: str, dsp_content: str, *args) -> str:
    """Expand dsp in a file into a self-contained dsp string."""
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg, sha_key 
    error_msg.reserve(4096)
    sha_key.reserve(100) # sha1 is 40 chars
    cdef string result = fi.expandDSPFromString(
        name_app.encode('utf8'),
        dsp_content.encode('utf8'),
        params.argc,
        params.argv,
        sha_key,
        error_msg
    )
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return (sha_key.decode(), result.decode())

def generate_auxfiles_from_file(filename: str, *args) -> str:
    """Generate additional files (other backends, SVG, XML, JSON...) from a file."""
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg
    error_msg.reserve(4096)
    result = fi.generateAuxFilesFromFile(
        filename.encode('utf8'),
        params.argc,
        params.argv,
        error_msg
    )
    if not error_msg.empty():
        print(error_msg.decode())
        return False
    return result

def generate_auxfiles_from_string(name_app: str, dsp_content: str, *args) -> str:
    """Generate additional files (other backends, SVG, XML, JSON...) from a string."""
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg
    error_msg.reserve(4096)
    result = fi.generateAuxFilesFromString(
        name_app.encode('utf8'),
        dsp_content.encode('utf8'),
        params.argc,
        params.argv,
        error_msg
    )
    if not error_msg.empty():
        print(error_msg.decode())
        return False
    return result

## ---------------------------------------------------------------------------
## faust/audio/rtaudio-dsp

cdef class RtAudioDriver:
    """faust audio driver using rtaudio cross-platform lib."""
    cdef fi.rtaudio *ptr
    cdef bint ptr_owner

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            del self.ptr
            self.ptr = NULL

    def __cinit__(self, int srate, int bsize):
        self.ptr = new fi.rtaudio(srate, bsize)
        self.ptr_owner = True

    def set_dsp(self, dsp: InterpreterDsp):
        self.ptr.setDsp(<fi.dsp*>dsp.ptr)

    def init(self, dsp: InterpreterDsp) -> bool:
        """initialize with dsp instance."""
        name = "RtAudioDriver".encode('utf8')
        if self.ptr.init(name, dsp.get_numinputs(), dsp.get_numoutputs()):
            self.set_dsp(dsp)
            return True
        return False

    def start(self):
        if not self.ptr.start():
            print("RtAudioDriver: could not start")

    def stop(self):
        self.ptr.stop()

    def get_buffersize(self):
        return self.ptr.getBufferSize()

    def get_samplerate(self):
        return self.ptr.getSampleRate()

    def get_numinputs(self):
        return self.ptr.getNumInputs()

    def get_numoutputs(self):
        return self.ptr.getNumOutputs()

## ---------------------------------------------------------------------------
## faust/dsp/interpreter-dsp


def get_version():
    """Get the version of the library.

    returns the library version as a static string.
    """
    return fi.getCLibFaustVersion().decode()


cdef class InterpreterDspFactory:
    """Interpreter DSP factory class."""

    cdef fi.interpreter_dsp_factory* ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            fi.deleteInterpreterDSPFactory(self.ptr)
            self.ptr = NULL

    def get_name(self) -> str:
        """Return factory name."""
        return self.ptr.getName().decode()

    def get_sha_key(self) -> str:
        """Return factory SHA key."""
        return self.ptr.getSHAKey().decode()
    
    def get_dsp_code(self) -> str:
        """Return factory expanded DSP code."""
        return self.ptr.getDSPCode().decode()
    
    def get_compile_options(self) -> str:
        """Return factory compile options."""
        return self.ptr.getCompileOptions().decode()
    
    def get_library_list(self) -> list[str]:
        """Get the Faust DSP factory list of library dependancies."""
        return self.ptr.getLibraryList()
    
    def get_include_pathnames(self) -> list[str]:
        """Get the list of all used includes."""
        return self.ptr.getIncludePathnames()
    
    def get_warning_messages(self) -> list[str]:
        """Get warning messages list for a given compilation."""
        return self.ptr.getWarningMessages()

    def create_dsp_instance(self) -> InterpreterDsp:
        """Create a new DSP instance, to be deleted with C++ 'delete'"""
        cdef fi.interpreter_dsp* dsp = self.ptr.createDSPInstance()
        return InterpreterDsp.from_ptr(dsp)

    cdef set_memory_manager(self, fi.dsp_memory_manager* manager):
        """Set a custom memory manager to be used when creating instances"""
        self.ptr.setMemoryManager(manager)

    cdef fi.dsp_memory_manager* get_memory_manager(self):
        """Set a custom memory manager to be used when creating instances"""
        return self.ptr.getMemoryManager()

    def write_to_bitcode(self) -> str:
        """Write a Faust DSP factory into a bitcode string."""
        return fi.writeInterpreterDSPFactoryToBitcode(self.ptr).decode()

    def write_to_bitcode_file(self, bit_code_path: str) -> bool:
        """Write a Faust DSP factory into a bitcode file."""
        return fi.writeInterpreterDSPFactoryToBitcodeFile(
            self.ptr, bit_code_path.encode('utf8'))

    @staticmethod
    cdef InterpreterDspFactory from_ptr(fi.interpreter_dsp_factory* ptr, bint owner=False):
        """Wrap external factory from pointer"""
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        factory.ptr = ptr
        factory.owner = owner
        return factory

    @staticmethod
    def from_sha_key(str sha_key) -> InterpreterDspFactory:
        """create an interpreter dsp factory from a sha key"""
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.getInterpreterDSPFactoryFromSHAKey(
            sha_key.encode())
        return factory

    @staticmethod
    def from_file(str filepath, *args) -> InterpreterDspFactory:
        """create an interpreter dsp factory from a file"""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        cdef ParamArray params = ParamArray(args)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.createInterpreterDSPFactoryFromFile(
            filepath.encode('utf8'),
            params.argc,
            params.argv,
            error_msg,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return
        return factory

    # @staticmethod
    # def from_signals(str name_app, fs.tvec signals, *args) -> InterpreterDspFactory:
    #     """Create a Faust DSP factory from a vector of output signals."""
    #     cdef string error_msg
    #     error_msg.reserve(4096)
    #     cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
    #         InterpreterDspFactory)
    #     cdef ParamArray params = ParamArray(args)
    #     factory.ptr_owner = True
    #     factory.ptr = <fi.interpreter_dsp_factory*>fi.createInterpreterDSPFactoryFromSignals(
    #         name_app.encode('utf8'),
    #         signals,
    #         params.argc,
    #         params.argv,
    #         error_msg,
    #     )
    #     if not error_msg.empty():
    #         print(error_msg.decode())
    #         return
    #     return factory

    @staticmethod
    def from_boxes(str name_app, Box box, *args) -> InterpreterDspFactory:
        """Create a Faust DSP factory from a box expression."""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        cdef ParamArray params = ParamArray(args)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.createInterpreterDSPFactoryFromBoxes(
            name_app.encode('utf8'),
            box.ptr,
            params.argc,
            params.argv,
            error_msg,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return
        return factory

    @staticmethod
    def from_bitcode_file(str bit_code_path) -> InterpreterDspFactory:
        """Create a Faust DSP factory from a bitcode file."""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.readInterpreterDSPFactoryFromBitcodeFile(
            bit_code_path.encode('utf8'),
            error_msg,
        )
        if error_msg.empty():
            print(error_msg.decode())
            return
        return factory

    @staticmethod
    def from_string(str name_app, str code, *args) -> InterpreterDspFactory:
        """create an interpreter dsp factory from a string"""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        cdef ParamArray params = ParamArray(args)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.createInterpreterDSPFactoryFromString(
            name_app.encode('utf8'),
            code.encode('utf8'),
            params.argc,
            params.argv,
            error_msg,
        )
        if error_msg.empty():
            print(error_msg.decode())
            return
        return factory

    @staticmethod
    def from_bitcode(str bitcode) -> InterpreterDspFactory:
        """Create a Faust DSP factory from a bitcode string."""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.readInterpreterDSPFactoryFromBitcode(
            bitcode.encode('utf8'),
            error_msg,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return
        return factory


cdef class InterpreterDsp:
    """DSP instance class with methods."""

    cdef fi.interpreter_dsp* ptr
    cdef bint ptr_owner

    # def __dealloc__(self):
    #     if self.ptr and self.ptr_owner:
    #         del self.ptr
    #         self.ptr = NULL

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False

    @staticmethod
    cdef InterpreterDsp from_ptr(fi.interpreter_dsp* ptr):
        """Wrap the dsp instance and manage its lifetime."""
        cdef InterpreterDsp dsp = InterpreterDsp.__new__(InterpreterDsp)
        dsp.ptr_owner = True
        dsp.ptr = ptr
        return dsp

    def get_numinputs(self) -> int:
        """Return instance number of audio inputs."""
        return self.ptr.getNumInputs()

    def get_numoutputs(self) -> int:
        """Return instance number of audio outputs."""
        return self.ptr.getNumOutputs()

    def get_samplerate(self) -> int:
        """Return the sample rate currently used by the instance."""
        return self.ptr.getSampleRate()

    def init(self, int sample_rate):
        """Global init, calls static class init and instance init."""
        self.ptr.init(sample_rate)

    def instance_init(self, int sample_rate):
        """Init instance state."""
        self.ptr.instanceInit(sample_rate)

    def instance_constants(self, int sample_rate):
        """Init instance constant state."""
        self.ptr.instanceConstants(sample_rate)

    def instance_reset_user_interface(self):
        """Init default control parameters values."""
        self.ptr.instanceResetUserInterface()

    def instance_clear(self):
        """Init instance state but keep the control parameter values."""
        self.ptr.instanceClear()

    def clone(self) -> InterpreterDsp:
        """Return a clone of the instance."""
        cdef fi.interpreter_dsp* dsp = self.ptr.clone()
        return InterpreterDsp.from_ptr(dsp)

    def build_user_interface(self):
        """Trigger the ui_interface parameter with instance specific calls."""
        cdef fi.PrintUI ui_interface
        self.ptr.buildUserInterface(<fi.UI*>&ui_interface)

    # cdef build_user_interface(self, fi.UI* ui_interface):
    #     """Trigger the ui_interface parameter with instance specific calls."""
    #     self.ptr.buildUserInterface(ui_interface)

    cdef metadata(self, fi.Meta* m):
        """Trigger the meta parameter with instance specific calls."""
        self.ptr.metadata(m)

def get_dsp_factory_from_sha_key(str sha_key) -> InterpreterDspFactory:
    """Get the Faust DSP factory associated with a given SHA key."""
    return InterpreterDspFactory.from_sha_key(sha_key.encode())

def create_dsp_factory_from_file(filename: str, *args) -> InterpreterDspFactory:
    """Create a Faust DSP factory from a DSP source code as a file."""
    return InterpreterDspFactory.from_file(filename, *args)

def create_dsp_factory_from_string(name_app: str, code: str, *args) -> InterpreterDspFactory:
    """Create a Faust DSP factory from a DSP source code as a string."""
    return InterpreterDspFactory.from_string(name_app, code, *args)

def delete_all_dsp_factories():
    """Delete all Faust DSP factories kept in the library cache."""
    fi.deleteAllInterpreterDSPFactories()

def get_all_dsp_factories():
    """Return Faust DSP factories of the library cache as a vector of their SHA keys."""
    return fi.getAllInterpreterDSPFactories()

def start_multithreaded_access_mode() -> bool:
    """Start multi-thread access mode."""
    return fi.startMTDSPFactories()

def stop_multithreaded_access_mode():
    """Stop multi-thread access mode."""
    fi.stopMTDSPFactories()

## to wrap -------------------------------------------------------------------

cdef fi.interpreter_dsp_factory* create_interpreter_dsp_factory_from_signals(
        const string& name_app, fi.tvec signals, int argc, const char* argv[], 
        string& error_msg):
    """Create a Faust DSP factory from a vector of output signals."""
    return fi.createInterpreterDSPFactoryFromSignals(
        name_app, signals, argc, argv, error_msg)

## ---------------------------------------------------------------------------
## faust/dsp/libfaust-signal

cdef const char* ffname(fs.Signal s):
    """Return the name parameter of a foreign function."""
    return fs.ffname(s)

cdef int ffarity(fs.Signal s):
    """Return the arity of a foreign function."""
    return fs.ffarity(s)

cdef string print_signal(fs.Signal sig, bint shared, int max_size):
    """Print a signal."""
    return fs.printSignal(sig, shared, max_size)

cdef fs.Signal sig_int(int n):
    return fs.sigInt(n)

cdef fs.Signal sig_real(double n):
    return fs.sigReal(n)

cdef fs.Signal sig_input(int idx):
    return fs.sigInput(idx)

cdef fs.Signal sig_delay(fs.Signal s, fs.Signal d):
    return fs.sigDelay(s, d)

# cdef fs.Signal sig_delay_(fs.Signal s):
#     return fs.sigDelay(s)

cdef fs.Signal sig_int_cast(fs.Signal s):
    return fs.sigIntCast(s)

cdef fs.Signal sig_float_cast(fs.Signal s):
    return fs.sigFloatCast(s)

cdef fs.Signal sig_read_only_table(fs.Signal n, fs.Signal init, fs.Signal ridx):
    return fs.sigReadOnlyTable(n, init, ridx)

cdef fs.Signal sig_write_read_table(fs.Signal n, fs.Signal init, fs.Signal widx, fs.Signal wsig, fs.Signal ridx):
    return fs.sigWriteReadTable(n, init, widx, wsig, ridx)

cdef fs.Signal sig_waveform(const fs.tvec& wf):
    return fs.sigWaveform(wf)

cdef fs.Signal sig_soundfile(const string& label):
    return fs.sigSoundfile(label)

cdef fs.Signal sig_soundfile_length(fs.Signal sf, fs.Signal part):
    return fs.sigSoundfileLength(sf, part)

cdef fs.Signal sig_soundfile_rate(fs.Signal sf, fs.Signal part):
    return fs.sigSoundfileRate(sf, part)

cdef fs.Signal sig_soundfile_buffer(fs.Signal sf, fs.Signal chan, fs.Signal part, fs.Signal ridx):
    return fs.sigSoundfileBuffer(sf, chan, part, ridx)

cdef fs.Signal sig_select2(fs.Signal selector, fs.Signal s1, fs.Signal s2):
    return fs.sigSelect2(selector, s1, s2)

cdef fs.Signal sig_select3(fs.Signal selector, fs.Signal s1, fs.Signal s2, fs.Signal s3):
    return fs.sigSelect3(selector, s1, s2, s3)

cdef fs.Signal sig_f_const(fs.SType type, const string& name, const string& file):
    return fs.sigFConst(type, name, file)

cdef fs.Signal sig_f_var(fs.SType type, const string& name, const string& file):
    return fs.sigFVar(type, name, file)

cdef fs.Signal sig_bin_op(fs.SOperator op, fs.Signal x, fs.Signal y):
    return fs.sigBinOp(op, x, y)

cdef fs.Signal sig_add(fs.Signal x, fs.Signal y):
    return fs.sigAdd(x, y)

cdef fs.Signal sig_sub(fs.Signal x, fs.Signal y):
    return fs.sigSub(x, y)

cdef fs.Signal sig_mul(fs.Signal x, fs.Signal y):
    return fs.sigMul(x, y)

cdef fs.Signal sig_div(fs.Signal x, fs.Signal y):
    return fs.sigDiv(x, y)

cdef fs.Signal sig_rem(fs.Signal x, fs.Signal y):
    return fs.sigRem(x, y)

cdef fs.Signal sig_left_shift(fs.Signal x, fs.Signal y):
    return fs.sigLeftShift(x, y)

cdef fs.Signal sig_l_right_shift(fs.Signal x, fs.Signal y):
    return fs.sigLRightShift(x, y)

cdef fs.Signal sig_gt(fs.Signal x, fs.Signal y):
    return fs.sigGT(x, y)

cdef fs.Signal sig_lt(fs.Signal x, fs.Signal y):
    return fs.sigLT(x, y)

cdef fs.Signal sig_ge(fs.Signal x, fs.Signal y):
    return fs.sigGE(x, y)

cdef fs.Signal sig_le(fs.Signal x, fs.Signal y):
    return fs.sigLE(x, y)

cdef fs.Signal sig_eq(fs.Signal x, fs.Signal y):
    return fs.sigEQ(x, y)

cdef fs.Signal sig_ne(fs.Signal x, fs.Signal y):
    return fs.sigNE(x, y)

cdef fs.Signal sig_and(fs.Signal x, fs.Signal y):
    return fs.sigAND(x, y)

cdef fs.Signal sig_or(fs.Signal x, fs.Signal y):
    return fs.sigOR(x, y)

cdef fs.Signal sig_xor(fs.Signal x, fs.Signal y):
    return fs.sigXOR(x, y)



cdef fs.Signal sig_abs(fs.Signal x):
    return fs.sigAbs(x)

cdef fs.Signal sig_acos(fs.Signal x):
    return fs.sigAcos(x)

cdef fs.Signal sig_tan(fs.Signal x):
    return fs.sigTan(x)

cdef fs.Signal sig_sqrt(fs.Signal x):
    return fs.sigSqrt(x)

cdef fs.Signal sig_sin(fs.Signal x):
    return fs.sigSin(x)

cdef fs.Signal sig_rint(fs.Signal x):
    return fs.sigRint(x)

cdef fs.Signal sig_log(fs.Signal x):
    return fs.sigLog(x)

cdef fs.Signal sig_log10(fs.Signal x):
    return fs.sigLog10(x)

cdef fs.Signal sig_floor(fs.Signal x):
    return fs.sigFloor(x)

cdef fs.Signal sig_exp(fs.Signal x):
    return fs.sigExp(x)

cdef fs.Signal sig_exp10(fs.Signal x):
    return fs.sigExp10(x)

cdef fs.Signal sig_cos(fs.Signal x):
    return fs.sigCos(x)

cdef fs.Signal sig_ceil(fs.Signal x):
    return fs.sigCeil(x)

cdef fs.Signal sig_atan(fs.Signal x):
    return fs.sigAtan(x)

cdef fs.Signal sig_asin(fs.Signal x):
    return fs.sigAsin(x)

cdef fs.Signal sig_remainder(fs.Signal x, fs.Signal y):
    return fs.sigRemainder(x, y)

cdef fs.Signal sig_pow(fs.Signal x, fs.Signal y):
    return fs.sigPow(x, y)

cdef fs.Signal sig_min(fs.Signal x, fs.Signal y):
    return fs.sigMin(x, y)

cdef fs.Signal sig_max(fs.Signal x, fs.Signal y):
    return fs.sigMax(x, y)

cdef fs.Signal sig_fmod(fs.Signal x, fs.Signal y):
    return fs.sigFmod(x, y)

cdef fs.Signal sig_atan2(fs.Signal x, fs.Signal y):
    return fs.sigAtan2(x, y)

cdef fs.Signal sig_recursion(fs.Signal s):
    return fs.sigRecursion(s)


cdef fs.Signal sig_self_n(int id):
    return fs.sigSelfN(id)

cdef fs.tvec sig_recursion_n(const fs.tvec& rf):
    return fs.sigRecursionN(rf)

cdef fs.Signal sig_button(const string& label):
    return fs.sigButton(label)

cdef fs.Signal sig_checkbox(const string& label):
    return fs.sigCheckbox(label)

cdef fs.Signal sig_v_slider(const string& label, fs.Signal init, fs.Signal min, fs.Signal max, fs.Signal step):
    return fs.sigVSlider(label, init, min, max, step)

cdef fs.Signal sig_h_slider(const string& label, fs.Signal init, fs.Signal min, fs.Signal max, fs.Signal step):
    return fs.sigHSlider(label, init, min, max, step)

cdef fs.Signal sig_num_entry(const string& label, fs.Signal init, fs.Signal min, fs.Signal max, fs.Signal step):
    return fs.sigNumEntry(label, init, min, max, step)

cdef fs.Signal sig_v_bargraph(const string& label, fs.Signal min, fs.Signal max, fs.Signal s):
    return fs.sigVBargraph(label, min, max, s)

cdef fs.Signal sig_h_bargraph(const string& label, fs.Signal min, fs.Signal max, fs.Signal s):
    return fs.sigHBargraph(label, min, max, s)

cdef fs.Signal sig_attach(fs.Signal s1, fs.Signal s2):
    return fs.sigAttach(s1, s2)

cdef bint is_sig_int(fs.Signal t, int* i):
    return fs.isSigInt(t, i)

cdef bint is_sig_real(fs.Signal t, double* r):
    return fs.isSigReal(t, r)

cdef bint is_sig_input(fs.Signal t, int* i):
    return fs.isSigInput(t, i)

cdef bint is_sig_output(fs.Signal t, int* i, fs.Signal& t0):
    return fs.isSigOutput(t, i, t0)

cdef bint is_sig_delay1(fs.Signal t, fs.Signal& t0):
    return fs.isSigDelay1(t, t0)

cdef bint is_sig_delay(fs.Signal t, fs.Signal& t0, fs.Signal& t1):
    return fs.isSigDelay(t, t0, t1)

cdef bint is_sig_prefix(fs.Signal t, fs.Signal& t0, fs.Signal& t1):
    return fs.isSigPrefix(t, t0, t1)

cdef bint is_sig_rd_tbl(fs.Signal s, fs.Signal& t, fs.Signal& i):
    return fs.isSigRDTbl(s, t, i)

cdef bint is_sig_wr_tbl(fs.Signal u, fs.Signal& id, fs.Signal& t, fs.Signal& i, fs.Signal& s):
    return fs.isSigWRTbl(u, id, t, i, s)

cdef bint is_sig_gen(fs.Signal t, fs.Signal& x):
    return fs.isSigGen(t, x)

cdef bint is_sig_doc_constant_tbl(fs.Signal t, fs.Signal& n, fs.Signal& sig):
    return fs.isSigDocConstantTbl(t, n, sig)

cdef bint is_sig_doc_write_tbl(fs.Signal t, fs.Signal& n, fs.Signal& sig, fs.Signal& widx, fs.Signal& wsig):
    return fs.isSigDocWriteTbl(t, n, sig, widx, wsig)

cdef bint is_sig_doc_access_tbl(fs.Signal t, fs.Signal& tbl, fs.Signal& ridx):
    return fs.isSigDocAccessTbl(t, tbl, ridx)

cdef bint is_sig_select2(fs.Signal t, fs.Signal& selector, fs.Signal& s1, fs.Signal& s2):
    return fs.isSigSelect2(t, selector, s1, s2)

cdef bint is_sig_assert_bounds(fs.Signal t, fs.Signal& s1, fs.Signal& s2, fs.Signal& s3):
    return fs.isSigAssertBounds(t, s1, s2, s3)

cdef bint is_sig_highest(fs.Signal t, fs.Signal& s):
    return fs.isSigHighest(t, s)

cdef bint is_sig_lowest(fs.Signal t, fs.Signal& s):
    return fs.isSigLowest(t, s)

cdef bint is_sig_bin_op(fs.Signal s, int* op, fs.Signal& x, fs.Signal& y):
    return fs.isSigBinOp(s, op, x, y)

cdef bint is_sig_f_fun(fs.Signal s, fs.Signal& ff, fs.Signal& largs):
    return fs.isSigFFun(s, ff, largs)

cdef bint is_sig_f_const(fs.Signal s, fs.Signal& type, fs.Signal& name, fs.Signal& file):
    return fs.isSigFConst(s, type, name, file)

cdef bint is_sig_f_var(fs.Signal s, fs.Signal& type, fs.Signal& name, fs.Signal& file):
    return fs.isSigFVar(s, type, name, file)

cdef bint is_proj(fs.Signal s, int* i, fs.Signal& rgroup):
    return fs.isProj(s, i, rgroup)

cdef bint is_rec(fs.Signal s, fs.Signal& var, fs.Signal& body):
    return fs.isRec(s, var, body)

cdef bint is_sig_int_cast(fs.Signal s, fs.Signal& x):
    return fs.isSigIntCast(s, x)

cdef bint is_sig_float_cast(fs.Signal s, fs.Signal& x):
    return fs.isSigFloatCast(s, x)

cdef bint is_sig_button(fs.Signal s, fs.Signal& lbl):
    return fs.isSigButton(s, lbl)

cdef bint is_sig_checkbox(fs.Signal s, fs.Signal& lbl):
    return fs.isSigCheckbox(s, lbl)

cdef bint is_sig_waveform(fs.Signal s):
    return fs.isSigWaveform(s)

cdef bint is_sig_h_slider(fs.Signal s, fs.Signal& lbl, fs.Signal& init, fs.Signal& min, fs.Signal& max, fs.Signal& step):
    return fs.isSigHSlider(s, lbl, init, min, max, step)

cdef bint is_sig_v_slider(fs.Signal s, fs.Signal& lbl, fs.Signal& init, fs.Signal& min, fs.Signal& max, fs.Signal& step):
    return fs.isSigVSlider(s, lbl, init, min, max, step)

cdef bint is_sig_num_entry(fs.Signal s, fs.Signal& lbl, fs.Signal& init, fs.Signal& min, fs.Signal& max, fs.Signal& step):
    return fs.isSigNumEntry(s, lbl, init, min, max, step)

cdef bint is_sig_h_bargraph(fs.Signal s, fs.Signal& lbl, fs.Signal& min, fs.Signal& max, fs.Signal& x):
    return fs.isSigHBargraph(s, lbl, min, max, x)

cdef bint is_sig_v_bargraph(fs.Signal s, fs.Signal& lbl, fs.Signal& min, fs.Signal& max, fs.Signal& x):
    return fs.isSigVBargraph(s, lbl, min, max, x)

cdef bint is_sig_attach(fs.Signal s, fs.Signal& s0, fs.Signal& s1):
    return fs.isSigAttach(s, s0, s1)

cdef bint is_sig_enable(fs.Signal s, fs.Signal& s0, fs.Signal& s1):
    return fs.isSigEnable(s, s0, s1)

cdef bint is_sig_control(fs.Signal s, fs.Signal& s0, fs.Signal& s1):
    return fs.isSigControl(s, s0, s1)

cdef bint is_sig_soundfile(fs.Signal s, fs.Signal& label):
    return fs.isSigSoundfile(s, label)

cdef bint is_sig_soundfile_length(fs.Signal s, fs.Signal& sf, fs.Signal& part):
    return fs.isSigSoundfileLength(s, sf, part)

cdef bint is_sig_soundfile_rate(fs.Signal s, fs.Signal& sf, fs.Signal& part):
    return fs.isSigSoundfileRate(s, sf, part)

cdef bint is_sig_soundfile_buffer(fs.Signal s, fs.Signal& sf, fs.Signal& chan, fs.Signal& part, fs.Signal& ridx):
    return fs.isSigSoundfileBuffer(s, sf, chan, part, ridx)

cdef fs.Signal simplify_to_normal_form(fs.Signal s):
    return fs.simplifyToNormalForm(s)

cdef fs.tvec simplify_to_normal_form2(fs.tvec siglist):
    return fs.simplifyToNormalForm2(siglist)

cdef string create_source_from_signals(const string& name_app, fs.tvec osigs, const string& lang, int argc, const char* argv[], string& error_msg):
    return fs.createSourceFromSignals(name_app, osigs, lang, argc, argv, error_msg)


## ---------------------------------------------------------------------------
## faust/dsp/libfaust-box

class box_context:
    def __enter__(self):
        fb.createLibContext()
    def __exit__(self, type, value, traceback):
        fb.destroyLibContext()


cdef class Box:
    """faust Box wrapper.
    """
    cdef fb.Box ptr

    def __cinit__(self):
        self.ptr = NULL

    @staticmethod
    cdef Box from_ptr(fb.Box ptr, bint ptr_owner=False):
        """Wrap external factory from pointer"""
        cdef Box box = Box.__new__(Box)
        box.ptr = ptr
        return box

    @staticmethod
    def from_int(int value) -> Box:
        """Create box from int"""
        cdef fb.Box b = fb.boxInt(value)
        return Box.from_ptr(b)

    @staticmethod
    def from_float(float value) -> Box:
        """Create box from float"""
        cdef fb.Box b = fb.boxReal(value)
        return Box.from_ptr(b)

    def create_source(self, name_app: str, lang, *args) -> str:
        """Create source code in a target language from a box expression."""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef ParamArray params = ParamArray(args)
        cdef string src = fb.createSourceFromBoxes(
            name_app,
            self.ptr,
            lang,
            params.argc,
            params.argv,
            error_msg)
        if error_msg.empty():
            print(error_msg.decode())
            return
        return src.decode()

    def print(self, shared: bool = False, max_size: int = 256):
        """Print this box."""
        print(fb.printBox(self.ptr, shared, max_size).decode())

    def __add__(self, Box other):
        """Add this box to another."""
        cdef fb.Box b = fb.boxAdd(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __radd__(self, Box other):
        """Reverse add this box to another."""
        cdef fb.Box b = fb.boxAdd(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __sub__(self, Box other):
        """Subtract this box from another."""
        cdef fb.Box b = fb.boxSub(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __rsub__(self, Box other):
        """Subtract this box from another."""
        cdef fb.Box b = fb.boxSub(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __mul__(self, Box other):
        """Multiply this box with another."""
        cdef fb.Box b = fb.boxMul(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __rmul__(self, Box other):
        """Reverse multiply this box with another."""
        cdef fb.Box b = fb.boxMul(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __div__(self, Box other):
        """Divide this box with another."""
        cdef fb.Box b = fb.boxDiv(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __rdiv__(self, Box other):
        """Reverse divide this box with another."""
        cdef fb.Box b = fb.boxDiv(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __eq__(self, Box other):
        """Compare for equality with another box."""
        cdef fb.Box b = fb.boxEQ(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __ne__(self, Box other):
        """Assert this box is not equal with another box."""
        cdef fb.Box b = fb.boxNE(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __gt__(self, Box other):
        """Is this box greater than another box."""
        cdef fb.Box b = fb.boxGT(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __ge__(self, Box other):
        """Is this box greater than or equal from another box."""
        cdef fb.Box b = fb.boxGE(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __lt__(self, Box other):
        """Is this box lesser than another box."""
        cdef fb.Box b = fb.boxLT(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __le__(self, Box other):
        """Is this box lesser than or equal from another box."""
        cdef fb.Box b = fb.boxLE(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __and__(self, Box other):
        """logical and with another box"""
        cdef fb.Box b = fb.boxAND(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __or__(self, Box other):
        """logical or with another box"""
        cdef fb.Box b = fb.boxOR(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __xor__(self, Box other):
        """logical xor with another box"""
        cdef fb.Box b = fb.boxXOR(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def to_string(self):
        """Convert this box tree (such as the label of a UI) to a string."""
        return fb.tree2str(self.ptr).decode()

    def to_int(self):
        """If this box tree has a node of type int, return it, otherwise error."""
        return fb.tree2int(self.ptr).decode()

    def abs(self) -> Box: 
        cdef fb.Box b = fb.boxAbs(self.ptr)
        return Box.from_ptr(b)

    def acos(self) -> Box: 
        cdef fb.Box b = fb.boxAcos(self.ptr)
        return Box.from_ptr(b)

    def tan(self) -> Box: 
        cdef fb.Box b = fb.boxTan(self.ptr)
        return Box.from_ptr(b)

    def sqrt(self) -> Box: 
        cdef fb.Box b = fb.boxSqrt(self.ptr)
        return Box.from_ptr(b)

    def sin(self) -> Box: 
        cdef fb.Box b = fb.boxSin(self.ptr)
        return Box.from_ptr(b)

    def rint(self) -> Box: 
        cdef fb.Box b = fb.boxRint(self.ptr)
        return Box.from_ptr(b)

    def round(self) -> Box: 
        cdef fb.Box b = fb.boxRound(self.ptr)
        return Box.from_ptr(b)

    def log(self) -> Box: 
        cdef fb.Box b = fb.boxLog(self.ptr)
        return Box.from_ptr(b)

    def log10(self) -> Box: 
        cdef fb.Box b = fb.boxLog10(self.ptr)
        return Box.from_ptr(b)

    def floor(self) -> Box: 
        cdef fb.Box b = fb.boxFloor(self.ptr)
        return Box.from_ptr(b)

    def exp(self) -> Box: 
        cdef fb.Box b = fb.boxExp(self.ptr)
        return Box.from_ptr(b)

    def exp10(self) -> Box: 
        cdef fb.Box b = fb.boxExp10(self.ptr)
        return Box.from_ptr(b)

    def cos(self) -> Box: 
        cdef fb.Box b = fb.boxCos(self.ptr)
        return Box.from_ptr(b)

    def ceil(self) -> Box: 
        cdef fb.Box b = fb.boxCeil(self.ptr)
        return Box.from_ptr(b)

    def atan(self) -> Box: 
        cdef fb.Box b = fb.boxAtan(self.ptr)
        return Box.from_ptr(b)

    def asin(self) -> Box: 
        cdef fb.Box b = fb.boxAsin(self.ptr)
        return Box.from_ptr(b)

    def is_nil(self) -> bool:
        """Check if a box is nil."""
        return fb.isNil(self.ptr)

    def is_box_abstr(self) -> bool:
        return fb.isBoxAbstr(self.ptr)

    def is_box_appl(self) -> bool:
        return fb.isBoxAppl(self.ptr)

    def is_box_button(self) -> bool:
        return fb.isBoxButton(self.ptr)

    def is_box_case(self) -> bool:
        return fb.isBoxCase(self.ptr)

    def is_box_checkbox(self) -> bool:
        return fb.isBoxCheckbox(self.ptr)

    def is_box_cut(self) -> bool:
        return fb.isBoxCut(self.ptr)

    def is_box_environment(self) -> bool:
        return fb.isBoxEnvironment(self.ptr)

    def is_box_error(self) -> bool:
        return fb.isBoxError(self.ptr)

    def is_box_f_const(self) -> bool:
        return fb.isBoxFConst(self.ptr)

    def is_box_f_fun(self) -> bool:
        return fb.isBoxFFun(self.ptr)

    def is_box_f_var_(self) -> bool:
        return fb.isBoxFVar(self.ptr)

    def is_box_h_bargraph(self) -> bool:
        return fb.isBoxHBargraph(self.ptr)

    def is_box_h_group(self) -> bool:
        return fb.isBoxHGroup(self.ptr)

    def is_box_h_slider(self) -> bool:
        return fb.isBoxHSlider(self.ptr)

    def is_box_ident(self) -> bool:
        return fb.isBoxIdent(self.ptr)

    def is_box_int(self) -> bool:
        return fb.isBoxInt(self.ptr)

    def is_box_num_entry(self) -> bool:
        return fb.isBoxNumEntry(self.ptr)

    def is_box_prim0(self) -> bool:
        return fb.isBoxPrim0(self.ptr)

    def is_box_prim1(self) -> bool:
        return fb.isBoxPrim1(self.ptr)

    def is_box_prim2(self) -> bool:
        return fb.isBoxPrim2(self.ptr)

    def is_box_prim3(self) -> bool:
        return fb.isBoxPrim3(self.ptr)

    def is_box_prim4(self) -> bool:
        return fb.isBoxPrim4(self.ptr)

    def is_box_prim5(self) -> bool:
        return fb.isBoxPrim5(self.ptr)

    def is_box_real_(self) -> bool:
        return fb.isBoxReal(self.ptr)

    def is_box_slot(self) -> bool:
        return fb.isBoxSlot(self.ptr)

    def is_box_soundfile(self) -> bool:
        return fb.isBoxSoundfile(self.ptr)

    def is_box_symbolic(self) -> bool:
        return fb.isBoxSymbolic(self.ptr)

    def is_box_t_group(self) -> bool:
        return fb.isBoxTGroup(self.ptr)

    def is_box_v_group(self) -> bool:
        return fb.isBoxVGroup(self.ptr)

    def is_box_v_slider(self) -> bool:
        return fb.isBoxVSlider(self.ptr)

    def is_box_waveform(self) -> bool:
        return fb.isBoxWaveform(self.ptr)

    def is_box_wire(self) -> bool:
        return fb.isBoxWire(self.ptr)


cdef class Int(Box):

    def __cinit__(self, int value):
        self.ptr = <fb.Box>fb.boxInt(value)

    @staticmethod
    cdef Int from_ptr(fb.Box ptr, bint ptr_owner=False):
        """Wrap external factory from pointer"""
        cdef Int box = Int.__new__(Int)
        box.ptr = ptr
        return box


# cdef class Int:
#     cdef fb.Box ptr

#     def __cinit__(self, int value):
#         self.ptr = <fb.Box>fb.boxInt(value)

#     @staticmethod
#     cdef Int from_ptr(fb.Box ptr, bint ptr_owner=False):
#         """Wrap external factory from pointer"""
#         cdef Int box = Int.__new__(Int)
#         box.ptr = ptr
#         return box

#     def print(self, shared: bool = False, max_size: int = 256):
#         """Print this box."""
#         print(fb.printBox(self.ptr, shared, max_size).decode())

#     def __add__(self, Box other):
#         """Add this box to another."""
#         cdef fb.Box b = fb.boxAdd(self.ptr, other.ptr)
#         return Box.from_ptr(b)

#     def __radd__(self, Box other):
#         """Reverse add this box to another."""
#         cdef fb.Box b = fb.boxAdd(self.ptr, other.ptr)
#         return Box.from_ptr(b)


# cdef string print_signal(fs.Signal sig, bint shared, int max_size):
#     """Print a signal."""
#     return fs.printSignal(sig, shared, max_size)

cdef bint get_def_name_property(fb.Box b, fb.Box& id):
    """Indicates the identifier (if any) the expression was a definition of."""
    return fb.getDefNameProperty(b, id)

cdef string extract_name(fb.Box full_label):
    """Extract the name from a label."""
    return fb.extractName(full_label)

def create_lib_context():
    """Create global compilation context, has to be done first."""
    fb.createLibContext()

def destroy_lib_context():
    """Destroy global compilation context, has to be done last."""
    fb.destroyLibContext()


cdef void* get_user_data(fb.Box b):
    """Return the extended type of a box."""
    return fb.getUserData(b)

cdef fb.Box box_int(int n):
    """Constant integer : for all t, x(t) = n."""
    return fb.boxInt(n)

cdef fb.Box box_real(double n):
    """Constant real : for all t, x(t) = n."""
    return fb.boxReal(n)

cdef fb.Box box_wire():
    """The identity box, copy its input to its output."""
    return fb.boxWire()

cdef fb.Box box_cut():
    """The cut box, to "stop"/terminate a signal."""
    return fb.boxCut()

cdef fb.Box box_seq(fb.Box x, fb.Box y):
    """The sequential composition of two blocks (e.g., A:B) expects: outputs(A)=inputs(B)."""
    return fb.boxSeq(x, y)

cdef fb.Box box_par(fb.Box x, fb.Box y):
    """The parallel composition of two blocks (e.g., A,B)."""
    return fb.boxPar(x, y)

cdef fb.Box box_par3(fb.Box x, fb.Box y, fb.Box z):
    """The parallel composition of three blocks (e.g., A,B,C)."""
    return fb.boxPar3(x, y, z)

cdef fb.Box box_par4(fb.Box a, fb.Box b, fb.Box c, fb.Box d):
    """The parallel composition of four blocks (e.g., A,B,C,D)."""
    return fb.boxPar4(a, b, c, d)

cdef fb.Box box_par5(fb.Box a, fb.Box b, fb.Box c, fb.Box d, fb.Box e):
    """The parallel composition of five blocks (e.g., A,B,C,D,E)."""
    return fb.boxPar5(a, b, c, d, e)

cdef fb.Box box_split(fb.Box x, fb.Box y):
    """The split composition (e.g., A<:B) operator is used to distribute
    the outputs of A to the inputs of B.
    """
    return fb.boxSplit(x, y)

cdef fb.Box box_merge(fb.Box x, fb.Box y):
    """The merge composition (e.g., A:>B) is the dual of the split composition."""
    return fb.boxMerge(x, y)

cdef fb.Box box_rec(fb.Box x, fb.Box y):
    """The recursive composition (e.g., A~B) is used to create cycles in the 
    block-diagram in order to express recursive computations.
    """
    return fb.boxRec(x, y)

cdef fb.Box box_route(fb.Box n, fb.Box m, fb.Box r):
    """The route primitive facilitates the routing of signals in Faust."""
    return fb.boxRoute(n, m, r)

cdef fb.Box box_delay_():
    """Create a delayed box."""
    return fb.boxDelay()

cdef fb.Box box_delay(fb.Box b, fb.Box del_):
    """Create a delayed box."""
    return fb.boxDelay(b, del_)

cdef fb.Box box_int_cast(fb.Box b):
    """Create a casted box."""
    return fb.boxIntCast(b)

cdef fb.Box box_int_cast_():
    """Create a casted box."""
    return fb.boxIntCast()

cdef fb.Box box_float_cast(fb.Box b):
    """Create a casted box."""
    return fb.boxFloatCast(b)

cdef fb.Box box_float_cast_():
    """Create a casted box."""
    return fb.boxFloatCast()

cdef fb.Box box_read_only_table(fb.Box n, fb.Box init, fb.Box ridx):
    """Create a read only table."""
    return fb.boxReadOnlyTable(n, init, ridx)

cdef fb.Box box_read_only_table_():
    """Create a read only table."""
    return fb.boxReadOnlyTable()

cdef fb.Box box_write_read_table(fb.Box n, fb.Box init, fb.Box widx, fb.Box wsig, fb.Box ridx):
    """Create a read/write table."""
    return fb.boxWriteReadTable(n, init, widx, wsig, ridx)

cdef fb.Box box_write_read_table_(f):
    """Create a read/write table."""
    return fb.boxWriteReadTable()

cdef fb.Box box_waveform(const fs.tvec& wf):
    """Create a waveform."""
    return fb.boxWaveform(wf)

cdef fb.Box box_soundfile(const string& label, fb.Box chan):
    """Create a soundfile block."""
    return fb.boxSoundfile(label, chan)

cdef fb.Box box_soundfile_(const string& label, fb.Box chan, fb.Box part, fb.Box ridx):
    """Create a soundfile block."""
    return fb.boxSoundfile(label, chan, part, ridx)

cdef fb.Box box_select2(fb.Box selector, fb.Box b1, fb.Box b2):
    """Create a selector between two boxes."""
    return fb.boxSelect2(selector, b1, b2)

cdef fb.Box box_select2_():
    """Create a selector between two boxes."""
    return fb.boxSelect2()

cdef fb.Box box_select3(fb.Box selector, fb.Box b1, fb.Box b2, fb.Box b3):
    """Create a selector between three boxes."""
    return fb.boxSelect3(selector, b1, b2, b3)

cdef fb.Box box_select3_():
    """Create a selector between three boxes."""
    return fb.boxSelect3()

cdef fb.Box box_f_const(fb.SType type, const string& name, const string& file):
    """Create a foreign constant box."""
    return fb.boxFConst(type, name, file)

cdef fb.Box box_f_var(fb.SType type, const string& name, const string& file):
    """Create a foreign variable box."""
    return fb.boxFVar(type, name, file)

cdef fb.Box box_bin_op(fb.SOperator op):
    """Generic binary mathematical functions."""
    return fb.boxBinOp(op)

cdef fb.Box box_bin_op_with_box(fb.SOperator op, fb.Box b1, fb.Box b2):
    """Generic binary mathematical functions."""
    return fb.boxBinOp(op, b1, b2)


cdef fb.Box box_rem(fb.Box b1, fb.Box b2):
    return fb.boxRem(b1, b2)

cdef fb.Box box_left_shift(fb.Box b1, fb.Box b2):
    return fb.boxLeftShift(b1, b2)

cdef fb.Box box_l_right_shift(fb.Box b1, fb.Box b2):
    return fb.boxLRightShift(b1, b2)

cdef fb.Box box_a_right_shift(fb.Box b1, fb.Box b2):
    return fb.boxARightShift(b1, b2)


# cdef fb.Box box_abs(fb.Box x):
#     return fb.boxAbs(x)

# cdef fb.Box box_acos(fb.Box x):
#     return fb.boxAcos(x)

# cdef fb.Box box_tan(fb.Box x):
#     return fb.boxTan(x)

# cdef fb.Box box_sqrt(fb.Box x):
#     return fb.boxSqrt(x)

# cdef fb.Box box_sin(fb.Box x):
#     return fb.boxSin(x)

# cdef fb.Box box_rint(fb.Box x):
#     return fb.boxRint(x)

# cdef fb.Box box_round(fb.Box x):
#     return fb.boxRound(x)

# cdef fb.Box box_log(fb.Box x):
#     return fb.boxLog(x)

# cdef fb.Box box_log10(fb.Box x):
#     return fb.boxLog10(x)

# cdef fb.Box box_floor(fb.Box x):
#     return fb.boxFloor(x)

# cdef fb.Box box_exp(fb.Box x):
#     return fb.boxExp(x)

# cdef fb.Box box_exp10(fb.Box x):
#     return fb.boxExp10(x)

# cdef fb.Box box_cos(fb.Box x):
#     return fb.boxCos(x)

# cdef fb.Box box_ceil(fb.Box x):
#     return fb.boxCeil(x)

# cdef fb.Box box_atan(fb.Box x):
#     return fb.boxAtan(x)

# cdef fb.Box box_asin(fb.Box x):
#     return fb.boxAsin(x)

cdef fb.Box box_remainder(fb.Box b1, fb.Box b2):
    return fb.boxRemainder(b1, b2)

cdef fb.Box box_pow(fb.Box b1, fb.Box b2):
    return fb.boxPow(b1, b2)

cdef fb.Box box_min(fb.Box b1, fb.Box b2):
    return fb.boxMin(b1, b2)

cdef fb.Box box_max(fb.Box b1, fb.Box b2):
    return fb.boxMax(b1, b2)

cdef fb.Box box_fmod(fb.Box b1, fb.Box b2):
    return fb.boxFmod(b1, b2)

cdef fb.Box box_atan2(fb.Box b1, fb.Box b2):
    return fb.boxAtan2(b1, b2)

cdef fb.Box box_button(const string& label):
    """Create a button box."""
    return fb.boxButton(label)

cdef fb.Box box_checkbox(const string& label):
    """Create a checkbox box."""
    return fb.boxCheckbox(label)

cdef fb.Box box_v_slider(const string& label, fb.Box init, fb.Box min, fb.Box max, fb.Box step):
    """Create a verical slider box."""
    return fb.boxVSlider(label, init, min, max, step)

cdef fb.Box box_h_slider(const string& label, fb.Box init, fb.Box min, fb.Box max, fb.Box step):
    """Create a horizontal slider box."""
    return fb.boxHSlider(label, init, min, max, step)

cdef fb.Box box_num_entry(const string& label, fb.Box init, fb.Box min, fb.Box max, fb.Box step):
    """Create a numeric entry box."""
    return fb.boxNumEntry(label, init, min, max, step)

cdef fb.Box box_v_bargraph(const string& label, fb.Box min, fb.Box max):
    """Create a vertical bargraph box."""
    return fb.boxVBargraph(label, min, max)

cdef fb.Box box_v_bargraph2(const string& label, fb.Box min, fb.Box max, fb.Box x):
    """Create a vertical bargraph box."""
    return fb.boxVBargraph(label, min, max, x)

cdef fb.Box box_h_bargraph(const string& label, fb.Box min, fb.Box max):
    """Create a horizontal bargraph box."""
    return fb.boxHBargraph(label, min, max)

cdef fb.Box box_h_bargraph2(const string& label, fb.Box min, fb.Box max, fb.Box x):
    """Create a horizontal bargraph box."""
    return fb.boxHBargraph(label, min, max, x)

cdef fb.Box box_v_group(const string& label, fb.Box group):
    """Create a vertical group box."""
    return fb.boxVGroup(label, group)

cdef fb.Box box_h_group(const string& label, fb.Box group):
    """Create a horizontal group box."""
    return fb.boxHGroup(label, group)

cdef fb.Box box_t_group(const string& label, fb.Box group):
    """Create a tab group box."""
    return fb.boxTGroup(label, group)

cdef fb.Box box_attach(fb.Box b1, fb.Box b2):
    """Create an attach box."""
    return fb.boxAttach(b1, b2)

cdef fb.Box box_prim2(fb.prim2 foo):
    return fb.boxPrim2(foo)

cdef bint is_box_abstr_(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxAbstr(t, x, y)

cdef bint is_box_access(fb.Box t, fb.Box& exp, fb.Box& id):
    return fb.isBoxAccess(t, exp, id)

cdef bint is_box_appl_(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxAppl(t, x, y)

cdef bint is_box_button_(fb.Box b, fb.Box& lbl):
    return fb.isBoxButton(b, lbl)

cdef bint is_box_case_(fb.Box b, fb.Box& rules):
    return fb.isBoxCase(b, rules)

cdef bint is_box_checkbox_(fb.Box b, fb.Box& lbl):
    return fb.isBoxCheckbox(b, lbl)

cdef bint is_box_component(fb.Box b, fb.Box& filename):
    return fb.isBoxComponent(b, filename)

cdef bint is_box_environment(fb.Box b):
    return fb.isBoxEnvironment(b)

cdef bint is_box_f_const(fb.Box b, fb.Box& type, fb.Box& name, fb.Box& file):
    return fb.isBoxFConst(b, type, name, file)

cdef bint is_box_f_fun(fb.Box b, fb.Box& ff):
    return fb.isBoxFFun(b, ff)

cdef bint is_box_f_var(fb.Box b, fb.Box& type, fb.Box& name, fb.Box& file):
    return fb.isBoxFVar(b, type, name, file)

cdef bint is_box_h_bargraph(fb.Box b, fb.Box& lbl, fb.Box& min, fb.Box& max):
    return fb.isBoxHBargraph(b, lbl, min, max)

cdef bint is_box_h_group(fb.Box b, fb.Box& lbl, fb.Box& x):
    return fb.isBoxHGroup(b, lbl, x)

cdef bint is_box_h_slider(fb.Box b, fb.Box& lbl, fb.Box& cur, fb.Box& min, fb.Box& max, fb.Box& step):
    return fb.isBoxHSlider(b, lbl, cur, min, max, step)

cdef bint is_box_ident(fb.Box t, const char** str):
    return fb.isBoxIdent(t, str)

cdef bint is_box_inputs(fb.Box t, fb.Box& x):
    return fb.isBoxInputs(t, x)

cdef bint is_box_int(fb.Box t, int* i):
    return fb.isBoxInt(t, i)

cdef bint is_box_i_par(fb.Box t, fb.Box& x, fb.Box& y, fb.Box& z):
    return fb.isBoxIPar(t, x, y, z)

cdef bint is_box_i_prod(fb.Box t, fb.Box& x, fb.Box& y, fb.Box& z):
    return fb.isBoxIProd(t, x, y, z)

cdef bint is_box_i_seq(fb.Box t, fb.Box& x, fb.Box& y, fb.Box& z):
    return fb.isBoxISeq(t, x, y, z)

cdef bint is_box_i_sum(fb.Box t, fb.Box& x, fb.Box& y, fb.Box& z):
    return fb.isBoxISum(t, x, y, z)

cdef bint is_box_library(fb.Box b, fb.Box& filename):
    return fb.isBoxLibrary(b, filename)

cdef bint is_box_merge(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxMerge(t, x, y)

cdef bint is_box_metadata(fb.Box b, fb.Box& exp, fb.Box& mdlist):
    return fb.isBoxMetadata(b, exp, mdlist)

cdef bint is_box_num_entry(fb.Box b, fb.Box& lbl, fb.Box& cur, fb.Box& min_, fb.Box& max_, fb.Box& step):
    return fb.isBoxNumEntry(b, lbl, cur, min_, max_, step)

cdef bint is_box_outputs(fb.Box t, fb.Box& x):
    return fb.isBoxOutputs(t, x)

cdef bint is_box_par(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxPar(t, x, y)

cdef bint is_box_prim0_(fb.Box b, fb.prim0* p):
    return fb.isBoxPrim0(b, p)

cdef bint is_box_prim1_(fb.Box b, fb.prim1* p):
    return fb.isBoxPrim1(b, p)

cdef bint is_box_prim2_(fb.Box b, fb.prim2* p):
    return fb.isBoxPrim2(b, p)

cdef bint is_box_prim3_(fb.Box b, fb.prim3* p):
    return fb.isBoxPrim3(b, p)

cdef bint is_box_prim4_(fb.Box b, fb.prim4* p):
    return fb.isBoxPrim4(b, p)

cdef bint is_box_prim5_(fb.Box b, fb.prim5* p):
    return fb.isBoxPrim5(b, p)

cdef bint is_box_real(fb.Box t, double* r):
    return fb.isBoxReal(t, r)

cdef bint is_box_rec(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxRec(t, x, y)

cdef bint is_box_route(fb.Box b, fb.Box& n, fb.Box& m, fb.Box& r):
    return fb.isBoxRoute(b, n, m, r)

cdef bint is_box_seq(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxSeq(t, x, y)

cdef bint is_box_soundfile(fb.Box b, fb.Box& label, fb.Box& chan):
    return fb.isBoxSoundfile(b, label, chan)

cdef bint is_box_split(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxSplit(t, x, y)

cdef bint is_box_symbolic(fb.Box t, fb.Box& slot, fb.Box& body):
    return fb.isBoxSymbolic(t, slot, body)

cdef bint is_box_t_group(fb.Box b, fb.Box& lbl, fb.Box& x):
    return fb.isBoxTGroup(b, lbl, x)

cdef bint is_box_v_bargraph(fb.Box b, fb.Box& lbl, fb.Box& min, fb.Box& max):
    return fb.isBoxVBargraph(b, lbl, min, max)

cdef bint is_box_v_group(fb.Box b, fb.Box& lbl, fb.Box& x):
    return fb.isBoxVGroup(b, lbl, x)

cdef bint is_box_v_slider(fb.Box b, fb.Box& lbl, fb.Box& cur, fb.Box& min, fb.Box& max, fb.Box& step):
    return fb.isBoxVSlider(b, lbl, cur, min, max, step)

cdef bint is_box_with_local_def(fb.Box t, fb.Box& body, fb.Box& ldef):
    return fb.isBoxWithLocalDef(t, body, ldef)

cdef fb.Box dsp_to_boxes(const string& name_app, const string& dsp_content, int argc, const char* argv[], int* inputs, int* outputs, string& error_msg):
    """Compile a DSP source code as a string in a flattened box."""
    return fb.DSPToBoxes(name_app, dsp_content, argc, argv, inputs, outputs, error_msg)

cdef bint get_box_type(fb.Box box, int* inputs, int* outputs):
    """Return the number of inputs and outputs of a box."""
    return fb.getBoxType(box, inputs, outputs)

cdef fs.tvec boxes_to_signals(fb.Box box, string& error_msg):
    """Compile a box expression in a list of signals in normal form."""
    return fb.boxesToSignals(box, error_msg)

cdef string create_source_from_boxes(const string& name_app, fb.Box box, const string& lang, int argc, const char* argv[], string& error_msg):
    """Create source code in a target language from a box expression."""
    return fb.createSourceFromBoxes(name_app, box, lang, argc, argv, error_msg)


