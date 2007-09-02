unit JavaScriptPluginUnit;

interface

uses Classes, js15decl, jsintf, SubStructUnit, TntSysUtils, Graphics, Types;

type
{$TYPEINFO ON}
  TSubtitleRangeJSWrapper = class; // Forward declaration

  TSubtitleRangeJSWrapperChangeStartEvent = procedure (Sender : TSubtitleRangeJSWrapper;
    SubtitleRange : TSubtitleRange; NewValue : Integer) of object;
  TSubtitleRangeJSWrapperChangeStopEvent = procedure (Sender : TSubtitleRangeJSWrapper;
    SubtitleRange : TSubtitleRange; NewValue : Integer) of object;
  TSubtitleRangeJSWrapperChangeTextEvent = procedure (Sender : TSubtitleRangeJSWrapper;
    SubtitleRange : TSubtitleRange; NewValue : WideString) of object;


  TSubtitleRangeJSWrapper = class(TObject)
  private
    FStrippedText : WideString;
    FStrippedTextProcessed : Boolean;
    FOnChangeStart : TSubtitleRangeJSWrapperChangeStartEvent;
    FOnChangeStop : TSubtitleRangeJSWrapperChangeStopEvent;
    FOnChangeText : TSubtitleRangeJSWrapperChangeTextEvent;
    FSubtitleRange : TSubtitleRange;
    function GetStart : Integer;
    function GetStop : Integer;
    function GetText : WideString;
    function GetStrippedText : WideString;
    procedure SetStart(Value : Integer);
    procedure SetStop(Value : Integer);
    procedure SetText(Value : WideString);
    procedure SetSubtitle(Value : TSubtitleRange);
  public
    property OnChangeStart : TSubtitleRangeJSWrapperChangeStartEvent read FOnChangeStart write FOnChangeStart;
    property OnChangeStop : TSubtitleRangeJSWrapperChangeStopEvent read FOnChangeStop write FOnChangeStop;
    property OnChangeText : TSubtitleRangeJSWrapperChangeTextEvent read FOnChangeText write FOnChangeText;
  published
    property Start : Integer read GetStart write SetStart;
    property Stop : Integer read GetStop write SetStop;
    property Text : WideString read GetText write SetText;
    property StrippedText : WideString read GetStrippedText write SetText;
  end;

  TSceneChangeWrapper = class(TObject)
  private
    FSceneChangeList : TIntegerDynArray;
    FStartOffset, FStopOffset : Integer;
  public
    procedure RegisterSceneChange(JSObject : TJSObject);
    procedure SetSceneChangeList(SceneChangeList : TIntegerDynArray);
    procedure SetStartAndStopOffset(StartOffset, StopOffset : Integer);
  published
    function Contains(Start, Stop : Integer) : Boolean;
    function GetCount : Integer;
    function GetAt(Index : Integer) : Integer;

    property StartOffset : Integer read FStartOffset;
    property StopOffset : Integer read FStopOffset;
  end;

