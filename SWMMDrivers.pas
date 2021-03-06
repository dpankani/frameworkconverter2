{ ------------------------------------------------------------------- }
{ Unit:    SWMMDrivers.pas }
{ Project: WERF Framework - SWMM Converter }
{ Version: 2.0 }
{ Date:    2/28/2014 }
{ Author:  Gesoyntec (D. Pankani) }
{ }
{ Delphi Pascal unit that for the main interface GUI that }
{ ------------------------------------------------------------------- }
unit SWMMDrivers;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Generics.Defaults, Generics.Collections,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtDlgs,
  UserInputConfirmationDlg, OperationStatusDlgFrm,
  ImportHelpDialogFrm, ExportHelpDlgFrm, SWMMIO, ConverterErrors,
  SWMMInput, SWMMOutput, ComCtrls, BusyDialogFrm, GIFImg,
  StrUtils, GSControlGrid, Vcl.Controls, FWIO;

const

  Errs: array [0 .. 6] of string =
    ('An unknown error occured when reading the SWMM file',
    'An unknown error occured when saving the new SWMM file',
    'Unable to read node IDs in the SWMM ouput file',
    'Unable to read pollutant IDs in the SWMM output file',
    'Unable to read the start/end dates of the simulation in the SWMM output file',
    'User specified time span begins earlier than available swmm data',
    'User specified time span ends later than available swmm data');

type
  TForm1 = class(TForm)
    OpenTextFileDialog1: TOpenTextFileDialog;
    SaveTextFileDialog1: TSaveTextFileDialog;
    btnSelectSWMMFile: TButton;
    txtSwmmFilePath: TLabel;
    btnCancel: TButton;
    btnHelp: TButton;
    btnRun: TButton;
    Label3: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    lblSect3Num: TLabel;
    lblOperatingMode: TLabel;
    lblHelp: TLabel;
    Label10: TLabel;
    lblSect2Num: TLabel;
    lbxAvailSWMMConstituents: TListBox;
    lbxSelectedSWMMConstituents: TListBox;
    btnConstituentInclude: TButton;
    btnConstituentExclude: TButton;
    Label15: TLabel;
    lblSelectedFWConstituents: TLabel;
    lbxAvailSWMMNodes: TListBox;
    lbxSelectedSWMMNodes: TListBox;
    btnNodeInclude: TButton;
    btnNodeExclude: TButton;
    Label9: TLabel;
    Label13: TLabel;
    lblTSStartEndDate: TLabel;
    strtDatePicker: TDateTimePicker;
    endDatePicker: TDateTimePicker;
    lblTimeSpanTitleNo: TLabel;
    lblTimeSpanTitle: TLabel;
    lblStrtDatePicker: TLabel;
    lblEndDatePicker: TLabel;
    btnNodeExcludeAll: TButton;
    btnNodeIncludeAll: TButton;
    btnConstituentExcludeAll: TButton;
    btnConstituentIncludeAll: TButton;

    procedure transferToFromListBox(lbxFrom: TListBox; lbxTo: TListBox;
      mode: integer);
    /// <summary>
    /// Handler for button used to browse to SWMM file
    /// </summary>
    /// <param name="Sender">
    /// Owner of the button (this form)
    /// </param>
    procedure btnSelectSWMMFileClick(Sender: TObject);

    /// <summary>
    /// Handler for form show event. Most of the setup of the form occurs in
    /// this method
    /// </summary>
    /// <param name="Sender">
    /// Owner (this form)
    /// </param>
    procedure FormShow(Sender: TObject);

    /// <summary>
    /// Displays a dialog to the user for confirmation of user input
    /// parameters and then processes the user import or export request when
    /// the confirmation dialog is dismissed
    /// </summary>
    /// <param name="Sender">
    /// Parent form - currently not used
    /// </param>
    procedure btnRunClick(Sender: TObject);
    // procedure ProgressCallback(InProgressOverall: TProgressBar);
    // procedure RadioGroup1Click(Sender: TObject);

    /// <summary>
    /// Handler for cancel button
    /// </summary>
    /// <param name="Sender">
    /// Owner of the button (this form)
    /// </param>
    procedure btnCancelClick(Sender: TObject);

    /// <summary>
    /// Handler for help button. Displays a dialog with help on how to use
    /// this tool
    /// </summary>
    /// <param name="Sender">
    /// Owner of the button (this form)
    /// </param>
    procedure btnHelpClick(Sender: TObject);

    /// <summary>
    /// Handler for help link. Displays a dialog with help on how to use this
    /// tool
    /// </summary>
    /// <param name="Sender">
    /// Owner of the button (this form)
    /// </param>
    procedure lblHelpClick(Sender: TObject);
    procedure btnNodeIncludeClick(Sender: TObject);
    procedure btnConstituentIncludeClick(Sender: TObject);
    procedure btnNodeExcludeClick(Sender: TObject);
    procedure btnConstituentExcludeClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure strtDatePickerChange(Sender: TObject);
    procedure endDatePickerChange(Sender: TObject);
    procedure btnNodeIncludeAllClick(Sender: TObject);
    procedure btnConstituentIncludeAllClick(Sender: TObject);
    procedure btnConstituentExcludeAllClick(Sender: TObject);
    procedure btnNodeExcludeAllClick(Sender: TObject);

  private
    workingDirPath: string;

    { Private declarations }

  var
    swmmFilePath: string;
    startDateList, endDateList: TStringList;
    swmmSeriesStrtDate: TDateTime;
    swmmSeriesEndDate: TDateTime;
    InputGroupNames: GroupNames;

  public
    { Public declarations }

  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnCancelClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TForm1.btnConstituentExcludeAllClick(Sender: TObject);
