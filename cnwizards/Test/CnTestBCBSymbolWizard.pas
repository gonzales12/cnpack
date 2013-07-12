{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     �й����Լ��Ŀ���Դ�������������                         }
{                   (C)Copyright 2001-2012 CnPack ������                       }
{                   ------------------------------------                       }
{                                                                              }
{            ���������ǿ�Դ��������������������� CnPack �ķ���Э������        }
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

unit CnTestBCBSymbolWizard;
{ |<PRE>
================================================================================
* ������ƣ�CnPack IDE ר�Ұ���������
* ��Ԫ���ƣ���ȡ BCB �� IDE �ڷ����б�ķ�װ����������Ԫ
* ��Ԫ���ߣ�CnPack ������
* ��    ע���õ�Ԫ�� BCB �ڻ�÷����б�ķ������в��ԣ�ֻ֧�� BCB 5/6��
*           �����ó���˼·�ǣ���ͨ�� GetProcAddress ��� bcbide50 �е�ȫ�ֱ���
*           Cppcodcmplt::CodeCompletionManager��ֵ�����Դ˲������� bcbide50 �е�
*           GetKibitzInfo �Դ����﷨�����͵����Զ���ɴ��ڡ��ڵ��������֮ǰ֮ǰ
*           �� Hook �� bccide �� IDEENABLEKIBITZING�������е��� GetValidSymbols
*           �� CppGetSymbolText ���õ������б��� Hook �� GetValidSymbols ����
*           ���� 0 �����ε������Զ���ɴ��ڡ�
* ����ƽ̨��PWin2000Pro + Delphi 5.01
* ���ݲ��ԣ�PWin9X/2000/XP + Delphi 5/6/7 + C++Builder 5/6
* �� �� �����ô����е��ַ����ݲ�֧�ֱ��ػ�����ʽ
* ��Ԫ��ʶ��$Id: CnTestBCBSymbolWizard.pas 1146 2012-10-24 06:25:41Z liuxiaoshanzhashu@gmail.com $
* �޸ļ�¼��2013.07.10 V1.0
*               ������Ԫ
================================================================================
|</PRE>}

interface

{$I CnWizards.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ToolsAPI, IniFiles, CnWizClasses, CnWizUtils, CnWizConsts, CnWizIdeUtils,
  CnWizCompilerConst, CnWizMethodHook;

type

//==============================================================================
// ���� BCB IDE �����б�Ĳ˵�ר��
//==============================================================================

{ TCnTestBCBSymbolWizard }

  TCnTestBCBSymbolWizard = class(TCnMenuWizard)
  private

  protected
    function GetHasConfig: Boolean; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function GetState: TWizardState; override;
    procedure Config; override;
    procedure LoadSettings(Ini: TCustomIniFile); override;
    procedure SaveSettings(Ini: TCustomIniFile); override;
    class procedure GetWizardInfo(var Name, Author, Email, Comment: string); override;
    function GetCaption: string; override;
    function GetHint: string; override;
    function GetDefShortCut: TShortCut; override;
    procedure Execute; override;
  end;

procedure CnIDEEnableKibitzing(AParam: Integer); stdcall;

implementation

uses
  CnDebug, mPasLex, CnWizEditFiler;

type
  TSymbols = packed array[0..(MaxInt div SizeOf(Integer))-1] of Integer;
  PSymbols = ^TSymbols;
  TUnknowns = packed array [0..(MaxInt div SizeOf(Byte))-1] of Byte;
  PUnknowns = ^TUnknowns;
  // ����������� TKibitzResult ��¼�� RTTI ��Ϣ����BCB�в�һ������
  TKibitzResult = packed record
  {$IFDEF COMPILER7_UP}
    KibitzDataArray: array [0..82] of Integer;
  {$ELSE}
    KibitzDataArray: array [0..81] of Integer;
  {$ENDIF}
  {$IFDEF COMPILER6_UP}
    KibitzDataStr: string; // RTTI ��ʾ�����λ����һ�� string ����
  {$ENDIF}
    KibitzReserveArray: array[0..255] of Integer; // �ٶ���һ�������鱸��
  end;

  TGetKibitzInfoProc = procedure(CCMgrSelf: Integer; XPos, YPos: Integer;
    var KibitzResult: TKibitzResult); register;

