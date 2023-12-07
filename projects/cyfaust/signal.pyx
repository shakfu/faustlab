
cdef bint is_nil(fb.Box b):
    """Check if a box is nil."""
    return fb.isNil(b)

cdef const char* tree2str(fb.Box b):
    """Convert a box (such as the label of a UI) to a string."""
    return fb.tree2str(b)

cdef int tree2int(fb.Box b):
    """If t has a node of type int, return it. Otherwise error."""
    return fb.tree2int(b)

cdef void* get_user_data(fb.Box b):
    """Return the xtended type of a box."""
    return fb.getUserData(b)

cdef fb.Box box_int(int n):
    """Constant integer : for all t, x(t) = n."""
    return fb.boxInt(n)

cdef fb.Box box_real(double n):
    """Constant real : for all t, x(t) = n."""
    return fb.boxReal(n)

cdef fb.Box box_wire():
    """The identity box, copy its input to its output."""
    return fb.boxWire()

cdef fb.Box box_cut():
    """The cut box, to "stop"/terminate a signal."""
    return fb.boxCut()

cdef fb.Box box_seq(fb.Box x, fb.Box y):
    """The sequential composition of two blocks (e.g., A:B) expects: outputs(A)=inputs(B)."""
    return fb.boxSeq(x, y)

cdef fb.Box box_par(fb.Box x, fb.Box y):
    """The parallel composition of two blocks (e.g., A,B)."""
    return fb.boxPar(x, y)

cdef fb.Box box_par3(fb.Box x, fb.Box y, fb.Box z):
    """The parallel composition of three blocks (e.g., A,B,C)."""
    return fb.boxPar3(x, y, z)

cdef fb.Box box_par4(fb.Box a, fb.Box b, fb.Box c, fb.Box d):
    """The parallel composition of four blocks (e.g., A,B,C,D)."""
    return fb.boxPar4(a, b, c, d)

cdef fb.Box box_par5(fb.Box a, fb.Box b, fb.Box c, fb.Box d, fb.Box e):
    """The parallel composition of five blocks (e.g., A,B,C,D,E)."""
    return fb.boxPar5(a, b, c, d, e)

cdef fb.Box box_split(fb.Box x, fb.Box y):
    """The split composition (e.g., A<:B) operator is used to distribute
    the outputs of A to the inputs of B.
    """
    return fb.boxSplit(x, y)

cdef fb.Box box_merge(fb.Box x, fb.Box y):
    """The merge composition (e.g., A:>B) is the dual of the split composition."""
    return fb.boxMerge(x, y)

cdef fb.Box box_rec(fb.Box x, fb.Box y):
    """The recursive composition (e.g., A~B) is used to create cycles in the 
    block-diagram in order to express recursive computations.
    """
    return fb.boxRec(x, y)

cdef fb.Box box_route(fb.Box n, fb.Box m, fb.Box r):
    """The route primitive facilitates the routing of signals in Faust."""
    return fb.boxRoute(n, m, r)

cdef fb.Box box_delay_():
    """Create a delayed box."""
    return fb.boxDelay()

cdef fb.Box box_delay(fb.Box b, fb.Box del_):
    """Create a delayed box."""
    return fb.boxDelay(b, del_)

cdef fb.Box box_int_cast(fb.Box b):
    """Create a casted box."""
    return fb.boxIntCast(b)

cdef fb.Box box_int_cast_():
    """Create a casted box."""
    return fb.boxIntCast()

cdef fb.Box box_float_cast(fb.Box b):
    """Create a casted box."""
    return fb.boxFloatCast(b)

cdef fb.Box box_float_cast_():
    """Create a casted box."""
    return fb.boxFloatCast()

cdef fb.Box box_read_only_table(fb.Box n, fb.Box init, fb.Box ridx):
    """Create a read only table."""
    return fb.boxReadOnlyTable(n, init, ridx)

cdef fb.Box box_read_only_table_():
    """Create a read only table."""
    return fb.boxReadOnlyTable()

cdef fb.Box box_write_read_table(fb.Box n, fb.Box init, fb.Box widx, fb.Box wsig, fb.Box ridx):
    """Create a read/write table."""
    return fb.boxWriteReadTable(n, init, widx, wsig, ridx)

