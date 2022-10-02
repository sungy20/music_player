## UI绘制

winAsm用于绘制UI界面

[简易教程]: http://www.360doc.com/content/17/0411/16/26018611_644699858.shtml

## 程序逻辑

* DialogProc处理窗口消息，根据不同类别的消息进行不同的响应

`DialogProc proc hWndDlg:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD`
接受参数: hWin是窗口句柄;uMsg是消息类别;wParam是消息参数；无返回值。

