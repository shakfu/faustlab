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
## common utility classes / functions
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



## ---------------------------------------------------------------------------
## faust/dsp/libfaust
##

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
##

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
##


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
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        cdef ParamArray params = ParamArray(args)
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
##

include "faust_box.pxi"



## ---------------------------------------------------------------------------
## faust/dsp/libfaust-signal
##

# include "faust_signal.pxi"

class signal_context:
    def __enter__(self):
        # Create global compilation context, has to be done first.
        fs.createLibContext()
    def __exit__(self, type, value, traceback):
        # Destroy global compilation context, has to be done last.
        fs.destroyLibContext()


cdef class SignalVector:
    """wraps tvec: a std::vector<CTree*>"""
    cdef vector[fs.Signal] ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr_owner = False

    def __iter__(self):
        for i in self.ptr:
            yield Signal.from_ptr(i)

    @staticmethod
    cdef SignalVector from_ptr(fs.tvec ptr):
        """Wrap a fs.tvec instance."""
        cdef SignalVector sv = SignalVector.__new__(SignalVector)
        sv.ptr = ptr
        return sv

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

    def simplify_to_normal_form(self):
        """Simplify a signal list to its normal form."""
        cdef fs.tvec sv = fs.simplifyToNormalForm2(self.ptr)
        return SignalVector.from_ptr(sv)


