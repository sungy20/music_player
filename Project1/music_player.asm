.386
.model flat, stdcall
option casemap: none

include need.inc

Asm_Function_1 proto stdcall arg1:dword,arg2:dword

.code

start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax
    ;invoke InitCommonControls
    invoke DialogBoxParam, hInstance, VA_MAIN, 0, offset DialogProc, 0
    invoke ExitProcess, eax

DialogProc proc hWin:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    mov eax, uMsg

    .if eax == WM_INITDIALOG
        invoke LoadIcon,hInstance,200
        invoke SendMessage,hWin,WM_SETICON,1,eax
    .elseif eax == WM_COMMAND
        mov eax,wParam
        .if eax == VA_EXIT
            invoke SendMessage,hWin,WM_CLOSE,0,0
        .elseif eax == VA_PlayButton
            invoke mciSendString,ADDR OPENMP3,NULL,0,NULL
            invoke mciSendString,ADDR PLAYMP3,NULL,0,NULL
        .endif
    .elseif eax == WM_CLOSE
        invoke EndDialog,hWin,0
    .endif

    xor eax,eax
    ret
DialogProc endp

end start
