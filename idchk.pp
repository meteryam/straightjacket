unit idchk;

interface

procedure identifier_check(identifierStr: string; identifier_class: string; currentModule: string; VAR identifier_list: tstringlist);

implementation

procedure identifier_check(identifierStr: string; identifier_class: string; VAR identifier_list: tstringlist; );
begin


// error when adding duplicate identifiers

i := 0;
while i < identifier_list.count do begin

	identifierField := identifier_list.valueFromIndex[i];
	identifier_field_list := extract_fields.extract_fields(identifierField);

	if currentModule = identifier_field_list.valueFromIndex[1] then begin
	if identifierStr = identifier_field_list.valueFromIndex[0] then begin
		writeln('found duplicate identifierStr declaration.  halting compilation.');
		halt;
	end;
	end;

	i := i + 1;
end;

// the first character may not be an underscore.  this prevents collisions with identifiers created by the back-end.

if leftstr(identifierStr,1) = '_' then begin
	writeln('identifier names cannot begin with underscores.  halting.');
	halt;
end;

// fail on prohibited characters.  this allows us to use special characters for operators and other syntactic indicators.

legalID := FALSE;

for i := 0 to length(identifierStr)-1 do begin

	case leftstr(rightstr(identifierStr,length(identifierStr)-i),1) of
		#$0030..#$0039: legalID := TRUE; // '0'..'9'
		#$0041..#$005A: legalID := TRUE; // 'A'..'Z'
		#$0095: legalID := TRUE; 		   // '_'
		#$0061..#$007A: legalID := TRUE; // 'a'..'z'
		else legalID := FALSE;
	end;

end;

if legalID = FALSE then begin
	writeln('identifiers may only contain numbers, letters and underscores.  halting compilation.');
	halt;
end;

// don't allow subroutines to be named "main"

if identifier_class <> 'var_or_con' then begin
if identifierStr = 'main' then begin
	writeln('subroutines may not be named "main".  halting compilation.');
	halt;
end;
end;

// prohibit reserved words

legalID := TRUE;

case identifierStr of
	'import': legalID := FALSE;
	'limport': legalID := FALSE;
	'as': legalID := FALSE;
	'if': legalID := FALSE;
	'then': legalID := FALSE;
	'elseif': legalID := FALSE;
	'else': legalID := FALSE;
	'end': legalID := FALSE;
	'loop': legalID := FALSE;
	'break': legalID := FALSE;
	'foreach': legalID := FALSE;
	'or': legalID := FALSE;
	'and': legalID := FALSE;
	'xor': legalID := FALSE;
	'not': legalID := FALSE;
	'defproc': legalID := FALSE;
	'defun': legalID := FALSE;
	'return': legalID := FALSE;
	'raise': legalID := FALSE;
	'except': legalID := FALSE;
	'when': legalID := FALSE;
	'var': legalID := FALSE;
	'const': legalID := FALSE;
	'char': legalID := FALSE;
	'unsigned': legalID := FALSE;
	'nullable': legalID := FALSE;
	'nul': legalID := FALSE;
	'int': legalID := FALSE;
	'int8': legalID := FALSE;
	'int16': legalID := FALSE;
	'int32': legalID := FALSE;
	'int64': legalID := FALSE;
	'int128': legalID := FALSE;
	'float': legalID := FALSE;
	'float8': legalID := FALSE;
	'float16': legalID := FALSE;
	'float32': legalID := FALSE;
	'float64': legalID := FALSE;
	'float128': legalID := FALSE;
	'nan': legalID := FALSE;
	'top': legalID := FALSE;
	'bool': legalID := FALSE;
	'true': legalID := FALSE;
	'false': legalID := FALSE;
	'complex': legalID := FALSE;
	'pointer': legalID := FALSE;
	'target': legalID := FALSE;
	'struct': legalID := FALSE;
	'field': legalID := FALSE;
	'array': legalID := FALSE;
	'table': legalID := FALSE;
	'list': legalID := FALSE;
	'type': legalID := FALSE;
	'is': legalID := FALSE;
	'convert': legalID := FALSE;
	'to': legalID := FALSE;
end;


end;



end.

