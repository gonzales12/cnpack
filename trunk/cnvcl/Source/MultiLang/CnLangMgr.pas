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

unit CnLangMgr;
{* |<PRE>
================================================================================
* �������ƣ�CnPack �����
* ��Ԫ���ƣ���������������൥Ԫ
* ��Ԫ���ߣ�CnPack������ ��Х (liuxiao@cnpack.org)
* ��    ע���õ�Ԫ�����˶��������������
* ����ƽ̨��PWin2000 + Delphi 5.0
* ���ݲ��ԣ�PWin9X/2000/XP + Delphi 5/6/7
* �� �� �����õ�Ԫ�е��ַ��������ϱ��ػ�������ʽ
* ��Ԫ��ʶ��$Id$
* �޸ļ�¼��2009.08.18 V1.5
*               ���ַ�������ע�����������������������
*           2009.07.15 V1.5
*               �޸���Դ�ַ��������洢���ƣ�ֱ�ӱ����� PResStringRec��Identifier
*               �У��ɷ���ʱͳһ�Ķ������ҽ��Լ������⡣
*           2009.07.11 V1.4
*               �����ַ���������ע����ƣ�ע���˵��ַ������ڸı�����ʱ���Զ�����
*               ���������¼����ֹ����� TranslateStr����Դ�ַ������Զ�����Ҳ��ͨ
*               ���ҽ� LoadResString ��ɡ�
*           2008.05.30 V1.3
*               ������ֻ���� string ���ԣ�����ĳ Tag ֵ������Ļ���
*           2007.09.18 V1.10
*               ���ӷ����¼��Ա����û������Ƿ���ĳЩ��������ԡ�
*           2006.08.21 V1.9
*               �����ֹ��������������ʱδ�ͷŵ����⡣
*           2006.08.19 V1.8
*               �޸�Ϊ������ʵ������ȫ�ֺ���ֻ���ص�һ��ʵ����
*           2006.08.17 V1.7
*               �����ַ������鷭�뺯����
*           2005.04.02 V1.6
*               ���ݴ޶�ΰ�Ľ��飬�ϲ� AList ��ʹ���Ա���ѭ�����á�
*           2004.10.25 V1.5
*               ���ӻ����ַ������������ķ���ģʽ��
*           2004.07.16 V1.4
*               ���ӵ�������ĳһ Component �Ĺ��ܣ���������ڲ����з��룬
*               ���������� IDE �������ǲ��ã�
*           2004.07.12 V1.3
*               ���г��������ܲ��ԣ�ȷ�� List ��ʹ��δ���������Ŀ���
*           2004.06.01 V1.2
*               �޸Ķ� Form �Ĵ����������� Form �� Parent �Ƿ�Ϊ nil ��
*           2003.12.10 V1.1
*               ���Ӷ�����Ķ��⴦��
*           2003.08.20 V1.0
*               ������Ԫ��ʵ�ֹ���
================================================================================
|</PRE>}

interface

{$I CnPack.inc}

{$UNDEF DEBUG}

uses
  SysUtils, Classes, Graphics, TypInfo, Windows, Forms, ComCtrls, ActnList,
  Dialogs, ExtCtrls, Controls, Contnrs, {$IFDEF COMPILER6_UP}Variants, {$ENDIF}
  CnConsts, CnClasses, CnCommon, CnLangStorage, CnIniStrUtils;

const
  CN_MULTI_LANG_TAG_NOT_TRANSLATE = 2001;
  {* ��� Tag ֵΪ��ֵʱ��������}

