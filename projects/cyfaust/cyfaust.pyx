# distutils: language = c++

from libc.stdlib cimport malloc, free
from libcpp.string cimport string
from libcpp.vector cimport vector

cimport faust_interp as fi
cimport faust_box as fb


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
    cdef fb.tvec* ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr = new fb.tvec()
        self.ptr_owner = False

    cdef add(self, fb.Signal sig):
        self.ptr.push_back(sig)




## ---------------------------------------------------------------------------
## faust/dsp/libfaust

def generate_sha1(data: str) -> str:
    """Generate SHA1 key from a string."""
    return fi.generateSHA1(data.encode('utf8')).decode()

def expand_dsp_from_file(filename: str, *args) -> (str, str):
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
    # def from_signals(str name_app, fb.tvec signals, *args) -> InterpreterDspFactory:
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

    # @staticmethod
    # def from_boxes(str name_app, fb.Box box, *args) -> InterpreterDspFactory:
    #     """Create a Faust DSP factory from a box expression."""
    #     cdef string error_msg
    #     error_msg.reserve(4096)
    #     cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
    #         InterpreterDspFactory)
    #     cdef ParamArray params = ParamArray(args)
    #     factory.ptr_owner = True
    #     factory.ptr = <fi.interpreter_dsp_factory*>fi.createInterpreterDSPFactoryFromBoxes(
    #         name_app.encode('utf8'),
    #         box,
    #         params.argc,
    #         params.argv,
    #         error_msg,
    #     )
    #     if not error_msg.empty():
    #         print(error_msg.decode())
    #         return
    #     return factory

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

cdef fi.interpreter_dsp_factory* create_interpreter_dsp_factory_from_boxes(
        const string& name_app, fi.Box box, int argc, const char* argv[], 
        string& error_msg):
    """Create a Faust DSP factory from a box expression."""
    return fi.createInterpreterDSPFactoryFromBoxes(
        name_app, box, argc, argv, error_msg)

## ---------------------------------------------------------------------------
## faust/dsp/libfaust-box

cdef print_box(fb.Box box, bint shared, int max_size):
    """Print a box."""
    return fb.printBox(box, shared, max_size)

cdef print_signal(fb.Signal sig, bint shared, int max_size):
    """Print a signal."""
    return fb.printSignal(sig, shared, max_size)

cdef bint get_def_mame_roperty(fb.Box b, fb.Box& id):
    return fb.getDefNameProperty(b, id)

cdef string extract_name(fb.Box full_label):
    return fb.extractName(full_label)

cdef void create_lib_context():
    fb.createLibContext()

cdef void destroy_lib_context():
    fb.destroyLibContext()

cdef bint is_nil(fb.Box b):
    return fb.isNil(b)

cdef const char* tree2str(fb.Box b):
    return fb.tree2str(b)

cdef int tree2int(fb.Box b):
    return fb.tree2int(b)

cdef void* get_user_data(fb.Box b):
    return fb.getUserData(b)

cdef fb.Box box_int(int n):
    return fb.boxInt(n)

cdef fb.Box box_real(double n):
    return fb.boxReal(n)

cdef fb.Box box_wire():
    return fb.boxWire()

cdef fb.Box box_cut():
    return fb.boxCut()

cdef fb.Box box_seq(fb.Box x, fb.Box y):
    return fb.boxSeq(x, y)

cdef fb.Box box_par(fb.Box x, fb.Box y):
    return fb.boxPar(x, y)

cdef fb.Box box_par3(fb.Box x, fb.Box y, fb.Box z):
    return fb.boxPar3(x, y, z)

cdef fb.Box box_par4(fb.Box a, fb.Box b, fb.Box c, fb.Box d):
    return fb.boxPar4(a, b, c, d)

cdef fb.Box box_par5(fb.Box a, fb.Box b, fb.Box c, fb.Box d, fb.Box e):
    return fb.boxPar5(a, b, c, d, e)

cdef fb.Box box_split(fb.Box x, fb.Box y):
    return fb.boxSplit(x, y)

