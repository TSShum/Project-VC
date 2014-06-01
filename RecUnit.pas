unit RecUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, OleCtrls, ACTIVELISTENPROJECTLib_TLB, ShellAPI, Tlhelp32,
  Menus, ExtCtrls;
function killTask(ExeFileName: string): Integer;

type
  TRecForm = class(TForm)
    DirectSR: TDirectSR;
    EnginesList: TComboBox;
    VolumeProgressBar: TProgressBar;
    lblPress: TLabel;
    TrayMenu: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    CheckTimer: TTimer;
    btnSS: TButton;
    procedure Tray(n:Integer; Icon:TIcon);
    procedure CheckTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure EnginesListChange(Sender: TObject);
    procedure btnSSClick(Sender: TObject);
    procedure DirectSRPhraseFinish(ASender: TObject; flags, beginhi,
      beginlo, endhi, endlo: Integer; const Phrase, parsed: WideString;
      results: Integer);
    procedure DirectSRVUMeter(ASender: TObject; beginhi, beginlo,
      level: Integer);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
  protected
    { Protected declarations }
    procedure ControlWindow(var Msg:TMessage); message WM_SYSCOMMAND;
    procedure TrayEvent(var Msg:TMessage); message WM_USER + 1;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  RecForm: TRecForm;
  stop: Boolean = true;
  listen: Boolean = false;

implementation

{$R *.dfm}
// Добавление в трей
procedure TRecForm.Tray(n:Integer; Icon:TIcon);
var Nim:TNotifyIconData;
begin
 with Nim do
  begin
   cbSize := SizeOf(Nim);
   Wnd := RecForm.Handle;
   uID := 1;
   uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
   hicon := Icon.Handle;
   uCallbackMessage := wm_user+1;
   szTip := 'Ведется распознование комманд';
  end;
 case n of
  1: Shell_NotifyIcon(Nim_Add,@Nim);
  2: Shell_NotifyIcon(Nim_Delete,@Nim);
  3: Shell_NotifyIcon(Nim_Modify,@Nim);
 end;
end;


procedure TRecForm.TrayEvent(var Msg:TMessage);
var p:TPoint;
begin
GetCursorPos(p); // Запоминаем координаты курсора мыши
case Msg.LParam of  // Проверяем какая кнопка была нажата
  WM_LBUTTONDBLCLK:
  begin
    PostMessage(Handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0);  
  end;
  WM_RBUTTONUP:
  begin
    SetForegroundWindow(Handle);  // Восстанавливаем программу в качестве переднего окна
    TrayMenu.Popup(p.X, p.Y);  // Заставляем всплыть popup
    PostMessage(Handle, WM_NULL, 0, 0);
  end;
end;
end;

// Отлавливаем, когда пользователь минимизирует программу
procedure TRecForm.ControlWindow(var Msg:TMessage);
begin
 if Msg.WParam = SC_MINIMIZE then
  begin
   Tray(1, Application.Icon); // Добавляем значок в трей
   ShowWindow(Handle, SW_HIDE); // Скрываем программу
   ShowWindow(Application.Handle, SW_HIDE); // Скрываем кнопку с TaskBar'а
 end else begin
  if Msg.WParam = SC_MAXIMIZE then
    begin
      Tray(2, Application.Icon); // Добавляем значок в трей
      ShowWindow(Handle, SW_SHOW); // Скрываем программу
      ShowWindow(Application.Handle, SW_SHOW); // Скрываем кнопку с TaskBar'а
    end else inherited;
 end;
end;

//'Убийца' процессов
{function killTask(ExeFileName: string): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);

  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
      Result := Integer(TerminateProcess(
                        OpenProcess(PROCESS_TERMINATE,
                                    BOOL(0),
                                    FProcessEntry32.th32ProcessID),
                                    0));
     ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;}

procedure TRecForm.FormCreate(Sender: TObject);
var
 i: integer;
begin
 for i:=1 to DirectSR.CountEngines do
  EnginesList.Items.Add(DirectSR.ModeName(i));
  EnginesList.ItemIndex:=1;

end;

procedure TRecForm.EnginesListChange(Sender: TObject);
begin
 DirectSR.Select(EnginesList.ItemIndex+1)
end;

procedure TRecForm.btnSSClick(Sender: TObject);
begin
if stop then
begin
// если не идет прослушивание, значит запускаем его
    DirectSR.Initialized:=1;
    DirectSR.Select(EnginesList.ItemIndex+1);
    DirectSR.GrammarFromFile('Grammar.txt');
    DirectSR.Activate;
    lblPress.Caption:='Распознаю...';
    Stop:=false;
    btnSS.caption:='Остановить';