{$TYPEINFO OFF}

  TJSPluginParamType = (jsptUnknown, jsptBoolean, jsptInteger, jsptDouble, jsptWideString);
  PJSPluginParam = ^TJSPluginParam;
  TJSPluginParam = record
    Name : WideString;
    ParamType : TJSPluginParamType;
    // Maybe use variant for the value
    BooleanValue : Boolean;
    IntegerValue : Integer;
    DoubleValue : Double;
    WideStringValue : WideString;
    UnitStr : WideString;
  end;

  TJSPluginNotifyEvent = procedure (const Msg : WideString) of object;

  TBaseJavascriptPlugin = class
  protected
    FEngine : TJSEngine;
    FScriptLogJsFunc : TJSFunction;
    FLastErrorMsg : WideString;
    FFatalError : Boolean;
    FVSSPluginObject : TJSObject;
    FFilename : WideString;
    FOnJSPluginError : TJSPluginNotifyEvent;

    procedure OnJsError(eng : TJSEngine; cx: PJSContext; Msg: PChar;
      report: PJSErrorReport);
  public
    constructor Create;
    destructor Destroy; override;
    function LoadScript(Filename : WideString) : Boolean;

    property Filename : WideString read FFilename;
    property LastErrorMsg : WideString read FLastErrorMsg;
    property FatalError : Boolean read FFatalError;    
    property OnJSPluginError : TJSPluginNotifyEvent read FOnJSPluginError write FOnJSPluginError;
  end;

  TJavaScriptPlugin = class(TBaseJavascriptPlugin)
  private
    FHasErrorFunc, FFixErrorFunc : TJSFunction;
    FVSSPluginObject : TJSObject;
    FCurrentSub, FPreviousSub, FNextSub : TSubtitleRangeJSWrapper;
    FCurrentSubJS, FPreviousSubJS, FNextSubJS : TJSObject;
    FParamCount : Integer;
    FOnSubtitleChangeStart : TSubtitleRangeJSWrapperChangeStartEvent;
    FOnSubtitleChangeStop : TSubtitleRangeJSWrapperChangeStopEvent;
    FOnSubtitleChangeText : TSubtitleRangeJSWrapperChangeTextEvent;
    FParamArray : array[0..2] of TJSBase; // used when calling a JS function

    // ----- Plugin constant -----
    FName : WideString;
    FDescription : WideString;
    FColor : Integer;
    FMessage : WideString;

    procedure FillParamArray(CurrentSub, PreviousSub, NextSub : TSubtitleRange);
    procedure SetOnSubtitleChangeStartEvent(Value : TSubtitleRangeJSWrapperChangeStartEvent);
    procedure SetOnSubtitleChangeStopEvent(Value : TSubtitleRangeJSWrapperChangeStopEvent);
    procedure SetOnSubtitleChangeTextEvent(Value : TSubtitleRangeJSWrapperChangeTextEvent);

  public
    constructor Create;
    destructor Destroy; override;
    function LoadScript(Filename : WideString) : Boolean;

    procedure FillParamList(ParamList : TList);
    procedure SetParamValue(Name, Value : WideString);
    function HasError(CurrentSub, PreviousSub, NextSub : TSubtitleRange) : WideString;
    procedure FixError(CurrentSub, PreviousSub, NextSub : TSubtitleRange);
    function CanFixError : Boolean;

    property Filename;
    property OnJSPluginError;
    property LastErrorMsg;
    property FatalError;

    property Name : WideString read FName;
    property Description : WideString read FDescription;
    property Color : Integer read FColor;
    property Msg : WideString read FMessage;
    property OnSubtitleChangeStart : TSubtitleRangeJSWrapperChangeStartEvent read FOnSubtitleChangeStart write SetOnSubtitleChangeStartEvent;
    property OnSubtitleChangeStop : TSubtitleRangeJSWrapperChangeStopEvent read FOnSubtitleChangeStop write SetOnSubtitleChangeStopEvent;
    property OnSubtitleChangeText : TSubtitleRangeJSWrapperChangeTextEvent read FOnSubtitleChangeText write SetOnSubtitleChangeTextEvent;
  end;

  TSimpleJavascriptWrapper = class(TBaseJavascriptPlugin)
  private
    FSetStatusBarTextJsFunc : TJSFunction;
    FNotifySubtitleModificationFunc : TJSFunction;
    FNotifySelectionModificationFunc : TJSFunction;
    FCurrentSub, FPreviousSub, FNextSub : TSubtitleRangeJSWrapper;
    FCurrentSubJS, FPreviousSubJS, FNextSubJS : TJSObject;
    FVSSPluginObject : TJSObject;
    FParamArray : array[0..2] of TJSBase; // used when calling a JS function
    FOnJSPluginSetStatusBarText : TJSPluginNotifyEvent;
    
    procedure FillParamArray(CurrentSub, PreviousSub, NextSub : TSubtitleRange);
  public
    constructor Create;
    destructor Destroy; override;
    function LoadScript(Filename : WideString) : Boolean;
    function NotifySubtitleModification(CurrentSub, PreviousSub, NextSub : TSubtitleRange) : WideString;
    function NotifySelectionModification(CurrentSub, PreviousSub, NextSub : TSubtitleRange) : WideString;
    property OnJSPluginSetStatusBarText : TJSPluginNotifyEvent read FOnJSPluginSetStatusBarText write FOnJSPluginSetStatusBarText;
  end;

  TAbstractJavaScriptPluginEnumerator = class
  protected
    FOnJSPluginError : TJSPluginNotifyEvent;
  public
    procedure Reset; virtual; abstract;
    function GetNext(var JSP : TJavaScriptPlugin) : Boolean; virtual; abstract;

    property OnJSPluginError : TJSPluginNotifyEvent read FOnJSPluginError write FOnJSPluginError;
  end;

  TJavaScriptPluginEnumerator = class(TAbstractJavaScriptPluginEnumerator)
  private
    FPluginPath : WideString;
    FFindFileAttrs : Integer;
    FSearchRec : TSearchRecW;
  public
    constructor Create(PluginPath : WideString);
    destructor Destroy; override;
    procedure Reset; override;
    function GetNext(var JSP : TJavaScriptPlugin) : Boolean; override;
    function GetPluginByName(Name : WideString) : TJavaScriptPlugin;
    function GetPluginByFilename(Filename : WideString) : TJavaScriptPlugin;
  end;

  function GetParamValueAsWideString(pParam : PJSPluginParam) : WideString;
  procedure SetParamValueAsWideString(pParam : PJSPluginParam; Value : WideString);
  function JSColorToTColor(RGBColor : Integer) : TColor;

