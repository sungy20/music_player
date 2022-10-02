.386
.model flat, stdcall
option casemap: none

include need.inc


.code

start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax
    invoke InitCommonControls
    invoke DialogBoxParam, hInstance, DIALOG, 0, offset dialogProc, 0  
    ;����dialog,dialogProcΪ����dialog��Ϣ���߼�����
    invoke ExitProcess, eax

dialogProc proc hWndDlg:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    mov eax, uMsg

    .if eax == WM_INITDIALOG
		invoke init, hWndDlg
        invoke LoadIcon,hInstance,temp
        invoke SendMessage,hWndDlg,WM_SETICON,0,eax
    .elseif eax == WM_COMMAND
        mov eax,wParam
        .if eax == CON_PAUSE
			invoke playPause,hWndDlg
		.elseif eax == IDC_IMPORT_BT;���µ��������
			invoke importSong, hWndDlg
			mov eax, wParam
		.elseif ax == IDC_SONGMENU;���赥
			shr eax,16
			.if ax == LBN_SELCHANGE;ѡ������ı�
				invoke SendDlgItemMessage, hWndDlg,IDC_SONGMENU,LB_GETCURSEL,0,0
				invoke changeSong,hWndDlg,eax;
			.endif
		.elseif eax == PRE_SONG
			.if currentSongIndex == 0
				mov eax, songMenuSize
				mov currentSongIndex,eax
			.endif
			dec currentSongIndex
			invoke SendDlgItemMessage,hWndDlg, IDC_SONGMENU, LB_SETCURSEL, currentSongIndex, 0;�ı�ѡ����
			invoke changeSong,hWndDlg,currentSongIndex;���Ÿ��׸���
		.elseif eax == NEXT_SONG;�������һ�׸�
			inc currentSongIndex
			mov eax, currentSongIndex
			.if eax == songMenuSize
				mov currentSongIndex,0
			.endif
			invoke SendDlgItemMessage,hWndDlg, IDC_SONGMENU, LB_SETCURSEL, currentSongIndex, 0;�ı�ѡ����
			invoke changeSong,hWndDlg,currentSongIndex;���Ÿ��׸���
        .endif
    .elseif eax == WM_CLOSE
        invoke EndDialog,hWndDlg,0
    .endif

    xor eax,eax
    ret
dialogProc endp
;-------------------------------------------------------------------------------------------------------
; ������ֲ������߼��ϵĳ�ʼ����������г�ʼ������д����������У�
; Receives: hWndDlg�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
init proc hWndDlg:DWORD
	;��ȡ������Ŀ¼
	invoke GetCurrentDirectory,200, addr guiWorkingDir
	;invoke MessageBox,hWndDlg, addr guiWorkingDir, addr guiWorkingDir, MB_OK
	
	;չʾ�赥�е����и���
	mov esi, offset songMenu
	mov ecx, songMenuSize
	.IF ecx > 0
		L1:
			push ecx
			invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_ADDSTRING, 0, ADDR (Song PTR [esi])._name
			add esi, TYPE songMenu
			pop ecx
		loop L1
	.ENDIF
	
	Ret
init endp

;-------------------------------------------------------------------------------------------------------
; �������/��ͣ��ťʱ��Ӧ
; Receives: hWndDlg�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
playPause proc hWndDlg:DWORD
	.if currentStatus == 0;����ǰ״̬Ϊֹͣ״̬
		mov currentStatus, 1;תΪ����״̬
		;invoke mciSendString, ADDR OPENMP3, NULL, 0, NULL;�򿪸���
		invoke openSong,hWndDlg, currentSongIndex;�򿪸���
		invoke mciSendString,ADDR commandPlaySong,NULL,0,NULL;���Ÿ���
		;invoke EndDialog,hWndDlg,0

	.elseif currentStatus == 1;����ǰ״̬Ϊ����״̬
		mov currentStatus, 2;תΪ��ͣ״̬
		invoke mciSendString, ADDR closeSongCommand, NULL, 0, NULL;��ͣ����	
		;invoke EndDialog,hWndDlg,0
		
	.elseif currentStatus == 2;����ǰ״̬Ϊ��ͣ״̬
		mov currentStatus, 1;תΪ����״̬
		invoke openSong,hWndDlg, currentSongIndex;�򿪸���
		invoke mciSendString,ADDR commandPlaySong,NULL,0,NULL;���Ÿ���
		;invoke mciSendString, ADDR commandResumeSong, NULL, 0, NULL;�ָ���������
	.endif
	Ret
playPause endp

