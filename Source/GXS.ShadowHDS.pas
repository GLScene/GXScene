//
// The unit is for GXScene Engine
//
(*
   Implements an HDS that automatically generates a terrain lightmap texture

 Issues:1:Ambient and Diffuse light properties can not be set to 0, to avoid what
          seems to be a Delphi bug: If a property of type 'Single' is set to 0,
          Delphi seems to skip the property's set method at startup, and just
          uses the default value instead. (Does anyone know a better workaround?)
        2:Subsampling is not currently supported.
        3:If the light vector's y component is not 0 then the shadow edges may be
          a bit jagged, due to the crude Bresenham line algorythm that was used.
          You can hide this by increasing SoftRange though.
        5:At some light angles, rounding errors cause various artifacts:
         (Black tile edges / slight mis-alignments /etc.)
        6:Applying materials ocasionally causes AV's

PS. The RayCastShadowHeight function returns the height of the shadow at a point
on the terrain. This, and the LightVector may come in handy for implementing shadow volumes?
*)

unit GXS.ShadowHDS;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Math,

  OpenGLx,
  Scene.VectorLists,
  GXS.HeightData,
  GXS.Graphics,
  Scene.VectorGeometry,
  GXS.Texture,
  Scene.VectorTypes,
  GXS.Coordinates,
  GXS.Material;

type
   TgxShadowHDS = class;
   TNewTilePreparedEvent = procedure (Sender : TgxShadowHDS; 
     heightData : TgxHeightData;  ShadowMapMaterial : TgxLibMaterial) of object;
   TThreadBmp32 = procedure (Sender : TgxShadowHDS; heightData : TgxHeightData; 
     bmp32:TgxBitmap32) of object;

   { An Height Data Source that generates terrain shadow maps automatically.
      The HDS must be connected to another HDS, which will provide the elevation
      data, and to a MaterialLibrary where shadowmaps will be placed. }
	 TgxShadowHDS = class (TgxHeightDataSourceFilter)
	   private
         FTileSize:integer;
         FShadowmapLibrary : TgxMaterialLibrary;
         FLightVector : TgxCoordinates;
         FScale       : TgxCoordinates;
         FScaleVec     :TVector3f;
         FOnNewTilePrepared : TNewTilePreparedEvent;
         FOnThreadBmp32 : TThreadBmp32;
         //FSubSampling : Integer;
         FMaxTextures : integer;
         Step :TVector3f;
         FScanDistance:integer;
         FSoftRange:cardinal;
         FDiffuse:single;
         FAmbient:single;
         OwnerHDS:TgxHeightDataSource; //The owner of the tile
	   protected
         procedure SetShadowmapLibrary(const val : TgxMaterialLibrary);
         procedure SetScale(AValue: TgxCoordinates);
         procedure SetLightVector(AValue: TgxCoordinates);
         procedure SetSoftRange(AValue:cardinal);
         procedure SetDiffuse(AValue: Single);
         procedure SetAmbient(AValue: Single);
         //procedure SetSubSampling(const val : Integer);
         procedure Trim(MaxTextureCount:integer);
         function  FindUnusedMaterial:TgxLibMaterial;
         function  CalcStep:TAffineVector;
         function  CalcScale:TAffineVector;
    { Get the number of steps, before the current tile's edge is reached,
      in the direction of the step vector;}
         function  WrapDist(Lx,Ly:single):integer;
    // Converts local tile coordinates to world coordinages. Even if the coordinates are off the tile.
         procedure LocalToWorld(Lx,Ly:single;HD:TgxHeightData;var Wx:single;var Wy:single);
    // Takes World coordinates and returns the correct tile, and converted local coordinates
         procedure WorldToLocal(wx,wy:single;var HD:TgxHeightData;var lx:single; var ly:single);
	   public
         //When true, only a blank ShadowMap is generated (FAST), but OnThreadBmp32 is still called in a subthread.
         SkipGenerate:boolean;  
	     constructor Create(AOwner: TComponent); override;
         destructor  Destroy; override;
         //procedure   Release(aHeightData : TgxHeightData); override;
    (* This will repeatedly delete the oldest unused texture from the TGLMaterialLibrary,
     until the texture count drops to MaxTextureCount.
     DONT use this if you used TGLHeightData.MaterialName to link your terrain textures.
     Either use with TGLHeightData.LibMaterial, or manually delete unused LightMap textures.*)
         procedure   TrimTextureCache(MaxTextureCount:integer=0);
         procedure   Notification(AComponent: TComponent; Operation: TOperation); override;
    // Prepare a blank texture for this tile's lightmap, from the main thread
         procedure   BeforePreparingData(heightData : TgxHeightData); override;
    // Calculate the lightmap from the HD thread, using the attached blank texture
         procedure   PreparingData(heightData : TgxHeightData); override;
         procedure   AfterPreparingData(heightData : TgxHeightData); override;
         procedure   GenerateShadowMap(heightData:TgxHeightData; ShadowMap:TgxBitmap32; scale:Single);
    { This traces a ray from a point on the terrain surface, back to the Lightsource,
     while testing for any intersections with the terrain.
     It returns the height of the shadow. There is no shadow if the shadow height is equal to terrain height.
     This is slow, but only needs to be done for pixels along the tile edge, facing the light.}
         function    RayCastShadowHeight(HD:TgxHeightData;localX,localY:single):single;  overload;
         procedure   RayCastLine(HeightData:TgxHeightData;Lx,Ly:single;ShadowMap:TgxBitmap32);
    { Calculate the pixel brightness, using Direct Diffuse light and Ambient light.
     DirectLight  = 1 if in direct sunlight (no shadows)
     0 if in shadow. (Use "SoftRange" for soft shadow edges i.e. 1>Directlight>0 )
     AmbientLight = Relative to Angle between surface Normal and sky (Directly up)
     ie. Vertical walls are darker because they see less sky.
     DiffuseLight = Relative to Angle between surface Normal, and Sun vector.}
         function    Shade(HeightData:TgxHeightData;x,y:integer;ShadowHeight,TerrainHeight:single):byte;
	   published
         property ShadowmapLibrary : TgxMaterialLibrary read FShadowmapLibrary write SetShadowmapLibrary;
         property OnThreadBmp32 : TThreadBmp32 read FOnThreadBmp32 write FOnThreadBmp32; //WARNING: This runs in a subthread
         property OnNewTilePrepared : TNewTilePreparedEvent read FOnNewTilePrepared write FOnNewTilePrepared;
         property LightVector : TgxCoordinates read FLightVector write SetLightVector;
         property Scale       : TgxCoordinates read FScale write FScale;
         property ScanDistance: integer read FScanDistance write FScanDistance;
         property SoftRange   : cardinal read FSoftRange write SetSoftRange; 
		 //Shadow height above sufrace for max diffuse light
         property Diffuse     : single read FDiffuse write SetDiffuse;
         property Ambient     : single read FAmbient write SetAmbient;
         property MaxTextures : integer read FMaxTextures write FMaxTextures;
         property OnSourceDataFetched;
  end;

// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------

constructor TgxShadowHDS.Create(AOwner: TComponent);
begin
 	inherited Create(AOwner);
  FLightVector := TgxCoordinates.CreateInitialized(Self, VectorMake(1, 0,-1));
  FLightVector.Style:=csVector; //csPoint;
  FScale := TgxCoordinates.CreateInitialized(Self, VectorMake(1,1,1));
  FScale.Style:=csVector; //csPoint;
  FScanDistance:=64;
  FAmbient:=0.25;
  FDiffuse:=0.75;
  FSoftRange:=1;
  //FSubSampling:=1;
  OwnerHDS:=self; //Until told otherwise, assume that ShadowHDS IS the tile owner.
  SkipGenerate:=false; //Set to true in "OnSourceDataFetched" to skip shadow generation.
end;

destructor TgxShadowHDS.Destroy;
begin
  self.Active:=false;
  FreeAndNil(FLightVector);
  FreeAndNil(FScale);
  ShadowmapLibrary:=nil;
 	inherited Destroy;
end;

procedure TgxShadowHDS.Notification(AComponent: TComponent; Operation: TOperation);
begin
   if Operation=opRemove then begin
      if AComponent=FShadowmapLibrary then ShadowmapLibrary:=nil;
   end;
   inherited;
end;

{
procedure TgxShadowHDS.Release(aHeightData : TgxHeightData);
var libMat : TgxLibMaterial;
begin
  HeightDataSource.Data.LockList;
  libMat:=aHeightData.LibMaterial;
  aHeightData.MaterialName:='';
  if (FMaxTextures>0)and(assigned(LibMat))and(libMat.IsUsed=false)
    then LibMat.free;
  inherited;
  HeightDataSource.Data.UnlockList;
end;
}

