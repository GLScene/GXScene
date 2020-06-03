//
// Graphic Scene Engine, http://glscene.org
//
{
   Skeleton colliders for defining and controlling verlet
   constraints. 
    
}
unit GXS.VerletSkeletonColliders;

interface

uses
  System.Classes,
   
  Scene.PersistentClasses, 
  Scene.VectorGeometry, 
  GXS.VectorFileObjects,
  GXS.VerletTypes,  
  Scene.VectorTypes;

type
  
  // TSCVerletBase
  //
  { Base verlet skeleton collider class. }
  TSCVerletBase = class(TgxSkeletonCollider)
    private
      FVerletConstraint : TVerletConstraint;

    public
      procedure WriteToFiler(writer : TVirtualWriter); override;
      procedure ReadFromFiler(reader : TVirtualReader); override;
      procedure AddToVerletWorld(VerletWorld : TgxVerletWorld); virtual;

      { The verlet constraint is created through the AddToVerletWorld
         procedure. }
      property VerletConstraint : TVerletConstraint read FVerletConstraint;
  end;

  // TSCVerletSphere
  //
  { Sphere shaped verlet constraint in a skeleton collider. }
  TSCVerletSphere = class(TSCVerletBase)
    private
      FRadius : Single;

    protected
      procedure SetRadius(const val : Single);

    public
      constructor Create; override;
      procedure WriteToFiler(writer : TVirtualWriter); override;
      procedure ReadFromFiler(reader : TVirtualReader); override;
      procedure AddToVerletWorld(VerletWorld : TgxVerletWorld); override;
      procedure AlignCollider; override;

      property Radius : Single read FRadius write SetRadius;
  end;

  // TSCVerletCapsule
  //
  { Capsule shaped verlet constraint in a skeleton collider. }
  TSCVerletCapsule = class(TSCVerletBase)
    private
      FRadius,
      FLength : Single;

    protected
      procedure SetRadius(const val : Single);
      procedure SetLength(const val : Single);

    public
      constructor Create; override;
      procedure WriteToFiler(writer : TVirtualWriter); override;
      procedure ReadFromFiler(reader : TVirtualReader); override;
      procedure AddToVerletWorld(VerletWorld : TgxVerletWorld); override;
      procedure AlignCollider; override;

      property Radius : Single read FRadius write SetRadius;
      property Length : Single read FLength write SetLength;
  end;

{ After loading call this function to add all the constraints in a
   skeleton collider list to a given verlet world. }
procedure AddSCVerletConstriantsToVerletWorld(
  colliders : TgxSkeletonColliderList; world : TgxVerletWorld);

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------
// ------------------ Global methods ------------------
// ------------------

// AddSCVerletConstriantsToVerletWorld
//
procedure AddSCVerletConstriantsToVerletWorld(
  colliders : TgxSkeletonColliderList; world : TgxVerletWorld);
var
  i : Integer;
begin
  for i:=0 to colliders.Count-1 do
    if colliders[i] is TSCVerletBase then
      TSCVerletBase(colliders[i]).AddToVerletWorld(world);
end;

// ------------------
// ------------------ TSCVerletBase ------------------
// ------------------

// WriteToFiler
//
procedure TSCVerletBase.WriteToFiler(writer : TVirtualWriter);
begin
  inherited WriteToFiler(writer);
  with writer do begin
    WriteInteger(0); // Archive Version 0
  end;
end;

// ReadFromFiler
//
procedure TSCVerletBase.ReadFromFiler(reader : TVirtualReader);
var
  archiveVersion : integer;
begin
  inherited ReadFromFiler(reader);
  archiveVersion:=reader.ReadInteger;
  if archiveVersion=0 then with reader do
    // Nothing yet
  else RaiseFilerException(archiveVersion);
end;

// AddToVerletWorld
//
procedure TSCVerletBase.AddToVerletWorld(VerletWorld : TgxVerletWorld);
begin
  AlignCollider;
end;


// ------------------
// ------------------ TSCVerletSphere ------------------
// ------------------

