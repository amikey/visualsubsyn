// -----------------------------------------------------------------------------
//  VisualSubSync
// -----------------------------------------------------------------------------
//  Copyright (C) 2003 Christophe Paris
// -----------------------------------------------------------------------------
//  This Program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2, or (at your option)
//  any later version.
//
//  This Program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with GNU Make; see the file COPYING.  If not, write to
//  the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
//  http://www.gnu.org/copyleft/gpl.html
// -----------------------------------------------------------------------------

unit SubStructUnit;

interface

uses WAVDisplayerUnit, VirtualTrees, GlobalUnit;

type
  TSubtitleRange = class(TRange)
    Text : WideString;
    Node : PVirtualNode; // TSubtitleRange and tree node are linked both way
  end;

  TSubtitleRangeFactory = class(TRangeFactory)
    function CreateRange : TRange; override;
  end;

  TSubtitleRangeWrapper = class(TContext)
    Index : Integer;
    SubRange : TSubtitleRange;
    function GetFieldValue(Name : string) : string; override;
  end;

implementation

uses MiscToolsUnit, SysUtils;

//==============================================================================

function TSubtitleRangeFactory.CreateRange : TRange;
begin
  Result := TSubtitleRange.Create;
end;

//------------------------------------------------------------------------------

function TSubtitleRangeWrapper.GetFieldValue(Name : string) : string;
var i : Integer;
begin
  if (Name = 'index') then
    Result := IntToStr(Index)
  else if (Name = 'time-index') then
    Result := Format('%x-%x',[SubRange.StartTime,SubRange.StopTime])
  else if (Name = 'start') then
    Result := TimeMsToString(SubRange.StartTime)
  else if (Name = 'stop') then
    Result := TimeMsToString(SubRange.StopTime)
  else if (Name = 'html-text') then
    Result := StringConvertPipeToBR(SubRange.Text)
  else if (Name = 'raw-text') then
    Result := StringConvertPipeToCRLF(SubRange.Text)
  else if (Name = 'html-text8') then
    Result := UTF8Encode(StringConvertPipeToBR(SubRange.Text))
  else if (Name = 'raw-text8') then
    Result := UTF8Encode(StringConvertPipeToCRLF(SubRange.Text))
  else if (Name = 'wav-size') then
  begin
    i := Round(((SubRange.StopTime - SubRange.StartTime) / 1000) * g_GlobalContext.WavAverageBytePerSecond);
    if (i < 1024) then
      Result := IntToStr(i) + ' B'
    else if (i < 1024*1024) then
      Result := IntToStr(i div 1024) + ' KB'
    else
      Result := IntToStr(i div 1024 div 1024) + ' MB';
  end;
end;

//==============================================================================
end.
//==============================================================================