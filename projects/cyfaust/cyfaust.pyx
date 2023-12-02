# distutils: language = c++

from libc.stdlib cimport malloc, free
from libcpp.string cimport string
from libcpp.vector cimport vector

cimport faust_interp as fi


## ---------------------------------------------------------------------------
## python c-api functions
##

cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)

## ---------------------------------------------------------------------------
## utility classes / functions
##

cdef class ParamArray:
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
## faust/dsp/interpreter-dsp


def get_version():
    """Get the version of the library.

    returns the library version as a static string.
    """
    return fi.getCLibFaustVersion().decode()


cdef class InterpreterDspFactory:
    cdef fi.interpreter_dsp_factory* ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            delete_interpreter_dsp_factory(self.ptr)

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

    @staticmethod
    def from_sha(str sha_key) -> InterpreterDspFactory:
        """create an interpreter dsp factory from a sha key"""
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        factory.ptr_owner = True
        factory.ptr = <dsp_factory*>get_interpreter_dsp_factory_from_sha_key(sha_key)
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
        factory.ptr = <dsp_factory*>create_interpreter_dsp_factory_from_file(
            filepath.encode('utf8'),
            params.argc,
            params.argv,
            error_msg,
        )
        if error_msg.empty():
            print(error_msg.decode())
            return
        return factory

    @staticmethod
    def from_string(str name_app, str code, str args) -> InterpreterDspFactory:
        """create an interpreter dsp factory from a string"""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        cdef ParamArray params = ParamArray(args)
        factory.ptr_owner = True
        factory.ptr = <dsp_factory*>create_interpreter_dsp_factory_from_string(
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


cdef class InterpreterDsp:
    cdef fi.interpreter_dsp* ptr
    cdef bint ptr_owner

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            del self.ptr

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

    cdef build_user_interface(self, fi.UI* ui_interface):
        """Trigger the ui_interface parameter with instance specific calls."""
        self.ptr.buildUserInterface(ui_interface)

    cdef metadata(self, fi.Meta* m):
        """Trigger the meta parameter with instance specific calls."""
        self.ptr.metadata(m)


ctypedef fi.interpreter_dsp_factory dsp_factory

cdef dsp_factory* get_interpreter_dsp_factory_from_sha_key(str sha_key):
    """Get the Faust DSP factory associated with a given SHA key."""
    return fi.getInterpreterDSPFactoryFromSHAKey(sha_key.encode())

cdef dsp_factory* create_interpreter_dsp_factory_from_file(
        const string& filename, int argc, const char* argv[], string& error_msg):
    """Create a Faust DSP factory from a DSP source code as a file."""
    return fi.createInterpreterDSPFactoryFromFile(
        filename, argc, argv, error_msg)

cdef dsp_factory* create_interpreter_dsp_factory_from_string(
        const string& name_app, const string& dsp_content, int argc, const char* argv[], string& error_msg):
    """Create a Faust DSP factory from a DSP source code as a string."""
    return fi.createInterpreterDSPFactoryFromString(
        name_app, dsp_content, argc, argv, error_msg)

cdef dsp_factory* create_interpreter_dsp_factory_from_signals(
        const string& name_app, fi.tvec signals, int argc, const char* argv[], string& error_msg):
    """Create a Faust DSP factory from a vector of output signals."""
    return fi.createInterpreterDSPFactoryFromSignals(
        name_app, signals, argc, argv, error_msg)

cdef dsp_factory* create_interpreter_dsp_factory_from_boxes(
        const string& name_app, fi.Box box, int argc, const char* argv[], string& error_msg):
    """Create a Faust DSP factory from a box expression.
    """
    return fi.createInterpreterDSPFactoryFromBoxes(
        name_app, box, argc, argv, error_msg)

cdef bint delete_interpreter_dsp_factory(dsp_factory* factory):
    """Delete a Faust DSP factory.
    """
    return fi.deleteInterpreterDSPFactory(factory)

cdef void delete_all_interpreter_dsp_factories():
    """Delete all Faust DSP factories kept in the library cache.
    """
    fi.deleteAllInterpreterDSPFactories()

cdef vector[string] get_all_interpreter_dsp_factories():
    """Return Faust DSP factories of the library cache as a vector of their SHA keys.
    """
    return fi.getAllInterpreterDSPFactories()

cdef bint start_multithreaded_access_mode():
    """Start multi-thread access mode
    """
    return fi.startMTDSPFactories()

cdef void stop_multithreaded_access_mode():
    """Stop multi-thread access mode.
    """
    fi.stopMTDSPFactories()

cdef dsp_factory* read_interpreter_dsp_factory_from_bitcode(const string& bitcode, string& error_msg):
    """Create a Faust DSP factory from a bitcode string.
    """
    return fi.readInterpreterDSPFactoryFromBitcode(bitcode, error_msg)
    
cdef string write_interpreter_dsp_factory_to_bitcode(dsp_factory* factory):
    """Write a Faust DSP factory into a bitcode string.
    """
    return fi.writeInterpreterDSPFactoryToBitcode(factory)

cdef dsp_factory* read_dsp_factory_from_bitcode_file(const string& bit_code_path, string& error_msg):
    """Create a Faust DSP factory from a bitcode file.
    """
    return fi.readInterpreterDSPFactoryFromBitcodeFile(bit_code_path, error_msg)

cdef bint write_interpreter_dsp_factory_to_bitcode_file(dsp_factory* factory, const string& bit_code_path):
    """Write a Faust DSP factory into a bitcode file.
    """
    return fi.writeInterpreterDSPFactoryToBitcodeFile(factory, bit_code_path)

