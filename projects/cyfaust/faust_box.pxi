
## ---------------------------------------------------------------------------
## faust/dsp/libfaust-box

def box_or_int(var):
    if isinstance(var, int):
        return Box.from_int(var)
    if isinstance(var, Box):
        assert is_box_int(var), "box is not an int box"
        return var
    raise TypeError

def box_or_float(var):
    if isinstance(var, float):
        return Box.from_real(var)
    elif isinstance(var, Box):
        assert is_box_real(var), "box is not a real box"
        return var
    raise TypeError


class box_context:
    def __enter__(self):
        fb.createLibContext()
    def __exit__(self, type, value, traceback):
        fb.destroyLibContext()


cdef class Box:
    """faust Box wrapper.
    """
    cdef fb.Box ptr
    cdef public int inputs
    cdef public int outputs

    def __cinit__(self):
        self.ptr = NULL
        self.inputs = 0
        self.outputs = 0

    def __init__(self, value = None):
        if not value:
            self.ptr = fb.boxWire()
        elif isinstance(value, int):
            self.ptr = fb.boxInt(value)
        elif isinstance(value, float):
            self.ptr = fb.boxReal(value)

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

    from_real = from_float

    @staticmethod
    def from_wire() -> Box:
        """Create box from wire box, copies its input to its output"""
        cdef fb.Box b = fb.boxWire()
        return Box.from_ptr(b)

    @staticmethod
    def from_cut() -> Box:
        """Create box from a cut box, to stop/terminate a signal"""
        cdef fb.Box b = fb.boxCut()
        return Box.from_ptr(b)

    @staticmethod
    def from_soundfile(label: str, output_channels: Box | int) -> Box:
        """Create a soundfile box."""
        if isinstance(output_channels, int):
            return box_soundfile(label, Box.from_int(output_channels))
        else:
            return box_soundfile(label, output_channels.ptr)

    @staticmethod
    def from_readonly_table(n: Box | int, Box init, ridx: Box | int) -> Box:
        """Create a read only table.

        n - the table size, a constant numerical expression (see [1])
        init - the table content
        ridx - the read index (an int between 0 and n-1)

        returns the table box.
        """
        _n = box_or_int(n)
        _ridx = box_or_int(ridx)
        return box_readonly_table(_n, init, _ridx)

    @property
    def is_valid(self) -> bool:
        """Return true if box is defined, false otherwise

        sets number of inputs and outputs as a side-effect
        """
        return fb.getBoxType(self.ptr,
            &self.inputs, &self.outputs)

    def print(self, shared: bool = False, max_size: int = 256):
        """Print this box."""
        print(fb.printBox(self.ptr, shared, max_size).decode())

    def create_source(self, str name_app, str lang, *args) -> str:
        """Create source code in a target language from a box expression.

        name_app - the name of the Faust program
        lang - the target source code's language which can be one of 
            'c', 'cpp', 'cmajor', 'codebox', 'csharp', 'dlang', 'fir', 
            'interp', 'java', 'jax','jsfx', 'julia', 'ocpp', 'rust' or 'wast'
            (depending of which of the corresponding backends are compiled in libfaust)
        args - tuple of parameters if any

        returns a string of source code on success, printing error_msg if error.
        """
        cdef ParamArray params = ParamArray(args)
        cdef string error_msg
        error_msg.reserve(4096)
        cdef string code = fb.createSourceFromBoxes(
            name_app.encode('utf8'),
            self.ptr,
            lang.encode('utf8'),
            params.argc,
            params.argv, 
            error_msg)
        if not error_msg.empty():
            print(error_msg.decode())
            return
        return code.decode()

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

    def is_abstr(self) -> bool:
        return fb.isBoxAbstr(self.ptr)

    def is_appl(self) -> bool:
        return fb.isBoxAppl(self.ptr)

    def is_button(self) -> bool:
        return fb.isBoxButton(self.ptr)

    def is_case(self) -> bool:
        return fb.isBoxCase(self.ptr)

    def is_checkbox(self) -> bool:
        return fb.isBoxCheckbox(self.ptr)

    def is_cut(self) -> bool:
        return fb.isBoxCut(self.ptr)

    def is_environment(self) -> bool:
        return fb.isBoxEnvironment(self.ptr)

    def is_error(self) -> bool:
        return fb.isBoxError(self.ptr)

    def is_f_const(self) -> bool:
        return fb.isBoxFConst(self.ptr)

    def is_ffun(self) -> bool:
        return fb.isBoxFFun(self.ptr)

    def is_fvar_(self) -> bool:
        return fb.isBoxFVar(self.ptr)

    def is_hbargraph(self) -> bool:
        return fb.isBoxHBargraph(self.ptr)

    def is_hgroup(self) -> bool:
        return fb.isBoxHGroup(self.ptr)

    def is_hslider(self) -> bool:
        return fb.isBoxHSlider(self.ptr)

    def is_ident(self) -> bool:
        return fb.isBoxIdent(self.ptr)

    def is_int(self) -> bool:
        return fb.isBoxInt(self.ptr)

    def is_numentry(self) -> bool:
        return fb.isBoxNumEntry(self.ptr)

    def is_prim0(self) -> bool:
        return fb.isBoxPrim0(self.ptr)

    def is_prim1(self) -> bool:
        return fb.isBoxPrim1(self.ptr)

    def is_prim2(self) -> bool:
        return fb.isBoxPrim2(self.ptr)

    def is_prim3(self) -> bool:
        return fb.isBoxPrim3(self.ptr)

    def is_prim4(self) -> bool:
        return fb.isBoxPrim4(self.ptr)

    def is_prim5(self) -> bool:
        return fb.isBoxPrim5(self.ptr)

    def is_real_(self) -> bool:
        return fb.isBoxReal(self.ptr)

    def is_slot(self) -> bool:
        return fb.isBoxSlot(self.ptr)

    def is_soundfile(self) -> bool:
        return fb.isBoxSoundfile(self.ptr)

    def is_symbolic(self) -> bool:
        return fb.isBoxSymbolic(self.ptr)

    def is_tgroup(self) -> bool:
        return fb.isBoxTGroup(self.ptr)

    def is_vgroup(self) -> bool:
        return fb.isBoxVGroup(self.ptr)

    def is_vslider(self) -> bool:
        return fb.isBoxVSlider(self.ptr)

    def is_waveform(self) -> bool:
        return fb.isBoxWaveform(self.ptr)

    def is_wire(self) -> bool:
        return fb.isBoxWire(self.ptr)


    def int_cast(self) -> Box:
        """Create a casted box.

        s - the box to be casted in integer

        returns the casted box.
        """
        cdef fb.Box b = fb.boxIntCast(self.ptr)
        return Box.from_ptr(b)


    def float_cast(self) -> Box:
        """Create a casted box.

        s - the signal to be casted as float/double value (depends of -single or -double compilation parameter)

        returns the casted box.
        """
        cdef fb.Box b = fb.boxFloatCast(self.ptr)
        return Box.from_ptr(b)


    def seq(self, Box y) -> Box:
        """The sequential composition of two blocks (e.g., A:B) expects: outputs(A)=inputs(B)

        returns the seq box.
        """
        cdef fb.Box b = fb.boxSeq(self.ptr, y.ptr)
        return Box.from_ptr(b)

    def par(self, Box y) -> Box:
        """The parallel composition of two blocks (e.g., A,B).

        It places the two block-diagrams one on top of the other, without connections.

        returns the par box.
        """
        cdef fb.Box b = fb.boxPar(self.ptr, y.ptr)
        return Box.from_ptr(b)


    def par3(self, Box y, Box z) -> Box:
        """The parallel composition of three blocks (e.g., A,B,C).
        
        It places the three block-diagrams one on top of the other, without connections.

        returns the par box.    
        """
        cdef fb.Box b = fb.boxPar3(self.ptr, y.ptr, z.ptr)
        return Box.from_ptr(b)


    def par4(self, Box b, Box c, Box d) -> Box:
        """The parallel composition of four blocks (e.g., A,B,C,D).

        It places the four block-diagrams one on top of the other, without connections.

        returns the par box.
        """
        cdef fb.Box p = fb.boxPar4(self.ptr, b.ptr, c.ptr, d.ptr)
        return Box.from_ptr(p)


    def par5(self, Box b, Box c, Box d, Box e) -> Box:
        """The parallel composition of five blocks (e.g., A,B,C,D,E).

        It places the five block-diagrams one on top of the other, without connections.

        returns the par box.
        """
        cdef fb.Box p = fb.boxPar5(self.ptr, b.ptr, c.ptr, d.ptr, e.ptr)
        return Box.from_ptr(p)

    def split(self, Box y) -> Box:
        """The split composition (e.g., A<:B) operator is used to distribute
        the outputs of A to the inputs of B.

        For the operation to be valid, the number of inputs of B
        must be a multiple of the number of outputs of A: outputs(A).k=inputs(B)

        returns the split box.
        """
        cdef fb.Box b = fb.boxSplit(self.ptr, y.ptr)
        return Box.from_ptr(b)


    def merge(self, Box y) -> Box:
        """The merge composition (e.g., A:>B) is the dual of the split composition.

        The number of outputs of A must be a multiple of the number of inputs of B: outputs(A)=k.inputs(B)

        returns the merge box.
        """
        cdef fb.Box b = fb.boxMerge(self.ptr, y.ptr)
        return Box.from_ptr(b)


    def rec(self, Box y) -> Box:
        """The recursive composition (e.g., A~B) is used to create cycles in the block-diagram
        in order to express recursive computations.

        It is the most complex operation in terms of connections: outputs(A)≥inputs(B) and inputs(A)≥outputs(B)

        returns the rec box.
        """
        cdef fb.Box b = fb.boxRec(self.ptr, y.ptr)
        return Box.from_ptr(b)


    def get_def_name_property(self) -> Box | None:
        """Returns the identifier (if any) the expression was a definition of.

        b the expression
        id reference to the identifier

        returns the identifier if the expression b was a definition of id
        else returns None
        """
        cdef fb.Box id = NULL
        if fb.getDefNameProperty(self.ptr, id):
            return Box.from_ptr(id)

    def extract_name(self) -> str:
        """Extract the name from a label.

        full_label the label to be analyzed

        returns the extracted name
        """
        return fb.extractName(self.ptr).decode()

    def delay(self, d: int | Box) -> Box:
        """Create a delayed box.

        s - the box to be delayed
        d - the delay box that doesn't have to be fixed but must be bounded and cannot be negative

        returns the delayed box.
        """
        if isinstance(d, int):
            return box_delay(self, Box.from_int(d))
        else:
            return box_delay(self, d.ptr)


    # def delay(self, int d) -> Box:
    #     """Create a delayed box.

    #     s - the box to be delayed
    #     d - the delay box that doesn't have to be fixed but must be bounded and cannot be negative

    #     returns the delayed box.
    #     """
    #     cdef fb.Box delay = fb.boxInt(d)
    #     cdef fb.Box b = fb.boxDelay(self.ptr, delay)
    #     return Box.from_ptr(b)