cdef class Interval:
    """wraps fs.Interval struct/class"""
    cdef fs.Interval *ptr

    def __dealloc__(self):
        if self.ptr:
            del self.ptr

    def __cinit__(self, double lo, double hi, int lsb):
        self.ptr = new fs.Interval(lo, hi, lsb)

    @staticmethod
    cdef Interval from_ptr(fs.Interval* ptr):
        """Wrap Interval from pointer"""
        cdef Interval ival = Interval.__new__(Interval)
        ival.ptr = ptr
        return ival

    @property
    def low(self) -> float:
        return self.ptr.fLo

    @property
    def high(self) -> float:
        return self.ptr.fHi

    @property
    def lsb(self) -> float:
        return self.ptr.fLSB


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

    @staticmethod
    def from_soundfile(str label) -> Signal:
        """Create signal from soundfile."""
        cdef fs.Signal s = fs.sigSoundfile(label.encode("utf8"))
        return Signal.from_ptr(s)

    @staticmethod
    def from_button(str label) -> Signal:
        """Create a button signal."""
        cdef fs.Signal s = fs.sigButton(label.encode('utf8'))
        return Signal.from_ptr(s)

    @staticmethod
    def from_checkbox(str label) -> Signal:
        """Create a checkbox signal."""
        cdef fs.Signal s = fs.sigCheckbox(label.encode('utf8'))
        return Signal.from_ptr(s)

    @staticmethod
    def from_vslider(str label, float init, float min, float max, float step) -> Signal:
        """Create a vertical slider signal."""
        cdef fs.Signal s = fs.sigVSlider(
            label.encode('utf8'), 
            fs.sigReal(init), 
            fs.sigReal(min),
            fs.sigReal(max), 
            fs.sigReal(step))
        return Signal.from_ptr(s)

    @staticmethod
    def from_hslider(str label, float init, float min, float max, float step) -> Signal:
        """Create a horizontal slider signal."""
        cdef fs.Signal s = fs.sigHSlider(
            label.encode('utf8'), 
            fs.sigReal(init), 
            fs.sigReal(min),
            fs.sigReal(max), 
            fs.sigReal(step))
        return Signal.from_ptr(s)

    @staticmethod
    def from_numentry(str label, float init, float min, float max, float step) -> Signal:
        """Create a num entry signal."""
        cdef fs.Signal s = fs.sigNumEntry(
            label.encode('utf8'), 
            fs.sigReal(init), 
            fs.sigReal(min),
            fs.sigReal(max), 
            fs.sigReal(step))
        return Signal.from_ptr(s)

    @staticmethod
    def from_read_only_table(int n, Signal init, int ridx):
        """Create a read-only table.

        n - the table size, a constant numerical expression (see [1])
        init - the table content
        ridx - the read index (an int between 0 and n-1)
     
        returns the table signal.
        """
        cdef fs.Signal s = fs.sigReadOnlyTable(
            fs.sigInt(n),
            init.ptr, 
            fs.sigInt(init))
        return Signal.from_ptr(s)

    @staticmethod
    def from_write_read_table(int n, Signal init, int widx, Signal wsig, int ridx):
        """Create a read-write-only table.

        n - the table size, a constant numerical expression (see [1])
        init - the table content
        widx - the write index (an integer between 0 and n-1)
        wsig - the input of the table
        ridx - the read index (an int between 0 and n-1)
     
        returns the table signal.
        """
        cdef fs.Signal s = fs.sigWriteReadTable(
            fs.sigInt(n),
            init.ptr,
            fs.sigInt(widx),
            wsig.ptr,
            fs.sigInt(ridx),
        )
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

    def simplify_to_normal_form(self) -> Signal:
        """Simplify a signal to its normal form."""
        cdef fs.Signal s = fs.simplifyToNormalForm(self.ptr)
        return Signal.from_ptr(s)

    def print(self, shared: bool = False, max_size: int = 256):
        """Print this signal."""
        print(fs.printSignal(self.ptr, shared, max_size).decode())

    def ffname(self, Signal s) -> str:
        """Return the name parameter of a foreign function."""
        return fs.ffname(self.ptr).decode()

    def ffarity(self, Signal s) -> int:
        """Return the arity of a foreign function."""
        return fs.ffarity(self.ptr)

    # def get_interval(self) -> Interval:
    #     """Get the signal interval."""
    #     cdef fs.Interval ival = <fs.Interval>fs.getSigInterval(self.ptr)
    #     return Interval.from_ptr(&ival)

    # def set_interval(self, Interval iv):
    #     """Set the signal interval."""
    #     fs.setSigInterval(self.ptr, iv.ptr)

    def attach(self, Signal other) -> Signal:
        """Create an attached signal from another signal
        
        The attach primitive takes two input signals and produces 
        one output signal which is a copy of the first input.

        The role of attach is to force the other input signal to be 
        compiled with this one.
        """
        cdef fs.Signal s = fs.sigAttach(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def vbargraph(self, str label, float min, float max) -> Signal:
        """Create a vertical bargraph signal from this signal"""
        cdef fs.Signal s = fs.sigVBargraph(
            label.encode('utf8'), 
            fs.sigReal(min),
            fs.sigReal(max), 
            self.ptr)
        return Signal.from_ptr(s)

    def hbargraph(self, str label, float min, float max) -> Signal:
        """Create a horizontal bargraph signal from this signal"""
        cdef fs.Signal s = fs.sigHBargraph(
            label.encode('utf8'), 
            fs.sigReal(min),
            fs.sigReal(max), 
            self.ptr)
        return Signal.from_ptr(s)

    def __add__(self, Signal other) -> Signal:
        """Add this signal to another."""
        cdef fs.Signal b = fs.sigAdd(self.ptr, other.ptr)
        return Signal.from_ptr(b)

    def __radd__(self, Signal other) -> Signal:
        """Reverse add this signal to another."""
        cdef fs.Signal b = fs.sigAdd(self.ptr, other.ptr)
        return Signal.from_ptr(b)

    def __sub__(self, Signal other) -> Signal:
        """Subtract this box from another."""
        cdef fs.Signal s = fs.sigSub(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __rsub__(self, Signal other) -> Signal:
        """Subtract this box from another."""
        cdef fs.Signal s = fs.sigSub(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __mul__(self, Signal other) -> Signal:
        """Multiply this box with another."""
        cdef fs.Signal s = fs.sigMul(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __rmul__(self, Signal other) -> Signal:
        """Reverse multiply this box with another."""
        cdef fs.Signal s = fs.sigMul(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __div__(self, Signal other) -> Signal:
        """Divide this box with another."""
        cdef fs.Signal s = fs.sigDiv(self.ptr, other.ptr)
        return Signal.from_ptr(s)

    def __rdiv__(self, Signal other) -> Signal:
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

    def delay(self, int d) -> Signal:
        cdef fs.Signal s = fs.sigDelay(self.ptr, fs.sigInt(d))
        return Signal.from_ptr(s)

    # def delay(self, Signal d) -> Signal:
    #     cdef fs.Signal s = fs.sigDelay(self.ptr, d.ptr)
    #     return Signal.from_ptr(s)

    def int_cast(self) -> Signal:
        cdef fs.Signal s = fs.sigIntCast(self.ptr)
        return Signal.from_ptr(s)

    def float_cast(self) -> Signal:
        cdef fs.Signal s = fs.sigFloatCast(self.ptr)
        return Signal.from_ptr(s)

    def recursion(self) -> Signal:
        cdef fs.Signal s = fs.sigRecursion(self.ptr)
        return Signal.from_ptr(s)

    def remainder(self, Signal y) -> Signal:
        cdef fs.Signal s = fs.sigRemainder(self.ptr, y.ptr)        
        return Signal.from_ptr(s)

    def pow(self, Signal y) -> Signal:
        cdef fs.Signal s = fs.sigPow(self.ptr, y.ptr)        
        return Signal.from_ptr(s)

    def min(self, Signal y) -> Signal:
        cdef fs.Signal s = fs.sigMin(self.ptr, y.ptr)        
        return Signal.from_ptr(s)

    def max(self, Signal y) -> Signal:
        cdef fs.Signal s = fs.sigMax(self.ptr, y.ptr)        
        return Signal.from_ptr(s)

    def fmod(self, Signal y) -> Signal:
        cdef fs.Signal s = fs.sigFmod(self.ptr, y.ptr)        
        return Signal.from_ptr(s)

    def atan(self, Signal y) -> Signal:
        cdef fs.Signal s = fs.sigAtan2(self.ptr, y.ptr)        
        return Signal.from_ptr(s)

    def is_int(self) -> bool:
        cdef int i
        return fs.isSigInt(self.ptr, &i)

    def is_float(self) -> bool:
        cdef double f
        return fs.isSigReal(self.ptr, &f)

    def is_input(self) -> bool:
        cdef int i
        return fs.isSigInput(self.ptr, &i)

    def is_output(self) -> bool:
        cdef int i
        cdef fs.Signal t0 = NULL
        return fs.isSigOutput(self.ptr, &i, t0)

    def is_delay1(self) -> bool:
        cdef fs.Signal t0 = NULL
        return fs.isSigDelay1(self.ptr, t0)

    def is_delay(self) -> bool:
        cdef fs.Signal t0 = NULL
        cdef fs.Signal t1 = NULL
        return fs.isSigDelay(self.ptr, t0, t1)

    def is_prefix(self) -> bool:
        cdef fs.Signal t0 = NULL
        cdef fs.Signal t1 = NULL
        return fs.isSigPrefix(self.ptr, t0, t1)

    def is_read_table(self) -> bool:
        cdef fs.Signal t = NULL
        cdef fs.Signal i = NULL
        return fs.isSigRDTbl(self.ptr, t, t)

    def is_write_table(self) -> bool:
        cdef fs.Signal id = NULL
        cdef fs.Signal t = NULL
        cdef fs.Signal i = NULL
        cdef fs.Signal s = NULL
        return fs.isSigWRTbl(self.ptr, id, t, i, s)

    def is_gen(self) -> bool:
        cdef fs.Signal x = NULL
        return fs.isSigGen(self.ptr, x)

    def is_doc_constant_tbl(self) -> bool:
        cdef fs.Signal n = NULL
        cdef fs.Signal sig = NULL
        return fs.isSigDocConstantTbl(self.ptr, n, sig)

    def is_doc_write_tbl(self) -> bool:
        cdef fs.Signal n = NULL
        cdef fs.Signal sig = NULL
        cdef fs.Signal widx = NULL
        cdef fs.Signal wsig = NULL
        return fs.isSigDocWriteTbl(self.ptr, n, sig, widx, wsig)

    def is_doc_access_tbl(self) -> bool:
        cdef fs.Signal tbl = NULL
        cdef fs.Signal ridx = NULL
        return fs.isSigDocAccessTbl(self.ptr, tbl, ridx)

    def is_select2(self) -> bool:
        cdef fs.Signal selector = NULL
        cdef fs.Signal s1 = NULL
        cdef fs.Signal s2 = NULL
        return fs.isSigSelect2(self.ptr, selector, s1, s2)

    def is_assert_bounds(self) -> bool:
        cdef fs.Signal s1 = NULL
        cdef fs.Signal s2 = NULL
        cdef fs.Signal s3 = NULL
        return fs.isSigAssertBounds(self.ptr, s1, s2, s3)

    def is_highest(self) -> bool:
        cdef fs.Signal s = NULL
        return fs.isSigHighest(self.ptr, s)

    def is_lowest(self) -> bool:
        cdef fs.Signal s = NULL
        return fs.isSigLowest(self.ptr, s)

    def is_bin_op(self) -> bool:
        cdef int op = 0
        cdef fs.Signal x = NULL
        cdef fs.Signal y = NULL
        return fs.isSigBinOp(self.ptr, &op, x, y)

    def is_ffun(self) -> bool:
        cdef fs.Signal ff = NULL
        cdef fs.Signal largs = NULL
        return fs.isSigFFun(self.ptr, ff, largs)

    def is_fconst(self) -> bool:
        cdef fs.Signal type = NULL
        cdef fs.Signal name = NULL
        cdef fs.Signal file = NULL
        return fs.isSigFConst(self.ptr, type, name, file)

    def is_fvar(self) -> bool:
        cdef fs.Signal type = NULL
        cdef fs.Signal name = NULL
        cdef fs.Signal file = NULL
        return fs.isSigFVar(self.ptr, type, name, file)

    def is_proj(self) -> bool:
        cdef int i = 0
        cdef fs.Signal rgroup = NULL
        return fs.isProj(self.ptr, &i, rgroup)

    def is_rec(self) -> bool:
        cdef fs.Signal var = NULL
        cdef fs.Signal body = NULL
        return fs.isRec(self.ptr, var, body)

    def is_int_cast(self) -> bool:
        cdef fs.Signal x = NULL
        return fs.isSigIntCast(self.ptr, x)

    def is_float_cast(self) -> bool:
        cdef fs.Signal x = NULL
        return fs.isSigFloatCast(self.ptr, x)

    def is_button(self) -> bool:
        cdef fs.Signal lbl = NULL
        return fs.isSigButton(self.ptr, lbl)

    def is_checkbox(self) -> bool:
        cdef fs.Signal lbl = NULL
        return fs.isSigCheckbox(self.ptr, lbl)

    def is_waveform(self) -> bool:
        return fs.isSigWaveform(self.ptr)

    def is_hslider(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal init = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal step = NULL
        return fs.isSigHSlider(self.ptr, lbl, init, min, max, step)

    def is_vslider(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal init = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal step = NULL
        return fs.isSigVSlider(self.ptr, lbl, init, min, max, step)

    def is_num_entry(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal init = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal step = NULL
        return fs.isSigNumEntry(self.ptr, lbl, init, min, max, step)

    def is_hbargraph(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal x = NULL
        return fs.isSigHBargraph(self.ptr, lbl, min, max, x)

    def is_vbargraph(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal x = NULL
        return fs.isSigVBargraph(self.ptr, lbl, min, max, x)

    def is_attach(self) -> bool:
        cdef fs.Signal s0 = NULL
        cdef fs.Signal s1 = NULL
        return fs.isSigAttach(self.ptr, s0, s1)

    def is_enable(self) -> bool:
        cdef fs.Signal s0 = NULL
        cdef fs.Signal s1 = NULL
        return fs.isSigEnable(self.ptr, s0, s1)

    def is_control(self) -> bool:
        cdef fs.Signal s0 = NULL
        cdef fs.Signal s1 = NULL
        return fs.isSigControl(self.ptr, s0, s1)

    def is_soundfile(self) -> bool:
        cdef fs.Signal label = NULL
        return fs.isSigSoundfile(self.ptr, label)

    def is_soundfile_length(self) -> bool:
        cdef fs.Signal sf = NULL
        cdef fs.Signal part = NULL
        return fs.isSigSoundfileLength(self.ptr, sf, part)

    def is_soundfile_rate(self) -> bool:
        cdef fs.Signal sf = NULL
        cdef fs.Signal part = NULL
        return fs.isSigSoundfileLength(self.ptr, sf, part)

    def is_soundfile_buffer(self) -> bool:
        cdef fs.Signal sf = NULL
        cdef fs.Signal chan = NULL
        cdef fs.Signal part = NULL
        cdef fs.Signal ridx = NULL
        return fs.isSigSoundfileBuffer(self.ptr, sf, chan, part, ridx)

## ---------------------------------------------------------------------------
## faust/dsp/libfaust-signal
##


def ffname(Signal s) -> str:
    """Return the name parameter of a foreign function.

    s - the signal
    returns the name
    """
    return fs.ffname(s.ptr).decode()


def ffarity(Signal s) -> int:
    """Return the arity of a foreign function.

    s - the signal
    returns the name
    """
    return fs.ffarity(s.ptr)


def print_signal(Signal sig, bint shared, int max_size) -> str:
    """Print the signal.

    sig - the signal to be printed
    shared - whether the identical sub signals are printed as identifiers
    max_size - the maximum number of characters to be printed (possibly needed for big expressions in non shared mode)

    returns the printed signal as a string
    """
    return fs.printSignal(sig.ptr, shared, max_size).decode()

def create_lib_context():
    """Create global compilation context, has to be done first.
    """
    fs.createLibContext()

def destroy_lib_context():
    """Destroy global compilation context, has to be done last.
    """
    fs.destroyLibContext()

# def get_sig_interval(Signal s) -> Interval:
#     """Get the signal interval.

#     s - the signal

#     returns the signal interval
#     """
#     cdef fs.Interval ival = fs.getSigInterval(s.ptr)
#     return Interval.from_ptr(ival)

# def set_sig_interval(Signal s, Interval inter):
#     """Set the signal interval.

#     s - the signal

#     inter - the signal interval
#     """
#     fs.setSigInterval(s.ptr, inter.ptr)

def is_nil(Signal s) -> bool:
    """Check if a signal is nil.

    s - the signal

    returns true if the signal is nil, otherwise false.
    """
    return fs.isNil(s.ptr)


def tree2str(Signal s):
    """Convert a signal (such as the label of a UI) to a string.

    s - the signal to convert

    returns a string representation of a signal.
    """
    return fs.tree2str(s.ptr).decode()


def xtendedArity(Signal s) -> int:
    """Return the arity of the xtended signal.

    s - the xtended signal

    returns the arity of the xtended signal.
    """
    return fs.xtendedArity(s.ptr)


def xtended_name(Signal s):
    """Return the name of the xtended signal.

    s - the xtended signal

    returns the name of the xtended signal.
    """
    return fs.xtendedName(s.ptr).decode()


def sig_int(int n) -> Signal:
    """Constant integer : for all t, x(t) = n.

    n - the integer

    returns the integer signal.
    """
    cdef fs.Signal s = fs.sigInt(n)
    return Signal.from_ptr(s)


def sig_real(float n) -> Signal:
    """Constant real : for all t, x(t) = n.

    n - the float/double value (depends of -single or -double compilation parameter)

    returns the float/double signal.
    """
    cdef fs.Signal s = fs.sigReal(n)
    return Signal.from_ptr(s)


def sig_input(int idx) -> Signal:
    """
    Create an input.

    idx - the input index

    returns the input signal.
    """
    cdef fs.Signal s = fs.sigInput(idx)
    return Signal.from_ptr(s)


def sig_delay(Signal s, Signal d) -> Signal:
    """
    Create a delayed signal.

    s - the signal to be delayed
    d - the delay signal that doesn't have to be fixed but must be bounded and cannot be negative

    returns the delayed signal.
    """
    cdef fs.Signal _s = fs.sigDelay(s.ptr, d.ptr)
    return Signal.from_ptr(_s)


def sig_delay1(Signal s) -> Signal:
    """Create a one sample delayed signal.

    s - the signal to be delayed

    returns the delayed signal.
    """
    cdef fs.Signal _s = fs.sigDelay1(s.ptr)
    return Signal.from_ptr(_s)


def sig_int_cast(Signal s) -> Signal:
    """Create a casted signal.

    s - the signal to be casted in integer

    returns the casted signal.
    """
    cdef fs.Signal _s = fs.sigIntCast(s.ptr)
    return Signal.from_ptr(_s)


def sig_float_cast(Signal s) -> Signal:
    """Create a casted signal.

    s - the signal to be casted as float/double value (depends of -single or -double compilation parameter)

    returns the casted signal.
    """
    cdef fs.Signal _s = fs.sigFloatCast(s.ptr)
    return Signal.from_ptr(_s)


def sig_readonly_table(Signal n, Signal init, Signal ridx) -> Signal:
    """Create a read only table.

    n - the table size, a constant numerical expression (see [1])
    init - the table content
    ridx - the read index (an int between 0 and n-1)

    returns the table signal.
    """
    cdef fs.Signal s = fs.sigReadOnlyTable(n.ptr, init.ptr, ridx.ptr)
    return Signal.from_ptr(s)


def sig_write_read_table(Signal n, Signal init, Signal widx, Signal wsig, Signal ridx) -> Signal:
    """Create a read/write table.

    n - the table size, a constant numerical expression (see [1])
    init - the table content
    widx - the write index (an integer between 0 and n-1)
    wsig - the input of the table
    ridx - the read index (an integer between 0 and n-1)

    returns the table signal.
    """
    cdef fs.Signal s = fs.sigWriteReadTable(
        n.ptr, init.ptr, widx.ptr, wsig.ptr, ridx.ptr)
    return Signal.from_ptr(s)


def sig_waveform_int(int[:] view not None) -> Signal:
    """Create a waveform from a memoryview of ints

    view - memorview of ints

    returns the waveform signal.
    """
    cdef size_t i, n
    cdef fs.tvec wfv
    n = view.shape[0]
    for i in range(n):
        wfv.push_back(fs.sigInt(view[i]))
    cdef fs.Signal wf = fs.sigWaveform(wfv)
    return Signal.from_ptr(wf)

def sig_waveform_float(float[:] view not None) -> Signal:
    """Create a waveform from a memoryview of floats

    view - memorview of floats

    returns the waveform signal.
    """
    cdef size_t i, n
    cdef fs.tvec wfv
    n = view.shape[0]
    for i in range(n):
        wfv.push_back(fs.sigReal(view[i]))
    cdef fs.Signal wf = fs.sigWaveform(wfv)
    return Signal.from_ptr(wf)


def sig_soundfile(*paths) -> Signal:
    """Create a soundfile block.

    label - of form "label[url:{'path1''path2''path3'}]" 
            to describe a list of soundfiles

    returns the soundfile block.
    """
    ps = "".join(repr(p) for p in paths)
    label = f"label[url:{ps}]"
    cdef fs.Signal s = fs.sigSoundfile(label.encode('utf8'))
    return Signal.from_ptr(s)

def sig_soundfile_length(Signal sf, Signal part) -> Signal:
    """Create the length signal of a given soundfile in frames.

    sf - the soundfile
    part - in the [0..255] range to select a given sound number, 
           a constant numerical expression (see [1])

    returns the soundfile length signal.
    """
    cdef fs.Signal s = fs.sigSoundfileLength(sf.ptr, part.ptr)
    return Signal.from_ptr(s)

def sig_soundfile_rate(Signal sf, Signal part) -> Signal:
    """Create the rate signal of a given soundfile in Hz.

    sf - the soundfile
    part - in the [0..255] range to select a given sound number, a constant numerical expression (see [1])

    returns the soundfile rate signal.
    """
    cdef fs.Signal s = fs.sigSoundfileRate(sf.ptr, part.ptr)
    return Signal.from_ptr(s)


def sig_soundfile_buffer(Signal sf, Signal chan, Signal part, Signal ridx) -> Signal:
    """Create the buffer signal of a given soundfile.

    sf - the soundfile
    chan - an integer to select a given channel, a constant numerical expression (see [1])
    part - in the [0..255] range to select a given sound number, a constant numerical expression (see [1])
    ridx - the read index (an integer between 0 and the selected sound length)

    returns the soundfile buffer signal.
    """
    cdef fs.Signal s = fs.sigSoundfileBuffer(sf.ptr, chan.ptr, part.ptr, ridx.ptr)
    return Signal.from_ptr(s)

def sig_select2(Signal selector, Signal s1, Signal s2) -> Signal:
    """Create a selector between two signals.

    selector - when 0 at time t returns s1[t], otherwise returns s2[t]
    (selector is automatically wrapped with sigIntCast)
    s1 - first signal to be selected
    s2 - second signal to be selected

    returns the selected signal depending of the selector value at each time t.
    """
    cdef fs.Signal s = fs.sigSelect2(selector.ptr, s1.ptr, s2.ptr)
    return Signal.from_ptr(s)


def sig_select3(Signal selector, Signal s1, Signal s2, Signal s3) -> Signal:
    """Create a selector between three signals.

    selector - when 0 at time t returns s1[t], when 1 at time t returns s2[t], otherwise returns s3[t]
    (selector is automatically wrapped with sigIntCast)
    s1 - first signal to be selected
    s2 - second signal to be selected
    s3 - third signal to be selected

    returns the selected signal depending of the selector value at each time t.
    """
    cdef fs.Signal s = fs.sigSelect3(selector.ptr, s1.ptr, s2.ptr, s3.ptr)
    return Signal.from_ptr(s)


def sig_fconst(fs.SType type, str name, str file) -> Signal:
    """Create a foreign constant signal.

    type - the foreign constant type of SType
    name - the foreign constant name
    file - the include file where the foreign constant is defined

    returns the foreign constant signal.
    """
    cdef fs.Signal s = fs.sigFConst(
        type, 
        name.encode('utf8'), 
        file.encode('utf8'))
    return Signal.from_ptr(s)

def sig_fvar(fs.SType type, str name, str file) -> Signal:
    """Create a foreign variable signal.

    type - the foreign variable type of SType
    name - the foreign variable name
    file - the include file where the foreign variable is defined

    returns the foreign variable signal.
    """
    cdef fs.Signal s = fs.sigFVar(
        type, 
        name.encode('utf8'), 
        file.encode('utf8'))
    return Signal.from_ptr(s)


cdef fs.Signal sig_bin_op(fs.SOperator op, fs.Signal x, fs.Signal y):
    return fs.sigBinOp(op, x, y)

cdef fs.Signal sig_self():
    """Create a recursive signal inside the sigRecursion expression.

    return the recursive signal.
    """
    return fs.sigSelf()

cdef fs.Signal sig_recursion(fs.Signal s):
    """Create a recursive signal. 

    Use sigSelf() to refer to the recursive signal 
    inside the sigRecursion expression.
    """
    return fs.sigRecursion(s)


cdef fs.Signal sig_self_n(int id):
    """Create a recursive signal inside the sigRecursionN expression.

    id - the recursive signal index (starting from 0, up to the number
         of outputs signals in the recursive block).

    return the list of signals with recursions.
    """
    return fs.sigSelfN(id)

cdef fs.tvec sig_recursion_n(const fs.tvec& rf):
    """Create a recursive block of signals.

    Use sigSelfN() to refer to the recursive signal
    inside the sigRecursionN expression.
    """
    return fs.sigRecursionN(rf)












