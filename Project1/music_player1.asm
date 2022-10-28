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
	.elseif eax == WM_TIMER  ;WM_TIMERΪ��ʱ����Ϣ
		.if currentStatus == 1;�����ǰ���ڲ��Ÿ���
			invoke changeProgressBar, hWndDlg;���Ľ���������λ��
			invoke repeatMode, hWndDlg  ;����ѭ��ģʽ������һ�׸�
		.endif
	.elseif eax == WM_HSCROLL  ;WM_HSCROLLΪ������Ϣ
		invoke GetDlgCtrlID,lParam
			mov curSlider,eax
			mov ax,WORD PTR wParam;��Ϣ���
			.if curSlider == IDC_VOLUME_SLIDER;��������
				.if ax == SB_THUMBTRACK;������Ϣ
					invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_GETCURSEL, 0, 0;��ȡ��ѡ�е��±�
					.if eax != -1;��ǰ�и�����ѡ�У����������������
						invoke changeVolume,hWndDlg
					.endif
				.elseif ax == SB_ENDSCROLL;����������Ϣ
					invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_GETCURSEL, 0, 0;��ȡ��ѡ�е��±�
					.if eax != -1;
						invoke changeVolume,hWndDlg
					.endif
				.endif
			.elseif curSlider == IDC_PROGRESS_BAR;���ڽ���
				.if ax == SB_ENDSCROLL;����������Ϣ
					mov ProgressBarDragging, 0
					invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_GETCURSEL, 0, 0;���ȡ��ѡ�е��±�
					.if eax != -1;��ǰ�и�����ѡ�У����������
						invoke changeTime, hWndDlg
					.endif
				.elseif ax == SB_THUMBTRACK;������Ϣ
					mov ProgressBarDragging, 1
				.endif
			.endif
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
		.elseif eax == IDC_VOLUME_BT ;������
			invoke silenceSwitch,hWndDlg
		.elseif ax == IDC_SONGMENU;���赥
			shr eax,16
			.if ax == LBN_SELCHANGE;ѡ������ı�
				invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_GETCURSEL, 0, 0;���ȡ��ѡ�е��±�
				mov currentSongIndex, eax
				mov currentStatus, 0; ����ǰ״̬��Ϊֹͣ�����㲥�Ÿı����
			.elseif ax == LBN_DBLCLK;˫����������
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
        .elseif eax == IDC_VOLUME_BT ;������ť@hemu,�����л�������ʵ�ֿ�
			.if hasSound == 1
				mov hasSound, 0
			.else
				mov hasSound, 1
			.endif
		.elseif eax == IDC_RECYLE_BT
			.if recyleWay == 0
				mov recyleWay, 1
			.elseif recyleWay == 1
				mov recyleWay, 2
			.else 
				mov recyleWay, 0
			.endif
			invoke changeRecyleButton,hWndDlg,recyleWay
        .endif
    .elseif eax == WM_CLOSE  ;WM_CLOSEΪ�رմ���
		invoke saveFile, hWndDlg
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
	
	invoke loadFile, hWndDlg
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

	;��ʼ�����Ű�ťΪ��ͣ״̬
	invoke changePlayButton,hWndDlg, 0
	invoke changeSilenceButton,hWndDlg, 1
	invoke changeRecyleButton,hWndDlg, recyleWay

	;����ͼ��
	mov eax, 113
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWndDlg,PRE_SONG, BM_SETIMAGE, IMAGE_ICON, eax;�޸İ�ť
	mov eax, 115
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWndDlg,NEXT_SONG, BM_SETIMAGE, IMAGE_ICON, eax;�޸İ�ť

	;��ʼ��������,���Χ��sliderLength��ֵĬ��Ϊ���ֵ
	invoke SendDlgItemMessage, hWndDlg, IDC_VOLUME_SLIDER, TBM_SETRANGEMIN, 0, 0
	invoke SendDlgItemMessage, hWndDlg, IDC_VOLUME_SLIDER, TBM_SETRANGEMAX, 0, sliderLength
	invoke SendDlgItemMessage, hWndDlg, IDC_VOLUME_SLIDER, TBM_SETPOS, 1, sliderLength

	;���ü�ʱ����ÿ0.5s����һ�ζ�ʱ����Ϣ
	invoke SetTimer, hWndDlg, 1, 500, NULL

	ret
