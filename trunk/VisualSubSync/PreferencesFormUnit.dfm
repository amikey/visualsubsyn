object PreferencesForm: TPreferencesForm
  Left = 204
  Top = 215
  BorderStyle = bsSingle
  BorderWidth = 4
  Caption = 'Preferences'
  ClientHeight = 305
  ClientWidth = 355
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object TntPageControl1: TTntPageControl
    Left = 0
    Top = 0
    Width = 353
    Height = 273
    ActivePage = tsGeneral
    TabOrder = 0
    object tsGeneral: TTntTabSheet
      BorderWidth = 2
      Caption = 'General'
      object TntGroupBox1: TTntGroupBox
        Left = 0
        Top = 0
        Width = 341
        Height = 49
        Caption = ' Web server : '
        TabOrder = 0
        object TntLabel1: TTntLabel
          Left = 16
          Top = 24
          Width = 25
          Height = 13
          Caption = 'Port :'
        end
        object EditServerPort: TTntEdit
          Left = 48
          Top = 20
          Width = 89
          Height = 21
          Hint = 'Port to which the webserver listen for connections'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          Text = '1'
          OnKeyPress = EditDigitOnlyKeyPress
        end
        object UpDownServerPort: TTntUpDown
          Left = 137
          Top = 20
          Width = 16
          Height = 21
          Associate = EditServerPort
          Min = 1
          Max = 32767
          Position = 1
          TabOrder = 1
          Thousands = False
        end
        object chkEnableCompression: TCheckBox
          Left = 208
          Top = 24
          Width = 121
          Height = 17
          Hint = 
            'Compress dynamic webpages for faster transmission (broken with I' +
            'E)'
          Caption = 'Enable compression'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
        end
      end
      object GroupBox1: TGroupBox
        Left = 0
        Top = 144
        Width = 341
        Height = 97
        Caption = ' Misc : '
        TabOrder = 1
        object chkAssociateExt: TCheckBox
          Left = 16
          Top = 24
          Width = 305
          Height = 17
          Hint = 
            'Double click on a .vssprj file will automatically open the proje' +
            'ct in VisualSubSync'
          Caption = 'Associate project file (*.vssprj) with VisualSubSync'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnClick = chkAssociateExtClick
        end
        object chkSwapSubList: TCheckBox
          Left = 16
          Top = 40
          Width = 113
          Height = 17
          Caption = 'Swap subtitles list'
          TabOrder = 1
        end
      end
      object GroupBox4: TGroupBox
        Left = 0
        Top = 56
        Width = 341
        Height = 81
        Caption = ' Backup : '
        TabOrder = 2
        object Label6: TLabel
          Left = 16
          Top = 52
          Width = 153
          Height = 13
          Caption = 'Automatic save every (minutes) :'
        end
        object chkCreateBackup: TCheckBox
          Left = 16
          Top = 24
          Width = 185
          Height = 17
          Caption = 'Create backup file (*.bak) on save'
          TabOrder = 0
        end
        object bttOpenBackupDir: TButton
          Left = 302
          Top = 49
          Width = 28
          Height = 20
          Hint = 'Open backup directory'
          Caption = '...'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnClick = bttOpenBackupDirClick
        end
        object EditBackupTime: TEdit
          Left = 176
          Top = 48
          Width = 57
          Height = 21
          TabOrder = 2
          Text = '0'
        end
        object UpDownBackupTime: TUpDown
          Left = 233
          Top = 48
          Width = 15
          Height = 21
          Associate = EditBackupTime
          TabOrder = 3
        end
      end
    end
    object tsErrorChecking: TTntTabSheet
      BorderWidth = 4
      Caption = 'Error checking'
      object TntBevel1: TTntBevel
        Left = 0
        Top = 177
        Width = 337
        Height = 60
      end
      object TntLabel2: TTntLabel
        Left = 0
        Top = 148
        Width = 33
        Height = 13
        Caption = 'Value :'
      end
      object lbErrorUnit: TTntLabel
        Left = 176
        Top = 148
        Width = 89
        Height = 13
        AutoSize = False
        Caption = '-'
      end
      object lbErrorDescription: TTntLabel
        Left = 8
        Top = 200
        Width = 321
        Height = 31
        AutoSize = False
        Caption = '-'
        WordWrap = True
      end
      object TntLabel3: TTntLabel
        Left = 8
        Top = 184
        Width = 73
        Height = 13
        Caption = 'Description :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object ShapeErrorColor: TShape
        Left = 314
        Top = 147
        Width = 15
        Height = 15
        Shape = stCircle
      end
      object TntLabel4: TTntLabel
        Left = 280
        Top = 148
        Width = 30
        Height = 13
        Caption = 'Color :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object ListErrorChecking: TTntCheckListBox
        Left = 0
        Top = 0
        Width = 337
        Height = 137
        ItemHeight = 13
        TabOrder = 0
        OnClick = ListErrorCheckingClick
      end
      object EditErrorValue: TTntEdit
        Left = 40
        Top = 144
        Width = 129
        Height = 21
        TabOrder = 1
        OnChange = EditErrorValueChange
        OnKeyPress = EditDigitOnlyKeyPress
      end
    end
    object tsHotKeys: TTntTabSheet
      BorderWidth = 4
      Caption = 'HotKeys'
      object TntLabel5: TTntLabel
        Left = 0
        Top = 200
        Width = 33
        Height = 13
        Caption = 'Mode :'
      end
      object TntLabel6: TTntLabel
        Left = 80
        Top = 200
        Width = 40
        Height = 13
        Caption = 'Hotkey :'
      end
      object ListHotkeys: TTntListView
        Left = 0
        Top = 0
        Width = 337
        Height = 193
        Columns = <
          item
            Caption = 'Name'
            Width = 150
          end
          item
            Caption = 'Normal'
            Width = 80
          end
          item
            Caption = 'Timing'
            Width = 80
          end>
        HideSelection = False
        ReadOnly = True
        RowSelect = True
        SortType = stText
        TabOrder = 0
        ViewStyle = vsReport
        OnDeletion = ListHotkeysDeletion
        OnSelectItem = ListHotkeysSelectItem
      end
      object HotKey1: THotKey
        Left = 80
        Top = 217
        Width = 185
        Height = 19
        HotKey = 0
        InvalidKeys = [hcNone]
        Modifiers = []
        TabOrder = 1
      end
      object ComboHotkeyMode: TTntComboBox
        Left = 0
        Top = 216
        Width = 73
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        ItemIndex = 0
        TabOrder = 4
        Text = 'Normal'
        OnSelect = ComboHotkeyModeSelect
        Items.WideStrings = (
          'Normal'
          'Timing')
      end
      object bttResetAllHotkeys: TTntButton
        Left = 272
        Top = 199
        Width = 65
        Height = 19
        Caption = 'Reset all'
        TabOrder = 5
        OnClick = bttResetAllHotkeysClick
      end
      object bttSetHotkey: TTntButton
        Left = 272
        Top = 217
        Width = 33
        Height = 19
        Caption = 'Set'
        TabOrder = 2
        OnClick = bttSetHotkeyClick
      end
      object bttClearHotkey: TTntButton
        Left = 304
        Top = 217
        Width = 33
        Height = 19
        Caption = 'Clear'
        TabOrder = 3
        OnClick = bttClearHotkeyClick
      end
    end
    object tsMouse: TTntTabSheet
      BorderWidth = 4
      Caption = 'Mouse'
      object GroupBox2: TGroupBox
        Left = 0
        Top = 0
        Width = 337
        Height = 121
        Caption = ' Mouse wheel control : '
        TabOrder = 0
        object Label1: TLabel
          Left = 24
          Top = 44
          Width = 93
          Height = 13
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Time scrolling :'
        end
        object Label2: TLabel
          Left = 24
          Top = 68
          Width = 93
          Height = 13
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Vertical Zoom :'
        end
        object Label3: TLabel
          Left = 24
          Top = 92
          Width = 93
          Height = 13
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Horizontal Zoom :'
        end
        object Label4: TLabel
          Left = 24
          Top = 22
          Width = 93
          Height = 13
          Alignment = taCenter
          AutoSize = False
          Caption = 'Actions'
          Color = clBtnText
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clHighlightText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentColor = False
          ParentFont = False
        end
        object Label5: TLabel
          Left = 124
          Top = 22
          Width = 181
          Height = 13
          Alignment = taCenter
          AutoSize = False
          Caption = 'Modifiers'
          Color = clBtnText
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clHighlightText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentColor = False
          ParentFont = False
        end
        object ComboWheelTimeScrollModifier: TComboBox
          Left = 124
          Top = 40
          Width = 181
          Height = 21
          Style = csDropDownList
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ItemHeight = 13
          ParentFont = False
          TabOrder = 0
          Items.Strings = (
            'Shift'
            'Alt'
            'Ctrl'
            'None')
        end
        object ComboWheelVZoomModifier: TComboBox
          Left = 124
          Top = 64
          Width = 181
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          TabOrder = 1
          Items.Strings = (
            'Shift'
            'Alt'
            'Ctrl'
            'None')
        end
        object ComboWheelHZoomModifier: TComboBox
          Left = 124
          Top = 88
          Width = 181
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          TabOrder = 2
          Items.Strings = (
            'Shift'
            'Alt'
            'Ctrl'
            'None')
        end
      end
      object GroupBox3: TGroupBox
        Left = 0
        Top = 132
        Width = 337
        Height = 105
        Caption = ' Misc : '
        TabOrder = 1
        object chkEnableSSATimingMode: TCheckBox
          Left = 16
          Top = 24
          Width = 305
          Height = 17
          Caption = 'Left/right mouse button set start/stop time in Timing Mode'
          TabOrder = 0
        end
      end
    end
  end
  object bttOk: TTntButton
    Left = 200
    Top = 280
    Width = 75
    Height = 25
    Caption = 'Ok'
    TabOrder = 1
    OnClick = bttOkClick
  end
  object bttCancel: TTntButton
    Left = 280
    Top = 280
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 2
    OnClick = bttCancelClick
  end
end