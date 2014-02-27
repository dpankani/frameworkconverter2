unit SWMMInput;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, StrUtils, SWMMIO;

procedure finalizeExport(var Conv: array of TMTARecord; filePathDir: string;
  Sender: TObject);
function checkForDuplicateTS(tsBlockInsertPosition: integer;
  TSList: TStringList; NewFileContentsList: TStringList;
  tsName: string): integer;
function updateSWMMInputFile(var Conv: array of TMTARecord;
  SWMMTSList: TStringList; filePathDir: string; swmmInputFilePath: string;
  Sender: TObject): string;

implementation

procedure finalizeExport(var Conv: array of TMTARecord; filePathDir: string;
  Sender: TObject);
var
  filePath: string;
  pathPrefix: string;
  pathSuffix: string;
  i: integer;
begin
  pathPrefix := filePathDir + '\TS\FrameworkTS_';
  pathSuffix := FormatDateTime('yyyymmddhhnnss', Now) + '.dat';

  for i := Low(Conv) to High(Conv) do
  begin
    if ((Conv[i].constituentSWMMName <> '') and (Conv[i].convFactor <> 0)) then
    begin
      filePath := pathPrefix + Conv[i].constituentSWMMName + pathSuffix;
      Conv[i].convertedTSFilePath := filePath;
      SWMMIO.saveTextFileToDisc(Conv[i].convertedTS, filePath);
    end;
  end;
end;

function checkForDuplicateTS(tsBlockInsertPosition: integer;
  TSList: TStringList; NewFileContentsList: TStringList;
  tsName: string): integer;
begin
  // check our cached list of TS names for a hit
  if (TSList.IndexOf(tsName) > 0) then
  begin
    // duplicate TS exists in the swmmfile so return its line number so we can overwrite with replacement
    while ((Pos(';;', NewFileContentsList[tsBlockInsertPosition]) > 0) and
      (tsBlockInsertPosition < NewFileContentsList.Count)) do
    begin
      inc(tsBlockInsertPosition);
    end;

    while ((Pos(tsName, NewFileContentsList[tsBlockInsertPosition]) = 0) and
      (tsBlockInsertPosition < NewFileContentsList.Count)) do
    begin
      inc(tsBlockInsertPosition);
    end;

    if (Pos(tsName, NewFileContentsList[tsBlockInsertPosition]) > 0) then
    begin
      result := tsBlockInsertPosition;
      Exit;
    end
    else
      result := 0;
  end;
  result := 0;
end;

function updateSWMMInputFile(var Conv: array of TMTARecord;
  SWMMTSList: TStringList; filePathDir: string; swmmInputFilePath: string;
  Sender: TObject): string;
var
  NewFileContentsList: TStringList;
  // lineNumber: integer;
  tempInt: integer;
  tsBlockInsertPosition: integer;
  tempRec: TMTARecord;
  pathSuffix: string;
  newSWMMInputFilePath: string;
  duplicateLineNumber: integer;