end else 
begin
// если прослушивание уже идет, то останавливаем его
    DirectSR.Deactivate;
    Stop:=true;
    btnSS.caption:='Распозновать';
    lblPress.Caption:='Работа приостановлена';
end;

end;

procedure TRecForm.CheckTimerTimer(Sender: TObject);
begin
if GetAsyncKeyState(VK_F9)< 0 then begin
  if not listen then begin
  listen := True;
  DirectSR.Initialized:=1;
  DirectSR.Select(EnginesList.ItemIndex+1);
  DirectSR.GrammarFromFile('Grammar.txt');
  DirectSR.Activate;
  lblPress.Caption:='Распознаю...';
  end
end else
if GetAsyncKeyState(VK_F9)= 0 then begin
  if listen then begin
  listen := False;
  DirectSR.Deactivate;
  lblPress.Caption:='Работа приостановлена';
  end;
end;

end;

procedure TRecForm.DirectSRPhraseFinish(ASender: TObject; flags, beginhi,
  beginlo, endhi, endlo: Integer; const Phrase, parsed: WideString;
  results: Integer);
begin

// ОПЕРАЦИИ ДЛЯ ГОЛОСОВЫХ КОММАНД:
//ShowMessage(Phrase);

 If (Phrase='Close program') then close;
 If (Phrase='My computer') then ShellExecute(RecForm.Handle, 'open', 'C:\Users\Paul\Desktop\Компьютер.lnk' ,nil, nil,SW_SHOWNORMAL);
 If (Phrase='Open photoshop') then ShellExecute(RecForm.Handle, 'open', 'photoshop.exe', nil, nil,SW_SHOWNORMAL);
// If (Phrase='Close photoshop') then KillTask('photoshop.exe');
 If (Phrase='Open skype') then ShellExecute(RecForm.Handle, 'open', 'skype.exe', nil, nil,SW_SHOWNORMAL);
// If (Phrase='Close skype') then KillTask('skype.exe');
 If (Phrase='Open notepad') then ShellExecute(RecForm.Handle, 'open', 'notepad.exe', nil, nil,SW_SHOWNORMAL);
// If (Phrase='Close notepad') then KillTask('notepad.exe');
 If (Phrase='Exit') then begin
    keybd_event(VK_LMENU,0,0,0);
    keybd_event(VK_F4,0,0,0);
    keybd_event(VK_F4,0,KEYEVENTF_KEYUP,0);
    keybd_event(VK_LMENU,0,KEYEVENTF_KEYUP,0);
    end;
 If(Phrase='Yes, i do') then begin
    keybd_event(VK_RETURN,0,0,0);
    keybd_event(VK_RETURN,0,KEYEVENTF_KEYUP,0);
    end;
 If(Phrase='No, i dont') then begin
    keybd_event(VK_TAB,0,0,0);
    keybd_event(VK_TAB,0,KEYEVENTF_KEYUP,0);
    keybd_event(VK_RETURN,0,0,0);
    keybd_event(VK_RETURN,0,KEYEVENTF_KEYUP,0);
    end;
 If(Phrase='Cancel') then begin
    keybd_event(VK_TAB,0,0,0);
    keybd_event(VK_TAB,0,KEYEVENTF_KEYUP,0);
    keybd_event(VK_TAB,0,0,0);
    keybd_event(VK_TAB,0,KEYEVENTF_KEYUP,0);
    keybd_event(VK_RETURN,0,0,0);
    keybd_event(VK_RETURN,0,KEYEVENTF_KEYUP,0);
    end;
 If(Phrase='Windows') then begin
    keybd_event(VK_LWIN,0,0,0);
    keybd_event(VK_LWIN,0,KEYEVENTF_KEYUP,0);
    end;
 If(Phrase='Hide') or (Phrase='Hide program') then begin
    PostMessage(Handle, WM_SYSCOMMAND, SC_MINIMIZE, 0);
    end;
 If(Phrase='Show') or (Phrase='Show program') then begin
    PostMessage(Handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
    end;
 If(Phrase='List of programs') then begin
    ShellExecute(RecForm.Handle, 'open', 'C:\Users\Paul\Desktop\Распознование голоса\ListWork.jpg' ,nil, nil,SW_SHOWNORMAL);
    Sleep(300);
    keybd_event(VK_F11,0,0,0);
    keybd_event(VK_F11,0,KEYEVENTF_KEYUP,0);
    end;
 If (Phrase='Good job') then ShowMessage('Thank you');
 end;


procedure TRecForm.DirectSRVUMeter(ASender: TObject; beginhi, beginlo,
  level: Integer);
begin
VolumeProgressBar.Position:=level;
end;


procedure TRecForm.N1Click(Sender: TObject);
begin
  Close;
end;

procedure TRecForm.N2Click(Sender: TObject);
begin
  PostMessage(Handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
end;

End.
