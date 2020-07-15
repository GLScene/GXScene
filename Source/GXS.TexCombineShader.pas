(*******************************************
*                                          *
* Graphic Scene Engine, http://glscene.org *
*                                          *
********************************************)

unit GXS.TexCombineShader;

(* A shader that allows texture combiner setup *)

interface

{$I Scene.inc}

uses
  System.Classes,
  System.SysUtils,
  
  Scene.Import.OpenGLx,
  Scene.XOpenGL,
  GXS.Texture,
  GXS.Material,
  GXS.RenderContextInfo,
  GXS.TextureCombiners,
  GXS.Context,
  GXS.Utils;

type

  // A shader that can setup the texture combiner.
  TgxTexCombineShader = class(TgxShader)
  private
    FCombiners: TStringList;
    FCommandCache: TgxCombinerCache;
    FCombinerIsValid: Boolean; // to avoid reparsing invalid stuff
    FDesignTimeEnabled: Boolean;
    FMaterialLibrary: TgxMaterialLibrary;
    FLibMaterial3Name: TgxLibMaterialName;
    CurrentLibMaterial3: TgxLibMaterial;
    FLibMaterial4Name: TgxLibMaterialName;
    CurrentLibMaterial4: TgxLibMaterial;
    FApplied3, FApplied4: Boolean;
  protected
    procedure SetCombiners(const val: TStringList);
    procedure SetDesignTimeEnabled(const val: Boolean);
    procedure SetMaterialLibrary(const val: TgxMaterialLibrary);
    procedure SetLibMaterial3Name(const val: TgxLibMaterialName);
    procedure SetLibMaterial4Name(const val: TgxLibMaterialName);
    procedure NotifyLibMaterial3Destruction;
    procedure NotifyLibMaterial4Destruction;
    procedure DoInitialize(var rci: TgxRenderContextInfo; Sender: TObject); override;
    procedure DoApply(var rci: TgxRenderContextInfo; Sender: TObject); override;
    function DoUnApply(var rci: TgxRenderContextInfo): Boolean; override;
    procedure DoFinalize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure NotifyChange(Sender: TObject); override;
  published
    property Combiners: TStringList read FCombiners write SetCombiners;
    property DesignTimeEnabled: Boolean read FDesignTimeEnabled write SetDesignTimeEnabled;
    property MaterialLibrary: TgxMaterialLibrary read FMaterialLibrary write SetMaterialLibrary;
    property LibMaterial3Name: TgxLibMaterialName read FLibMaterial3Name write SetLibMaterial3Name;
    property LibMaterial4Name: TgxLibMaterialName read FLibMaterial4Name write SetLibMaterial4Name;
  end;

//===================================================================
implementation
//===================================================================

// ------------------
// ------------------ TgxTexCombineShader ------------------
// ------------------

constructor TgxTexCombineShader.Create(AOwner: TComponent);
begin
  inherited;
  ShaderStyle := ssLowLevel;
  FCombiners := TStringList.Create;
  TStringList(FCombiners).OnChange := NotifyChange;
  FCombinerIsValid := True;
  FCommandCache := nil;
end;

destructor TgxTexCombineShader.Destroy;
begin
  if Assigned(currentLibMaterial3) then
    currentLibMaterial3.UnregisterUser(Self);
  if Assigned(currentLibMaterial4) then
    currentLibMaterial4.UnregisterUser(Self);
  inherited;
  FCombiners.Free;
end;

procedure TgxTexCombineShader.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (FMaterialLibrary = AComponent) and (Operation = opRemove) then
  begin
    NotifyLibMaterial3Destruction;
    NotifyLibMaterial4Destruction;
    FMaterialLibrary := nil;
  end;
  inherited;
end;

procedure TgxTexCombineShader.NotifyChange(Sender: TObject);
begin
  FCombinerIsValid := True;
  FCommandCache := nil;
  inherited NotifyChange(Sender);
end;

procedure TgxTexCombineShader.NotifyLibMaterial3Destruction;
begin
  FLibMaterial3Name := '';
  currentLibMaterial3 := nil;
end;

procedure TgxTexCombineShader.NotifyLibMaterial4Destruction;
begin
  FLibMaterial4Name := '';
  currentLibMaterial4 := nil;
end;

procedure TgxTexCombineShader.SetMaterialLibrary(const val: TgxMaterialLibrary);
begin
  FMaterialLibrary := val;
  SetLibMaterial3Name(LibMaterial3Name);
  SetLibMaterial4Name(LibMaterial4Name);
end;

procedure TgxTexCombineShader.SetLibMaterial3Name(const val: TgxLibMaterialName);
var
  newLibMaterial: TgxLibMaterial;