  TIDEEnableKibitzingProc = procedure(AParam: Integer); stdcall;

  TKibitzGetValidSymbolsProc = function(AParam: Integer;
    Symbols: PSymbols; Unknowns: PUnknowns; SymbolCount: Integer): Integer; stdcall;

  TCompGetSymbolTextProc = procedure(Symbol: Integer {Comtypes::TSymbol*};
    Bif: PChar; Unknown: Word); stdcall;

const
  bccLibName = 'bccide.dll';

  CodeCompletionManagerName = '@Cppcodcmplt@CodeCompletionManager'; // bcbide50.bpl ��ȫ�ֵ�CodeCompletionManagerʵ���ĵ�������

  GetKibitzInfoName = '@Cppcodcmplt@TCodeCompletionManager@GetKibitzInfo$qqriir22Comtypes@TKibitzResult';

  IDEEnableKibitzingName = 'IDEENABLEKIBITZING';

  KibitzGetValidSymbolsName = 'CppGetValidSymbols';
  // corideXX.bpl
  // Comdebug.CompGetSymbolText(Symbol: PSymbols; var S: string; Unknown: Word); stdcall;
  CppGetSymbolTextName = 'CppGetSymbolText';

  csMaxSymbolCount = 32768;

var
  CorIdeModule: HModule = 0;
  DphIdeModule: HModule = 0;
  bccModule: HModule = 0;
  
  IDEEnableKibitzingRun: Boolean = False;

  GlobalCodeCompletionManager: Integer = 0;
  KibitzEnabled: Boolean = False;
  GetKibitzInfo: TGetKibitzInfoProc;
  IDEEnableKibitzing: TIDEEnableKibitzingProc;
  KibitzGetValidSymbols: TKibitzGetValidSymbolsProc;
  CppGetSymbolText: TCompGetSymbolTextProc;

  IDEEnableKibitzingHook: TCnMethodHook = nil;
  KibitzGetValidSymbolsHook: TCnMethodHook = nil;

function KibitzInitialize: Boolean;
var
  P: PInteger;
begin
  Result := False;
  try
    DphIdeModule := LoadLibrary(DphIdeLibName);
    Assert(DphIdeModule <> 0, 'Failed to load DphIdeModule');

    GetKibitzInfo := GetProcAddress(DphIdeModule, GetKibitzInfoName);
    Assert(Assigned(GetKibitzInfo), 'Failed to load GetKibitzInfo from DphIdeModule');

    P := GetProcAddress(DphIdeModule, CodeCompletionManagerName);
    if P <> nil then
    begin
      GlobalCodeCompletionManager := Integer(P^);
      CnDebugger.LogFmt('Get Global CodeCompletionManager Address %8.8x, Value %8.8x.',
        [Integer(P), GlobalCodeCompletionManager]);
    end;

    bccModule := LoadLibrary(bccLibName);
    Assert(bccModule <> 0, 'Failed to load dccModule');

    KibitzGetValidSymbols := GetProcAddress(bccModule, KibitzGetValidSymbolsName);
    Assert(Assigned(KibitzGetValidSymbols), 'Failed to load KibitzGetValidSymbols from dccModule');

    IDEEnableKibitzing := GetProcAddress(bccModule, IDEEnableKibitzingName);
    Assert(Assigned(IDEEnableKibitzing), 'Failed to load IDEEnableKibitzing from dccModule');

//    CorIdeModule := LoadLibrary(CorIdeLibName);
//    Assert(CorIdeModule <> 0, 'Failed to load CorIdeModule');

    CppGetSymbolText := GetProcAddress(bccModule, CppGetSymbolTextName);
    Assert(Assigned(CppGetSymbolText), 'Failed to load CppGetSymbolText');

    Result := True;
  {$IFDEF Debug}
    CnDebugger.LogMsg('TCnTestBCBSymbolWizard KibitzInitialize succ');
  {$ENDIF}
  except
    on E: Exception do
      DoHandleException(E.Message);
  end;
end;

procedure KibitzFinalize;
begin
  if CorIdeModule <> 0 then
  begin
    FreeLibrary(CorIdeModule);
    CorIdeModule := 0;
  end;

  if bccModule <> 0 then
  begin
    FreeLibrary(bccModule);
    bccModule := 0;
  end;