init endp

;-------------------------------------------------------------------------------------------------------
;���ڿ⺯��ȱʧ������ֱ��ʹ��win32API��StrToInt��Դ��
;-------------------------------------------------------------------------------------------------------
StrToInt proc uses esi lpszStr
  xor esi,esi
  xor eax,eax
@@:
  mov ecx,lpszStr
  movzx ecx,Byte ptr [ecx+esi]
  test cl,cl
  jz @f
  .if ((cl >= '0') && (cl <= '9'))
    sub cl,'0'
    lea eax,[eax+eax*4]
    lea eax,[ecx+eax*2]
    inc esi
    jmp @b
  .else
    xor eax,eax
    ret
  .endif
@@:
  ret
StrToInt endp

;-------------------------------------------------------------------------------------------------------
; �������/��ͣ��ťʱ��Ӧ
; Receives: hWndDlg�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
playPause proc hWndDlg:DWORD
	.if currentStatus == 0;����ǰ״̬Ϊֹͣ״̬
		mov currentStatus, 1;תΪ����״̬
		invoke changePlayButton,hWndDlg, 1
		;invoke mciSendString, ADDR OPENMP3, NULL, 0, NULL;�򿪸���
		invoke mciSendString, ADDR commandCloseSong, NULL, 0, NULL ;�赥��ĳ����������ʱ���л���һ�׸貢�ҵ�����ţ���Ҫֹ֮ͣǰ�ĸ���
		invoke openSong,hWndDlg, currentSongIndex;�򿪸���
		invoke mciSendString,ADDR commandPlaySong,NULL,0,NULL;���Ÿ���

		invoke mciSendString, addr commandGetLength, addr songLength, 32, NULL;��ȡ��������
		invoke StrToInt, addr songLength
		invoke SendDlgItemMessage, hWndDlg, IDC_PROGRESS_BAR, TBM_SETRANGEMAX, 0, eax;�ѽ������ĳɸ���������һ����
		;invoke EndDialog,hWndDlg,0
		invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_GETCURSEL, 0, 0;��ȡ��ѡ�е��±�
		.if eax != -1;��ǰ�и�����ѡ�У����������������
			invoke changeVolume,hWndDlg
		.endif

	.elseif currentStatus == 1;����ǰ״̬Ϊ����״̬
		mov currentStatus, 2;תΪ��ͣ״̬
		invoke changePlayButton,hWndDlg, 0
		invoke mciSendString, ADDR commandPauseSong, NULL, 0, NULL;��ͣ����	
		;invoke EndDialog,hWndDlg,0
		
	.elseif currentStatus == 2;����ǰ״̬Ϊ��ͣ״̬
		mov currentStatus, 1;תΪ����״̬
		invoke changePlayButton,hWndDlg, 1
		invoke openSong,hWndDlg, currentSongIndex;�򿪸���
		invoke mciSendString,ADDR commandPlaySong,NULL,0,NULL;���Ÿ���
		;invoke mciSendString, ADDR commandResumeSong, NULL, 0, NULL;�ָ���������
		invoke changeVolume,hWndDlg
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
	invoke changePlayButton,hWndDlg, 1
	invoke mciSendString, ADDR commandCloseSong, NULL, 0, NULL;�ر�֮ǰ�ĸ���
	;���µ�ǰ��������Ϣ
	mov eax, newSongIndex
	mov currentSongIndex, eax
	mov currentStatus, 1;תΪ����״̬
	invoke openSong,hWndDlg, currentSongIndex;���µĸ���
	invoke mciSendString, ADDR commandPlaySong, NULL, 0, NULL;���Ÿ���

	invoke mciSendString, addr commandGetLength, addr songLength, 32, NULL;��ȡ��������
	invoke StrToInt, addr songLength
	invoke SendDlgItemMessage, hWndDlg, IDC_PROGRESS_BAR, TBM_SETRANGEMAX, 0, eax;�ѽ������ĳɸ���������һ����
	
	invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_GETCURSEL, 0, 0;��ȡ��ѡ�е��±�
	.if eax != -1;��ǰ�и�����ѡ�У����������������
		invoke changeVolume,hWndDlg
	.endif
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

