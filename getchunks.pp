unit getchunks;

interface

uses classes, sysutils, strutils;
function getchunks (currentLine: string) : tstringlist;

implementation

function getchunks (currentLine: string) : tstringlist;

var inputChar: char;
var foundString: boolean;
var skip: boolean;
//var comment: boolean;
var workingStr: string;
var currentChunk: string;
var prevChar: char;
var chunk_list: tstringlist;
//var i: integer;

{$GOTO ON}
label found_comment;
label finish;

begin

chunk_list := tstringlist.create;
//chunk_list.clear;

currentChunk := '';
foundString := FALSE;
prevChar := chr(0);
skip := FALSE;
//comment := FALSE;

if currentLine <> '' then begin

	workingStr := trim(tab2Space(currentLine,1));

	//i := 0;
	for inputChar in workingStr do begin
	//while i < length(workingStr) do begin

		//inputChar := leftstr(rightstr(workingStr,length(workingStr)-1),1);
		//writeln('inputChar: ' + inputChar);

		if foundString = TRUE then begin
			currentChunk := currentChunk + inputChar;	// quoted strings need to end in back-quotes

			if inputChar = '`' then begin	// switch to non-string when it ends
				if currentChunk <> '' then chunk_list.add(currentChunk);
				currentChunk := '';
				foundString := FALSE;
				skip := TRUE;				// don't process back-quotes twice
			end;
		end;

		if foundString = FALSE then begin	// start handling quoted strings
			if (inputChar = '`') AND (skip = FALSE) then begin
				foundString := TRUE;
				if currentChunk <> '' then chunk_list.add(currentChunk);
				currentChunk := '`';		// quoted strings need to begin with back-quotes
			end;

			skip := FALSE;	// don't process back-quotes twice

			if inputChar <> '`' then begin
				if (inputChar <> ' ') AND (inputChar <> chr(9)) then begin

					if (inputChar = '/') then begin
						if (prevChar = '/') then goto found_comment;
						//if (prevChar = chr(0)) then prevChar := '/';
					end;

					if (inputChar <> '/') then begin

						// currentChunk := currentChunk + inputChar;

						if prevChar <> '/' then begin

							if (inputChar = '(') OR (inputChar = ')') then begin
								if currentChunk <> '' then chunk_list.add(currentChunk);
								chunk_list.add(inputChar);	// parentheses get their own lines
								currentChunk := '';
							end;

								// put everything within enclosed parentheses into its own chunk

							if (inputChar <> '(') AND (inputChar <> ')') then currentChunk := currentChunk + lowercase(inputChar);

							if inputChar = '=' then currentChunk := currentChunk + inputChar;

								// when an equal sign is found, put the rest of workingStr in its own chunk.

						end;

						if prevChar = '/' then begin
							writeln('comments require two forward-slashes, not one.');
							halt;
						end;
					end;	// if (inputChar <> '/')

				end;	// if (inputChar <> ' ') AND (inputChar <> chr(9))

				if (inputChar = ' ') OR (inputChar = chr(9)) then begin
					//write(currentChunk + ' ');
					if currentChunk <> '' then chunk_list.add(currentChunk);
					currentChunk := '';

					// if the first chunk was "if", then write special code to handle the rest of workingStr
					// format:  if - conditions - then

				end;
			end;	// if inputChar <> '`'
		end;	// if foundString = FALSE

		prevChar := inputChar;
		//writeln('prevChar: ' + prevChar);

//		i := i + 1;

	end;	// for inputChar in currentLine

	if currentChunk <> '' then chunk_list.add(currentChunk);

	getchunks := chunk_list;
end;

goto finish;

found_comment:
chunk_list.clear;

finish:
if currentLine = '' then getchunks := chunk_list;

end;

end.

