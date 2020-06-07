(*******************************************
*                                          *
* Graphic Scene Engine, http://glscene.org *
*                                          *
********************************************)
(*
   A GLSL shader that applies bump mapping. 
    Notes:
     1) Alpha is a synthetic property, in real life your should set each
      color's Alpha individualy
     2) TgxSLMLBumpShader takes all Light parameters directly
      from OpenGL (that includes TgxLightSource's)
    TODO:
      1) Implement IGLShaderDescription in all shaders.
*)
unit GXS.GLSLBumpShader;

interface

{$I Scene.inc}

uses
  System.Classes,
  System.SysUtils,

  Import.OpenGLx,
  Scene.VectorGeometry,
  Scene.VectorTypes,
  GXS.Texture,
  GXS.Scene,
  GXS.Cadencer,
  Scene.Strings,
  GXS.CustomShader,
  GXS.Color,
  GXS.RenderContextInfo,
  GXS.Material,
  GXS.GLSLShader;

type
  EGLSLBumpShaderException = class(EGLSLShaderException);

  // An abstract class.
  TgxBaseCustomGLSLBumpShader = class(TgxCustomGLSLShader, IgxMaterialLibrarySupported)
  private
    FBumpHeight: Single;
    FBumpSmoothness: Integer;
    FSpecularPower: Single;
    FSpecularSpread: Single;
    FLightPower: Single;
    FMaterialLibrary: TgxMaterialLibrary;
    FNormalTexture: TgxTexture;
    FSpecularTexture: TgxTexture;
    FNormalTextureName: TgxLibMaterialName;
    FSpecularTextureName: TgxLibMaterialName;
    function GetNormalTextureName: TgxLibMaterialName;
    function GetSpecularTextureName: TgxLibMaterialName;
    procedure SetNormalTextureName(const Value: TgxLibMaterialName);
    procedure SetSpecularTextureName(const Value: TgxLibMaterialName);
    procedure SetSpecularTexture(const Value: TgxTexture);
    procedure SetNormalTexture(const Value: TgxTexture);
    // Implementing IGLMaterialLibrarySupported.
    function GetMaterialLibrary: TgxAbstractMaterialLibrary;
  protected
    procedure DoApply(var rci : TgxRenderContextInfo; Sender : TObject); override;
    function DoUnApply(var rci: TgxRenderContextInfo): Boolean; override;
    procedure SetMaterialLibrary(const Value: TgxMaterialLibrary); virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner : TComponent); override;
    property BumpHeight: Single read FBumpHeight write FBumpHeight;
    property BumpSmoothness: Integer read FBumpSmoothness write FBumpSmoothness;
    property SpecularPower: Single read FSpecularPower write FSpecularPower;
    property SpecularSpread: Single read FSpecularSpread write FSpecularSpread;
    property LightPower: Single read FLightPower write FLightPower;
    property NormalTexture: TgxTexture read FNormalTexture write SetNormalTexture;
    property SpecularTexture: TgxTexture read FSpecularTexture write SetSpecularTexture;
    property NormalTextureName: TgxLibMaterialName read GetNormalTextureName write SetNormalTextureName;
    property SpecularTextureName: TgxLibMaterialName read GetSpecularTextureName write SetSpecularTextureName;
    property MaterialLibrary: TgxMaterialLibrary read FMaterialLibrary write SetMaterialLibrary;
  end;

  // An abstract class.
  TgxBaseCustomGLSLBumpShaderMT = class(TgxBaseCustomGLSLBumpShader)
  private
    FMainTexture: TgxTexture;
    FMainTextureName: TgxLibMaterialName;
    function GetMainTextureName: string;
    procedure SetMainTextureName(const Value: string);
  protected
    procedure SetMaterialLibrary(const Value: TgxMaterialLibrary); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    property MainTexture: TgxTexture read FMainTexture write FMainTexture;
    property MainTextureName: TgxLibMaterialName read GetMainTextureName write SetMainTextureName;
  end;

  // One Light shaders.
  TgxCustomGLSLBumpShaderAM = class(TgxBaseCustomGLSLBumpShaderMT)
  private
    FAmbientColor: TgxColor;
    FDiffuseColor: TgxColor;
    FSpecularColor: TgxColor;

    function GetAlpha: Single;
    procedure SetAlpha(const Value: Single);
  protected
    procedure DoApply(var rci : TgxRenderContextInfo; Sender : TObject); override;
    procedure DoInitialize(var rci : TgxRenderContextInfo; Sender : TObject); override;
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    property AmbientColor: TgxColor read FAmbientColor;
    property DiffuseColor: TgxColor read FDiffuseColor;
    property SpecularColor: TgxColor read FSpecularColor;
    property Alpha: Single read GetAlpha write SetAlpha;
  end;

  TgxCustomGLSLBumpShaderMT = class(TgxBaseCustomGLSLBumpShaderMT)
  protected
    procedure DoApply(var rci : TgxRenderContextInfo; Sender : TObject); override;
    procedure DoInitialize(var rci : TgxRenderContextInfo; Sender : TObject); override;
  end;

  TgxCustomGLSLBumpShader = class(TgxBaseCustomGLSLBumpShader, IgxShaderDescription)
  private
    // Implementing IGLShaderDescription.
    procedure SetShaderTextures(const Textures: array of TgxTexture);
    procedure GetShaderTextures(var Textures: array of TgxTexture);
    procedure SetShaderColorParams(const AAmbientColor, ADiffuseColor, ASpecularcolor: TVector4f);
    procedure GetShaderColorParams(var AAmbientColor, ADiffuseColor, ASpecularcolor: TVector4f);
    procedure SetShaderMiscParameters(const ACadencer: TgxCadencer; const AMatLib: TgxMaterialLibrary; const ALightSources: TgxLightSourceSet);
    procedure GetShaderMiscParameters(var ACadencer: TgxCadencer; var AMatLib: TgxMaterialLibrary; var ALightSources: TgxLightSourceSet);
    function GetShaderAlpha: Single;
    procedure SetShaderAlpha(const Value: Single);
    function GetShaderDescription: string;
  protected
    procedure DoApply(var rci : TgxRenderContextInfo; Sender : TObject); override;
    procedure DoInitialize(var rci : TgxRenderContextInfo; Sender : TObject); override;
  end;

  // MultiLight shaders.
  TgxCustomGLSLMLBumpShader = class(TgxBaseCustomGLSLBumpShader, IgxShaderDescription)
  private
    FLightSources: TgxLightSourceSet;
    FLightCompensation: Single;
    procedure SetLightSources(const Value: TgxLightSourceSet);
    procedure SetLightCompensation(const Value: Single);
    // Implementing IGLShaderDescription.
    procedure SetShaderTextures(const Textures: array of TgxTexture);
    procedure GetShaderTextures(var Textures: array of TgxTexture);
    procedure SetShaderColorParams(const AAmbientColor, ADiffuseColor, ASpecularcolor: TVector4f);
    procedure GetShaderColorParams(var AAmbientColor, ADiffuseColor, ASpecularcolor: TVector4f);
    procedure SetShaderMiscParameters(const ACadencer: TgxCadencer; const AMatLib: TgxMaterialLibrary; const ALightSources: TgxLightSourceSet);
    procedure GetShaderMiscParameters(var ACadencer: TgxCadencer; var AMatLib: TgxMaterialLibrary; var ALightSources: TgxLightSourceSet);
    function GetShaderAlpha: Single;
    procedure SetShaderAlpha(const Value: Single);
    function GetShaderDescription: string;
  protected
    procedure DoApply(var rci : TgxRenderContextInfo; Sender : TObject); override;
    procedure DoInitialize(var rci : TgxRenderContextInfo; Sender : TObject); override;
  public
    constructor Create(AOwner : TComponent); override;
    property LightSources: TgxLightSourceSet read FLightSources write SetLightSources default [1];
    { Setting LightCompensation to a value less than 1 decreeses individual
       light intensity when using multiple lights }
    property LightCompensation: Single read FLightCompensation write SetLightCompensation;
  end;

  TgxCustomGLSLMLBumpShaderMT = class(TgxBaseCustomGLSLBumpShaderMT)
  private
    FLightSources: TgxLightSourceSet;
    FLightCompensation: Single;
    procedure SetLightSources(const Value: TgxLightSourceSet);
    procedure SetLightCompensation(const Value: Single);
  protected
    procedure DoApply(var rci : TgxRenderContextInfo; Sender : TObject); override;
    procedure DoInitialize(var rci : TgxRenderContextInfo; Sender : TObject); override;
  public
    constructor Create(AOwner : TComponent); override;
    property LightSources: TgxLightSourceSet read FLightSources write SetLightSources default [1];
    (* Setting LightCompensation to a value less than 1 decreeses individual
       light intensity when using multiple lights *)
    property LightCompensation: Single read FLightCompensation write SetLightCompensation;
  end;

  // One light shaders.
  TgxSLBumpShaderMT = class(TgxCustomGLSLBumpShaderMT)
  published
    property MainTextureName;
    property NormalTextureName;
    property SpecularTextureName;
    property MaterialLibrary;
    property BumpHeight;
    property BumpSmoothness;
    property SpecularPower;
    property SpecularSpread;
    property LightPower;
  end;

  TgxSLBumpShader = class(TgxCustomGLSLBumpShader)
  published
    property NormalTextureName;
    property SpecularTextureName;
    property MaterialLibrary;
    property BumpHeight;
    property BumpSmoothness;
    property SpecularPower;
    property SpecularSpread;
    property LightPower;
  end;

  TgxSLBumpShaderAM = class(TgxCustomGLSLBumpShaderAM)
  published
    property AmbientColor;
    property DiffuseColor;
    property SpecularColor;
    property Alpha stored False;
    property MainTextureName;
    property NormalTextureName;
    property SpecularTextureName;
    property MaterialLibrary;
    property BumpHeight;
    property BumpSmoothness;
    property SpecularPower;
    property SpecularSpread;
    property LightPower;
  end;

  // Multi light shaders.
  TgxSLMLBumpShader = class(TgxCustomGLSLMLBumpShader)
  published
    property NormalTextureName;
    property SpecularTextureName;
    property MaterialLibrary;
    property BumpHeight;
    property BumpSmoothness;
    property SpecularPower;
    property SpecularSpread;
    property LightPower;
    property LightSources;
    property LightCompensation;
  end;

  TgxSLMLBumpShaderMT = class(TgxCustomGLSLMLBumpShaderMT)
  published
    property MainTextureName;
    property NormalTextureName;
    property SpecularTextureName;
    property MaterialLibrary;
    property BumpHeight;
    property BumpSmoothness;
    property SpecularPower;
    property SpecularSpread;
    property LightPower;
    property LightSources;
    property LightCompensation;
  end;

