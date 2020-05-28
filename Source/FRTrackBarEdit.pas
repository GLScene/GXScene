//
// The unit for GXScene Engine
//
{
  Frame combining a TrackBar and an Edit. 
}
unit FRTrackBarEdit;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Edit,
  FMX.Controls.Presentation;

type
  TRTrackBarEdit = class(TFrame)
    TrackBar: TTrackBar;
    Edit: TEdit;
    procedure TrackBarChange(Sender: TObject);
    procedure EditChange(Sender: TObject);
  private
    procedure SetValue(const val : Single);
    function GetValue : Single;
    procedure SetValueMin(const val : Single);
    function GetValueMin : Single;
    procedure SetValueMax(const val : Single);
    function GetValueMax : Single;
  public
    property Value : Single read GetValue write SetValue;
    property ValueMin : Single read GetValueMin write SetValueMin;
    property ValueMax : Single read GetValueMax write SetValueMax;
  end;

//=====================================================================
implementation
//=====================================================================

{$R *.fmx}

procedure TRTrackBarEdit.TrackBarChange(Sender: TObject);
begin
   Edit.Text:=FloatToStr(TrackBar.Value);
end;

procedure TRTrackBarEdit.EditChange(Sender: TObject);
var
   I : Integer;
begin
   try
      I := StrToInt(Edit.Text);
      TrackBar.Value := I;
   except
      // ignore
   end;
end;

procedure TRTrackBarEdit.SetValue(const val: Single);
begin
   TrackBar.Value:=val;
   TrackBarChange(Self);
end;

function TRTrackBarEdit.GetValue: Single;
begin
   Result:=TrackBar.Value;
end;

procedure TRTrackBarEdit.SetValueMax(const val: Single);
begin
   TrackBar.Max:=val;
   TrackBarChange(Self);
end;

function TRTrackBarEdit.GetValueMax: Single;
begin
   Result:=TrackBar.Max;
end;

procedure TRTrackBarEdit.SetValueMin(const val: Single);
begin
   TrackBar.Min:=val;
   TrackBarChange(Self);
end;

function TRTrackBarEdit.GetValueMin: Single;
begin
   Result:=TrackBar.Min;
end;

end.
