unit UserInputConfirmationDlg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.StdCtrls, Vcl.ExtDlgs,
  Vcl.ExtCtrls;

type
  TUserInputVerificationFrm = class(TForm)
    Label1: TLabel;
    txtSwmmFilePath: TLabel;
    txtSWMMNodeID: TLabel;
    Label4: TLabel;
    StringGrid1: TStringGrid;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    txtTSStartDate: TLabel;
    txtTSEndDate: TLabel;
    txtTSFilePath: TLabel;
    txtErrors: TLabel;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SWMMUserInputVerificationFrm: TUserInputVerificationFrm;

implementation

{$R *.dfm}

end.