type
  ECnLanguageManagerError = class(Exception);

  PCnLangChangedNotifierRecord = ^TCnLangChangedNotifierRecord;
  TCnLangChangedNotifierRecord = record
    Notifier: TMethod;
  end;

  TCnAutoTransOption = (atApplication, atForms, atDataModules);
  TCnAutoTransOptions = set of TCnAutoTransOption;

  TCnTranslationMode = (tmByComponents, tmByStrings);
  {* ����ģʽ�����ݴ���Ϳؼ��ȱ������Ǹ��ݷ����ַ������ݱ��� }

  TCnStringObj = class
  {* ����һ�Զ�������ַ���}
  private
    FStringAddr: Pointer;
    FStringName: WideString;
    FIsWide: Boolean;
  public
    property StringAddr: Pointer read FStringAddr write FStringAddr;
    property StringName: WideString read FStringName write FStringName;
    property IsWide: Boolean read FIsWide write FIsWide;
  end;

  TCnResourceStringObj = class
  {* ����һ�Զ��������Դ�ַ���}
  private
    FStringRecAddr: Pointer;
    FStringName: WideString;
    FDstStr: WideString;
  public
    property StringRecAddr: Pointer read FStringRecAddr write FStringRecAddr;
    property StringName: WideString read FStringName write FStringName;
  end;

  TCnBaseLangManager = class(TCnComponent)
  {* �����Թ������� }
  private
    FDefaultLanguageIndex: Integer;
    FCurrentLanguageIndex: Integer;
    FOnStorageChanged: TNotifyEvent;
    FOnLanguageChanged: TNotifyEvent;
    FAutoTranslateStrings: Boolean;
    procedure SetLanguageStorage(Value: TCnCustomLangStorage);
    procedure AdjustNewLanguage(AID: LongWord);
    function GetCurrentLanguageIndex: Integer;
  protected
    FLanguageStorage: TCnCustomLangStorage;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
    procedure DoStorageChanged; virtual;
    procedure DoLanguageChanged; virtual;
    procedure SetCurrentLanguageIndex(const Value: Integer); virtual;

    procedure GetComponentInfo(var AName, Author, Email, Comment: string); override;
  public
    constructor Create(AOwner: TComponent); override;
    {* ���췽�� }
    destructor Destroy; override;
    {* ���ٷ��� }
    function Translate(Src: WideString): WideString;
    {* ���ݵ�ǰ���Ի�÷�����ַ��� }
    function TranslateString(Src: WideString): WideString;
    {* ���ݵ�ǰ���Ի�÷�����ַ��������򷵻ؿ� }
    function TranslateStrFmt(Src: WideString; Args: array of const): WideString;
    {* ���ݵ�ǰ���Ի�ø�ʽ���ķ����ַ��� }

    property AutoTranslateStrings: Boolean read FAutoTranslateStrings
      write FAutoTranslateStrings default True;
    {* �Ƿ������Ըı�ʱ�Զ������Ѿ�ע���˵��ַ�������Դ�ַ�����Ĭ��Ϊ True}

    property LanguageStorage: TCnCustomLangStorage read FLanguageStorage
      write SetLanguageStorage;
    {* �����Դ洢Ԫ������ }
    property CurrentLanguageIndex: Integer read GetCurrentLanguageIndex
      write SetCurrentLanguageIndex default -1;
    {* ��ǰ���Ժţ�Ӱ�쵽����������������á����Ժź����ɴ洢Ԫ����Ŀ���ݾ��� }
    property OnStorageChanged: TNotifyEvent read FOnStorageChanged
      write FOnStorageChanged;
    {* �洢Ԫ�����øı�ʱ���� }
    property OnLanguageChanged: TNotifyEvent read FOnLanguageChanged
      write FOnLanguageChanged;
    {* ��ǰ���Է����ı�ʱ���� }
  end;
  
  TCnTranslateObjectEvent = procedure (AObject: TObject; var Translate: Boolean) of object;
  {* ����һ����ʱ���¼�ԭ�� }

  TCnTranslateObjectPropertyEvent = procedure (AObject: TObject; const PropName: string;
    var Translate: Boolean) of object;
  {* ����һ������ĳ������ʱ���¼�ԭ�� }
    
  TCnCustomLangManager = class(TCnBaseLangManager)
  {* ���з��봰�������Ķ����Թ����� }
  private
    FNotifier: TList;
    FAutoTranslate: Boolean;
    FTranslateTreeNode: Boolean;
    FTranslateListItem: Boolean;
    FUseDefaultFont: Boolean;
    FTranslateOtherFont: Boolean;
    FAutoTransOptions: TCnAutoTransOptions;
    FTranslationMode: TCnTranslationMode;
    FOldTransForms: TList;
    FOldTransDMs: TList;
    FOldFormPrefix: WideString;
    FOldDMPrefix: WideString;
    FIgnoreAction: Boolean;
    FOnTranslateObjectProperty: TCnTranslateObjectPropertyEvent;
    FOnTranslateObject: TCnTranslateObjectEvent;
    procedure SetTranslationMode(const Value: TCnTranslationMode);
  protected
    procedure TranslateRecurComponent(AComponent: TComponent;
      AList: TList; const BaseName: WideString); virtual;
    {* �ݹ鷭��һ Component ���� Children }
    procedure TranslateRecurObject(AObject: TObject; AList: TList;
      const BaseName: WideString = ''); virtual;
    {* �ݹ鷭��һ Object ���������е� Object }
    function GetRecurOwner(AComponent: TComponent): WideString;
    {* ���ݻ��һ Component �����ȱ�ʶ�ַ��� }
    procedure TranslateKeyToValue(const Key, Value: WideString);
    {* ���뼶�����ַ��� }
    procedure SetCurrentLanguageIndex(const Value: Integer); override;
    procedure DoLanguageChanged; override;
    function DoTranslateObject(AObject: TObject): Boolean; virtual;
    function DoTranslateObjectProperty(AObject: TObject;
      const PropName: WideString): Boolean; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AddChangeNotifier(Notify: TNotifyEvent);
    {* �������Ըı�ʱ���¼�֪ͨ }
    procedure RemoveChangeNotifier(Notify: TNotifyEvent);
    {* ɾ�����Ըı�ʱ���¼�֪ͨ }
    procedure TranslateComponent(AComponent: TComponent; const BaseName: WideString = '');
    {* ����һ��Ԫ�������Ӷ���������� }
    procedure TranslateForm(AForm: TCustomForm);
    {* ����һ�� Form �����Ӷ���������� }
    procedure TranslateObject(AObject: TObject; const BaseName: WideString = '');
    {* ����һ���������Ӷ���������� }
    property AutoTranslate: Boolean read FAutoTranslate
      write FAutoTranslate default True;
    {* �Ƿ��ڵ�ǰ���ԺŸı���Զ����������Ѿ����ڵĴ������������ }
    property TranslationMode: TCnTranslationMode read FTranslationMode
       write SetTranslationMode;
    {* ����ģʽ��Ĭ�ϸ��ݴ���Ϳؼ��ȱ��� }
    property AutoTransOptions: TCnAutoTransOptions read FAutoTransOptions
      write FAutoTransOptions;
    {* �Զ�����ѡ������Ƿ��봰�塢����ģ��� Application ʵ�� }
    property TranslateListItem: Boolean read FTranslateListItem
      write FTranslateListItem default False;
    {* �Ƿ��� ListView �е� ListItem }
    property TranslateTreeNode: Boolean read FTranslateTreeNode
      write FTranslateTreeNode default False;
    {* �Ƿ��� TreeView �е� TreeNode }
    property UseDefaultFont: Boolean read FUseDefaultFont
      write FUseDefaultFont default True;
    {* �Ƿ����괰���ʹ�� DefaultFont �����ô������� }
    property TranslateOtherFont: Boolean read FTranslateOtherFont
      write FTranslateOtherFont default True;
    {* �Ƿ������� Font ���Է�����ַ��� }
    property IgnoreAction: Boolean read FIgnoreAction
      write FIgnoreAction default True;
    {* �Ƿ��� Action ���Բ�Ϊ�յĿؼ��� Caption �� Hint ����}
    property OnTranslateObject: TCnTranslateObjectEvent read FOnTranslateObject
      write FOnTranslateObject;
    {* ����һ����ʱ���¼� }
    property OnTranslateObjectProperty: TCnTranslateObjectPropertyEvent
      read FOnTranslateObjectProperty write FOnTranslateObjectProperty;
    {* ����һ�����ĳ������ʱ���¼� }
  end;

  TCnLangManager = class(TCnCustomLangManager)
  {* ���д��巭�������Ķ����Թ����� }
  published
    property LanguageStorage;
    {* �����Դ洢Ԫ������ }
    property CurrentLanguageIndex;
    {* ��ǰ���Ժţ�Ӱ�쵽����������������á����Ժź����ɴ洢Ԫ����Ŀ���ݾ��� }
    property AutoTranslate;
    {* �Ƿ��ڵ�ǰ���ԺŸı���Զ������Ѿ����ڵĴ������������ }
    property AutoTranslateStrings;
    {* �Ƿ������Ըı�ʱ�Զ������Ѿ�ע���˵��ַ�������Դ�ַ�����Ĭ��Ϊ True}
    property TranslationMode;
    {* ����ģʽ��Ĭ�ϸ��ݴ���Ϳؼ��ȱ��� }
    property AutoTransOptions;
    {* �Զ�����ѡ������Ƿ��봰�塢����ģ��� Application ʵ�� }
    property TranslateListItem;
    {* �Ƿ��� ListView �е� ListItem }
    property TranslateTreeNode;
    {* �Ƿ��� TreeView �е� TreeNode  }
    property UseDefaultFont;
    {* �Ƿ����괰���ʹ�� DefaultFont �����ô������� }
    property TranslateOtherFont;
    {* �Ƿ������� Font ���Է�����ַ��� }
    property IgnoreAction;
    {* �Ƿ��� Action ���Բ�Ϊ�յĿؼ��� Caption �� Hint ����}
    property OnStorageChanged;
    {* �洢Ԫ�����øı�ʱ���� }
    property OnLanguageChanged;
    {* ��ǰ���Է����ı�ʱ���� }
    property OnTranslateObject;
    {* ����һ����ʱ���¼� }
    property OnTranslateObjectProperty;
    {* ����һ�����ĳ������ʱ���¼� }
  end;

function CnLanguageManager: TCnCustomLangManager;
{* ȫ�ֺ��������ڷ��ض����Թ�������ʵ�� }

procedure CreateLanguageManager(AOwner: TComponent = nil);
{* ���������Թ����������ڷǿ��ӻ����ֹ����������Թ������ĳ��� }

function GetPropName(Instance: TObject; Index: Integer): WideString;
{* ���ĳ����ĵ� n �� published �������� }

function GetValueByTransName(Owner: TComponent; const Name: WideString): WideString;
{* ��ü����ַ���������ֵ }