begin
  // to account for different screen resolution set form height base on control positions
  Height := btnRun.Top + 90;
  transferToFromListBox(lbxSelectedSWMMConstituents,
    lbxAvailSWMMConstituents, 1);
end;

procedure TForm1.btnConstituentExcludeClick(Sender: TObject);
begin
  // to account for different screen resolution set form height base on control positions
  Height := btnRun.Top + 90;
  transferToFromListBox(lbxSelectedSWMMConstituents,
    lbxAvailSWMMConstituents, 0);
end;

procedure TForm1.btnConstituentIncludeAllClick(Sender: TObject);
begin
  // if (Height < 610) then
  // Height := 610;
  // to account for different screen resolution set form height base on control positions
  Height := btnRun.Top + 90;
  // only enable run button if at least one constituent selected
  btnRun.Enabled := true;

  // move currently selected constituent to select constituents list box
  transferToFromListBox(lbxAvailSWMMConstituents,
    lbxSelectedSWMMConstituents, 1);
end;

procedure TForm1.btnConstituentIncludeClick(Sender: TObject);
begin
  // to account for different screen resolution set form height base on control positions
  Height := btnRun.Top + 90;
  // only enable run button if at least one constituent selected
  btnRun.Enabled := true;

  // move currently selected constituent to select constituents list box
  transferToFromListBox(lbxAvailSWMMConstituents,
    lbxSelectedSWMMConstituents, 0);
end;

procedure TForm1.btnHelpClick(Sender: TObject);
begin
  if (SWMMIO.operatingMode = SWMMIO.opModes[0]) then // importing from SWMM
    ImportHelpDialog.ShowModal()
  else
    ExportHelpDialogFrm.ShowModal();
end;

procedure TForm1.lblHelpClick(Sender: TObject);
begin
  btnHelpClick(Sender);
end;

procedure TForm1.strtDatePickerChange(Sender: TObject);
begin
  if (strtDatePicker.Date < swmmSeriesStrtDate) then
  begin
    MessageDlg
      ('The start date you selected is earlier than the time span of the available SWMM timeseries, please try again',
      mtInformation, [mbOK], 0);
    strtDatePicker.Date := swmmSeriesStrtDate;
  end;
  InputGroupNames.startDate := strtDatePicker.Date;
end;

procedure TForm1.btnRunClick(Sender: TObject);
var
  // lists for holding output filename contents
  lstGroupnames, lstParams, lstFWControlMetafile: TStringList;
  myYear, myMonth, myDay, hr, mn, sc, ms: Word;
  I: integer;
