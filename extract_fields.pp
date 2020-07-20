unit extract_fields;

interface

uses classes, sysutils;

function extract_fields(identifier: string) : tstringlist;

implementation

function extract_fields(identifier: string) : tstringlist;

var field_list: tstringlist;
var inputChar: string;
var currentField: string;
var i: integer;

begin

	field_list := tstringlist.create;
	inputChar := '';
	currentField := '';

	i := 0;
	while i < length(identifier) do begin
	
		inputChar := leftstr(rightstr(identifier,length(identifier)-i),1);

		if inputChar <> '!' then currentField := currentField + inputChar;

		if inputChar = '!' then begin
			field_list.add(currentField);
		end;

		i := i + 1;
	end;

	extract_fields := field_list;
end;

end.