// Create
//
constructor TSCVerletSphere.Create;
begin
  inherited;
  Radius:=0.5;
  AlignCollider;
end;

// WriteToFiler
//
procedure TSCVerletSphere.WriteToFiler(writer : TVirtualWriter);
begin
  inherited WriteToFiler(writer);
  with writer do begin
    WriteInteger(0); // Archive Version 0
    WriteFloat(FRadius);
  end;
end;

// ReadFromFiler
//
procedure TSCVerletSphere.ReadFromFiler(reader : TVirtualReader);
var
  archiveVersion : integer;
begin
  inherited ReadFromFiler(reader);
  archiveVersion:=reader.ReadInteger;
  if archiveVersion=0 then with reader do
    Radius:=ReadFloat
  else RaiseFilerException(archiveVersion);
end;

// AddToVerletWorld
//
procedure TSCVerletSphere.AddToVerletWorld(VerletWorld : TgxVerletWorld);
begin
  FVerletConstraint:=TVCSphere.Create(VerletWorld);
  TVCSphere(FVerletConstraint).Radius:=FRadius;
  inherited;
end;

// AlignCollider
//
procedure TSCVerletSphere.AlignCollider;
begin
  inherited;
  if Assigned(FVerletConstraint) then
    TVCSphere(FVerletConstraint).Location:=AffineVectorMake(GlobalMatrix.W);
end;

// SetRadius
//
procedure TSCVerletSphere.SetRadius(const val : Single);
begin
  if val<>FRadius then begin
    FRadius:=val;
    if Assigned(FVerletConstraint) then
      TVCSphere(FVerletConstraint).Radius:=FRadius;
  end;
end;


// ------------------
// ------------------ TSCVerletCapsule ------------------
// ------------------

// Create
//
constructor TSCVerletCapsule.Create;
begin
  inherited;
  Radius:=0.5;
  Length:=1;
  AlignCollider;
end;

// WriteToFiler
//
procedure TSCVerletCapsule.WriteToFiler(writer : TVirtualWriter);
begin
  inherited WriteToFiler(writer);
  with writer do begin
    WriteInteger(0); // Archive Version 0
    WriteFloat(FRadius);
    WriteFloat(FLength);
  end;
end;

// ReadFromFiler
//
procedure TSCVerletCapsule.ReadFromFiler(reader : TVirtualReader);
var
  archiveVersion : integer;
begin
  inherited ReadFromFiler(reader);
  archiveVersion:=reader.ReadInteger;
  if archiveVersion=0 then with reader do begin
    Radius:=ReadFloat;
    Length:=ReadFloat;
  end else RaiseFilerException(archiveVersion);
end;

// AddToVerletWorld
//
procedure TSCVerletCapsule.AddToVerletWorld(VerletWorld : TgxVerletWorld);
begin
  FVerletConstraint:=TVCCapsule.Create(VerletWorld);
  TVCCapsule(FVerletConstraint).Radius:=FRadius;
  TVCCapsule(FVerletConstraint).Length:=FLength;
  inherited;
end;

// AlignCollider
//
procedure TSCVerletCapsule.AlignCollider;
begin
  inherited;
  if Assigned(FVerletConstraint) then begin
    TVCCapsule(FVerletConstraint).Location:=AffineVectorMake(GlobalMatrix.W);
    TVCCapsule(FVerletConstraint).Axis:=AffineVectorMake(GlobalMatrix.Y);
  end;
end;

// SetRadius
//
procedure TSCVerletCapsule.SetRadius(const val : Single);
begin
  if val<>FRadius then begin
    FRadius:=val;
    if Assigned(FVerletConstraint) then
      TVCCapsule(FVerletConstraint).Radius:=FRadius;
  end;
end;

// SetLength
//
procedure TSCVerletCapsule.SetLength(const val : Single);
begin
  if val<>FLength then begin
    FLength:=val;
    if Assigned(FVerletConstraint) then
      TVCCapsule(FVerletConstraint).Length:=FLength;
  end;
end;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
initialization
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

  RegisterClasses([TSCVerletBase,TSCVerletSphere,TSCVerletCapsule]);

end.
