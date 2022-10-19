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

;-------------------------------------------------------------------------------------------------------
; 处理dialog信息的逻辑函数
; Receives: hWndDlg是窗口句柄,uMsg、wParam、lParam区分各类信息
; Returns: none
;-------------------------------------------------------------------------------------------------------
dialogProc proc hWndDlg:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    mov eax, uMsg  ;将事件信息存入eax

    .if eax == WM_INITDIALOG  ;WM_INITDIALOG为初始化窗口
		invoke init, hWndDlg
	.elseif eax == WM_HSCROLL  ;WM_HSCROLL为滑块消息
		invoke GetDlgCtrlID,lParam
			mov curSlider,eax
			mov ax,WORD PTR wParam;消息类别
			.if curSlider == IDC_VOLUME_SLIDER;调节音量
				.if ax == SB_THUMBTRACK;滚动消息
					invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_GETCURSEL, 0, 0;获取被选中的下标
					.if eax != -1;当前有歌曲被选中，则发送命令调整音量
						invoke changeVolume,hWndDlg
					.endif
				.elseif ax == SB_ENDSCROLL;滚动结束消息
					invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_GETCURSEL, 0, 0;获取被选中的下标
					.if eax != -1;
						invoke changeVolume,hWndDlg
					.endif
				.endif
			.endif
    .elseif eax == WM_COMMAND  ;WM_COMMAND为控件信息
        mov eax, wParam
		mov ebx, songMenuSize
		.if eax == IDC_IMPORT_BT ;按下导入歌曲键
			invoke importSong, hWndDlg
			;mov eax, wParam
			invoke SetCurrentDirectory, ADDR guiWorkingDir;
		.elseif ebx == 0 ;歌单为空时，下面的操作就没意思了
			ret
        .elseif eax == CON_PAUSE  ;暂停/播放键
			invoke playPause,hWndDlg
		.elseif ax == IDC_SONGMENU;若歌单
			shr eax,16
			.if ax == LBN_SELCHANGE;选中项发生改变
				invoke SendDlgItemMessage, hWndDlg, IDC_SONGMENU, LB_GETCURSEL, 0, 0;则获取被选中的下标
				mov currentSongIndex, eax
				mov currentStatus, 0; 将当前状态设为停止，方便播放改变歌曲
			.elseif ax == LBN_DBLCLK;双击歌曲播放
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
		.elseif eax == IDC_DELETE_BT ;删除选中歌曲
			invoke SendDlgItemMessage, hWndDlg,IDC_SONGMENU,LB_GETCURSEL,0,0
			.if eax == -1 ;没选中歌曲
				ret
			.endif
			invoke deleteSong,hWndDlg,eax;
		.elseif eax == IDC_VOLUME_BT ;静音按钮@hemu,静音切换靠你来实现咯
			;.if hasSound == 1
			;	mov hasSound, 0
			;	invoke changeVolume,hWndDlg
			;.else
			;	mov hasSound, 1
			;	invoke changeVolume,hWndDlg
			;.endif
        .endif
    .elseif eax == WM_CLOSE  ;WM_CLOSE为关闭窗口
		invoke saveFile, hWndDlg
        invoke EndDialog,hWndDlg,0
    .endif
    xor eax,eax  ;可以尝试注释，之后会发生有意思的事，嘻嘻
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
	
	invoke loadFile, hWndDlg
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
	invoke SendDlgItemMessage,hWndDlg, IDC_SONGMENU, LB_SETCURSEL, 0, 0 ;将列表选择设置到第一首歌上

	;初始化播放按钮为暂停状态
	invoke changePlayButton,hWndDlg, 0

	invoke changeSilenceButton,hWndDlg, 1
	;加载图标
	mov eax, 113
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWndDlg,PRE_SONG, BM_SETIMAGE, IMAGE_ICON, eax;修改按钮
	mov eax, 115
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWndDlg,NEXT_SONG, BM_SETIMAGE, IMAGE_ICON, eax;修改按钮
	;初始化音量条,最大范围到sliderLength且值默认为最大值
	invoke SendDlgItemMessage, hWndDlg, IDC_VOLUME_SLIDER, TBM_SETRANGEMIN, 0, 0
	invoke SendDlgItemMessage, hWndDlg, IDC_VOLUME_SLIDER, TBM_SETRANGEMAX, 0, sliderLength
	invoke SendDlgItemMessage, hWndDlg, IDC_VOLUME_SLIDER, TBM_SETPOS, 1, sliderLength
	ret
