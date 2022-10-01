include     windows.inc
include     user32.inc
include     kernel32.inc
include     comctl32.inc
include     winmm.inc

includelib  kernel32.lib
includelib  user32.lib
includelib  winmm.lib
includelib  comctl32.lib

DialogProc proto arg1:dword,arg2:dword,arg3:dword,arg4:dword

.const

PRE_SONG		EQU 1004
CON_PAUSE		EQU 1005
NEXT_SONG		EQU 1006
DIALOG		    EQU 1001
temp		    EQU 1000

.data

FileName BYTE "trans.mp3",0
OPENMP3  BYTE "open src\\trans.mp3 alias cursong",0
PLAYMP3  BYTE "play cursong repeat",0

.data?
hInstance dword ?
