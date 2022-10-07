.386
.model flat, stdcall
option casemap: none

include need.inc


.code

start:
    invoke GetModuleHandle, NULL  ;获取已经载入进程空间的模块句柄
    mov hInstance, eax  ;eax获得了模块句柄
    invoke InitCommonControls
    invoke DialogBoxParam, hInstance, DIALOG, 0, offset dialogProc, 0  
    ;创建dialog,dialogProc为处理dialog消息的逻辑函数
    invoke ExitProcess, eax

dialogProc proc hWndDlg:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    mov eax, uMsg  ;将事件信息存入eax

    .if eax == WM_INITDIALOG  ;WM_INITDIALOG为初始化窗口
		invoke init, hWndDlg
    .elseif eax == WM_COMMAND  ;WM_COMMAND为控件信息
        mov eax,wParam
        .if eax == CON_PAUSE  ;暂停/播放键
			invoke playPause,hWndDlg
		.elseif eax == IDC_IMPORT_BT ;按下导入歌曲键
			invoke importSong, hWndDlg
			;mov eax, wParam
			invoke SetCurrentDirectory, ADDR guiWorkingDir;
		.elseif eax == IDC_SONGMENU;若歌单
			shr eax,16
			.if eax == LBN_SELCHANGE;选中项发生改变
				invoke SendDlgItemMessage, hWndDlg,IDC_SONGMENU,LB_GETCURSEL,0,0
				invoke changeSong,hWndDlg,eax;
			.endif
		.elseif eax == PRE_SONG ;点击前一首歌
			.if currentSongIndex == 0
				mov eax, songMenuSize
				mov currentSongIndex,eax
			.endif
			dec currentSongIndex
			invoke SendDlgItemMessage,hWndDlg, IDC_SONGMENU, LB_SETCURSEL, currentSongIndex, 0;改变选中项
			invoke changeSong,hWndDlg,currentSongIndex;播放该首歌曲
		.elseif eax == NEXT_SONG;若点击下一首歌
			inc currentSongIndex
			mov eax, currentSongIndex
			.if eax == songMenuSize
				mov currentSongIndex,0
			.endif
			invoke SendDlgItemMessage,hWndDlg, IDC_SONGMENU, LB_SETCURSEL, currentSongIndex, 0;改变选中项
			invoke changeSong,hWndDlg,currentSongIndex;播放该首歌曲
        .endif
    .elseif eax == WM_CLOSE  ;WM_CLOSE为关闭窗口
        invoke EndDialog,hWndDlg,0
    .endif
    xor eax,eax
    ret
dialogProc endp
;-------------------------------------------------------------------------------------------------------
; 完成音乐播放器逻辑上的初始化（请把所有初始化工作写在这个函数中）
; Receives: hWndDlg是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
init proc hWndDlg:DWORD
	invoke LoadIcon,hInstance,IDI_ERROR
    invoke SendMessage,hWndDlg,WM_SETICON,0,eax
	;获取程序工作目录
	invoke GetCurrentDirectory,200, addr guiWorkingDir  ;检索当前进程的当前目录。
	;invoke MessageBox,hWndDlg, addr guiWorkingDir, addr guiWorkingDir, MB_OK  ;弹出一个对话框，用于检查guiworkingdir
	
	;展示歌单中的所有歌曲
	mov esi, offset songMenu
	mov ecx, songMenuSize
	.IF ecx > 0
		L1:
			push ecx
			invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_ADDSTRING, 0, ADDR (Song PTR [esi])._name  
			;向hwnddlg中的songmenu控件发送消息,LB_ADDSTRING信息表示为menu末尾添加song.name
			add esi, TYPE songMenu
			pop ecx
		loop L1
	.ENDIF
	
	Ret
init endp

