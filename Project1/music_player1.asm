.386
.model flat, stdcall
option casemap: none

include need.inc


.code

start:
    invoke GetModuleHandle, NULL  ;��ȡ�Ѿ�������̿ռ��ģ����
    mov hInstance, eax  ;eax�����ģ����
    invoke InitCommonControls
    invoke DialogBoxParam, hInstance, DIALOG, 0, offset dialogProc, 0  
    ;����dialog,dialogProcΪ����dialog��Ϣ���߼�����
    invoke ExitProcess, eax

;-------------------------------------------------------------------------------------------------------
; ����dialog��Ϣ���߼�����
; Receives: hWndDlg�Ǵ��ھ��,uMsg��wParam��lParam���ָ�����Ϣ
; Returns: none
;-------------------------------------------------------------------------------------------------------
dialogProc proc hWndDlg:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    mov eax, uMsg  ;���¼���Ϣ����eax

    .if eax == WM_INITDIALOG  ;WM_INITDIALOGΪ��ʼ������
		invoke init, hWndDlg
    .elseif eax == WM_COMMAND  ;WM_COMMANDΪ�ؼ���Ϣ
        mov eax, wParam
		mov ebx, songMenuSize
		.if eax == IDC_IMPORT_BT ;���µ��������
			invoke importSong, hWndDlg
			;mov eax, wParam
			invoke SetCurrentDirectory, ADDR guiWorkingDir;
		.elseif ebx == 0 ;�赥Ϊ��ʱ������Ĳ�����û��˼��
			ret
        .elseif eax == CON_PAUSE  ;��ͣ/���ż�
			invoke playPause,hWndDlg
		.elseif ax == IDC_SONGMENU;���赥
			shr eax,16
			.if ax == LBN_DBLCLK;˫����������
				invoke SendDlgItemMessage, hWndDlg,IDC_SONGMENU,LB_GETCURSEL,0,0
				invoke changeSong,hWndDlg,eax;
			.endif
		.elseif eax == PRE_SONG ;���ǰһ�׸�
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
		.elseif eax == IDC_DELETE_BT ;ɾ��ѡ�и���
			invoke SendDlgItemMessage, hWndDlg,IDC_SONGMENU,LB_GETCURSEL,0,0
			.if eax == -1 ;ûѡ�и���
				ret
			.endif
			invoke deleteSong,hWndDlg,eax;
        .endif
    .elseif eax == WM_CLOSE  ;WM_CLOSEΪ�رմ���
        invoke EndDialog,hWndDlg,0
    .endif
    xor eax,eax  ;���Գ���ע�ͣ�֮��ᷢ������˼���£�����
    ret
dialogProc endp
;-------------------------------------------------------------------------------------------------------
; ������ֲ������߼��ϵĳ�ʼ����������г�ʼ������д����������У�
; Receives: hWndDlg�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
init proc hWndDlg:DWORD
	invoke LoadIcon,hInstance,IDI_ERROR
    invoke SendMessage,hWndDlg,WM_SETICON,0,eax
	;��ȡ������Ŀ¼
	invoke GetCurrentDirectory,200, addr guiWorkingDir  ;������ǰ���̵ĵ�ǰĿ¼��
	;invoke MessageBox,hWndDlg, addr guiWorkingDir, addr guiWorkingDir, MB_OK  ;����һ���Ի������ڼ��guiworkingdir
	
	;չʾ�赥�е����и���
	mov esi, offset songMenu
	mov ecx, songMenuSize
	.IF ecx > 0
		L1:
			push ecx
			invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_ADDSTRING, 0, ADDR (Song PTR [esi])._name  
			;��hwnddlg�е�songmenu�ؼ�������Ϣ,LB_ADDSTRING��Ϣ��ʾΪmenuĩβ���song.name
			add esi, TYPE songMenu
			pop ecx
		loop L1
	.ENDIF
	invoke SendDlgItemMessage,hWndDlg, IDC_SONGMENU, LB_SETCURSEL, 0, 0 ;���б�ѡ�����õ���һ�׸���
	ret
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
		invoke mciSendString, ADDR commandPauseSong, NULL, 0, NULL;��ͣ����	
		;invoke EndDialog,hWndDlg,0
		
	.elseif currentStatus == 2;����ǰ״̬Ϊ��ͣ״̬
		mov currentStatus, 1;תΪ����״̬
		invoke openSong,hWndDlg, currentSongIndex;�򿪸���
		invoke mciSendString,ADDR commandPlaySong,NULL,0,NULL;���Ÿ���
		;invoke mciSendString, ADDR commandResumeSong, NULL, 0, NULL;�ָ���������
	.endif
	ret
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
	mov openfilename.lStructSize, SIZEOF openfilename ;ָ���ṹ��Ĵ�С��һ����SIZEOF����
	mov eax, hWndDlg
	mov openfilename.hwndOwner, eax ;ָ���ṹ��ĸ�����
	mov eax, OFN_ALLOWMULTISELECT  ;ѡ�����ļ�
	or eax, OFN_EXPLORER
	mov openfilename.Flags, eax
	mov openfilename.nMaxFile, nMaxFile  ;ָ���ļ�����С
	mov openfilename.lpstrTitle, OFFSET szLoadTitle  ;�Ի���ı���
	mov openfilename.lpstrInitialDir, OFFSET szInitDir  ;��ʱ�ĳ�ʼĿ¼
	mov openfilename.lpstrFile, OFFSET szOpenFileNames  ;�ļ���
	invoke GetOpenFileName, ADDR openfilename
	.IF eax == 1  ;ѡ���ļ��ɹ�
		;invoke crt_printf, offset printstr, openfilename.lpstrFile
		invoke lstrcpyn, ADDR szPath, ADDR szOpenFileNames, openfilename.nFileOffset ;���ڶ����������Ƶ���һ������������Ϊ����������
		invoke lstrlen, ADDR szPath ;���س���
		mov nLen, eax ;eax��ֵ���ǳ���
		mov ebx, eax
		mov al, szPath[ebx]
		.IF al != sep  ;sep��need.inc��
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
		mov ax, openfilename.nFileOffset ;nfileoffsetָʾ�ļ�����ʼ��λ��
		add esi, eax
		mov al, [esi]
		.WHILE al != 0  ;�ò���Ϊ����songmenu
			mov szFileName, 0
			invoke lstrcat, ADDR szFileName, ADDR szPath
			invoke lstrcat, ADDR szFileName, esi
			mov edi, curOffset
			add curOffset, SIZEOF Song
			invoke lstrcpy, edi, esi  ;song._name
			add edi, 100
			invoke lstrcpy, edi, ADDR szFileName  ;song._path
			invoke lstrlen, esi
			inc eax
			add esi, eax
			add songMenuSize, 1
			mov al, [esi]
		.ENDW
		mov esi, originOffset
		mov ecx, songMenuSize
		sub ecx, curSize  ;ecx����ӵ����ӵĸ���
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
	invoke mciSendString, ADDR commandCloseSong, NULL, 0, NULL;�ر�֮ǰ�ĸ���
	;���µ�ǰ��������Ϣ
	mov eax, newSongIndex
	mov currentSongIndex, eax
	mov currentStatus, 1;תΪ����״̬
	invoke openSong,hWndDlg, currentSongIndex;���µĸ���
	invoke mciSendString, ADDR commandPlaySong, NULL, 0, NULL;���Ÿ���
	
	ret
