object CnMenuSortForm: TCnMenuSortForm
  Left = 230
  Top = 136
  BorderStyle = bsDialog
  Caption = '高级设置'
  ClientHeight = 435
  ClientWidth = 571
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  Scaled = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object btnOK: TButton
    Left = 326
    Top = 405
    Width = 75
    Height = 21
    Caption = '确定(&O)'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 406
    Top = 405
    Width = 75
    Height = 21
    Cancel = True
    Caption = '取消(&C)'
    ModalResult = 2
    TabOrder = 2
  end
  object btnHelp: TButton
    Left = 486
    Top = 405
    Width = 75
    Height = 21
    Caption = '帮助(&H)'
    TabOrder = 3
    OnClick = btnHelpClick
  end
  object PageControl: TPageControl
    Left = 8
    Top = 8
    Width = 554
    Height = 385
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = '排序(&S)'
      object Label1: TLabel
        Left = 8
        Top = 8
        Width = 108
        Height = 13
        Caption = '专家菜单顺序设置：'
      end
      object lvMenuWizards: TListView
        Left = 0
        Top = 34
        Width = 546
        Height = 323
        Align = alBottom
        Columns = <
          item
            Caption = '菜单项标题'
            Width = 140
          end
          item
            Caption = '专家名称'
            Width = 139
          end
          item
            Caption = '专家 ID'
            Width = 144
          end
          item
            Caption = '专家类型'
            Width = 102
          end>
        DragMode = dmAutomatic
        HideSelection = False
        ReadOnly = True
        RowSelect = True
        TabOrder = 3
        ViewStyle = vsReport
        OnColumnClick = lvMenuWizardsColumnClick
        OnCompare = lvMenuWizardsCompare
        OnDragDrop = lvMenuWizardsDragDrop
        OnDragOver = lvMenuWizardsDragOver
        OnKeyDown = lvMenuWizardsKeyDown
        OnStartDrag = lvMenuWizardsStartDrag
      end
      object btnReset: TBitBtn
        Left = 516
        Top = 8
        Width = 21
        Height = 21
        Action = ResetAction
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
        Glyph.Data = {
          F6000000424DF600000000000000760000002800000010000000100000000100
          0400000000008000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888800000
          008888888880FEFEF00888888880EFEFE0C000000000FEFEF0C00FBFBF00EFEF
          E0C00BFBFB00FEFEF0C00FBFBF00000000C00BFBFB030EFEFE000FBFBF080000
          0000000000030888888880BFBFB0089998888800000008899888888888888898
          9888888889888988888888888898988888888888888988888888}
      end
      object btnDown: TBitBtn
        Left = 483
        Top = 8
        Width = 21
        Height = 21
        Action = DownAction
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        Glyph.Data = {
          DE000000424DDE0000000000000076000000280000000D0000000D0000000100
          04000000000068000000C40E0000C40E00001000000000000000000000000000
          BF0000BF000000BFBF00BF000000BF00BF00BFBF0000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          7000777777077777700077777060777770007777066607777000777066666077
          7000770666666607700070000666000070007777066607777000777706660777
          7000777706660777700077770000077770007777777777777000777777777777
          7000}
      end
      object btnUp: TBitBtn
        Left = 451
        Top = 8
        Width = 21
        Height = 21
        Action = UpAction
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        Glyph.Data = {
          DE000000424DDE0000000000000076000000280000000D0000000D0000000100
          04000000000068000000C40E0000C40E00001000000000000000000000000000
          BF0000BF000000BFBF00BF000000BF00BF00BFBF0000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          7000777777777777700077770000077770007777066607777000777706660777
          7000777706660777700070000666000070007706666666077000777066666077
          7000777706660777700077777060777770007777770777777000777777777777
          7000}
      end
    end
    object TabSheet2: TTabSheet
      Caption = '高级(&A)'
      ImageIndex = 1
      object Label2: TLabel
        Left = 8
        Top = 8
        Width = 216
        Height = 13
        Caption = '专家实例创建设置（下一次启动有效）：'
      end
      object lvWizardCreate: TListView
        Left = 0
        Top = 34
        Width = 546
        Height = 323
        Align = alBottom
        Checkboxes = True
        Columns = <
          item
            Caption = '专家名称'
            Width = 210
          end
          item
            Caption = '专家 ID'
            Width = 175
          end
          item
            Caption = '专家类型'
            Width = 140
          end>
        HideSelection = False
        ReadOnly = True
        RowSelect = True
        TabOrder = 3
        ViewStyle = vsReport
      end
      object BitBtn1: TBitBtn
        Left = 483
        Top = 8
        Width = 21
        Height = 21
        Action = actSelNone
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        Glyph.Data = {
          36040000424D3604000000000000360000002800000010000000100000000100
          2000000000000004000000000000000000000000000000000000FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00905F5A00EDD8
          CA00E9D0BF00E6CAB500E3C4AB00E0BDA100DDB89800DAB28F00D7AD8600905F
          5A00FF00FF0000000000FF00FF00FF00FF0000000000FF00FF00905F5A00FBF4
          EE00F8EDE000F7E6D100F4E0C500F2D9B800F0D3AC00EFCCA000EDC79300905F
          5A00FF00FF0000000000FF00FF00FF00FF0000000000FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00905F5A00EDD8
          CA00E9D0BF00E6CAB500E3C4AB00E0BDA100DDB89800DAB28F00D7AD8600905F
          5A00FF00FF0000000000FF00FF00FF00FF0000000000FF00FF00905F5A00FBF4
          EE00F8EDE000F7E6D100F4E0C500F2D9B800F0D3AC00EFCCA000EDC79300905F
          5A00FF00FF0000000000FF00FF00FF00FF0000000000FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00905F5A00EDD8
          CA00E9D0BF00E6CAB500E3C4AB00E0BDA100DDB89800DAB28F00D7AD8600905F
          5A00FF00FF0000000000FF00FF00FF00FF0000000000FF00FF00905F5A00FBF4
          EE00F8EDE000F7E6D100F4E0C500F2D9B800F0D3AC00EFCCA000EDC79300905F
          5A00FF00FF0000000000FF00FF00FF00FF0000000000FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00}
      end
      object BitBtn2: TBitBtn
        Left = 516
        Top = 8
        Width = 21
        Height = 21
        Action = actSelReverse
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
        Glyph.Data = {
          36040000424D3604000000000000360000002800000010000000100000000100
          2000000000000004000000000000000000000000000000000000FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00905F5A00EDD8
          CA00E9D0BF00E6CAB500E3C4AB00E0BDA100DDB89800DAB28F00D7AD8600905F
          5A00FF00FF0000000000FF00FF00FF00FF0000000000FF00FF00905F5A00FBF4
          EE00F8EDE000F7E6D100F4E0C500F2D9B800F0D3AC00EFCCA000EDC79300905F
          5A00FF00FF0000000000FF00FF00FF00FF0000000000FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00905F5A00EDD8
          CA00E9D0BF00E6CAB500E3C4AB00E0BDA100DDB89800DAB28F00D7AD8600905F
          5A00FF00FF0000000000FF00FF000001DC0000000000FF00FF00905F5A00FBF4
          EE00F8EDE000F7E6D100F4E0C500F2D9B800F0D3AC00EFCCA000EDC79300905F
          5A00FF00FF00000000000001DC000001DC0000000000FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF000000000000000000000000000000BB00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000001DC00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00905F5A00EDD8
          CA00E9D0BF00E6CAB500E3C4AB00E0BDA100DDB89800DAB28F00D7AD8600905F
          5A00FF00FF0000000000FF00FF00FF00FF0000000000FF00FF00905F5A00FBF4
          EE00F8EDE000F7E6D100F4E0C500F2D9B800F0D3AC00EFCCA000EDC79300905F
          5A00FF00FF0000000000FF00FF00FF00FF0000000000FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00}
      end
      object BitBtn3: TBitBtn
        Left = 451
        Top = 8
        Width = 21
        Height = 21
        Action = actSelAll
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        Glyph.Data = {
          36040000424D3604000000000000360000002800000010000000100000000100
          2000000000000004000000000000000000000000000000000000FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00905F5A00EDD8
          CA00E9D0BF00E6CAB500E3C4AB00E0BDA100DDB89800DAB28F00D7AD8600905F
          5A00FF00FF0000000000FF00FF000001DC0000000000FF00FF00905F5A00FBF4
          EE00F8EDE000F7E6D100F4E0C500F2D9B800F0D3AC00EFCCA000EDC79300905F
          5A00FF00FF00000000000001DC000001DC0000000000FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF000000000000000000000000000000BB00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000001DC00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00905F5A00EDD8
          CA00E9D0BF00E6CAB500E3C4AB00E0BDA100DDB89800DAB28F00D7AD8600905F
          5A00FF00FF0000000000FF00FF000001DC0000000000FF00FF00905F5A00FBF4
          EE00F8EDE000F7E6D100F4E0C500F2D9B800F0D3AC00EFCCA000EDC79300905F
          5A00FF00FF00000000000001DC000001DC0000000000FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF000000000000000000000000000000BB00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000001DC00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF0000000000000000000000000000000000FF00FF00905F5A00EDD8
          CA00E9D0BF00E6CAB500E3C4AB00E0BDA100DDB89800DAB28F00D7AD8600905F
          5A00FF00FF0000000000FF00FF000001DC0000000000FF00FF00905F5A00FBF4
          EE00F8EDE000F7E6D100F4E0C500F2D9B800F0D3AC00EFCCA000EDC79300905F
          5A00FF00FF00000000000001DC000001DC0000000000FF00FF00905F5A00905F
          5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F5A00905F
          5A00FF00FF000000000000000000000000000000BB00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
          FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000001DC00}
      end
    end
  end
  object ActionList: TActionList
    OnUpdate = ActionListUpdate
    Left = 400
    Top = 8
    object UpAction: TAction
      Hint = '选中的菜单专家上移'
      OnExecute = UpActionExecute
    end
    object DownAction: TAction
      Hint = '选中的菜单专家下移'
      OnExecute = DownActionExecute
    end
    object ResetAction: TAction
      Hint = '重置菜单专家顺序'
      OnExecute = ResetActionExecute
    end
    object actSelAll: TAction
      Hint = '勾选所有专家'
      OnExecute = actSelAllExecute
    end
    object actSelNone: TAction
      Hint = '不勾选所有专家'
      OnExecute = actSelNoneExecute
    end
    object actSelReverse: TAction
      Hint = '反向勾选专家'
      OnExecute = actSelReverseExecute
    end
  end
end
