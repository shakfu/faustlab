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

cdef dsp_factory* create_interpreter_dsp_ractory_from_signals(
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

cdef fi.interpreter_dsp_factory* read_interpreter_dsp_factory_from_bitcode_file(const string& bit_code_path, string& error_msg):
    """Create a Faust DSP factory from a bitcode file.
    """
    return fi.readInterpreterDSPFactoryFromBitcodeFile(bit_code_path, error_msg)

cdef bint write_interpreter_dsp_factory_to_bitcode_file(dsp_factory* factory, const string& bit_code_path):
    """Write a Faust DSP factory into a bitcode file.
    """
    return fi.writeInterpreterDSPFactoryToBitcodeFile(factory, bit_code_path)

