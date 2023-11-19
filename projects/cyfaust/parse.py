import re


FUNC = re.compile(r"^cdef\s+(.+)\s+(\w+)\((.+)\):")

def to_snake_case(name):
    name = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    name = re.sub('__([A-Z])', r'_\1', name)
    name = re.sub('([a-z0-9])([A-Z])', r'\1_\2', name)
    return name.lower()

def to_camel_case(name):
	return ''.join(word.title() for word in name.split('_'))

with open("scratch.cpp") as f:
	lines = f.readlines()

doc_linenum = None
rows = []
row = {}
for i, line in enumerate(lines):
	line = line.strip()
	if doc_linenum == i:
		row['doc'] = line.lstrip("* ")
		# print("doc:", row['doc'])
	if line.startswith("/**"):
		doc_linenum = i+1		
	if line.startswith("cdef"):
		row['func'] = line
		# print("func:", row['func'])
		if 'doc' in row:
			rows.append(row)
			row = {}

for r in rows:
	func = r['func']
	func = func.replace(';', ':')
	docstring = f'''    \"\"\"{r['doc']}\"\"\"'''
	if FUNC.match(func):
		m = FUNC.match(func)
		returntype, fname, args = m.groups()
		snakename = to_snake_case(fname[1:])
		qual_func = f"fi.{fname}"
		params = args.split(',')
		# print(params)
		_args = ", ".join(p.split()[-1] for p in params)
		func = func.replace(fname, snakename)
		print(func)
		print(docstring)
		print(f"    return {qual_func}({_args})")
	print()