cdef fb.Box box_merge(fb.Box x, fb.Box y):
    return fb.boxMerge(x, y)

cdef fb.Box box_rec(fb.Box x, fb.Box y):
    return fb.boxRec(x, y)

cdef fb.Box box_route(fb.Box n, fb.Box m, fb.Box r):
    return fb.boxRoute(n, m, r)

cdef fb.Box box_delay_():
    return fb.boxDelay()

cdef fb.Box box_delay(fb.Box b, fb.Box del_):
    return fb.boxDelay(b, del_)

cdef fb.Box box_int_cast(fb.Box b):
    return fb.boxIntCast(b)

cdef fb.Box box_int_cast_():
    return fb.boxIntCast()

cdef fb.Box box_float_cast(fb.Box b):
    return fb.boxFloatCast(b)

cdef fb.Box box_float_cast_():
    return fb.boxFloatCast()

cdef fb.Box box_read_only_table(fb.Box n, fb.Box init, fb.Box ridx):
    return fb.boxReadOnlyTable(n, init, ridx)

cdef fb.Box box_read_only_table_():
    return fb.boxReadOnlyTable()

cdef fb.Box box_write_read_table(fb.Box n, fb.Box init, fb.Box widx, fb.Box wsig, fb.Box ridx):
    return fb.boxWriteReadTable(n, init, widx, wsig, ridx)

cdef fb.Box box_write_read_table_(f):
    return fb.boxWriteReadTable()

cdef fb.Box box_waveform(const fb.tvec& wf):
    return fb.boxWaveform(wf)

cdef fb.Box box_soundfile(const string& label, fb.Box chan):
    return fb.boxSoundfile(label, chan)

cdef fb.Box box_soundfile_with_part(const string& label, fb.Box chan, fb.Box part, fb.Box ridx):
    return fb.boxSoundfile(label, chan, part, ridx)

cdef fb.Box box_select2(fb.Box selector, fb.Box b1, fb.Box b2):
    return fb.boxSelect2(selector, b1, b2)

cdef fb.Box box_select3(fb.Box selector, fb.Box b1, fb.Box b2, fb.Box b3):
    return fb.boxSelect3(selector, b1, b2, b3)

cdef fb.Box box_f_const(fb.SType type, const string& name, const string& file):
    return fb.boxFConst(type, name, file)

cdef fb.Box box_f_var(fb.SType type, const string& name, const string& file):
    return fb.boxFVar(type, name, file)

cdef fb.Box box_bin_op(fb.SOperator op):
    return fb.boxBinOp(op)

cdef fb.Box box_bin_op_with_box(fb.SOperator op, fb.Box b1, fb.Box b2):
    return fb.boxBinOp(op, b1, b2)

cdef fb.Box box_add(fb.Box b1, fb.Box b2):
    return fb.boxAdd(b1, b2)

cdef fb.Box box_sub(fb.Box b1, fb.Box b2):
    return fb.boxSub(b1, b2)

cdef fb.Box box_mul(fb.Box b1, fb.Box b2):
    return fb.boxMul(b1, b2)

cdef fb.Box box_div(fb.Box b1, fb.Box b2):
    return fb.boxDiv(b1, b2)

cdef fb.Box box_rem(fb.Box b1, fb.Box b2):
    return fb.boxRem(b1, b2)

cdef fb.Box box_left_shift(fb.Box b1, fb.Box b2):
    return fb.boxLeftShift(b1, b2)

cdef fb.Box box_l_right_shift(fb.Box b1, fb.Box b2):
    return fb.boxLRightShift(b1, b2)

cdef fb.Box box_a_right_shift(fb.Box b1, fb.Box b2):
    return fb.boxARightShift(b1, b2)

cdef fb.Box box_gt(fb.Box b1, fb.Box b2):
    return fb.boxGT(b1, b2)

cdef fb.Box box_lt(fb.Box b1, fb.Box b2):
    return fb.boxLT(b1, b2)

cdef fb.Box box_ge(fb.Box b1, fb.Box b2):
    return fb.boxGE(b1, b2)

