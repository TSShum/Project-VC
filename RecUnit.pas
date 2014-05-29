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
