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
## tests
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