;-------------------------------------------------------------------------------------------------------
; �����µĸ���
; hWndDlg�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
importSong proc uses eax ebx esi edi hWndDlg:DWORD
	LOCAL nLen: DWORD
	LOCAL curOffset: DWORD
	LOCAL originOffset: DWORD
	LOCAL curSize: DWORD
	mov al,0
	mov edi, OFFSET openfilename
	mov ecx, SIZEOF openfilename
	cld
	rep stosb
	mov openfilename.lStructSize, SIZEOF openfilename
	mov eax, hWndDlg
	mov openfilename.hwndOwner, eax
	mov eax, OFN_ALLOWMULTISELECT
	or eax, OFN_EXPLORER
	mov openfilename.Flags, eax
	mov openfilename.nMaxFile, nMaxFile
	mov openfilename.lpstrTitle, OFFSET szLoadTitle
	mov openfilename.lpstrInitialDir, OFFSET szInitDir
	mov openfilename.lpstrFile, OFFSET szOpenFileNames
	invoke GetOpenFileName, ADDR openfilename
	.IF eax == 1
		invoke lstrcpyn, ADDR szPath, ADDR szOpenFileNames, openfilename.nFileOffset
		invoke lstrlen, ADDR szPath
		mov nLen, eax
		mov ebx, eax
		mov al, szPath[ebx]
		.IF al != sep
			mov al, sep
			mov szPath[ebx], al
			mov szPath[ebx + 1], 0
		.ENDIF
		mov ebx, songMenuSize
		mov curSize, ebx
		mov edi, OFFSET songMenu
		mov eax, SIZEOF Song
		mul ebx
		add edi, eax
		mov curOffset, edi
		mov originOffset, edi
		mov esi, OFFSET szOpenFileNames
		mov eax, 0
		mov ax, openfilename.nFileOffset
		add esi, eax
		mov al, [esi]
		.WHILE al != 0
			mov szFileName, 0
			invoke lstrcat, ADDR szFileName, ADDR szPath
			invoke lstrcat, ADDR szFileName, esi
			mov edi, curOffset
			add curOffset, SIZEOF Song
			invoke lstrcpy, edi, esi
			add edi, 100
			invoke lstrcpy, edi, ADDR szFileName
			invoke lstrlen, esi
			inc eax
			add esi, eax
			add songMenuSize, 1
			mov al, [esi]
		.ENDW
		mov esi, originOffset
		mov ecx, songMenuSize
		sub ecx, curSize
		.IF ecx > 0
			L1:
				push ecx
				invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_ADDSTRING, 0, ADDR (Song PTR [esi])._name
				add esi, TYPE songMenu
				pop ecx
			loop L1
		.ENDIF
	.ENDIF
	ret
importSong endp

;-------------------------------------------------------------------------------------------------------
; �л�����ʱ��Ӧ
; Receives: hWndDlg�Ǵ��ھ��,newSongIndex���µĸ�����songMenu�е��±�
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeSong proc hWndDlg:DWORD, newSongIndex: DWORD
	invoke mciSendString, ADDR closeSongCommand, NULL, 0, NULL;�ر�֮ǰ�ĸ���
	;invoke closeSong,hWndDlg;�ر�֮ǰ�ĸ���
	;���µ�ǰ��������Ϣ
	mov eax, newSongIndex
	mov currentSongIndex, eax
	mov currentStatus, 1;תΪ����״̬
	invoke openSong,hWndDlg, currentSongIndex;���µĸ���
	invoke mciSendString, ADDR commandPlaySong, NULL, 0, NULL;���Ÿ���
	
	Ret
changeSong endp

;-------------------------------------------------------------------------------------------------------
; ��ĳ�׸�
; Receives: index�Ǹ����ڸ赥���±ꣻ
; Requires: currentStatus == 0 ����ǰ״̬������ֹͣ״̬
; Returns: none
;-------------------------------------------------------------------------------------------------------
openSong proc hWndDlg:DWORD, index:DWORD
	;���Ҹ���ͬ��Ŀ¼����û����֮ͬ����lrc�ļ�
	;invoke readLrcFile, hWndDlg, index
	mov eax, index
	mov ebx, TYPE songMenu
	mul ebx;��ʱeax�д洢�˵�index�׸��������songMenu��ƫ�Ƶ�ַ
	
	invoke wsprintf, ADDR mediaCommand, ADDR OPENMP3, ADDR songMenu[eax]._path
	invoke mciSendString, ADDR mediaCommand, NULL, 0, NULL;�򿪸���

	Ret
openSong endp

end start
