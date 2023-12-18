


names = [
	'Add',
	'Sub',
	'Mul',
	'Div',
	'Rem',
	'LeftShift',
	'LRightShift',
	'ARightShift',
	'GT',
	'LT',
	'GE',
	'LE',
	'EQ',
	'NE',
	'AND',
	'OR',
	'XOR',
	'Remainder',
	'Pow',
	'Min',
	'Max',
	'Fmod',
	'Atan2',
 ]

f = """\
def box_{lname}_op() -> Box:
    cdef fb.Box b = fb.box{name}()
    return Box.from_ptr(b)

def box_{lname}(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.box{name}(b1.ptr, b2.ptr)
    return Box.from_ptr(b)
"""

for i in names:
	print(f.format(lname=i.lower(), name=i))