def print_box(Box box, bint shared, int max_size) -> str:
    """Print the box.

    box - the box to be printed
    shared - whether the identical sub boxes are printed as identifiers
    max_size - the maximum number of characters to be printed (possibly needed for big expressions in non shared mode)

    returns the printed box as a string
    """
    return fb.printBox(box.ptr, shared, max_size).decode()


def get_def_name_property(Box b) -> Box | None:
    """Returns the identifier (if any) the expression was a definition of.

    b the expression
    id reference to the identifier

    returns the identifier if the expression b was a definition of id
    else returns None
    """
    cdef fb.Box id = NULL
    if fb.getDefNameProperty(b.ptr, id):
        return Box.from_ptr(id)

def extract_name(Box full_label) -> str:
    """Extract the name from a label.

    full_label the label to be analyzed

    returns the extracted name
    """
    return fb.extractName(full_label.ptr).decode()

def create_lib_context():
    """Create global compilation context, has to be done first."""
    fb.createLibContext()

def destroy_lib_context():
    """Destroy global compilation context, has to be done last."""
    fb.destroyLibContext()


# cdef void* get_user_data(Box b):
#     """Return the xtended type of a box.

#     b - the box whose xtended type to return

#     returns a pointer to xtended type if it exists, otherwise nullptr.
#     """
#     return fb.getUserData(b.ptr)