var
  g_SceneChange: TSceneChangeWrapper;

implementation

uses SysUtils, Windows, WAVDisplayerUnit, MiscToolsUnit;

//------------------------------------------------------------------------------

function GetParamValueAsWideString(pParam : PJSPluginParam) : WideString;
begin
  case pParam.ParamType of
    jsptBoolean: Result := BoolToStr(pParam.BooleanValue);
    jsptInteger: Result := IntToStr(pParam.IntegerValue);
    jsptDouble: Result := FloatToStr(pParam.DoubleValue);
    jsptWideString: Result := pParam.WideStringValue;
    else Result := '';
  end;
end;

//------------------------------------------------------------------------------

procedure SetParamValueAsWideString(pParam : PJSPluginParam; Value : WideString);
begin
  case pParam.ParamType of
    jsptBoolean: pParam.BooleanValue := StrToBool(Value);
    jsptInteger: pParam.IntegerValue := StrToInt(Value);
    jsptDouble: pParam.DoubleValue := StrToFloat(Value);
    jsptWideString: pParam.WideStringValue := Value;
  end;
end;

//------------------------------------------------------------------------------

function JSColorToTColor(RGBColor : Integer) : TColor;
begin
  Result := RGBColor and $0000FF00;
  Result := Result or ((RGBColor and $000000FF) shl 16);
  Result := Result or ((RGBColor and $00FF0000) shr 16);
end;

//------------------------------------------------------------------------------

function _JS_ScriptLog(cx: PJSContext; obj: PJSObject; argc: uintN; argv, rval: pjsval): JSBool; cdecl;
var
  jseng: TJSEngine;
  jsplugin : TBaseJavascriptPlugin;
begin
  if (argc = 1) then
  begin
    jseng := TJSEngine(PEngineData(JS_GetContextPrivate(cx))^);
    jsplugin := TBaseJavascriptPlugin(jseng.UserData);
    if Assigned(jsplugin.FOnJSPluginError) then
      jsplugin.FOnJSPluginError( JSStringToString(JSValToJSString(argv^)) );
  end;
  Result := JS_TRUE;
end;

//------------------------------------------------------------------------------

function _JS_SetStatusBarText(cx: PJSContext; obj: PJSObject; argc: uintN; argv, rval: pjsval): JSBool; cdecl;
var
  jseng: TJSEngine;
  jsplugin : TSimpleJavascriptWrapper;
begin
  if (argc = 1) then
  begin
    jseng := TJSEngine(PEngineData(JS_GetContextPrivate(cx))^);
    jsplugin := TSimpleJavascriptWrapper(jseng.UserData);
    if Assigned(jsplugin.FOnJSPluginSetStatusBarText) then
    begin
      jsplugin.FOnJSPluginSetStatusBarText(JSStringToString(JSValToJSString(argv^)));
    end;
  end;
  Result := JS_TRUE;
end;

// =============================================================================

function TSubtitleRangeJSWrapper.GetStart : Integer;
begin
  Result := FSubtitleRange.StartTime;
end;

function TSubtitleRangeJSWrapper.GetStop : Integer;
begin
  Result := FSubtitleRange.StopTime;
end;

function TSubtitleRangeJSWrapper.GetText : WideString;
begin
  Result := FSubtitleRange.Text;
end;

function TSubtitleRangeJSWrapper.GetStrippedText : WideString;
begin
  if (FStrippedTextProcessed = False) then
  begin
    FStrippedText := StripTags(FSubtitleRange.Text);
    FStrippedTextProcessed := True;
  end;
  Result := FStrippedText;