//-----------------------------------------------------------------------------
implementation
//-----------------------------------------------------------------------------

procedure GetVertexProgramCode(const Code: TStrings);
begin
  with Code do
  begin
    Clear;
    Add('varying vec2 Texcoord; ');
    Add('varying vec3 ViewDirection; ');
    Add('varying vec3 LightDirection; ');
    Add(' ');
    Add('void main( void ) ');
    Add('{ ');
    Add('   gl_Position = ftransform(); ');
    Add('   Texcoord    = gl_MultiTexCoord0.xy; ');
    Add(' ');
    Add('   vec3 fvViewDirection   = (gl_ModelViewMatrix * gl_Vertex).xyz; ');
    Add('   vec3 fvLightDirection  =  gl_LightSource[0].position.xyz - fvViewDirection; ');
    Add(' ');
    Add('   vec3 fvNormal         = gl_NormalMatrix * gl_Normal; ');
    Add('   vec3 fvBinormal       = gl_NormalMatrix * gl_MultiTexCoord2.xyz; ');
    Add('   vec3 fvTangent        = gl_NormalMatrix * gl_MultiTexCoord1.xyz; ');
    Add(' ');
    Add('   ViewDirection.x  = dot( fvTangent, fvViewDirection ); ');
    Add('   ViewDirection.y  = dot( fvBinormal, fvViewDirection ); ');
    Add('   ViewDirection.z  = dot( fvNormal, fvViewDirection ); ');
    Add(' ');
    Add('   LightDirection.x  = dot( fvTangent, fvLightDirection ); ');
    Add('   LightDirection.y  = dot( fvBinormal, fvLightDirection ); ');
    Add('   LightDirection.z  = dot( fvNormal, fvLightDirection ); ');
    Add(' ');
    Add('   LightDirection = normalize(LightDirection); ');
    Add('   ViewDirection  = normalize(ViewDirection); ');
    Add('} ');
  end;
