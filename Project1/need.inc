include     windows.inc
include     user32.inc
include     kernel32.inc
include     comctl32.inc
include     winmm.inc
include		comdlg32.inc
include		msvcrt.inc
include 	shlwapi.inc
include 	msvcrt.inc
include gdi32.inc
include gdiplus.inc
include wsock32.inc

includelib  kernel32.lib
includelib  user32.lib
includelib  winmm.lib
includelib  comctl32.lib
includelib	winmm.lib
includelib	msvcrt.lib
includelib  comdlg32.lib
includelib gdi32.lib
includelib gdiplus.lib
includelib wsock32.lib
;函数声明
dialogProc proto arg1:dword,arg2:dword,arg3:dword,arg4:dword
init PROTO:DWORD

playPause PROTO :DWORD
importSong PROTO :DWORD
changeSong PROTO :DWORD, :DWORD
openSong PROTO:DWORD, :DWORD
deleteSong PROTO:DWORD, :DWORD
loadFile PROTO:DWORD
saveFile PROTO:DWORD
changeVolume PROTO:DWORD
changeProgressBar PROTO:DWORD
changeTime PROTO:DWORD
;歌曲结构体
Song STRUCT
	_name BYTE 100 DUP(0);歌曲名
	_path BYTE 100 DUP(0);歌曲路径
Song ends

.const

;控件大写，资源小写
PRE_SONG		EQU 1028
CON_PAUSE		EQU 1005
NEXT_SONG		EQU 1027
IDC_SERACH_BT		EQU 1013
IDC_SEARCH_EDIT		EQU 1012
IDC_CLEAR_BT		EQU 1011
IDC_DELETE_BT		EQU 1009
IDC_IMPORT_BT		EQU 1008
IDC_SONGMENU		EQU 1026
recyle		EQU 112
IDC_RECYLE_BT		EQU 1014
back		EQU 113
control		EQU 114
forward		EQU 115
pause0		EQU 116
play		EQU 117
random		EQU 118
loop0		EQU 119
loop1		EQU 120
open_sound		EQU 121
close_sound		EQU 122
cover		EQU 123
IDC_VOLUME_SLIDER		EQU 1024
IDC_COVER_IMAGE		EQU 1019
IDC_VOLUME_IMAGE		EQU 1018
IDC_IYRIC		EQU 1020
IDC_PROGRESS_BAR		EQU 1025
DIALOG		EQU 1001
temp EQU 1000

.data

	songMenuFilename BYTE "\\song.dat",0 ;歌单保存位置
	OPENMP3  BYTE  'open "%s" alias cursong',0;打开歌曲命令

	commandPlaySong  BYTE "play cursong",0;播放歌曲
	commandPauseSong BYTE "pause cursong",0;暂停歌曲
	commandResumeSong BYTE "resume cursong",0;恢复歌曲播放
	commandCloseSong BYTE "close cursong",0;关闭当前歌曲
	commandGetProgress BYTE "status cursong position", 0;获取歌曲进度条位置
	commandSetProgress BYTE "seek cursong to %d", 0;设置歌曲当前播放位置命令
	commandGetLength BYTE "status cursong length", 0;获取歌曲长度命令

	;当前歌曲信息
	currentStatus BYTE 0;当前的播放状态
	;0:停止状态
	;1:播放状态
	;2:暂停状态
	currentSongIndex DWORD 0;当前歌曲在歌单中的下标

	songLength BYTE 32 dup(0);当前歌曲长度（单位：毫秒）
	songProgress BYTE 32 dup(0);当前播放进度（单位：毫秒）
	timeScale DWORD 1000;秒和毫秒进制
	timeScaleSec DWORD 60;秒和分钟进制
	timeMinuteLength DWORD 0;当前歌曲进度（分钟取整）
	timeSecondLength DWORD 0;当前歌曲进度（秒取整）

	;---歌单信息,将其内容写在文件中---
	;songMenu Song 100 dup(<"1", "1">)
	songMenu Song 50 DUP(<"0","0">)
	songMenuSize DWORD 0;歌单大小
	songFileName BYTE "song.dat", 0 ;歌单文件名字
	;---歌单信息---

	;---打开文件对话框---
	openfilename OPENFILENAME <>  ;https://blog.csdn.net/hanxiaoyang123/article/details/83999587
	szLoadTitle BYTE '选择歌曲', 0
	szInitDir BYTE '\\', 0
	szOpenFileNames BYTE 8000 DUP(0)
	szFileName BYTE 100 DUP(0)
	szPath BYTE 100 DUP(0)
	nMaxFile = SIZEOF szOpenFileNames
	szBaseDir BYTE 256 DUP(0)
	sep BYTE '\\'
	szWarningTitle BYTE 'Warning', 0
	szWarning BYTE '请选择要删除的歌曲', 0
	printstr BYTE "%s",0
	clear BYTE 100 DUP(0)
	;---打开文件对话框---

	guiWorkingDir BYTE 200 DUP(0);GUI主程序的工作路径

	;---音量功能---
	curSlider DWORD ?;当前产生事件的进度条
	hasSound BYTE 1
	commandVolumeChange BYTE "setaudio cursong volume to %d",0;音量大小改变
	sliderLength DWORD 1000
	;---音量功能---

	;---进度条功能---
	ProgressBarDragging BYTE 0;
	;---进度条功能---
.data?
	hInstance dword ?
	mediaCommand BYTE 100 DUP(0); 多媒体控制命令(mciSendString需要附加参数时使用）

