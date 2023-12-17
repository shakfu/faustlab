

cdef void* getUserData(Signal s):
    """Return the xtended type of a signal.

    s - the signal whose xtended type to return

    returns a pointer to xtended type if it exists, otherwise nullptr.
    """








cdef Signal sigFConst(SType type, const string& name, const string& file)

    """Create a foreign constant signal.

    type - the foreign constant type of SType
    name - the foreign constant name
    file - the include file where the foreign constant is defined

    returns the foreign constant signal.
    """

cdef Signal sigFVar(SType type, const string& name, const string& file)
    """Create a foreign variable signal.

    type - the foreign variable type of SType
    name - the foreign variable name
    file - the include file where the foreign variable is defined

    returns the foreign variable signal.
    """

cdef Signal sigBinOp(SOperator op, Signal x, Signal y)
    """Generic binary mathematical functions.

    op - the operator in SOperator set
    x - first signal
    y - second signal

    returns the result signal of op(x,y).
    """

"""Specific binary mathematical functions.

x - first signal
y - second signal

returns the result signal of fun(x,y).
"""
cdef Signal sigAdd(Signal x, Signal y)
cdef Signal sigSub(Signal x, Signal y)
cdef Signal sigMul(Signal x, Signal y)
cdef Signal sigDiv(Signal x, Signal y)
cdef Signal sigRem(Signal x, Signal y)

cdef Signal sigLeftShift(Signal x, Signal y)
cdef Signal sigLRightShift(Signal x, Signal y)
cdef Signal sigARightShift(Signal x, Signal y)

cdef Signal sigGT(Signal x, Signal y)
cdef Signal sigLT(Signal x, Signal y)
cdef Signal sigGE(Signal x, Signal y)
cdef Signal sigLE(Signal x, Signal y)
cdef Signal sigEQ(Signal x, Signal y)
cdef Signal sigNE(Signal x, Signal y)

cdef Signal sigAND(Signal x, Signal y)
cdef Signal sigOR(Signal x, Signal y)
cdef Signal sigXOR(Signal x, Signal y)

"""Extended unary mathematical functions.
"""
cdef Signal sigAbs(Signal x)
cdef Signal sigAcos(Signal x)
cdef Signal sigTan(Signal x)
cdef Signal sigSqrt(Signal x)
cdef Signal sigSin(Signal x)
cdef Signal sigRint(Signal x)
cdef Signal sigLog(Signal x)
cdef Signal sigLog10(Signal x)
cdef Signal sigFloor(Signal x)
cdef Signal sigExp(Signal x)
cdef Signal sigExp10(Signal x)
cdef Signal sigCos(Signal x)
cdef Signal sigCeil(Signal x)
cdef Signal sigAtan(Signal x)
cdef Signal sigAsin(Signal x)

"""Extended binary mathematical functions.
"""
cdef Signal sigRemainder(Signal x, Signal y)
cdef Signal sigPow(Signal x, Signal y)
cdef Signal sigMin(Signal x, Signal y)
cdef Signal sigMax(Signal x, Signal y)
cdef Signal sigFmod(Signal x, Signal y)
cdef Signal sigAtan2(Signal x, Signal y)


cdef Signal sigSelf():
    """Create a recursive signal inside the sigRecursion expression.

    returns the recursive signal.
    """


cdef Signal sigRecursion(Signal s):
    """Create a recursive signal. Use sigSelf() to refer to the
    recursive signal inside the sigRecursion expression.

    s - the signal to recurse on.

    returns the signal with a recursion.
    """



cdef Signal sigSelfN(int id):
    """Create a recursive signal inside the sigRecursionN expression.

    id - the recursive signal index (starting from 0, up to the number of outputs signals in the recursive block)

    returns the recursive signal.
    """


cdef tvec sigRecursionN(const tvec& rf):
    """
    Create a recursive block of signals. Use sigSelfN() to refer to the
    recursive signal inside the sigRecursionN expression.

    rf - the list of signals to recurse on.

    returns the list of signals with recursions.
    """



cdef Signal sigButton(const string& label):
    """Create a button signal.

    label - the label definition (see [2])

    returns the button signal.
    """


cdef Signal sigCheckbox(const string& label):
    """Create a checkbox signal.

    label - the label definition (see [2])

    returns the checkbox signal.
    """


cdef Signal sigVSlider(const string& label, Signal init, Signal min, Signal max, Signal step):
    """Create a vertical slider signal.

    label - the label definition (see [2])
    init - the init signal, a constant numerical expression (see [1])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    step - the step signal, a constant numerical expression (see [1])

    returns the vertical slider signal.
    """



cdef Signal sigHSlider(const string& label, Signal init, Signal min, Signal max, Signal step):
    """Create an horizontal slider signal.

    label - the label definition (see [2])
    init - the init signal, a constant numerical expression (see [1])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    step - the step signal, a constant numerical expression (see [1])

    returns the horizontal slider signal.
    """



cdef Signal sigNumEntry(const string& label, Signal init, Signal min, Signal max, Signal step):
    """Create a num entry signal.

    label - the label definition (see [2])
    init - the init signal, a constant numerical expression (see [1])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    step - the step signal, a constant numerical expression (see [1])

    returns the num entry signal.
    """



cdef Signal sigVBargraph(const string& label, Signal min, Signal max, Signal s):
    """Create a vertical bargraph signal.

    label - the label definition (see [2])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    s - the input signal

    returns the vertical bargraph signal.
    """