end;

procedure GetFragmentProgramCodeMP(const Code: TStrings; const UseSpecularMap: Boolean; const UseNormalMap: Boolean);
begin
  with Code do
  begin
    Clear;
    Add('uniform vec4 fvAmbient; ');
    Add('uniform vec4 fvSpecular; ');
    Add('uniform vec4 fvDiffuse; ');
    Add(' ');
    Add('uniform float fLightPower; ');
    Add('uniform float fSpecularPower; ');
    Add('uniform float fSpecularSpread; ');
    if UseNormalMap then
    begin
      Add('uniform sampler2D bumpMap; ');
      Add('uniform float fBumpHeight; ');
      Add('uniform float fBumpSmoothness; ');
    end;
    Add(' ');
    Add('uniform sampler2D baseMap; ');
    if UseSpecularMap then
      Add('uniform sampler2D specMap; ');
    Add(' ');
    Add('varying vec2 Texcoord; ');
    Add('varying vec3 ViewDirection; ');
    Add('varying vec3 LightDirection; ');
    Add(' ');
    Add('void main( void ) ');
    Add('{ ');
    if UseNormalMap then
      Add('   vec3  fvNormal = normalize( ( texture2D( bumpMap, Texcoord ).xyz * fBumpSmoothness) - fBumpHeight * fBumpSmoothness); ')
    else
      Add('   vec3  fvNormal = vec3(0.0, 0.0, 1);');
    Add(' ');
    Add('   float fNDotL           = dot( fvNormal, LightDirection ); ');
    Add('   vec3  fvReflection     = normalize( ( (fSpecularSpread * fvNormal ) * fNDotL ) - LightDirection ); ');
    Add(' ');
    Add('   float fRDotV           = max( dot( fvReflection, -ViewDirection ), 0.0 ); ');
    Add(' ');
    Add('   vec4  fvBaseColor      = texture2D( baseMap, Texcoord ); ');
    if UseSpecularMap then
      Add('   vec4  fvSpecColor      = texture2D( specMap, Texcoord ) * fvSpecular; ')
    else
      Add('   vec4  fvSpecColor      =                                  fvSpecular; ');
    Add(' ');
    Add('   vec4  fvTotalDiffuse   = clamp(fvDiffuse * fNDotL, 0.0, 1.0); ');
    Add(' ');
    Add('    //  (fvTotalDiffuse + 0.2) / 1.2 is used for removing artefacts on the non-lit side ');
    Add('   vec4  fvTotalSpecular  = clamp((pow(fRDotV, fSpecularPower ) ) * (fvTotalDiffuse + 0.2) / 1.2 * fvSpecColor, 0.0, 1.0); ');
    Add(' ');
    Add('   gl_FragColor = fLightPower * (fvBaseColor * ( fvAmbient + fvTotalDiffuse ) + fvTotalSpecular); ');
    Add('} ');
  end;
end;

