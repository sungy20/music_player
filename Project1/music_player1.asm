.386
.model flat, stdcall
option casemap: none

include need.inc


.code

start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax
    ;invoke InitCommonControls
    invoke DialogBoxParam, hInstance, DIALOG, 0, offset DialogProc, 0  
    ;创建dialog,dialogproc为处理dialog消息的逻辑函数
    invoke ExitProcess, eax

DialogProc proc hWndDlg:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    mov eax, uMsg

    .if eax == WM_INITDIALOG
        invoke LoadIcon,hInstance,temp
        invoke SendMessage,hWndDlg,WM_SETICON,0,eax
    .elseif eax == WM_COMMAND
        mov eax,wParam
        .if eax == CON_PAUSE
            invoke mciSendString,ADDR OPENMP3,NULL,0,NULL
            invoke mciSendString,ADDR PLAYMP3,NULL,0,NULL
        .endif
    .elseif eax == WM_CLOSE
        invoke EndDialog,hWndDlg,0
    .endif

    xor eax,eax
    ret
DialogProc endp

end start