cdef fb.Box box_le(fb.Box b1, fb.Box b2):
    return fb.boxLE(b1, b2)

cdef fb.Box box_eq(fb.Box b1, fb.Box b2):
    return fb.boxEQ(b1, b2)

cdef fb.Box box_ne(fb.Box b1, fb.Box b2):
    return fb.boxNE(b1, b2)

cdef fb.Box box_and(fb.Box b1, fb.Box b2):
    return fb.boxAND(b1, b2)

cdef fb.Box box_or(fb.Box b1, fb.Box b2):
    return fb.boxOR(b1, b2)

cdef fb.Box box_xor(fb.Box b1, fb.Box b2):
    return fb.boxXOR(b1, b2)

cdef fb.Box box_abs(fb.Box x):
    return fb.boxAbs(x)

cdef fb.Box box_acos(fb.Box x):
    return fb.boxAcos(x)

cdef fb.Box box_tan(fb.Box x):
    return fb.boxTan(x)

cdef fb.Box box_sqrt(fb.Box x):
    return fb.boxSqrt(x)

cdef fb.Box box_sin(fb.Box x):
    return fb.boxSin(x)

cdef fb.Box box_rint(fb.Box x):
    return fb.boxRint(x)

cdef fb.Box box_round(fb.Box x):
    return fb.boxRound(x)

cdef fb.Box box_log(fb.Box x):
    return fb.boxLog(x)

cdef fb.Box box_log10(fb.Box x):
    return fb.boxLog10(x)

cdef fb.Box box_floor(fb.Box x):
    return fb.boxFloor(x)

cdef fb.Box box_exp(fb.Box x):
    return fb.boxExp(x)

cdef fb.Box box_exp10(fb.Box x):
    return fb.boxExp10(x)

cdef fb.Box box_cos(fb.Box x):
    return fb.boxCos(x)

cdef fb.Box box_ceil(fb.Box x):
    return fb.boxCeil(x)

cdef fb.Box box_atan(fb.Box x):
    return fb.boxAtan(x)

cdef fb.Box box_asin(fb.Box x):
    return fb.boxAsin(x)

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
    return fb.boxButton(label)

cdef fb.Box box_checkbox(const string& label):
    return fb.boxCheckbox(label)

cdef fb.Box box_v_slider(const string& label, fb.Box init, fb.Box min, fb.Box max, fb.Box step):
    return fb.boxVSlider(label, init, min, max, step)

cdef fb.Box box_h_slider(const string& label, fb.Box init, fb.Box min, fb.Box max, fb.Box step):
    return fb.boxHSlider(label, init, min, max, step)

cdef fb.Box box_num_entry(const string& label, fb.Box init, fb.Box min, fb.Box max, fb.Box step):
    return fb.boxNumEntry(label, init, min, max, step)

cdef fb.Box box_v_bargraph(const string& label, fb.Box min, fb.Box max):
    return fb.boxVBargraph(label, min, max)

cdef fb.Box box_v_bargraph2(const string& label, fb.Box min, fb.Box max, fb.Box x):
    return fb.boxVBargraph(label, min, max, x)

cdef fb.Box box_h_bargraph(const string& label, fb.Box min, fb.Box max):
    return fb.boxHBargraph(label, min, max)

cdef fb.Box box_h_bargraph2(const string& label, fb.Box min, fb.Box max, fb.Box x):
    return fb.boxHBargraph(label, min, max, x)

cdef fb.Box box_v_group(const string& label, fb.Box group):
    return fb.boxVGroup(label, group)

cdef fb.Box box_h_group(const string& label, fb.Box group):
    return fb.boxHGroup(label, group)

cdef fb.Box box_t_group(const string& label, fb.Box group):
    return fb.boxTGroup(label, group)

cdef fb.Box box_attach(fb.Box b1, fb.Box b2):
    return fb.boxAttach(b1, b2)

cdef fb.Box box_prim2(fb.prim2 foo):
    return fb.boxPrim2(foo)