procedure SetValueByTransName(Owner: TComponent; const Name, Value: WideString);
{* ���ü����ַ���������ֵ }

procedure TranslateStr(var SrcStr: string; const IDStr: string); overload;
procedure TranslateStr(var SrcStr: WideString; const IDStr: WideString); overload;
{* ����ĳ���ַ��������޷���������򲻴��ڷ�������Ŀ���� SrcStr ���ֲ��� }

procedure TranslateStrArray(var StrArray: array of string; const IDStr: string);
procedure TranslateWideStrArray(var StrArray: array of WideString; const IDStr: WideString);
{* ����ĳ���ַ������� }

procedure RegisterTranslateString(const StringAddr: PAnsiString; const IDStr: WideString); overload;
procedure RegisterTranslateString(const StringAddr: PWideString; const IDStr: WideString); overload;
{* ע��һ�ַ����������ַ�����ƣ��������Ըı�ʱ���Զ����룬�����ֹ��� Translate}

procedure RegisterTranslateResourceString(const ResStringAddr: Pointer; const IDStr: WideString);
{* ע��һ��Դ�ַ����������ַ�����ƣ��������Ըı�ʱ���Զ�����}

procedure TranslateReggedStrings;
{* ����ע���˵��ַ�������Դ�ַ�������������������Ըı����Զ�����
   ���￪�ų�������Ҫ�ֹ����õĳ��ϣ����ʼ���˶����������δ�ı����Եĳ���}

implementation

uses
{$IFDEF DEBUG}
  CnDebug,
{$ENDIF DEBUG}
  CnLangConsts;

type
  TCnIterateByTransName = (itGet, itSet);

var
  FLangMgrList: TList = nil;

  FRegStrings: TObjectList;
  FRegResStrings: TObjectList;

// ʹ�����ж��������ʵ���еĵ�һ����Ϊȫ�ַ��ص�ʵ��
function CnLanguageManager: TCnCustomLangManager;
var
  I: Integer;
begin
  Result := nil;
  if (FLangMgrList <> nil) and (FLangMgrList.Count > 0) then
    for I := 0 to FLangMgrList.Count - 1 do
      if TObject(FLangMgrList.Items[I]) is TCnCustomLangManager then
      begin
        Result := TObject(FLangMgrList.Items[I]) as TCnCustomLangManager;
        Exit;
      end;
end;

procedure CreateLanguageManager(AOwner: TComponent);
begin
  if CnLanguageManager = nil then
    TCnLangManager.Create(AOwner);
end;

procedure TranslateStr(var SrcStr: string; const IDStr: string);
var
  DstStr: WideString;
begin
  if CnLanguageManager <> nil then
  begin
    DstStr := CnLanguageManager.Translate(IDStr);
    if DstStr <> '' then
      SrcStr := DstStr;
  end;
end;

procedure TranslateStr(var SrcStr: WideString; const IDStr: WideString);
var
  DstStr: WideString;
begin
  if CnLanguageManager <> nil then
  begin
    DstStr := CnLanguageManager.Translate(IDStr);
    if DstStr <> '' then
      SrcStr := DstStr;
  end;
end;

procedure TranslateStrArray(var StrArray: array of string; const IDStr: string);
var
  I: Integer;
  DstStr: WideString;
begin
  if CnLanguageManager <> nil then
  begin
    for I := Low(StrArray) to High(StrArray) do
    begin
      DstStr := CnLanguageManager.Translate(IDStr + IntToStr(I));
      if DstStr <> '' then
        StrArray[I] := DstStr;
    end;
  end;
end;

procedure TranslateWideStrArray(var StrArray: array of WideString; const IDStr: WideString);
var
  I: Integer;
  DstStr: WideString;
begin
  if CnLanguageManager <> nil then
  begin
    for I := Low(StrArray) to High(StrArray) do
    begin
      DstStr := CnLanguageManager.Translate(IDStr + IntToStr(I));
      if DstStr <> '' then
        StrArray[I] := DstStr;
    end;
  end;
end;

//==============================================================================
// TCnBaseLangManager
//==============================================================================

procedure TCnBaseLangManager.AdjustNewLanguage(AID: LongWord);
var
  i: Integer;
begin
  if AID = 0 then
    AID := GetSystemDefaultLangID;
  if Assigned(FLanguageStorage) then
    for i := 0 to FLanguageStorage.LanguageCount - 1 do
      if FLanguageStorage.Languages.Items[i].LanguageID = AID then
      begin
        CurrentLanguageIndex := i;
        Exit;
      end;
end;

constructor TCnBaseLangManager.Create(AOwner: TComponent);
var
  i: Integer;
begin
  inherited;

  if FLangMgrList = nil then
    FLangMgrList := TList.Create;

  FLangMgrList.Add(Self);

  FDefaultLanguageIndex := -1;
  FCurrentLanguageIndex := -1;

  FAutoTranslateStrings := True;

  if (csDesigning in ComponentState) then
    for I := 0 to AOwner.ComponentCount - 1 do
      if AOwner.Components[i] is TCnCustomLangFileStorage then
      begin
        LanguageStorage := AOwner.Components[i] as TCnCustomLangFileStorage;
        Exit;
      end;
end;

destructor TCnBaseLangManager.Destroy;
begin
  FLangMgrList.Remove(Self);
  inherited;
end;

procedure TCnBaseLangManager.DoLanguageChanged;
begin
  if FAutoTranslateStrings then
    TranslateReggedStrings;

  if Assigned(FOnLanguageChanged) then
    FOnLanguageChanged(Self);
end;

procedure TCnBaseLangManager.DoStorageChanged;
begin
  if Assigned(FOnStorageChanged) then
    FOnStorageChanged(Self);
end;

function TCnBaseLangManager.GetCurrentLanguageIndex: Integer;
begin
  Result := FCurrentLanguageIndex;
end;

procedure TCnBaseLangManager.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(aComponent, Operation);
  if (Operation = opRemove) and (AComponent = FLanguageStorage) then
    FLanguageStorage := nil;
end;

procedure TCnBaseLangManager.SetCurrentLanguageIndex(
  const Value: Integer);
begin
  FCurrentLanguageIndex := Value;
  if Assigned(FLanguageStorage) then
    if (Value >= 0) and (Value < FLanguageStorage.LanguageCount) then
    begin
      FLanguageStorage.CurrentLanguageIndex := Value;
      DoLanguageChanged;
    end;
end;

procedure TCnBaseLangManager.SetLanguageStorage(Value:
  TCnCustomLangStorage);
var
  AID: LongWord;
begin
  if Value <> FLanguageStorage then
  begin
    if Assigned(FLanguageStorage) then
      FLanguageStorage.RemoveFreeNotification(Self);

    FLanguageStorage := Value;
    if (Value <> nil) and (FCurrentLanguageIndex <> -1) then
      if FCurrentLanguageIndex <> FLanguageStorage.CurrentLanguageIndex then
         FLanguageStorage.CurrentLanguageIndex := FCurrentLanguageIndex;

    if Assigned(Value) then
      Value.FreeNotification(Self);
    if FLanguageStorage.CurrentLanguage <> nil then
    begin
      AID := FLanguageStorage.CurrentLanguage.LanguageID;
      AdjustNewLanguage(AID);
    end;
    DoStorageChanged;
  end;
