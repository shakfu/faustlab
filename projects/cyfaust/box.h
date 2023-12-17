

"""
Opaque types.
"""
class CTree;
typedef vector<CTree*> tvec;

typedef CTree* Signal;
typedef CTree* Box;
typedef CTree* Tree;

typedef Tree (*prim0)();
typedef Tree (*prim1)(Tree x);
typedef Tree (*prim2)(Tree x, Tree y);
typedef Tree (*prim3)(Tree x, Tree y, Tree z);
typedef Tree (*prim4)(Tree w, Tree x, Tree y, Tree z);
typedef Tree (*prim5)(Tree v, Tree w, Tree x, Tree y, Tree z);

const char* prim0name(prim0);
const char* prim1name(prim1);
const char* prim2name(prim2);
const char* prim3name(prim3);
const char* prim4name(prim4);
const char* prim5name(prim5);

"""Return the name parameter of a foreign function.

s - the signal
returns the name
"""
const char* ffname(Signal s);

"""Return the arity of a foreign function.

s - the signal
returns the name
"""
int ffarity(Signal s);

enum SType { kSInt, kSReal };

enum SOperator { kAdd, kSub, kMul, kDiv, kRem, kLsh, kARsh, kLRsh, kGT, kLT, kGE, kLE, kEQ, kNE, kAND, kOR, kXOR };

"""
Base class for factories.
"""
struct dsp_factory_base {
    
    virtual ~dsp_factory_base() {}
    
    virtual void write(std::ostream* /*out*/, bool /*binary*/ = false, bool /*compact*/ = false) {}
};





"""Convert a box (such as the label of a UI) to a string.

b - the box to convert

returns a string representation of a box.
"""
const char* tree2str(Box b);

"""If t has a node of type int, return it. Otherwise error

b - the box to convert

returns the int value of the box.
"""
int tree2int(Box b);

"""Return the xtended type of a box.

b - the box whose xtended type to return

returns a pointer to xtended type if it exists, otherwise nullptr.
"""
void* getUserData(Box b);

"""Constant integer : for all t, x(t) = n.

n - the integer

returns the integer box.
"""

Box boxInt(int n);

"""Constant real : for all t, x(t) = n.

n - the float/double value (depends of -single or -double compilation parameter)

returns the float/double box.
"""
Box boxReal(double n);

"""The identity box, copy its input to its output.

returns the identity box.
"""
Box boxWire();

"""The cut box, to stop/terminate a signal.

returns the cut box.
"""
Box boxCut();

"""The sequential composition of two blocks (e.g., A:B) expects: outputs(A)=inputs(B)

returns the seq box.
"""
Box boxSeq(Box x, Box y);

"""The parallel composition of two blocks (e.g., A,B).

It places the two block-diagrams one on top of the other, without connections.

returns the par box.
"""
Box boxPar(Box x, Box y);

Box boxPar3(Box x, Box y, Box z);

Box boxPar4(Box a, Box b, Box c, Box d);

Box boxPar5(Box a, Box b, Box c, Box d, Box e);

"""The split composition (e.g., A<:B) operator is used to distribute
the outputs of A to the inputs of B.

For the operation to be valid, the number of inputs of B
must be a multiple of the number of outputs of A: outputs(A).k=inputs(B)

returns the split box.
"""
Box boxSplit(Box x, Box y);

"""The merge composition (e.g., A:>B) is the dual of the split composition.

The number of outputs of A must be a multiple of the number of inputs of B: outputs(A)=k.inputs(B)

returns the merge box.
"""
Box boxMerge(Box x, Box y);

"""The recursive composition (e.g., A~B) is used to create cycles in the block-diagram
in order to express recursive computations.

It is the most complex operation in terms of connections: outputs(A)≥inputs(B) and inputs(A)≥outputs(B)

returns the rec box.
"""
Box boxRec(Box x, Box y);