;-------------------------------------------------------------------------------------------------------
; 点击播放/暂停按钮时响应
; Receives: hWndDlg是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
playPause proc hWndDlg:DWORD
	.if currentStatus == 0;若当前状态为停止状态
		mov currentStatus, 1;转为播放状态
		;invoke mciSendString, ADDR OPENMP3, NULL, 0, NULL;打开歌曲
		invoke openSong,hWndDlg, currentSongIndex;打开歌曲
		invoke mciSendString,ADDR commandPlaySong,NULL,0,NULL;播放歌曲
		;invoke EndDialog,hWndDlg,0

	.elseif currentStatus == 1;若当前状态为播放状态
		mov currentStatus, 2;转为暂停状态
		invoke mciSendString, ADDR commandPauseSong, NULL, 0, NULL;暂停歌曲	
		;invoke EndDialog,hWndDlg,0
		
	.elseif currentStatus == 2;若当前状态为暂停状态
		mov currentStatus, 1;转为播放状态
		invoke openSong,hWndDlg, currentSongIndex;打开歌曲
		invoke mciSendString,ADDR commandPlaySong,NULL,0,NULL;播放歌曲
		;invoke mciSendString, ADDR commandResumeSong, NULL, 0, NULL;恢复歌曲播放
	.endif
	Ret
playPause endp

;-------------------------------------------------------------------------------------------------------
; 导入新的歌曲
; hWndDlg是窗口句柄；
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
	mov openfilename.lStructSize, SIZEOF openfilename ;指定结构体的大小，一般用SIZEOF即可
	mov eax, hWndDlg
	mov openfilename.hwndOwner, eax ;指定结构体的父窗口
	mov eax, OFN_ALLOWMULTISELECT  ;选择多个文件
	or eax, OFN_EXPLORER
	mov openfilename.Flags, eax
	mov openfilename.nMaxFile, nMaxFile  ;指定文件名大小
	mov openfilename.lpstrTitle, OFFSET szLoadTitle  ;对话框的标题
	mov openfilename.lpstrInitialDir, OFFSET szInitDir  ;打开时的初始目录
	mov openfilename.lpstrFile, OFFSET szOpenFileNames  ;文件名
	invoke GetOpenFileName, ADDR openfilename
	.IF eax == 1  ;选择文件成功
		;invoke crt_printf, offset printstr, openfilename.lpstrFile
		invoke lstrcpyn, ADDR szPath, ADDR szOpenFileNames, openfilename.nFileOffset ;将第二个参数复制到第一个参数，长度为第三个参数
		invoke lstrlen, ADDR szPath ;返回长度
		mov nLen, eax ;eax的值就是长度
		mov ebx, eax
		mov al, szPath[ebx]
		.IF al != sep  ;sep在need.inc中
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
		mov ax, openfilename.nFileOffset ;nfileoffset指示文件名开始的位置
		add esi, eax
		mov al, [esi]
		.WHILE al != 0  ;该部分为增加songmenu
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
		sub ecx, curSize  ;ecx现在拥有添加的歌数
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
; 切换歌曲时响应
; Receives: hWndDlg是窗口句柄,newSongIndex是新的歌曲在songMenu中的下标
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeSong proc hWndDlg:DWORD, newSongIndex: DWORD
	invoke mciSendString, ADDR commandCloseSong, NULL, 0, NULL;关闭之前的歌曲
	;更新当前歌曲的信息
	mov eax, newSongIndex
	mov currentSongIndex, eax
	mov currentStatus, 1;转为播放状态
	invoke openSong,hWndDlg, currentSongIndex;打开新的歌曲
	invoke mciSendString, ADDR commandPlaySong, NULL, 0, NULL;播放歌曲
	
	Ret
changeSong endp

;-------------------------------------------------------------------------------------------------------
; 打开某首歌
; Receives: index是歌曲在歌单中下标；
; Requires: currentStatus == 0 即当前状态必须是停止状态
; Returns: none
;-------------------------------------------------------------------------------------------------------
openSong proc hWndDlg:DWORD, index:DWORD
	;LOCAL asd:DWORD;调试用
	;查找歌曲同级目录下有没有与之同名的lrc文件，即歌词文件
	;invoke readLrcFile, hWndDlg, index
	mov eax, index
	mov ebx, TYPE songMenu
	mul ebx;此时eax中存储了第index首歌曲相对于songMenu的偏移地址
	;mov asd, eax ;调试用
	;invoke crt_printf, ADDR OPENMP3, ADDR songMenu[eax]._path ;调试用
	;mov eax, asd ;调试用
	invoke wsprintf, ADDR mediaCommand, ADDR OPENMP3, ADDR songMenu[eax]._path
	invoke mciSendString, ADDR mediaCommand, NULL, 0, NULL;打开歌曲


	Ret
openSong endp

end start