procedure TgxShadowHDS.TrimTextureCache(MaxTextureCount:integer);  //Thread-safe Version
// Thread-safe Version
begin
  If(not assigned(self))or(not assigned(OwnerHDS)) then 
    exit;
  with OwnerHDS.Data.LockList do 
  try
    Trim(MaxTextureCount);
  finally
    OwnerHDS.Data.UnlockList;
  end;
end;

procedure TgxShadowHDS.Trim(MaxTextureCount:integer); //internal use only
var 
  matLib: TgxMaterialLibrary;
  libMat: TgxLibMaterial;
  i:integer;
  cnt:integer;
begin
  matLib:=FShadowmapLibrary;
  if matLib<>nil then 
  begin
    //---------------------------------
    //--Trim unused textures, until MaxTextureCount is reached--
    cnt:=matlib.Materials.Count;
    i:=0;
    while (i<cnt)and(cnt>=MaxTextureCount) do 
	begin
      libMat:=matlib.Materials[i];
      if libMat.IsUsed then 
	    inc(i)
      else
	  begin
        libmat.Free;
        dec(cnt);  //cnt:=matlib.Materials.Count;
      end;
    end;
    //----------------------------------------------------------
  end;
end;

function TgxShadowHDS.FindUnusedMaterial:TgxLibMaterial;
var 
  matLib: TgxMaterialLibrary;
    i:integer;
    cnt:integer;
begin
  result:=nil;
  matLib:=FShadowmapLibrary;
  if matLib<>nil then 
  begin
    cnt:=matlib.Materials.Count;
    i:=0;
    while(i<cnt)and(matlib.Materials[i].IsUsed) do inc(i);
    if (i<cnt) then 
	  result:=matlib.Materials[i];
  end;
end;

procedure TgxShadowHDS.SetLightVector(AValue: TgxCoordinates);
begin
  With OwnerHDS.Data.LockList do try
    FLightVector.Assign(AValue);
    CalcStep;
    //MarkDirty;
  finally OwnerHDS.Data.UnlockList; end;
end;

function TgxShadowHDS.CalcStep:TAffineVector;
var L:single;
    v:TAffineVector;
begin
  MakeVector(v,FLightVector.X/FScale.X,FLightVector.Y/FScale.Y,256*FLightVector.Z/FScale.Z);
  L:=MaxFloat(abs(v.X),abs(v.Y));
  Step:=VectorScale(v,1/L);
  step.X:=trunc(step.X*16384)/16384;  //round down the fraction now, to prevent rounding errors later
  step.Y:=trunc(step.Y*16384)/16384;  //round down the fraction now, to prevent rounding errors later

  if((FLightVector.X=0)and(FLightVector.Y=0))then begin
    step.X:=1;
    step.Y:=0;
    step.Z:=-maxint;
  end;

  result:=step;
end;

function TgxShadowHDS.CalcScale:TAffineVector;
begin
  FScaleVec.X:=FScale.X*256;
  FScaleVec.Y:=FScale.Y*256;
  FScaleVec.Z:=FScale.Z;
  result:=FScaleVec;
end;

procedure TgxShadowHDS.BeforePreparingData(heightData : TgxHeightData);
var HD    : TgxHeightData;
    libMat: TgxLibMaterial;
    MatName:string;
begin
  if not assigned(FShadowmapLibrary) then exit;
  HD:=HeightData;
  OwnerHDS:=HD.Owner;
  with OwnerHDS.Data.LockList do try
    Trim(FMaxTextures);
    MatName:='ShadowHDS_x'+IntToStr(HD.XLeft)+'y'+IntToStr(HD.YTop)+'.'; //name contains xy coordinates of the current tile
    libMat:=FShadowmapLibrary.Materials.Add;
    //---------Recycle Textures---------
    //libMat:=self.FindUnusedMaterial;                  //look for an unused texture, to recycle
    //if libMat=nil
    //  then libMat:=FShadowmapLibrary.Materials.Add    //if no free textures were found, get a new one
    //  else libMat.Material.Texture.Enabled:=false;    //recycle the unused texture
    //----------------------------------
    libMat.Name:=MatName;
    //HD.MaterialName:=LibMat.Name;
    HD.LibMaterial:=LibMat;  //attach texture to current tile
  finally OwnerHDS.Data.UnlockList; end;