"""The route primitive facilitates the routing of signals in Faust.

It has the following syntax: route(A,B,a,b,c,d,...) or route(A,B,(a,b),(c,d),...)

n -  the number of input signals
m -  the number of output signals
r - the routing description, a 'par' expression of a,b / (a,b) input/output pairs

returns the route box.
"""
Box boxRoute(Box n, Box m, Box r);

"""Create a delayed box.

returns the delayed box.
"""
Box boxDelay();

"""Create a delayed box.

s - the box to be delayed
del - the delay box that doesn't have to be fixed but must be bounded and cannot be negative

returns the delayed box.
"""
Box boxDelay(Box b, Box del);

"""Create a casted box.

returns the casted box.
"""
Box boxIntCast();

"""Create a casted box.

s - the box to be casted in integer

returns the casted box.
"""
Box boxIntCast(Box b);

"""Create a casted box.

returns the casted box.
"""
Box boxFloatCast();

"""Create a casted box.

s - the signal to be casted as float/double value (depends of -single or -double compilation parameter)

returns the casted box.
"""
Box boxFloatCast(Box b);

"""Create a read only table.

returns the table box.
"""
Box boxReadOnlyTable();

"""Create a read only table.

n - the table size, a constant numerical expression (see [1])
init - the table content
ridx - the read index (an int between 0 and n-1)

returns the table box.
"""
Box boxReadOnlyTable(Box n, Box init, Box ridx);

"""Create a read/write table.

returns the table box.
"""
Box boxWriteReadTable();

"""Create a read/write table.

n - the table size, a constant numerical expression (see [1])
init - the table content
widx - the write index (an integer between 0 and n-1)
wsig - the input of the table
ridx - the read index (an integer between 0 and n-1)

returns the table box.
"""
Box boxWriteReadTable(Box n, Box init, Box widx, Box wsig, Box ridx);

"""Create a waveform.

wf - the content of the waveform as a vector of boxInt or boxDouble boxes

returns the waveform box.
"""
Box boxWaveform(const tvec& wf);

"""Create a soundfile block.

label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
chan - the number of outputs channels, a constant numerical expression (see [1])

returns the soundfile box.
"""
Box boxSoundfile(const string& label, Box chan);

"""Create a soundfile block.

label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
chan - the number of outputs channels, a constant numerical expression (see [1])
part - in the [0..255] range to select a given sound number, a constant numerical expression (see [1])
ridx - the read index (an integer between 0 and the selected sound length)

returns the soundfile box.
"""
Box boxSoundfile(const string& label, Box chan, Box part, Box ridx);

"""Create a selector between two boxes.

returns the selected box depending of the selector value at each time t.
"""
Box boxSelect2();

"""Create a selector between two boxes.

selector - when 0 at time t returns s1[t], otherwise returns s2[t]
s1 - first box to be selected
s2 - second box to be selected

returns the selected box depending of the selector value at each time t.
"""
Box boxSelect2(Box selector, Box b1, Box b2);

"""Create a selector between three boxes.

returns the selected box depending of the selector value at each time t.
"""
Box boxSelect3();

"""Create a selector between three boxes.

selector - when 0 at time t returns s1[t], when 1 at time t returns s2[t], otherwise returns s3[t]
s1 - first box to be selected
s2 - second box to be selected
s3 - third box to be selected

returns the selected box depending of the selector value at each time t.
"""
Box boxSelect3(Box selector, Box b1, Box b2, Box b3);

"""Create a foreign constant box.

type - the foreign constant type of SType
name - the foreign constant name
file - the include file where the foreign constant is defined

returns the foreign constant box.
"""
Box boxFConst(SType type, const string& name, const string& file);

"""Create a foreign variable box.

type - the foreign variable type of SType
name - the foreign variable name
file - the include file where the foreign variable is defined

returns the foreign variable box.
"""
Box boxFVar(SType type, const string& name, const string& file);

"""Generic binary mathematical functions.

op - the operator in SOperator set

returns the result box of op(x,y).
"""
Box boxBinOp(SOperator op);

Box boxBinOp(SOperator op, Box b1, Box b2);

