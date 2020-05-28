//
// The unit for GXScene Engine
//
{
  Editor frame for a TgxFaceProperties. 
}
unit FRFaceEditor;

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
  FMX.TabControl,
  FMX.Controls.Presentation,

  FRTrackBarEdit,
  FRColorEditor,
  GXS.Material;

type
  TRFaceEditor = class(TFrame)
    TabControl: TTabControl;
    TIAmbient: TTabItem;
    TIDiffuse: TTabItem;
    TIEmission: TTabItem;
    TISpecular: TTabItem;
    CEAmbiant: TRColorEditor;
    Label1: TLabel;
    TBEShininess: TRTrackBarEdit;
    CEDiffuse: TRColorEditor;
    CEEmission: TRColorEditor;
    CESpecular: TRColorEditor;
    procedure TBEShininessTrackBarChange(Sender: TObject);
  private
    FOnChange: TNotifyEvent;
    Updating: Boolean;
    FFaceProperties: TgxFaceProperties;
    procedure SetFaceProperties(const val: TgxFaceProperties);
    procedure OnColorChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property FaceProperties: TgxFaceProperties read FFaceProperties
      write SetFaceProperties;
  end;

//=====================================================================
implementation
//=====================================================================

{$R *.fmx}

//---------------------------------------------------------
{ TRFaceEditor }
//---------------------------------------------------------

constructor TRFaceEditor.Create(AOwner: TComponent);
begin
  inherited;
  FFaceProperties := TgxFaceProperties.Create(nil);
  CEAmbiant.OnChange := OnColorChange;
  CEDiffuse.OnChange := OnColorChange;
  CEEmission.OnChange := OnColorChange;
  CESpecular.OnChange := OnColorChange;
  { TODO : E2003 Undeclared identifier: 'DoubleBuffered' }
  (*TabControl.DoubleBuffered := True;*)
end;

destructor TRFaceEditor.Destroy;
begin
  FFaceProperties.Free;
  inherited;
end;

procedure TRFaceEditor.OnColorChange(Sender: TObject);
var
  bmp: TBitmap;
  bmpRect: TRectF;

  procedure AddBitmapFor(ce: TRColorEditor);
  begin
    with bmp.Canvas do
    begin
      Fill.Color := ce.PAPreview.Color;
      FillRect(bmpRect,20,40,AllCorners,100);
    end;
    { TODO : E2003 Undeclared identifier: 'ImageList', to be replaced }
    (*ImageList.Add(bmp, nil);*)
  end;

begin
  if not updating then
  begin
    // Update imageList
    bmp := TBitmap.Create;
    try
      bmp.Width := 16;
      bmp.Height := 16;
      bmpRect := TRectF.Create(0, 0, 16, 16);
    { TODO : E2003 Undeclared identifier: 'ImageList', to be replaced }
      (*ImageList.Clear;*)
      bmp.Canvas.BeginScene;
      AddBitmapFor(CEAmbiant);
      bmp.Canvas.EndScene;
      FFaceProperties.Ambient.Color := CEAmbiant.Color;
      AddBitmapFor(CEDiffuse);
      FFaceProperties.Diffuse.Color := CEDiffuse.Color;
      AddBitmapFor(CEEmission);
      FFaceProperties.Emission.Color := CEEmission.Color;
      AddBitmapFor(CESpecular);
      FFaceProperties.Specular.Color := CESpecular.Color;
    finally
      bmp.Free;
    end;
    // Trigger onChange
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TRFaceEditor.TBEShininessTrackBarChange(Sender: TObject);
begin
  if not Updating then
  begin
    TBEShininess.TrackBarChange(Sender);
    FFaceProperties.Shininess := Round(TBEShininess.Value);
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TRFaceEditor.SetFaceProperties(const val: TgxFaceProperties);
begin
  Updating := True;
  try
    CEAmbiant.Color := val.Ambient.Color;
    CEDiffuse.Color := val.Diffuse.Color;
    CEEmission.Color := val.Emission.Color;
    CESpecular.Color := val.Specular.Color;
    TBEShininess.Value := val.Shininess;
  finally
    Updating := False;
  end;
  OnColorChange(Self);
  TBEShininessTrackBarChange(Self);
end;

end.