end;


procedure TgxShadowHDS.PreparingData(heightData : TgxHeightData);
var HD    : TgxHeightData;
    libMat: TgxLibMaterial;
    bmp32 : TgxBitmap32;
begin
  HD:=HeightData;
  libMat:=HD.LibMaterial;
  Assert(Assigned(HD));
  Assert(Assigned(libMat));
  Assert(libMat.Material.Texture.Disabled);

  //With heightData.Owner.Data.LockList do try //lock out other threads
    //Transfer tile texture coordinates to generated texture
    libMat.TextureScale.X :=HD.TextureCoordinatesScale.S;
    libMat.TextureScale.Y :=HD.TextureCoordinatesScale.T;
    libMat.TextureOffset.X:=HD.TextureCoordinatesOffset.S;
    libMat.TextureOffset.Y:=HD.TextureCoordinatesOffset.T;
    //------------------------------------------------------
    //--Set up new Lightmap texture for the current tile--
    libMat.Material.MaterialOptions:=[moNoLighting];
    with libMat.Material.Texture do begin
      ImageClassName:=TgxBlankImage.ClassName;
      MinFilter:=miNearestMipmapNearest;
      //MinFilter:=miLinearMipmapLinear;
      //MagFilter:=maNearest;
      MagFilter:=maLinear;

      TextureMode:=tmReplace;
      TextureWrap:=twNone;
      //TextureFormat:=tfLuminance;
      TextureFormat:=tfRGB16;
      //TextureFormat:=tfRGBA;
      bmp32:=(Image as TgxBlankImage).GetBitmap32;
      if not SkipGenerate then
        GenerateShadowMap(HD , bmp32, 1);
      if Assigned(FOnThreadBmp32) then FOnThreadBmp32(self,heightData,bmp32);

      //Enabled:=True;
      with HD.Owner.Data.LockList do try Enabled:=True;
      finally HD.Owner.Data.UnlockList; end;
    end;
  //finally HD.Owner.Data.UnlockList; end;
  //----------------------------------------------------
end;

procedure TgxShadowHDS.AfterPreparingData(heightData : TgxHeightData);
begin
  if Assigned(FOnNewTilePrepared) then FOnNewTilePrepared(Self,heightData,heightData.LibMaterial);
end;