def box_is_nil(Box b) -> bool:
    """Check if a box is nil.

    b - the box

    returns true if the box is nil, otherwise false.
    """
    return fb.isNil(b.ptr)


def tree2str(Box b) -> str:
    """Convert a box (such as the label of a UI) to a string.

    b - the box to convert

    returns a string representation of a box.
    """
    return fb.tree2str(b.ptr).decode()


def tree2int(Box b) -> int:
    """If t has a node of type int, return it. Otherwise error

    b - the box to convert

    returns the int value of the box.
    """
    return fb.tree2int(b.ptr)



def box_int(int n) -> Box:
    """Constant integer : for all t, x(t) = n.

    n - the integer

    returns the integer box.
    """
    cdef fb.Box b = fb.boxInt(n)
    return Box.from_ptr(b)


def box_float(float n) -> Box:
    """Constant real : for all t, x(t) = n.

    n - the float/double value (depends of -single or -double compilation parameter)

    returns the float/double box.
    """
    cdef fb.Box b = fb.boxReal(n)
    return Box.from_ptr(b)

box_real = box_float


def box_wire() -> Box:
    """The identity box, copy its input to its output.

    returns the identity box.
    """
    cdef fb.Box b = fb.boxWire()
    return Box.from_ptr(b)


def box_cut() -> Box:
    """The cut box, to stop/terminate a signal.

    returns the cut box.
    """
    cdef fb.Box b = fb.boxCut()
    return Box.from_ptr(b)