  if DphIdeModule <> 0 then
  begin
    FreeLibrary(DphIdeModule);
    DphIdeModule := 0;
  end;
end;

function ParseProjectBegin(var FileName: AnsiString; var X, Y: Integer): Boolean;
var
  Stream: TMemoryStream;
  Source: AnsiString;
  Lex: TmwPasLex;
begin
{$IFDEF Debug}
  CnDebugger.LogMsg('ParseProjectBegin');
{$ENDIF}

  Result := False;
  FileName := CnOtaGetCurrentProjectFileName;
  Stream := TMemoryStream.Create;
  try
    EditFilerSaveFileToStream(FileName, Stream, False);
    Source := PAnsiChar(Stream.Memory);
  finally
    Stream.Free;
  end;

{$IFDEF Debug}
  CnDebugger.LogMsg(FileName + #13#10 + Source);
{$ENDIF}
  Lex := TmwPasLex.Create;
  try
    Lex.Origin := PAnsiChar(Source);
    while Lex.TokenID <> tkNull do
    begin
      if Lex.TokenID = tkBegin then
      begin
        Lex.Next;
        X := 0;
        Y := Lex.LineNumber + 1;
        Result := True;
        Break;
      end;
      Lex.Next;
    end;
  finally
    Lex.Free;
  end;
end;

procedure FakeDoKibitzCompile(FileName: AnsiString; XPos, YPos: Integer;
  var KibitzResult: TKibitzResult); register;
begin
  CnDebugger.LogMsg('TestBCBSymbol FakeDoKibitzCompile');
  FillChar(KibitzResult.KibitzDataArray, SizeOf(KibitzResult.KibitzDataArray), 0);
end;

function FakeKibitzGetValidSymbols(var KibitzResult: TKibitzResult;
  Symbols: PSymbols; Unknowns: PUnknowns; SymbolCount: Integer): Integer; stdcall;
begin
  CnDebugger.LogMsg('TestBCBSymbol FakeKibitzGetValidSymbols');
  Result := 0;
end;

procedure CnIDEEnableKibitzing(AParam: Integer); stdcall;
var
  I, SymbolCount: Integer;
  Unknowns: PUnknowns;
  Symbols: PSymbols;
  Text: array[0..1023] of Char;
begin
  if IDEEnableKibitzingRun then
  begin
    if Assigned(IDEEnableKibitzing) then
    begin
      IDEEnableKibitzingHook.UnhookMethod;
      IDEEnableKibitzing(AParam);
      Exit;
    end;
  end;
  IDEEnableKibitzingRun := True;

  CnDebugger.LogFmt('Enter CnIDEEnableKibitzing. AParam is %8.8x', [AParam]);
  Symbols := nil;
  Unknowns := nil;
  try
    // ������ʱ�ڴ�
    GetMem(Symbols, csMaxSymbolCount * SizeOf(Integer));
    GetMem(Unknowns, csMaxSymbolCount * SizeOf(Byte));

    // ȡ����Ч�ķ��ű�����
    SymbolCount := KibitzGetValidSymbols(AParam, Symbols, Unknowns, csMaxSymbolCount);
    CnDebugger.LogFmt('Enter CnIDEEnableKibitzing. SymbolCount is %d', [SymbolCount]);

    // ��÷�����
    for I := 0 to SymbolCount - 1 do
    begin
      CppGetSymbolText(Symbols^[I], @(Text[0]), 1);  // 0 �������֣�8�������ͣ�1��������Ҫ��
      CnDebugger.LogFmt('TCnTestBCBSymbolWizard, Get Symbol %d, %s', [I, Text]);
    end;

    // Ȼ��Hook��GetValidSymbol����ֹ���������Զ����
    if KibitzGetValidSymbolsHook = nil then
      KibitzGetValidSymbolsHook := TCnMethodHook.Create(@KibitzGetValidSymbols, @FakeKibitzGetValidSymbols)
    else
      KibitzGetValidSymbolsHook.HookMethod;
  finally
    if Unknowns <> nil then
      FreeMem(Unknowns);
    if Symbols <> nil then
      FreeMem(Symbols);
  end;

  if Assigned(IDEEnableKibitzing) then
  begin
    IDEEnableKibitzingHook.UnhookMethod;
    IDEEnableKibitzing(AParam);
  end;
end;


//==============================================================================
// ���� BCB IDE �����б�Ĳ˵�ר�� �˵�ר��
//==============================================================================

{ TCnTestBCBSymbolWizard }

procedure TCnTestBCBSymbolWizard.Config;
begin
  ShowMessage('No option for this test case.');
end;

constructor TCnTestBCBSymbolWizard.Create;
begin
  inherited;
  KibitzEnabled := KibitzInitialize;
end;

destructor TCnTestBCBSymbolWizard.Destroy;
begin
  KibitzFinalize;
  inherited;
end;

procedure TCnTestBCBSymbolWizard.Execute;
var
  KibitzResult: TKibitzResult;
  CharPos: TOTACharPos;
  Offset: Integer;
  EditControl: TControl;
  IsC: Integer;
begin
  if not KibitzEnabled then
  begin
    ShowMessage('Kibitz NOT Enabled. Can NOT Get Symbols.');
    Exit;
  end;

  FillChar(KibitzResult, SizeOf(KibitzResult), 0);
  CharPos := CnOtaGetCurrCharPos(nil);
  Offset := 0;

  // CodeCompletionManager ȫ��ʵ���п���û�е�ǰEditControl��ֵ������
  EditControl := CnOtaGetCurrentEditControl;
  (PInteger(GlobalCodeCompletionManager + SizeOf(Integer)))^ := Integer(EditControl);

  // CodeCompletionManager ȫ��ʵ���п���û�е�ǰ�ļ���Cpp�ı�ǣ�Ҳ����
  if CurrentIsCSource then
  begin
    IsC := (PInteger(GlobalCodeCompletionManager + $C8))^;
    IsC := IsC or 1;
    (PInteger(GlobalCodeCompletionManager + $C8))^ := IsC;
  end;

  IDEEnableKibitzingRun := False;
  if IDEEnableKibitzingHook = nil then
    IDEEnableKibitzingHook := TCnMethodHook.Create(@IDEEnableKibitzing, @CnIDEEnableKibitzing)
  else
    IDEEnableKibitzingHook.HookMethod;

  // ִ�з�����Ϣ���룬�ڱ�Hook�Ĺ������õ������б�
  GetKibitzInfo(GlobalCodeCompletionManager, CharPos.CharIndex + Offset,
    CharPos.Line, KibitzResult);
  IDEEnableKibitzingHook.UnhookMethod;
  IDEEnableKibitzingRun := False;

  if KibitzGetValidSymbolsHook = nil then
    KibitzGetValidSymbolsHook := TCnMethodHook.Create(@KibitzGetValidSymbols, @FakeKibitzGetValidSymbols);
  KibitzGetValidSymbolsHook.UnhookMethod; // �ñ����εĻָ�����
end;

function TCnTestBCBSymbolWizard.GetCaption: string;
begin
  Result := 'Test BCB IDE Symbol';
end;

function TCnTestBCBSymbolWizard.GetDefShortCut: TShortCut;
begin
  Result := 0;
end;

function TCnTestBCBSymbolWizard.GetHasConfig: Boolean;
begin
  Result := True;
end;

function TCnTestBCBSymbolWizard.GetHint: string;
begin
  Result := 'Test Hint';
end;

function TCnTestBCBSymbolWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

class procedure TCnTestBCBSymbolWizard.GetWizardInfo(var Name, Author, Email, Comment: string);
begin
  Name := 'Test BCB IDE Symbols Menu Wizard';
  Author := 'Liu Xiao';
  Email := 'master@cnpack.org';
  Comment := 'Test for BCB IDE Symbols';
end;

procedure TCnTestBCBSymbolWizard.LoadSettings(Ini: TCustomIniFile);
begin

end;

procedure TCnTestBCBSymbolWizard.SaveSettings(Ini: TCustomIniFile);
begin

end;

initialization
{$IFDEF BCB6}
  RegisterCnWizard(TCnTestBCBSymbolWizard); // BCB6��ע��˲���ר�ң���δ���Թ�
{$ELSE}
  {$IFDEF BCB5}
  RegisterCnWizard(TCnTestBCBSymbolWizard); // BCB5��ע��˲���ר��
  {$ENDIF}
{$ENDIF}

end.