;-------------------------------------------------------------------------------------------------------
; ��ȡ�����ļ��еĸ赥��Ϣ
; Receives: hWndDlg
; Returns: none
;-------------------------------------------------------------------------------------------------------
loadFile proc hWndDlg:DWORD
	LOCAL songFile: DWORD
	LOCAL bytesRead: DWORD
	invoke CreateFile, addr songFileName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL 
	mov songFile, eax
	.if songFile == INVALID_HANDLE_VALUE
		mov songMenuSize, 0
	.else
		invoke ReadFile, songFile, addr songMenuSize, SIZEOF songMenuSize, addr bytesRead, NULL
		.if bytesRead != SIZEOF songMenuSize
			mov songMenuSize, 0
		.else
			;mov ebx, songMenuSize
			;mov eax, SIZEOF Song
			;mul eax
			invoke ReadFile, songFile, addr songMenu, SIZEOF songMenu, ADDR bytesRead, NULL
			.IF bytesRead != SIZEOF songMenu
				mov songMenuSize, 0
			.ENDIF
		.ENDIF
	.ENDIF
	INVOKE CloseHandle, songFile

	ret
loadFile endp

;-------------------------------------------------------------------------------------------------------
; �����˳�ǰ�ĸ赥��Ϣ
; Receives: hWndDlg
; Returns: none
;-------------------------------------------------------------------------------------------------------
saveFile proc hWndDlg:DWORD
	LOCAL songFile: DWORD
	LOCAL bytesWritten: DWORD
	INVOKE CreateFile, ADDR songFileName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	mov songFile, eax
	.IF songFile == INVALID_HANDLE_VALUE
		ret
	.ENDIF
	INVOKE WriteFile, songFile, ADDR songMenuSize, SIZEOF songMenuSize, ADDR bytesWritten, NULL
	INVOKE WriteFile, songFile, ADDR songMenu, SIZEOF songMenu, ADDR bytesWritten, NULL
	INVOKE CloseHandle, songFile
	ret
saveFile endp

;-------------------------------------------------------------------------------------------------------
; �ı����������С
; Receives: hWndDlg
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeVolume proc hWndDlg:DWORD
	invoke SendDlgItemMessage,hWndDlg,IDC_VOLUME_SLIDER,TBM_GETPOS,0,0;��ȡ�α���ֵ
	.if hasSound == 1
		invoke wsprintf, addr mediaCommand, addr commandVolumeChange, eax
		invoke changeSilenceButton, hWndDlg, 1
	.else
		invoke wsprintf, addr mediaCommand, addr commandVolumeChange, 0
		invoke changeSilenceButton, hWndDlg, 0
	.endif
	invoke mciSendString, addr mediaCommand, NULL, 0, NULL
	ret
changeVolume endp

;-------------------------------------------------------------------------------------------------------
; ���ݲ��Ž��ȸı������
; Receives: hWndDlg
; Returns: none
;-------------------------------------------------------------------------------------------------------

changeProgressBar proc hWndDlg: DWORD
	local temp2: DWORD
	.if currentStatus == 1;����ǰΪ����״̬
		invoke mciSendString, addr commandGetProgress, addr songProgress, 32, NULL;��ȡ��ǰ����λ��
		invoke StrToInt, addr songProgress;��ǰ����ת��int����eax��
		mov temp2, eax
		.if ProgressBarDragging == 0;����ǰ�û�û����ʱ������ô���½�����λ��
			invoke SendDlgItemMessage, hWndDlg, IDC_PROGRESS_BAR, TBM_SETPOS, 1, temp2
		.endif
	.endif
	Ret
changeProgressBar endp