end;

function TCnBaseLangManager.Translate(Src: WideString): WideString;
begin
  Result := TranslateString(Src);
end;

function TCnBaseLangManager.TranslateString(Src: WideString): WideString;
begin
  if FLanguageStorage <> nil then
  begin
    if CurrentLanguageIndex <> FLanguageStorage.CurrentLanguageIndex then
      FLanguageStorage.CurrentLanguageIndex := CurrentLanguageIndex;
    FLanguageStorage.GetString(Src, Result);
  end
  else
    Result := '';
end;

function TCnBaseLangManager.TranslateStrFmt(Src: WideString; Args:
  array of const): WideString;
begin
{$IFDEF COMPILER6_UP}
  Result := WideFormat(Translate(Src), Args);
{$ELSE}
  // todo: D5 doesn't support WideFormat
  Result := Format(Translate(Src), Args);
{$ENDIF}
end;

function GetPropName(Instance: TObject; Index: Integer): WideString;
var
  PropList: PPropList;
  PropInfo: PPropInfo;
  Data: PTypeData;
begin
  Result := '';
  Data := GetTypeData(Instance.Classinfo);
  GetMem(PropList, Data^.PropCount * Sizeof(PPropInfo));
  try
    GetPropInfos(Instance.ClassInfo, PropList);
    PropInfo := PropList^[Index];
    Result := PropInfoName(PropInfo);
  finally
    FreeMem(PropList, Data^.PropCount * Sizeof(PPropInfo));
  end;
end;

function IterateTransName(Owner: TComponent; const Name, Value: WideString;
  Mode: TCnIterateByTransName): WideString;
var
  S, R, P, Q, Prefix, SubFix: WideString;
  OutS: string;
  I, J, K, OutN: Integer;
  AObject: TObject;
begin
  Result := '';
  if Owner = nil then Exit;

  I := Pos(DefDelimeter, Name);
  if I > 0 then   // I �ǵ�һ��λ��
  begin
    S := Copy(Name, 1, I - 1);
    if S = Owner.ClassName then
    begin
      R := Copy(Name, I + 1, Length(Name) - I); // R �ǵ�һ�����ִ�
      J := Pos(DefDelimeter, R);
      if J > 0 then  // J �ǵڶ���λ��
      begin
        P := Copy(R, 1, J - 1); // P ��ʱ�ǵ�һ�͵ڶ����м���ִ�
        if Owner.FindComponent(P) <> nil then // �ӿؼ�����������
        begin
          Result := VartoStr(GetPropValueIncludeSub(Owner.FindComponent(P),
            Copy(R, J + 1, Length(R) - J)));
          if Mode = itSet then
            SetPropValueIncludeSub(Owner.FindComponent(P), Copy(R, J + 1, Length(R) - J), Value);
        end  // Ȼ��������Ե�����
        else
        begin
          Result := VartoStr(GetPropValueIncludeSub(Owner, Copy(Name, I + 1, Length(Name) - I)));
          if Mode = itSet then
            SetPropValueIncludeSub(Owner, Copy(Name, I + 1, Length(Name) - I), Value);
        end;

        if Result = '' then
        begin
          // ���� Item0 ֮��������
          K := 1;
          while (CharPosWithCounter(DefDelimeter, R, K) <> 0) and
            (CharPosWithCounter(DefDelimeter, R, K + 1) <> 0) do
          begin
            Q := Copy(R, CharPosWithCounter(DefDelimeter, R, K) + 1,
              CharPosWithCounter(DefDelimeter, R, K + 1) - CharPosWithCounter(DefDelimeter, R, K) - 1);
            SeparateStrAndNum(Q, OutS, OutN);
            if (OutN = -1) or ((OutS <> 'Item') and (OutS <> 'ListItem')
              and (OutS <> 'TreeNode')) then
            begin
              Inc(K);
              Continue;
            end;

            Prefix := Copy(R, 1, CharPosWithCounter(DefDelimeter, R, K) - 1);
            Subfix := Copy(R, CharPosWithCounter(DefDelimeter, R, K + 1) + 1,
              Length(R) - CharPosWithCounter(DefDelimeter, R, K + 1));
            // Prefix �� Listview1 ��ʽ���ַ���
            AObject := Owner.FindComponent(P); // ���ҵ��ӿؼ�������ֱ���� ListView1
            try
              if Prefix <> P then // ˵�� Prefix ������
                AObject := TObject(Integer(GetPropValueIncludeSub(AObject,
                  Copy(Prefix, CharPosWithCounter(DefDelimeter, R) + 1,
                  Length(Prefix) - CharPosWithCounter(DefDelimeter, R)))));
            except
              Inc(K);
              Continue;
            end;

            if AObject = nil then // �ҵ�������Item0�ĸö���
            begin
              Inc(K);
              Continue;
            end;

            if (AObject is TCollection) and (OutS = 'Item') then
            begin
              if OutN < (AObject as TCollection).Count then
              begin
                if Mode = itGet then
                  Result := VartoStr(GetPropValueIncludeSub((AObject as TCollection).
                    Items[OutN], Subfix));
                if Mode = itSet then
                  SetPropValueIncludeSub((AObject as TCollection).Items[OutN],
                    Subfix, Value);
              end;
            end
            else if (AObject is TListView) and (OutS = 'ListItem') then
            begin
              if OutN < (AObject as TListView).Items.Count then
              begin
                if Subfix = 'Caption' then // ListItem �� Caption ���Բ��� published
                begin
                  if Mode = itGet then
                    Result := (AObject as TListView).Items[OutN].Caption;
                  if Mode = itSet then
                    (AObject as TListView).Items[OutN].Caption := Value;
                end
                else // ���ޱ�Ҫ����Ϊ TListItem �� published ����
                begin
                  if Mode = itGet then
                    Result := VartoStr(GetPropValueIncludeSub((AObject as TListView).
                      Items[OutN], Subfix));
                  if Mode = itSet then
                    SetPropValueIncludeSub((AObject as TListView).Items[OutN],
                      Subfix, Value);
                end;
              end;
            end
            else if (AObject is TTreeView) and (OutS = 'TreeNode') then
            begin
              if OutN < (AObject as TTreeView).Items.Count then
              begin
                if (Subfix = 'Text') then // TreeNode �� Text ���Բ��� published
                begin
                  if Mode = itGet then
                    Result := (AObject as TTreeView).Items[OutN].Text;
                  if Mode = itSet then
                    (AObject as TTreeView).Items[OutN].Text := Value;
                end
                else // ���ޱ�Ҫ����Ϊ TTreeNode �� published ����
                begin
                  if Mode = itGet then
                    Result := VartoStr(GetPropValueIncludeSub((AObject as TTreeView).
                      Items[OutN], Subfix));
                  if Mode = itSet then
                    SetPropValueIncludeSub((AObject as TTreeView).Items[OutN],
                      Subfix, Value);
                end;
              end;
            end;
            Inc(K);
          end;
        end;
      end
      else // ֱ��������
      begin
        if Mode = itGet then
          Result := VartoStr(GetPropValueIncludeSub(Owner, Copy(Name, I + 1, Length(Name) - I)));
        if Mode = itSet then
          SetPropValueIncludeSub(Owner, Copy(Name, I + 1, Length(Name) - I), Value);
      end;
    end
    else if (S = 'Application') and (Owner = Application) then
    begin
      if Mode = itGet then
        Result := VartoStr(GetPropValueIncludeSub(Application,
          Copy(Name, I + 1, Length(Name) - I)));
      if Mode = itSet then
        SetPropValueIncludeSub(Application, Copy(Name, I + 1, Length(Name) - I), Value);
    end
    else
    begin
      if Mode = itGet then
        Result := VartoStr(GetPropValueIncludeSub(Owner.FindComponent(S),
          Copy(Name, I + 1, Length(Name) - I)));
      if Mode = itSet then
        SetPropValueIncludeSub(Owner.FindComponent(S), Copy(Name, I + 1, Length(Name) - I), Value);
    end;
  end;