procedure GetFragmentProgramCode(const Code: TStrings; const UseSpecularMap: Boolean; const UseNormalMap: Boolean);
begin
  with Code do
  begin
    Clear;
    Add('uniform float fLightPower; ');
    Add('uniform float fSpecularPower; ');
    Add('uniform float fSpecularSpread; ');
    if UseNormalMap then
    begin
      Add('uniform sampler2D bumpMap; ');
      Add('uniform float fBumpHeight; ');
      Add('uniform float fBumpSmoothness; ');
    end;
    Add(' ');
    Add('uniform sampler2D baseMap; ');
    if UseSpecularMap then
      Add('uniform sampler2D specMap; ');
    Add(' ');
    Add('varying vec2 Texcoord; ');
    Add('varying vec3 ViewDirection; ');
    Add('varying vec3 LightDirection; ');
    Add(' ');
    Add('void main( void ) ');
    Add('{ ');
    if UseNormalMap then
      Add('   vec3  fvNormal = normalize( ( texture2D( bumpMap, Texcoord ).xyz * fBumpSmoothness) - fBumpHeight * fBumpSmoothness); ')
    else
      Add('   vec3  fvNormal = vec3(0.0, 0.0, 1.0);');
    Add(' ');
    Add('   float fNDotL           = dot( fvNormal, LightDirection ); ');
    Add('   vec3  fvReflection     = normalize( ( (fSpecularSpread * fvNormal ) * fNDotL ) - LightDirection ); ');
    Add(' ');
    Add('   float fRDotV           = max(dot( fvReflection, -ViewDirection ), 0.0); ');
    Add(' '); 
    Add('   vec4  fvBaseColor      = texture2D( baseMap, Texcoord ); ');
    if UseSpecularMap then
      Add('   vec4  fvSpecColor      = texture2D( specMap, Texcoord ) * gl_LightSource[0].specular; ')
    else
      Add('   vec4  fvSpecColor      =                                  gl_LightSource[0].specular; ');
    Add(' ');
    Add('   vec4  fvTotalDiffuse   = clamp(gl_LightSource[0].diffuse * fNDotL, 0.0, 1.0); ');
    Add(' ');
    Add('    //  (fvTotalDiffuse + 0.2) / 1.2 is used for removing artefacts on the non-lit side ');
    Add('   vec4  fvTotalSpecular  = clamp((pow(fRDotV, fSpecularPower ) ) * (fvTotalDiffuse + 0.2) / 1.2 * fvSpecColor, 0.0, 1.0); ');
    Add(' ');
    Add('   gl_FragColor = fLightPower * (fvBaseColor * ( gl_LightSource[0].ambient + fvTotalDiffuse ) + fvTotalSpecular); ');
    Add('} ');
  end;
end;

procedure GetMLVertexProgramCode(const Code: TStrings);
begin
  with Code do
  begin
    Clear;
    Add('varying vec2 Texcoord; ');
    Add('varying vec3 ViewDirection; ');
    Add(' ');
    Add('varying vec3 fvViewDirection; ');
    Add('varying vec3 fvNormal; ');
    Add('varying vec3 fvBinormal; ');
    Add('varying vec3 fvTangent; ');
    Add(' ');
    Add('void main( void ) ');
    Add('{ ');
    Add('   gl_Position = ftransform(); ');
    Add('   Texcoord    = gl_MultiTexCoord0.xy; ');
    Add(' ');
    Add('   fvViewDirection   = (gl_ModelViewMatrix * gl_Vertex).xyz; ');
    Add(' ');
    Add('   fvNormal         = gl_NormalMatrix * gl_Normal; ');
    Add('   fvBinormal       = gl_NormalMatrix * gl_MultiTexCoord2.xyz; ');
    Add('   fvTangent        = gl_NormalMatrix * gl_MultiTexCoord1.xyz; ');
    Add(' ');
    Add('   ViewDirection.x  = dot( fvTangent, fvViewDirection ); ');
    Add('   ViewDirection.y  = dot( fvBinormal, fvViewDirection ); ');
    Add('   ViewDirection.z  = dot( fvNormal, fvViewDirection ); ');
    Add(' ');
    Add('   ViewDirection  = normalize(ViewDirection); ');
    Add('} ');
  end;
end;

procedure GetMLFragmentProgramCodeBeg(const Code: TStrings; const UseSpecularMap: Boolean; const UseNormalMap: Boolean);
begin
  with Code do
  begin
    Clear;
    Add('uniform float fLightPower; ');
    Add('uniform float fSpecularPower; ');
    Add('uniform float fSpecularSpread; ');
    if UseNormalMap then
    begin
      Add('uniform sampler2D bumpMap; ');
      Add('uniform float fBumpHeight; ');
      Add('uniform float fBumpSmoothness; ');
    end;
    Add(' ');
    Add('uniform sampler2D baseMap; ');
    if UseSpecularMap then
      Add('uniform sampler2D specMap; ');
    Add(' ');
    Add('varying vec2 Texcoord; ');
    Add('varying vec3 ViewDirection; ');
    Add(' ');
    Add('varying vec3 fvViewDirection; ');
    Add('varying vec3 fvNormal; ');
    Add('varying vec3 fvBinormal; ');
    Add('varying vec3 fvTangent; ');
    Add(' ');
    Add('void main( void ) ');
    Add('{ ');
    Add('   vec3 LightDirection;');
    Add('   vec3 fvLightDirection; ');
    Add(' ');
    if UseNormalMap then
      Add('   vec3  fvBumpNormal = normalize( ( texture2D( bumpMap, Texcoord ).xyz * fBumpSmoothness) - fBumpHeight * fBumpSmoothness); ')
    else
      Add('   vec3  fvBumpNormal = vec3(0.0, 0.0, 1);');
    Add(' ');
    Add('   float fNDotL        ; ');
    Add('   vec3  fvReflection  ; ');
    Add('   float fRDotV        ; ');
    Add('   vec4  fvBaseColor = texture2D( baseMap, Texcoord ); ');
    if UseSpecularMap then
      Add('   vec4 fvSpecColor      = texture2D( specMap, Texcoord ); ')
    else
      Add('   vec4 fvSpecColor      = vec4(1.0, 1.0, 1.0, 1.0); ');
    Add('   vec4  fvNewDiffuse  ; ');
    Add('   vec4  fvTotalDiffuse  = vec4(0, 0, 0, 0); ');
    Add('   vec4  fvTotalAmbient  = vec4(0, 0, 0, 0); ');
    Add('   vec4  fvTotalSpecular = vec4(0, 0, 0, 0); ');
  end;