begin
  // locate new libmaterial
  if Assigned(FMaterialLibrary) then
    newLibMaterial := MaterialLibrary.Materials.GetLibMaterialByName(val)
  else
    newLibMaterial := nil;
  FLibMaterial3Name := val;
  // unregister if required
  if newLibMaterial <> currentLibMaterial3 then
  begin
    // unregister from old
    if Assigned(currentLibMaterial3) then
      currentLibMaterial3.UnregisterUser(Self);
    currentLibMaterial3 := newLibMaterial;
    // register with new
    if Assigned(currentLibMaterial3) then
      currentLibMaterial3.RegisterUser(Self);
    NotifyChange(Self);
  end;
end;

procedure TgxTexCombineShader.SetLibMaterial4Name(const val: TgxLibMaterialName);
var
  newLibMaterial: TgxLibMaterial;
begin
  // locate new libmaterial
  if Assigned(FMaterialLibrary) then
    newLibMaterial := MaterialLibrary.Materials.GetLibMaterialByName(val)
  else
    newLibMaterial := nil;
  FLibMaterial4Name := val;
  // unregister if required
  if newLibMaterial <> currentLibMaterial4 then
  begin
    // unregister from old
    if Assigned(currentLibMaterial4) then
      currentLibMaterial4.UnregisterUser(Self);
    currentLibMaterial4 := newLibMaterial;
    // register with new
    if Assigned(currentLibMaterial4) then
      currentLibMaterial4.RegisterUser(Self);
    NotifyChange(Self);
  end;
end;

procedure TgxTexCombineShader.DoInitialize(var rci: TgxRenderContextInfo; Sender: TObject);
begin
end;

procedure TgxTexCombineShader.DoApply(var rci: TgxRenderContextInfo; Sender: TObject);
var
  n, units: Integer;
begin
  if not GL_ARB_multitexture then
    Exit;
  FApplied3 := False;
  FApplied4 := False;
  if FCombinerIsValid and (FDesignTimeEnabled or (not (csDesigning in ComponentState))) then
  begin
    try
      if Assigned(currentLibMaterial3) or Assigned(currentLibMaterial4) then
      begin
        glGetIntegerv(GL_MAX_TEXTURE_UNITS_ARB, @n);
        units := 0;
        if Assigned(currentLibMaterial3) and (n >= 3) then
        begin
          with currentLibMaterial3.Material.Texture do
          begin
            if Enabled then
            begin
              if currentLibMaterial3.TextureMatrixIsIdentity then
                ApplyAsTextureN(3, rci)
              else
                ApplyAsTextureN(3, rci, @currentLibMaterial3.TextureMatrix.X.X);
              //                     ApplyAsTextureN(3, rci, currentLibMaterial3);
              Inc(units, 4);
              FApplied3 := True;
            end;
          end;
        end;
        if Assigned(currentLibMaterial4) and (n >= 4) then
        begin
          with currentLibMaterial4.Material.Texture do
          begin
            if Enabled then
            begin
              if currentLibMaterial4.TextureMatrixIsIdentity then
                ApplyAsTextureN(4, rci)
              else
                ApplyAsTextureN(4, rci, @currentLibMaterial4.TextureMatrix.X.X);
              //                     ApplyAsTextureN(4, rci, currentLibMaterial4);
              Inc(units, 8);
              FApplied4 := True;
            end;
          end;
        end;
        if units > 0 then
          xglMapTexCoordToArbitraryAdd(units);
      end;

      if Length(FCommandCache) = 0 then
        FCommandCache := GetTextureCombiners(FCombiners);
      for n := 0 to High(FCommandCache) do
      begin
        rci.gxStates.ActiveTexture := FCommandCache[n].ActiveUnit;
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_ARB);
        glTexEnvi(GL_TEXTURE_ENV, FCommandCache[n].Arg1, FCommandCache[n].Arg2);
      end;
      rci.gxStates.ActiveTexture := 0;
    except
      on E: Exception do
      begin
        FCombinerIsValid := False;
        InformationDlg(E.ClassName + ': ' + E.Message);
      end;
    end;
  end;
end;

function TgxTexCombineShader.DoUnApply(var rci: TgxRenderContextInfo): Boolean;
begin
  if FApplied3 then
    with currentLibMaterial3.Material.Texture do
      UnApplyAsTextureN(3, rci, (not currentLibMaterial3.TextureMatrixIsIdentity));
  if FApplied4 then
    with currentLibMaterial4.Material.Texture do
      UnApplyAsTextureN(4, rci, (not currentLibMaterial4.TextureMatrixIsIdentity));
  Result := False;
end;

procedure TgxTexCombineShader.DoFinalize;
begin
end;

procedure TgxTexCombineShader.SetCombiners(const val: TStringList);
begin
  if val <> FCombiners then
  begin
    FCombiners.Assign(val);
    NotifyChange(Self);
  end;
end;

procedure TgxTexCombineShader.SetDesignTimeEnabled(const val: Boolean);
begin
  if val <> FDesignTimeEnabled then
  begin
    FDesignTimeEnabled := val;
    NotifyChange(Self);
  end;
end;

end.