end;

procedure TSubtitleRangeJSWrapper.SetStart(Value : Integer);
begin
  if (Value <> FSubtitleRange.StartTime) then
  begin
    if Assigned(FOnChangeStart) then
      FOnChangeStart(Self, FSubtitleRange, Value);
    FSubtitleRange.StartTime := Value;
  end;
end;

procedure TSubtitleRangeJSWrapper.SetStop(Value : Integer);
begin
  if (Value <> FSubtitleRange.StopTime) then
  begin
    if Assigned(FOnChangeStop) then
      FOnChangeStop(Self, FSubtitleRange, Value);
    FSubtitleRange.StopTime := Value;
  end;
end;

procedure TSubtitleRangeJSWrapper.SetText(Value : WideString);
begin
  if (Value <> FSubtitleRange.Text) then
  begin
    if Assigned(FOnChangeText) then
      FOnChangeText(Self, FSubtitleRange, Value);
    FSubtitleRange.Text := Value;
    FStrippedTextProcessed := False;
  end;
end;

procedure TSubtitleRangeJSWrapper.SetSubtitle(Value : TSubtitleRange);
begin
  FSubtitleRange := Value;
  FStrippedTextProcessed := False;
end;

// =============================================================================

constructor TBaseJavascriptPlugin.Create;
begin
  inherited Create;
  FEngine := TJSEngine.Create(40000);
  FEngine.OnJSError := OnJsError;
  FEngine.UserData := Self;
  FScriptLogJsFunc := FEngine.Global.AddMethod('ScriptLog', _JS_ScriptLog, 1);
end;

//------------------------------------------------------------------------------

destructor TBaseJavascriptPlugin.Destroy;
begin
  if Assigned(FScriptLogJsFunc) then
    FreeAndNil(FScriptLogJsFunc);
  FEngine.Free;
  inherited;
end;

//------------------------------------------------------------------------------

procedure TBaseJavascriptPlugin.OnJsError(eng : TJSEngine; cx: PJSContext;
  Msg: PChar; report: PJSErrorReport);
var
	ErrorTypeStr: WideString;
begin
  if (report^.flags and JSREPORT_EXCEPTION <> 0) then
  begin
		ErrorTypeStr := 'Exception';
    FFatalError := True;
  end
	else if (report^.flags and JSREPORT_WARNING <> 0) then
  begin
		ErrorTypeStr := 'Warning';
    FFatalError := False;
  end
	else
  begin
		ErrorTypeStr := 'Error';
    FFatalError := True;
  end;
	FLastErrorMsg := Format('%s in %s (Line %d) / %s',
    [ErrorTypeStr, WideExtractFileName(FFilename), report^.lineno+1, Msg]);
  if Assigned(FOnJSPluginError) then
    FOnJSPluginError(FLastErrorMsg);
end;

//------------------------------------------------------------------------------

function TBaseJavascriptPlugin.LoadScript(Filename : WideString) : Boolean;
var FScript : TJSScript;
begin
  Result := False;
  FFilename := Filename;

  FScript := TJSScript.Create;
  FScript.LoadRaw(Filename);
  FScript.Compile(FEngine); // try to compile the script
  if (not FScript.Compiled) then
  begin
    FScript.Free;
    Exit;
  end;

  Result := FScript.Execute(FEngine);
  FScript.Free;
end;

// =============================================================================

constructor TJavaScriptPlugin.Create;
begin
  inherited Create;

  FCurrentSub := TSubtitleRangeJSWrapper.Create;
  FPreviousSub := TSubtitleRangeJSWrapper.Create;
  FNextSub := TSubtitleRangeJSWrapper.Create;
  FCurrentSubJS := nil; FPreviousSubJS := nil; FNextSubJS := nil;
  FHasErrorFunc := nil; FFixErrorFunc := nil;
  FVSSPluginObject := nil;
end;

//------------------------------------------------------------------------------

destructor TJavaScriptPlugin.Destroy;
begin
  if Assigned(FCurrentSubJS) then
    FreeAndNil(FCurrentSubJS);
  if Assigned(FPreviousSubJS) then
    FreeAndNil(FPreviousSubJS);
  if Assigned(FNextSubJS) then
    FreeAndNil(FNextSubJS);

  if Assigned(FHasErrorFunc) then
    FreeAndNil(FHasErrorFunc);
  if Assigned(FFixErrorFunc) then
    FreeAndNil(FFixErrorFunc);
  if Assigned(FVSSPluginObject) then
    FreeAndNil(FVSSPluginObject);
  
  FNextSub.Free;
  FPreviousSub.Free;
  FCurrentSub.Free;

  inherited;