end;

function GetValueByTransName(Owner: TComponent; const Name: WideString): WideString;
begin
  Result := IterateTransName(Owner, Name, '', itGet);
end;

procedure SetValueByTransName(Owner: TComponent; const Name, Value: WideString);
begin
  IterateTransName(Owner, Name, Value, itSet);
end;

//==============================================================================
// TCnCustomLangManager
//==============================================================================

constructor TCnCustomLangManager.Create;
begin
  inherited;
  FNotifier := TList.Create;
  FAutoTranslate := True;
  FAutoTransOptions := [atApplication, atForms, atDataModules];
  FUseDefaultFont := True;
  FTranslateOtherFont := True;
  FTranslateListItem := False;
  FTranslateTreeNode := False;
  FIgnoreAction := True;
end;

destructor TCnCustomLangManager.Destroy;
var
  i: Integer;
  P: Pointer;
begin
  for i := 0 to FNotifier.Count - 1 do
  begin
    P := FNotifier[i];
    Dispose(P);
  end;
  FreeAndNil(FNotifier);
  
  FreeAndNil(FOldTransForms);
  FreeAndNil(FOldTransDMs);
  inherited Destroy;
end;

procedure TCnCustomLangManager.TranslateComponent(AComponent: TComponent;
  const BaseName: WideString);
var
  List: TList;
  ABaseName, Prefix: WideString;
  Iterator: ICnLangStringIterator;
  AKey, AValue: WideString;
  APos: Integer;
begin
  if (AComponent <> nil) and (AComponent.Tag = CN_MULTI_LANG_TAG_NOT_TRANSLATE) then
    Exit;

  ABaseName := BaseName;
  if ABaseName = '' then
    ABaseName := GetRecurOwner(AComponent);

  if FTranslationMode = tmByComponents then
  begin
    List := TList.Create;
    List.Add(AComponent); // ���������������ֹ���ӿؼ����ö��ظ�����
    try
      if AComponent.ComponentCount > 0 then
        TranslateRecurComponent(AComponent, List, ABaseName)
      else
        TranslateRecurObject(AComponent, List, ABaseName);
    finally
      List.Free;
    end;
  end
  else
  begin
    Iterator := FLanguageStorage.CreateIterator;
    if Iterator <> nil then
    begin
      APos := Pos(DefDelimeter, ABaseName);
      if APos > 0 then
        Prefix := Copy(ABaseName, 1, APos - 1)
      else
        Prefix := ABaseName;

      Iterator.StartIterate(Prefix);
      try
        while not Iterator.Eof do
        begin
          Iterator.GetCurrentKeyValue(AKey, AValue);
          TranslateKeyToValue(AKey, AValue);
          Iterator.Next;
        end;
      finally
        Iterator.EndIterate;
      end;
    end;
  end;
end;

procedure TCnCustomLangManager.TranslateRecurComponent(
  AComponent: TComponent;  AList: TList; const BaseName: WideString);
var
  I: Integer;
  T: TComponent;
  IsInList, IsApplication: Boolean;
begin
{$IFDEF DEBUG}
  CnDebugger.LogEnter('TranslateRecurComponent: ' + BaseName + ' ' + AComponent.Name);
{$ENDIF DEBUG}
  IsApplication := AComponent is TApplication;
  if AComponent <> nil then
  begin
    if AComponent.Tag = CN_MULTI_LANG_TAG_NOT_TRANSLATE then
      Exit;

    TranslateObject(AComponent, BaseName);
    // ʹ�� AList ���������Ժ͸� Component �ظ�
    for I := 0 to AComponent.ComponentCount - 1 do
    begin
      T := AComponent.Components[I];
      if IsApplication and (T is TCustomForm) then
        Continue; // ������ Application ������ Form������ TranslateForm ��������

      if T.Tag = CN_MULTI_LANG_TAG_NOT_TRANSLATE then
        Continue;

      IsInList := AList <> nil;
      if IsInList and (AList.IndexOf(T) = -1) then
      begin
        IsInList := False;
        AList.Add(T);
      end;  // �б�Ϊ nil ʱ���жϣ���Ϊ nil ʱ����Ƿ��Ѱ���

      if not IsInList then            // ������ĳһ Form �� Parent �������2004.06.01 by Passion
      begin
        if (AComponent is TCustomForm) {and ((AComponent as TCustomForm).Parent = nil)} then
          TranslateRecurComponent(T, AList, BaseName)
        else
          TranslateRecurComponent(T, AList, BaseName + DefDelimeter + AComponent.Name);
      end;
    end;
  end;
{$IFDEF DEBUG}
  CnDebugger.LogLeave('TranslateRecurComponent: ' + BaseName + ' ' + AComponent.Name);
{$ENDIF DEBUG}
end;

procedure TCnCustomLangManager.TranslateForm(AForm: TCustomForm);
begin
  LockWindowUpdate(AForm.Handle);
  try
    if FUseDefaultFont and Assigned(FLanguageStorage) then
    begin
      with FLanguageStorage do
      begin
        if FontInited then
        begin
        {$IFDEF DEBUG}
          CnDebugger.LogMsg('LangManager: FontInited. ');
        {$ENDIF DEBUG}
          if CurrentLanguageIndex <> -1 then
          begin
            AForm.Font.Name := DefaultFont.Name;
            AForm.Font.Size := DefaultFont.Size;
            AForm.Font.Charset := DefaultFont.Charset;
          end;
        end;
      end;
    end;
    TranslateComponent(AForm, AForm.ClassName);
  finally
    LockWindowUpdate(0);
  end;
end;

procedure TCnCustomLangManager.TranslateObject(AObject: TObject;
  const BaseName: WideString = '');
var
  AList: TList;
begin
{$IFDEF DEBUG}
  CnDebugger.LogEnter('TranslateObject: ' + BaseName + ' ' + AObject.ClassName);
{$ENDIF DEBUG}
  AList := TList.Create;
  AList.Add(AObject); // ���������������ֹ�����������ö��ظ�����
  try
    if DoTranslateObject(AObject) then
      TranslateRecurObject(AObject, AList, BaseName);
  finally
    AList.Free;
  end;
{$IFDEF DEBUG}
  CnDebugger.LogLeave('TranslateObject: ' + BaseName + ' ' + AObject.ClassName);
{$ENDIF DEBUG}
end;

procedure TCnCustomLangManager.TranslateRecurObject(AObject: TObject;
  AList: TList; const BaseName: WideString);
