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
;��������
dialogProc proto arg1:dword,arg2:dword,arg3:dword,arg4:dword
init PROTO:DWORD

playPause PROTO :DWORD
importSong PROTO :DWORD
changeSong PROTO :DWORD, :DWORD
openSong PROTO:DWORD, :DWORD
;�����ṹ��
Song STRUCT
	_name BYTE 100 DUP(0);������
	_path BYTE 100 DUP(0);����·��
Song ends

.const

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

	songMenuFilename BYTE "\\song.dat",0 ;�赥����λ��
	FileName BYTE "trans.mp3",0
	OPENMP3  BYTE  'open "%s" alias cursong type mpegvideo',0;�򿪸�������

	commandPlaySong  BYTE "play cursong",0;���Ÿ���
	commandPauseSong BYTE "pause cursong",0;��ͣ����
	commandResumeSong BYTE "resume cursong",0;�ָ���������
	closeSongCommand BYTE "close cursong",0;�رյ�ǰ����

	;��ǰ������Ϣ
	currentStatus BYTE 0;��ǰ�Ĳ���״̬
	;0:ֹͣ״̬
	;1:����״̬
	;2:��ͣ״̬
	currentSongIndex DWORD 0;��ǰ�����ڸ赥�е��±�

	songLength BYTE 32 dup(0);��ǰ�������ȣ���λ�����룩
	timeScale DWORD 1000;��ͺ������
	timeScaleSec DWORD 60;��ͷ��ӽ���
	timeMinuteLength DWORD 0;��ǰ�������ȣ�����ȡ����
	timeSecondLength DWORD 0;��ǰ�������ȣ���ȡ����

	;---�赥��Ϣ,��������д���ļ���---
	;songMenu Song 100 dup(<"1", "1">)
	songMenu Song <"trans.mp3","src/trans.mp3">,<"Viva.mp3","src/Viva.mp3">,
	 <"��Ԫ��.mp3","src/��Ԫ��.mp3">,<"����.mp3","src/����.mp3">,
	<"�Ը�֮��.mp3","src/�Ը�֮��.mp3">,<"���֮��.wav","src/���֮��.wav">
	songMenuSize DWORD 6;�赥��С
	;---�赥��Ϣ---

	;---���ļ��Ի���---
	openfilename OPENFILENAME <>
	szLoadTitle BYTE 'ѡ�����', 0
	szInitDir BYTE '\\', 0
	szOpenFileNames BYTE 8000 DUP(0)
	szFileName BYTE 100 DUP(0)
	szPath BYTE 100 DUP(0)
	nMaxFile = SIZEOF szOpenFileNames
	szBaseDir BYTE 256 DUP(0)
	sep BYTE '\\'
	szWarningTitle BYTE 'Warning', 0
	szWarning BYTE '��ѡ��Ҫɾ���ĸ���', 0
	;---���ļ��Ի���---

	guiWorkingDir BYTE 200 DUP(0);GUI������Ĺ���·��
.data?
	hInstance dword ?
	mediaCommand BYTE ?; ��ý���������(mciSendString��Ҫ���Ӳ���ʱʹ�ã