changeSong endp

;-------------------------------------------------------------------------------------------------------
; ��ĳ�׸�
; Receives: index�Ǹ����ڸ赥���±ꣻ
; Requires: currentStatus == 0 ����ǰ״̬������ֹͣ״̬
; Returns: none
;-------------------------------------------------------------------------------------------------------
openSong proc hWndDlg:DWORD, index:DWORD
	LOCAL asd:DWORD;������
	;���Ҹ���ͬ��Ŀ¼����û����֮ͬ����lrc�ļ���������ļ�
	;invoke readLrcFile, hWndDlg, index
	mov eax, index
	mov ebx, TYPE songMenu
	mul ebx;��ʱeax�д洢�˵�index�׸��������songMenu��ƫ�Ƶ�ַ
	mov asd, eax ;������
	invoke crt_printf, ADDR OPENMP3, ADDR songMenu[eax]._path ;������
	mov eax, asd ;������
	invoke wsprintf, ADDR mediaCommand, ADDR OPENMP3, ADDR songMenu[eax]._path
	invoke mciSendString, ADDR mediaCommand, NULL, 0, NULL;�򿪸���

	ret
openSong endp

;-------------------------------------------------------------------------------------------------------
; ɾ����Ӧindex�ĸ�
; Receives: index�Ǹ����ڸ赥���±ꣻ
; Returns: none
;-------------------------------------------------------------------------------------------------------
deleteSong proc hWndDlg:DWORD, index:DWORD
	LOCAL nextadd :DWORD ;��һ�׸�ĵ�ַ
	mov eax, currentSongIndex
	inc eax
	.if eax == songMenuSize
		mov currentSongIndex, 0
	.endif
	dec eax
	.if eax == index
		invoke mciSendString, ADDR commandCloseSong, NULL, 0, NULL; ����ɾ���������ڲ���
		mov currentStatus, 0 ;����ǰ״̬����Ϊֹͣ
	.endif

	mov esi, OFFSET songMenu
	mov eax, index
	mov ebx, SIZEOF Song
	mul ebx
	add esi, eax ;����Ҫɾ�����λ��
	mov nextadd, esi
	add nextadd, SIZEOF Song
	mov edi, nextadd ;��һ�׸��λ��
	mov ecx, songMenuSize
	dec ecx
	.IF ecx > index
		L1:
			push ecx
			invoke lstrcpy, esi, edi  ;song._name
			add edi, 100
			add esi, 100
			invoke lstrcpy, esi, edi  ;song._path
			add esi, 100
			add edi, 100
			pop ecx
		loop L1
	.ENDIF
	invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_DELETESTRING, index, 0
	sub songMenuSize, 1 
	ret
deleteSong endp

end start