{
procedure TgxShadowHDS.PreparingData(heightData : TgxHeightData);
var HD    : TgxHeightData;
    libMat: TgxLibMaterial;
    bmp32 : TgxBitmap32;
    MatName:string;
    Hold:TgxUpdateAbleObject;
    lst:TList;
begin

  if not assigned (FShadowmapLibrary) then exit;
  //--Generate Shadow Map for tile--
  lst:=HeightDataSource.Data.LockList;   //lock out other threads
  //Uno.Acquire;
  HD:=HeightData;
  MatName:='ShadowHDS_x'+IntToStr(HD.XLeft)+'y'+IntToStr(HD.YTop)+'.'; //name contains xy coordinates of the current tile
  Hold:=TgxUpdateAbleObject.Create(self);

  LibMat:=FShadowmapLibrary.Materials.GetLibMaterialByName(MatName);   //Check if Tile Texture already exists
  //if assigned(libmat) then LibMat.Name:='Dirty';

  //LibMat:=nil;
  if LibMat=nil then begin
    if (FMaxTextures>0)and(HD.Thread=nil)  //Dont trim the cache from a sub-thread;
      then TrimTextureCache(FMaxTextures); //Trim unused textures from the material library
    //Generate new ShadowMap texture for this tile
    libMat:=FShadowmapLibrary.Materials.Add;
    libMat.RegisterUser(Hold);  //hold onto the texture, so another thread doesnt delete it

    //Transfer tile texture coordinates to generated texture
    libMat.TextureScale.X :=HD.TextureCoordinatesScale.S;
    libMat.TextureScale.Y :=HD.TextureCoordinatesScale.T;
    libMat.TextureOffset.X:=HD.TextureCoordinatesOffset.S;
    libMat.TextureOffset.Y:=HD.TextureCoordinatesOffset.T;
    //------------------------------------------------------
    //--Set up new Lightmap texture for the current tile--
    libMat.Material.MaterialOptions:=[moNoLighting];
    with libMat.Material.Texture do begin
      ImageClassName:=TgxBlankImage.ClassName;
      Enabled:=True;
      MinFilter:=miNearestMipmapNearest;
      //MagFilter:=maNearest;
      MagFilter:=maLinear;
      TextureMode:=tmReplace;
      //TextureWrap:=twBoth;
      TextureWrap:=twNone;
      //TextureFormat:=tfRGB16;
      //TextureFormat:=tfRGBA16;
      TextureFormat:=tfLuminanceAlpha;
      bmp32:=(Image as TgxBlankImage).GetBitmap32(GL_TEXTURE_2D);
      GenerateShadowMap(HD , bmp32, 1);
    end;
    libMat.Name:=MatName;
    //----------------------------------------------------
  end;
  //HD.MaterialName:=LibMat.Name;
  HD.LibMaterial:=LibMat;  //attach texture to current tile
  libMat.UnregisterUser(Hold);
  Hold.Free;
  //Uno.Release;
  HeightDataSource.Data.UnlockList;
  if Assigned(FOnNewTilePrepared) then FOnNewTilePrepared(Self,HD,libMat);
end;
}

procedure TgxShadowHDS.GenerateShadowMap(heightData:TgxHeightData; ShadowMap:TgxBitmap32; scale:Single);
var HD : TgxHeightData;
    x,y:integer;   //in local space
    sx,sy:single;
begin
  HD:=HeightData;
  FTileSize:=(HD.Size-1);
  ShadowMap.Height:=FTileSize;
  ShadowMap.Width :=FTileSize;
  CalcStep;
  CalcScale;
  sx:=step.X;
  sy:=step.Y;
  if abs(sx)>abs(sy) then begin
    y:=0;
    if sx<0 then x:=FTileSize-1     //right to left
    else x:=0;                      //left to right
    while(y<FTileSize) do begin
      RayCastLine(HD,x,y,ShadowMap); //cast a shadow line across the tile
      inc(y);
    end;
  end else begin
    x:=0;
    if sy<0 then y:=FTileSize-1     //top to bottom
    else y:=0;                      //bottom to top
    while(x<FTileSize) do begin
      RayCastLine(HD,x,y,ShadowMap); //cast a shadow line across the tile
      inc(x);
    end;
  end;
end;

function TgxShadowHDS.RayCastShadowHeight(HD:TgxHeightData;localX,localY:single):single;
var tmpHD:TgxHeightData;
    wx,wy:single;
    lx,ly:single;
    h:single;
    ctr:integer;
    rh:single;
    dif:single;
    ShadowDif:single;
    startH:single;
    jump:integer;
begin
  lx:=ClampValue(LocalX,0,FTileSize);
  ly:=ClampValue(LocalY,0,FTileSize);
  StartH:=HD.InterpolatedHeight(lx,ly);
  tmpHD:=HD;
  ctr:=0;
  ShadowDif:=0;
  rh:=StartH;
  jump:=1;
  while (ctr<FScanDistance)and(tmpHD.DataState<>hdsNone) do begin
    lx:=lx-step.X*jump;
    ly:=ly-step.Y*jump;
    rh:=rh-step.Z*jump;
    //--jump to new tile--
    if (lx<0)or(lx>=FTileSize)or(ly<0)or(ly>=FTileSize) then begin
      LocalToWorld(lx,ly,tmpHD,wx,wy); //if our local coordinates are off the tile,
      WorldToLocal(wx,wy,tmpHD,lx,ly); //get the new tile, and local coordinates
    end else begin
      h:=tmpHD.InterpolatedHeight(lx,ly);
      dif:=h-rh;
      ShadowDif:=MaxFloat(dif,ShadowDif);
      if ShadowDif>(-Step.Z)+FSoftRange   //if ray is more than 1 steps above the surface
        then jump:=2                       //then take 2 steps at a time
        else jump:=1;
      inc(ctr);
    end;
  end;
  result:=startH+ShadowDif;    //actual height of shadow