"""Specific binary mathematical functions.

returns the result box.
"""
Box boxAdd();
Box boxAdd(Box b1, Box b2);
Box boxSub();
Box boxSub(Box b1, Box b2);
Box boxMul();
Box boxMul(Box b1, Box b2);
Box boxDiv();
Box boxDiv(Box b1, Box b2);
Box boxRem();
Box boxRem(Box b1, Box b2);

Box boxLeftShift();
Box boxLeftShift(Box b1, Box b2);
Box boxLRightShift();
Box boxLRightShift(Box b1, Box b2);
Box boxARightShift();
Box boxARightShift(Box b1, Box b2);

Box boxGT();
Box boxGT(Box b1, Box b2);
Box boxLT();
Box boxLT(Box b1, Box b2);
Box boxGE();
Box boxGE(Box b1, Box b2);
Box boxLE();
Box boxLE(Box b1, Box b2);
Box boxEQ();
Box boxEQ(Box b1, Box b2);
Box boxNE();
Box boxNE(Box b1, Box b2);

Box boxAND();
Box boxAND(Box b1, Box b2);
Box boxOR();
Box boxOR(Box b1, Box b2);
Box boxXOR();
Box boxXOR(Box b1, Box b2);

"""Extended unary mathematical functions.
"""
Box boxAbs();
Box boxAbs(Box x);
Box boxAcos();
Box boxAcos(Box x);
Box boxTan();
Box boxTan(Box x);
Box boxSqrt();
Box boxSqrt(Box x);
Box boxSin();
Box boxSin(Box x);
Box boxRint();
Box boxRint(Box x);
Box boxRound();
Box boxRound(Box x);
Box boxLog();
Box boxLog(Box x);
Box boxLog10();
Box boxLog10(Box x);
Box boxFloor();
Box boxFloor(Box x);
Box boxExp();
Box boxExp(Box x);
Box boxExp10();
Box boxExp10(Box x);
Box boxCos();
Box boxCos(Box x);
Box boxCeil();
Box boxCeil(Box x);
Box boxAtan();
Box boxAtan(Box x);
Box boxAsin();
Box boxAsin(Box x);

"""Extended binary mathematical functions.
"""
Box boxRemainder();
Box boxRemainder(Box b1, Box b2);
Box boxPow();
Box boxPow(Box b1, Box b2);
Box boxMin();
Box boxMin(Box b1, Box b2);
Box boxMax();
Box boxMax(Box b1, Box b2);
Box boxFmod();
Box boxFmod(Box b1, Box b2);
Box boxAtan2();
Box boxAtan2(Box b1, Box b2);

"""Create a button box.

label - the label definition (see [2])

returns the button box.
"""
Box boxButton(const string& label);

"""Create a checkbox box.

label - the label definition (see [2])

returns the checkbox box.
"""
Box boxCheckbox(const string& label);

"""Create a vertical slider box.

label - the label definition (see [2])
init - the init box, a constant numerical expression (see [1])
min - the min box, a constant numerical expression (see [1])
max - the max box, a constant numerical expression (see [1])
step - the step box, a constant numerical expression (see [1])

returns the vertical slider box.
"""
Box boxVSlider(const string& label, Box init, Box min, Box max, Box step);

"""Create an horizontal slider box.

label - the label definition (see [2])
init - the init box, a constant numerical expression (see [1])
min - the min box, a constant numerical expression (see [1])
max - the max box, a constant numerical expression (see [1])
step - the step box, a constant numerical expression (see [1])

returns the horizontal slider box.
"""
Box boxHSlider(const string& label, Box init, Box min, Box max, Box step);

"""Create a num entry box.

label - the label definition (see [2])
init - the init box, a constant numerical expression (see [1])
min - the min box, a constant numerical expression (see [1])
max - the max box, a constant numerical expression (see [1])
step - the step box, a constant numerical expression (see [1])

returns the num entry box.
"""
Box boxNumEntry(const string& label, Box init, Box min, Box max, Box step);