cdef fb.Box box_write_read_table_(f):
    """Create a read/write table."""
    return fb.boxWriteReadTable()

cdef fb.Box box_waveform(const fb.tvec& wf):
    """Create a waveform."""
    return fb.boxWaveform(wf)

cdef fb.Box box_soundfile(const string& label, fb.Box chan):
    """Create a soundfile block."""
    return fb.boxSoundfile(label, chan)

cdef fb.Box box_soundfile_(const string& label, fb.Box chan, fb.Box part, fb.Box ridx):
    """Create a soundfile block."""
    return fb.boxSoundfile(label, chan, part, ridx)

cdef fb.Box box_select2(fb.Box selector, fb.Box b1, fb.Box b2):
    """Create a selector between two boxes."""
    return fb.boxSelect2(selector, b1, b2)

cdef fb.Box box_select2_():
    """Create a selector between two boxes."""
    return fb.boxSelect2()

cdef fb.Box box_select3(fb.Box selector, fb.Box b1, fb.Box b2, fb.Box b3):
    """Create a selector between three boxes."""
    return fb.boxSelect3(selector, b1, b2, b3)

cdef fb.Box box_select3_():
    """Create a selector between three boxes."""
    return fb.boxSelect3()

cdef fb.Box box_f_const(fb.SType type, const string& name, const string& file):
    """Create a foreign constant box."""
    return fb.boxFConst(type, name, file)

cdef fb.Box box_f_var(fb.SType type, const string& name, const string& file):
    """Create a foreign variable box."""
    return fb.boxFVar(type, name, file)

cdef fb.Box box_bin_op(fb.SOperator op):
    """Generic binary mathematical functions."""
    return fb.boxBinOp(op)

cdef fb.Box box_bin_op_with_box(fb.SOperator op, fb.Box b1, fb.Box b2):
    """Generic binary mathematical functions."""
    return fb.boxBinOp(op, b1, b2)

cdef fb.Box box_add(fb.Box b1, fb.Box b2):
    """Add two boxes."""
    return fb.boxAdd(b1, b2)

cdef fb.Box box_sub(fb.Box b1, fb.Box b2):
    """Subtract two boxes."""
    return fb.boxSub(b1, b2)

cdef fb.Box box_mul(fb.Box b1, fb.Box b2):
    """Multiply two boxes."""
    return fb.boxMul(b1, b2)

cdef fb.Box box_div(fb.Box b1, fb.Box b2):
    """Divide two boxes."""
    return fb.boxDiv(b1, b2)

cdef fb.Box box_rem(fb.Box b1, fb.Box b2):
    return fb.boxRem(b1, b2)

cdef fb.Box box_left_shift(fb.Box b1, fb.Box b2):
    return fb.boxLeftShift(b1, b2)

cdef fb.Box box_l_right_shift(fb.Box b1, fb.Box b2):
    return fb.boxLRightShift(b1, b2)

cdef fb.Box box_a_right_shift(fb.Box b1, fb.Box b2):
    return fb.boxARightShift(b1, b2)

cdef fb.Box box_gt(fb.Box b1, fb.Box b2):
    """Greater than"""
    return fb.boxGT(b1, b2)

cdef fb.Box box_lt(fb.Box b1, fb.Box b2):
    """Lesser than"""
    return fb.boxLT(b1, b2)

cdef fb.Box box_ge(fb.Box b1, fb.Box b2):
    """Greater than or equal"""
    return fb.boxGE(b1, b2)

cdef fb.Box box_le(fb.Box b1, fb.Box b2):
    """Lesser than or equal"""
    return fb.boxLE(b1, b2)

cdef fb.Box box_eq(fb.Box b1, fb.Box b2):
    """Equals"""
    return fb.boxEQ(b1, b2)

cdef fb.Box box_ne(fb.Box b1, fb.Box b2):
    """Not Equals"""
    return fb.boxNE(b1, b2)

cdef fb.Box box_and(fb.Box b1, fb.Box b2):
    return fb.boxAND(b1, b2)

cdef fb.Box box_or(fb.Box b1, fb.Box b2):
    return fb.boxOR(b1, b2)

cdef fb.Box box_xor(fb.Box b1, fb.Box b2):
    return fb.boxXOR(b1, b2)

cdef fb.Box box_abs(fb.Box x):
    return fb.boxAbs(x)