end;


//------------------------------------------------------------------------------

procedure TJavaScriptPlugin.SetOnSubtitleChangeStartEvent(Value : TSubtitleRangeJSWrapperChangeStartEvent);
begin
  if (@Value <> @FOnSubtitleChangeStart) then
  begin
    FOnSubtitleChangeStart := Value;
    FCurrentSub.FOnChangeStart := Value;
    FPreviousSub.FOnChangeStart := Value;
    FNextSub.FOnChangeStart := Value;
  end;
end;

//------------------------------------------------------------------------------

procedure TJavaScriptPlugin.SetOnSubtitleChangeStopEvent(Value : TSubtitleRangeJSWrapperChangeStopEvent);
begin
  if (@Value <> @FOnSubtitleChangeStop) then
  begin
    FOnSubtitleChangeStop := Value;
    FCurrentSub.FOnChangeStop := Value;
    FPreviousSub.FOnChangeStop := Value;
    FNextSub.FOnChangeStop := Value;
  end;
end;

//------------------------------------------------------------------------------

procedure TJavaScriptPlugin.SetOnSubtitleChangeTextEvent(Value : TSubtitleRangeJSWrapperChangeTextEvent);
begin
  if (@Value <> @FOnSubtitleChangeText) then
  begin
    FOnSubtitleChangeText := Value;
    FCurrentSub.FOnChangeText := Value;
    FPreviousSub.FOnChangeText := Value;
    FNextSub.FOnChangeText := Value;
  end;
end;

//------------------------------------------------------------------------------

function TJavaScriptPlugin.LoadScript(Filename : WideString) : Boolean;
begin
  Result := inherited LoadScript(Filename);
  if not Result then
    Exit;

  if FEngine.Global.GetProperty('VSSPlugin', FVSSPluginObject) then
  begin
    FCurrentSubJS := FVSSPluginObject.AddNativeObject(FCurrentSub,'');
    FPreviousSubJS := FVSSPluginObject.AddNativeObject(FPreviousSub,'');
    FNextSubJS := FVSSPluginObject.AddNativeObject(FNextSub,'');
    FHasErrorFunc := FVSSPluginObject.GetFunction('HasError');
    if FVSSPluginObject.IsFunction('FixError') then
      FFixErrorFunc := FVSSPluginObject.GetFunction('FixError');

    // ----- Plugin constant -----
    FVSSPluginObject.GetProperty('Name', FName);
    FVSSPluginObject.GetProperty('Description', FDescription);
    FVSSPluginObject.GetProperty('Color', FColor);
    FVSSPluginObject.GetProperty('Message', FMessage);

    // Scene change
    g_SceneChange.RegisterSceneChange(FEngine.Global);

    // We need at least one function
    Result := (FHasErrorFunc <> nil);
  end;
end;

//------------------------------------------------------------------------------

procedure TJavaScriptPlugin.FillParamList(ParamList : TList);
var ListEnum : TStringArray;
    i : Integer;
    pPluginParam : PJSPluginParam;
    ParamObject : TJSObject;
begin
  ParamList.Clear;
  FParamCount := 0;
  ListEnum := FVSSPluginObject.Enumerate;
  for i := 0 to Length(ListEnum)-1 do
  begin
    if Pos('Param', ListEnum[i]) = 1 then
    begin
      FVSSPluginObject.GetProperty(ListEnum[i], ParamObject);
      if not Assigned(ParamObject) then
        Continue;
      pPluginParam := New(PJSPluginParam);
      ZeroMemory(pPluginParam, SizeOf(TJSPluginParam));
      pPluginParam.Name := ListEnum[i];
      ParamObject.GetProperty('Unit', pPluginParam.UnitStr);
      case ParamObject.TypeOf('Value') of
        JSTYPE_NUMBER:
          if (ParamObject.IsInteger('Value')) then
          begin
            pPluginParam.ParamType := jsptInteger;
            ParamObject.GetProperty('Value', pPluginParam.IntegerValue);
          end else begin
            pPluginParam.ParamType := jsptDouble;
            ParamObject.GetProperty('Value', pPluginParam.DoubleValue);
          end;
        JSTYPE_STRING:
          begin
            pPluginParam.ParamType := jsptWideString;
            ParamObject.GetProperty('Value', pPluginParam.WideStringValue);
          end;
        JSTYPE_BOOLEAN:
          begin
            pPluginParam.ParamType := jsptBoolean;
            ParamObject.GetProperty('Value', pPluginParam.BooleanValue);
          end;
        else
            pPluginParam.ParamType := jsptUnknown;
      end;
      if (pPluginParam.ParamType <> jsptUnknown) then
      begin
        ParamList.Add(pPluginParam);
        Inc(FParamCount);
      end
      else
        Dispose(pPluginParam);
      //FreeAndNil(ParamObject);
    end;
  end;
  SetLength(ListEnum, 0);