init endp

;-------------------------------------------------------------------------------------------------------
; 点击播放/暂停按钮时响应
; Receives: hWndDlg是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
playPause proc hWndDlg:DWORD
	.if currentStatus == 0;若当前状态为停止状态
		mov currentStatus, 1;转为播放状态
		invoke changePlayButton,hWndDlg, 1
		;invoke mciSendString, ADDR OPENMP3, NULL, 0, NULL;打开歌曲
		invoke mciSendString, ADDR commandCloseSong, NULL, 0, NULL ;歌单中某歌曲正播放时，切换下一首歌并且点击播放，需要停止之前的歌曲
		invoke openSong,hWndDlg, currentSongIndex;打开歌曲
		invoke mciSendString,ADDR commandPlaySong,NULL,0,NULL;播放歌曲
		;invoke EndDialog,hWndDlg,0

	.elseif currentStatus == 1;若当前状态为播放状态
		mov currentStatus, 2;转为暂停状态
		invoke changePlayButton,hWndDlg, 0
		invoke mciSendString, ADDR commandPauseSong, NULL, 0, NULL;暂停歌曲	
		;invoke EndDialog,hWndDlg,0
		
	.elseif currentStatus == 2;若当前状态为暂停状态
		mov currentStatus, 1;转为播放状态
		invoke changePlayButton,hWndDlg, 1
		invoke openSong,hWndDlg, currentSongIndex;打开歌曲
		invoke mciSendString,ADDR commandPlaySong,NULL,0,NULL;播放歌曲
		;invoke mciSendString, ADDR commandResumeSong, NULL, 0, NULL;恢复歌曲播放
	.endif
	ret
playPause endp

;-------------------------------------------------------------------------------------------------------
; 寻找歌单中是否有搜索歌曲
; songName是歌曲名称
; Returns: 找到返回1，否则返回0
;-------------------------------------------------------------------------------------------------------
searchSong proc uses esi ecx songNameaddr:DWORD
	mov esi, offset songMenu
	mov ecx, songMenuSize
	.while(ecx > 0)
		push ecx
		invoke lstrcmp, esi, songNameaddr
		pop ecx
		.if(eax == 0)
			ret 1
		.endif
		add esi, 200
		dec ecx
	.endw
	ret 0
searchSong endp

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
		.IF al != sep  ;sep在need.inc中，为'\\'，这里是给szpath加一个斜杠
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
			invoke lstrcpy, ADDR songName, esi
			invoke searchSong, ADDR songName
			.if (eax == 0)
			.else
				mov edi, curOffset
				add curOffset, SIZEOF Song
				invoke lstrcpy, edi, esi  ;song._name
				add edi, 100
				invoke lstrcpy, edi, ADDR szFileName  ;song._path
				add songMenuSize, 1
			.endif
			invoke lstrlen, esi
			inc eax
			add esi, eax
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
	invoke changePlayButton,hWndDlg, 1
	invoke mciSendString, ADDR commandCloseSong, NULL, 0, NULL;关闭之前的歌曲
	;更新当前歌曲的信息
	mov eax, newSongIndex
	mov currentSongIndex, eax
	mov currentStatus, 1;转为播放状态
	
	invoke openSong,hWndDlg, currentSongIndex;打开新的歌曲
	invoke mciSendString, ADDR commandPlaySong, NULL, 0, NULL;播放歌曲
	
	ret
changeSong endp

