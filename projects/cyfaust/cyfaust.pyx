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
    cdef vector[fs.Signal] ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr_owner = False

    def __iter__(self):
        for i in self.ptr:
            yield Signal.from_ptr(i)

    cdef add_ptr(self, fs.Signal sig):
        self.ptr.push_back(sig)

    def add(self, Signal sig):
        self.ptr.push_back(sig.ptr)

    def create_source(self, name_app: str, lang, *args) -> str:
        """Create source code in a target language from a signal expression."""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef ParamArray params = ParamArray(args)
        cdef string src = fs.createSourceFromSignals(
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

    @staticmethod
    def from_signals(str name_app, SignalVector signals, *args) -> InterpreterDspFactory:
        """Create a Faust DSP factory from a vector of output signals."""
        cdef string error_msg
        # cdef fs.tvec sigvec
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        cdef ParamArray params = ParamArray(args)
        # sigvec.push_back(<fs.Signal>signals.ptr)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.createInterpreterDSPFactoryFromSignals(
            name_app.encode('utf8'),
            <fs.tvec>signals.ptr,
            params.argc,
            params.argv,
            error_msg,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return
        return factory
    
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
## faust/dsp/libfaust-box

include "faust_box.pxi"



## ---------------------------------------------------------------------------
## faust/dsp/libfaust-signal

# include "faust_signal.pxi"


class signal_context:
    def __enter__(self):
        fb.createLibContext()
    def __exit__(self, type, value, traceback):
        fb.destroyLibContext()


cdef class Signal:
    """faust Signal wrapper.
    """
    cdef fs.Signal ptr

    def __cinit__(self):
        self.ptr = NULL

    @staticmethod
    cdef Signal from_ptr(fs.Signal ptr, bint ptr_owner=False):
        """Wrap Signal from pointer"""
        cdef Signal sig = Signal.__new__(Signal)
        sig.ptr = ptr
        return sig

    @staticmethod
    def from_input(int idx) -> Signal:
        """Create signal from int"""
        cdef fs.Signal s = fs.sigInput(idx)
        return Signal.from_ptr(s)

    @staticmethod
    def from_int(int value) -> Signal:
        """Create signal from int"""
        cdef fs.Signal s = fs.sigInt(value)
        return Signal.from_ptr(s)

    @staticmethod
    def from_float(float value) -> Signal:
        """Create signal from float"""
        cdef fs.Signal s = fs.sigReal(value)
        return Signal.from_ptr(s)

    def create_source(self, name_app: str, lang, *args) -> str:
        """Create source code in a target language from a signal expression."""
        cdef fs.tvec signals
        cdef string error_msg
        error_msg.reserve(4096)
        signals.push_back(self.ptr)
        cdef ParamArray params = ParamArray(args)
        cdef string src = fs.createSourceFromSignals(
            name_app,
            signals,
            lang,
            params.argc,
            params.argv,
            error_msg)
        if error_msg.empty():
            print(error_msg.decode())
            return
        return src.decode()

    def print(self, shared: bool = False, max_size: int = 256):
        """Print this signal."""
        print(fs.printSignal(self.ptr, shared, max_size).decode())

    def ffname(Signal s) -> str:
        """Return the name parameter of a foreign function."""
        return fs.ffname(s.ptr).decode()

    def ffarity(Signal s) -> int:
        """Return the arity of a foreign function."""
        return fs.ffarity(s.ptr)

    def __add__(self, Signal other):
        """Add this signal to another."""
        cdef fs.Signal b = fs.sigAdd(self.ptr, other.ptr)
        return Signal.from_ptr(b)

    def __radd__(self, Signal other):
        """Reverse add this signal to another."""
        cdef fs.Signal b = fs.sigAdd(self.ptr, other.ptr)
        return Signal.from_ptr(b)

    def __sub__(self, Signal other):
        """Subtract this box from another."""
        cdef fs.Signal s = fs.sigSub(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __rsub__(self, Signal other):
        """Subtract this box from another."""
        cdef fs.Signal s = fs.sigSub(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __mul__(self, Signal other):
        """Multiply this box with another."""
        cdef fs.Signal s = fs.sigMul(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __rmul__(self, Signal other):
        """Reverse multiply this box with another."""
        cdef fs.Signal s = fs.sigMul(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __div__(self, Signal other):
        """Divide this box with another."""
        cdef fs.Signal s = fs.sigDiv(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __rdiv__(self, Signal other):
        """Reverse divide this box with another."""
        cdef fs.Signal s = fs.sigDiv(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __eq__(self, Signal other):
        """Compare for equality with another signal."""
        cdef fs.Signal s = fs.sigEQ(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __ne__(self, Signal other):
        """Assert this box is not equal with another signal."""
        cdef fs.Signal s = fs.sigNE(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __gt__(self, Signal other):
        """Is this box greater than another signal."""
        cdef fs.Signal s = fs.sigGT(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __ge__(self, Signal other):
        """Is this box greater than or equal from another signal."""
        cdef fs.Signal s = fs.sigGE(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __lt__(self, Signal other):
        """Is this box lesser than another signal."""
        cdef fs.Signal s = fs.sigLT(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __le__(self, Signal other):
        """Is this box lesser than or equal from another signal."""
        cdef fs.Signal s = fs.sigLE(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __and__(self, Signal other):
        """logical and with another signal."""
        cdef fs.Signal s = fs.sigAND(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __or__(self, Signal other):
        """logical or with another signal."""
        cdef fs.Signal s = fs.sigOR(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __xor__(self, Signal other):
        """logical xor with another signal."""
        cdef fs.Signal s = fs.sigXOR(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    # TODO: check sigRem = modulo if this is correct
    def __mod__(self, Signal other):
        """modulo of other Signal"""
        cdef fs.Signal s = fs.sigRem(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    # cdef fs.Signal sig_rem(fs.Signal x, fs.Signal y):
    #     return fs.sigRem(x, y)

    def __lshift__(self, Signal other):
        """bitwise left-shift"""
        cdef fs.Signal s = fs.sigLeftShift(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __rshift__(self, Signal other):
        """bitwise right-shift"""
        cdef fs.Signal s = fs.sigLRightShift(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def abs(self) -> Signal:
        cdef fs.Signal s = fs.sigAbs(self.ptr)
        return Signal.from_ptr(s)

    def acos(self) -> Signal:
        cdef fs.Signal s = fs.sigAcos(self.ptr)
        return Signal.from_ptr(s)

    def tan(self) -> Signal:
        cdef fs.Signal s = fs.sigTan(self.ptr)
        return Signal.from_ptr(s)

    def sqrt(self) -> Signal:
        cdef fs.Signal s = fs.sigSqrt(self.ptr)
        return Signal.from_ptr(s)

    def sin(self) -> Signal:
        cdef fs.Signal s = fs.sigSin(self.ptr)
        return Signal.from_ptr(s)

    def rint(self) -> Signal:
        cdef fs.Signal s = fs.sigRint(self.ptr)
        return Signal.from_ptr(s)

    def log(self) -> Signal:
        cdef fs.Signal s = fs.sigLog(self.ptr)
        return Signal.from_ptr(s)

    def log10(self) -> Signal:
        cdef fs.Signal s = fs.sigLog10(self.ptr)
        return Signal.from_ptr(s)

    def floor(self) -> Signal:
        cdef fs.Signal s = fs.sigFloor(self.ptr)
        return Signal.from_ptr(s)

    def exp(self) -> Signal:
        cdef fs.Signal s = fs.sigExp(self.ptr)
        return Signal.from_ptr(s)

    def exp10(self) -> Signal:
        cdef fs.Signal s = fs.sigExp10(self.ptr)
        return Signal.from_ptr(s)

    def cos(self) -> Signal:
        cdef fs.Signal s = fs.sigCos(self.ptr)
        return Signal.from_ptr(s)

    def ceil(self) -> Signal:
        cdef fs.Signal s = fs.sigCeil(self.ptr)
        return Signal.from_ptr(s)

    def atan(self) -> Signal:
        cdef fs.Signal s = fs.sigAtan(self.ptr)
        return Signal.from_ptr(s)

    def asin(self) -> Signal:
        cdef fs.Signal s = fs.sigAsin(self.ptr)
        return Signal.from_ptr(s)




## ---------------------------------------------------------------------------
## faust/dsp/libfaust-signal


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





