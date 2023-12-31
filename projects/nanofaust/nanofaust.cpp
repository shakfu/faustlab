#define INCLUDE_RTAUDIO_WRAPPER 0

#include <nanobind/nanobind.h>
#include <nanobind/stl/string.h>
#include <nanobind/stl/vector.h>

// faust
#include "faust/dsp/dsp.h"
#include "faust/dsp/libfaust.h"
#include "faust/dsp/libfaust-signal.h"
#include "faust/dsp/libfaust-box.h"
#include "faust/dsp/interpreter-dsp.h"
#include "faust/audio/rtaudio-dsp.h"
#include "faust/gui/meta.h"
#include "faust/gui/PrintUI.h"
// #include "faust/compiler/tlib/tree.hh" // for CTree

// rtaudio
#include "rtaudio/RtAudio.h"

namespace nb = nanobind;
using namespace nb::literals;

struct CTree {};

// struct DspMeta : Meta, std::map<const char*, const char*>
// {
//     void declare(const char* key, const char* value)
//     { 
//         (*this)[key] = value;
//     }
// };


NB_MODULE(nanofaust, m)
{
    m.doc() = "nanofaust: a nanobind wrapper around the faust interpreter.";
    m.attr("__version__") = "0.0.1";

    // -----------------------------------------------------------------------
    // faust/dsp/dsp.h

    nb::class_<dsp>(m, "Dsp");

    
    // -----------------------------------------------------------------------
    // faust/dsp/libfaust-signal.h

    nb::class_<Signal>(m, "Signal");

    // -----------------------------------------------------------------------
    // faust/dsp/libfaust.h
    
    m.def("generate_sha1", &generateSHA1, "Generate SHA1 key from a string.");
    m.def("expand_dsp_from_file", [](const std::string& filename, std::vector<std::string> args, std::string& sha_key, std::string& error_msg) {
        std::vector<const char *> argv;
        argv.reserve(args.size());
        for (auto &i : args) argv.push_back(const_cast<char *>(i.c_str()));
        return expandDSPFromFile(filename, argv.size(), argv.data(), sha_key, error_msg);
    }, "Expand DSP source code from a file into a self-contained DSP string.");

    m.def("expand_dsp_from_string", [](const std::string& name_app, const std::string& dsp_content, std::vector<std::string> args, std::string& sha_key, std::string& error_msg) {
        std::vector<const char *> argv;
        argv.reserve(args.size());
        for (auto &i : args) argv.push_back(const_cast<char *>(i.c_str()));
        return expandDSPFromString(name_app, dsp_content, argv.size(), argv.data(), sha_key, error_msg);
    }, "Expand DSP source code from a file into a self-contained DSP string.");

    m.def("generate_aux_files_from_file", [](const std::string& filename, std::vector<std::string> args, std::string& error_msg) {
        std::vector<const char *> argv;
        argv.reserve(args.size());
        for (auto &i : args) argv.push_back(const_cast<char *>(i.c_str()));
        return generateAuxFilesFromFile(filename, argv.size(), argv.data(), error_msg);
    }, "Generate additional file (other backends, SVG, XML, JSON...) starting from a filename.");

    m.def("generate_aux_files_from_string", [](const std::string& name_app, const std::string& dsp_content, std::vector<std::string> args, std::string& error_msg) {
        std::vector<const char *> argv;
        argv.reserve(args.size());
        for (auto &i : args) argv.push_back(const_cast<char *>(i.c_str()));
        return generateAuxFilesFromString(name_app, dsp_content, argv.size(), argv.data(), error_msg);
    }, "Expand DSP source code from a file into a self-contained DSP string.");

    // -----------------------------------------------------------------------
    // faust/dsp/interpreter-dsp.h

    m.def("get_version", &getCLibFaustVersion, "Retrieve the libfaust version.");
    m.def("get_interpreter_dsp_factory_from_sha_key", &getInterpreterDSPFactoryFromSHAKey, "Get the Faust DSP factory associated with a given SHA key.");

    m.def("create_interpreter_dsp_factory_from_file", [](const std::string& filename, nb::args& args) -> interpreter_dsp_factory* {
        std::vector<std::string> params;
        std::string error_msg;
        std::vector<const char *> argv;
        for (const auto &arg : args) {
            params.push_back(nb::cast<std::string>(arg));
        }
        argv.reserve(params.size());
        for (auto &i : params)
            argv.push_back(const_cast<char *>(i.c_str()));
        interpreter_dsp_factory* factory = (interpreter_dsp_factory*)createInterpreterDSPFactoryFromFile(filename, argv.size(), argv.data(), error_msg);
        if (!factory) {
            std::cerr << "Cannot create factory : " << error_msg;
            return NULL;
        }
        return factory;
    }, "Create a Faust DSP factory from a DSP source code as a file.", nb::rv_policy::reference);
    // }, nb::args("filename"), nb::args("args"), "Create a Faust DSP factory from a DSP source code as a file.", nb::rv_policy::reference);

    m.def("create_interpreter_dsp_factory_from_string", [](const std::string& name_app, const std::string& dsp_content, std::vector<std::string> args, std::string& error_msg) {
        std::vector<const char *> argv;
        argv.reserve(args.size());
        for (auto &i : args) argv.push_back(const_cast<char *>(i.c_str()));
        return createInterpreterDSPFactoryFromString(name_app, dsp_content, argv.size(), argv.data(), error_msg);
    }, "Create a Faust DSP factory from a DSP source code as a string.");

    m.def("create_interpreter_dsp_factory_from_signals", [](const std::string& name_app, tvec signals, std::vector<std::string> args, std::string& error_msg) {
        std::vector<const char *> argv;
        argv.reserve(args.size());
        for (auto &i : args) argv.push_back(const_cast<char *>(i.c_str()));    
        return createInterpreterDSPFactoryFromSignals(name_app, signals, argv.size(), argv.data(), error_msg);
    }, "Create a Faust DSP factory from a vector of output signals.");

    m.def("create_interpreter_dsp_factory_from_boxes", [](const std::string& name_app, Box box, std::vector<std::string> args, std::string& error_msg) {
        std::vector<const char *> argv;
        argv.reserve(args.size());
        for (auto &i : args) argv.push_back(const_cast<char *>(i.c_str()));    
        return createInterpreterDSPFactoryFromBoxes(name_app, box, argv.size(), argv.data(), error_msg);
    }, "Create a Faust DSP factory from a box expression.");

    m.def("delete_interpreter_dsp_factory", &deleteInterpreterDSPFactory, "Delete a Faust DSP factory,");
    m.def("delete_all_interpreter_dsp_factories", &deleteAllInterpreterDSPFactories, "Delete all Faust DSP factories kept in the library cache.");
    m.def("get_all_interpreter_dsp_factories", &getAllInterpreterDSPFactories, "Return Faust DSP factories of the library cache as a vector of their SHA keys.");
    m.def("start_multithreaded_dsp_factories", &startMTDSPFactories, "Start multi-thread access mode");
    m.def("stop_multithreaded_dsp_factories", &stopMTDSPFactories, "Stop multi-thread access mode");
    m.def("read_interpreter_dsp_factory_from_bitcode", &readInterpreterDSPFactoryFromBitcode, "Create a Faust DSP factory from a bitcode string.");
    m.def("write_interpreter_dsp_factory_to_bitcode", &writeInterpreterDSPFactoryToBitcode, "Write a Faust DSP factory into a bitcode string.");
    m.def("read_interpreter_dsp_factory_from_bitcode_file", &readInterpreterDSPFactoryFromBitcodeFile, "Create a Faust DSP factory from a bitcode file.");
    m.def("write_interpreter_dsp_factory_to_bitcode_file", &writeInterpreterDSPFactoryToBitcodeFile, "Write a Faust DSP factory into a bitcode file.");

    nb::class_<interpreter_dsp, dsp>(m, "InterpreterDsp")
        .def("get_numinputs", &interpreter_dsp::getNumInputs, "Return instance number of audio inputs")
        .def("get_numoutputs", &interpreter_dsp::getNumOutputs, "Return instance number of audio outputs")
        // .def("build_user_interface", &interpreter_dsp::buildUserInterface, "Trigger the ui_interface parameter with instance specific calls")
        .def("build_user_interface", [](interpreter_dsp &self) {
            PrintUI print_ui;
            return self.buildUserInterface(&print_ui);
         }, "Trigger the ui_interface parameter with instance specific calls")
        .def("get_sampletate", &interpreter_dsp::getSampleRate, "Return the sample rate currently used by the instance")
        .def("init", &interpreter_dsp::init, "Global init calls classInit and instanceInit")
        .def("instance_init", &interpreter_dsp::instanceInit, "Init instance state")
        .def("instance_constants", &interpreter_dsp::instanceConstants, "Init instance constant state")
        .def("instance_reset_user_interface", &interpreter_dsp::instanceResetUserInterface, "Init default control parameters values")
        .def("instance_clear", &interpreter_dsp::instanceClear, "Init instance state but keep the control parameter values")
        .def("clone", &interpreter_dsp::clone, "Return a clone of the instance.")
        .def("metadata", &interpreter_dsp::metadata, "Trigger the Meta* parameter with instance specific calls to 'declare' (key, value) metadata.")
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

    // -----------------------------------------------------------------------
    // faust/audio/rtaudio-dsp.h
    
    nb::class_<rtaudio>(m, "RtAudioDriver")
        .def(nb::init<int, int>())
        // .def("init", nb::overload_cast<const char*, dsp*>(&rtaudio::init), "initialize driver")
        .def("init", [](rtaudio &self, dsp* instance) {
            return self.init("FaustDSP", instance); // first char* arg is a dummy
        }, "initialize audio driver")
        .def("set_dsp", &rtaudio::setDsp)
        .def("start", &rtaudio::start)
        .def("stop", &rtaudio::stop)
        .def("get_buffersize", &rtaudio::getBufferSize)
        .def("get_sapmplerate", &rtaudio::getSampleRate)
        .def("get_numinputs", &rtaudio::getNumInputs)
        .def("get_numoutputs", &rtaudio::getNumOutputs)
        ;

    // -----------------------------------------------------------------------
    // faust/gui/PrintUI.h
    
    nb::class_<PrintUI>(m, "PrintUI")
        .def(nb::init<>())
        .def("open_tab_box", &PrintUI::openTabBox)
        .def("open_horizontal_box", &PrintUI::openHorizontalBox)
        .def("open_vertical_box", &PrintUI::openVerticalBox)
        .def("close_box", &PrintUI::closeBox)
        .def("add_button", &PrintUI::addButton)
        .def("add_check_button", &PrintUI::addCheckButton)
        .def("add_vertical_slider", &PrintUI::addVerticalSlider)
        .def("add_horizontal_slider", &PrintUI::addHorizontalSlider)
        .def("add_numentry", &PrintUI::addNumEntry)
        .def("add_horizontal_bargraph", &PrintUI::addHorizontalBargraph)
        .def("add_vertical_bargraph", &PrintUI::addVerticalBargraph)
        // .def("add_soundfile", &PrintUI::addSoundfile)
        .def("declare", &PrintUI::declare)
        ;

    // -----------------------------------------------------------------------
    // faust/gui/meta.h

    nb::class_<Meta>(m, "Meta")
        .def("declare", &Meta::declare, "declare key value items")
        ;
    
    // nb::class_<DspMeta>(m, "DspMeta")
    //     .def("declare", &DspMeta::declare, "declare key value items")
    //     ;

    // -----------------------------------------------------------------------
    // rtaudio/RtAudio.h

#if INCLUDE_RTAUDIO_WRAPPER

    nb::enum_<RtAudioErrorType>(m, "RtAudioErrorType")
        .value("RTAUDIO_NO_ERROR",          RtAudioErrorType::RTAUDIO_NO_ERROR,           "No error")
        .value("RTAUDIO_WARNING",           RtAudioErrorType::RTAUDIO_WARNING,            "A non-critical error")
        .value("RTAUDIO_UNKNOWN_ERROR",     RtAudioErrorType::RTAUDIO_UNKNOWN_ERROR,      "An unspecified error type.")
        .value("RTAUDIO_NO_DEVICES_FOUND",  RtAudioErrorType::RTAUDIO_NO_DEVICES_FOUND,   "No devices found on system")
        .value("RTAUDIO_INVALID_DEVICE",    RtAudioErrorType::RTAUDIO_INVALID_DEVICE,     "An invalid device ID was specified")
        .value("RTAUDIO_DEVICE_DISCONNECT", RtAudioErrorType::RTAUDIO_DEVICE_DISCONNECT,  "A device in use was disconnected")
        .value("RTAUDIO_MEMORY_ERROR",      RtAudioErrorType::RTAUDIO_MEMORY_ERROR,       "An error occurred during memory allocation.")
        .value("RTAUDIO_INVALID_PARAMETER", RtAudioErrorType::RTAUDIO_INVALID_PARAMETER,  "Tn invalid parameter was specified to a function.")
        .value("RTAUDIO_INVALID_USE",       RtAudioErrorType::RTAUDIO_INVALID_USE,        "The function was called incorrectly.")    
        .value("RTAUDIO_DRIVER_ERROR",      RtAudioErrorType::RTAUDIO_DRIVER_ERROR,       "A system driver error occurred.")
        .value("RTAUDIO_SYSTEM_ERROR",      RtAudioErrorType::RTAUDIO_SYSTEM_ERROR,       "A system error occurred.")
        .value("RTAUDIO_THREAD_ERROR",      RtAudioErrorType::RTAUDIO_THREAD_ERROR,       "A thread error occurred.")
        .export_values();

    nb::class_<RtApi>(m, "RtApi");

    nb::class_<RtAudio> _rta(m, "RtAudio");

    nb::enum_<RtAudio::Api>(_rta, "Api")
        .value("UNSPECIFIED",    RtAudio::Api::UNSPECIFIED,    "Search for a working compiled API")
        .value("MACOSX_CORE",    RtAudio::Api::MACOSX_CORE,    "Macintosh OS-X Core Audio API")
        .value("LINUX_ALSA",     RtAudio::Api::LINUX_ALSA,     "The Advanced Linux Sound Architecture API")
        .value("UNIX_JACK",      RtAudio::Api::UNIX_JACK,      "The Jack Low-Latency Audio Server API")
        .value("LINUX_PULSE",    RtAudio::Api::LINUX_PULSE,    "The Linux PulseAudio API")
        .value("LINUX_OSS",      RtAudio::Api::LINUX_OSS,      "The Linux Open Sound System API")
        .value("WINDOWS_ASIO",   RtAudio::Api::WINDOWS_ASIO,   "The Steinberg Audio Stream I/O API")
        .value("WINDOWS_WASAPI", RtAudio::Api::WINDOWS_WASAPI, "The Microsoft WASAPI API")
        .value("WINDOWS_DS",     RtAudio::Api::WINDOWS_DS,     "The Microsoft DirectSound API")
        .value("RTAUDIO_DUMMY",  RtAudio::Api::RTAUDIO_DUMMY,  "A compilable but non-functional API")
        .value("NUM_APIS",       RtAudio::Api::NUM_APIS,       "Number of values in this enum")
        .export_values();

    nb::class_<RtAudio::DeviceInfo>(_rta, "DeviceInfo")
        .def(nb::init<>())
        .def_rw("id", &RtAudio::DeviceInfo::ID)
        .def_rw("name", &RtAudio::DeviceInfo::name)
        .def_rw("output_channels", &RtAudio::DeviceInfo::outputChannels)
        .def_rw("input_channels", &RtAudio::DeviceInfo::inputChannels)
        .def_rw("duplex_channels", &RtAudio::DeviceInfo::duplexChannels)
        .def_rw("is_default_output", &RtAudio::DeviceInfo::isDefaultOutput)
        .def_rw("is_default_intput", &RtAudio::DeviceInfo::isDefaultInput)
        .def_rw("samplerates", &RtAudio::DeviceInfo::sampleRates)
        .def_rw("current_samplerate", &RtAudio::DeviceInfo::currentSampleRate)
        .def_rw("preferred_samplerate", &RtAudio::DeviceInfo::preferredSampleRate)
        .def_rw("native_formats", &RtAudio::DeviceInfo::nativeFormats)
        ;

    nb::class_<RtAudio::StreamParameters>(_rta, "StreamParameters")
        .def(nb::init<>())
        .def_rw("device_id", &RtAudio::StreamParameters::deviceId)
        .def_rw("nchannels", &RtAudio::StreamParameters::nChannels)
        .def_rw("first_channel", &RtAudio::StreamParameters::firstChannel)
        ;

    nb::class_<RtAudio::StreamOptions>(_rta, "StreamOptions")
        .def(nb::init<>())
        .def_rw("flags", &RtAudio::StreamOptions::flags)
        .def_rw("stream_name", &RtAudio::StreamOptions::streamName)
        .def_rw("priority", &RtAudio::StreamOptions::priority)
        ;

    _rta.def_static("get_version", &RtAudio::getVersion, "Return the current RtAudio version.");
    _rta.def_static("get_compiled_apis", []() {
        std::vector<RtAudio::Api> apis;
        RtAudio::getCompiledApi(apis);
        return apis;
    }, "Get the available compiled audio APIs.");

    _rta.def_static("get_api_name", &RtAudio::getApiName, "Return the name of a specified compiled audio API.");
    _rta.def_static("get_api_display_name", &RtAudio::getApiDisplayName, "Return the display name of a specified compiled audio API.");
    _rta.def_static("get_compiled_api_by_name", &RtAudio::getCompiledApiByName, "Return the compiled audio API having the given name.");
    _rta.def_static("get_compiled_api_by_display_name", &RtAudio::getCompiledApiByDisplayName, "Return the compiled audio API having the given display name.");

    // constructor
    _rta.def(nb::init<RtAudio::Api>(), nb::arg("api") = RtAudio::Api::UNSPECIFIED);
    // _rta.def(nb::init<RtAudio::Api, RtAudioErrorCallback>(), nb::arg("api") = RtAudio::Api::UNSPECIFIED, nb::arg("errorCallback") = 0);

    _rta.def("get_current_api", &RtAudio::getCurrentApi, "Returns the audio API specifier for the current instance of RtAudio");
    _rta.def("get_device_count", &RtAudio::getDeviceCount, "Returns the number of audio devices available");
    _rta.def("get_device_ids", &RtAudio::getDeviceIds, "Returns a list of audio device ids");
    _rta.def("get_device_names", &RtAudio::getDeviceNames, "Returns a list of audio device names");
    _rta.def("get_device_info", &RtAudio::getDeviceInfo, "Returns a DeviceInfo instance for the given device id.");
    _rta.def("open_stream", &RtAudio::openStream, "Open a stream with the specified parameters");
    _rta.def("get_default_output_device", &RtAudio::getDefaultOutputDevice, "Returns the ID of the default output device.");
    _rta.def("get_default_intput_device", &RtAudio::getDefaultInputDevice, "Returns the ID of the default input device.");
    _rta.def("close_stream", &RtAudio::closeStream, "Closes a stream and frees any associated stream memory.");
    _rta.def("start_stream", &RtAudio::startStream, "Starts a stream.");
    _rta.def("stop_stream", &RtAudio::stopStream, "Stop a stream, allowing any samples remaining in the output queue to be played.");
    _rta.def("abort_stream", &RtAudio::abortStream, "Stop a stream, discarding any samples remaining in the input/output queue.");
    _rta.def("get_error_text", &RtAudio::getErrorText, "Retrieve the error message corresponding to the last error or warning condition.");
    _rta.def("is_stream_open", &RtAudio::isStreamOpen, "Returns true if a stream is open and false if not.");
    _rta.def("is_stream_running", &RtAudio::isStreamRunning, "Returns true if the stream is running and false if it is stopped or not open.");
    _rta.def("get_stream_time", &RtAudio::getStreamTime, "Returns the number of seconds of processed data since the stream was started.");
    _rta.def("set_stream_time", &RtAudio::setStreamTime, "Set the stream time to a time in seconds greater than or equal to 0.0.");
    _rta.def("get_stream_latency", &RtAudio::getStreamLatency, "Returns the internal stream latency in sample frames.");
    _rta.def("get_stream_samplerate", &RtAudio::getStreamSampleRate, "Returns actual sample rate in use by the (open) stream.");
    _rta.def("set_error_callback", &RtAudio::setErrorCallback, "Set a client-defined function that will be invoked when an error or warning occurs.");
    _rta.def("show_warnings", &RtAudio::showWarnings, "Specify whether warning messages should be output or not.");

#endif // INCLUDE_RTAUDIO_WRAPPER

}