begin
  NewFileContentsList := TStringList.Create;
  pathSuffix := FormatDateTime('yyyymmddhhnnss', Now) + '.inp';
  newSWMMInputFilePath := filePathDir + '\' +
    ChangeFileExt(ExtractFileName(swmmInputFilePath), '') + pathSuffix;
  try

    { First check if the swmm file we will be updating exists - note that update version save to new path. }
    if FileExists(swmmInputFilePath) then
    begin
      { If it exists, load the data into the stringlist. }
      NewFileContentsList.LoadFromFile(swmmInputFilePath);

      // Look for insertion points for TIMESERIES and INFLOW blocks
      tsBlockInsertPosition := NewFileContentsList.IndexOf('[REPORTS]');
      if (tsBlockInsertPosition < 0) then
        tsBlockInsertPosition := NewFileContentsList.IndexOf('[CURVES]');
      if (tsBlockInsertPosition < 0) then
        tsBlockInsertPosition := NewFileContentsList.IndexOf('[TAGS]');
      if (tsBlockInsertPosition < 0) then
      begin
        raise Exception.Create
          ('Check SWMM input file format. Unable to write timeseries to SWMM input file');
        Exit;
      end;

      // 1. Write TimeSeries Block
      // check TS list that was passed in to see if input file already contains TS to avoid duplicates
      if (SWMMTSList.Count > 0) then
      begin
        // timeseries section already exists in swmm input file so simply add to it - check for duplicate names
        tsBlockInsertPosition := NewFileContentsList.IndexOf('[TIMESERIES]');
        while (Pos(';;', NewFileContentsList[tsBlockInsertPosition + 1]) < 1) do
        begin
          inc(tsBlockInsertPosition);
        end;
        // see checkForDuplicateTS fxn which checks for duplicate TS names in swmm file below;
      end
      else
      begin
        // timeseries section does not already exist in swmm input file so write times series block and add to TS to it
        NewFileContentsList.Insert(tsBlockInsertPosition, '[TIMESERIES]');
        NewFileContentsList.Insert(tsBlockInsertPosition + 2,
          ';;Name          	Type      	Path');
        NewFileContentsList.Insert(tsBlockInsertPosition + 3,
          ';;-------------- ---------- ---------- ----------');
      end;

      tempInt := 3;
      for tempRec in Conv do
      begin
        if (tempRec.convertedTSFilePath <> '') then
        begin
          // duplicateLineNumber := 0;
          duplicateLineNumber := checkForDuplicateTS(tsBlockInsertPosition,
            SWMMTSList, NewFileContentsList, tempRec.tsName);
          if (duplicateLineNumber <> 0) then
            NewFileContentsList.Delete(duplicateLineNumber);

          NewFileContentsList.Insert(tsBlockInsertPosition + tempInt,
            tempRec.tsName + '      FILE      "' +
            tempRec.convertedTSFilePath + '"');
        end;
        inc(tempInt);
      end;
      tsBlockInsertPosition := tsBlockInsertPosition + tempInt - 2;

      // 2. Write Inflow Block
      // check TS list that was passed in to see if input file already contains TS
      if ((SWMMTSList.Count > 0) and (NewFileContentsList.IndexOf('[INFLOWS]')
        > -1)) then
      begin
        // Inflow section already exists in swmm input file so simply add to it - check for duplicate names
        tsBlockInsertPosition := NewFileContentsList.IndexOf('[INFLOWS]') + 1;
        while (Pos(';;', NewFileContentsList[tsBlockInsertPosition]) > 0) do
        begin
          inc(tsBlockInsertPosition);
        end;
        // TODO check for duplicates names in inflow block
      end
      else
      begin
        // Inflow section does not already exist in swmm input file so write times series block and add to TS to it
        NewFileContentsList.Insert(tsBlockInsertPosition, '');
        NewFileContentsList.Insert(tsBlockInsertPosition + 1, '[INFLOWS]');
        NewFileContentsList.Insert(tsBlockInsertPosition + 2,
          ';;                                                 Param    Units    Scale    Baseline Baseline');
        NewFileContentsList.Insert(tsBlockInsertPosition + 3,
          ';;Node           Parameter        Time Series      Type     Factor   Factor   Value    Pattern');
        NewFileContentsList.Insert(tsBlockInsertPosition + 4,
          ';;-------------- ---------------- ---------------- -------- -------- -------- -------- --------');
        tsBlockInsertPosition := tsBlockInsertPosition + 5;
      end;

      tempInt := 0;
      for tempRec in Conv do
      begin
        if (tempRec.convertedTSFilePath <> '') then
        begin
          NewFileContentsList.Insert(tsBlockInsertPosition + tempInt,
            tempRec.tsNodeName + '        ' + tempRec.constituentSWMMName +
            '        ' + tempRec.tsName + '        ' + tempRec.tsType +
            '        ' + FloatToStr(tempRec.tsUnitsFactor) + '        ' +
            FloatToStr(tempRec.convFactor));
        end;
        inc(tempInt);
      end;
      SWMMIO.saveTextFileToDisc(NewFileContentsList, newSWMMInputFilePath);
    end
    else
      { Otherwise, raise an exception. }
      raise Exception.Create('File does not exist.');
  finally
    result := '';
    NewFileContentsList.Free;
  end;
  result := newSWMMInputFilePath;
end;

end.