end;

procedure GetMLFragmentProgramCodeMid(const Code: TStrings; const CurrentLight: Integer);
begin
  with Code do
  begin
    Add('   fvLightDirection  = gl_LightSource[' + IntToStr(CurrentLight) + '].position.xyz - fvViewDirection; ');
    Add(' ');
    Add('   LightDirection.x  = dot( fvTangent, fvLightDirection ); ');
    Add('   LightDirection.y  = dot( fvBinormal, fvLightDirection ); ');
    Add('   LightDirection.z  = dot( fvNormal, fvLightDirection ); ');
    Add('   LightDirection = normalize(LightDirection); ');
    Add(' ');
    Add('   fNDotL           = dot( fvBumpNormal, LightDirection ); ');
    Add('   fvReflection     = normalize( ( (fSpecularSpread * fvBumpNormal ) * fNDotL ) - LightDirection ); ');
    Add('   fRDotV           = max( dot( fvReflection, -ViewDirection ), 0.0 ); ');
    Add('   fvNewDiffuse     = clamp(gl_LightSource[' + IntToStr(CurrentLight) + '].diffuse * fNDotL, 0.0, 1.0); ');
    Add('   fvTotalDiffuse   = min(fvTotalDiffuse + fvNewDiffuse, 1.0); ');
    Add('   fvTotalSpecular  = min(fvTotalSpecular + clamp((pow(fRDotV, fSpecularPower ) ) * (fvNewDiffuse + 0.2) / 1.2 * (fvSpecColor * gl_LightSource[' + IntToStr(CurrentLight) + '].specular), 0.0, 1.0), 1.0); ');
    Add('   fvTotalAmbient   = fvTotalAmbient + gl_LightSource[' + IntToStr(CurrentLight) + '].ambient; ');
  end;
end;

procedure GetMLFragmentProgramCodeEnd(const Code: TStrings; const FLightCount: Integer; const FLightCompensation: Single);
var
  Temp: AnsiString;
begin
  with Code do
  begin
    Str((1 + (FLightCount  - 1) * FLightCompensation) / FLightCount :1 :1, Temp);
    if (FLightCount = 1) or (FLightCompensation = 1) then
      Add('   gl_FragColor = fLightPower * (fvBaseColor * ( fvTotalAmbient + fvTotalDiffuse ) + fvTotalSpecular); ')
    else
      Add('   gl_FragColor = fLightPower * (fvBaseColor * ( fvTotalAmbient + fvTotalDiffuse ) + fvTotalSpecular) * ' + string(Temp) + '; ');
    Add('} ');
  end;
end;


{ TgxBaseCustomGLSLBumpShader }

constructor TgxBaseCustomGLSLBumpShader.Create(AOwner: TComponent);
begin
  inherited;
  FSpecularPower := 6;
  FSpecularSpread := 1.5;
  FLightPower := 1;

  FBumpHeight := 0.5;
  FBumpSmoothness := 300;
  TStringList(VertexProgram.Code).OnChange := nil;
  TStringList(FragmentProgram.Code).OnChange := nil;
  VertexProgram.Enabled := True;
  FragmentProgram.Enabled := True;
end;

procedure TgxBaseCustomGLSLBumpShader.DoApply(
  var rci: TgxRenderContextInfo; Sender: TObject);
begin
  // Don't inherit not to call the event.
  GetGLSLProg.UseProgramObject;

  Param['fSpecularPower'].AsVector1f := FSpecularPower;
  Param['fSpecularSpread'].AsVector1f := FSpecularSpread;
  Param['fLightPower'].AsVector1f := FLightPower;

  if FSpecularTexture <> nil then
    Param['specMap'].AsTexture2D[2] := FSpecularTexture;

{$IFNDEF VXS_OPTIMIZATIONS}
  if FNormalTexture <> nil then
{$ENDIF}
  begin
    Param['bumpMap'].AsTexture2D[1] := FNormalTexture;
    Param['fBumpHeight'].AsVector1f := FBumpHeight;
    Param['fBumpSmoothness'].AsVector1f := FBumpSmoothness;
  end;
end;

function TgxBaseCustomGLSLBumpShader.DoUnApply(
  var rci: TgxRenderContextInfo): Boolean;
begin
  //don't inherit not to call the event
  Result := False;
  GetGLSLProg.EndUseProgramObject;
end;

function TgxBaseCustomGLSLBumpShader.GetMaterialLibrary: TgxAbstractMaterialLibrary;
begin
  Result := FMaterialLibrary;
end;

function TgxBaseCustomGLSLBumpShader.GetNormalTextureName: TgxLibMaterialName;
begin
  Result := FMaterialLibrary.GetNameOfTexture(FNormalTexture);
  if Result = '' then Result := FNormalTextureName;
end;

function TgxBaseCustomGLSLBumpShader.GetSpecularTextureName: TgxLibMaterialName;
begin
  Result := FMaterialLibrary.GetNameOfTexture(FSpecularTexture);
  if Result = '' then Result := FSpecularTextureName;
