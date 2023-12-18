

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







Box boxPrim2(prim2 foo);

"""Test each box and fill additional boxe specific parameters.

returns true and fill the specific parameters if the box is of a given type, false otherwise
"""

WARNINGS

2. cyfaust_get_user_data
3. box_prim2
4. is_box_ident
5. is_box_prim0
6. is_box_prim1
7. is_box_prim2
8. is_box_prim3
9. is_box_prim4
10 is_box_prim5
11. getUserData






