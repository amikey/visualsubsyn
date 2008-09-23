unit SRTParserUnit;

interface

uses Classes, Contnrs;

type
  TSRTSubtitle = class
    Start, Stop : Integer;
    Text : WideString;
  end;
  
  TSRTParser = class
  private
    FIsUTF8 : Boolean;
    FAutoCorrectedFile : Boolean;
    FSubList : TObjectList;
  public
    constructor Create;
    destructor Destroy; override;

    function Load(Filename : WideString) : Integer;

    function GetCount : Integer;
    function GetAt(Index : Integer) : TSRTSubtitle;
  published
    property IsUTF8 : Boolean read FIsUTF8;
    property AutoCorrectedFile : Boolean read FAutoCorrectedFile;
  end;

implementation

uses TntClasses, MiscToolsUnit, SysUtils, TntSysUtils;

constructor TSRTParser.Create;
begin
  FSubList := TObjectList.Create(True);
  FIsUTF8 := False;
  FAutoCorrectedFile := False;
end;

destructor TSRTParser.Destroy;
begin
  inherited;
  FreeAndNil(FSubList);
end;

function TSRTParser.GetCount : Integer;
begin
  Result := FSubList.Count;
end;

function TSRTParser.GetAt(Index : Integer) : TSRTSubtitle;
begin
  Result := TSRTSubtitle(FSubList[Index]);
end;

function TSRTParser.Load(Filename : WideString) : Integer;
var Source : TTntStringList;
    i, lineIndex : integer;
    Start, Stop, NextStart, NextStop : Integer;
    S, SubText : WideString;
    Sub : TSRTSubtitle;
begin
  Source := TTntStringList.Create;
  Source.LoadFromFile(Filename);
  FIsUTF8 := (Source.LastFileCharSet <> csAnsi);
  FAutoCorrectedFile := False;
  lineIndex := 0;

  // Add a blank line because TTntStringList is eating the last line
  // if it's blank. This is safe because we will trim the text later anyway.
  Source.Add('');

  // Skip lines until a timestamps line
  while (lineIndex < Source.Count) do
  begin
    S := Source[lineIndex];
    Inc(lineIndex);
    if IsTimeStampsLine(S, Start, Stop) then
      Break;
  end;

  while (lineIndex < Source.Count) do
  begin
    // Copy text until a timestamps line
    SubText := '';
    while (lineIndex < Source.Count) do
    begin
      S := Source[lineIndex];
      Inc(lineIndex);
      if IsTimeStampsLine(S, NextStart, NextStop) then
        Break;
      SubText := SubText + Trim(S) + CRLF;
    end;
    SubText := TrimRight(SubText);
    if (Start <> -1) and (Stop <> -1) then
    begin
      // Auto fix timestamp if this subtitle stop time is equal
      // to next subtitle start time
      if (Stop = NextStart) then
      begin
        FAutoCorrectedFile := True;
        Dec(Stop);
      end;
      // Remove the index line if any
      i := RPos(CRLF, SubText);
      if ((i > 0) and (StrToIntDef(Copy(SubText, i+2, MaxInt), -1) <> -1) and (lineIndex < Source.Count)) then
      begin
        Delete(SubText, i, MaxInt);
      end;
      Sub := TSRTSubtitle.Create;
      Sub.Start := Start;
      Sub.Stop := Stop;
      Sub.Text := Trim(SubText);

      FSubList.Add(Sub);
    end;
    Start := NextStart;
    Stop := NextStop;
  end;
  Source.Free;

  Result := FSubList.Count;
end;

end.