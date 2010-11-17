{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     �й����Լ��Ŀ���Դ�������������                         }
{                   (C)Copyright 2001-2010 CnPack ������                       }
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

unit CnScript_RegExpr;
{ |<PRE>
================================================================================
* �������ƣ�CnPack IDE ר�Ұ�
* ��Ԫ���ƣ��ű���չ RegExpr ע����
* ��Ԫ���ߣ��ܾ��� (zjy@cnpack.org)
* ��    ע���õ�Ԫ�� UnitParser v0.7 �Զ����ɵ��ļ��޸Ķ���
* ����ƽ̨��PWinXP SP2 + Delphi 5.01
* ���ݲ��ԣ�PWin9X/2000/XP + Delphi 5/6/7
* �� �� �����ô����е��ַ���֧�ֱ��ػ�������ʽ
* ��Ԫ��ʶ��$Id: CnScript_CnWizIdeUtils.pas 418 2010-02-08 04:53:54Z zhoujingyu $
* �޸ļ�¼��2010.05.11 V1.0
*               ������Ԫ
================================================================================
|</PRE>}

interface

{$I CnWizards.inc}

{$DEFINE UniCode}

uses
  Windows, SysUtils, Classes, RegExpr, uPSComponent, uPSRuntime, uPSCompiler;

type

  TPSImport_RegExpr = class(TPSPlugin)
  public
    procedure CompileImport1(CompExec: TPSScript); override;
    procedure ExecImport1(CompExec: TPSScript; const ri: TPSRuntimeClassImporter); override;
  end;

{ compile-time registration functions }
procedure SIRegister_RegExpr(CL: TPSPascalCompiler);

{ run-time registration functions }
procedure RIRegister_RegExpr_Routines(S: TPSExec);

implementation

(* === compile-time registration functions === *)
(*----------------------------------------------------------------------------*)
procedure SIRegister_RegExpr(CL: TPSPascalCompiler);
begin
{$IFDEF UniCode}
  CL.AddTypeS('RegExprString', 'WideString');
{$ELSE}
  CL.AddTypeS('RegExprString', 'AnsiString');
{$ENDIF}
  CL.AddDelphiFunction('Function ExecRegExpr( const ARegExpr, AInputStr : RegExprString) : boolean');
  CL.AddDelphiFunction('Procedure SplitRegExpr( const ARegExpr, AInputStr : RegExprString; APieces : TStrings)');
  CL.AddDelphiFunction('Function ReplaceRegExpr( const ARegExpr, AInputStr, AReplaceStr : RegExprString; AUseSubstitution : boolean) : RegExprString');
  CL.AddDelphiFunction('Function QuoteRegExprMetaChars( const AStr : RegExprString) : RegExprString');
  CL.AddDelphiFunction('Function RegExprSubExpressions( const ARegExpr : string; ASubExprs : TStrings; AExtendedSyntax : boolean) : integer');
end;

(* === run-time registration functions === *)
(*----------------------------------------------------------------------------*)
procedure RIRegister_RegExpr_Routines(S: TPSExec);
begin
  S.RegisterDelphiFunction(@ExecRegExpr, 'ExecRegExpr', cdRegister);
  S.RegisterDelphiFunction(@SplitRegExpr, 'SplitRegExpr', cdRegister);
  S.RegisterDelphiFunction(@ReplaceRegExpr, 'ReplaceRegExpr', cdRegister);
  S.RegisterDelphiFunction(@QuoteRegExprMetaChars, 'QuoteRegExprMetaChars', cdRegister);
  S.RegisterDelphiFunction(@RegExprSubExpressions, 'RegExprSubExpressions', cdRegister);
end;

 
 
{ TPSImport_RegExpr }
(*----------------------------------------------------------------------------*)
procedure TPSImport_RegExpr.CompileImport1(CompExec: TPSScript);
begin
  SIRegister_RegExpr(CompExec.Comp);
end;
(*----------------------------------------------------------------------------*)
procedure TPSImport_RegExpr.ExecImport1(CompExec: TPSScript; const ri: TPSRuntimeClassImporter);
begin
  RIRegister_RegExpr_Routines(CompExec.Exec); // comment it if no routines
end;
(*----------------------------------------------------------------------------*)

end.