end;

procedure TgxBaseCustomGLSLBumpShader.Notification(
  AComponent: TComponent; Operation: TOperation);
var
  Index: Integer;
begin
  inherited;
  if Operation = opRemove then
    if AComponent = FMaterialLibrary then
      if FMaterialLibrary <> nil then
      begin
        // Need to nil the textures that were ownned by it.
        if FNormalTexture <> nil then
        begin
          Index := FMaterialLibrary.Materials.GetTextureIndex(FNormalTexture);
          if Index <> -1 then
            SetNormalTexture(nil);
        end;

        if FSpecularTexture <> nil then
        begin
          Index := FMaterialLibrary.Materials.GetTextureIndex(FSpecularTexture);
          if Index <> -1 then
            SetSpecularTexture(nil);
        end;

        FMaterialLibrary := nil;
      end;
end;

procedure TgxBaseCustomGLSLBumpShader.SetMaterialLibrary(
  const Value: TgxMaterialLibrary);
begin
  if FMaterialLibrary <> nil then
    FMaterialLibrary.RemoveFreeNotification(Self);
  FMaterialLibrary := Value;

  if FMaterialLibrary <> nil then
  begin
    FMaterialLibrary.FreeNotification(Self);

    if FNormalTextureName <> '' then
      SetNormalTextureName(FNormalTextureName);

    if FSpecularTextureName <> '' then
      SetSpecularTextureName(FSpecularTextureName);
  end
  else
  begin
    FNormalTextureName := '';
    FSpecularTextureName := '';
  end;
end;

procedure TgxBaseCustomGLSLBumpShader.SetNormalTexture(
  const Value: TgxTexture);
begin
  FNormalTexture := Value;
  FinalizeShader;
end;

procedure TgxBaseCustomGLSLBumpShader.SetNormalTextureName(
  const Value: TgxLibMaterialName);
begin
  if FMaterialLibrary = nil then
  begin
    FNormalTextureName := Value;
    if not (csLoading in ComponentState) then
      raise EGLSLBumpShaderException.Create(strErrorEx + strMatLibNotDefined);
  end
  else
  begin
    SetNormalTexture(FMaterialLibrary.TextureByName(Value));
    FNormalTextureName := '';
  end;
end;

procedure TgxBaseCustomGLSLBumpShader.SetSpecularTexture(
  const Value: TgxTexture);
begin
  FSpecularTexture := Value;
  FinalizeShader;
end;

procedure TgxBaseCustomGLSLBumpShader.SetSpecularTextureName(
  const Value: TgxLibMaterialName);
begin
  if FMaterialLibrary = nil then
  begin
    FSpecularTextureName := Value;
    if not (csLoading in ComponentState) then
      raise EGLSLBumpShaderException.Create(strErrorEx + strMatLibNotDefined);
  end
  else
  begin
    SetSpecularTexture(FMaterialLibrary.TextureByName(Value));
    FSpecularTextureName := '';
  end;
end;

{ TgxBaseCustomGLSLBumpShaderMT }

function TgxBaseCustomGLSLBumpShaderMT.GetMainTextureName: TgxLibMaterialName;
begin
  Result := FMaterialLibrary.GetNameOfTexture(FMainTexture);
  if Result = '' then Result := FMainTextureName;
end;

procedure TgxBaseCustomGLSLBumpShaderMT.Notification(
  AComponent: TComponent; Operation: TOperation);
var
  Index: Integer;
begin
  if Operation = opRemove then
    if AComponent = FMaterialLibrary then
      if FMaterialLibrary <> nil then
      begin
        //need to nil the textures that were ownned by it
        if FMainTexture <> nil then
        begin
          Index := FMaterialLibrary.Materials.GetTextureIndex(FMainTexture);
          if Index <> -1 then
            FMainTexture := nil;
        end;
      end;
  inherited;
end;

procedure TgxBaseCustomGLSLBumpShaderMT.SetMainTextureName(
  const Value: TgxLibMaterialName);
begin
  if FMaterialLibrary = nil then
  begin
    FMainTextureName := Value;
    if not (csLoading in ComponentState) then
      raise EGLSLBumpShaderException.Create(strErrorEx + strMatLibNotDefined);
  end
  else
  begin
    FMainTexture := FMaterialLibrary.TextureByName(Value);
    FMainTextureName := '';
  end;
end;

procedure TgxBaseCustomGLSLBumpShaderMT.SetMaterialLibrary(
  const Value: TgxMaterialLibrary);
begin
  inherited;
  if FMaterialLibrary <> nil then
  begin
    if FMainTextureName <> '' then
      SetMainTextureName(FMainTextureName);
  end
  else
    FMainTextureName := '';
end;

{ TgxCustomGLSLBumpShaderAM }

constructor TgxCustomGLSLBumpShaderAM.Create(AOwner: TComponent);
begin
  inherited;

  FAmbientColor := TgxColor.Create(Self);
  FDiffuseColor := TgxColor.Create(Self);
  FSpecularColor := TgxColor.Create(Self);

  // Setup initial parameters.
  FAmbientColor.SetColor(0.15, 0.15, 0.15, 1);
  FDiffuseColor.SetColor(1, 1, 1, 1);
  FSpecularColor.SetColor(1, 1, 1, 1);
end;

destructor TgxCustomGLSLBumpShaderAM.Destroy;
begin
  FAmbientColor.Destroy;
  FDiffuseColor.Destroy;
  FSpecularColor.Destroy;

  inherited;
