
## ---------------------------------------------------------------------------
## faust/dsp/libfaust-box

class box_context:
    def __enter__(self):
        fb.createLibContext()
    def __exit__(self, type, value, traceback):
        fb.destroyLibContext()


cdef class Box:
    """faust Box wrapper.
    """
    cdef fb.Box ptr

    def __cinit__(self):
        self.ptr = NULL

    @staticmethod
    cdef Box from_ptr(fb.Box ptr, bint ptr_owner=False):
        """Wrap external factory from pointer"""
        cdef Box box = Box.__new__(Box)
        box.ptr = ptr
        return box

    @staticmethod
    def from_int(int value) -> Box:
        """Create box from int"""
        cdef fb.Box b = fb.boxInt(value)
        return Box.from_ptr(b)

    @staticmethod
    def from_float(float value) -> Box:
        """Create box from float"""
        cdef fb.Box b = fb.boxReal(value)
        return Box.from_ptr(b)

    def create_source(self, name_app: str, lang, *args) -> str:
        """Create source code in a target language from a box expression."""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef ParamArray params = ParamArray(args)
        cdef string src = fb.createSourceFromBoxes(
            name_app,
            self.ptr,
            lang,
            params.argc,
            params.argv,
            error_msg)
        if error_msg.empty():
            print(error_msg.decode())
            return
        return src.decode()

    def print(self, shared: bool = False, max_size: int = 256):
        """Print this box."""
        print(fb.printBox(self.ptr, shared, max_size).decode())

    def __add__(self, Box other):
        """Add this box to another."""
        cdef fb.Box b = fb.boxAdd(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __radd__(self, Box other):
        """Reverse add this box to another."""
        cdef fb.Box b = fb.boxAdd(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __sub__(self, Box other):
        """Subtract this box from another."""
        cdef fb.Box b = fb.boxSub(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __rsub__(self, Box other):
        """Subtract this box from another."""
        cdef fb.Box b = fb.boxSub(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __mul__(self, Box other):
        """Multiply this box with another."""
        cdef fb.Box b = fb.boxMul(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __rmul__(self, Box other):
        """Reverse multiply this box with another."""
        cdef fb.Box b = fb.boxMul(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __div__(self, Box other):
        """Divide this box with another."""
        cdef fb.Box b = fb.boxDiv(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __rdiv__(self, Box other):
        """Reverse divide this box with another."""
        cdef fb.Box b = fb.boxDiv(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __eq__(self, Box other):
        """Compare for equality with another box."""
        cdef fb.Box b = fb.boxEQ(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __ne__(self, Box other):
        """Assert this box is not equal with another box."""
        cdef fb.Box b = fb.boxNE(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __gt__(self, Box other):
        """Is this box greater than another box."""
        cdef fb.Box b = fb.boxGT(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __ge__(self, Box other):
        """Is this box greater than or equal from another box."""
        cdef fb.Box b = fb.boxGE(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __lt__(self, Box other):
        """Is this box lesser than another box."""
        cdef fb.Box b = fb.boxLT(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __le__(self, Box other):
        """Is this box lesser than or equal from another box."""
        cdef fb.Box b = fb.boxLE(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __and__(self, Box other):
        """logical and with another box"""
        cdef fb.Box b = fb.boxAND(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __or__(self, Box other):
        """logical or with another box"""
        cdef fb.Box b = fb.boxOR(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __xor__(self, Box other):
        """logical xor with another box"""
        cdef fb.Box b = fb.boxXOR(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __lshift__(self, Box other):
        """bitwise left-shift"""
        cdef fb.Box b = fb.boxLeftShift(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __rshift__(self, Box other):
        """bitwise right-shift"""
        cdef fb.Box b = fb.boxLRightShift(self.ptr, other.ptr)
        return Box.from_ptr(b)

    # TODO: ???
    # Box boxARightShift()
    # Box boxARightShift(Box b1, Box b2)

    def to_string(self):
        """Convert this box tree (such as the label of a UI) to a string."""
        return fb.tree2str(self.ptr).decode()

    def to_int(self):
        """If this box tree has a node of type int, return it, otherwise error."""
        return fb.tree2int(self.ptr).decode()

    def abs(self) -> Box: 
        cdef fb.Box b = fb.boxAbs(self.ptr)
        return Box.from_ptr(b)

    def acos(self) -> Box: 
        cdef fb.Box b = fb.boxAcos(self.ptr)
        return Box.from_ptr(b)

    def tan(self) -> Box: 
        cdef fb.Box b = fb.boxTan(self.ptr)
        return Box.from_ptr(b)

    def sqrt(self) -> Box: 
        cdef fb.Box b = fb.boxSqrt(self.ptr)
        return Box.from_ptr(b)

    def sin(self) -> Box: 
        cdef fb.Box b = fb.boxSin(self.ptr)
        return Box.from_ptr(b)

    def rint(self) -> Box: 
        cdef fb.Box b = fb.boxRint(self.ptr)
        return Box.from_ptr(b)

    def round(self) -> Box: 
        cdef fb.Box b = fb.boxRound(self.ptr)
        return Box.from_ptr(b)

    def log(self) -> Box: 
        cdef fb.Box b = fb.boxLog(self.ptr)
        return Box.from_ptr(b)

    def log10(self) -> Box: 
        cdef fb.Box b = fb.boxLog10(self.ptr)
        return Box.from_ptr(b)

    def floor(self) -> Box: 
        cdef fb.Box b = fb.boxFloor(self.ptr)
        return Box.from_ptr(b)

    def exp(self) -> Box: 
        cdef fb.Box b = fb.boxExp(self.ptr)
        return Box.from_ptr(b)

    def exp10(self) -> Box: 
        cdef fb.Box b = fb.boxExp10(self.ptr)
        return Box.from_ptr(b)

    def cos(self) -> Box: 
        cdef fb.Box b = fb.boxCos(self.ptr)
        return Box.from_ptr(b)

    def ceil(self) -> Box: 
        cdef fb.Box b = fb.boxCeil(self.ptr)
        return Box.from_ptr(b)

    def atan(self) -> Box: 
        cdef fb.Box b = fb.boxAtan(self.ptr)
        return Box.from_ptr(b)

    def asin(self) -> Box: 
        cdef fb.Box b = fb.boxAsin(self.ptr)
        return Box.from_ptr(b)

    def is_nil(self) -> bool:
        """Check if a box is nil."""
        return fb.isNil(self.ptr)

    def is_box_abstr(self) -> bool:
        return fb.isBoxAbstr(self.ptr)

    def is_box_appl(self) -> bool:
        return fb.isBoxAppl(self.ptr)

    def is_box_button(self) -> bool:
        return fb.isBoxButton(self.ptr)

    def is_box_case(self) -> bool:
        return fb.isBoxCase(self.ptr)

    def is_box_checkbox(self) -> bool:
        return fb.isBoxCheckbox(self.ptr)

    def is_box_cut(self) -> bool:
        return fb.isBoxCut(self.ptr)

    def is_box_environment(self) -> bool:
        return fb.isBoxEnvironment(self.ptr)

    def is_box_error(self) -> bool:
        return fb.isBoxError(self.ptr)

    def is_box_f_const(self) -> bool:
        return fb.isBoxFConst(self.ptr)

    def is_box_f_fun(self) -> bool:
        return fb.isBoxFFun(self.ptr)

    def is_box_f_var_(self) -> bool:
        return fb.isBoxFVar(self.ptr)

    def is_box_h_bargraph(self) -> bool:
        return fb.isBoxHBargraph(self.ptr)

    def is_box_h_group(self) -> bool:
        return fb.isBoxHGroup(self.ptr)

    def is_box_h_slider(self) -> bool:
        return fb.isBoxHSlider(self.ptr)

    def is_box_ident(self) -> bool:
        return fb.isBoxIdent(self.ptr)

    def is_box_int(self) -> bool:
        return fb.isBoxInt(self.ptr)

    def is_box_num_entry(self) -> bool:
        return fb.isBoxNumEntry(self.ptr)

    def is_box_prim0(self) -> bool:
        return fb.isBoxPrim0(self.ptr)

    def is_box_prim1(self) -> bool:
        return fb.isBoxPrim1(self.ptr)

    def is_box_prim2(self) -> bool:
        return fb.isBoxPrim2(self.ptr)

    def is_box_prim3(self) -> bool:
        return fb.isBoxPrim3(self.ptr)

    def is_box_prim4(self) -> bool:
        return fb.isBoxPrim4(self.ptr)

    def is_box_prim5(self) -> bool:
        return fb.isBoxPrim5(self.ptr)

    def is_box_real_(self) -> bool:
        return fb.isBoxReal(self.ptr)

    def is_box_slot(self) -> bool:
        return fb.isBoxSlot(self.ptr)

    def is_box_soundfile(self) -> bool:
        return fb.isBoxSoundfile(self.ptr)

    def is_box_symbolic(self) -> bool:
        return fb.isBoxSymbolic(self.ptr)

    def is_box_t_group(self) -> bool:
        return fb.isBoxTGroup(self.ptr)

    def is_box_v_group(self) -> bool:
        return fb.isBoxVGroup(self.ptr)

    def is_box_v_slider(self) -> bool:
        return fb.isBoxVSlider(self.ptr)

    def is_box_waveform(self) -> bool:
        return fb.isBoxWaveform(self.ptr)

    def is_box_wire(self) -> bool:
        return fb.isBoxWire(self.ptr)


cdef class Int(Box):

    def __cinit__(self, int value):
        self.ptr = <fb.Box>fb.boxInt(value)

    @staticmethod
    cdef Int from_ptr(fb.Box ptr, bint ptr_owner=False):
        """Wrap external factory from pointer"""
        cdef Int box = Int.__new__(Int)
        box.ptr = ptr
        return box


# cdef class Int:
#     cdef fb.Box ptr

#     def __cinit__(self, int value):
#         self.ptr = <fb.Box>fb.boxInt(value)

#     @staticmethod
#     cdef Int from_ptr(fb.Box ptr, bint ptr_owner=False):
#         """Wrap external factory from pointer"""
#         cdef Int box = Int.__new__(Int)
#         box.ptr = ptr
#         return box

#     def print(self, shared: bool = False, max_size: int = 256):
#         """Print this box."""
#         print(fb.printBox(self.ptr, shared, max_size).decode())

#     def __add__(self, Box other):
#         """Add this box to another."""
#         cdef fb.Box b = fb.boxAdd(self.ptr, other.ptr)
#         return Box.from_ptr(b)

#     def __radd__(self, Box other):
#         """Reverse add this box to another."""
#         cdef fb.Box b = fb.boxAdd(self.ptr, other.ptr)
#         return Box.from_ptr(b)


# cdef string print_signal(fs.Signal sig, bint shared, int max_size):
#     """Print a signal."""
#     return fs.printSignal(sig, shared, max_size)


# cdef bint get_def_name_property(fb.Box b, fb.Box& id):
#     """Indicates the identifier (if any) the expression was a definition of.

#     b the expression
#     id reference to the identifier

#     returns true if the expression b was a definition of id
#     """
#     cdef fb.Box id = NULL
#     return fb.getDefNameProperty(b, id)

# cdef string extract_name(fb.Box full_label):
#     """Extract the name from a label."""
#     return fb.extractName(full_label)

# def create_lib_context():
#     """Create global compilation context, has to be done first."""
#     fb.createLibContext()

# def destroy_lib_context():
#     """Destroy global compilation context, has to be done last."""
#     fb.destroyLibContext()


# cdef void* get_user_data(fb.Box b):
#     """Return the extended type of a box."""
#     return fb.getUserData(b)

# cdef fb.Box box_int(int n):
#     """Constant integer : for all t, x(t) = n."""
#     return fb.boxInt(n)

# cdef fb.Box box_real(double n):
#     """Constant real : for all t, x(t) = n."""
#     return fb.boxReal(n)

# cdef fb.Box box_wire():
#     """The identity box, copy its input to its output."""
#     return fb.boxWire()

# cdef fb.Box box_cut():
#     """The cut box, to "stop"/terminate a signal."""
#     return fb.boxCut()

# cdef fb.Box box_seq(fb.Box x, fb.Box y):
#     """The sequential composition of two blocks (e.g., A:B) expects: outputs(A)=inputs(B)."""
#     return fb.boxSeq(x, y)

# cdef fb.Box box_par(fb.Box x, fb.Box y):
#     """The parallel composition of two blocks (e.g., A,B)."""
#     return fb.boxPar(x, y)

# cdef fb.Box box_par3(fb.Box x, fb.Box y, fb.Box z):
#     """The parallel composition of three blocks (e.g., A,B,C)."""
#     return fb.boxPar3(x, y, z)

# cdef fb.Box box_par4(fb.Box a, fb.Box b, fb.Box c, fb.Box d):
#     """The parallel composition of four blocks (e.g., A,B,C,D)."""
#     return fb.boxPar4(a, b, c, d)

# cdef fb.Box box_par5(fb.Box a, fb.Box b, fb.Box c, fb.Box d, fb.Box e):
#     """The parallel composition of five blocks (e.g., A,B,C,D,E)."""
#     return fb.boxPar5(a, b, c, d, e)

# cdef fb.Box box_split(fb.Box x, fb.Box y):
#     """The split composition (e.g., A<:B) operator is used to distribute
#     the outputs of A to the inputs of B.
#     """
#     return fb.boxSplit(x, y)

# cdef fb.Box box_merge(fb.Box x, fb.Box y):
#     """The merge composition (e.g., A:>B) is the dual of the split composition."""
#     return fb.boxMerge(x, y)

# cdef fb.Box box_rec(fb.Box x, fb.Box y):
#     """The recursive composition (e.g., A~B) is used to create cycles in the 
#     block-diagram in order to express recursive computations.
#     """
#     return fb.boxRec(x, y)

# cdef fb.Box box_route(fb.Box n, fb.Box m, fb.Box r):
#     """The route primitive facilitates the routing of signals in Faust."""
#     return fb.boxRoute(n, m, r)

# cdef fb.Box box_delay_():
#     """Create a delayed box."""
#     return fb.boxDelay()

# cdef fb.Box box_delay(fb.Box b, fb.Box del_):
#     """Create a delayed box."""
#     return fb.boxDelay(b, del_)

# cdef fb.Box box_int_cast(fb.Box b):
#     """Create a casted box."""
#     return fb.boxIntCast(b)

# cdef fb.Box box_int_cast_():
#     """Create a casted box."""
#     return fb.boxIntCast()

# cdef fb.Box box_float_cast(fb.Box b):
#     """Create a casted box."""
#     return fb.boxFloatCast(b)

# cdef fb.Box box_float_cast_():
#     """Create a casted box."""
#     return fb.boxFloatCast()

# cdef fb.Box box_read_only_table(fb.Box n, fb.Box init, fb.Box ridx):
#     """Create a read only table."""
#     return fb.boxReadOnlyTable(n, init, ridx)

# cdef fb.Box box_read_only_table_():
#     """Create a read only table."""
#     return fb.boxReadOnlyTable()

# cdef fb.Box box_write_read_table(fb.Box n, fb.Box init, fb.Box widx, fb.Box wsig, fb.Box ridx):
#     """Create a read/write table."""
#     return fb.boxWriteReadTable(n, init, widx, wsig, ridx)

# cdef fb.Box box_write_read_table_(f):
#     """Create a read/write table."""
#     return fb.boxWriteReadTable()

# cdef fb.Box box_waveform(const fs.tvec& wf):
#     """Create a waveform."""
#     return fb.boxWaveform(wf)

# cdef fb.Box box_soundfile(const string& label, fb.Box chan):
#     """Create a soundfile block."""
#     return fb.boxSoundfile(label, chan)

# cdef fb.Box box_soundfile_(const string& label, fb.Box chan, fb.Box part, fb.Box ridx):
#     """Create a soundfile block."""
#     return fb.boxSoundfile(label, chan, part, ridx)

# cdef fb.Box box_select2(fb.Box selector, fb.Box b1, fb.Box b2):
#     """Create a selector between two boxes."""
#     return fb.boxSelect2(selector, b1, b2)

# cdef fb.Box box_select2_():
#     """Create a selector between two boxes."""
#     return fb.boxSelect2()

# cdef fb.Box box_select3(fb.Box selector, fb.Box b1, fb.Box b2, fb.Box b3):
#     """Create a selector between three boxes."""
#     return fb.boxSelect3(selector, b1, b2, b3)

# cdef fb.Box box_select3_():
#     """Create a selector between three boxes."""
#     return fb.boxSelect3()

# cdef fb.Box box_f_const(fb.SType type, const string& name, const string& file):
#     """Create a foreign constant box."""
#     return fb.boxFConst(type, name, file)

# cdef fb.Box box_f_var(fb.SType type, const string& name, const string& file):
#     """Create a foreign variable box."""
#     return fb.boxFVar(type, name, file)

# cdef fb.Box box_bin_op(fb.SOperator op):
#     """Generic binary mathematical functions."""
#     return fb.boxBinOp(op)

# cdef fb.Box box_bin_op_with_box(fb.SOperator op, fb.Box b1, fb.Box b2):
#     """Generic binary mathematical functions."""
#     return fb.boxBinOp(op, b1, b2)


# cdef fb.Box box_rem(fb.Box b1, fb.Box b2):
#     return fb.boxRem(b1, b2)

# cdef fb.Box box_left_shift(fb.Box b1, fb.Box b2):
#     return fb.boxLeftShift(b1, b2)

# cdef fb.Box box_l_right_shift(fb.Box b1, fb.Box b2):
#     return fb.boxLRightShift(b1, b2)

# cdef fb.Box box_a_right_shift(fb.Box b1, fb.Box b2):
#     return fb.boxARightShift(b1, b2)


# # cdef fb.Box box_abs(fb.Box x):
# #     return fb.boxAbs(x)

# # cdef fb.Box box_acos(fb.Box x):
# #     return fb.boxAcos(x)

# # cdef fb.Box box_tan(fb.Box x):
# #     return fb.boxTan(x)

# # cdef fb.Box box_sqrt(fb.Box x):
# #     return fb.boxSqrt(x)

# # cdef fb.Box box_sin(fb.Box x):
# #     return fb.boxSin(x)

# # cdef fb.Box box_rint(fb.Box x):
# #     return fb.boxRint(x)

# # cdef fb.Box box_round(fb.Box x):
# #     return fb.boxRound(x)

# # cdef fb.Box box_log(fb.Box x):
# #     return fb.boxLog(x)

# # cdef fb.Box box_log10(fb.Box x):
# #     return fb.boxLog10(x)

# # cdef fb.Box box_floor(fb.Box x):
# #     return fb.boxFloor(x)

# # cdef fb.Box box_exp(fb.Box x):
# #     return fb.boxExp(x)

# # cdef fb.Box box_exp10(fb.Box x):
# #     return fb.boxExp10(x)

# # cdef fb.Box box_cos(fb.Box x):
# #     return fb.boxCos(x)

# # cdef fb.Box box_ceil(fb.Box x):
# #     return fb.boxCeil(x)

# # cdef fb.Box box_atan(fb.Box x):
# #     return fb.boxAtan(x)

# # cdef fb.Box box_asin(fb.Box x):
# #     return fb.boxAsin(x)

# cdef fb.Box box_remainder(fb.Box b1, fb.Box b2):
#     return fb.boxRemainder(b1, b2)

# cdef fb.Box box_pow(fb.Box b1, fb.Box b2):
#     return fb.boxPow(b1, b2)

# cdef fb.Box box_min(fb.Box b1, fb.Box b2):
#     return fb.boxMin(b1, b2)

# cdef fb.Box box_max(fb.Box b1, fb.Box b2):
#     return fb.boxMax(b1, b2)

# cdef fb.Box box_fmod(fb.Box b1, fb.Box b2):
#     return fb.boxFmod(b1, b2)

# cdef fb.Box box_atan2(fb.Box b1, fb.Box b2):
#     return fb.boxAtan2(b1, b2)

# cdef fb.Box box_button(const string& label):
#     """Create a button box."""
#     return fb.boxButton(label)

# cdef fb.Box box_checkbox(const string& label):
#     """Create a checkbox box."""
#     return fb.boxCheckbox(label)

# cdef fb.Box box_v_slider(const string& label, fb.Box init, fb.Box min, fb.Box max, fb.Box step):
#     """Create a verical slider box."""
#     return fb.boxVSlider(label, init, min, max, step)

# cdef fb.Box box_h_slider(const string& label, fb.Box init, fb.Box min, fb.Box max, fb.Box step):
#     """Create a horizontal slider box."""
#     return fb.boxHSlider(label, init, min, max, step)

# cdef fb.Box box_num_entry(const string& label, fb.Box init, fb.Box min, fb.Box max, fb.Box step):
#     """Create a numeric entry box."""
#     return fb.boxNumEntry(label, init, min, max, step)

# cdef fb.Box box_v_bargraph(const string& label, fb.Box min, fb.Box max):
#     """Create a vertical bargraph box."""
#     return fb.boxVBargraph(label, min, max)

# cdef fb.Box box_v_bargraph2(const string& label, fb.Box min, fb.Box max, fb.Box x):
#     """Create a vertical bargraph box."""
#     return fb.boxVBargraph(label, min, max, x)

# cdef fb.Box box_h_bargraph(const string& label, fb.Box min, fb.Box max):
#     """Create a horizontal bargraph box."""
#     return fb.boxHBargraph(label, min, max)

# cdef fb.Box box_h_bargraph2(const string& label, fb.Box min, fb.Box max, fb.Box x):
#     """Create a horizontal bargraph box."""
#     return fb.boxHBargraph(label, min, max, x)

# cdef fb.Box box_v_group(const string& label, fb.Box group):
#     """Create a vertical group box."""
#     return fb.boxVGroup(label, group)

# cdef fb.Box box_h_group(const string& label, fb.Box group):
#     """Create a horizontal group box."""
#     return fb.boxHGroup(label, group)

# cdef fb.Box box_t_group(const string& label, fb.Box group):
#     """Create a tab group box."""
#     return fb.boxTGroup(label, group)

# cdef fb.Box box_attach(fb.Box b1, fb.Box b2):
#     """Create an attach box."""
#     return fb.boxAttach(b1, b2)

# cdef fb.Box box_prim2(fb.prim2 foo):
#     return fb.boxPrim2(foo)

# cdef bint is_box_abstr_(fb.Box t, fb.Box& x, fb.Box& y):
#     return fb.isBoxAbstr(t, x, y)

# cdef bint is_box_access(fb.Box t, fb.Box& exp, fb.Box& id):
#     return fb.isBoxAccess(t, exp, id)

# cdef bint is_box_appl_(fb.Box t, fb.Box& x, fb.Box& y):
#     return fb.isBoxAppl(t, x, y)

# cdef bint is_box_button_(fb.Box b, fb.Box& lbl):
#     return fb.isBoxButton(b, lbl)

# cdef bint is_box_case_(fb.Box b, fb.Box& rules):
#     return fb.isBoxCase(b, rules)

# cdef bint is_box_checkbox_(fb.Box b, fb.Box& lbl):
#     return fb.isBoxCheckbox(b, lbl)

# cdef bint is_box_component(fb.Box b, fb.Box& filename):
#     return fb.isBoxComponent(b, filename)

# cdef bint is_box_environment(fb.Box b):
#     return fb.isBoxEnvironment(b)

# cdef bint is_box_f_const(fb.Box b, fb.Box& type, fb.Box& name, fb.Box& file):
#     return fb.isBoxFConst(b, type, name, file)

# cdef bint is_box_f_fun(fb.Box b, fb.Box& ff):
#     return fb.isBoxFFun(b, ff)

# cdef bint is_box_f_var(fb.Box b, fb.Box& type, fb.Box& name, fb.Box& file):
#     return fb.isBoxFVar(b, type, name, file)

# cdef bint is_box_h_bargraph(fb.Box b, fb.Box& lbl, fb.Box& min, fb.Box& max):
#     return fb.isBoxHBargraph(b, lbl, min, max)

# cdef bint is_box_h_group(fb.Box b, fb.Box& lbl, fb.Box& x):
#     return fb.isBoxHGroup(b, lbl, x)

# cdef bint is_box_h_slider(fb.Box b, fb.Box& lbl, fb.Box& cur, fb.Box& min, fb.Box& max, fb.Box& step):
#     return fb.isBoxHSlider(b, lbl, cur, min, max, step)

# cdef bint is_box_ident(fb.Box t, const char** str):
#     return fb.isBoxIdent(t, str)

# cdef bint is_box_inputs(fb.Box t, fb.Box& x):
#     return fb.isBoxInputs(t, x)

# cdef bint is_box_int(fb.Box t, int* i):
#     return fb.isBoxInt(t, i)

# cdef bint is_box_i_par(fb.Box t, fb.Box& x, fb.Box& y, fb.Box& z):
#     return fb.isBoxIPar(t, x, y, z)

# cdef bint is_box_i_prod(fb.Box t, fb.Box& x, fb.Box& y, fb.Box& z):
#     return fb.isBoxIProd(t, x, y, z)

# cdef bint is_box_i_seq(fb.Box t, fb.Box& x, fb.Box& y, fb.Box& z):
#     return fb.isBoxISeq(t, x, y, z)

# cdef bint is_box_i_sum(fb.Box t, fb.Box& x, fb.Box& y, fb.Box& z):
#     return fb.isBoxISum(t, x, y, z)

# cdef bint is_box_library(fb.Box b, fb.Box& filename):
#     return fb.isBoxLibrary(b, filename)

# cdef bint is_box_merge(fb.Box t, fb.Box& x, fb.Box& y):
#     return fb.isBoxMerge(t, x, y)

# cdef bint is_box_metadata(fb.Box b, fb.Box& exp, fb.Box& mdlist):
#     return fb.isBoxMetadata(b, exp, mdlist)

# cdef bint is_box_num_entry(fb.Box b, fb.Box& lbl, fb.Box& cur, fb.Box& min_, fb.Box& max_, fb.Box& step):
#     return fb.isBoxNumEntry(b, lbl, cur, min_, max_, step)

# cdef bint is_box_outputs(fb.Box t, fb.Box& x):
#     return fb.isBoxOutputs(t, x)

# cdef bint is_box_par(fb.Box t, fb.Box& x, fb.Box& y):
#     return fb.isBoxPar(t, x, y)

# cdef bint is_box_prim0_(fb.Box b, fb.prim0* p):
#     return fb.isBoxPrim0(b, p)

# cdef bint is_box_prim1_(fb.Box b, fb.prim1* p):
#     return fb.isBoxPrim1(b, p)

# cdef bint is_box_prim2_(fb.Box b, fb.prim2* p):
#     return fb.isBoxPrim2(b, p)

# cdef bint is_box_prim3_(fb.Box b, fb.prim3* p):
#     return fb.isBoxPrim3(b, p)

# cdef bint is_box_prim4_(fb.Box b, fb.prim4* p):
#     return fb.isBoxPrim4(b, p)

# cdef bint is_box_prim5_(fb.Box b, fb.prim5* p):
#     return fb.isBoxPrim5(b, p)

# cdef bint is_box_real(fb.Box t, double* r):
#     return fb.isBoxReal(t, r)

# cdef bint is_box_rec(fb.Box t, fb.Box& x, fb.Box& y):
#     return fb.isBoxRec(t, x, y)

# cdef bint is_box_route(fb.Box b, fb.Box& n, fb.Box& m, fb.Box& r):
#     return fb.isBoxRoute(b, n, m, r)

# cdef bint is_box_seq(fb.Box t, fb.Box& x, fb.Box& y):
#     return fb.isBoxSeq(t, x, y)

# cdef bint is_box_soundfile(fb.Box b, fb.Box& label, fb.Box& chan):
#     return fb.isBoxSoundfile(b, label, chan)

# cdef bint is_box_split(fb.Box t, fb.Box& x, fb.Box& y):
#     return fb.isBoxSplit(t, x, y)

# cdef bint is_box_symbolic(fb.Box t, fb.Box& slot, fb.Box& body):
#     return fb.isBoxSymbolic(t, slot, body)

# cdef bint is_box_t_group(fb.Box b, fb.Box& lbl, fb.Box& x):
#     return fb.isBoxTGroup(b, lbl, x)

# cdef bint is_box_v_bargraph(fb.Box b, fb.Box& lbl, fb.Box& min, fb.Box& max):
#     return fb.isBoxVBargraph(b, lbl, min, max)

# cdef bint is_box_v_group(fb.Box b, fb.Box& lbl, fb.Box& x):
#     return fb.isBoxVGroup(b, lbl, x)

# cdef bint is_box_v_slider(fb.Box b, fb.Box& lbl, fb.Box& cur, fb.Box& min, fb.Box& max, fb.Box& step):
#     return fb.isBoxVSlider(b, lbl, cur, min, max, step)

# cdef bint is_box_with_local_def(fb.Box t, fb.Box& body, fb.Box& ldef):
#     return fb.isBoxWithLocalDef(t, body, ldef)

# cdef fb.Box dsp_to_boxes(const string& name_app, const string& dsp_content, int argc, const char* argv[], int* inputs, int* outputs, string& error_msg):
#     """Compile a DSP source code as a string in a flattened box."""
#     return fb.DSPToBoxes(name_app, dsp_content, argc, argv, inputs, outputs, error_msg)

# cdef bint get_box_type(fb.Box box, int* inputs, int* outputs):
#     """Return the number of inputs and outputs of a box."""
#     return fb.getBoxType(box, inputs, outputs)

# cdef fs.tvec boxes_to_signals(fb.Box box, string& error_msg):
#     """Compile a box expression in a list of signals in normal form."""
#     return fb.boxesToSignals(box, error_msg)

# cdef string create_source_from_boxes(const string& name_app, fb.Box box, const string& lang, int argc, const char* argv[], string& error_msg):
#     """Create source code in a target language from a box expression."""
#     return fb.createSourceFromBoxes(name_app, box, lang, argc, argv, error_msg)