var
  i: Integer;
  APropName, APropValue, TransStr, AStr: WideString;
  APropType: TTypeKind;
  Data: PTypeData;
  ActionObj, SubObj: TObject;
  AItem: TCollectionItem;
  AListItem: TListItem;
  ATreeNode: TTreeNode;
  IsForm, IsInList: Boolean;
  NeedIgnoreAction: Boolean;
  ActionCaption, ActionHint: WideString;
  Info: PPropInfo;
begin
  if (AObject <> nil) {and (AList <> nil)} and Assigned(FLanguageStorage) then
  begin
    // ���⴫��һЩҰ�˵� AObject ������ѭ�������� IDE �ڲ����ֹ�
    try
      if AObject.ClassType = AObject.ClassParent then
        Exit;
      
      if (AObject.ClassParent <> nil) and (AObject.ClassParent.ClassParent = AObject.ClassType) then
        Exit;
    except
      Exit;
    end;
    
    if (AObject is TCnCustomLangStorage) or (AObject is TCnCustomLangStorage)
      or ((AObject is TComponent) and ((AObject as TComponent).Name = '')) then
        Exit;

    if (AObject is TStrings) then  // Strings�Ķ���ֱ�ӷ��� Text ���ԡ�
    begin
      AStr := 'Text';
      // ���÷���ĳ����ǰ���¼�
      if not DoTranslateObjectProperty(AObject, AStr) then
        Exit;

      if BaseName <> '' then
        AStr := BaseName + DefDelimeter + AStr;

      TransStr := TranslateString(AStr);
      if TransStr <> '' then
        (AObject as TStrings).Text := TransStr;

      Exit;
    end
    else if (AObject is TCollection) then // TCollection ��������� Item
    begin
      for i := 0 to (AObject as TCollection).Count - 1 do
      begin
        AItem := (AObject as TCollection).Items[i];

        IsInList := AList <> nil;
        if IsInList and (AList.IndexOf(AItem) = -1) then
        begin
          IsInList := False;
          AList.Add(AItem);
        end;

        if not IsInList then
        begin
          if BaseName <> '' then
            TranslateRecurObject(AItem, AList, BaseName + DefDelimeter +
              'Item' + InttoStr(i))
          else
            TranslateRecurObject(AItem, AList, 'Item' + InttoStr(i));
        end;
      end;
    end
    // ListView ����Ҫʱ������ Item
    else if FTranslateListItem and (AObject is TListView) then
    begin
      for i := 0 to (AObject as TListView).Items.Count - 1 do
      begin
        AListItem := (AObject as TListView).Items[i];

        IsInList := AList <> nil;
        if IsInList and (AList.IndexOf(AListItem) = -1) then
        begin
          IsInList := False;
          AList.Add(AListItem);
        end;

        if not IsInList then
        begin
          if BaseName <> '' then
            TranslateRecurObject(AListItem, AList, BaseName + DefDelimeter +
              TComponent(AObject).Name + DefDelimeter + 'ListItem' + InttoStr(i))
          else
            TranslateRecurObject(AListItem, AList, TComponent(AObject).Name +
              DefDelimeter + 'ListItem' + InttoStr(i));
        end;
      end;
    end
    // ListItem ������ Caption ���Ժ� SubItems ����
    else if FTranslateListItem and (AObject is TListItem) then
    begin
      AStr := 'Caption';
      // ���÷���ĳ����ǰ���¼�
      if DoTranslateObjectProperty(AObject, AStr) then
      begin
        if BaseName <> '' then
          AStr := BaseName + DefDelimeter + AStr;

        TransStr := TranslateString(AStr);
        if TransStr <> '' then
          (AObject as TListItem).Caption := TransStr;
      end;

      AStr := 'SubItems.Text';
      if BaseName <> '' then
        AStr := BaseName + DefDelimeter + AStr;

      TransStr := TranslateString(AStr);
      if TransStr <> '' then
        (AObject as TListItem).SubItems.Text := TransStr;
      Exit;
    end
    // TreeView ����Ҫʱ������ Item
    else if FTranslateTreeNode and (AObject is TTreeView) then
    begin
      for i := 0 to (AObject as TTreeView).Items.Count - 1 do
      begin
        ATreeNode := (AObject as TTreeView).Items[i];

        IsInList := AList <> nil;
        if IsInList and (AList.IndexOf(ATreeNode) = -1) then
        begin
          IsInList := False;
          AList.Add(ATreeNode);
        end;

        if not IsInList then
        begin
          if BaseName <> '' then
            TranslateRecurObject(ATreeNode, AList, BaseName + DefDelimeter +
              TComponent(AObject).Name + DefDelimeter + 'TreeNode' + InttoStr(i))
          else
            TranslateRecurObject(ATreeNode, AList, TComponent(AObject).Name +
              DefDelimeter + 'TreeNode' + InttoStr(i));
        end;
      end;
    end
    // TreeNode ������ Text ���ԡ�
    else if FTranslateTreeNode and (AObject is TTreeNode) then
    begin
      AStr := 'Text';
      // ���÷���ĳ����ǰ���¼�
      if not DoTranslateObjectProperty(AObject, AStr) then
        Exit;
              
      if BaseName <> '' then
        AStr := BaseName + DefDelimeter + AStr;

      TransStr := TranslateString(AStr);
      if TransStr <> '' then
        (AObject as TTreeNode).Text := TransStr;
      Exit;
    end;

    IsForm := (AObject is TCustomForm) or (AObject is TCustomFrame);
    try
      Data := GetTypeData(AObject.Classinfo);
    except
      Exit; // TChartSeriesList ���ڴ˴����������ò�ץס����
    end;

    NeedIgnoreAction := False;
    if FIgnoreAction then
    begin
      // �����Ƿ��� Action ���ԣ����Ƿ� nil
      for I := 0 to Data^.PropCount - 1 do
      begin
        APropName := GetPropName(AObject, I);
        if (PropType(AObject, APropName) = tkClass) and (APropName = 'Action') then
        begin
          // ���� Action ���ԣ�ΪtkClass
          ActionObj := GetObjectProp(AObject, APropName);
          if (ActionObj <> nil) and (ActionObj is TCustomAction)then
          begin
            // �� Action ���Բ�Ϊ nil �ģ���Ҫ���� Caption �� Hint
            NeedIgnoreAction := True;
            ActionCaption := (ActionObj as TCustomAction).Caption;
            ActionHint := (ActionObj as TCustomAction).Hint;
            Break;
          end;
        end;
      end;
    end;

    for I := 0 to Data^.PropCount - 1 do
    begin
      APropName := GetPropName(AObject, I);
      
      // ������ TComponent �� Name ����
      if (AObject is TComponent) and (APropName = 'Name') then
        Continue;

      // ������ TCnComponent �� About ����
      if (AObject is TCnComponent) and (APropName = 'About') then
        Continue;

      APropType := PropType(AObject, APropName);
      if (APropType in [tkString, tkWChar, tkLString, tkWString
        {$IFDEF UNICODE_STRING}, tkUString{$ENDIF}]) then
      begin
        if NeedIgnoreAction then
        begin
          APropValue := VartoStr(GetPropValue(AObject, APropName));
          if (APropName = 'Caption') and (ActionCaption = APropValue) then
            Continue
          else if (APropName = 'Hint') and (ActionHint = APropValue) then
            Continue;
        end;

        Info := GetPropInfo(AObject, APropName);
        if (Info <> nil) and (Info^.SetProc = nil) then // ֻ������д�ģ��㿪
          Continue;

        // ���÷���ĳ����ǰ���¼�
        if not DoTranslateObjectProperty(AObject, APropName) then
          Continue;

        if IsForm then
          AStr := AObject.ClassName + DefDelimeter + APropName
        else if AObject is TComponent then
          AStr := TComponent(AObject).Name + DefDelimeter + APropName
        else
          AStr := APropName;

        if (BaseName <> '') and not IsForm then
          AStr := BaseName + DefDelimeter + AStr;

        TransStr := TranslateString(AStr);
        if TransStr <> '' then
          SetPropValue(AObject, APropName, TransStr);
      end
      else if APropType = tkClass then
      begin
        SubObj := GetObjectProp(AObject, APropName);
        if SubObj = nil then
          Continue;

        IsInList := AList <> nil;
        if IsInList and (AList.IndexOf(SubObj) = -1) then
        begin
          IsInList := False;
          AList.Add(SubObj);
        end;

        // ���÷���ĳ����ǰ���¼�
        if not DoTranslateObjectProperty(AObject, APropName) then
          Continue;
        
        if AObject is TComponent then // �� Component ����и��ӵĴ���
        begin
          if not IsInList then
          begin
      {* ���Ӷ��������û� Owner �����κοؼ��Ŀؼ����� Owner ѭ���ķ�ʽ���ʲ�����
         ��ֻ���ڴ˴������ؼ���.����������ʽ���ʡ���������������������һ���ؼ�
         ���������ԣ����ӵ������ӿؼ��������ӿؼ��� Owner ���� nil�����ɸ��ؼ���
         �𴴽��ͷš��������ӿؼ�����һ������ָ��Է��������ͻ����ѭ�����ã�����
         ���ǵ�ͨ�� List ��ʽ��������ѭ����  }
            if (AObject is TControl) and (SubObj is TFont) and (APropName = 'Font') then
            begin
              if not IsParentFont(AObject as TControl) then // ��ʹ�� ParentFont ʱ������
              begin
                if not IsForm then
                  AStr := TComponent(AObject).Name + DefDelimeter + SCnControlFont
                else
                  AStr := SCnControlFont;

                if BaseName <> ''  then
                  AStr := BaseName + DefDelimeter + AStr;

                TransStr := TranslateString(AStr);
                if TransStr <> '' then
                  StringToFontEx(TransStr, TCnFontControl(AObject).Font,
                    GetParentFont(AObject as TComponent));
              end;
            end // �������洦�� TControl ������
            else if FTranslateOtherFont and (SubObj is TFont) then
            begin
              if not IsForm then
                AStr := TComponent(AObject).Name + DefDelimeter +
                  SystemNamePrefix + APropName
              else
                AStr := SystemNamePrefix + APropName;

              if BaseName <> ''  then
                AStr := BaseName + DefDelimeter + AStr;

              TransStr := TranslateString(AStr);

              try
                if TransStr <> '' then
                  StringToFontEx(TransStr, SubObj as TFont,
                    GetParentFont(AObject as TComponent));
              except
                ; // ������һ���ϵ��쳣
              end;
            end // �������� Font��
            else if (not (SubObj is TComponent)) or     // ��� SubObj ���� TComponent ��ֻ���ڴ�ͨ�����Ա���
              ((SubObj as TComponent).Owner = nil) then // ��� SubObj �� Owner ��Ϊ nil��������� Owner ����������˵���˴���������
            begin
              if IsForm then
                TranslateRecurObject(SubObj, AList, TComponent(AObject).ClassName
                  + DefDelimeter + APropName)
              else if (InheritsFromClassName(AObject, 'TNotebook') or InheritsFromClassName(AObject, 'TTabbedNotebook'))
                and (APropName = 'Pages') then
              // ������ TNotebook/TTabbedNotebook �� Pages �����������ҳ�����ݶ�ʧ��
              else if InheritsFromClassName(AObject, 'TJvWizard') and (APropName = 'Pages') then
              // ������ JVcl Wizards �� Pages �������� Crash
              else if not (SubObj is TComponent) then
              // �˴�Ӧ���ж� SubObj �Ƿ��� TComponet Ȼ������Ƿ���� TranslateRecurComponent
                TranslateRecurObject(SubObj, AList, BaseName + DefDelimeter +
                  TComponent(AObject).Name + DefDelimeter + APropName)
              else
                TranslateRecurComponent((SubObj as TComponent), AList, BaseName + DefDelimeter +
                  TComponent(AObject).Name + DefDelimeter + APropName)
            end;
          end;
        end
        else // AObject ���� Component ��ֱ�ӷ���������������
        begin
          if not IsInList then
            TranslateRecurObject(SubObj, AList, BaseName + DefDelimeter + APropName);
        end;
      end;
    end;
  end;