end;


procedure TgxShadowHDS.LocalToWorld(Lx,Ly:single;HD:TgxHeightData;var Wx:single;var Wy:single);
var HDS:TgxHeightDataSource;
begin
  HDS:=self.HeightDataSource;
  wx:=Lx+HD.XLeft;
  wy:=HDS.Height-HD.YTop-Ly;

  //wrap terrain                               //no longer needed?
  //if wx>=HDS.Width then wx:=wx-HDS.Width;
  //if wx<0 then wx:=wx+HDS.Width;
  //if wy>=HDS.Height then wy:=wy-HDS.Height;
  //if wy<0 then wy:=wy+HDS.Height;
end;

procedure TgxShadowHDS.WorldToLocal(Wx,Wy:single;var HD:TgxHeightData;var lx:single; var ly:single);
var HDS:TgxHeightDataSource;
    xleft,ytop:integer;
    size:integer;
begin
  //wrap terrain                               //no longer needed?
  //HDS:=self.HeightDataSource;
  //if wx>=HDS.Width then wx:=wx-HDS.Width;
  //if wx<0 then wx:=wx+HDS.Width;
  //if wy>=HDS.Height then wy:=wy-HDS.Height;
  //if wy<0 then wy:=wy+HDS.Height;

  HDS:=self.HeightDataSource;
  size:=FTileSize;
  xleft:=floor(wx/size)*size;
  lx:=wx-xLeft;
  ytop:=floor((HDS.Height-wy)/size)*size;
  ly:=(HDS.Height-ytop-wy);
  HD:=HDS.GetData(xleft,ytop,size+1,hdtSmallInt);
end;
//----------------------------------------------------------

procedure TgxShadowHDS.RayCastLine(HeightData:TgxHeightData;Lx,Ly:single;ShadowMap:TgxBitmap32);
var sh,h:single;
    HD:TgxHeightData;
    Size:integer;
    nmRow : PPixel32Array;
    ctr:integer;
    px,py:integer;
    lum:byte;
    wrapDst:integer;
    //pink:boolean;
    //PinkMax:integer;
    cx,cy:single;
    procedure LineStep; //draw the pixel, and increase counters
    begin
      cx:=ClampValue(lx,0,size-1);
      cy:=ClampValue(ly,0,size-1);
      px:=trunc(cx);
      py:=trunc(cy);
      h :=HD.InterpolatedHeight(cx,cy);
      sh:=maxFloat(sh,h);
      lum:=Shade(HD,px,py,sh,h);
      nmRow:=shadowMap.ScanLine[Size-1-py];
      nmRow[px].r:=lum;
      nmRow[px].g:=lum;
      nmRow[px].b:=lum;
      nmRow[px].a:=255;
      //pinkMax:=MinInteger(Integer(lum+8),255);
      //if pink=true then nmRow[px].r:=pinkMax;
      Lx:=Lx+step.X;
      Ly:=Ly+step.Y;
      sh:=sh+step.Z;
      inc(ctr);
    end;
begin
  HD:=HeightData;
  sh:=RayCastShadowHeight(HD,Lx,Ly);
  size:=FTileSize;
  ctr:=0;
  wrapDst:=WrapDist(Lx,Ly);
  //pink:=false;
  if wrapdst<size then begin        // check if this line will wrap before its end
    while ctr<=wrapdst do linestep; //take one exta step, to prevent gaps due to rounding errors
    Lx:=Lx-step.X;                 //
    Ly:=Ly-step.Y;                 // step back, to compensate for the extra step
    ctr:=ctr-1;                     //
    if abs(step.X)>abs(step.Y) then begin    //East or West
      if step.Y<0 then Ly:=Ly+size;           //ESE or WSW
      if step.Y>0 then Ly:=Ly-size;           //ENE or WNW
    end else begin                             //North or South
      if step.X<0 then Lx:=Lx+size;           //NNW or SSW
      if step.X>0 then Lx:=Lx-size;           //NNE or SSE
    end;
    cx:=ClampValue(Lx,0,size-1);
    cy:=ClampValue(Ly,0,size-1);
    sh:=RayCastShadowHeight(HD,cx,cy);
    sh:=sh+step.Z*0.4;
    //pink:=true;
  end;
  while ctr<size do linestep; //No wrapping