cdef fb.Box box_acos(fb.Box x):
    return fb.boxAcos(x)

cdef fb.Box box_tan(fb.Box x):
    return fb.boxTan(x)

cdef fb.Box box_sqrt(fb.Box x):
    return fb.boxSqrt(x)

cdef fb.Box box_sin(fb.Box x):
    return fb.boxSin(x)

cdef fb.Box box_rint(fb.Box x):
    return fb.boxRint(x)

cdef fb.Box box_round(fb.Box x):
    return fb.boxRound(x)

cdef fb.Box box_log(fb.Box x):
    return fb.boxLog(x)

cdef fb.Box box_log10(fb.Box x):
    return fb.boxLog10(x)

cdef fb.Box box_floor(fb.Box x):
    return fb.boxFloor(x)

cdef fb.Box box_exp(fb.Box x):
    return fb.boxExp(x)

cdef fb.Box box_exp10(fb.Box x):
    return fb.boxExp10(x)

cdef fb.Box box_cos(fb.Box x):
    return fb.boxCos(x)

cdef fb.Box box_ceil(fb.Box x):
    return fb.boxCeil(x)

cdef fb.Box box_atan(fb.Box x):
    return fb.boxAtan(x)

cdef fb.Box box_asin(fb.Box x):
    return fb.boxAsin(x)

cdef fb.Box box_remainder(fb.Box b1, fb.Box b2):
    return fb.boxRemainder(b1, b2)

cdef fb.Box box_pow(fb.Box b1, fb.Box b2):
    return fb.boxPow(b1, b2)

cdef fb.Box box_min(fb.Box b1, fb.Box b2):
    return fb.boxMin(b1, b2)

cdef fb.Box box_max(fb.Box b1, fb.Box b2):
    return fb.boxMax(b1, b2)

cdef fb.Box box_fmod(fb.Box b1, fb.Box b2):
    return fb.boxFmod(b1, b2)

cdef fb.Box box_atan2(fb.Box b1, fb.Box b2):
    return fb.boxAtan2(b1, b2)

cdef fb.Box box_button(const string& label):
    """Create a button box."""
    return fb.boxButton(label)

cdef fb.Box box_checkbox(const string& label):
    """Create a checkbox box."""
    return fb.boxCheckbox(label)

cdef fb.Box box_v_slider(const string& label, fb.Box init, fb.Box min, fb.Box max, fb.Box step):
    """Create a verical slider box."""
    return fb.boxVSlider(label, init, min, max, step)

cdef fb.Box box_h_slider(const string& label, fb.Box init, fb.Box min, fb.Box max, fb.Box step):
    """Create a horizontal slider box."""
    return fb.boxHSlider(label, init, min, max, step)

cdef fb.Box box_num_entry(const string& label, fb.Box init, fb.Box min, fb.Box max, fb.Box step):
    """Create a numeric entry box."""
    return fb.boxNumEntry(label, init, min, max, step)

cdef fb.Box box_v_bargraph(const string& label, fb.Box min, fb.Box max):
    """Create a vertical bargraph box."""
    return fb.boxVBargraph(label, min, max)

cdef fb.Box box_v_bargraph2(const string& label, fb.Box min, fb.Box max, fb.Box x):
    """Create a vertical bargraph box."""
    return fb.boxVBargraph(label, min, max, x)

cdef fb.Box box_h_bargraph(const string& label, fb.Box min, fb.Box max):
    """Create a horizontal bargraph box."""
    return fb.boxHBargraph(label, min, max)

cdef fb.Box box_h_bargraph2(const string& label, fb.Box min, fb.Box max, fb.Box x):
    """Create a horizontal bargraph box."""
    return fb.boxHBargraph(label, min, max, x)

cdef fb.Box box_v_group(const string& label, fb.Box group):
    """Create a vertical group box."""
    return fb.boxVGroup(label, group)

cdef fb.Box box_h_group(const string& label, fb.Box group):
    """Create a horizontal group box."""
    return fb.boxHGroup(label, group)

cdef fb.Box box_t_group(const string& label, fb.Box group):
    """Create a tab group box."""
    return fb.boxTGroup(label, group)

cdef fb.Box box_attach(fb.Box b1, fb.Box b2):
    """Create an attach box."""
    return fb.boxAttach(b1, b2)