end;

//------------------------------------------------------------------------------

procedure TJavaScriptPlugin.SetParamValue(Name, Value : WideString);
var ParamObject : TJSObject;
    val: TJSBase;
begin
  if FVSSPluginObject.HasProperty(Name) and
    FVSSPluginObject.GetProperty(Name, ParamObject) and
    Assigned(ParamObject) then
  begin
    if ParamObject.HasProperty('Value') then
    begin
      case ParamObject.TypeOf('Value') of
        JSTYPE_NUMBER:
          if (ParamObject.IsInteger('Value')) then
            val := ParamObject.Declare(StrToInt(Value))
          else
            val := ParamObject.Declare(StrToFloat(Value));
        JSTYPE_STRING:
          val := ParamObject.Declare(Value);
        JSTYPE_BOOLEAN:
          val := ParamObject.Declare(StrToBool(Value));
        else
          val := nil;
      end;
      if Assigned(val) then
      begin
        ParamObject.SetProperty('Value', val);
      end;
    end;
    //FreeAndNil(ParamObject);
  end;
end;

//------------------------------------------------------------------------------

procedure TJavaScriptPlugin.FillParamArray(CurrentSub, PreviousSub, NextSub : TSubtitleRange);
var i : Integer;
begin
  for i:=0 to Length(FParamArray)-1 do
    FParamArray[i] := nil;
  
  if Assigned(CurrentSub) then
  begin
    FCurrentSub.SetSubtitle(CurrentSub);
    FParamArray[0] := FCurrentSubJS;
  end;
  if Assigned(PreviousSub) then
  begin
    FPreviousSub.SetSubtitle(PreviousSub);
    FParamArray[1] := FPreviousSubJS;
  end;
  if Assigned(NextSub) then
  begin
    FNextSub.SetSubtitle(NextSub);
    FParamArray[2] := FNextSubJS;
  end;
end;

//------------------------------------------------------------------------------

function TJavaScriptPlugin.HasError(CurrentSub, PreviousSub, NextSub : TSubtitleRange) : WideString;
begin
  FillParamArray(CurrentSub, PreviousSub, NextSub);
  FHasErrorFunc.Call(FParamArray, Result);
end;

//------------------------------------------------------------------------------

procedure TJavaScriptPlugin.FixError(CurrentSub, PreviousSub, NextSub : TSubtitleRange);
var Dummy : Boolean;
begin
  if Assigned(FFixErrorFunc) then
  begin
    FillParamArray(CurrentSub, PreviousSub, NextSub);
    FFixErrorFunc.Call(FParamArray, Dummy);
  end;
end;

//------------------------------------------------------------------------------

function TJavaScriptPlugin.CanFixError : Boolean;
begin
  Result := Assigned(FFixErrorFunc);
end;

// =============================================================================

constructor TJavaScriptPluginEnumerator.Create(PluginPath : WideString);
begin
  inherited Create;
  FPluginPath := WideIncludeTrailingBackslash(PluginPath);
  FFindFileAttrs := faAnyFile;
  FSearchRec.FindHandle := INVALID_HANDLE_VALUE;
end;

//------------------------------------------------------------------------------

destructor TJavaScriptPluginEnumerator.Destroy;
begin
  if (FSearchRec.FindHandle <> INVALID_HANDLE_VALUE) then
    WideFindClose(FSearchRec);
  inherited;
end;

//------------------------------------------------------------------------------