end;

//----------------------------------------------------------

function TgxShadowHDS.WrapDist(Lx,Ly:single):integer;
var x,y:single;
    size:integer;
    sx,sy:single;
begin
  sx:=step.X;
  sy:=step.Y;
  size:=FTileSize;
  x:=size;
  y:=size;
  if abs(sx)>abs(sy) then begin
    if sy>0 then y:=(size-Ly)/sy;
    if sy<0 then y:=-Ly/sy;
  end else begin
    if sx>0 then x:=(size-Lx)/sx;
    if sx<0 then x:=-Lx/sx;
  end;
  result:=Ceil(minFloat(x,y));
end;

function TgxShadowHDS.Shade(HeightData:TgxHeightData;x,y:integer;ShadowHeight,TerrainHeight:single):byte;
var HD:TgxHeightData;
    nv:TAffineVector;
    dot:single;
    sunVec:TAffineVector;
    directLight:single;   //Range:0-1  (0 if in shadow) (<1 and >0 if near shadow edge)
    diffuseLight:single;
    ambientLight:single;
    Light:single;
begin
  HD:=HeightData;
  nv:=HD.NormalAtNode(x,y,FScaleVec);
  //--Ambient Light from blue sky (directly up)--
  ambientLight:=nv.Z;
  //--Shadows/Direct light/Soft shadow edges--
  DirectLight:=ClampValue(1-(ShadowHeight-TerrainHeight)/SoftRange,0,1);
  //--Diffuse light, when not in shadow--
  if DirectLight=0 then diffuseLight:=0  //no direct light (shadow)
  else begin                             //diffused light ~ cos of normalVec and lightVec
    MakeVector(sunVec,LightVector.X,LightVector.Y,-LightVector.Z);
    NormalizeVector(SunVec);
    dot:=VectorDotProduct(nv,sunVec);    //cos of the angle between the normal and light
    diffuseLight:=maxFloat(dot,0);
  end;
  //-------------------------------------
  light:=(FDiffuse*diffuseLight*DirectLight)+(FAmbient*ambientLight);
  result:=round(ClampValue(light,0,1)*255);
end;

procedure TgxShadowHDS.SetShadowmapLibrary(const val : TgxMaterialLibrary);
begin
  if val <> FShadowmapLibrary then
  begin
    if assigned(FShadowmapLibrary) then
      FShadowmapLibrary.RemoveFreeNotification(Self);
    FShadowmapLibrary := val;
    if assigned(FShadowmapLibrary) then
      FShadowmapLibrary.FreeNotification(Self);
    MarkDirty;
  end;
end;

procedure TgxShadowHDS.SetScale(AValue: TgxCoordinates);
begin
  with OwnerHDS.Data.LockList do try
    FScale.Assign(AValue);
  //CalcScale;
  //MarkDirty;
  finally 
    OwnerHDS.Data.UnlockList; 
  end;
end;

procedure TgxShadowHDS.SetSoftRange(AValue:Cardinal);
begin
  with OwnerHDS.Data.LockList do 
  try
    FSoftRange:=MaxInteger(AValue,1);
    //MarkDirty;
  finally 
    OwnerHDS.Data.UnlockList; 
  end;
end;

procedure TgxShadowHDS.SetDiffuse(AValue: Single);
begin
  with OwnerHDS.Data.LockList do 
  try
    FDiffuse:=ClampValue(AValue,0.001,1);
    //MarkDirty;
  finally 
    OwnerHDS.Data.UnlockList; 
  end;
end;

procedure TgxShadowHDS.SetAmbient(AValue: Single);
begin
  with OwnerHDS.Data.LockList do 
  try
    FAmbient:=ClampValue(AValue,0.001,1);
    //MarkDirty;
  finally 
    OwnerHDS.Data.UnlockList; 
  end;
end;

// ------------------------------------------------------------------
initialization
// ------------------------------------------------------------------

	// class registrations
 RegisterClass(TgxShadowHDS);

end.