end;

procedure TCnCustomLangManager.SetCurrentLanguageIndex(
  const Value: Integer);
var
  I: Integer;
  Iterator: ICnLangStringIterator;
  AKey, AValue: WideString;
begin
  inherited;

  // ����ڲ����з���
  if not (csDesigning in ComponentState) and FAutoTranslate
    and (LanguageStorage <> nil) then
  begin
    if FTranslationMode = tmByComponents then
    begin
      if atForms in FAutoTransOptions then
        for I := 0 to Screen.CustomFormCount - 1 do
          TranslateForm(Screen.CustomForms[I]);

      if atDataModules in FAutoTransOptions then
        for I := 0 to Screen.DataModuleCount - 1 do
          TranslateComponent(Screen.DataModules[I]);

      if atApplication in FAutoTransOptions then
        TranslateComponent(Application);
    end
    else // ���ڷ�����Ŀ
    begin
      Iterator := FLanguageStorage.CreateIterator;
      if Iterator <> nil then
      begin
        Iterator.StartIterate;
        try
          while not Iterator.Eof do
          begin
            Iterator.GetCurrentKeyValue(AKey, AValue);
            TranslateKeyToValue(AKey, AValue);
            Iterator.Next;
          end;
        finally
          Iterator.EndIterate;
        end;
      end;
    end;
  end;
end;

procedure TCnCustomLangManager.AddChangeNotifier(Notify: TNotifyEvent);
var
  P: PCnLangChangedNotifierRecord;
  I: Integer;
  Found: Boolean;
begin
  Found := False;
  for I := 0 to FNotifier.Count - 1 do
    if SameMethod(TMethod(PCnLangChangedNotifierRecord(FNotifier[I])^.Notifier),
      TMethod(Notify)) then
    begin
      Found := True;
      Break;
    end;

  if not Found then
  begin
    New(P);
    P^.Notifier := TMethod(Notify);
    FNotifier.Add(P);
  end;
end;

procedure TCnCustomLangManager.RemoveChangeNotifier(Notify: TNotifyEvent);
var
  P: PCnLangChangedNotifierRecord;
  Idx, I: Integer;