procedure TJavaScriptPluginEnumerator.Reset;
begin
  if (FSearchRec.FindHandle <> INVALID_HANDLE_VALUE) then
    WideFindClose(FSearchRec);
  if (WideFindFirst(FPluginPath + '*.js', FFindFileAttrs, FSearchRec) <> 0) then
      WideFindClose(FSearchRec);
end;

//------------------------------------------------------------------------------

function TJavaScriptPluginEnumerator.GetNext(var JSP : TJavaScriptPlugin) : Boolean;
begin
  Result := False;
  if (FSearchRec.FindHandle <> INVALID_HANDLE_VALUE) then
  begin
    JSP := TJavaScriptPlugin.Create;
    JSP.OnJSPluginError := FOnJSPluginError;
    Result := JSP.LoadScript(FPluginPath + FSearchRec.Name);
    if (WideFindNext(FSearchRec) <> 0) then
      WideFindClose(FSearchRec);
    if not Result then
    begin
      FreeAndNil(JSP);
      Result := GetNext(JSP);
    end;
  end;
end;

//------------------------------------------------------------------------------

function TJavaScriptPluginEnumerator.GetPluginByName(Name : WideString) : TJavaScriptPlugin;
var JSPCurrent : TJavaScriptPlugin;
begin
  Result := nil;
  Reset;
  while (GetNext(JSPCurrent)) do
  begin
    if (JSPCurrent.Name = Name) then
    begin
      Result := JSPCurrent;
      Break;
    end;
    JSPCurrent.Free;
  end;
end;

//------------------------------------------------------------------------------

function TJavaScriptPluginEnumerator.GetPluginByFilename(Filename : WideString) : TJavaScriptPlugin;
begin
  Result := nil;
  Reset;
  while (FSearchRec.FindHandle <> INVALID_HANDLE_VALUE) do
  begin
    if ((FPluginPath + FSearchRec.Name) = Filename) then
    begin
      Result := TJavaScriptPlugin.Create;
      Result.OnJSPluginError := FOnJSPluginError;
      if Result.LoadScript(FPluginPath + FSearchRec.Name) = False then
      begin
        Result.Free;
        Result := nil;
      end;
      Break;
    end;
    if (WideFindNext(FSearchRec) <> 0) then
      WideFindClose(FSearchRec);
  end;
end;

// =============================================================================

constructor TSimpleJavascriptWrapper.Create;
begin
  inherited Create;

  FSetStatusBarTextJsFunc := FEngine.Global.AddMethod('SetStatusBarText',
    _JS_SetStatusBarText, 1);

  FCurrentSub := TSubtitleRangeJSWrapper.Create;
  FPreviousSub := TSubtitleRangeJSWrapper.Create;
  FNextSub := TSubtitleRangeJSWrapper.Create;
  FCurrentSubJS := nil; FPreviousSubJS := nil; FNextSubJS := nil;
  FVSSPluginObject := nil;
  FNotifySubtitleModificationFunc := nil;
end;

//------------------------------------------------------------------------------

destructor TSimpleJavascriptWrapper.Destroy;
begin
  if Assigned(FCurrentSubJS) then
    FreeAndNil(FCurrentSubJS);
  if Assigned(FPreviousSubJS) then
    FreeAndNil(FPreviousSubJS);
  if Assigned(FNextSubJS) then
    FreeAndNil(FNextSubJS);

  if Assigned(FNotifySubtitleModificationFunc) then
    FreeAndNil(FNotifySubtitleModificationFunc);
  if Assigned(FVSSPluginObject) then
    FreeAndNil(FVSSPluginObject);

  FNextSub.Free;
  FPreviousSub.Free;
  FCurrentSub.Free;

  if Assigned(FSetStatusBarTextJsFunc) then
    FreeAndNil(FSetStatusBarTextJsFunc);

  inherited;
end;

//------------------------------------------------------------------------------

function TSimpleJavascriptWrapper.NotifySubtitleModification(CurrentSub,
  PreviousSub, NextSub : TSubtitleRange) : WideString;
begin
  if Assigned(FNotifySubtitleModificationFunc) then
  begin
    FillParamArray(CurrentSub, PreviousSub, NextSub);
    FNotifySubtitleModificationFunc.Call(FParamArray, Result);
  end;
end;

//------------------------------------------------------------------------------

function TSimpleJavascriptWrapper.NotifySelectionModification(CurrentSub,
  PreviousSub, NextSub : TSubtitleRange) : WideString;