end;

procedure TgxCustomGLSLBumpShaderAM.DoApply(var rci: TgxRenderContextInfo;
  Sender: TObject);
begin
  inherited;

  Param['fvAmbient'].AsVector4f := FAmbientColor.Color;
  Param['fvDiffuse'].AsVector4f := FDiffuseColor.Color;
  Param['fvSpecular'].AsVector4f := FSpecularColor.Color;

  Param['baseMap'].AsTexture2D[0] := FMainTexture;
end;

procedure TgxCustomGLSLBumpShaderAM.DoInitialize(var rci : TgxRenderContextInfo; Sender : TObject);
begin
  GetVertexProgramCode(VertexProgram.Code);
  GetFragmentProgramCodeMP(FragmentProgram.Code, FSpecularTexture <> nil, FNormalTexture <> nil);
  VertexProgram.Enabled := True;
  FragmentProgram.Enabled := True;
  inherited;
end;

function TgxCustomGLSLBumpShaderAM.GetAlpha: Single;
begin
  Result := (FAmbientColor.Alpha + FDiffuseColor.Alpha + FSpecularColor.Alpha) / 3;
end;

procedure TgxCustomGLSLBumpShaderAM.SetAlpha(const Value: Single);
begin
  FAmbientColor.Alpha := Value;
  FDiffuseColor.Alpha := Value;
  FSpecularColor.Alpha := Value;
end;

{ TgxCustomGLSLMLBumpShaderMT }

constructor TgxCustomGLSLMLBumpShaderMT.Create(AOwner: TComponent);
begin
  inherited;

  FLightSources := [1];
  FLightCompensation := 1;
end;

procedure TgxCustomGLSLMLBumpShaderMT.DoApply(var rci: TgxRenderContextInfo;
  Sender: TObject);
begin
  inherited;
  Param['baseMap'].AsTexture2D[0] := FMainTexture;
end;

procedure TgxCustomGLSLMLBumpShaderMT.DoInitialize(var rci : TgxRenderContextInfo; Sender : TObject);
var
  I: Integer;
  lLightCount: Integer;
begin
  GetMLVertexProgramCode(VertexProgram.Code);
  
  with FragmentProgram.Code do
  begin
    GetMLFragmentProgramCodeBeg(FragmentProgram.Code, FSpecularTexture <> nil, FNormalTexture <> nil);

    lLightCount := 0;
    // Repeat for all lights.
    for I := 0 to vxsShaderMaxLightSources - 1 do
      if I + 1 in FLightSources then
      begin
        GetMLFragmentProgramCodeMid(FragmentProgram.Code, I);
        Inc(lLightCount);
      end;

    GetMLFragmentProgramCodeEnd(FragmentProgram.Code, lLightCount, FLightCompensation);
  end;
  VertexProgram.Enabled := True;
  FragmentProgram.Enabled := True;
  inherited;
end;

procedure TgxCustomGLSLMLBumpShaderMT.SetLightCompensation(
  const Value: Single);
begin
  FLightCompensation := Value;
  FinalizeShader;
end;

procedure TgxCustomGLSLMLBumpShaderMT.SetLightSources(
  const Value: TgxLightSourceSet);
begin
  Assert(Value <> [], strErrorEx + strShaderNeedsAtLeastOneLightSource);
  FLightSources := Value;
  FinalizeShader;
end;

{ TgxCustomGLSLBumpShaderMT }

procedure TgxCustomGLSLBumpShaderMT.DoApply(
  var rci: TgxRenderContextInfo; Sender: TObject);
begin
  inherited;
  Param['baseMap'].AsTexture2D[0] := FMainTexture;
end;

procedure TgxCustomGLSLBumpShaderMT.DoInitialize(var rci : TgxRenderContextInfo; Sender : TObject);
begin
  GetVertexProgramCode(VertexProgram.Code);
  GetFragmentProgramCode(FragmentProgram.Code, FSpecularTexture <> nil, FNormalTexture <> nil);
  inherited;
end;

{ TgxCustomGLSLBumpShader }

procedure TgxCustomGLSLBumpShader.DoApply(var rci: TgxRenderContextInfo;
  Sender: TObject);
begin
  inherited;
  Param['baseMap'].AsVector1i := 0;  // Use the current texture.
end;

procedure TgxCustomGLSLBumpShader.DoInitialize(var rci : TgxRenderContextInfo; Sender : TObject);
begin
  GetVertexProgramCode(VertexProgram.Code);
  GetFragmentProgramCode(FragmentProgram.Code, FSpecularTexture <> nil, FNormalTexture <> nil);
  VertexProgram.Enabled := True;
  FragmentProgram.Enabled := True;
  inherited;
end;


function TgxCustomGLSLBumpShader.GetShaderAlpha: Single;
begin
  //ignore
  Result := -1;
end;

procedure TgxCustomGLSLBumpShader.GetShaderColorParams(var AAmbientColor,
  ADiffuseColor, ASpecularcolor: TVector4f);
begin
  //ignore
  AAmbientColor := NullHmgVector;
  ADiffuseColor := NullHmgVector;
  ASpecularcolor := NullHmgVector;
end;

procedure TgxCustomGLSLBumpShader.GetShaderTextures(
  var Textures: array of TgxTexture);
begin
  Textures[0] := FNormalTexture;
  Textures[1] := FSpecularTexture;
end;

procedure TgxCustomGLSLBumpShader.GetShaderMiscParameters(var ACadencer: TgxCadencer;
  var AMatLib: TgxMaterialLibrary; var ALightSources: TgxLightSourceSet);
