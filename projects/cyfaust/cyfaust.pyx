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


def print_box(Box box, bint shared, int max_size) -> str:
    """Print the box.

    box - the box to be printed
    shared - whether the identical sub boxes are printed as identifiers
    max_size - the maximum number of characters to be printed (possibly needed for big expressions in non shared mode)

    returns the printed box as a string
    """
    return fb.printBox(box.ptr, shared, max_size).decode()


def get_def_name_property(Box b) -> Box | None:
    """Returns the identifier (if any) the expression was a definition of.

    b the expression
    id reference to the identifier

    returns the identifier if the expression b was a definition of id
    else returns None
    """
    cdef fb.Box id = NULL
    if fb.getDefNameProperty(b.ptr, id):
        return Box.from_ptr(id)

def extract_name(Box full_label) -> str:
    """Extract the name from a label.

    full_label the label to be analyzed

    returns the extracted name
    """
    return fb.extractName(full_label.ptr).decode()

def create_lib_context():
    """Create global compilation context, has to be done first."""
    fb.createLibContext()

def destroy_lib_context():
    """Destroy global compilation context, has to be done last."""
    fb.destroyLibContext()

cdef void* get_user_data(Box b):
    """Return the xtended type of a box.

    b - the box whose xtended type to return

    returns a pointer to xtended type if it exists, otherwise nullptr.
    """
    return fb.getUserData(b.ptr)

def box_is_nil(Box b) -> bool:
    """Check if a box is nil.

    b - the box

    returns true if the box is nil, otherwise false.
    """
    return fb.isNil(b.ptr)


def tree2str(Box b) -> str:
    """Convert a box (such as the label of a UI) to a string.

    b - the box to convert

    returns a string representation of a box.
    """
    return fb.tree2str(b.ptr).decode()


def tree2int(Box b) -> int:
    """If t has a node of type int, return it. Otherwise error

    b - the box to convert

    returns the int value of the box.
    """
    return fb.tree2int(b.ptr)



def box_int(int n) -> Box:
    """Constant integer : for all t, x(t) = n.

    n - the integer

    returns the integer box.
    """
    cdef fb.Box b = fb.boxInt(n)
    return Box.from_ptr(b)

def box_float(float n) -> Box:
    """Constant real : for all t, x(t) = n.

    n - the float/double value (depends of -single or -double compilation parameter)

    returns the float/double box.
    """
    cdef fb.Box b = fb.boxReal(n)
    return Box.from_ptr(b)


def box_wire() -> Box:
    """The identity box, copy its input to its output.

    returns the identity box.
    """
    cdef fb.Box b = fb.boxWire()
    return Box.from_ptr(b)


def box_cut() -> Box:
    """The cut box, to stop/terminate a signal.

    returns the cut box.
    """
    cdef fb.Box b = fb.boxCut()
    return Box.from_ptr(b)