begin

  // 0. init lists to hold content of output files
  lstGroupnames := TStringList.Create;
  lstParams := TStringList.Create;

  // 1. create content to be written to - groupnames.txt - file containing file, and node names
  DecodeDate(InputGroupNames.startDate, myYear, myMonth, myDay);
  lstGroupnames.Add('''' + IntToStr(myYear) + ''',''' + Format('%2d',[myMonth]) +
    ''',''' + Format('%2d',[myDay]) + '''');
  DecodeDate(InputGroupNames.endDate, myYear, myMonth, myDay);
  lstGroupnames.Add('''' + IntToStr(myYear) + ''',''' + Format('%2d',[myMonth]) + ''','''
    + Format('%2d',[myDay]) + '''');

  // Add group name string
  decodeTime(now, hr, mn, sc, ms);
  lstGroupnames.Add('SWMM5_Group_' + IntToStr(myYear) + IntToStr(myMonth) + IntToStr(myDay) + IntToStr(hr) + IntToStr(mn) +
    IntToStr(sc));

  for I := 0 to lbxSelectedSWMMNodes.Items.Count - 1 do
  begin
      lstGroupnames.Add('''' + swmmFilePath + ''',''' + lbxSelectedSWMMNodes.Items
      [I] + '''');
  end;

  // 2. create content to be written to - paramslist.txt - file containing list of selected SWMM pollutants
  lstParams.Add(IntToStr(lbxSelectedSWMMConstituents.Items.Count + 1));
  // add flow since always included
  lstParams.Add('FLOW');
  for I := 0 to lbxSelectedSWMMConstituents.Items.Count - 1 do
  begin
    lstParams.Add(lbxSelectedSWMMConstituents.Items[I]);
  end;

  // 3. content for messages.txt created and saved below
  // report errors or success to FW
  ConverterErrors.reportErrorsToFW();

  // 4. write groupnames.txt and paramslist.txt files to disc
  // if (SWMMIO.operatingMode = SWMMIO.opModes[0]) then
  // SWMM_TO_FW importing from swmm binary file
  // begin
  saveTextFileToDisc(lstGroupnames, SWMMIO.workingDir +
    fileNameGroupNames, true);
  // end;

  // 5. write groupnames.txt and paramslist.txt files to disc
  saveTextFileToDisc(lstParams, SWMMIO.workingDir + fileNameParamsList, true);

  // release resources and exit program
  if (assigned(lstGroupnames)) then
    lstGroupnames.Free;
  if (assigned(lstParams)) then
    lstParams.Free;
  if (assigned(lstFWControlMetafile)) then
    lstFWControlMetafile.Free;

  reportErrorsToFW();
  Self.Close();
end;

procedure TForm1.transferToFromListBox(lbxFrom: TListBox; lbxTo: TListBox;
  mode: integer);
var
  itemName: string;
  I: integer;
begin
  // mode = 1 transfer all items, mode = 0 transfer selected item
  if mode = 1 then
  begin
    for I := 0 to lbxFrom.Items.Count - 1 do
    begin
      itemName := lbxFrom.Items.Strings[0];
      lbxTo.Items.Add(itemName);
      lbxFrom.Items.Delete(0);
    end;
  end
  else
  begin
    // move currently selected item to select items list box
    if (lbxFrom.ItemIndex <> -1) then
    begin
      itemName := lbxFrom.Items.Strings[lbxFrom.ItemIndex];

      // add selected item to selected items listbox
      lbxTo.Items.Add(itemName);
      // deleted items from available items listbox
      lbxFrom.Items.Delete(lbxFrom.ItemIndex);
    end;
  end;
end;

procedure TForm1.btnNodeExcludeAllClick(Sender: TObject);
begin
  // if (Height < 550) then
  // Height := 500;
  // to account for different screen resolution set form height base on control positions
  Height := lblTimeSpanTitleNo.Top + 30;
  transferToFromListBox(lbxSelectedSWMMNodes, lbxAvailSWMMNodes, 0);
end;

procedure TForm1.btnNodeExcludeClick(Sender: TObject);
begin
  transferToFromListBox(lbxSelectedSWMMNodes, lbxAvailSWMMNodes, 0);
end;

procedure TForm1.btnNodeIncludeAllClick(Sender: TObject);
begin
  // if (Height < 550) then
  // Height := 500;
  // to account for different screen resolution set form height base on control positions
  Height := lblTimeSpanTitleNo.Top + 30;
  transferToFromListBox(lbxAvailSWMMNodes, lbxSelectedSWMMNodes, 1);
end;

procedure TForm1.btnNodeIncludeClick(Sender: TObject);
begin
  // if (Height < 550) then
  // Height := 500;
  // to account for different screen resolution set form height base on control positions
  Height := lblTimeSpanTitleNo.Top + 30;
  transferToFromListBox(lbxAvailSWMMNodes, lbxSelectedSWMMNodes, 0);
end;

procedure TForm1.btnSelectSWMMFileClick(Sender: TObject);
var
  swmmFileContents: TStringList;
  TempListArr: TArray<TStringList>;
  swmmIDsListArr: TArray<TStringList>;
begin
  // ShowMessage('Height' + Format('%d',[Screen.WorkAreaHeight]));
  try
    if OpenTextFileDialog1.Execute then
    begin
      { First check if the file exists. }
      if FileExists(OpenTextFileDialog1.FileName) then
      begin
        // Height := 325;
        // to account for different screen resolution set form height base on control positions
        Height := lblSect3Num.Top + 30;
        // save the directory so can write TS to same directory later
        workingDirPath := ExtractFileDir(OpenTextFileDialog1.FileName);
        swmmFilePath := OpenTextFileDialog1.FileName;
        txtSwmmFilePath.Caption := swmmFilePath;

        if (SWMMIO.operatingMode = SWMMIO.opModes[0]) then
        // importing from swmm binary file
        begin
          TempListArr := SWMMIO.getSWMMNodeIDsFromBinary(swmmFilePath);
          if (TempListArr[0].Count < 1) then
            // Unable to read nodes in SWMM output file
            ConverterErrors.errorsList.Add(Errs[2])
          else
            NodeNameList := TempListArr[0];

          if (TempListArr[1].Count < 1) then
            // Unable to read pollutant names in SWMM output file
            ConverterErrors.errorsList.Add(Errs[3])
          else
            PollList := TempListArr[1];

          if ((TempListArr[2].Count < 1) and (TempListArr[3].Count < 1)) then
            // Unable to read simulation start end dates in SWMM output file
            ConverterErrors.errorsList.Add(Errs[4])
          else
          begin
            startDateList := TempListArr[2];
            endDateList := TempListArr[3];

            swmmSeriesStrtDate := EncodeDate(StrToInt(startDateList[0]),
              StrToInt(startDateList[1]), StrToInt(startDateList[2]));
            swmmSeriesEndDate := EncodeDate(StrToInt(endDateList[0]),
              StrToInt(TempListArr[3][1]), StrToInt(endDateList[2]));

          end;
          lblTSStartEndDate.Caption :=
            Format('Simulation Period: From %s to %s',
            [FormatDateTime('mm/dd/yyyy', swmmSeriesStrtDate),
            FormatDateTime('mm/dd/yyyy', swmmSeriesEndDate)]);
        end
        else // we are exporting to swmm so using SWMM input file
        begin

          // 0-NodeIDs list, 1-Pollutants list, 2-Timeseries list, 3-Inflows list
          // swmmIDsListArr := SWMMIO.getSWMMNodeIDsFromTxtInput(swmmFilePath);
          swmmFileContents := readSWMMInputFile(swmmFilePath);
          swmmIDsListArr := SWMMIO.getSWMMNodeIDsFromTxtInput(swmmFileContents);
          SWMMIO.TSList := swmmIDsListArr[2];
          SWMMIO.InflowsList := swmmIDsListArr[3];
          SWMMIO.NodeNameList := swmmIDsListArr[0];
          SWMMIO.PollList := swmmIDsListArr[1];

          swmmSeriesStrtDate := StrToDateTime(swmmIDsListArr[4][0]);
          swmmSeriesEndDate := StrToDateTime(swmmIDsListArr[4][1]);

        end
      end
      else
      begin
        { Otherwise, raise an exception. }
        raise Exception.Create('File does not exist.');
        exit
      end;

      // check dates in swmm file again dates from groupnames.txt
      // if swmm timeseries starts later than FW timespan set start datepicker to swmm timeseries start
      if ((strtDatePicker.Date < swmmSeriesStrtDate) or
        (strtDatePicker.Date > swmmSeriesEndDate)) then
      begin
        strtDatePicker.Date := swmmSeriesStrtDate;
        InputGroupNames.startDate := swmmSeriesStrtDate;
      end;

      // if swmm timeseries ends earlier than FW timespan set end datepicker to swmm timeseries end
      if ((endDatePicker.Date > swmmSeriesEndDate) or
        (endDatePicker.Date < swmmSeriesStrtDate)) then
      begin
        endDatePicker.Date := swmmSeriesEndDate;
        InputGroupNames.endDate := swmmSeriesEndDate;
      end;

      lbxAvailSWMMNodes.Items := SWMMIO.NodeNameList;
      lbxAvailSWMMConstituents.Items := SWMMIO.PollList;
      SWMMIO.PollList.Insert(0, 'Exclude');
    end;
  finally
  end;
end;

procedure TForm1.endDatePickerChange(Sender: TObject);
begin
  if (endDatePicker.Date > swmmSeriesEndDate) then
  begin
    MessageDlg
      ('The end date you selected is later than the time span of the available SWMM timeseries, please try again',
      mtInformation, [mbOK], 0);
    endDatePicker.Date := swmmSeriesEndDate;
  end;
  InputGroupNames.endDate := endDatePicker.Date;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (assigned(endDateList)) then
    endDateList.Free;
  if (assigned(ConverterErrors.errorsList)) then
    ConverterErrors.errorsList.Free;
end;

procedure TForm1.FormShow(Sender: TObject);
var
  numConstituents, I: integer;

begin
  // Height := 130;
  // to account for different screen resolution set form height base on control positions
  Height := lblSect2Num.Top + 30;
  Form1.color := clwhite;

  // 0. For SWMM_TO_FW, if groupnames file does not exist cannot continue, alert user and exit else get FW time span
  // If (SWMMIO.operatingMode = SWMMIO.opModes[0]) then
  // begin
  If (ConverterErrors.checkInputFiles() = -1) then
  begin
    MessageDlg
      ('A Valid Framework File (groupnames.txt) was not found. SWMM Converter cannot continue',
      mtInformation, [mbOK], 0);
    Self.Close();
  end
  else
  begin
    // read groupnames file, extract dates and list of files for use later and set time span datepickers
    InputGroupNames := FWIO.readGroupNames();
    strtDatePicker.DateTime := InputGroupNames.startDate;
    endDatePicker.DateTime := InputGroupNames.endDate;
  end;
  // end;

  lblTSStartEndDate.Caption := '';
  if (SWMMIO.operatingMode = SWMMIO.opModes[0]) then
  // SWMM_TO_FW importing from swmm binary file
  begin
    lblOperatingMode.Caption := 'Importing to WERF Framwork from SWMM';
    btnSelectSWMMFile.Caption := 'Select SWMM Results Output File';
    OpenTextFileDialog1.Filter := 'SWMM Results (*.out)|*.OUT';
    SaveTextFileDialog1.Filter := 'SWMM Input (*.inp)|*.INP';
    lblSelectedFWConstituents.Caption := 'Selected For Import to Framework';
  end
  else // SWMM_FROM_FW we are exporting to swmm so using SWMM input file
  begin
    lblOperatingMode.Caption := 'Exporting from WERF Framework to SWMM';
    btnSelectSWMMFile.Caption := 'Select SWMM Input File';
    OpenTextFileDialog1.Filter := 'SWMM Input (*.inp)|*.INP';
    SaveTextFileDialog1.Filter := 'SWMM Input (*.inp)|*.INP';
    lblSelectedFWConstituents.Caption := 'Selected For Export from Framework';
    strtDatePicker.Hide; // not needed for SWMM_FROM_FW
    endDatePicker.Hide; // not needed for SWMM_FROM_FW
    lblTimeSpanTitle.Hide; // not needed for SWMM_FROM_FW
    lblStrtDatePicker.Hide; // not needed for SWMM_FROM_FW
    lblEndDatePicker.Hide; // not needed for SWMM_FROM_FW
    lblTimeSpanTitleNo.Hide; // not needed for SWMM_FROM_FW
  end;

  // prepare framework to SWMM pollutant matching grid to be populated
  numConstituents := Length(SWMMIO.constituentNames);

  // clear all list boxes
  lbxAvailSWMMNodes.Items.Clear;
  lbxSelectedSWMMNodes.Items.Clear;
  lbxAvailSWMMConstituents.Items.Clear;
  lbxSelectedSWMMConstituents.Items.Clear;

  // default constituents
  for I := 0 to numConstituents - 1 do
  begin
    // pollutant framework pollutants list box with framework pollutant names
    lbxAvailSWMMConstituents.Items.Add(constituentNames[I]);
  end;

  // remove flow from the fw constituents list box since always required
  lbxAvailSWMMConstituents.Items.Delete(0);
end;

end.