begin
  ACadencer := nil;
  AMatLib := FMaterialLibrary;
  ALightSources := [0];
end;

procedure TgxCustomGLSLBumpShader.SetShaderAlpha(const Value: Single);
begin
  //ignore
end;

procedure TgxCustomGLSLBumpShader.SetShaderColorParams(const AAmbientColor,
  ADiffuseColor, ASpecularcolor: TVector4f);
begin
  //ignore
end;

procedure TgxCustomGLSLBumpShader.SetShaderMiscParameters(
  const ACadencer: TgxCadencer; const AMatLib: TgxMaterialLibrary;
  const ALightSources: TgxLightSourceSet);
begin
  SetMaterialLibrary(AMatLib);
end;

procedure TgxCustomGLSLBumpShader.SetShaderTextures(
  const Textures: array of TgxTexture);
begin
  SetNormalTexture(Textures[0]);
  SetSpecularTexture(Textures[1]);
end;

function TgxCustomGLSLBumpShader.GetShaderDescription: string;
begin
  Result := 'ShaderTexture1 is NormalMap, ShaderTexture2 is SpecularMap'
end;


{ TgxCustomGLSLMLBumpShader }

constructor TgxCustomGLSLMLBumpShader.Create(AOwner: TComponent);
begin
  inherited;

  FLightSources := [1];
  FLightCompensation := 1;
end;

procedure TgxCustomGLSLMLBumpShader.DoApply(var rci: TgxRenderContextInfo;
  Sender: TObject);
begin
  inherited;
  Param['baseMap'].AsVector1i := 0;  // Use the current texture.
end;

procedure TgxCustomGLSLMLBumpShader.DoInitialize(var rci : TgxRenderContextInfo; Sender : TObject);
var
  I: Integer;
  lLightCount: Integer;
begin
  GetMLVertexProgramCode(VertexProgram.Code);
  
  with FragmentProgram.Code do
  begin
    GetMLFragmentProgramCodeBeg(FragmentProgram.Code, FSpecularTexture <> nil, FNormalTexture <> nil);

    lLightCount := 0;

    // Repeat for all lights.
    for I := 0 to vxsShaderMaxLightSources - 1 do
      if I + 1 in FLightSources then
      begin
        GetMLFragmentProgramCodeMid(FragmentProgram.Code, I);
        Inc(lLightCount);
      end;

    GetMLFragmentProgramCodeEnd(FragmentProgram.Code, lLightCount, FLightCompensation);
  end;
  VertexProgram.Enabled := True;
  FragmentProgram.Enabled := True;
  inherited;
end;

procedure TgxCustomGLSLMLBumpShader.SetLightCompensation(
  const Value: Single);
begin
  FLightCompensation := Value;
  FinalizeShader;
end;

procedure TgxCustomGLSLMLBumpShader.SetLightSources(
  const Value: TgxLightSourceSet);
begin
  Assert(Value <> [], strErrorEx + strShaderNeedsAtLeastOneLightSource);
  FLightSources := Value;
  FinalizeShader;
end;

function TgxCustomGLSLMLBumpShader.GetShaderAlpha: Single;
begin
  //ignore
  Result := -1;
end;

procedure TgxCustomGLSLMLBumpShader.GetShaderColorParams(var AAmbientColor,
  ADiffuseColor, ASpecularcolor: TVector4f);
begin
  //ignore
  AAmbientColor := NullHmgVector;
  ADiffuseColor := NullHmgVector;
  ASpecularcolor := NullHmgVector;
end;

function TgxCustomGLSLMLBumpShader.GetShaderDescription: string;
begin
  Result := 'ShaderTexture1 is NormalMap, ShaderTexture2 is SpecularMap';
end;

procedure TgxCustomGLSLMLBumpShader.GetShaderMiscParameters(
  var ACadencer: TgxCadencer; var AMatLib: TgxMaterialLibrary;
  var ALightSources: TgxLightSourceSet);
begin
  ACadencer := nil;
  AMatLib := FMaterialLibrary;
  ALightSources := FLightSources;
end;

procedure TgxCustomGLSLMLBumpShader.GetShaderTextures(
  var Textures: array of TgxTexture);
begin
  Textures[0] := FNormalTexture;
  Textures[1] := FSpecularTexture;
end;

procedure TgxCustomGLSLMLBumpShader.SetShaderAlpha(const Value: Single);
begin
  //ignore
end;

procedure TgxCustomGLSLMLBumpShader.SetShaderColorParams(const AAmbientColor,
  ADiffuseColor, ASpecularcolor: TVector4f);
begin
  //ignore
end;

procedure TgxCustomGLSLMLBumpShader.SetShaderMiscParameters(
  const ACadencer: TgxCadencer; const AMatLib: TgxMaterialLibrary;
  const ALightSources: TgxLightSourceSet);
begin
  SetMaterialLibrary(AMatLib);
  SetLightSources(ALightSources);
end;

procedure TgxCustomGLSLMLBumpShader.SetShaderTextures(
  const Textures: array of TgxTexture);
begin
  SetNormalTexture(Textures[0]);
  SetSpecularTexture(Textures[1]);
end;

initialization
  RegisterClasses([TgxSLBumpShaderMT, TgxSLBumpShader, TgxSLBumpShaderAM,
                   TgxSLMLBumpShader, TgxSLMLBumpShaderMT]);

end.