;-------------------------------------------------------------------------------------------------------
; 打开某首歌
; Receives: index是歌曲在歌单中下标；
; Requires: currentStatus == 0 即当前状态必须是停止状态
; Returns: none
;-------------------------------------------------------------------------------------------------------
openSong proc hWndDlg:DWORD, index:DWORD
	LOCAL asd:DWORD;调试用
	;查找歌曲同级目录下有没有与之同名的lrc文件，即歌词文件
	;invoke readLrcFile, hWndDlg, index
	mov eax, index
	mov ebx, TYPE songMenu
	mul ebx;此时eax中存储了第index首歌曲相对于songMenu的偏移地址
	mov asd, eax ;调试用
	invoke crt_printf, ADDR OPENMP3, ADDR songMenu[eax]._path ;调试用
	mov eax, asd ;调试用
	invoke wsprintf, ADDR mediaCommand, ADDR OPENMP3, ADDR songMenu[eax]._path
	invoke mciSendString, ADDR mediaCommand, NULL, 0, NULL;打开歌曲

	ret
openSong endp

;-------------------------------------------------------------------------------------------------------
; 删除对应index的歌
; Receives: index是歌曲在歌单中下标；
; Returns: none
;-------------------------------------------------------------------------------------------------------
deleteSong proc hWndDlg:DWORD, index:DWORD
	LOCAL nextadd :DWORD ;下一首歌的地址
	mov eax, currentSongIndex
	inc eax
	.if eax == songMenuSize
		mov currentSongIndex, 0
	.endif
	dec eax
	.if eax == index
		invoke mciSendString, ADDR commandCloseSong, NULL, 0, NULL; 若待删除歌曲正在播放
		mov currentStatus, 0 ;将当前状态设置为停止
	.endif

	mov esi, OFFSET songMenu
	mov eax, index
	mov ebx, SIZEOF Song
	mul ebx
	add esi, eax ;到达要删除歌的位置
	mov nextadd, esi
	add nextadd, SIZEOF Song
	mov edi, nextadd ;下一首歌的位置
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
; 读取保存文件中的歌单信息
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
; 保存退出前的歌单信息
; Receives: hWndDlg
; Returns: none
;-------------------------------------------------------------------------------------------------------
saveFile proc hWndDlg:DWORD
	LOCAL songFile: DWORD
	LOCAL bytesWritten: DWORD
	invoke CreateFile, addr songFileName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	mov songFile, eax
	.if songFile == INVALID_HANDLE_VALUE
		ret
	.endif
	invoke WriteFile, songFile, addr songMenuSize, SIZEOF songMenuSize, addr bytesWritten, NULL
	invoke WriteFile, songFile, addr songMenu, SIZEOF songMenu, addr bytesWritten, NULL
	invoke CloseHandle, songFile
	ret
saveFile endp

;-------------------------------------------------------------------------------------------------------
; 改变歌曲音量大小
; Receives: hWndDlg
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeVolume proc hWndDlg:DWORD
	invoke SendDlgItemMessage,hWndDlg,IDC_VOLUME_SLIDER,TBM_GETPOS,0,0;获取游标数值
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
; 改变播放按钮
; Receives: hWndDlg是窗口句柄；playing=1表示接下来播放，=0表示接下来不播放
; Returns: none
;-------------------------------------------------------------------------------------------------------
changePlayButton proc hWndDlg:DWORD, playing:BYTE
	.if playing == 0;转到暂停状态
		mov eax, 116
	.else;转到播放状态
		mov eax, 117
	.endif
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWndDlg,CON_PAUSE, BM_SETIMAGE, IMAGE_ICON, eax;修改按钮
	Ret
changePlayButton endp

;-------------------------------------------------------------------------------------------------------
; 刷新静音按钮的视图显示
; Receives: hWndDlg是窗口句柄；_hasSound=1表示接下来有声音，=0表示接下来没有声音
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeSilenceButton proc hWndDlg:DWORD, _hasSound:BYTE
	.if _hasSound == 0;转到暂停状态
		mov eax, close_sound
	.else;转到播放状态
		mov eax, open_sound
	.endif
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWndDlg,IDC_VOLUME_BT, BM_SETIMAGE, IMAGE_ICON, eax;修改按钮
	Ret
changeSilenceButton endp
end start
