unit literate;

interface

uses no_leading_WS, classes, sysutils;

function literate_extract(VAR argument: string) : string;

implementation

function literate_extract(VAR argument: string) : string;

var litInput: textFile;
var litOutput: textFile;
var currentLine: ansiString;
var workingStr: ansiString;
var count: integer;
var tag_list: tstringList;
var mode: integer;
var currentTag: string;
var loopStr: ansiString;
var tempFileName: string;
var foundMatch: boolean;

begin

assign(litInput,argument);
reset(litInput);

tag_list := tstringlist.create;
currentTag := '';
mode := 0;
workingStr := '';

while not EOF(litInput) do begin

		// mode 0 means ignore the line being read
		// mode 1 means start collecting tags
		// mode 2 means start extracting the enclosed code

	readln(litInput, currentLine);
	workingStr := no_leading_WS.strip(currentLine);

	if leftStr(workingStr,2) = '<<' then begin	// handle markup

		if workingStr = '<<def>>' then mode := 1;
		if workingStr = '<</def>>' then mode := 0;

		if (workingStr <> '<<def>>') AND (workingStr <> '<</def>>') then begin

			foundMatch := FALSE;
			count := tag_list.count-1;

			while count >= 0 do begin

				loopStr := tag_list.valueFromIndex[count];

				if (lowercase(workingStr) = '<<' + lowercase(loopStr) + '>>') then begin
					foundMatch := TRUE;
					currentTag := loopStr;
					mode := 2;

					tempFileName := 'working\' + currentTag + '.txt';
					assign(litOutput,tempFileName);
					if fileExists(tempFileName) = TRUE then append(litOutput);
					if fileExists(tempFileName) = FALSE then rewrite(litOutput);
					count := 0;
				end;

				if (lowercase(workingStr) = '<</' + lowercase(loopStr) + '>>') then begin
					foundMatch := TRUE;
					currentTag := '';
					close(litOutput);
					count := 0;
				end;

				count := count - 1;

			end;	// while count > 0

			if foundMatch = FALSE then begin
				writeln('tag not defined in tag list.');
				halt;
			end;

			mode := 2;
		end;	// if (workingStr <> '<<def>>') AND (workingStr <> '<</def>>')

	end;	// if leftStr(workingStr,2) = '<<'

	if (workingStr <> '') AND (leftStr(workingStr,2) <> '<<') then begin		// handle content
		if mode = 1 then tag_list.add(lowercase(workingStr));
		if mode = 2 then writeln(litOutput, currentLine);
	end;

end;	// while not EOF(litInput)

//
//	append the extracted text into one file
//

assign(litOutput,'working\' + argument);
rewrite(litOutput);

for loopStr in tag_list do begin
	assign(litInput,'working\' + loopStr + '.txt');
	reset(litInput);

	while not EOF(litInput) do begin
		readln(litInput, currentLine);
		writeln(litOutput, currentLine);
	end;

	close(litInput);
end;

close(litOutput);

for loopStr in tag_list do begin	// clean up temporary files
	tempFileName := 'working\' + loopStr + '.txt';
	deleteFile(tempFileName);
end;

literate_extract := 'working\' + argument;

end;

end.
