

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
    def from_int(int value) -> Signal:
        """Create signal from int"""
        cdef fs.Signal b = fs.sigInt(value)
        return Signal.from_ptr(b)

    @staticmethod
    def from_float(float value) -> Signal:
        """Create signal from float"""
        cdef fs.Signal b = fs.sigReal(value)
        return Signal.from_ptr(b)

    # def create_source(self, name_app: str, lang, *args) -> str:
    #     """Create source code in a target language from a signal expression."""
    #     cdef string error_msg
    #     error_msg.reserve(4096)
    #     cdef ParamArray params = ParamArray(args)
    #     cdef string src = fs.createSourceFromSignals(
    #         name_app,
    #         self.ptr,
    #         lang,
    #         params.argc,
    #         params.argv,
    #         error_msg)
    #     if error_msg.empty():
    #         print(error_msg.decode())
    #         return
    #     return src.decode()

    def print(self, shared: bool = False, max_size: int = 256):
        """Print this signal."""
        print(fs.printSignal(self.ptr, shared, max_size).decode())

    def __add__(self, Signal other):
        """Add this signal to another."""
        cdef fs.Signal b = fs.sigAdd(self.ptr, other.ptr)
        return Signal.from_ptr(b)

    def __radd__(self, Signal other):
        """Reverse add this signal to another."""
        cdef fs.Signal b = fs.sigAdd(self.ptr, other.ptr)
        return Signal.from_ptr(b)


## ---------------------------------------------------------------------------
## faust/dsp/libfaust-signal

cdef const char* ffname(fs.Signal s):
    """Return the name parameter of a foreign function."""
    return fs.ffname(s)

cdef int ffarity(fs.Signal s):
    """Return the arity of a foreign function."""
    return fs.ffarity(s)

cdef string print_signal(fs.Signal sig, bint shared, int max_size):
    """Print a signal."""
    return fs.printSignal(sig, shared, max_size)

cdef fs.Signal sig_int(int n):
    return fs.sigInt(n)

cdef fs.Signal sig_real(double n):
    return fs.sigReal(n)

cdef fs.Signal sig_input(int idx):
    return fs.sigInput(idx)

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

cdef fs.Signal sig_add(fs.Signal x, fs.Signal y):
    return fs.sigAdd(x, y)

cdef fs.Signal sig_sub(fs.Signal x, fs.Signal y):
    return fs.sigSub(x, y)

cdef fs.Signal sig_mul(fs.Signal x, fs.Signal y):
    return fs.sigMul(x, y)

cdef fs.Signal sig_div(fs.Signal x, fs.Signal y):
    return fs.sigDiv(x, y)

cdef fs.Signal sig_rem(fs.Signal x, fs.Signal y):
    return fs.sigRem(x, y)

cdef fs.Signal sig_left_shift(fs.Signal x, fs.Signal y):
    return fs.sigLeftShift(x, y)

cdef fs.Signal sig_l_right_shift(fs.Signal x, fs.Signal y):
    return fs.sigLRightShift(x, y)

cdef fs.Signal sig_gt(fs.Signal x, fs.Signal y):
    return fs.sigGT(x, y)

cdef fs.Signal sig_lt(fs.Signal x, fs.Signal y):
    return fs.sigLT(x, y)

cdef fs.Signal sig_ge(fs.Signal x, fs.Signal y):
    return fs.sigGE(x, y)

cdef fs.Signal sig_le(fs.Signal x, fs.Signal y):
    return fs.sigLE(x, y)

cdef fs.Signal sig_eq(fs.Signal x, fs.Signal y):
    return fs.sigEQ(x, y)

cdef fs.Signal sig_ne(fs.Signal x, fs.Signal y):
    return fs.sigNE(x, y)

cdef fs.Signal sig_and(fs.Signal x, fs.Signal y):
    return fs.sigAND(x, y)

cdef fs.Signal sig_or(fs.Signal x, fs.Signal y):
    return fs.sigOR(x, y)

cdef fs.Signal sig_xor(fs.Signal x, fs.Signal y):
    return fs.sigXOR(x, y)



cdef fs.Signal sig_abs(fs.Signal x):
    return fs.sigAbs(x)

cdef fs.Signal sig_acos(fs.Signal x):
    return fs.sigAcos(x)

cdef fs.Signal sig_tan(fs.Signal x):
    return fs.sigTan(x)

cdef fs.Signal sig_sqrt(fs.Signal x):
    return fs.sigSqrt(x)

cdef fs.Signal sig_sin(fs.Signal x):
    return fs.sigSin(x)

cdef fs.Signal sig_rint(fs.Signal x):
    return fs.sigRint(x)

cdef fs.Signal sig_log(fs.Signal x):
    return fs.sigLog(x)

cdef fs.Signal sig_log10(fs.Signal x):
    return fs.sigLog10(x)

cdef fs.Signal sig_floor(fs.Signal x):
    return fs.sigFloor(x)

cdef fs.Signal sig_exp(fs.Signal x):
    return fs.sigExp(x)

cdef fs.Signal sig_exp10(fs.Signal x):
    return fs.sigExp10(x)

cdef fs.Signal sig_cos(fs.Signal x):
    return fs.sigCos(x)

cdef fs.Signal sig_ceil(fs.Signal x):
    return fs.sigCeil(x)

cdef fs.Signal sig_atan(fs.Signal x):
    return fs.sigAtan(x)

cdef fs.Signal sig_asin(fs.Signal x):
    return fs.sigAsin(x)

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