def box_seq(Box x, Box y) -> Box:
    """The sequential composition of two blocks (e.g., A:B) expects: outputs(A)=inputs(B)

    returns the seq box.
    """
    cdef fb.Box b = fb.boxSeq(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_par(Box x, Box y) -> Box:
    """The parallel composition of two blocks (e.g., A,B).

    It places the two block-diagrams one on top of the other, without connections.

    returns the par box.
    """
    cdef fb.Box b = fb.boxPar(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_par3(Box x, Box y, Box z) -> Box:
    """The parallel composition of three blocks (e.g., A,B,C).
    
    It places the three block-diagrams one on top of the other, without connections.

    returns the par box.    
    """
    cdef fb.Box b = fb.boxPar3(x.ptr, y.ptr, z.ptr)
    return Box.from_ptr(b)


def box_par4(Box a, Box b, Box c, Box d) -> Box:
    """The parallel composition of four blocks (e.g., A,B,C,D).

    It places the four block-diagrams one on top of the other, without connections.

    returns the par box.
    """
    cdef fb.Box p = fb.boxPar4(a.ptr, b.ptr, c.ptr, d.ptr)
    return Box.from_ptr(p)


def box_par5(Box a, Box b, Box c, Box d, Box e) -> Box:
    """The parallel composition of five blocks (e.g., A,B,C,D,E).

    It places the five block-diagrams one on top of the other, without connections.

    returns the par box.
    """
    cdef fb.Box p = fb.boxPar5(a.ptr, b.ptr, c.ptr, d.ptr, e.ptr)
    return Box.from_ptr(p)

def box_split(Box x, Box y) -> Box:
    """The split composition (e.g., A<:B) operator is used to distribute
    the outputs of A to the inputs of B.

    For the operation to be valid, the number of inputs of B
    must be a multiple of the number of outputs of A: outputs(A).k=inputs(B)

    returns the split box.
    """
    cdef fb.Box b = fb.boxSplit(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_merge(Box x, Box y) -> Box:
    """The merge composition (e.g., A:>B) is the dual of the split composition.

    The number of outputs of A must be a multiple of the number of inputs of B: outputs(A)=k.inputs(B)

    returns the merge box.
    """
    cdef fb.Box b = fb.boxMerge(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_rec(Box x, Box y) -> Box:
    """The recursive composition (e.g., A~B) is used to create cycles in the block-diagram
    in order to express recursive computations.

    It is the most complex operation in terms of connections: outputs(A)≥inputs(B) and inputs(A)≥outputs(B)

    returns the rec box.
    """
    cdef fb.Box b = fb.boxRec(x.ptr, y.ptr)
    return Box.from_ptr(b)

def box_route(Box n, Box m, Box r) -> Box:
    """The route primitive facilitates the routing of signals in Faust.

    It has the following syntax: route(A,B,a,b,c,d,...) or route(A,B,(a,b),(c,d),...)

    n -  the number of input signals
    m -  the number of output signals
    r - the routing description, a 'par' expression of a,b / (a,b) input/output pairs

    returns the route box.
    """
    cdef fb.Box b = fb.boxRoute(n.ptr, m.ptr, r.ptr)
    return Box.from_ptr(b)


def box_delay_op() -> Box:
    """Create a delayed box.

    returns the delayed box.
    """
    cdef fb.Box b = fb.boxDelay()
    return Box.from_ptr(b)


def box_delay(Box b, Box d) -> Box:
    """Create a delayed box.

    s - the box to be delayed
    d - the delay box that doesn't have to be fixed but must be bounded and cannot be negative

    returns the delayed box.
    """
    cdef fb.Box _b = fb.boxDelay(b.ptr, d.ptr)
    return Box.from_ptr(_b)


def box_int_cast_op() -> Box:
    """Create a casted box.

    returns the casted box.
    """
    cdef fb.Box _b = fb.boxIntCast()
    return Box.from_ptr(_b)


def box_int_cast(Box b) -> Box:
    """Create a casted box.

    s - the box to be casted in integer

    returns the casted box.
    """
    cdef fb.Box _b = fb.boxIntCast(b.ptr)
    return Box.from_ptr(_b)


def box_float_cast_op() -> Box:
    """Create a casted box."""
    cdef fb.Box _b = fb.boxFloatCast()
    return Box.from_ptr(_b)


def box_float_cast(Box b) -> Box:
    """Create a casted box.

    s - the signal to be casted as float/double value (depends of -single or -double compilation parameter)

    returns the casted box.
    """
    cdef fb.Box _b = fb.boxFloatCast(b.ptr)
    return Box.from_ptr(_b)


def box_readonly_table_op() -> Box:
    """Create a read only table.

    returns the table box.
    """
    cdef fb.Box b = fb.boxReadOnlyTable()
    return Box.from_ptr(b)


def box_readonly_table(Box n, Box init, Box ridx) -> Box:
    """Create a read only table.

    n - the table size, a constant numerical expression (see [1])
    init - the table content
    ridx - the read index (an int between 0 and n-1)

    returns the table box.
    """
    cdef fb.Box b = fb.boxReadOnlyTable(n.ptr, init.ptr, ridx.ptr)
    return Box.from_ptr(b)

def box_write_read_table_op() -> Box:
    """Create a read/write table.
    
    returns the table box.
    """
    cdef fb.Box b = fb.boxWriteReadTable()
    return Box.from_ptr(b)

def box_write_read_table(Box n, Box init, Box widx, Box wsig, Box ridx) -> Box:
    """Create a read/write table.

    n - the table size, a constant numerical expression (see [1])
    init - the table content
    widx - the write index (an integer between 0 and n-1)
    wsig - the input of the table
    ridx - the read index (an integer between 0 and n-1)

    returns the table box.
    """
    cdef fb.Box b = fb.boxWriteReadTable(n.ptr, init.ptr, widx.ptr, wsig.ptr, ridx.ptr)
    return Box.from_ptr(b)


def box_waveform(SignalVector wf):
    """Create a waveform.

    wf - the content of the waveform as a vector of boxInt or boxDouble boxes

    returns the waveform box.
    """
    cdef fb.Box b = fb.boxWaveform(<const fs.tvec>wf.ptr)
    return Box.from_ptr(b)


def box_soundfile(str label, Box chan) -> Box:
    """Create a soundfile block.

    label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
    chan - the number of outputs channels, a constant numerical expression (see [1])

    returns the soundfile box.
    """
    cdef fb.Box b = fb.boxSoundfile(label.encode('utf8'), chan.ptr)
    return Box.from_ptr(b)


def box_soundfile2(str label, Box chan, Box part, Box ridx) -> Box:
    """Create a soundfile block.

    label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
    chan - the number of outputs channels, a constant numerical expression (see [1])
    part - in the [0..255] range to select a given sound number, a constant numerical expression (see [1])
    ridx - the read index (an integer between 0 and the selected sound length)

    returns the soundfile box.
    """
    cdef fb.Box b = fb.boxSoundfile(label.encode('utf8'), chan.ptr, part.ptr, ridx.ptr)
    return Box.from_ptr(b)


def box_select2(Box selector, Box b1, Box b2) -> Box:
    """Create a selector between two boxes.

    selector - when 0 at time t returns s1[t], otherwise returns s2[t]
    s1 - first box to be selected
    s2 - second box to be selected

    returns the selected box depending of the selector value at each time t.
    """
    cdef fb.Box b = fb.boxSelect2(selector.ptr, b1.ptr, b2.ptr)
    return Box.from_ptr(b)


def box_select2_op() -> Box:
    """Create a selector between two boxes.

    returns the selected box depending of the selector value at each time t.
    """
    cdef fb.Box b = fb.boxSelect2()
    return Box.from_ptr(b)


def box_select3(Box selector, Box b1, Box b2, Box b3) -> Box:
    """Create a selector between three boxes.

    selector - when 0 at time t returns s1[t], when 1 at time t returns s2[t], otherwise returns s3[t]
    s1 - first box to be selected
    s2 - second box to be selected
    s3 - third box to be selected

    returns the selected box depending of the selector value at each time t.
    """
    cdef fb.Box b = fb.boxSelect3(selector.ptr, b1.ptr, b2.ptr, b3.ptr)
    return Box.from_ptr(b)

def box_fconst(fb.SType type, str name, str file) -> Box:
    """Create a foreign constant box.

    type - the foreign constant type of SType
    name - the foreign constant name
    file - the include file where the foreign constant is defined

    returns the foreign constant box.
    """
    cdef fb.Box b = fb.boxFConst(type, name, file)
    return Box.from_ptr(b)

def box_fvar(fb.SType type, str name, str file) -> Box:
    """Create a foreign variable box.

    type - the foreign variable type of SType
    name - the foreign variable name
    file - the include file where the foreign variable is defined

    returns the foreign variable box.
    """
    cdef fb.Box b = fb.boxFVar(type, name, file)
    return Box.from_ptr(b)

def box_bin_op0(fb.SOperator op) -> Box:
    """Generic binary mathematical functions.

    op - the operator in SOperator set

    returns the result box of op(x,y).
    """
    cdef fb.Box b = fb.boxBinOp(op)
    return Box.from_ptr(b)

def box_bin_op(fb.SOperator op, Box b1, Box b2) -> Box:
    """Generic binary mathematical functions.

    op - the operator in SOperator set

    returns the result box of op(x,y).
    """
    cdef fb.Box b = fb.boxBinOp(op, b1.ptr, b2.ptr)
    return Box.from_ptr(b)




def box_add_op() -> Box:
    cdef fb.Box b = fb.boxAdd()
    return Box.from_ptr(b)

def box_add(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxAdd(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_sub_op() -> Box:
    cdef fb.Box b = fb.boxSub()
    return Box.from_ptr(b)

def box_sub(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxSub(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_mul_op() -> Box:
    cdef fb.Box b = fb.boxMul()
    return Box.from_ptr(b)

def box_mul(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxMul(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_div_op() -> Box:
    cdef fb.Box b = fb.boxDiv()
    return Box.from_ptr(b)

def box_div(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxDiv(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_rem_op() -> Box:
    cdef fb.Box b = fb.boxRem()
    return Box.from_ptr(b)

def box_rem(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxRem(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_leftshift_op() -> Box:
    cdef fb.Box b = fb.boxLeftShift()
    return Box.from_ptr(b)

def box_leftshift(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxLeftShift(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_lrightshift_op() -> Box:
    cdef fb.Box b = fb.boxLRightShift()
    return Box.from_ptr(b)

def box_lrightshift(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxLRightShift(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_arightshift_op() -> Box:
    cdef fb.Box b = fb.boxARightShift()
    return Box.from_ptr(b)

def box_arightshift(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxARightShift(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_gt_op() -> Box:
    cdef fb.Box b = fb.boxGT()
    return Box.from_ptr(b)

def box_gt(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxGT(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_lt_op() -> Box:
    cdef fb.Box b = fb.boxLT()
    return Box.from_ptr(b)

def box_lt(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxLT(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_ge_op() -> Box:
    cdef fb.Box b = fb.boxGE()
    return Box.from_ptr(b)

def box_ge(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxGE(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_le_op() -> Box:
    cdef fb.Box b = fb.boxLE()
    return Box.from_ptr(b)

def box_le(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxLE(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_eq_op() -> Box:
    cdef fb.Box b = fb.boxEQ()
    return Box.from_ptr(b)

def box_eq(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxEQ(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_ne_op() -> Box:
    cdef fb.Box b = fb.boxNE()
    return Box.from_ptr(b)

def box_ne(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxNE(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_and_op() -> Box:
    cdef fb.Box b = fb.boxAND()
    return Box.from_ptr(b)

def box_and(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxAND(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_or_op() -> Box:
    cdef fb.Box b = fb.boxOR()
    return Box.from_ptr(b)

def box_or(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxOR(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_xor_op() -> Box:
    cdef fb.Box b = fb.boxXOR()
    return Box.from_ptr(b)

def box_xor(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxXOR(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_remainder_op() -> Box:
    cdef fb.Box b = fb.boxRemainder()
    return Box.from_ptr(b)

def box_remainder(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxRemainder(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_pow_op() -> Box:
    cdef fb.Box b = fb.boxPow()
    return Box.from_ptr(b)

def box_pow(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxPow(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_min_op() -> Box:
    cdef fb.Box b = fb.boxMin()
    return Box.from_ptr(b)

def box_min(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxMin(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_max_op() -> Box:
    cdef fb.Box b = fb.boxMax()
    return Box.from_ptr(b)

def box_max(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxMax(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_fmod_op() -> Box:
    cdef fb.Box b = fb.boxFmod()
    return Box.from_ptr(b)

def box_fmod(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxFmod(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_atan2_op() -> Box:
    cdef fb.Box b = fb.boxAtan2()
    return Box.from_ptr(b)

def box_atan2(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxAtan2(b1.ptr, b2.ptr)
    return Box.from_ptr(b)


def box_button(str label) -> Box:
    """Create a button box.

    label - the label definition (see [2])

    returns the button box.
    """
    cdef fb.Box b = fb.boxButton(label.encode('utf8'))
    return Box.from_ptr(b)


def box_checkbox(str label) -> Box:
    """Create a checkbox box.

    label - the label definition (see [2])

    returns the checkbox box.
    """
    cdef fb.Box b = fb.boxCheckbox(label.encode('utf8'))
    return Box.from_ptr(b)


def box_vslider(str label, Box init, Box min, Box max, Box step) -> Box:
    """Create a vertical slider box.

    label - the label definition (see [2])
    init - the init box, a constant numerical expression (see [1])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    step - the step box, a constant numerical expression (see [1])

    returns the vertical slider box.
    """
    cdef fb.Box b = fb.boxVSlider(label.encode('utf8'), init.ptr, min.ptr, max.ptr, step.ptr)
    return Box.from_ptr(b)

def box_hslider(str label, Box init, Box min, Box max, Box step) -> Box:
    """Create an horizontal slider box.

    label - the label definition (see [2])
    init - the init box, a constant numerical expression (see [1])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    step - the step box, a constant numerical expression (see [1])

    returns the horizontal slider box.
    """
    cdef fb.Box b = fb.boxHSlider(label.encode('utf8'), init.ptr, min.ptr, max.ptr, step.ptr)
    return Box.from_ptr(b)

def box_numentry(str label, Box init, Box min, Box max, Box step) -> Box:
    """Create a num entry box.

    label - the label definition (see [2])
    init - the init box, a constant numerical expression (see [1])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    step - the step box, a constant numerical expression (see [1])

    returns the num entry box.
    """
    cdef fb.Box b = fb.boxNumEntry(label.encode('utf8'), init.ptr, min.ptr, max.ptr, step.ptr)
    return Box.from_ptr(b)


def box_vbargraph(str label, Box min, Box max) -> Box:
    """Create a vertical bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    x - the input box

    returns the vertical bargraph box.
    """
    cdef fb.Box b = fb.boxVBargraph(label.encode('utf8'), min.ptr, max.ptr)
    return Box.from_ptr(b)

def box_vbargraph2(str label, Box min, Box max, Box x) -> Box:
    """Create a vertical bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    x - the input box

    returns the vertical bargraph box.
    """
    cdef fb.Box b = fb.boxVBargraph(label.encode('utf8'), min.ptr, max.ptr, x.ptr)
    return Box.from_ptr(b)

def box_hbargraph(str label, Box min, Box max) -> Box:
    """Create a horizontal bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    x - the input box

    returns the horizontal bargraph box.
    """
    cdef fb.Box b = fb.boxHBargraph(label.encode('utf8'), min.ptr, max.ptr)
    return Box.from_ptr(b)

def box_hbargraph2(str label, Box min, Box max, Box x) -> Box:
    """Create a horizontal bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    x - the input box

    returns the horizontal bargraph box.
    """
    cdef fb.Box b = fb.boxHBargraph(label.encode('utf8'), min.ptr, max.ptr, x.ptr)
    return Box.from_ptr(b)


def box_vgroup(str label, Box group) -> Box:
    """Create a vertical group box.

    label - the label definition (see [2])
    group - the group to be added

    returns the vertical group box.
    """
    cdef fb.Box b = fb.boxVGroup(label.encode('utf8'), group.ptr)
    return Box.from_ptr(b)


def box_hgroup(str label, Box group) -> Box:
    """Create a horizontal group box.

    label - the label definition (see [2])
    group - the group to be added

    returns the horizontal group box.
    """
    cdef fb.Box b = fb.boxHGroup(label.encode('utf8'), group.ptr)
    return Box.from_ptr(b)

def box_tgroup(str label, Box group) -> Box:
    """Create a tab group box.

    label - the label definition (see [2])
    group - the group to be added

    returns the tab group box.
    """
    cdef fb.Box b = fb.boxTGroup(label.encode('utf8'), group.ptr)
    return Box.from_ptr(b)

def box_attach_op() -> Box:
    """Create an attach box.

    returns the attach box.
    """
    cdef fb.Box b = fb.boxAttach()
    return Box.from_ptr(b)


def box_attach(Box b1, Box b2) -> Box:
    """Create an attach box.

    The attach primitive takes two input boxes and produces one output box
    which is a copy of the first input. The role of attach is to force
    its second input boxes to be compiled with the first one.

    returns the attach box.
    """
    cdef fb.Box b = fb.boxAttach(b1.ptr, b2.ptr)
    return Box.from_ptr(b)


# cdef fb.Box box_prim2(fb.prim2 foo):
#     return fb.boxPrim2(foo)

def is_box_abstr(Box t) -> bool:
    return fb.isBoxAbstr(t.ptr)

def getparams_box_abstr(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxAbstr(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def getparams_box_access(Box t) -> dict:
    cdef fb.Box exp = NULL
    cdef fb.Box id = NULL
    if fb.isBoxAccess(t.ptr, exp, id):
        return dict(
            exp=Box.from_ptr(exp),
            id=Box.from_ptr(id),
        )
    else:
        return {}

def is_box_appl(Box t) -> bool:
    return fb.isBoxAppl(t.ptr)

def getparams_box_appl(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxAppl(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def is_box_button(Box b) -> bool:
    return fb.isBoxButton(b.ptr)

def getparams_box_button(Box b) -> dict:
    cdef fb.Box lbl = NULL
    if fb.isBoxButton(b.ptr, lbl):
        return dict(
            lbl=Box.from_ptr(lbl),
        )
    else:
        return {}

def is_box_case(Box b) -> bool:
    return fb.isBoxCase(b.ptr)

def getparams_box_case(Box b) -> dict:
    cdef fb.Box rules = NULL
    if fb.isBoxCase(b.ptr, rules):
        return dict(
            rules=Box.from_ptr(rules),
        )
    else:
        return {}

def is_box_checkbox(Box b) -> bool:
    return fb.isBoxCheckbox(b.ptr)

def getparams_box_checkbox(Box b) -> dict:
    cdef fb.Box lbl = NULL
    if fb.isBoxCheckbox(b.ptr, lbl):
        return dict(
            lbl=Box.from_ptr(lbl),
        )
    else:
        return {}

def getparams_box_component(Box b) -> dict:
    cdef fb.Box filename = NULL
    if fb.isBoxComponent(b.ptr, filename):
        return dict(
            filename=Box.from_ptr(filename),
        )
    else:
        return {}

def is_box_cut(Box t) -> bool:
    return fb.isBoxCut(t.ptr)

def is_box_environment(Box b) -> bool:
    return fb.isBoxEnvironment(b.ptr)

def is_box_error(Box t) -> bool:
    return fb.isBoxError(t.ptr)

def is_box_fconst(Box b) -> bool:
    return fb.isBoxFConst(b.ptr)

def getparams_box_fconst(Box b) -> dict:
    cdef fb.Box type = NULL
    cdef fb.Box name = NULL
    cdef fb.Box file = NULL
    if fb.isBoxFConst(b.ptr, type, name, file):
        return dict(
            type=Box.from_ptr(type),
            name=Box.from_ptr(name),
            file=Box.from_ptr(file),
        )
    else:
        return {}

def is_box_ffun(Box b) -> bool:
    return fb.isBoxFFun(b.ptr)

def getparams_box_ffun(Box b) -> dict:
    cdef fb.Box ff = NULL
    if fb.isBoxFFun(b.ptr, ff):
        return dict(
            ff=Box.from_ptr(ff),
        )
    else:
        return {}

def is_box_fvar(Box b) -> bool:
    return fb.isBoxFVar(b.ptr)

def getparams_box_fvar(Box b) -> dict:
    cdef fb.Box type = NULL
    cdef fb.Box name = NULL
    cdef fb.Box file = NULL
    if fb.isBoxFVar(b.ptr, type, name, file):
        return dict(
            type=Box.from_ptr(type),
            name=Box.from_ptr(name),
            file=Box.from_ptr(file),
        )
    else:
        return {}

def is_box_hbargraph(Box b) -> bool:
    return fb.isBoxHBargraph(b.ptr)

def getparams_box_hbargraph(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    if fb.isBoxHBargraph(b.ptr, lbl, min, max):
        return dict(
            lbl=Box.from_ptr(lbl),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
        )
    else:
        return {}

def is_box_hgroup(Box b) -> bool:
    return fb.isBoxHGroup(b.ptr)

def getparams_box_hgroup(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box x = NULL
    if fb.isBoxHGroup(b.ptr, lbl, x):
        return dict(
            lbl=Box.from_ptr(lbl),
            x=Box.from_ptr(x),
        )
    else:
        return {}

def is_box_hslider(Box b) -> bool:
    return fb.isBoxHSlider(b.ptr)

def getparams_box_hslider(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box cur = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    cdef fb.Box step = NULL
    if fb.isBoxHSlider(b.ptr, lbl, cur, min, max, step):
        return dict(
            lbl=Box.from_ptr(lbl),
            cur=Box.from_ptr(cur),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
            step=Box.from_ptr(step),
        )
    else:
        return {}

def is_box_ident(Box t) -> bool:
    return fb.isBoxIdent(t.ptr)

def get_box_id(Box t) -> str | None:
    cdef const char** cstr = <const char**> malloc(1024 * sizeof(char*))
    if fb.isBoxIdent(t.ptr, cstr):
        return cstr[0].decode()


def getparams_box_inputs(Box t) -> dict:
    cdef fb.Box x = NULL
    if fb.isBoxInputs(t.ptr, x):
        return dict(
            x=Box.from_ptr(x),
        )
    else:
        return {}

def is_box_int(Box t) -> bool:
    return fb.isBoxInt(t.ptr)

def getparams_box_int(Box t) -> dict:
    cdef int i = 0
    if fb.isBoxInt(t.ptr, &i):
        return dict(
            i=i,
        )
    else:
        return {}

def getparams_box_ipar(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    cdef fb.Box z = NULL
    if fb.isBoxIPar(t.ptr, x, y, z):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
            z=Box.from_ptr(z),
        )
    else:
        return {}

def getparams_box_iprod(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    cdef fb.Box z = NULL
    if fb.isBoxIProd(t.ptr, x, y, z):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
            z=Box.from_ptr(z),
        )
    else:
        return {}

def getparams_box_iseq(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    cdef fb.Box z = NULL
    if fb.isBoxISeq(t.ptr, x, y, z):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
            z=Box.from_ptr(z),
        )
    else:
        return {}

def getparams_box_isum(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    cdef fb.Box z = NULL
    if fb.isBoxISum(t.ptr, x, y, z):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
            z=Box.from_ptr(z),
        )
    else:
        return {}

def getparams_box_library(Box b) -> dict:
    cdef fb.Box filename = NULL
    if fb.isBoxLibrary(b.ptr, filename):
        return dict(
            filename=Box.from_ptr(filename),
        )
    else:
        return {}

def getparams_box_merge(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxMerge(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def getparams_box_metadata(Box b) -> dict:
    cdef fb.Box exp = NULL
    cdef fb.Box mdlist = NULL
    if fb.isBoxMetadata(b.ptr, exp, mdlist):
        return dict(
            exp=Box.from_ptr(exp),
            mdlist=Box.from_ptr(mdlist),
        )
    else:
        return {}

def is_box_num_entry(Box b) -> bool:
    return fb.isBoxNumEntry(b.ptr)

def getparams_box_num_entry(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box cur = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    cdef fb.Box step = NULL
    if fb.isBoxNumEntry(b.ptr, lbl, cur, min, max, step):
        return dict(
            lbl=Box.from_ptr(lbl),
            cur=Box.from_ptr(cur),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
            step=Box.from_ptr(step),
        )
    else:
        return {}

def getparams_box_outputs(Box t) -> dict:
    cdef fb.Box x = NULL
    if fb.isBoxOutputs(t.ptr, x):
        return dict(
            x=Box.from_ptr(x),
        )
    else:
        return {}

def getparams_box_par(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxPar(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}




def is_box_prim0_(Box b) -> bool:
    cdef fb.prim0 p
    return fb.isBoxPrim0(b.ptr, &p)

def is_box_prim1_(Box b) -> bool:
    cdef fb.prim1 p
    return fb.isBoxPrim1(b.ptr, &p)

def is_box_prim2_(Box b) -> bool:
    cdef fb.prim2 p
    return fb.isBoxPrim2(b.ptr, &p)

def is_box_prim3_(Box b) -> bool:
    cdef fb.prim3 p
    return fb.isBoxPrim3(b.ptr, &p)

def is_box_prim4_(Box b) -> bool:
    cdef fb.prim4 p
    return fb.isBoxPrim4(b.ptr, &p)

def is_box_prim5_(Box b) -> bool:
    cdef fb.prim5 p
    return fb.isBoxPrim5(b.ptr, &p)


def is_box_prim0(Box b) -> bool:
    return fb.isBoxPrim0(b.ptr)

def is_box_prim1(Box b) -> bool:
    return fb.isBoxPrim1(b.ptr)

def is_box_prim2(Box b) -> bool:
    return fb.isBoxPrim2(b.ptr)

def is_box_prim3(Box b) -> bool:
    return fb.isBoxPrim3(b.ptr)

def is_box_prim4(Box b) -> bool:
    return fb.isBoxPrim4(b.ptr)

def is_box_prim5(Box b) -> bool:
    return fb.isBoxPrim5(b.ptr)



def is_box_real(Box t) -> bool:
    return fb.isBoxReal(t.ptr)

def getparams_box_real(Box t) -> dict:
    cdef double r
    if fb.isBoxReal(t.ptr, &r):
        return dict(
            r=r,
        )
    else:
        return {}

def getparams_box_rec(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxRec(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def getparams_box_route(Box b) -> dict:
    cdef fb.Box n = NULL
    cdef fb.Box m = NULL
    cdef fb.Box r = NULL
    if fb.isBoxRoute(b.ptr, n, m, r):
        return dict(
            n=Box.from_ptr(n),
            m=Box.from_ptr(m),
            r=Box.from_ptr(r),
        )
    else:
        return {}

def getparams_box_seq(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxSeq(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def is_box_slot(Box t) -> bool:
    return fb.isBoxSlot(t.ptr)

def getparams_box_slot(Box t) -> dict:
    cdef int id = 0
    if fb.isBoxSlot(t.ptr, &id):
        return dict(
            id=id,
        )
    else:
        return {}

def is_box_soundfile(Box b) -> bool:
    return fb.isBoxSoundfile(b.ptr)

def getparams_box_soundfile(Box b) -> dict:
    cdef fb.Box label = NULL
    cdef fb.Box chan = NULL
    if fb.isBoxSoundfile(b.ptr, label, chan):
        return dict(
            label=Box.from_ptr(label),
            chan=Box.from_ptr(chan),
        )
    else:
        return {}

def getparams_box_split(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxSplit(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def is_box_symbolic(Box t) -> bool:
    return fb.isBoxSymbolic(t.ptr)

def getparams_box_symbolic(Box t) -> dict:
    cdef fb.Box slot = NULL
    cdef fb.Box body = NULL
    if fb.isBoxSymbolic(t.ptr, slot, body):
        return dict(
            slot=Box.from_ptr(slot),
            body=Box.from_ptr(body),
        )
    else:
        return {}

def is_box_t_group(Box b) -> bool:
    return fb.isBoxTGroup(b.ptr)

def getparams_box_tgroup(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box x = NULL
    if fb.isBoxTGroup(b.ptr, lbl, x):
        return dict(
            lbl=Box.from_ptr(lbl),
            x=Box.from_ptr(x),
        )
    else:
        return {}

def is_box_vbargraph(Box b) -> bool:
    return fb.isBoxVBargraph(b.ptr)

def getparams_box_vbargraph(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    if fb.isBoxVBargraph(b.ptr, lbl, min, max):
        return dict(
            lbl=Box.from_ptr(lbl),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
        )
    else:
        return {}

def is_box_vgroup(Box b) -> bool:
    return fb.isBoxVGroup(b.ptr)

def getparams_box_vgroup(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box x = NULL
    if fb.isBoxVGroup(b.ptr, lbl, x):
        return dict(
            lbl=Box.from_ptr(lbl),
            x=Box.from_ptr(x),
        )
    else:
        return {}

def is_box_vslider(Box b) -> bool:
    return fb.isBoxVSlider(b.ptr)

def getparams_box_vslider(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box cur = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    cdef fb.Box step = NULL
    if fb.isBoxVSlider(b.ptr, lbl, cur, min, max, step):
        return dict(
            lbl=Box.from_ptr(lbl),
            cur=Box.from_ptr(cur),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
            step=Box.from_ptr(step),
        )
    else:
        return {}

def is_box_waveform(Box b) -> bool:
    return fb.isBoxWaveform(b.ptr)

def is_box_wire(Box t) -> bool:
    return fb.isBoxWire(t.ptr)

def getparams_box_with_local_def(Box t) -> dict:
    cdef fb.Box body = NULL
    cdef fb.Box ldef = NULL
    if fb.isBoxWithLocalDef(t.ptr, body, ldef):
        return dict(
            body=Box.from_ptr(body),
            ldef=Box.from_ptr(ldef),
        )
    else:
        return {}







def dsp_to_boxes(str name_app, str dsp_content, *args) -> Box:
    """Compile a DSP source code as a string in a flattened box

    name_app - the name of the Faust program
    dsp_content - the Faust program as a string
    argc - the number of parameters in argv array
    argv - the array of parameters
    inputs - the place to return the number of inputs of the resulting box
    outputs - the place to return the number of outputs of the resulting box
    error_msg - the error string to be filled

    returns a flattened box on success, otherwise a null pointer.
    """
    cdef ParamArray params = ParamArray(args)
    cdef int inputs, outputs
    cdef string error_msg
    error_msg.reserve(4096)
    cdef fb.Box b = fb.DSPToBoxes(
        name_app.encode('utf8'),
        dsp_content.encode('utf8'),
        params.argc,
        params.argv,
        &inputs,
        &outputs,
        error_msg,
    )
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return Box.from_ptr(b)


def get_box_type(Box b) -> tuple[int, int] | None:
    """Return the number of inputs and outputs of a box

    box - the box we want to know the number of inputs and outputs
    inputs - the place to return the number of inputs
    outputs - the place to return the number of outputs

    returns true if type is defined, false if undefined.
    """
    cdef int inputs, outputs
    if fb.getBoxType(b.ptr, &inputs, &outputs):
        return (inputs, outputs)

def boxes_to_signals(Box b) -> SignalVector | None:
    """Compile a box expression in a list of signals in normal form
    (see simplifyToNormalForm in libfaust-signal.h)

    box - the box expression
    error_msg - the error string to be filled

    returns a list of signals in normal form on success, otherwise an empty list.
    """
    cdef string error_msg
    error_msg.reserve(4096)
    cdef fs.tvec vec = fb.boxesToSignals(b.ptr, error_msg)
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return SignalVector.from_ptr(vec)


def create_source_from_boxes(str name_app, Box box, str lang, *args) -> str:
    """Create source code in a target language from a box expression.

    name_app - the name of the Faust program
    box - the box expression
    lang - the target source code's language which can be one of 
        'c', 'cpp', 'cmajor', 'codebox', 'csharp', 'dlang', 'fir', 
        'interp', 'java', 'jax','jsfx', 'julia', 'ocpp', 'rust' or 'wast'
        (depending of which of the corresponding backends are compiled in libfaust)
    argc - the number of parameters in argv array
    argv - the array of parameters
    error_msg - the error string to be filled

    returns a string of source code on success, setting error_msg on error.
    """
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg
    error_msg.reserve(4096)
    cdef string code = fb.createSourceFromBoxes(
        name_app.encode('utf8'),
        box.ptr,
        lang.encode('utf8'),
        params.argc,
        params.argv, 
        error_msg)
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return code.decode()