"""Create a vertical bargraph box.

label - the label definition (see [2])
min - the min box, a constant numerical expression (see [1])
max - the max box, a constant numerical expression (see [1])

returns the vertical bargraph box.
"""
Box boxVBargraph(const string& label, Box min, Box max);

"""Create a vertical bargraph box.

label - the label definition (see [2])
min - the min box, a constant numerical expression (see [1])
max - the max box, a constant numerical expression (see [1])
x - the input box

returns the vertical bargraph box.
"""
Box boxVBargraph(const string& label, Box min, Box max, Box x);

"""Create an horizontal bargraph box.

label - the label definition (see [2])
min - the min box, a constant numerical expression (see [1])
max - the max box, a constant numerical expression (see [1])

returns the horizontal bargraph box.
"""
Box boxHBargraph(const string& label, Box min, Box max);

"""Create a horizontal bargraph box.

label - the label definition (see [2])
min - the min box, a constant numerical expression (see [1])
max - the max box, a constant numerical expression (see [1])
x - the input box

returns the horizontal bargraph box.
"""
Box boxHBargraph(const string& label, Box min, Box max, Box x);

"""Create a vertical group box.

label - the label definition (see [2])
group - the group to be added

returns the vertical group box.
"""
Box boxVGroup(const string& label, Box group);

"""Create a horizontal group box.

label - the label definition (see [2])
group - the group to be added

returns the horizontal group box.
"""
Box boxHGroup(const string& label, Box group);

"""Create a tab group box.

label - the label definition (see [2])
group - the group to be added

returns the tab group box.
"""
Box boxTGroup(const string& label, Box group);

"""Create an attach box.

The attach primitive takes two input boxes and produces one output box
which is a copy of the first input. The role of attach is to force
its second input boxes to be compiled with the first one.

returns the attach box.
"""
Box boxAttach();

"""Create an attach box.

The attach primitive takes two input box and produces one output box
which is a copy of the first input. The role of attach is to force
its second input box to be compiled with the first one.

s1 - the first box
s2 - the second box

returns the attach box.
"""
Box boxAttach(Box b1, Box b2);

Box boxPrim2(prim2 foo);