def box_seq(Box x, Box y) -> Box:
    """The sequential composition of two blocks (e.g., A:B) expects: outputs(A)=inputs(B)

    returns the seq box.
    """
    cdef fb.Box b = fb.boxSeq(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_par(Box x, Box y) -> Box:
    """The parallel composition of two blocks (e.g., A,B).

    It places the two block-diagrams one on top of the other, without connections.

    returns the par box.
    """
    cdef fb.Box b = fb.boxPar(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_par3(Box x, Box y, Box z) -> Box:
    """The parallel composition of three blocks (e.g., A,B,C).
    
    It places the three block-diagrams one on top of the other, without connections.

    returns the par box.    
    """
    cdef fb.Box b = fb.boxPar3(x.ptr, y.ptr, z.ptr)
    return Box.from_ptr(b)


def box_par4(Box a, Box b, Box c, Box d) -> Box:
    """The parallel composition of four blocks (e.g., A,B,C,D).

    It places the four block-diagrams one on top of the other, without connections.

    returns the par box.
    """
    cdef fb.Box p = fb.boxPar4(a.ptr, b.ptr, c.ptr, d.ptr)
    return Box.from_ptr(p)


def box_par5(Box a, Box b, Box c, Box d, Box e) -> Box:
    """The parallel composition of five blocks (e.g., A,B,C,D,E).

    It places the five block-diagrams one on top of the other, without connections.

    returns the par box.
    """
    cdef fb.Box p = fb.boxPar5(a.ptr, b.ptr, c.ptr, d.ptr, e.ptr)
    return Box.from_ptr(p)

def box_split(Box x, Box y) -> Box:
    """The split composition (e.g., A<:B) operator is used to distribute
    the outputs of A to the inputs of B.

    For the operation to be valid, the number of inputs of B
    must be a multiple of the number of outputs of A: outputs(A).k=inputs(B)

    returns the split box.
    """
    cdef fb.Box b = fb.boxSplit(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_merge(Box x, Box y) -> Box:
    """The merge composition (e.g., A:>B) is the dual of the split composition.

    The number of outputs of A must be a multiple of the number of inputs of B: outputs(A)=k.inputs(B)

    returns the merge box.
    """
    cdef fb.Box b = fb.boxMerge(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_rec(Box x, Box y) -> Box:
    """The recursive composition (e.g., A~B) is used to create cycles in the block-diagram
    in order to express recursive computations.

    It is the most complex operation in terms of connections: outputs(A)≥inputs(B) and inputs(A)≥outputs(B)

    returns the rec box.
    """
    cdef fb.Box b = fb.boxRec(x.ptr, y.ptr)
    return Box.from_ptr(b)

def box_route(Box n, Box m, Box r) -> Box:
    """The route primitive facilitates the routing of signals in Faust.

    It has the following syntax: route(A,B,a,b,c,d,...) or route(A,B,(a,b),(c,d),...)

    n -  the number of input signals
    m -  the number of output signals
    r - the routing description, a 'par' expression of a,b / (a,b) input/output pairs

    returns the route box.
    """
    cdef fb.Box b = fb.boxRoute(n.ptr, m.ptr, r.ptr)
    return Box.from_ptr(b)


def box_delay0() -> Box:
    """Create a delayed box.

    returns the delayed box.
    """
    cdef fb.Box b = fb.boxDelay()
    return Box.from_ptr(b)


def box_delay(Box b, Box d) -> Box:
    """Create a delayed box.

    s - the box to be delayed
    d - the delay box that doesn't have to be fixed but must be bounded and cannot be negative

    returns the delayed box.
    """
    cdef fb.Box _b = fb.boxDelay(b.ptr, d.ptr)
    return Box.from_ptr(_b)


def box_int_cast0() -> Box:
    """Create a casted box.

    returns the casted box.
    """
    cdef fb.Box _b = fb.boxIntCast()
    return Box.from_ptr(_b)


def box_int_cast(Box b) -> Box:
    """Create a casted box.

    s - the box to be casted in integer

    returns the casted box.
    """
    cdef fb.Box _b = fb.boxIntCast(b.ptr)
    return Box.from_ptr(_b)


def box_float_cast0() -> Box:
    """Create a casted box."""
    cdef fb.Box _b = fb.boxFloatCast()
    return Box.from_ptr(_b)


def box_float_cast(Box b) -> Box:
    """Create a casted box.

    s - the signal to be casted as float/double value (depends of -single or -double compilation parameter)

    returns the casted box.
    """
    cdef fb.Box _b = fb.boxFloatCast(b.ptr)
    return Box.from_ptr(_b)


def box_readonly_table0() -> Box:
    """Create a read only table.

    returns the table box.
    """
    cdef fb.Box b = fb.boxReadOnlyTable()
    return Box.from_ptr(b)


def box_readonly_table(Box n, Box init, Box ridx) -> Box:
    """Create a read only table.

    n - the table size, a constant numerical expression (see [1])
    init - the table content
    ridx - the read index (an int between 0 and n-1)

    returns the table box.
    """
    cdef fb.Box b = fb.boxReadOnlyTable(n.ptr, init.ptr, ridx.ptr)
    return Box.from_ptr(b)

def box_write_read_table0() -> Box:
    """Create a read/write table.
    
    returns the table box.
    """
    cdef fb.Box b = fb.boxWriteReadTable()
    return Box.from_ptr(b)

def box_write_read_table(Box n, Box init, Box widx, Box wsig, Box ridx) -> Box:
    """Create a read/write table.

    n - the table size, a constant numerical expression (see [1])
    init - the table content
    widx - the write index (an integer between 0 and n-1)
    wsig - the input of the table
    ridx - the read index (an integer between 0 and n-1)

    returns the table box.
    """
    cdef fb.Box b = fb.boxWriteReadTable(n.ptr, init.ptr, widx.ptr, wsig.ptr, ridx.ptr)
    return Box.from_ptr(b)


def box_waveform(SignalVector wf):
    """Create a waveform.

    wf - the content of the waveform as a vector of boxInt or boxDouble boxes

    returns the waveform box.
    """
    cdef fb.Box b = fb.boxWaveform(<const fs.tvec>wf.ptr)
    return Box.from_ptr(b)


def box_soundfile(str label, Box chan) -> Box:
    """Create a soundfile block.

    label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
    chan - the number of outputs channels, a constant numerical expression (see [1])

    returns the soundfile box.
    """
    cdef fb.Box b = fb.boxSoundfile(label.encode('utf8'), chan.ptr)
    return Box.from_ptr(b)


def box_soundfile2(str label, Box chan, Box part, Box ridx) -> Box:
    """Create a soundfile block.

    label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
    chan - the number of outputs channels, a constant numerical expression (see [1])
    part - in the [0..255] range to select a given sound number, a constant numerical expression (see [1])
    ridx - the read index (an integer between 0 and the selected sound length)

    returns the soundfile box.
    """
    cdef fb.Box b = fb.boxSoundfile(label.encode('utf8'), chan.ptr, part.ptr, ridx.ptr)
    return Box.from_ptr(b)


def box_select2(Box selector, Box b1, Box b2) -> Box:
    """Create a selector between two boxes.

    selector - when 0 at time t returns s1[t], otherwise returns s2[t]
    s1 - first box to be selected
    s2 - second box to be selected

    returns the selected box depending of the selector value at each time t.
    """
    cdef fb.Box b = fb.boxSelect2(selector.ptr, b1.ptr, b2.ptr)
    return Box.from_ptr(b)


def box_select2_() -> Box:
    """Create a selector between two boxes.

    returns the selected box depending of the selector value at each time t.
    """
    cdef fb.Box b = fb.boxSelect2()
    return Box.from_ptr(b)


def box_select3(Box selector, Box b1, Box b2, Box b3) -> Box:
    """Create a selector between three boxes.

    selector - when 0 at time t returns s1[t], when 1 at time t returns s2[t], otherwise returns s3[t]
    s1 - first box to be selected
    s2 - second box to be selected
    s3 - third box to be selected

    returns the selected box depending of the selector value at each time t.
    """
    cdef fb.Box b = fb.boxSelect3(selector.ptr, b1.ptr, b2.ptr, b3.ptr)
    return Box.from_ptr(b)

def box_fconst(fb.SType type, str name, str file) -> Box:
    """Create a foreign constant box.

    type - the foreign constant type of SType
    name - the foreign constant name
    file - the include file where the foreign constant is defined

    returns the foreign constant box.
    """
    cdef fb.Box b = fb.boxFConst(type, name, file)
    return Box.from_ptr(b)

def box_fvar(fb.SType type, str name, str file) -> Box:
    """Create a foreign variable box.

    type - the foreign variable type of SType
    name - the foreign variable name
    file - the include file where the foreign variable is defined

    returns the foreign variable box.
    """
    cdef fb.Box b = fb.boxFVar(type, name, file)
    return Box.from_ptr(b)

def box_bin_op0(fb.SOperator op) -> Box:
    """Generic binary mathematical functions.

    op - the operator in SOperator set

    returns the result box of op(x,y).
    """
    cdef fb.Box b = fb.boxBinOp(op)
    return Box.from_ptr(b)

def box_bin_op(fb.SOperator op, Box b1, Box b2) -> Box:
    """Generic binary mathematical functions.

    op - the operator in SOperator set

    returns the result box of op(x,y).
    """
    cdef fb.Box b = fb.boxBinOp(op, b1.ptr, b2.ptr)
    return Box.from_ptr(b)




def box_add_op() -> Box:
    cdef fb.Box b = fb.boxAdd()
    return Box.from_ptr(b)

def box_add(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxAdd(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_sub_op() -> Box:
    cdef fb.Box b = fb.boxSub()
    return Box.from_ptr(b)

def box_sub(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxSub(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_mul_op() -> Box:
    cdef fb.Box b = fb.boxMul()
    return Box.from_ptr(b)

def box_mul(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxMul(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_div_op() -> Box:
    cdef fb.Box b = fb.boxDiv()
    return Box.from_ptr(b)

def box_div(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxDiv(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_rem_op() -> Box:
    cdef fb.Box b = fb.boxRem()
    return Box.from_ptr(b)

def box_rem(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxRem(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_leftshift_op() -> Box:
    cdef fb.Box b = fb.boxLeftShift()
    return Box.from_ptr(b)

def box_leftshift(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxLeftShift(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_lrightshift_op() -> Box:
    cdef fb.Box b = fb.boxLRightShift()
    return Box.from_ptr(b)

def box_lrightshift(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxLRightShift(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_arightshift_op() -> Box:
    cdef fb.Box b = fb.boxARightShift()
    return Box.from_ptr(b)

def box_arightshift(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxARightShift(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_gt_op() -> Box:
    cdef fb.Box b = fb.boxGT()
    return Box.from_ptr(b)

def box_gt(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxGT(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_lt_op() -> Box:
    cdef fb.Box b = fb.boxLT()
    return Box.from_ptr(b)

def box_lt(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxLT(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_ge_op() -> Box:
    cdef fb.Box b = fb.boxGE()
    return Box.from_ptr(b)

def box_ge(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxGE(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_le_op() -> Box:
    cdef fb.Box b = fb.boxLE()
    return Box.from_ptr(b)

def box_le(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxLE(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_eq_op() -> Box:
    cdef fb.Box b = fb.boxEQ()
    return Box.from_ptr(b)

def box_eq(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxEQ(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_ne_op() -> Box:
    cdef fb.Box b = fb.boxNE()
    return Box.from_ptr(b)

def box_ne(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxNE(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_and_op() -> Box:
    cdef fb.Box b = fb.boxAND()
    return Box.from_ptr(b)

def box_and(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxAND(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_or_op() -> Box:
    cdef fb.Box b = fb.boxOR()
    return Box.from_ptr(b)

def box_or(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxOR(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_xor_op() -> Box:
    cdef fb.Box b = fb.boxXOR()
    return Box.from_ptr(b)

def box_xor(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxXOR(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_remainder_op() -> Box:
    cdef fb.Box b = fb.boxRemainder()
    return Box.from_ptr(b)

def box_remainder(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxRemainder(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_pow_op() -> Box:
    cdef fb.Box b = fb.boxPow()
    return Box.from_ptr(b)

def box_pow(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxPow(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_min_op() -> Box:
    cdef fb.Box b = fb.boxMin()
    return Box.from_ptr(b)

def box_min(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxMin(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_max_op() -> Box:
    cdef fb.Box b = fb.boxMax()
    return Box.from_ptr(b)

def box_max(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxMax(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_fmod_op() -> Box:
    cdef fb.Box b = fb.boxFmod()
    return Box.from_ptr(b)

def box_fmod(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxFmod(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_atan2_op() -> Box:
    cdef fb.Box b = fb.boxAtan2()
    return Box.from_ptr(b)

def box_atan2(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxAtan2(b1.ptr, b2.ptr)
    return Box.from_ptr(b)


def box_button(str label) -> Box:
    """Create a button box.

    label - the label definition (see [2])

    returns the button box.
    """
    cdef fb.Box b = fb.boxButton(label.encode('utf8'))
    return Box.from_ptr(b)


def box_checkbox(str label) -> Box:
    """Create a checkbox box.

    label - the label definition (see [2])

    returns the checkbox box.
    """
    cdef fb.Box b = fb.boxCheckbox(label.encode('utf8'))
    return Box.from_ptr(b)


def box_vslider(str label, Box init, Box min, Box max, Box step) -> Box:
    """Create a vertical slider box.

    label - the label definition (see [2])
    init - the init box, a constant numerical expression (see [1])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    step - the step box, a constant numerical expression (see [1])

    returns the vertical slider box.
    """
    cdef fb.Box b = fb.boxVSlider(label.encode('utf8'), init.ptr, min.ptr, max.ptr, step.ptr)
    return Box.from_ptr(b)

def box_hslider(str label, Box init, Box min, Box max, Box step) -> Box:
    """Create an horizontal slider box.

    label - the label definition (see [2])
    init - the init box, a constant numerical expression (see [1])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    step - the step box, a constant numerical expression (see [1])

    returns the horizontal slider box.
    """
    cdef fb.Box b = fb.boxHSlider(label.encode('utf8'), init.ptr, min.ptr, max.ptr, step.ptr)
    return Box.from_ptr(b)

def box_numentry(str label, Box init, Box min, Box max, Box step) -> Box:
    """Create a num entry box.

    label - the label definition (see [2])
    init - the init box, a constant numerical expression (see [1])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    step - the step box, a constant numerical expression (see [1])

    returns the num entry box.
    """
    cdef fb.Box b = fb.boxNumEntry(label.encode('utf8'), init.ptr, min.ptr, max.ptr, step.ptr)
    return Box.from_ptr(b)


def box_vbargraph(str label, Box min, Box max) -> Box:
    """Create a vertical bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    x - the input box

    returns the vertical bargraph box.
    """
    cdef fb.Box b = fb.boxVBargraph(label.encode('utf8'), min.ptr, max.ptr)
    return Box.from_ptr(b)

def box_vbargraph2(str label, Box min, Box max, Box x) -> Box:
    """Create a vertical bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    x - the input box

    returns the vertical bargraph box.
    """
    cdef fb.Box b = fb.boxVBargraph(label.encode('utf8'), min.ptr, max.ptr, x.ptr)
    return Box.from_ptr(b)

def box_hbargraph(str label, Box min, Box max) -> Box:
    """Create a horizontal bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    x - the input box

    returns the horizontal bargraph box.
    """
    cdef fb.Box b = fb.boxHBargraph(label.encode('utf8'), min.ptr, max.ptr)
    return Box.from_ptr(b)

def box_hbargraph2(str label, Box min, Box max, Box x) -> Box:
    """Create a horizontal bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    x - the input box

    returns the horizontal bargraph box.
    """
    cdef fb.Box b = fb.boxHBargraph(label.encode('utf8'), min.ptr, max.ptr, x.ptr)
    return Box.from_ptr(b)


def box_vgroup(str label, Box group) -> Box:
    """Create a vertical group box.

    label - the label definition (see [2])
    group - the group to be added

    returns the vertical group box.
    """
    cdef fb.Box b = fb.boxVGroup(label.encode('utf8'), group.ptr)
    return Box.from_ptr(b)


def box_hgroup(str label, Box group) -> Box:
    """Create a horizontal group box.

    label - the label definition (see [2])
    group - the group to be added

    returns the horizontal group box.
    """
    cdef fb.Box b = fb.boxHGroup(label.encode('utf8'), group.ptr)
    return Box.from_ptr(b)

def box_tgroup(str label, Box group) -> Box:
    """Create a tab group box.

    label - the label definition (see [2])
    group - the group to be added

    returns the tab group box.
    """
    cdef fb.Box b = fb.boxTGroup(label.encode('utf8'), group.ptr)
    return Box.from_ptr(b)

def box_attach_op() -> Box:
    """Create an attach box.

    returns the attach box.
    """
    cdef fb.Box b = fb.boxAttach()
    return Box.from_ptr(b)


def box_attach(Box b1, Box b2) -> Box:
    """Create an attach box.

    The attach primitive takes two input boxes and produces one output box
    which is a copy of the first input. The role of attach is to force
    its second input boxes to be compiled with the first one.

    returns the attach box.
    """
    cdef fb.Box b = fb.boxAttach(b1.ptr, b2.ptr)
    return Box.from_ptr(b)


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



## ---------------------------------------------------------------------------
## faust/dsp/libfaust-signal
##

include "faust_signal.pxi"