cdef Signal sigHBargraph(const string& label, Signal min, Signal max, Signal s):
    """Create an horizontal bargraph signal.

    label - the label definition (see [2])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    s - the input signal

    returns the horizontal bargraph signal.
    """



cdef Signal sigAttach(Signal s1, Signal s2):
    """Create an attach signal.

    The attach primitive takes two input signals and produces one output signal
    which is a copy of the first input. The role of attach is to force
    its second input signal to be compiled with the first one.

    s1 - the first signal
    s2 - the second signal

    returns the attach signal.
    """


"""
Test each signal and fill additional signal specific parameters.

returns true and fill the specific parameters if the signal is of a given type, false otherwise
"""
cdef bool isSigInt(Signal t, int* i)
cdef bool isSigReal(Signal t, double* r)
cdef bool isSigInput(Signal t, int* i)
cdef bool isSigOutput(Signal t, int* i, Signal& t0)
cdef bool isSigDelay1(Signal t, Signal& t0)
cdef bool isSigDelay(Signal t, Signal& t0, Signal& t1)
cdef bool isSigPrefix(Signal t, Signal& t0, Signal& t1)
cdef bool isSigRDTbl(Signal s, Signal& t, Signal& i)
cdef bool isSigWRTbl(Signal u, Signal& id, Signal& t, Signal& i, Signal& s)
cdef bool isSigGen(Signal t, Signal& x)
cdef bool isSigDocConstantTbl(Signal t, Signal& n, Signal& sig)
cdef bool isSigDocWriteTbl(Signal t, Signal& n, Signal& sig, Signal& widx, Signal& wsig)
cdef bool isSigDocAccessTbl(Signal t, Signal& tbl, Signal& ridx)
cdef bool isSigSelect2(Signal t, Signal& selector, Signal& s1, Signal& s2)
cdef bool isSigAssertBounds(Signal t, Signal& s1, Signal& s2, Signal& s3)
cdef bool isSigHighest(Signal t, Signal& s)
cdef bool isSigLowest(Signal t, Signal& s)

cdef bool isSigBinOp(Signal s, int* op, Signal& x, Signal& y)
cdef bool isSigFFun(Signal s, Signal& ff, Signal& largs)
cdef bool isSigFConst(Signal s, Signal& type, Signal& name, Signal& file)
cdef bool isSigFVar(Signal s, Signal& type, Signal& name, Signal& file)

cdef bool isProj(Signal s, int* i, Signal& rgroup)
cdef bool isRec(Signal s, Signal& var, Signal& body)

cdef bool isSigIntCast(Signal s, Signal& x)
cdef bool isSigFloatCast(Signal s, Signal& x)

cdef bool isSigButton(Signal s, Signal& lbl)
cdef bool isSigCheckbox(Signal s, Signal& lbl)

cdef bool isSigWaveform(Signal s)

cdef bool isSigHSlider(Signal s, Signal& lbl, Signal& init, Signal& min, Signal& max, Signal& step)
cdef bool isSigVSlider(Signal s, Signal& lbl, Signal& init, Signal& min, Signal& max, Signal& step)
cdef bool isSigNumEntry(Signal s, Signal& lbl, Signal& init, Signal& min, Signal& max, Signal& step)

cdef bool isSigHBargraph(Signal s, Signal& lbl, Signal& min, Signal& max, Signal& x)
cdef bool isSigVBargraph(Signal s, Signal& lbl, Signal& min, Signal& max, Signal& x)

cdef bool isSigAttach(Signal s, Signal& s0, Signal& s1)

cdef bool isSigEnable(Signal s, Signal& s0, Signal& s1)
cdef bool isSigControl(Signal s, Signal& s0, Signal& s1)

cdef bool isSigSoundfile(Signal s, Signal& label)
cdef bool isSigSoundfileLength(Signal s, Signal& sf, Signal& part)
cdef bool isSigSoundfileRate(Signal s, Signal& sf, Signal& part)
cdef bool isSigSoundfileBuffer(Signal s, Signal& sf, Signal& chan, Signal& part, Signal& ridx)


cdef Signal simplifyToNormalForm(Signal s):
    """Simplify a signal to its normal form, where:
     
     - all possible optimisations, simplications, and compile time computations have been done
     - the mathematical functions (primitives and binary functions), delay, select2, soundfile primitive...
     are properly typed (arguments and result)
     - signal cast are properly done when needed

    sig - the signal to be processed

    returns the signal in normal form.
    """



cdef tvec simplifyToNormalForm2(tvec siglist):
    """Simplify a signal list to its normal form, where:
     
     - all possible optimisations, simplications, and compile time computations have been done
     - the mathematical functions (primitives and binary functions), delay, select2, soundfile primitive...
     are properly typed (arguments and result)
     - signal cast are properly done when needed

    siglist - the signal list to be processed

    returns the signal vector in normal form.
    """



cdef string createSourceFromSignals(const string& name_app, tvec osigs, const string& lang, nt argc, const char* argv[], string& error_msg):
    """Create source code in a target language from a vector of output signals.

    name_app - the name of the Faust program
    osigs - the vector of output signals (that will internally be converted in normal form,
    see simplifyToNormalForm)
    lang - the target source code's language which can be one of 'c',
    'cpp', 'cmajor', 'codebox', 'csharp', 'dlang', 'fir', 'interp', 'java', 'jax',
    'jsfx', 'julia', 'ocpp', 'rust' or 'wast'
    (depending of which of the corresponding backends are compiled in libfaust)
    argc - the number of parameters in argv array
    argv - the array of parameters
    error_msg - the error string to be filled

    returns a string of source code on success, setting error_msg on error.
    """