"""Test each box and fill additional boxe specific parameters.

returns true and fill the specific parameters if the box is of a given type, false otherwise
"""
bool isBoxAbstr(Box t);
bool isBoxAbstr(Box t, Box& x, Box& y);
bool isBoxAccess(Box t, Box& exp, Box& id);
bool isBoxAppl(Box t);
bool isBoxAppl(Box t, Box& x, Box& y);
bool isBoxButton(Box b);
bool isBoxButton(Box b, Box& lbl);
bool isBoxCase(Box b);
bool isBoxCase(Box b, Box& rules);
bool isBoxCheckbox(Box b);
bool isBoxCheckbox(Box b, Box& lbl);
bool isBoxComponent(Box b, Box& filename);
bool isBoxCut(Box t);
bool isBoxEnvironment(Box b);
bool isBoxError(Box t);
bool isBoxFConst(Box b);
bool isBoxFConst(Box b, Box& type, Box& name, Box& file);
bool isBoxFFun(Box b);
bool isBoxFFun(Box b, Box& ff);
bool isBoxFVar(Box b);
bool isBoxFVar(Box b, Box& type, Box& name, Box& file);
bool isBoxHBargraph(Box b);
bool isBoxHBargraph(Box b, Box& lbl, Box& min, Box& max);
bool isBoxHGroup(Box b);
bool isBoxHGroup(Box b, Box& lbl, Box& x);
bool isBoxHSlider(Box b);
bool isBoxHSlider(Box b, Box& lbl, Box& cur, Box& min, Box& max, Box& step);
bool isBoxIdent(Box t);
bool isBoxIdent(Box t, const char** str);
bool isBoxInputs(Box t, Box& x);
bool isBoxInt(Box t);
bool isBoxInt(Box t, int* i);
bool isBoxIPar(Box t, Box& x, Box& y, Box& z);
bool isBoxIProd(Box t, Box& x, Box& y, Box& z);
bool isBoxISeq(Box t, Box& x, Box& y, Box& z);
bool isBoxISum(Box t, Box& x, Box& y, Box& z);
bool isBoxLibrary(Box b, Box& filename);
bool isBoxMerge(Box t, Box& x, Box& y);
bool isBoxMetadata(Box b, Box& exp, Box& mdlist);
bool isBoxNumEntry(Box b);
bool isBoxNumEntry(Box b, Box& lbl, Box& cur, Box& min, Box& max, Box& step);
bool isBoxOutputs(Box t, Box& x);
bool isBoxPar(Box t, Box& x, Box& y);
bool isBoxPrim0(Box b);
bool isBoxPrim1(Box b);
bool isBoxPrim2(Box b);
bool isBoxPrim3(Box b);
bool isBoxPrim4(Box b);
bool isBoxPrim5(Box b);
bool isBoxPrim0(Box b, prim0* p);
bool isBoxPrim1(Box b, prim1* p);
bool isBoxPrim2(Box b, prim2* p);
bool isBoxPrim3(Box b, prim3* p);
bool isBoxPrim4(Box b, prim4* p);
bool isBoxPrim5(Box b, prim5* p);
bool isBoxReal(Box t);
bool isBoxReal(Box t, double* r);
bool isBoxRec(Box t, Box& x, Box& y);
bool isBoxRoute(Box b, Box& n, Box& m, Box& r);
bool isBoxSeq(Box t, Box& x, Box& y);
bool isBoxSlot(Box t);
bool isBoxSlot(Box t, int* id);
bool isBoxSoundfile(Box b);
bool isBoxSoundfile(Box b, Box& label, Box& chan);
bool isBoxSplit(Box t, Box& x, Box& y);
bool isBoxSymbolic(Box t);
bool isBoxSymbolic(Box t, Box& slot, Box& body);
bool isBoxTGroup(Box b);
bool isBoxTGroup(Box b, Box& lbl, Box& x);
bool isBoxVBargraph(Box b);
bool isBoxVBargraph(Box b, Box& lbl, Box& min, Box& max);
bool isBoxVGroup(Box b);
bool isBoxVGroup(Box b, Box& lbl, Box& x);
bool isBoxVSlider(Box b);
bool isBoxVSlider(Box b, Box& lbl, Box& cur, Box& min, Box& max, Box& step);
bool isBoxWaveform(Box b);
bool isBoxWire(Box t);
bool isBoxWithLocalDef(Box t, Box& body, Box& ldef);

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
Box DSPToBoxes(const string& name_app, const string& dsp_content, int argc, const char* argv[], int* inputs, int* outputs, string& error_msg);

"""Return the number of inputs and outputs of a box

box - the box we want to know the number of inputs and outputs
inputs - the place to return the number of inputs
outputs - the place to return the number of outputs

returns true if type is defined, false if undefined.
"""
bool getBoxType(Box box, int* inputs, int* outputs);

"""Compile a box expression in a list of signals in normal form
(see simplifyToNormalForm in libfaust-signal.h)

box - the box expression
error_msg - the error string to be filled

returns a list of signals in normal form on success, otherwise an empty list.
"""
tvec boxesToSignals(Box box, string& error_msg);

"""Create source code in a target language from a box expression.

name_app - the name of the Faust program
box - the box expression
lang - the target source code's language which can be one of "c",
"cpp", "cmajor", "codebox", "csharp", "dlang", "fir", "interp", "java", "jax",
"jsfx", "julia", "ocpp", "rust" or "wast"
(depending of which of the corresponding backends are compiled in libfaust)
argc - the number of parameters in argv array
argv - the array of parameters
error_msg - the error string to be filled

returns a string of source code on success, setting error_msg on error.
"""
string createSourceFromBoxes(const string& name_app, Box box,
                                               const string& lang,
                                               int argc, const char* argv[],
                                               string& error_msg);


