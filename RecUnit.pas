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