cdef bint is_box_abstr(fb.Box t):
    return fb.isBoxAbstr(t)

cdef bint is_box_abstr_(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxAbstr(t, x, y)

cdef bint is_box_access(fb.Box t, fb.Box& exp, fb.Box& id):
    return fb.isBoxAccess(t, exp, id)

cdef bint is_box_appl(fb.Box t):
    return fb.isBoxAppl(t)

cdef bint is_box_appl_(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxAppl(t, x, y)

cdef bint is_box_button(fb.Box b):
    return fb.isBoxButton(b)

cdef bint is_box_button_(fb.Box b, fb.Box& lbl):
    return fb.isBoxButton(b, lbl)

cdef bint is_box_case(fb.Box b):
    return fb.isBoxCase(b)

cdef bint is_box_case_(fb.Box b, fb.Box& rules):
    return fb.isBoxCase(b, rules)

cdef bint is_box_checkbox(fb.Box b):
    return fb.isBoxCheckbox(b)

cdef bint is_box_checkbox_(fb.Box b, fb.Box& lbl):
    return fb.isBoxCheckbox(b, lbl)

cdef bint is_box_component(fb.Box b, fb.Box& filename):
    return fb.isBoxComponent(b, filename)

cdef bint is_box_cut(fb.Box t):
    return fb.isBoxCut(t)

cdef bint is_box_environment(fb.Box b):
    return fb.isBoxEnvironment(b)

cdef bint is_box_error(fb.Box t):
    return fb.isBoxError(t)

cdef bint is_box_f_const_(fb.Box b):
    return fb.isBoxFConst(b)

cdef bint is_box_f_const(fb.Box b, fb.Box& type, fb.Box& name, fb.Box& file):
    return fb.isBoxFConst(b, type, name, file)

cdef bint is_box_f_fun_(fb.Box b):
    return fb.isBoxFFun(b)

cdef bint is_box_f_fun(fb.Box b, fb.Box& ff):
    return fb.isBoxFFun(b, ff)

cdef bint is_box_f_var_(fb.Box b):
    return fb.isBoxFVar(b)

cdef bint is_box_f_var(fb.Box b, fb.Box& type, fb.Box& name, fb.Box& file):
    return fb.isBoxFVar(b, type, name, file)

cdef bint is_box_h_bargraph_(fb.Box b):
    return fb.isBoxHBargraph(b)

cdef bint is_box_h_bargraph(fb.Box b, fb.Box& lbl, fb.Box& min, fb.Box& max):
    return fb.isBoxHBargraph(b, lbl, min, max)

cdef bint is_box_h_group_(fb.Box b):
    return fb.isBoxHGroup(b)

cdef bint is_box_h_group(fb.Box b, fb.Box& lbl, fb.Box& x):
    return fb.isBoxHGroup(b, lbl, x)

cdef bint is_box_h_slider_(fb.Box b):
    return fb.isBoxHSlider(b)

cdef bint is_box_h_slider(fb.Box b, fb.Box& lbl, fb.Box& cur, fb.Box& min, fb.Box& max, fb.Box& step):
    return fb.isBoxHSlider(b, lbl, cur, min, max, step)

cdef bint is_box_ident_(fb.Box t):
    return fb.isBoxIdent(t)

cdef bint is_box_ident(fb.Box t, const char** str):
    return fb.isBoxIdent(t, str)

cdef bint is_box_inputs(fb.Box t, fb.Box& x):
    return fb.isBoxInputs(t, x)

cdef bint is_box_int_(fb.Box t):
    return fb.isBoxInt(t)

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

cdef bint is_box_num_entry_(fb.Box b):
    return fb.isBoxNumEntry(b)

cdef bint is_box_num_entry(fb.Box b, fb.Box& lbl, fb.Box& cur, fb.Box& min_, fb.Box& max_, fb.Box& step):
    return fb.isBoxNumEntry(b, lbl, cur, min_, max_, step)

cdef bint is_box_outputs(fb.Box t, fb.Box& x):
    return fb.isBoxOutputs(t, x)

cdef bint is_box_par(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxPar(t, x, y)

cdef bint is_box_prim0(fb.Box b):
    return fb.isBoxPrim0(b)

cdef bint is_box_prim1(fb.Box b):
    return fb.isBoxPrim1(b)

cdef bint is_box_prim2(fb.Box b):
    return fb.isBoxPrim2(b)

cdef bint is_box_prim3(fb.Box b):
    return fb.isBoxPrim3(b)

cdef bint is_box_prim4(fb.Box b):
    return fb.isBoxPrim4(b)

cdef bint is_box_prim5(fb.Box b):
    return fb.isBoxPrim5(b)

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

cdef bint is_box_real_(fb.Box t):
    return fb.isBoxReal(t)

cdef bint is_box_real(fb.Box t, double* r):
    return fb.isBoxReal(t, r)

cdef bint is_box_rec(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxRec(t, x, y)

cdef bint is_box_route(fb.Box b, fb.Box& n, fb.Box& m, fb.Box& r):
    return fb.isBoxRoute(b, n, m, r)

cdef bint is_box_seq(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxSeq(t, x, y)

cdef bint is_box_slot(fb.Box t):
    return fb.isBoxSlot(t)

cdef bint is_box_soundfile_(fb.Box b):
    return fb.isBoxSoundfile(b)

cdef bint is_box_soundfile(fb.Box b, fb.Box& label, fb.Box& chan):
    return fb.isBoxSoundfile(b, label, chan)

cdef bint is_box_split(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxSplit(t, x, y)

cdef bint is_box_symbolic_(fb.Box t):
    return fb.isBoxSymbolic(t)

cdef bint is_box_symbolic(fb.Box t, fb.Box& slot, fb.Box& body):
    return fb.isBoxSymbolic(t, slot, body)

cdef bint is_box_t_group_(fb.Box b):
    return fb.isBoxTGroup(b)

cdef bint is_box_t_group(fb.Box b, fb.Box& lbl, fb.Box& x):
    return fb.isBoxTGroup(b, lbl, x)

cdef bint is_box_v_bargraph_(fb.Box b):
    return fb.isBoxVBargraph(b)

cdef bint is_box_v_bargraph(fb.Box b, fb.Box& lbl, fb.Box& min, fb.Box& max):
    return fb.isBoxVBargraph(b, lbl, min, max)

cdef bint is_box_v_group_(fb.Box b):
    return fb.isBoxVGroup(b)

cdef bint is_box_v_group(fb.Box b, fb.Box& lbl, fb.Box& x):
    return fb.isBoxVGroup(b, lbl, x)

cdef bint is_box_v_slider_(fb.Box b):
    return fb.isBoxVSlider(b)

cdef bint is_box_v_slider(fb.Box b, fb.Box& lbl, fb.Box& cur, fb.Box& min, fb.Box& max, fb.Box& step):
    return fb.isBoxVSlider(b, lbl, cur, min, max, step)

cdef bint is_box_waveform(fb.Box b):
    return fb.isBoxWaveform(b)

cdef bint is_box_wire(fb.Box t):
    return fb.isBoxWire(t)

cdef bint is_box_with_local_def(fb.Box t, fb.Box& body, fb.Box& ldef):
    return fb.isBoxWithLocalDef(t, body, ldef)

cdef fb.Box dsp_to_boxes(const string& name_app, const string& dsp_content, int argc, const char* argv[], int* inputs, int* outputs, string& error_msg):
    return fb.DSPToBoxes(name_app, dsp_content, argc, argv, inputs, outputs, error_msg)

cdef bint get_box_type(fb.Box box, int* inputs, int* outputs):
    return fb.getBoxType(box, inputs, outputs)

cdef fb.tvec boxes_to_signals(fb.Box box, string& error_msg):
    return fb.boxesToSignals(box, error_msg)

cdef fb.string create_source_from_boxes(const string& name_app, fb.Box box, const string& lang, int argc, const char* argv[], string& error_msg):
    return fb.createSourceFromBoxes(name_app, box, lang, argc, argv, error_msg)


