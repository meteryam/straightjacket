echo off
REM fpc -O3 -Cr -Fuunits no_leading_WS.txt
REM fpc -O3 -Cr -Fuunits literate.txt
REM fpc -O3 -Cr -Fuunits getchunks.txt
REM fpc -O3 -Cr -Fuunits statement.txt
REM fpc -O3 -Cr -Fuunits branch.txt
REM fpc -O3 -Cr -Fuunits deftype.txt
REM fpc -O3 -Cr -Fuunits defun.txt
REM fpc -O3 -Cr -Fuunits vardef.txt
fpc -O3 -Cr straightjacket.txt
del *.o
del *.ppu