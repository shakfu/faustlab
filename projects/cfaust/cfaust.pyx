# distutils: language = c++

from libc.stdlib cimport malloc, free

cimport faust_interp as fi

## ---------------------------------------------------------------------------
## python c-api functions
##

cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


## ---------------------------------------------------------------------------
## utility functions
##

def get_version():
    """Get the version of the library.

    returns the library version as a static string.
    """
    return fi.getCLibFaustVersion().decode()

## ---------------------------------------------------------------------------
## Extension Classes
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


cdef class InterpreterDspFactory:
    cdef fi.interpreter_dsp_factory* ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            fi.deleteCInterpreterDSPFactory(self.ptr)

    def create_dsp_instance(self) -> InterpreterDsp:
        """Create a new DSP instance.
        """
        cdef fi.interpreter_dsp* dsp = <fi.interpreter_dsp*>fi.createCInterpreterDSPInstance(
            self.ptr
        )
        return InterpreterDsp.from_ptr(dsp)

    def get_library_list(self) -> list[str]:
        """Get the list of library dependancies of the Faust DSP factory.
        """
        cdef const char** libs = fi.getCInterpreterDSPFactoryLibraryList(self.ptr)
        cdef int length = sizeof(libs) // sizeof(libs[0])
        result = []
        for i in range(length):
            result.append(libs[i].decode())
        fi.freeCMemory(libs)
        return result

    def write_to_bitcode(self) -> str:
        """Write a Faust DSP factory into a bitcode string."""
        return fi.writeCInterpreterDSPFactoryToBitcode(self.ptr).decode()

    def write_to_bitcode_file(self, bit_code_path: str) -> bool:
        """Write a Faust DSP factory into a bitcode file."""
        return fi.writeCInterpreterDSPFactoryToBitcodeFile(
            self.ptr, bit_code_path.encode('utf8'))

    @staticmethod
    def from_sha_key(str sha_key) -> InterpreterDspFactory:
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.getCInterpreterDSPFactoryFromSHAKey(
            sha_key.encode('utf8')
        )
        return factory

    @staticmethod
    def from_file(str filepath, *args) -> InterpreterDspFactory:
        cdef char error_msg[4096]
        error_msg[0] = 0
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        cdef ParamArray params = ParamArray(args)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.createCInterpreterDSPFactoryFromFile(
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
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.createCInterpreterDSPFactoryFromString(
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

    @staticmethod
    def from_bitcode(str bitcode) -> InterpreterDspFactory:
        """Create a Faust DSP factory from a bitcode string."""
        cdef char error_msg[4096]
        error_msg[0] = 0
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.readCInterpreterDSPFactoryFromBitcode(
            bitcode.encode('utf8'),
            error_msg,
        )
        if error_msg[0] != 0:
            print(error_msg.decode())
            return
        return factory

    @staticmethod
    def from_bitcode_file(str bit_code_path) -> InterpreterDspFactory:
        """Create a Faust DSP factory from a bitcode file."""
        cdef char error_msg[4096]
        error_msg[0] = 0
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.readCInterpreterDSPFactoryFromBitcodeFile(
            bit_code_path.encode('utf8'),
            error_msg,
        )
        if error_msg[0] != 0:
            print(error_msg.decode())
            return
        return factory


cdef class InterpreterDsp:
    cdef fi.interpreter_dsp* ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False

    def __dealloc__(self):
        if self.ptr is not NULL and self.ptr_owner is True:
            fi.deleteCInterpreterDSPInstance(self.ptr)

    @staticmethod
    cdef InterpreterDsp from_ptr(fi.interpreter_dsp* ptr, bint ptr_owner=False):
        """Wrap the dsp instance and manage its lifetime."""
        cdef InterpreterDsp dsp = InterpreterDsp.__new__(InterpreterDsp)
        dsp.ptr_owner = ptr_owner
        dsp.ptr = ptr
        return dsp

    def get_numinputs(self) -> int:
        return fi.getNumInputsCInterpreterDSPInstance(self.ptr)

    def get_numoutputs(self) -> int:
        return fi.getNumOutputsCInterpreterDSPInstance(self.ptr)

    def get_samplerate(self) -> int:
        return fi.getSampleRateCInterpreterDSPInstance(self.ptr)

    def init(self, int sample_rate):
        fi.instanceInitCInterpreterDSPInstance(self.ptr, sample_rate)

    def constants(self, int sample_rate):
        fi.instanceConstantsCInterpreterDSPInstance(self.ptr, sample_rate)

    def reset_user_interface(self):
        fi.instanceResetUserInterfaceCInterpreterDSPInstance(self.ptr)

    def clear(self):
        fi.instanceClearCInterpreterDSPInstance(self.ptr)

    def build_default_user_interface(self):
        cdef fi.PrintCUI interface
        fi.buildUserInterfaceCInterpreterDSPInstance(
            self.ptr, <fi.UIGlue*>&interface)

    cdef void build_user_interface(self, fi.UIGlue* interface):
        fi.buildUserInterfaceCInterpreterDSPInstance(self.ptr, interface)

    cdef void metadata(self, fi.MetaGlue* meta):
        fi.metadataCInterpreterDSPInstance(self.ptr, meta)

    def default_metadata(self):
        cdef fi.MetaGlue meta
        fi.metadataCInterpreterDSPInstance(self.ptr, <fi.MetaGlue*>&meta)

    def clone(self) -> InterpreterDsp:
        cdef fi.interpreter_dsp* dsp = fi.cloneCInterpreterDSPInstance(self.ptr)
        return InterpreterDsp.from_ptr(dsp)

## ---------------------------------------------------------------------------
## faust/dsp/interpreter-dsp-c
##

def get_dsp_factory_from_sha_key(sha_key: str) -> InterpreterDspFactory:
    """Get the Faust DSP factory associated with a given SHA key.
    """
    cdef InterpreterDspFactory factory = InterpreterDspFactory.from_sha_key(
        sha_key.encode('utf8'))
    return factory


def create_dsp_factory_from_file(filename: str, *args):
    """Create a Faust DSP factory from a DSP source code as a file. 
    """
    cdef InterpreterDspFactory factory = InterpreterDspFactory.from_file(
        filename, *args)
    return factory

def create_dsp_factory_from_string(name_app: str, dsp_content: str, *args):
    """Create a Faust DSP factory from a DSP source code as a string. 
    """
    cdef InterpreterDspFactory factory = InterpreterDspFactory.from_string(
        name_app, dsp_content, *args)
    return factory

def create_dsp_factory_from_bitcode(bitcode: str):
    """Create a Faust DSP factory from a bitcode string.
    """
    cdef InterpreterDspFactory factory = InterpreterDspFactory.from_bitcode(
        bitcode,
    )
    return factory

def create_dsp_factory_from_bitcode_file(bit_code_path: str):
    """Create a Faust DSP factory from a bitcode file.
    """
    cdef InterpreterDspFactory factory = InterpreterDspFactory.from_bitcode_file(
        bit_code_path,
    )
    return factory

def delete_all_dsp_factories():
    """Delete all Faust DSP factories kept in the library cache.
    """
    fi.deleteAllCInterpreterDSPFactories()

def get_all_dsp_factories() -> list[str]:
    """Return Faust DSP factories of the library cache as a vector of their SHA keys.
    """
    cdef const char** factories = fi.getAllCInterpreterDSPFactories()
    cdef int length = sizeof(factories) // sizeof(factories[0])
    result = []
    for i in range(length):
        result.append(factories[i].decode())
    fi.freeCMemory(factories)
    return result

def start_multithreaded_access_mode() -> bool:
    """Start multi-thread access mode."""
    return fi.startMTDSPFactories()

def stop_multithreaded_access_mode():
    """Stop multi-thread access mode."""
    fi.stopMTDSPFactories()


## not yet wrapped

cdef fi.interpreter_dsp_factory* create_interpreter_dsp_factory_from_signals(
        const char* name_app, fi.Signal* signals, int argc, const char* argv[],
        char* error_msg):
    """Create a Faust DSP factory from a vector of output signals.
    """
    return fi.createCInterpreterDSPFactoryFromSignals(
        name_app, signals, argc, argv, error_msg)

cdef fi.interpreter_dsp_factory* create_interpreter_dsp_factory_from_boxes(
        const char* name_app, fi.Box box, int argc, const char* argv[], char* error_msg):
    """Create a Faust DSP factory from a box expression.
    """
    return fi.createCInterpreterDSPFactoryFromBoxes(
        name_app, box, argc, argv, error_msg)


## instance functions.

cdef void compute_interpreter_dsp_instance(fi.interpreter_dsp* dsp, int count, float** input, float** output):
    fi.computeCInterpreterDSPInstance(dsp, count, input, output)