cdef fb.Box box_prim2(fb.prim2 foo):
    return fb.boxPrim2(foo)

cdef bint is_box_abstr(fb.Box t):
    return fb.isBoxAbstr(t)

cdef bint is_box_abstr_(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxAbstr(t, x, y)

cdef bint is_box_access(fb.Box t, fb.Box& exp, fb.Box& id):
    return fb.isBoxAccess(t, exp, id)

cdef bint is_box_appl(fb.Box t):
    return fb.isBoxAppl(t)

cdef bint is_box_appl_(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxAppl(t, x, y)

cdef bint is_box_button(fb.Box b):
    return fb.isBoxButton(b)

cdef bint is_box_button_(fb.Box b, fb.Box& lbl):
    return fb.isBoxButton(b, lbl)

cdef bint is_box_case(fb.Box b):
    return fb.isBoxCase(b)

cdef bint is_box_case_(fb.Box b, fb.Box& rules):
    return fb.isBoxCase(b, rules)

cdef bint is_box_checkbox(fb.Box b):
    return fb.isBoxCheckbox(b)

cdef bint is_box_checkbox_(fb.Box b, fb.Box& lbl):
    return fb.isBoxCheckbox(b, lbl)

cdef bint is_box_component(fb.Box b, fb.Box& filename):
    return fb.isBoxComponent(b, filename)

cdef bint is_box_cut(fb.Box t):
    return fb.isBoxCut(t)

cdef bint is_box_environment(fb.Box b):
    return fb.isBoxEnvironment(b)

cdef bint is_box_error(fb.Box t):
    return fb.isBoxError(t)

cdef bint is_box_f_const_(fb.Box b):
    return fb.isBoxFConst(b)

cdef bint is_box_f_const(fb.Box b, fb.Box& type, fb.Box& name, fb.Box& file):
    return fb.isBoxFConst(b, type, name, file)

cdef bint is_box_f_fun_(fb.Box b):
    return fb.isBoxFFun(b)

cdef bint is_box_f_fun(fb.Box b, fb.Box& ff):
    return fb.isBoxFFun(b, ff)

cdef bint is_box_f_var_(fb.Box b):
    return fb.isBoxFVar(b)

cdef bint is_box_f_var(fb.Box b, fb.Box& type, fb.Box& name, fb.Box& file):
    return fb.isBoxFVar(b, type, name, file)

cdef bint is_box_h_bargraph_(fb.Box b):
    return fb.isBoxHBargraph(b)

cdef bint is_box_h_bargraph(fb.Box b, fb.Box& lbl, fb.Box& min, fb.Box& max):
    return fb.isBoxHBargraph(b, lbl, min, max)

cdef bint is_box_h_group_(fb.Box b):
    return fb.isBoxHGroup(b)

cdef bint is_box_h_group(fb.Box b, fb.Box& lbl, fb.Box& x):
    return fb.isBoxHGroup(b, lbl, x)

cdef bint is_box_h_slider_(fb.Box b):
    return fb.isBoxHSlider(b)

cdef bint is_box_h_slider(fb.Box b, fb.Box& lbl, fb.Box& cur, fb.Box& min, fb.Box& max, fb.Box& step):
    return fb.isBoxHSlider(b, lbl, cur, min, max, step)

cdef bint is_box_ident_(fb.Box t):
    return fb.isBoxIdent(t)

cdef bint is_box_ident(fb.Box t, const char** str):
    return fb.isBoxIdent(t, str)

cdef bint is_box_inputs(fb.Box t, fb.Box& x):
    return fb.isBoxInputs(t, x)

cdef bint is_box_int_(fb.Box t):
    return fb.isBoxInt(t)

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

cdef bint is_box_num_entry_(fb.Box b):
    return fb.isBoxNumEntry(b)

cdef bint is_box_num_entry(fb.Box b, fb.Box& lbl, fb.Box& cur, fb.Box& min_, fb.Box& max_, fb.Box& step):
    return fb.isBoxNumEntry(b, lbl, cur, min_, max_, step)

cdef bint is_box_outputs(fb.Box t, fb.Box& x):
    return fb.isBoxOutputs(t, x)

cdef bint is_box_par(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxPar(t, x, y)

cdef bint is_box_prim0(fb.Box b):
    return fb.isBoxPrim0(b)

cdef bint is_box_prim1(fb.Box b):
    return fb.isBoxPrim1(b)

cdef bint is_box_prim2(fb.Box b):
    return fb.isBoxPrim2(b)

cdef bint is_box_prim3(fb.Box b):
    return fb.isBoxPrim3(b)

cdef bint is_box_prim4(fb.Box b):
    return fb.isBoxPrim4(b)

cdef bint is_box_prim5(fb.Box b):
    return fb.isBoxPrim5(b)

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

cdef bint is_box_real_(fb.Box t):
    return fb.isBoxReal(t)

cdef bint is_box_real(fb.Box t, double* r):
    return fb.isBoxReal(t, r)

cdef bint is_box_rec(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxRec(t, x, y)

cdef bint is_box_route(fb.Box b, fb.Box& n, fb.Box& m, fb.Box& r):
    return fb.isBoxRoute(b, n, m, r)

cdef bint is_box_seq(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxSeq(t, x, y)

cdef bint is_box_slot(fb.Box t):
    return fb.isBoxSlot(t)

cdef bint is_box_soundfile_(fb.Box b):
    return fb.isBoxSoundfile(b)

cdef bint is_box_soundfile(fb.Box b, fb.Box& label, fb.Box& chan):
    return fb.isBoxSoundfile(b, label, chan)

cdef bint is_box_split(fb.Box t, fb.Box& x, fb.Box& y):
    return fb.isBoxSplit(t, x, y)

cdef bint is_box_symbolic_(fb.Box t):
    return fb.isBoxSymbolic(t)

cdef bint is_box_symbolic(fb.Box t, fb.Box& slot, fb.Box& body):
    return fb.isBoxSymbolic(t, slot, body)

cdef bint is_box_t_group_(fb.Box b):
    return fb.isBoxTGroup(b)

cdef bint is_box_t_group(fb.Box b, fb.Box& lbl, fb.Box& x):
    return fb.isBoxTGroup(b, lbl, x)

cdef bint is_box_v_bargraph_(fb.Box b):
    return fb.isBoxVBargraph(b)

cdef bint is_box_v_bargraph(fb.Box b, fb.Box& lbl, fb.Box& min, fb.Box& max):
    return fb.isBoxVBargraph(b, lbl, min, max)

cdef bint is_box_v_group_(fb.Box b):
    return fb.isBoxVGroup(b)

cdef bint is_box_v_group(fb.Box b, fb.Box& lbl, fb.Box& x):
    return fb.isBoxVGroup(b, lbl, x)

cdef bint is_box_v_slider_(fb.Box b):
    return fb.isBoxVSlider(b)

cdef bint is_box_v_slider(fb.Box b, fb.Box& lbl, fb.Box& cur, fb.Box& min, fb.Box& max, fb.Box& step):
    return fb.isBoxVSlider(b, lbl, cur, min, max, step)

cdef bint is_box_waveform(fb.Box b):
    return fb.isBoxWaveform(b)

cdef bint is_box_wire(fb.Box t):
    return fb.isBoxWire(t)

cdef bint is_box_with_local_def(fb.Box t, fb.Box& body, fb.Box& ldef):
    return fb.isBoxWithLocalDef(t, body, ldef)

cdef fb.Box dsp_to_boxes(const string& name_app, const string& dsp_content, int argc, const char* argv[], int* inputs, int* outputs, string& error_msg):
    """Compile a DSP source code as a string in a flattened box."""
    return fb.DSPToBoxes(name_app, dsp_content, argc, argv, inputs, outputs, error_msg)

cdef bint get_box_type(fb.Box box, int* inputs, int* outputs):
    """Return the number of inputs and outputs of a box."""
    return fb.getBoxType(box, inputs, outputs)

cdef fb.tvec boxes_to_signals(fb.Box box, string& error_msg):
    """Compile a box expression in a list of signals in normal form."""
    return fb.boxesToSignals(box, error_msg)

cdef fb.string create_source_from_boxes(const string& name_app, fb.Box box, const string& lang, int argc, const char* argv[], string& error_msg):
    """Create source code in a target language from a box expression."""
    return fb.createSourceFromBoxes(name_app, box, lang, argc, argv, error_msg)

