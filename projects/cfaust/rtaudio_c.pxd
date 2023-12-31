
cdef extern from "rtaudio/rtaudio_c.h":

    ctypedef unsigned long rtaudio_format_t

    cdef unsigned long RTAUDIO_FORMAT_SINT8 = 0x01
    cdef unsigned long RTAUDIO_FORMAT_SINT16 = 0x02
    cdef unsigned long RTAUDIO_FORMAT_SINT24 = 0x04
    cdef unsigned long RTAUDIO_FORMAT_SINT32 = 0x08
    cdef unsigned long RTAUDIO_FORMAT_FLOAT32 = 0x10
    cdef unsigned long RTAUDIO_FORMAT_FLOAT64 = 0x20

    ctypedef unsigned int rtaudio_stream_flags_t

    cdef unsigned int RTAUDIO_FLAGS_NONINTERLEAVED = 0x1
    cdef unsigned int RTAUDIO_FLAGS_MINIMIZE_LATENCY = 0x2
    cdef unsigned int RTAUDIO_FLAGS_HOG_DEVICE = 0x4
    cdef unsigned int RTAUDIO_FLAGS_SCHEDULE_REALTIME = 0x8
    cdef unsigned int RTAUDIO_FLAGS_ALSA_USE_DEFAULT = 0x10
    cdef unsigned int RTAUDIO_FLAGS_JACK_DONT_CONNECT = 0x20

    ctypedef unsigned int rtaudio_stream_status_t

    cdef unsigned int RTAUDIO_STATUS_INPUT_OVERFLOW = 0x1
    cdef unsigned int RTAUDIO_STATUS_OUTPUT_UNDERFLOW = 0x2

    ctypedef int (*rtaudio_cb_t)(
        void *out, 
        void *in_,
        unsigned int nFrames,
        double stream_time,
        rtaudio_stream_status_t status,
        void *userdata
    )

    ctypedef enum rtaudio_error:
        RTAUDIO_ERROR_NONE = 0
        RTAUDIO_ERROR_WARNING
        RTAUDIO_ERROR_UNKNOWN          
        RTAUDIO_ERROR_NO_DEVICES_FOUND 
        RTAUDIO_ERROR_INVALID_DEVICE   
        RTAUDIO_ERROR_DEVICE_DISCONNECT
        RTAUDIO_ERROR_MEMORY_ERROR     
        RTAUDIO_ERROR_INVALID_PARAMETER
        RTAUDIO_ERROR_INVALID_USE      
        RTAUDIO_ERROR_DRIVER_ERROR     
        RTAUDIO_ERROR_SYSTEM_ERROR     
        RTAUDIO_ERROR_THREAD_ERROR     

    ctypedef int rtaudio_error_t


    ctypedef void (*rtaudio_error_cb_t)(rtaudio_error_t err, const char *msg)

    ctypedef enum rtaudio_api:
        RTAUDIO_API_UNSPECIFIED
        RTAUDIO_API_MACOSX_CORE
        RTAUDIO_API_LINUX_ALSA
        RTAUDIO_API_UNIX_JACK
        RTAUDIO_API_LINUX_PULSE
        RTAUDIO_API_LINUX_OSS
        RTAUDIO_API_WINDOWS_ASIO
        RTAUDIO_API_WINDOWS_WASAPI
        RTAUDIO_API_WINDOWS_DS 
        RTAUDIO_API_DUMMY
        RTAUDIO_API_NUM          

    ctypedef int rtaudio_api_t

    cdef int NUM_SAMPLE_RATES = 16
    cdef int MAX_NAME_LENGTH = 512

    ctypedef struct rtaudio_device_info_t:
        unsigned int id
        unsigned int output_channels
        unsigned int input_channels
        unsigned int duplex_channels
        int is_default_output
        int is_default_input
        rtaudio_format_t native_formats
        unsigned int preferred_sample_rate
        unsigned int sample_rates[16]
        char name[512]

    ctypedef struct rtaudio_stream_parameters_t:
        unsigned int device_id
        unsigned int num_channels
        unsigned int first_channel


    ctypedef struct rtaudio_stream_options_t:
        rtaudio_stream_flags_t flags
        unsigned int num_buffers
        int priority
        char name[512]

    ctypedef struct rtaudio_t

    const char *rtaudio_version()

    unsigned int rtaudio_get_num_compiled_apis()
    const rtaudio_api_t *rtaudio_compiled_api()
    const char *rtaudio_api_name(rtaudio_api_t api_)
    const char *rtaudio_api_display_name(rtaudio_api_t api_)
    rtaudio_api_t rtaudio_compiled_api_by_name(const char *name)
    const char *rtaudio_error_fn "rtaudio_error" (rtaudio_t audio)
    rtaudio_error_t rtaudio_error_type(rtaudio_t audio)
    rtaudio_t rtaudio_create(rtaudio_api_t api_)
    void rtaudio_destroy(rtaudio_t audio)
    rtaudio_api_t rtaudio_current_api(rtaudio_t audio)
    int rtaudio_device_count(rtaudio_t audio)
    unsigned int rtaudio_get_device_id(rtaudio_t audio, int i)
    rtaudio_device_info_t rtaudio_get_device_info( rtaudio_t audio, unsigned int id)
    unsigned int rtaudio_get_default_output_device(rtaudio_t audio)
    unsigned int rtaudio_get_default_input_device(rtaudio_t audio)

    rtaudio_error_t rtaudio_open_stream(
        rtaudio_t audio, rtaudio_stream_parameters_t *output_params,
        rtaudio_stream_parameters_t *input_params,
        rtaudio_format_t format, unsigned int sample_rate,
        unsigned int *buffer_frames, rtaudio_cb_t cb,
        void *userdata, rtaudio_stream_options_t *options,
        rtaudio_error_cb_t errcb
    )

    void rtaudio_close_stream(rtaudio_t audio)
    rtaudio_error_t rtaudio_start_stream(rtaudio_t audio)
    rtaudio_error_t rtaudio_stop_stream(rtaudio_t audio)
    rtaudio_error_t rtaudio_abort_stream(rtaudio_t audio)
    int rtaudio_is_stream_open(rtaudio_t audio)
    int rtaudio_is_stream_running(rtaudio_t audio)
    double rtaudio_get_stream_time(rtaudio_t audio)
    void rtaudio_set_stream_time(rtaudio_t audio, double time)
    long rtaudio_get_stream_latency(rtaudio_t audio)
    unsigned int rtaudio_get_stream_sample_rate(rtaudio_t audio)
    void rtaudio_show_warnings(rtaudio_t audio, int show)

