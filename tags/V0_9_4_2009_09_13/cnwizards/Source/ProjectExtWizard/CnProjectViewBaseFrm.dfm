object CnProjectViewBaseForm: TCnProjectViewBaseForm
  Left = 300
  Top = 150
  AutoScroll = False
  BorderIcons = [biSystemMenu]
  Caption = 'BaseForm'
  ClientHeight = 433
  ClientWidth = 622
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Icon.Data = {
    0000010001001010100000000000280100001600000028000000100000002000
    00000100040000000000C0000000000000000000000000000000000000000000
    000000008000008000000080800080000000800080008080000080808000C0C0
    C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
    00000000000000000000000000000008000000000000000FBFBFBFBF0000000F
    0B00000F0000000FBFBFBFBF0000000F0B00000F0000000FBFBFBFBF0000000F
    0B00000F0000000FBFBFBFBF0000000F0000000F0000000FBFBFBFBF0000000F
    4B444F0F0000000FFFFFFFFF800000000000000000000000000000000000FFFF
    0000FFFF0000E0070000E0070000E0070000E0070000E0070000E0070000E007
    0000E0070000E0070000E0070000E0070000E0070000FFFF0000FFFF0000}
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  Scaled = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnlHeader: TPanel
    Left = 0
    Top = 30
    Width = 622
    Height = 36
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblSearch: TLabel
      Left = 15
      Top = 12
      Width = 42
      Height = 13
      Caption = '查找(&F):'
      FocusControl = edtMatchSearch
    end
    object lblProject: TLabel
      Left = 327
      Top = 12
      Width = 42
      Height = 13
      Caption = '工程(&P):'
      FocusControl = cbbProjectList
    end
    object edtMatchSearch: TEdit
      Left = 71
      Top = 8
      Width = 220
      Height = 21
      TabOrder = 0
      OnChange = edtMatchSearchChange
      OnKeyDown = edtMatchSearchKeyDown
    end
    object cbbProjectList: TComboBox
      Left = 383
      Top = 8
      Width = 220
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 1
      OnChange = cbbProjectListChange
    end
  end
  object lvList: TListView
    Left = 0
    Top = 66
    Width = 622
    Height = 348
    Align = alClient
    AllocBy = 500
    Columns = <
      item
        Caption = '窗体'
        Width = 210
      end
      item
        Caption = '类型'
        Width = 100
      end
      item
        Caption = '工程'
        Width = 140
      end
      item
        Alignment = taRightJustify
        Caption = '大小(Byte)'
        Width = 80
      end
      item
        Caption = '文件类型'
        Width = 72
      end>
    HideSelection = False
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    SmallImages = dmCnSharedImages.Images
    SortType = stText
    TabOrder = 1
    ViewStyle = vsReport
    OnColumnClick = lvListColumnClick
    OnCustomDrawItem = lvListCustomDrawItem
    OnDblClick = lvListDblClick
    OnKeyDown = lvListKeyDown
    OnKeyPress = lvListKeyPress
    OnSelectItem = lvListSelectItem
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 414
    Width = 622
    Height = 19
    AutoHint = True
    Panels = <
      item
        Style = psOwnerDraw
        Width = 340
      end
      item
        Text = '工程总数: 1'
        Width = 110
      end
      item
        Text = '窗体总数: 1'
        Width = 110
      end>
    ParentFont = True
    ParentShowHint = False
    ShowHint = True
    SimplePanel = False
    UseSystemFont = False
  end
  object ToolBar: TToolBar
    Left = 0
    Top = 0
    Width = 622
    Height = 30
    AutoSize = True
    BorderWidth = 1
    EdgeBorders = [ebLeft, ebTop, ebRight, ebBottom]
    Flat = True
    Images = dmCnSharedImages.Images
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
    object btnOpen: TToolButton
      Left = 0
      Top = 0
      Action = actOpen
    end
    object btnSep1: TToolButton
      Left = 23
      Top = 0
      Width = 8
      ImageIndex = 2
      Style = tbsSeparator
    end
    object btnAttribute: TToolButton
      Left = 31
      Top = 0
      Action = actAttribute
    end
    object btnSep3: TToolButton
      Left = 54
      Top = 0
      Width = 8
      ImageIndex = 1
      Style = tbsSeparator
    end
    object btnCopy: TToolButton
      Left = 62
      Top = 0
      Action = actCopy
    end
    object btnSep4: TToolButton
      Left = 85
      Top = 0
      Width = 8
      ImageIndex = 1
      Style = tbsSeparator
    end
    object btnSelectAll: TToolButton
      Left = 93
      Top = 0
      Action = actSelectAll
    end
    object btnSelectNone: TToolButton
      Left = 116
      Top = 0
      Action = actSelectNone
    end
    object btnSelectInvert: TToolButton
      Left = 139
      Top = 0
      Action = actSelectInvert
    end
    object btnSep5: TToolButton
      Left = 162
      Top = 0
      Width = 8
      ImageIndex = 1
      Style = tbsSeparator
    end
    object btnMatchStart: TToolButton
      Left = 170
      Top = 0
      Action = actMatchStart
      Grouped = True
      Style = tbsCheck
    end
    object btnMatchAny: TToolButton
      Left = 193
      Top = 0
      Action = actMatchAny
      Grouped = True
      Style = tbsCheck
    end
    object btnSep6: TToolButton
      Left = 216
      Top = 0
      Width = 8
      ImageIndex = 1
      Style = tbsSeparator
    end
    object btnHookIDE: TToolButton
      Left = 224
      Top = 0
      Action = actHookIDE
      Style = tbsCheck
    end
    object btnQuery: TToolButton
      Left = 247
      Top = 0
      Action = actQuery
      Style = tbsCheck
    end
    object btnFont: TToolButton
      Left = 270
      Top = 0
      Action = actFont
    end
    object btnSep7: TToolButton
      Left = 293
      Top = 0
      Width = 8
      ImageIndex = 1
      Style = tbsSeparator
    end
    object btnHelp: TToolButton
      Left = 301
      Top = 0
      Action = actHelp
    end
    object btnSep8: TToolButton
      Left = 324
      Top = 0
      Width = 8
      ImageIndex = 1
      Style = tbsSeparator
    end
    object btnClose: TToolButton
      Left = 332
      Top = 0
      Action = actClose
    end
  end
  object ActionList: TActionList
    Images = dmCnSharedImages.Images
    OnUpdate = ActionListUpdate
    Left = 15
    Top = 390
    object actOpen: TAction
      Caption = '打开(&O)'
      Hint = '打开所选窗体'
      ImageIndex = 34
      OnExecute = actOpenExecute
    end
    object actAttribute: TAction
      Caption = '属性(&R)'
      Hint = '显示所选窗体文件属性'
      ImageIndex = 19
      OnExecute = actAttributeExecute
    end
    object actCopy: TAction
      Caption = '复制(&C)'
      Hint = '复制所选窗体名到剪贴板'
      ImageIndex = 10
      OnExecute = actCopyExecute
    end
    object actSelectAll: TAction
      Caption = '全部选择(&W)'
      Hint = '选择所有窗体'
      ImageIndex = 61
      OnExecute = actSelectAllExecute
    end
    object actSelectNone: TAction
      Caption = '取消选择(&N)'
      Hint = '取消选择窗体'
      ImageIndex = 62
      OnExecute = actSelectNoneExecute
    end
    object actSelectInvert: TAction
      Caption = '反向选择(&V)'
      Hint = '反向选择窗体'
      ImageIndex = 63
      OnExecute = actSelectInvertExecute
    end
    object actMatchStart: TAction
      Caption = '匹配开头(&S)'
      Hint = '匹配窗体名开头'
      ImageIndex = 27
      OnExecute = actMatchStartExecute
    end
    object actMatchAny: TAction
      Caption = '匹配所有(&A)'
      Hint = '匹配窗体名所有位置'
      ImageIndex = 28
      OnExecute = actMatchAnyExecute
    end
    object actHookIDE: TAction
      Caption = '挂接 IDE(&I)'
      Hint = '挂接工程窗体列表到 IDE'
      ImageIndex = 2
      OnExecute = actHookIDEExecute
    end
    object actQuery: TAction
      Caption = '打开多个窗体提示(&P)'
      Hint = '打开多个窗体时提示'
      ImageIndex = 18
      OnExecute = actQueryExecute
    end
    object actFont: TAction
      Caption = '字体(&F)'
      Hint = '设置字体'
      ImageIndex = 29
      OnExecute = actFontExecute
    end
    object actHelp: TAction
      Caption = '帮助(&H)'
      Hint = '显示帮助'
      ImageIndex = 1
      OnExecute = actHelpExecute
    end
    object actClose: TAction
      Caption = '关闭(&E)'
      Hint = '关闭窗口'
      ImageIndex = 0
      OnExecute = actCloseExecute
    end
  end
  object dlgFont: TFontDialog
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    MinFontSize = 0
    MaxFontSize = 0
    Left = 47
    Top = 390
  end
end
