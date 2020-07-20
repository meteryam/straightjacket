echo off
llc hello.ll
gcc hello.s -o hello -L"C:\gnu\MinGW\lib" -L"C:\gnu\MinGW\lib\gcc\mingw32\4.6.1"
rm hello.s
hello.exe
pause