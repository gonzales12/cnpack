{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     �й����Լ��Ŀ���Դ�������������                         }
{                   (C)Copyright 2001-2009 CnPack ������                       }
{                   ------------------------------------                       }
{                                                                              }
{            ���������ǿ�Դ���������������������� CnPack �ķ���Э������        }
{        �ĺ����·�����һ����                                                }
{                                                                              }
{            ������һ��������Ŀ����ϣ�������ã���û���κε���������û��        }
{        �ʺ��ض�Ŀ�Ķ������ĵ���������ϸ���������� CnPack ����Э�顣        }
{                                                                              }
{            ��Ӧ���Ѿ��Ϳ�����һ���յ�һ�� CnPack ����Э��ĸ��������        }
{        ��û�У��ɷ������ǵ���վ��                                            }
{                                                                              }
{            ��վ��ַ��http://www.cnpack.org                                   }
{            �����ʼ���master@cnpack.org                                       }
{                                                                              }
{******************************************************************************}

unit CnSourceHighlightFrm;
{ |<PRE>
================================================================================
* �������ƣ�CnPack IDE ר�Ұ�
* ��Ԫ���ƣ�����༭��������չ���ô���
* ��Ԫ���ߣ��ܾ��� (zjy@cnpack.org)
* ��    ע��
* ����ƽ̨��PWin2000Pro + Delphi 5.01
* ���ݲ��ԣ�PWin9X/2000/XP + Delphi 5/6/7 + C++Builder 5/6
* �� �� �����õ�Ԫ�е��ַ���֧�ֱ��ػ�������ʽ
* ��Ԫ��ʶ��$Id$
* �޸ļ�¼��2008.06.17
*               ���Ӷ� BDS ��֧��
*           2005.09.05
*               ������Ԫ
================================================================================
|</PRE>}

interface

{$I CnWizards.inc}

{$IFDEF CNWIZARDS_CNSOURCEHIGHLIGHT}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  CnWizMultiLang, StdCtrls, ExtCtrls, Buttons, ComCtrls, Menus, IniFiles,
  CnWizShareImages, CnSourceHighlight, CnWizOptions, CnSpin, CnLangMgr, CnIni;

type
  TCnSourceHighlightForm = class(TCnTranslateForm)
    grpBracket: TGroupBox;
    lbl3: TLabel;
    shpBracket: TShape;
    lbl4: TLabel;
    shpBracketBk: TShape;
    lbl5: TLabel;
    shpBracketBd: TShape;
    chkMatchedBracket: TCheckBox;
    chkBracketBold: TCheckBox;
    chkBracketMiddle: TCheckBox;
    btnOK: TButton;
    btnCancel: TButton;
    btnHelp: TButton;
    dlgColor: TColorDialog;
    grpStructHighlight: TGroupBox;
    chkHighlight: TCheckBox;
    rgMatchRange: TRadioGroup;
    grpHighlightColor: TGroupBox;
    shpneg1: TShape;
    shp0: TShape;
    shp1: TShape;
    shp2: TShape;
    shp3: TShape;
    shp4: TShape;
    shp5: TShape;
    rgMatchDelay: TRadioGroup;
    hkMatchHotkey: THotKey;
    chkMaxSize: TCheckBox;
    seDelay: TCnSpinEdit;
    pnl1: TPanel;
    seMaxLines: TCnSpinEdit;
    pnlBtn: TPanel;
    btnReset: TSpeedButton;
    chkDrawLine: TCheckBox;
    chkBkHighlight: TCheckBox;
    shpBk: TShape;
    btnLineSetting: TButton;
    pnl2: TPanel;
    lblBk: TLabel;
    chkCurrentToken: TCheckBox;
    chkHighlightCurLine: TCheckBox;
    shpCurLine: TShape;
    pmColor: TPopupMenu;
    mniReset: TMenuItem;
    mniExport: TMenuItem;
    mniImport: TMenuItem;
    dlgOpenColor: TOpenDialog;
    dlgSaveColor: TSaveDialog;
    procedure UpdateControls(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure shpBracketMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnResetClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnLineSettingClick(Sender: TObject);
    procedure mniResetClick(Sender: TObject);
    procedure mniExportClick(Sender: TObject);
    procedure mniImportClick(Sender: TObject);
  private
    { Private declarations }
    AWizard: TCnSourceHighlight;
    procedure ResetToDefaultColor;
  protected
    function GetHelpTopic: string; override;
    procedure DoLanguageChanged(Sender: TObject); override;
  public
    { Public declarations }
  end;

function ShowSourceHighlightForm(Wizard: TCnSourceHighlight): Boolean;

{$ENDIF CNWIZARDS_CNSOURCEHIGHLIGHT}

implementation

uses
  CnHighlightLineFrm;

{$IFDEF CNWIZARDS_CNSOURCEHIGHLIGHT}

{$R *.DFM}

function ShowSourceHighlightForm(Wizard: TCnSourceHighlight): Boolean;
begin
  with TCnSourceHighlightForm.Create(nil) do
  try
    AWizard := Wizard;

    chkMatchedBracket.Checked := Wizard.MatchedBracket;
    shpBracket.Brush.Color := Wizard.BracketColor;
    shpBracketBk.Brush.Color := Wizard.BracketColorBk;
    shpBracketBd.Brush.Color := Wizard.BracketColorBd;
    chkBracketBold.Checked := Wizard.BracketBold;
    chkBracketMiddle.Checked := Wizard.BracketMiddle;

    chkHighlight.Checked := Wizard.StructureHighlight;
    chkDrawLine.Checked := Wizard.BlockMatchDrawLine;
    chkBkHighlight.Checked := Wizard.BlockMatchHighlight;
    chkCurrentToken.Checked := Wizard.CurrentTokenHighlight;
    shpBk.Brush.Color := Wizard.BlockMatchBackground;
{$IFDEF BDS}
    chkHighlightCurLine.Enabled := False;
    shpCurLine.Enabled := False;
{$ELSE}
    chkHighlightCurLine.Checked := Wizard.HighLightCurrentLine;
    shpCurLine.Brush.Color := Wizard.HighLightLineColor;
{$ENDIF}

    rgMatchRange.ItemIndex := Integer(Wizard.BlockHighlightRange);
    rgMatchDelay.ItemIndex := Integer(Wizard.BlockHighlightStyle);
    seDelay.Value := Wizard.BlockMatchDelay;
    chkMaxSize.Checked := Wizard.BlockMatchLineLimit;
    seMaxLines.Value := Wizard.BlockMatchMaxLines;
    hkMatchHotkey.HotKey := Wizard.BlockMatchHotkey;

    shpneg1.Brush.Color := Wizard.FHighLightColors[-1];
    shp0.Brush.Color := Wizard.FHighLightColors[0];
    shp1.Brush.Color := Wizard.FHighLightColors[1];
    shp2.Brush.Color := Wizard.FHighLightColors[2];
    shp3.Brush.Color := Wizard.FHighLightColors[3];
    shp4.Brush.Color := Wizard.FHighLightColors[4];
    shp5.Brush.Color := Wizard.FHighLightColors[5];

    Result := ShowModal = mrOk;
    if Result then
    begin
      Wizard.MatchedBracket := chkMatchedBracket.Checked;
      Wizard.BracketColor := shpBracket.Brush.Color;
      Wizard.BracketColorBk := shpBracketBk.Brush.Color;
      Wizard.BracketColorBd := shpBracketBd.Brush.Color;
      Wizard.BracketBold := chkBracketBold.Checked;
      Wizard.BracketMiddle := chkBracketMiddle.Checked;

      Wizard.StructureHighlight := chkHighlight.Checked;
      Wizard.BlockMatchDrawLine := chkDrawLine.Checked;
      Wizard.BlockMatchHighlight := chkBkHighlight.Checked;
      Wizard.CurrentTokenHighlight := chkCurrentToken.Checked;
      Wizard.BlockMatchBackground := shpBk.Brush.Color;
      Wizard.CurrentTokenBackground := shpBk.Brush.Color;

{$IFNDEF BDS}
      Wizard.HighLightCurrentLine := chkHighlightCurLine.Checked;
      Wizard.HighLightLineColor := shpCurLine.Brush.Color;
{$ENDIF}

      Wizard.BlockHighlightRange := TBlockHighlightRange(rgMatchRange.ItemIndex);
      Wizard.BlockHighlightStyle := TBlockHighlightStyle(rgMatchDelay.ItemIndex);
      Wizard.BlockMatchDelay := seDelay.Value;
      Wizard.BlockMatchLineLimit := chkMaxSize.Checked;
      Wizard.BlockMatchMaxLines := seMaxLines.Value;
      Wizard.BlockMatchHotkey := hkMatchHotkey.HotKey;

      Wizard.FHighLightColors[-1] := shpneg1.Brush.Color;
      Wizard.FHighLightColors[0] := shp0.Brush.Color;
      Wizard.FHighLightColors[1] := shp1.Brush.Color;
      Wizard.FHighLightColors[2] := shp2.Brush.Color;
      Wizard.FHighLightColors[3] := shp3.Brush.Color;
      Wizard.FHighLightColors[4] := shp4.Brush.Color;
      Wizard.FHighLightColors[5] := shp5.Brush.Color;


      Wizard.DoSaveSettings;
      Wizard.RepaintEditors;
    end;
  finally
    Free;
  end;
end;

procedure TCnSourceHighlightForm.FormCreate(Sender: TObject);
begin
  UpdateControls(nil);
end;

procedure TCnSourceHighlightForm.UpdateControls(Sender: TObject);
begin
  shpBracket.Enabled := chkMatchedBracket.Checked;
  shpBracketBk.Enabled := chkMatchedBracket.Checked;
  shpBracketBd.Enabled := chkMatchedBracket.Checked;
  chkBracketBold.Enabled := chkMatchedBracket.Checked;
  chkBracketMiddle.Enabled := chkMatchedBracket.Checked;

  rgMatchDelay.Enabled := chkHighlight.Checked or chkDrawLine.Checked;
  rgMatchRange.Enabled := chkHighlight.Checked or chkDrawLine.Checked;
  grpHighlightColor.Enabled := chkHighlight.Checked or chkDrawLine.Checked;

//  chkCurrentToken.Enabled := chkBkHighlight.Checked;
  lblBk.Enabled := chkBkHighlight.Checked or chkCurrentToken.Checked;
  shpBk.Enabled := chkBkHighlight.Checked or chkCurrentToken.Checked;

  chkMaxSize.Enabled := chkHighlight.Checked or chkDrawLine.Checked;
  seDelay.Enabled := (chkHighlight.Checked or chkDrawLine.Checked) and (rgMatchDelay.ItemIndex = 1);
  seMaxLines.Enabled := (chkHighlight.Checked or chkDrawLine.Checked) and chkMaxSize.Checked;
  hkMatchHotkey.Enabled := (chkHighlight.Checked or chkDrawLine.Checked) and (rgMatchDelay.ItemIndex = 2);
end;

procedure TCnSourceHighlightForm.shpBracketMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Sender is TShape then
  begin
    dlgColor.Color := TShape(Sender).Brush.Color;
    if dlgColor.Execute then
      TShape(Sender).Brush.Color := dlgColor.Color;
  end;
end;

procedure TCnSourceHighlightForm.btnResetClick(Sender: TObject);
var
  P: TPoint;
begin
  P.x := btnReset.Left;
  P.y := btnReset.Top + btnReset.Height + 1;
  P := btnReset.Parent.ClientToScreen(P);
  pmColor.Popup(P.x, P.y);
end;

procedure TCnSourceHighlightForm.btnHelpClick(Sender: TObject);
begin
  ShowFormHelp;
end;

function TCnSourceHighlightForm.GetHelpTopic: string;
begin
  Result := 'CnSourceHighlight';
end;

procedure TCnSourceHighlightForm.DoLanguageChanged(Sender: TObject);
begin
  if (CnLanguageManager.LanguageStorage <> nil) and
    (CnLanguageManager.LanguageStorage.CurrentLanguage <> nil) then
  begin
    lblBk.Visible := (CnLanguageManager.LanguageStorage.CurrentLanguage.LanguageID = 2052) or
      (CnLanguageManager.LanguageStorage.CurrentLanguage.LanguageID = 1028);
    // �����Ľ����£���� label û�ط���ʾ���������
  end;
end;

procedure TCnSourceHighlightForm.btnLineSettingClick(Sender: TObject);
begin
  with TCnHighlightLineForm.Create(Self) do
  begin
    cbbLineType.ItemIndex := Ord(AWizard.BlockMatchLineStyle);
    seLineWidth.Value := AWizard.BlockMatchLineWidth;
    chkLineEnd.Checked := AWizard.BlockMatchLineEnd;
    chkLineHori.Checked := AWizard.BlockMatchLineHori;
    chkLineHoriDot.Checked := AWizard.BlockMatchLineHoriDot;
    chkLineClass.Checked := not AWizard.BlockMatchLineClass;

    if ShowModal = mrOK then
    begin
      AWizard.BlockMatchLineStyle := TCnLineStyle(cbbLineType.ItemIndex);
      AWizard.BlockMatchLineWidth := seLineWidth.Value;
      AWizard.BlockMatchLineEnd := chkLineEnd.Checked;
      AWizard.BlockMatchLineHori := chkLineHori.Checked;
      AWizard.BlockMatchLineHoriDot := chkLineHoriDot.Checked;
      AWizard.BlockMatchLineClass := not chkLineClass.Checked;

      AWizard.DoSaveSettings;
      AWizard.RepaintEditors;
    end;
    Free;
  end;
end;

procedure TCnSourceHighlightForm.ResetToDefaultColor;
begin
  shpBracket.Brush.Color := clBlack;
  shpBracketBk.Brush.Color := clAqua;
  shpBracketBd.Brush.Color := $CCCCD6;
  shpBk.Brush.Color := clYellow;
  shpCurLine.Brush.Color := LoadIDEDefaultCurrentColor;

  shpneg1.Brush.Color := HighLightDefColors[-1];
  shp0.Brush.Color := HighLightDefColors[0];
  shp1.Brush.Color := HighLightDefColors[1];
  shp2.Brush.Color := HighLightDefColors[2];
  shp3.Brush.Color := HighLightDefColors[3];
  shp4.Brush.Color := HighLightDefColors[4];
  shp5.Brush.Color := HighLightDefColors[5];
end;

procedure TCnSourceHighlightForm.mniResetClick(Sender: TObject);
begin
  ResetToDefaultColor;
end;

const
  csHighlightColorsSection = 'HighlightColors';

  csBracketColor = 'BracketColor';
  csBracketColorBk = 'BracketColorBk';
  csBracketColorBd = 'BracketColorBd';
  csBlockMatchBackground = 'BlockMatchBackground';
  csCurrentTokenHighlight = 'CurrentTokenHighlight';
  csBlockMatchHighlightColor = 'BlockMatchHighlightColor';
  csHighLightLineColor = 'HighLightLineColor';

procedure TCnSourceHighlightForm.mniExportClick(Sender: TObject);
var
  Ini: TCnIniFile;
begin
  if dlgSaveColor.Execute then
  begin
    Ini := TCnIniFile.Create(ChangeFileExt(dlgSaveColor.FileName, '.ini'));
    try
      Ini.WriteColor(csHighlightColorsSection, csBracketColor, shpBracket.Brush.Color);
      Ini.WriteColor(csHighlightColorsSection, csBracketColorBk, shpBracketBk.Brush.Color);
      Ini.WriteColor(csHighlightColorsSection, csBracketColorBd, shpBracketBd.Brush.Color);
      Ini.WriteColor(csHighlightColorsSection, csBlockMatchBackground, shpBk.Brush.Color);
      Ini.WriteColor(csHighlightColorsSection, csHighLightLineColor, shpCurLine.Brush.Color);
      Ini.WriteColor(csHighlightColorsSection, csBlockMatchHighlightColor + '-1', shpneg1.Brush.Color);
      Ini.WriteColor(csHighlightColorsSection, csBlockMatchHighlightColor + '0', shp0.Brush.Color);
      Ini.WriteColor(csHighlightColorsSection, csBlockMatchHighlightColor + '1', shp1.Brush.Color);
      Ini.WriteColor(csHighlightColorsSection, csBlockMatchHighlightColor + '2', shp2.Brush.Color);
      Ini.WriteColor(csHighlightColorsSection, csBlockMatchHighlightColor + '3', shp3.Brush.Color);
      Ini.WriteColor(csHighlightColorsSection, csBlockMatchHighlightColor + '4', shp4.Brush.Color);
      Ini.WriteColor(csHighlightColorsSection, csBlockMatchHighlightColor + '5', shp5.Brush.Color);

      Ini.UpdateFile;
    finally
      Ini.Free;
    end;
  end;
end;

procedure TCnSourceHighlightForm.mniImportClick(Sender: TObject);
var
  Ini: TCnIniFile;
begin
  if dlgOpenColor.Execute then
  begin
    Ini := TCnIniFile.Create(dlgOpenColor.FileName);
    try
      shpBracket.Brush.Color := Ini.ReadColor(csHighlightColorsSection, csBracketColor, shpBracket.Brush.Color);
      shpBracketBk.Brush.Color := Ini.ReadColor(csHighlightColorsSection, csBracketColorBk, shpBracketBk.Brush.Color);
      shpBracketBd.Brush.Color := Ini.ReadColor(csHighlightColorsSection, csBracketColorBd, shpBracketBd.Brush.Color);
      shpBk.Brush.Color := Ini.ReadColor(csHighlightColorsSection, csBlockMatchBackground, shpBk.Brush.Color);
      shpCurLine.Brush.Color := Ini.ReadColor(csHighlightColorsSection, csHighLightLineColor, shpCurLine.Brush.Color);
      shpneg1.Brush.Color := Ini.ReadColor(csHighlightColorsSection, csBlockMatchHighlightColor + '-1', shpneg1.Brush.Color);
      shp0.Brush.Color := Ini.ReadColor(csHighlightColorsSection, csBlockMatchHighlightColor + '0', shp0.Brush.Color);
      shp1.Brush.Color := Ini.ReadColor(csHighlightColorsSection, csBlockMatchHighlightColor + '1', shp1.Brush.Color);
      shp2.Brush.Color := Ini.ReadColor(csHighlightColorsSection, csBlockMatchHighlightColor + '2', shp2.Brush.Color);
      shp3.Brush.Color := Ini.ReadColor(csHighlightColorsSection, csBlockMatchHighlightColor + '3', shp3.Brush.Color);
      shp4.Brush.Color := Ini.ReadColor(csHighlightColorsSection, csBlockMatchHighlightColor + '4', shp4.Brush.Color);
      shp5.Brush.Color := Ini.ReadColor(csHighlightColorsSection, csBlockMatchHighlightColor + '5', shp5.Brush.Color);
    finally
      Ini.Free;
    end;
  end;
end;

{$ENDIF CNWIZARDS_CNSOURCEHIGHLIGHT}
end.