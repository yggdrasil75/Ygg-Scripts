object FixedSettings: TFixedSettings
  Left = 0
  Top = 0
  Caption = 'FixedSettings'
  ClientHeight = 435
  ClientWidth = 733
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    733
    435)
  PixelsPerInch = 96
  TextHeight = 13
  object FixedSetting: TLabel
    Left = 72
    Top = 8
    Width = 113
    Height = 20
    Caption = 'Fixed Settings'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = 0
    Font.Name = 'Bookman Old Style'
    Font.Style = []
    ParentFont = False
  end
  object FixedScrollBox: TScrollBox
    Left = 8
    Top = 39
    Width = 717
    Height = 388
    TabOrder = 0
    object AddressValueArmo: TListView
      Left = 3
      Top = 3
      Width = 707
      Height = 383
      Hint = 'Address is in the format KeywordBOD2Slot'
      Columns = <
        item
          AutoSize = True
          Caption = 'Address'
        end
        item
          AutoSize = True
          Caption = 'Rating'
        end
        item
          AutoSize = True
          Caption = 'Weight'
        end
        item
          AutoSize = True
          Caption = 'Value'
        end>
      GridLines = True
      RowSelect = True
      ParentShowHint = False
      ShowWorkAreas = True
      ShowHint = True
      TabOrder = 0
      ViewStyle = vsReport
      Visible = False
    end
    object AddressValueWeap: TListView
      Left = 3
      Top = 3
      Width = 707
      Height = 383
      Hint = 'Address is in the format KeywordBOD2Slot'
      Columns = <
        item
          AutoSize = True
          Caption = 'Address'
        end
        item
          AutoSize = True
          Caption = 'Weight'
        end
        item
          AutoSize = True
          Caption = 'Value'
        end
        item
          Caption = 'Damage'
        end
        item
          Caption = 'Speed'
        end
        item
          Caption = 'Reach'
        end
        item
          Caption = 'Max Range'
        end
        item
          Caption = 'Min Range'
        end
        item
          Caption = 'Critical Damage'
        end>
      GridLines = True
      RowSelect = True
      ParentShowHint = False
      ShowWorkAreas = True
      ShowHint = True
      TabOrder = 1
      ViewStyle = vsReport
      Visible = False
    end
    object AddressValueAmmo: TListView
      Left = 3
      Top = 3
      Width = 707
      Height = 383
      Hint = 'Address is in the format KeywordBOD2Slot'
      Columns = <
        item
          AutoSize = True
          Caption = 'Address'
        end
        item
          AutoSize = True
          Caption = 'Weight'
        end
        item
          AutoSize = True
          Caption = 'Value'
        end
        item
          Caption = 'Damage'
        end>
      GridLines = True
      RowSelect = True
      ParentShowHint = False
      ShowWorkAreas = True
      ShowHint = True
      TabOrder = 2
      ViewStyle = vsReport
      Visible = False
    end
  end
  object Save: TButton
    Left = 650
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Save'
    TabOrder = 1
    OnClick = SaveToIni
  end
  object Finish: TButton
    Left = 480
    Top = 8
    Width = 164
    Height = 25
    Caption = 'Finish (WARNING: Save first)'
    TabOrder = 2
  end
  object ArmoWeapAmmoSelect: TComboBox
    Left = 219
    Top = 8
    Width = 166
    Height = 21
    Anchors = []
    TabOrder = 3
    Text = 'Current Item Type'
    OnSelect = ArmoWeapAmmoSelectSelect
    Items.Strings = (
      'Armor'
      'Weapons'
      'Ammunition')
  end
  object Reset: TButton
    Left = 399
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Reset'
    TabOrder = 4
    OnClick = InitializeCalcLists
  end
end