;-------------------------------------------------------------------------------------------------------
; ���ݽ������ı䲥�Ž���
; Receives: hWndDlg
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeTime proc hWndDlg: DWORD
	invoke SendDlgItemMessage,hWndDlg,IDC_PROGRESS_BAR,TBM_GETPOS,0,0;��ȡ��ǰSlider�α�λ��
	invoke wsprintf, addr mediaCommand, addr commandSetProgress, eax
	invoke mciSendString, addr mediaCommand, NULL, 0, NULL
	.if currentStatus == 1;
		invoke mciSendString, addr commandPlaySong, NULL, 0, NULL
	.elseif currentStatus == 2;
		invoke mciSendString, addr commandPlaySong, NULL, 0, NULL
		mov currentStatus, 1;����϶�����������ͣתΪ����
	.endif
	Ret
changeTime endp

;-------------------------------------------------------------------------------------------------------
; �ı䲥�Ű�ť
; Receives: hWndDlg�Ǵ��ھ����playing=1��ʾ���������ţ�=0��ʾ������������
; Returns: none
;-------------------------------------------------------------------------------------------------------
changePlayButton proc hWndDlg:DWORD, playing:BYTE
	.if playing == 0;ת����ͣ״̬
		mov eax, 116
	.else;ת������״̬
		mov eax, 117
	.endif
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWndDlg,CON_PAUSE, BM_SETIMAGE, IMAGE_ICON, eax;�޸İ�ť
	Ret
changePlayButton endp

;-------------------------------------------------------------------------------------------------------
; ˢ�¾�����ť����ͼ��ʾ
; Receives: hWndDlg�Ǵ��ھ����_hasSound=1��ʾ��������������=0��ʾ������û������
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeSilenceButton proc hWndDlg:DWORD, _hasSound:BYTE
	.if _hasSound == 0;ת����ͣ״̬
		mov eax, close_sound
	.else;ת������״̬
		mov eax, open_sound
	.endif
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWndDlg,IDC_VOLUME_BT, BM_SETIMAGE, IMAGE_ICON, eax;�޸İ�ť
	Ret
changeSilenceButton endp

;-------------------------------------------------------------------------------------------------------
; ˢ�²��ŷ�ʽ��ť����ͼ��ʾ
; Receives: hWndDlg�Ǵ��ھ����_hasSound=0��ʾ�����=1��ʾ����ѭ��,=2��ʾ�б�ѭ��,
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeRecyleButton proc hWndDlg:DWORD, _hasSound:WORD
	.if _hasSound == 0;���
		mov eax, random
	.elseif _hasSound == 1;����ѭ��
		mov eax, loop1
	.else
		mov eax, recyle
	.endif
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWndDlg,IDC_RECYLE_BT, BM_SETIMAGE, IMAGE_ICON, eax;�޸İ�ť
	Ret
changeRecyleButton endp

;-------------------------------------------------------------------------------------------------------
; ����ѭ��ģʽ������һ�׸�
; Receives: hWndDlg�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
repeatMode proc hWndDlg:DWORD
	LOCAL temp:DWORD
	.if currentStatus == 1  ;��ǰ״̬Ϊ����
		invoke StrToInt, addr songLength
		mov temp, eax
		invoke StrToInt, addr songProgress
		.if eax >= temp;��������
			.if recyleWay == 1;����ѭ��
				invoke mciSendString, addr commandSetStart, NULL, 0, NULL;��λ��������ͷ
				invoke mciSendString, addr commandPlaySong, NULL, 0, NULL
			.elseif recyleWay == 2;�б�ѭ��
				invoke SendMessage, hWndDlg, WM_COMMAND, NEXT_SONG, 0;������Ϣ��ģ������"��һ��"��ť
			.endif
		.endif
	.endif
	ret
repeatMode endp

;-------------------------------------------------------------------------------------------------------
; ���������ť
; Receives: hWndDlg�Ǵ��ھ��
; Returns: none
;-------------------------------------------------------------------------------------------------------
silenceSwitch proc hWndDlg:DWORD
	mov al, hasSound
	not al
	mov hasSound, al
	invoke changeVolume,hWndDlg
	ret
silenceSwitch endp

end start
