#include <nanobind/nanobind.h>

// faust
#include "faust/dsp/libfaust.h"
#include "faust/dsp/libfaust-signal.h"
#include "faust/dsp/libfaust-box.h"
#include "faust/dsp/interpreter-dsp.h"


namespace nb = nanobind;
using namespace nb::literals;

NB_MODULE(nanofaust, m)
{
    m.doc() = "nanofaust: a nanobind wrapper around the faust interpreter.";
    m.attr("__version__") = "0.0.1";

    // libfaust
    m.def("generate_sha1", &generateSHA1, "Generate SHA1 key from a string.");

    m.def("expand_dsp_from_file", [](const std::string& filename, std::vector<std::string> args, std::string& sha_key,  std::string& error_msg) {
        std::vector<const char *> cstrs;
        cstrs.reserve(args.size());
        for (auto &i : args) cstrs.push_back(const_cast<char *>(i.c_str()));
        return expandDSPFromFile(filename, cstrs.size(), cstrs.data(), sha_key, error_msg);
    }, "Expand DSP source code into a self-contained DSP.");

    m.def("expand_dsp_from_string", [](const std::string& name_app, const std::string& dsp_content, std::vector<std::string> args, std::string& sha_key,  std::string& error_msg) {
        std::vector<const char *> cstrs;
        cstrs.reserve(args.size());
        for (auto &i : args) cstrs.push_back(const_cast<char *>(i.c_str()));
        return expandDSPFromString(name_app, dsp_content, cstrs.size(), cstrs.data(), sha_key, error_msg);
    }, "Expand DSP source code from a file into a self-contained DSP string.");

    m.def("generate_aux_files_from_file", [](const std::string& filename, std::vector<std::string> args, std::string& error_msg) {
        std::vector<const char *> cstrs;
        cstrs.reserve(args.size());
        for (auto &i : args) cstrs.push_back(const_cast<char *>(i.c_str()));
        return generateAuxFilesFromFile(filename, cstrs.size(), cstrs.data(), error_msg);
    }, "Generate additional file (other backends, SVG, XML, JSON...) starting from a filename.");

    m.def("generate_aux_files_from_string", [](const std::string& name_app, const std::string& dsp_content, std::vector<std::string> args, std::string& error_msg) {
        std::vector<const char *> cstrs;
        cstrs.reserve(args.size());
        for (auto &i : args) cstrs.push_back(const_cast<char *>(i.c_str()));
        return generateAuxFilesFromString(name_app, dsp_content, cstrs.size(), cstrs.data(), error_msg);
    }, "Generate additional file (other backends, SVG, XML, JSON...) starting from a string.");


    // interpreter-dsp

    m.def("get_version", &getCLibFaustVersion, "Retrieve the libfaust version.");
    m.def("get_interpreter_dsp_factory_from_sha_key", &getInterpreterDSPFactoryFromSHAKey, "Get the Faust DSP factory associated with a given SHA key.");

    m.def("create_interpreter_dsp_factory_from_file", [](const std::string& filename, std::vector<std::string> args, std::string& error_msg) {
        std::vector<const char *> cstrs;
        cstrs.reserve(args.size());
        for (auto &i : args) cstrs.push_back(const_cast<char *>(i.c_str()));
        return createInterpreterDSPFactoryFromFile(filename, cstrs.size(), cstrs.data(), error_msg);
    }, "Create a Faust DSP factory from a DSP source code as a file.");

    m.def("create_interpreter_dsp_factory_from_string", [](const std::string& name_app, const std::string& dsp_content, std::vector<std::string> args, std::string& error_msg) {
        std::vector<const char *> cstrs;
        cstrs.reserve(args.size());
        for (auto &i : args) cstrs.push_back(const_cast<char *>(i.c_str()));
        return createInterpreterDSPFactoryFromString(name_app, dsp_content, cstrs.size(), cstrs.data(), error_msg);
    }, "Create a Faust DSP factory from a DSP source code as a string.");


    // m.def("create_interpreter_dsp_factory_from_signals", &createInterpreterDSPFactoryFromSignals, "Create a Faust DSP factory from a vector of output signals.");
    // m.def("create_interpreter_dsp_factory_from_boxes", &createInterpreterDSPFactoryFromBoxes, "Create a Faust DSP factory from a box expression.");
    m.def("delete_interpreter_dsp_factory", &deleteInterpreterDSPFactory, "Delete a Faust DSP factory,");
    m.def("delete_all_interpreter_dsp_factories", &deleteAllInterpreterDSPFactories, "Delete all Faust DSP factories kept in the library cache.");
    m.def("get_all_interpreter_dsp_factories", &getAllInterpreterDSPFactories, "Return Faust DSP factories of the library cache as a vector of their SHA keys.");
    m.def("start_multithreaded_dsp_factories", &startMTDSPFactories, "Start multi-thread access mode");
    m.def("stop_multithreaded_dsp_factories", &stopMTDSPFactories, "Stop multi-thread access mode");
    m.def("read_interpreter_dsp_factory_from_bitcode", &readInterpreterDSPFactoryFromBitcode, "Create a Faust DSP factory from a bitcode string.");
    m.def("write_interpreter_dsp_factory_to_bitcode", &writeInterpreterDSPFactoryToBitcode, "Write a Faust DSP factory into a bitcode string.");
    m.def("read_interpreter_dsp_factory_from_bitcode_file", &readInterpreterDSPFactoryFromBitcodeFile, "Create a Faust DSP factory from a bitcode file.");
    m.def("write_interpreter_dsp_factory_to_bitcode_file", &writeInterpreterDSPFactoryToBitcodeFile, "Write a Faust DSP factory into a bitcode file.");

    nb::class_<interpreter_dsp>(m, "InterpreterDsp")
        .def("get_numinputs", &interpreter_dsp::getNumInputs, "Return instance number of audio inputs")
        .def("get_numoutputs", &interpreter_dsp::getNumOutputs, "Return instance number of audio outputs")
        // .def("build_user_interface", &interpreter_dsp::buildUserInterface, "Trigger the ui_interface parameter with instance specific calls")
        .def("get_sampletate", &interpreter_dsp::getSampleRate, "Return the sample rate currently used by the instance")
        .def("init", &interpreter_dsp::init, "Global init calls classInit and instanceInit")
        .def("instance_init", &interpreter_dsp::instanceInit, "Init instance state")
        .def("instance_constants", &interpreter_dsp::instanceConstants, "Init instance constant state")
        .def("instance_reset_user_interface", &interpreter_dsp::instanceResetUserInterface, "Init default control parameters values")
        .def("instance_clear", &interpreter_dsp::instanceClear, "Init instance state but keep the control parameter values")
        .def("clone", &interpreter_dsp::clone, "Return a clone of the instance.")
        // .def("metadata", &interpreter_dsp::metadata, "Trigger the Meta* parameter with instance specific calls to 'declare' (key, value) metadata.")
        // .def("compute", &interpreter_dsp::compute, "DSP instance computation, to be called with successive in/out audio buffers.")
        ;

    nb::class_<interpreter_dsp_factory>(m, "InterpreterDspFactory")
        .def("get_name", &interpreter_dsp_factory::getName, "Return factory name")
        .def("get_sha_key", &interpreter_dsp_factory::getSHAKey, "Return factory SHA key")
        .def("get_dsp_code", &interpreter_dsp_factory::getDSPCode, "Return factory expanded DSP code")
        .def("get_compile_options", &interpreter_dsp_factory::getCompileOptions, "Return factory compile options")
        .def("get_library_list", &interpreter_dsp_factory::getLibraryList, "Get the Faust DSP factory list of library dependancies")
        .def("get_include_pathnames", &interpreter_dsp_factory::getIncludePathnames, "Get the list of all used includes")
        .def("get_warning_messages", &interpreter_dsp_factory::getWarningMessages, "Get warning messages list for a given compilation")
        .def("create_dsp_instance", &interpreter_dsp_factory::createDSPInstance, "Create a new DSP instance, to be deleted with C++ 'delete'")
        .def("set_memory_manager", &interpreter_dsp_factory::setMemoryManager, "Set a custom memory manager to be used when creating instances")
        .def("get_memory_manager", &interpreter_dsp_factory::getMemoryManager, "Return the currently set custom memory manager")
        ;
}