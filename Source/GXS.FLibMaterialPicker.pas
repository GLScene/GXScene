//
// Graphic Scene Engine, http://glscene.org
//
(*
 Allows choosing a material in a material library
*)
unit GXS.FLibMaterialPicker;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.Math.Vectors,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.ListBox,
  FMX.Objects,
  FMX.Media,
  FMX.Viewport3D,
  FMX.Controls3D,
  FMX.Objects3D,
  FMX.Types3D,
  FMX.MaterialSources,
  FMX.Controls.Presentation,

  GXS.Material,
  GXS.FRMaterialPreview;

type
  TgxLibMaterialPicker = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    LBMaterials: TListBox;
    BBOK: TButton;
    ImageOK: TImage;
    BBCancel: TButton;
    MPPreview: TRMaterialPreview;
    procedure LBMaterialsClick(Sender: TObject);
    procedure LBMaterialsDblClick(Sender: TObject);
    procedure CBObjectChange(Sender: TObject);
    procedure CBBackgroundChange(Sender: TObject);
  public
    function Execute(var materialName: TgxLibMaterialName;
      materialLibrary: TgxAbstractMaterialLibrary): Boolean;
  end;

function GLLibMaterialPicker: TgxLibMaterialPicker;
procedure ReleaseLibMaterialPicker;

//=================================================================
implementation
//=================================================================

{$R *.fmx}

var
  vLibMaterialPicker: TgxLibMaterialPicker;

function GLLibMaterialPicker: TgxLibMaterialPicker;
begin
  if not Assigned(vLibMaterialPicker) then
    vLibMaterialPicker := TgxLibMaterialPicker.Create(nil);
  Result := vLibMaterialPicker;
end;

procedure ReleaseLibMaterialPicker;
begin
  if Assigned(vLibMaterialPicker) then
  begin
    vLibMaterialPicker.Free;
    vLibMaterialPicker := nil;
  end;
end;

//-----------------------------------------------------
// TLibMaterialPicker
//-----------------------------------------------------
procedure TgxLibMaterialPicker.CBBackgroundChange(Sender: TObject);
begin
  //
end;

procedure TgxLibMaterialPicker.CBObjectChange(Sender: TObject);
begin
  //
end;

function TgxLibMaterialPicker.Execute(var materialName: TgxLibMaterialName;
  materialLibrary: TgxAbstractMaterialLibrary): Boolean;
begin
  with LBMaterials do
  begin
    materialLibrary.SetNamesToTStrings(LBMaterials.Items);
    ItemIndex := Items.IndexOf(materialName);
    if (ItemIndex < 0) and (Items.Count > 0) then
      ItemIndex := 0;
    BBOk.Enabled := (Items.Count > 0);
  end;
  LBMaterialsClick(Self);
  Result := (ShowModal = mrOk);
  if Result then
  begin
    with LBMaterials do
      if ItemIndex >= 0 then
        materialName := Items[ItemIndex]
      else
        materialName := '';
  end;
end;

procedure TgxLibMaterialPicker.LBMaterialsClick(Sender: TObject);
begin
  with LBMaterials do
    if ItemIndex >= 0 then
      MPPreview.LibMaterial := TgxAbstractLibMaterial(Items.Objects[ItemIndex]);
end;

procedure TgxLibMaterialPicker.LBMaterialsDblClick(Sender: TObject);
begin
 /// BBOk.Click;
end;

end.
