

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