begin
  if Assigned(FNotifySelectionModificationFunc) then
  begin
    FillParamArray(CurrentSub, PreviousSub, NextSub);
    FNotifySelectionModificationFunc.Call(FParamArray, Result);
  end;
end;

//------------------------------------------------------------------------------

function TSimpleJavascriptWrapper.LoadScript(Filename : WideString) : Boolean;
begin
  Result := inherited LoadScript(Filename);
  if not Result then
    Exit;

  if FEngine.Global.GetProperty('VSSPlugin', FVSSPluginObject) then
  begin
    FCurrentSubJS := FVSSPluginObject.AddNativeObject(FCurrentSub,'');
    FPreviousSubJS := FVSSPluginObject.AddNativeObject(FPreviousSub,'');
    FNextSubJS := FVSSPluginObject.AddNativeObject(FNextSub,'');

    FNotifySubtitleModificationFunc := FVSSPluginObject.GetFunction('OnSubtitleModification');
    FNotifySelectionModificationFunc := FVSSPluginObject.GetFunction('OnSelectedSubtitle');

    // Scene change
    g_SceneChange.RegisterSceneChange(FEngine.Global);

    // We need at least one function
    Result := (FNotifySubtitleModificationFunc <> nil) or
      (FNotifySelectionModificationFunc <> nil);
  end;
end;

//------------------------------------------------------------------------------

procedure TSimpleJavascriptWrapper.FillParamArray(CurrentSub, PreviousSub,
  NextSub : TSubtitleRange);
var i : Integer;
begin
  for i:=0 to Length(FParamArray)-1 do
    FParamArray[i] := nil;
  
  if Assigned(CurrentSub) then
  begin
    FCurrentSub.SetSubtitle(CurrentSub);
    FParamArray[0] := FCurrentSubJS;
  end;
  if Assigned(PreviousSub) then
  begin
    FPreviousSub.SetSubtitle(PreviousSub);
    FParamArray[1] := FPreviousSubJS;
  end;
  if Assigned(NextSub) then
  begin
    FNextSub.SetSubtitle(NextSub);
    FParamArray[2] := FNextSubJS;
  end;
end;

//==============================================================================

function TSceneChangeWrapper.GetCount : Integer;
begin
  Result := Length(FSceneChangeList);
end;

function TSceneChangeWrapper.GetAt(Index : Integer) : Integer;
begin
  if (Index >= Low(FSceneChangeList)) and (Index <= High(FSceneChangeList)) then
    Result := FSceneChangeList[Index]
  else
    Result := -1;
end;

function TSceneChangeWrapper.Contains(Start, Stop : Integer) : Boolean;
var I : Integer;
    OffsetedStart, OffsetedStop : Integer;
begin
  OffsetedStart := Start - FStartOffset;
  OffsetedStop := Stop + FStopOffset;
  for I := Low(FSceneChangeList) to High(FSceneChangeList) do
  begin
    if (FSceneChangeList[I] >= OffsetedStart) and
       (FSceneChangeList[I] <= OffsetedStop) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

procedure TSceneChangeWrapper.RegisterSceneChange(JSObject : TJSObject);
var SceneChangeJSObj : TJSObject;
begin
  SceneChangeJSObj := JSObject.AddNativeObject(Self, 'SceneChange');
  SceneChangeJSObj.SetMethodInfo('Contains', 2, rtBoolean);  
  SceneChangeJSObj.SetMethodInfo('GetCount', 0, rtInteger);
  SceneChangeJSObj.SetMethodInfo('GetAt', 1, rtInteger);
end;

procedure TSceneChangeWrapper.SetSceneChangeList(SceneChangeList : TIntegerDynArray);
begin
  SetLength(FSceneChangeList, System.Length(SceneChangeList));
  if System.Length(SceneChangeList) > 0 then
  begin
    CopyMemory(@FSceneChangeList[0], @SceneChangeList[0],
      Length(SceneChangeList) * SizeOf(Integer));
  end;
end;

procedure TSceneChangeWrapper.SetStartAndStopOffset(StartOffset, StopOffset : Integer);
begin
  FStartOffset := StartOffset;
  FStopOffset := StopOffset;
end;

//==============================================================================

initialization
  g_SceneChange := TSceneChangeWrapper.Create;

finalization
  g_SceneChange.Free;
  g_SceneChange := nil;

//------------------------------------------------------------------------------
end.
//------------------------------------------------------------------------------
