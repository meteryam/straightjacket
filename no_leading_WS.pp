unit no_leading_WS;

interface

uses sysutils, strutils;
function strip (argument: string) : string;

implementation

function strip (argument: string) : string;

var tempstr: string;

begin

tempstr := tab2Space(argument,4);
strip := trimLeft(tempstr);

end;

end.

