unit vardef;

interface

uses classes, extract_fields, sysutils, strutils;

procedure vardef_proc(VAR chunk_list: tstringlist; VAR identifier_list: tstringlist; VAR module_list: tstringlist; lineNumber: integer; currentModule: string);

implementation

procedure declare_char(varname: string; value: string; procname: string; currentModule: string; nullableFlag: boolean);

var outputFile: textFile;
var outputFileName: string;

begin

	if nullableFlag = FALSE then begin
		if value = '\0' then begin
			writeln('you cannot assign null to a non-nullable identifier.  halting compilation.');
			halt;
		end;
		if value = '' then begin
			writeln('non-nullable character variables must must be initialized at declaration time.  halting compilation.');
			halt;
		end;
	end
	else begin
		if value = '' then value := '\0';
	end;

	outputFileName := 'working\' + currentModule;
	assign(outputFile,outputFileName);

	if fileExists(outputFileName) = TRUE then append(outputFile);
	if fileExists(outputFileName) = FALSE then rewrite(outputFile);

	if procname <> '' then begin

		write(outputFile,'@' + procname + varname + ' = internal global');

	end;

	if procname = '' then begin

		write(outputFile,'@' + varname + ' = internal global');

	end;

	write(outputFile,' i8 ');

//	writeln('value: ' + value);

	case value of
		'\\': writeln(outputFile,'92; \');
		'\`': writeln(outputFile,'126; `');
		'\0': writeln(outputFile,'0; null');
		'\a': writeln(outputFile,'7; bell');
		'\b': writeln(outputFile,'8; backspace');
		'\t': writeln(outputFile,'9; tab');
		'\f': writeln(outputFile,'12; form feed');
		'\n': writeln(outputFile,'10; line feed');
		'\r': writeln(outputFile,'13; carriage return');
		'\e': writeln(outputFile,'27; escape');
		' ': writeln(outputFile,'32; space');
		'!': writeln(outputFile,'33; exclamation');
		'"': writeln(outputFile,'34; double quote');
		'#': writeln(outputFile,'35; pound sign');
		'$': writeln(outputFile,'36; dollar sign');
		'%': writeln(outputFile,'37; percent sign');
		'&': writeln(outputFile,'38; ampersand');
		chr(39): writeln(outputFile,chr(39) + '; single quote');
		'(': writeln(outputFile,'40; left parenthesis');
		')': writeln(outputFile,'41; right parenthesis');
		'*': writeln(outputFile,'42; asterisk');
		'+': writeln(outputFile,'43; plus sign');
		',': writeln(outputFile,'44; comma');
		'-': writeln(outputFile,'45; dash');
		'.': writeln(outputFile,'46; period');
		'/': writeln(outputFile,'47; forward-slash');
		'0': writeln(outputFile,'48; zero');
		'1': writeln(outputFile,'49; one');
		'2': writeln(outputFile,'50; two');
		'3': writeln(outputFile,'51; three');
		'4': writeln(outputFile,'52; four');
		'5': writeln(outputFile,'53; five');
		'6': writeln(outputFile,'54; six');
		'7': writeln(outputFile,'55; seven');
		'8': writeln(outputFile,'56; eight');
		'9': writeln(outputFile,'57; nine');
		':': writeln(outputFile,'58; colon');
		';': writeln(outputFile,'59; semicolon');
		'<': writeln(outputFile,'60; less than');
		'=': writeln(outputFile,'61; equal sign');
		'>': writeln(outputFile,'62; greater than');
		'?': writeln(outputFile,'63; question mark');
		'@': writeln(outputFile,'64; at sign');
		'A': writeln(outputFile,'65; A');
		'B': writeln(outputFile,'66; B');
		'C': writeln(outputFile,'67; C');
		'D': writeln(outputFile,'68; D');
		'E': writeln(outputFile,'69; E');
		'F': writeln(outputFile,'70; F');
		'G': writeln(outputFile,'71; G');
		'H': writeln(outputFile,'72; H');
		'I': writeln(outputFile,'73; I');
		'J': writeln(outputFile,'74; J');
		'K': writeln(outputFile,'75; K');
		'L': writeln(outputFile,'76; L');
		'M': writeln(outputFile,'77; M');
		'N': writeln(outputFile,'78; N');
		'O': writeln(outputFile,'79; O');
		'P': writeln(outputFile,'80; P');
		'Q': writeln(outputFile,'81; Q');
		'R': writeln(outputFile,'82; R');
		'S': writeln(outputFile,'83; S');
		'T': writeln(outputFile,'84; T');
		'U': writeln(outputFile,'85; U');
		'V': writeln(outputFile,'86; V');
		'W': writeln(outputFile,'87; W');
		'X': writeln(outputFile,'88; X');
		'Y': writeln(outputFile,'89; Y');
		'Z': writeln(outputFile,'90; Z');
		'[': writeln(outputFile,'91; [');
		'\': writeln(outputFile,'92; \');
		']': writeln(outputFile,'93; ]');
		'^': writeln(outputFile,'94; ^');
		'_': writeln(outputFile,'95; _');
		'a': writeln(outputFile,'97; a');
		'b': writeln(outputFile,'98; b');
		'c': writeln(outputFile,'99; c');
		'd': writeln(outputFile,'100; d');
		'e': writeln(outputFile,'101; e');
		'f': writeln(outputFile,'102; f');
		'g': writeln(outputFile,'103; g');
		'h': writeln(outputFile,'104; h');
		'i': writeln(outputFile,'105; i');
		'j': writeln(outputFile,'106; j');
		'k': writeln(outputFile,'107; k');
		'l': writeln(outputFile,'108; l');
		'm': writeln(outputFile,'109; m');
		'n': writeln(outputFile,'110; n');
		'o': writeln(outputFile,'111; o');
		'p': writeln(outputFile,'112; p');
		'q': writeln(outputFile,'113; q');
		'r': writeln(outputFile,'114; r');
		's': writeln(outputFile,'115; s');
		't': writeln(outputFile,'116; t');
		'u': writeln(outputFile,'117; u');
		'v': writeln(outputFile,'118; v');
		'w': writeln(outputFile,'119; w');
		'x': writeln(outputFile,'120; x');
		'y': writeln(outputFile,'121; y');
		'z': writeln(outputFile,'122; z');
		'{': writeln(outputFile,'123; {');
		'|': writeln(outputFile,'124; |');
		'}': writeln(outputFile,'125; }');
		'~': writeln(outputFile,'126; ~');
		else writeln(IntToStr(Hex2Dec(rightstr(value,length(value)-1))) + ' ; ' + value);
	end;

	writeln(outputFile);

	close(outputFile);

end;

procedure vardef_proc(VAR chunk_list: tstringlist; VAR identifier_list: tstringlist; VAR module_list: tstringlist; lineNumber: integer; currentModule: string);

var i: integer;
var limit: integer;
var currentChunk: ansiString;
var type_list: tstringlist;
var identifier_field_list: tstringlist;
// var found_duplicate: boolean;
var currentLine: string;
var quoted_char: string;
var varname: string;
var identifier_kind1: string;
var identifier_kind2: string;
var exportFlag: string;
var nullableFlag: boolean;
var legalVariable: boolean;
var newIdentifierListEntry: string;
var typeNumStr: string;
var identifierField: string;
var exclam_pos: integer;

begin

for i := 0 to module_list.count - 1 do begin

	exclam_pos := pos('!', module_list.valueFromIndex[i]);

	if (leftStr(module_list.valueFromIndex[i], exclam_pos-1) = currentModule) then begin
	if (rightStr(module_list.valueFromIndex[i], length(module_list.valueFromIndex[i])-exclam_pos) = 'main') then begin
		writeln('declarations not allowed in the main module.  halting compilation.');
		halt;
	end;
	end;

end;

if chunk_list.valueFromIndex[0] = 'var' then identifier_kind2 := '5';
if chunk_list.valueFromIndex[0] = 'const' then identifier_kind2 := '6';

type_list := tstringlist.create;
identifier_field_list := tstringlist.create;


// print the contents of chunk_list

currentLine := '';
i := 0;
while i < chunk_list.count do begin

	currentChunk := chunk_list.valueFromIndex[i];
	currentLine := currentLine + currentChunk;
	if i < chunk_list.count - 1 then currentLine := currentLine + ' ';

	write(currentChunk + ' ');

	i := i + 1;
end;
writeln;


// fill type_list

limit := 0;

if chunk_list.valueFromIndex[chunk_list.count-2] = '=' then limit := 3;
if chunk_list.valueFromIndex[chunk_list.count-2] <> '=' then limit := 1;

i := 1;
while i < chunk_list.count-limit do begin
	currentChunk := chunk_list.valueFromIndex[i];
	type_list.add(currentChunk);
	i := i + 1;
end;


// print declared types

i := 0;
while i < type_list.count do begin

	currentChunk := type_list.valueFromIndex[i];
//		write(currentChunk + ' ');

	i := i + 1;
end;
//	writeln;


// extract information about the variable from its declaration

exportFlag := '';
nullableFlag := FALSE;
quoted_char := '';

// if type_list.valueFromIndex[type_list.count-1] = 'char' then begin

if type_list.count >= 2 then begin
	if type_list.valueFromIndex[type_list.count-2] = 'nullable' then nullableFlag := TRUE;
end;

// define the digits in typeNumStr

if chunk_list.valueFromIndex[chunk_list.count-2] = '=' then begin
	quoted_char := chunk_list.valueFromIndex[chunk_list.count-1];

	if (leftStr(chunk_list.valueFromIndex[chunk_list.count-3],1) = '$') OR (leftStr(chunk_list.valueFromIndex[chunk_list.count-3],1) = '~') then begin

		if rightStr(leftStr(chunk_list.valueFromIndex[chunk_list.count-3],2),1) = '_' then begin
			writeln('variable names cannot begin with underscores.  halting compilation.');
			halt;
		end;

		exportFlag := leftStr(chunk_list.valueFromIndex[chunk_list.count-3],1);
		varname := rightStr(chunk_list.valueFromIndex[chunk_list.count-3],length(rightStr(chunk_list.valueFromIndex[chunk_list.count-3],chunk_list.count-2)));

		if chunk_list.valueFromIndex[0] = 'const' then begin
		if exportFlag = '$' then begin
			writeln('constants may only be exported as read-only values.  halting compilation.');
			halt;
		end;
		end;
	end;

	if (leftStr(chunk_list.valueFromIndex[chunk_list.count-3],1) <> '$') AND (leftStr(chunk_list.valueFromIndex[chunk_list.count-3],1) <> '~') then begin

		if leftStr(chunk_list.valueFromIndex[chunk_list.count-3],1) = '_' then begin
			writeln('variable names cannot begin with underscores.  halting compilation.');
			halt;
		end;

		varname := chunk_list.valueFromIndex[chunk_list.count-3];
	end;


end;

if chunk_list.valueFromIndex[chunk_list.count-2] <> '=' then begin

	if chunk_list.valueFromIndex[0] = 'const' then begin
		writeln('constants must be initialized at declaration time.  halting compilation.');
		halt;
	end;

	quoted_char := chr(96) + chr(96);	// transmit empty string
	varname := chunk_list.valueFromIndex[chunk_list.count-1];
end;

//		writeln('quoted_char: ' + quoted_char);

// end;	// if type_list.valueFromIndex[type_list.count-1] = 'char'



// verify that the identifier has no problems

identifier_check(varname, 'var_or_con', currentModule, identifier_list);




// update identifier_list

 if exportFlag = '' then identifier_kind1 := '0';	// private
if exportFlag = '$' then identifier_kind1 := '1';	// shared
if exportFlag = '~' then identifier_kind1 := '2';	// shared read-only

newIdentifierListEntry := varname + '!' + currentModule + '!' + identifier_kind1 + identifier_kind2 + '!0!0!' + typeNumStr + '!';
	// once we have subroutines, supply the current subroutine name as the last parameter.

identifier_list.add(newIdentifierListEntry);



// write the declaration code

case type_list.valueFromIndex[type_list.count-1] of
	'char': legalVariable := declare_char(varname, leftstr(rightstr(quoted_char,length(quoted_char)-1),length(quoted_char)-2), '', currentModule, nullableFlag);
		// once we have subroutines, supply module.subroutine. as the last parameter.
end;


end;

end.


// var char something = `B`

// outer type handlers (can) call type handlers for the types they enclose
// list > array > primitive

// write a 1d array handler
	// write separate code for each primitive type
legalVariable