begin
  Idx := -1;
  for I := 0 to FNotifier.Count - 1 do
    if SameMethod(TMethod(PCnLangChangedNotifierRecord(FNotifier[I])^.Notifier),
      TMethod(Notify)) then
    begin
      Idx := I;
      Break;
    end;

  if Idx >= 0 then
  begin
    P := FNotifier[Idx];
    Dispose(P);
    FNotifier.Delete(Idx);
  end;
end;

procedure TCnCustomLangManager.DoLanguageChanged;
var
  I: Integer;
begin
  inherited; // ����Ӧ��������Ըı��¼�����ʵʩ֪ͨ��
  for I := 0 to FNotifier.Count - 1 do
    TNotifyEvent(PCnLangChangedNotifierRecord(FNotifier.Items[I])^.Notifier)(Self);
end;

function TCnCustomLangManager.DoTranslateObject(AObject: TObject): Boolean;
begin
  Result := True;
  if Assigned(FOnTranslateObject) then
    FOnTranslateObject(AObject, Result);
end;

function TCnCustomLangManager.DoTranslateObjectProperty(AObject: TObject;
  const PropName: WideString): Boolean;
begin
  Result := True;
  if Assigned(FOnTranslateObjectProperty) then
    FOnTranslateObjectProperty(AObject, PropName, Result);
end;

function TCnCustomLangManager.GetRecurOwner(AComponent: TComponent): WideString;
begin
  if (AComponent is TCustomForm) or (AComponent is TDataModule) then
    Result := AComponent.ClassName
  else if AComponent.Owner <> nil then
  begin
    if AComponent.Owner is TCustomForm then
      Result := AComponent.Owner.ClassName
    else
      Result := GetRecurOwner(AComponent.Owner) + DefDelimeter + AComponent.Owner.Name;
  end;
end;

procedure TCnCustomLangManager.SetTranslationMode(
  const Value: TCnTranslationMode);
begin
  FTranslationMode := Value;
end;

procedure TCnCustomLangManager.TranslateKeyToValue(const Key,
  Value: WideString);
var
  I, APos: Integer;
  Prefix: WideString;
begin
  if Key = '' then
    Exit;

  APos := Pos(DefDelimeter, Key);
  if APos = 0 then // ������ŵĲ��ڴ˷���
    Exit;

  Prefix := Copy(Key, 1, APos - 1);

  if atForms in FAutoTransOptions then
  begin
    if (Prefix <> FOldFormPrefix) or not Assigned(FOldTransForms) then
    begin
      if not Assigned(FOldTransForms) then
        FOldTransForms := TList.Create
      else
        FOldTransForms.Clear;

      for I := 0 to Screen.CustomFormCount - 1 do
        if Screen.CustomForms[I].ClassNameIs(Prefix) then
          FOldTransForms.Add(Screen.CustomForms[I]);
    end;

    for I := 0 to FOldTransForms.Count - 1 do
      SetValueByTransName(TComponent(FOldTransForms.Items[I]), Key, Value);
  end;

  if atDataModules in FAutoTransOptions then
  begin
    if (Prefix <> FOldDMPrefix) or not Assigned(FOldTransDMs) then
    begin
      if not Assigned(FOldTransDMs) then
        FOldTransDMs := TList.Create
      else
        FOldTransDMs.Clear;

      for I := 0 to Screen.DataModuleCount - 1 do
        if Screen.DataModules[I].ClassNameIs(Prefix) then
          FOldTransDMs.Add(Screen.DataModules[I]);
    end;

    for I := 0 to FOldTransDMs.Count - 1 do
      SetValueByTransName(TComponent(FOldTransDMs.Items[I]), Key, Value);
  end;

  if atApplication in FAutoTransOptions then
    if Prefix = 'Application' then
      SetValueByTransName(Application, Key, Value);
end;

procedure FreeLanguageManagers;
var
  I: Integer;
begin
  if Assigned(FLangMgrList) then
  begin
    if FLangMgrList.Count > 0 then
      for I := FLangMgrList.Count - 1 downto 0 do
        if FLangMgrList.Items[I] <> nil then
          TObject(FLangMgrList.Items[I]).Free;

    FreeAndNil(FLangMgrList);
  end;
end;

procedure TCnBaseLangManager.GetComponentInfo(var AName, Author, Email,
  Comment: string);
begin
  AName := SCnLangMgrName;
  Author := SCnPack_LiuXiao;
  Email := SCnPack_LiuXiaoEmail;
  Comment := SCnLangMgrComment;
end;

procedure RegisterTranslateResourceString(
  const ResStringAddr: Pointer; const IDStr: WideString);
var
  AObj: TCnResourceStringObj;
begin
  if ResStringAddr <> nil then
  begin
    AObj := TCnResourceStringObj.Create;
    AObj.StringRecAddr := ResStringAddr;
    AObj.StringName := IDStr;
    FRegResStrings.Add(AObj);
  end;
end;

procedure RegisterTranslateString(const StringAddr: PAnsiString; const IDStr: WideString);
var
  AObj: TCnStringObj;
begin
  if StringAddr <> nil then
  begin
    AObj := TCnStringObj.Create;
    AObj.StringAddr := StringAddr;
    AObj.StringName := IDStr;
    AObj.IsWide := False;
    FRegStrings.Add(AObj);
  end;
end;

procedure RegisterTranslateString(const StringAddr: PWideString; const IDStr: WideString);
var
  AObj: TCnStringObj;
begin
  if StringAddr <> nil then
  begin
    AObj := TCnStringObj.Create;
    AObj.StringAddr := StringAddr;
    AObj.StringName := IDStr;
    AObj.IsWide := True;
    FRegStrings.Add(AObj);
  end;
end;

procedure TranslateReggedStrings;
var
  I: Integer;
  AObj: TCnStringObj;
  BObj: TCnResourceStringObj;
  DstStr: WideString;
  OldProtect: Cardinal;
begin
  if CnLanguageManager = nil then
    raise Exception.Create('Language Manager NOT initialized.');

  for I := 0 to FRegStrings.Count - 1 do
  begin
    AObj := TCnStringObj(FRegStrings[I]);
    DstStr := CnLanguageManager.TranslateString(AObj.StringName);
    if DstStr <> '' then
    begin
      if AObj.IsWide then
        PWideString(AObj.FStringAddr)^ := DstStr
      else
        PAnsiString(AObj.FStringAddr)^ := DstStr;
    end;
  end;

  for I := 0 to FRegResStrings.Count - 1 do
  begin
    BObj := TCnResourceStringObj(FRegResStrings[I]);
    DstStr := CnLanguageManager.TranslateString(BObj.StringName);
    if DstStr <> '' then
    begin
      BObj.FDstStr := DstStr; // ����һ���ַ�������
      VirtualProtect(BObj.StringRecAddr, SizeOf(TResStringRec), PAGE_EXECUTE_READWRITE, @OldProtect);
      PResStringRec(BObj.StringRecAddr)^.Identifier := Integer(DstStr);
      VirtualProtect(BObj.StringRecAddr, SizeOf(TResStringRec), OldProtect, nil);
    end;
  end;
end;

initialization
  FRegStrings := TObjectList.Create(True);
  FRegResStrings := TObjectList.Create(True);

finalization
  FreeLanguageManagers;
  FRegStrings.Free;
  FRegResStrings.Free;

end.