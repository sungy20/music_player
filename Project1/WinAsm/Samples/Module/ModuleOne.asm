.386
.MODEL FLAT, STDCALL
OPTION CASEMAP:NONE

OPTION PROC:PRIVATE	;<-----All Procedures of these modules are private unless otherwise stated

Include windows.inc
Include user32.inc

.DATA

szModule		DB "ModuleOne",0
szTextPublic	DB "This message is from within a public procedure of ModuleOne.",0
szTextPrivate	DB "This message is from within a private procedure of ModuleOne.",0
.CODE


; This Procedure is private, so any Other module can use the same name for a procedure 
TestProc Proc hWnd:HWND
	Invoke MessageBox,hWnd,ADDR szTextPrivate,ADDR szModule,MB_OK
	RET
TestProc EndP


; This Procedure is public, so you can call it from any module
ModuleOne Proc PUBLIC hWnd:HWND
	
	Invoke MessageBox,hWnd,ADDR szTextPublic,ADDR szModule,MB_OK
	Invoke TestProc,hWnd
	RET

ModuleOne EndP

End