//
// Graphic Scene Engine, http://glscene.org
//
(*
  Coordinate related classes.
*)

unit GXS.Coordinates;

interface

{$I Scene.inc}

uses
  System.Classes,
  System.SysUtils,

  Import.OpenGLx,
  Scene.VectorGeometry,
  Scene.VectorTypes, 
  GXS.BaseClasses,
  GXS.CrossPlatform;

type
  { Identifie le type de données stockées au sein d'un TgxCustomCoordinates.
    csPoint2D : a simple 2D point (Z=0, W=0)
    csPoint : un point (W=1)
    csVector : un vecteur (W=0)
    csUnknown : aucune contrainte  }
  TgxCoordinatesStyle = (csPoint2D, csPoint, csVector, csUnknown);

  { Stores and homogenous vector.
    This class is basicly a container for a TVector, allowing proper use of
    delphi property editors and editing in the IDE. Vector/Coordinates
    manipulation methods are only minimal. 
    Handles dynamic default values to save resource file space.  }
  TgxCustomCoordinates = class(TgxUpdateAbleObject)
  private
    FCoords: TVector;
    FStyle: TgxCoordinatesStyle; // NOT Persistent
    FPDefaultCoords: PVector;
    procedure SetAsPoint2D(const Value: TVector2f);
    procedure SetAsVector(const Value: TVector);
    procedure SetAsAffineVector(const Value: TAffineVector);
    function GetAsAffineVector: TAffineVector; inline;
    function GetAsPoint2D: TVector2f;
    function GetAsString: String;
    function GetCoordinate(const AIndex: Integer): Single; inline;
    procedure SetCoordinate(const AIndex: Integer; const AValue: Single); inline;
    function GetDirectCoordinate(const Index: Integer): Single; inline;
    procedure SetDirectCoordinate(const Index: Integer; const AValue: Single); inline;
  protected
    procedure SetDirectVector(const V: TVector); inline;
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadData(Stream: TStream);
    procedure WriteData(Stream: TStream);
  public
    constructor CreateInitialized(AOwner: TPersistent; const AValue: TVector;
      const AStyle: TgxCoordinatesStyle = CsUnknown);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure WriteToFiler(Writer: TWriter);
    procedure ReadFromFiler(Reader: TReader);
    procedure Initialize(const Value: TVector);
    procedure NotifyChange(Sender: TObject); override;
    { Identifies the coordinates styles.
      The property is NOT persistent, csUnknown by default, and should be
      managed by owner object only (internally).
      It is used by the TgxCustomCoordinates for internal "assertion" checks
      to detect "misuses" or "misunderstandings" of what the homogeneous
      coordinates system implies. }
    property Style: TgxCoordinatesStyle read FStyle write FStyle;
    procedure Translate(const TranslationVector: TVector); overload;
    procedure Translate(const TranslationVector: TAffineVector); overload;
    procedure AddScaledVector(const Factor: Single; const TranslationVector: TVector); overload;
    procedure AddScaledVector(const Factor: Single; const TranslationVector: TAffineVector); overload;
    procedure Rotate(const AnAxis: TAffineVector; AnAngle: Single); overload;
    procedure Rotate(const AnAxis: TVector; AnAngle: Single); overload;
    procedure Normalize; inline;
    procedure Invert;
    procedure Scale(Factor: Single);
    function VectorLength: Single;
    function VectorNorm: Single;
    function MaxXYZ: Single;
    function Equals(const AVector: TVector): Boolean; reintroduce;
    procedure SetVector(const X, Y: Single; Z: Single = 0); overload;
    procedure SetVector(const X, Y, Z, W: Single); overload;
    procedure SetVector(const V: TAffineVector); overload;
    procedure SetVector(const V: TVector); overload;
    procedure SetPoint(const X, Y, Z: Single); overload;
    procedure SetPoint(const V: TAffineVector); overload;
    procedure SetPoint(const V: TVector); overload;
    procedure SetPoint2D(const X, Y: Single); overload;
    procedure SetPoint2D(const Vector: TAffineVector); overload;
    procedure SetPoint2D(const Vector: TVector); overload;
    procedure SetPoint2D(const Vector: TVector2f); overload;
    procedure SetToZero;
    function AsAddress: PGLFloat; inline;
    { The coordinates viewed as a vector.
      Assigning a value to this property will trigger notification events,
      if you don't want so, use DirectVector instead. }
    property AsVector: TVector read FCoords write SetAsVector;
    { The coordinates viewed as an affine vector.
      Assigning a value to this property will trigger notification events,
      if you don't want so, use DirectVector instead.
      The W component is automatically adjustes depending on style. }
    property AsAffineVector: TAffineVector read GetAsAffineVector  write SetAsAffineVector;
    { The coordinates viewed as a 2D point.
      Assigning a value to this property will trigger notification events,
      if you don't want so, use DirectVector instead. }
    property AsPoint2D: TVector2f read GetAsPoint2D write SetAsPoint2D;
    property X: Single index 0 read GetCoordinate write SetCoordinate;
    property Y: Single index 1 read GetCoordinate write SetCoordinate;
    property Z: Single index 2 read GetCoordinate write SetCoordinate;
    property W: Single index 3 read GetCoordinate write SetCoordinate;
    property Coordinate[const AIndex: Integer]: Single read GetCoordinate write SetCoordinate; default;
    { The coordinates, in-between brackets, separated by semi-colons. }
    property AsString: String read GetAsString;
    // Similar to AsVector but does not trigger notification events
    property DirectVector: TVector read FCoords write SetDirectVector;
    property DirectX: Single index 0 read GetDirectCoordinate write SetDirectCoordinate;
    property DirectY: Single index 1 read GetDirectCoordinate write SetDirectCoordinate;
    property DirectZ: Single index 2 read GetDirectCoordinate write SetDirectCoordinate;
    property DirectW: Single index 3 read GetDirectCoordinate write SetDirectCoordinate;
  end;

  { A TgxCustomCoordinates that publishes X, Y properties. }
  TgxCoordinates2 = class(TgxCustomCoordinates)
  published
    property X stored False;
    property Y stored False;
  end;

  { A TgxCustomCoordinates that publishes X, Y, Z properties. }
  TgxCoordinates3 = class(TgxCustomCoordinates)
  published
    property X stored False;
    property Y stored False;
    property Z stored False;
  end;

  { A TgxCustomCoordinates that publishes X, Y, Z, W properties. }
  TgxCoordinates4 = class(TgxCustomCoordinates)
  published
    property X stored False;
    property Y stored False;
    property Z stored False;
    property W stored False;
  end;

  TgxCoordinates = TgxCoordinates3;

  { Actually Sender should be TgxCustomCoordinates, but that would require
   changes in a some other GXScene units and some other projects that use
   TgxCoordinatesUpdateAbleComponent }
  IVXCoordinatesUpdateAble = interface(IInterface)
    ['{ACB98D20-8905-43A7-AFA5-225CF5FA6FF5}']
    procedure CoordinateChanged(Sender: TgxCustomCoordinates);
  end;

  TgxCoordinatesUpdateAbleComponent = class(TgxUpdateAbleComponent,
    IVXCoordinatesUpdateAble)
  public
    procedure CoordinateChanged(Sender: TgxCustomCoordinates); virtual;
      abstract;
  end;

var
  { Specifies if TgxCustomCoordinates should allocate memory for
   their default values (ie. design-time) or not (run-time) }
  VUseDefaultCoordinateSets: Boolean = False;

//==================================================================
implementation
//==================================================================

const
  csVectorHelp =
    'If you are getting assertions here, consider using the SetPoint procedure';
  csPointHelp =
    'If you are getting assertions here, consider using the SetVector procedure';
  csPoint2DHelp =
    'If you are getting assertions here, consider using one of the SetVector or SetPoint procedures';

// ------------------
// ------------------ TgxCustomCoordinates ------------------
// ------------------
constructor TgxCustomCoordinates.CreateInitialized(AOwner: TPersistent;
  const AValue: TVector; const AStyle: TgxCoordinatesStyle = CsUnknown);
begin
  Create(AOwner);
  Initialize(AValue);
  FStyle := AStyle;
end;

destructor TgxCustomCoordinates.Destroy;
begin
  if Assigned(FPDefaultCoords) then
    Dispose(FPDefaultCoords);
  inherited;
end;

procedure TgxCustomCoordinates.Initialize(const Value: TVector);
begin
  FCoords := Value;
  if VUseDefaultCoordinateSets then
  begin
    if not Assigned(FPDefaultCoords) then
      New(FPDefaultCoords);
    FPDefaultCoords^ := Value;
  end;
end;

procedure TgxCustomCoordinates.Assign(Source: TPersistent);
begin
  if Source is TgxCustomCoordinates then
    FCoords := TgxCustomCoordinates(Source).FCoords
  else
    inherited;
end;

procedure TgxCustomCoordinates.WriteToFiler(Writer: TWriter);
var
  WriteCoords: Boolean;
begin
  with Writer do
  begin
    WriteInteger(0); // Archive Version 0
    if VUseDefaultCoordinateSets then
      WriteCoords := not VectorEquals(FPDefaultCoords^, FCoords)
    else
      WriteCoords := True;
    WriteBoolean(WriteCoords);
    if WriteCoords then
      Write(FCoords.X, SizeOf(FCoords));
  end;
end;

procedure TgxCustomCoordinates.ReadFromFiler(Reader: TReader);
var
  N: Integer;
begin
  with Reader do
  begin
    ReadInteger; // Ignore ArchiveVersion
    if ReadBoolean then
    begin
      N := SizeOf(FCoords);
      Assert(N = 4 * SizeOf(Single));
      Read(FCoords.X, N);
    end
    else if Assigned(FPDefaultCoords) then
      FCoords := FPDefaultCoords^;
  end;
end;

procedure TgxCustomCoordinates.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineBinaryProperty('Coordinates', ReadData, WriteData,
    not(Assigned(FPDefaultCoords) and VectorEquals(FPDefaultCoords^, FCoords)));
end;

procedure TgxCustomCoordinates.ReadData(Stream: TStream);
begin
  Stream.Read(FCoords, SizeOf(FCoords));
end;

procedure TgxCustomCoordinates.WriteData(Stream: TStream);
begin
  Stream.Write(FCoords, SizeOf(FCoords));
end;

procedure TgxCustomCoordinates.NotifyChange(Sender: TObject);
var
  Int: IVXCoordinatesUpdateAble;
begin
  if Supports(Owner, IVXCoordinatesUpdateAble, Int) then
    Int.CoordinateChanged(TgxCoordinates(Self));
  inherited NotifyChange(Sender);
end;

procedure TgxCustomCoordinates.Translate(const TranslationVector: TVector);
begin
  FCoords.X := FCoords.X + TranslationVector.X;
  FCoords.Y := FCoords.Y + TranslationVector.Y;
  FCoords.Z := FCoords.Z + TranslationVector.Z;
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.Translate(const TranslationVector
  : TAffineVector);
begin
  FCoords.X := FCoords.X + TranslationVector.X;
  FCoords.Y := FCoords.Y + TranslationVector.Y;
  FCoords.Z := FCoords.Z + TranslationVector.Z;
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.AddScaledVector(const Factor: Single;
  const TranslationVector: TVector);
var
  F: Single;
begin
  F := Factor;
  CombineVector(FCoords, TranslationVector, F);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.AddScaledVector(const Factor: Single;
  const TranslationVector: TAffineVector);
var
  F: Single;
begin
  F := Factor;
  CombineVector(FCoords, TranslationVector, F);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.Rotate(const AnAxis: TAffineVector;
  AnAngle: Single);
begin
  RotateVector(FCoords, AnAxis, AnAngle);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.Rotate(const AnAxis: TVector; AnAngle: Single);
begin
  RotateVector(FCoords, AnAxis, AnAngle);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.Normalize;
begin
  NormalizeVector(FCoords);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.Invert;
begin
  NegateVector(FCoords);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.Scale(Factor: Single);
begin
  ScaleVector(PAffineVector(@FCoords)^, Factor);
  NotifyChange(Self);
end;

function TgxCustomCoordinates.VectorLength: Single;
begin
  Result := Scene.VectorGeometry.VectorLength(FCoords);
end;

function TgxCustomCoordinates.VectorNorm: Single;
begin
  Result := Scene.VectorGeometry.VectorNorm(FCoords);
end;

function TgxCustomCoordinates.MaxXYZ: Single;
begin
  Result := Scene.VectorGeometry.MaxXYZComponent(FCoords);
end;

function TgxCustomCoordinates.Equals(const AVector: TVector): Boolean;
begin
  Result := VectorEquals(FCoords, AVector);
end;

procedure TgxCustomCoordinates.SetVector(const X, Y: Single; Z: Single = 0);
begin
  Assert(FStyle = csVector, csVectorHelp);
  Scene.VectorGeometry.SetVector(FCoords, X, Y, Z);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.SetVector(const V: TAffineVector);
begin
  Assert(FStyle = csVector, csVectorHelp);
  Scene.VectorGeometry.SetVector(FCoords, V);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.SetVector(const V: TVector);
begin
  Assert(FStyle = csVector, csVectorHelp);
  Scene.VectorGeometry.SetVector(FCoords, V);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.SetVector(const X, Y, Z, W: Single);
begin
  Assert(FStyle = csVector, csVectorHelp);
  Scene.VectorGeometry.SetVector(FCoords, X, Y, Z, W);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.SetDirectCoordinate(const Index: Integer;
  const AValue: Single);
begin
  FCoords.V[index] := AValue;
end;

procedure TgxCustomCoordinates.SetDirectVector(const V: TVector);
begin
  FCoords.X := V.X;
  FCoords.Y := V.Y;
  FCoords.Z := V.Z;
  FCoords.W := V.W;
end;

procedure TgxCustomCoordinates.SetToZero;
begin
  FCoords.X := 0;
  FCoords.Y := 0;
  FCoords.Z := 0;
  if FStyle = CsPoint then
    FCoords.W := 1
  else
    FCoords.W := 0;
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.SetPoint(const X, Y, Z: Single);
begin
  Assert(FStyle = CsPoint, CsPointHelp);
  MakePoint(FCoords, X, Y, Z);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.SetPoint(const V: TAffineVector);
begin
  Assert(FStyle = CsPoint, CsPointHelp);
  MakePoint(FCoords, V);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.SetPoint(const V: TVector);
begin
  Assert(FStyle = CsPoint, CsPointHelp);
  MakePoint(FCoords, V);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.SetPoint2D(const X, Y: Single);
begin
  Assert(FStyle = CsPoint2D, CsPoint2DHelp);
  MakeVector(FCoords, X, Y, 0);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.SetPoint2D(const Vector: TAffineVector);
begin
  Assert(FStyle = CsPoint2D, CsPoint2DHelp);
  MakeVector(FCoords, Vector);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.SetPoint2D(const Vector: TVector);
begin
  Assert(FStyle = CsPoint2D, CsPoint2DHelp);
  MakeVector(FCoords, Vector);
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.SetPoint2D(const Vector: TVector2f);
begin
  Assert(FStyle = CsPoint2D, CsPoint2DHelp);
  MakeVector(FCoords, Vector.X, Vector.Y, 0);
  NotifyChange(Self);
end;

function TgxCustomCoordinates.AsAddress: PGLFloat;
begin
  Result := @FCoords;
end;

procedure TgxCustomCoordinates.SetAsVector(const Value: TVector);
begin
  FCoords := Value;
  case FStyle of
    CsPoint2D:
      begin
        FCoords.Z := 0;
        FCoords.W := 0;
      end;
    CsPoint:
      FCoords.W := 1;
    CsVector:
      FCoords.W := 0;
  else
    Assert(False);
  end;
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.SetAsAffineVector(const Value: TAffineVector);
begin
  case FStyle of
    CsPoint2D:
      MakeVector(FCoords, Value);
    CsPoint:
      MakePoint(FCoords, Value);
    CsVector:
      MakeVector(FCoords, Value);
  else
    Assert(False);
  end;
  NotifyChange(Self);
end;

procedure TgxCustomCoordinates.SetAsPoint2D(const Value: TVector2f);
begin
  case FStyle of
    CsPoint2D, CsPoint, CsVector:
      begin
        FCoords.X := Value.X;
        FCoords.Y := Value.Y;
        FCoords.Z := 0;
        FCoords.W := 0;
      end;
  else
    Assert(False);
  end;
  NotifyChange(Self);
end;

function TgxCustomCoordinates.GetAsAffineVector: TAffineVector;
begin
  Scene.VectorGeometry.SetVector(Result, FCoords);
end;

function TgxCustomCoordinates.GetAsPoint2D: TVector2f;
begin
  Result.X := FCoords.X;
  Result.Y := FCoords.Y;
end;

procedure TgxCustomCoordinates.SetCoordinate(const AIndex: Integer;
  const AValue: Single);
begin
  FCoords.C[AIndex] := AValue;
  NotifyChange(Self);
end;

function TgxCustomCoordinates.GetCoordinate(const AIndex: Integer): Single;
begin
  Result := FCoords.C[AIndex];
end;

function TgxCustomCoordinates.GetDirectCoordinate(
  const Index: Integer): Single;
begin
  Result := FCoords.C[index]
end;

function TgxCustomCoordinates.GetAsString: String;
begin
  case Style of
    CsPoint2D:
      Result := Format('(%g; %g)', [FCoords.X, FCoords.Y]);
    CsPoint:
      Result := Format('(%g; %g; %g)', [FCoords.X, FCoords.Y, FCoords.Z]);
    CsVector:
      Result := Format('(%g; %g; %g; %g)', [FCoords.X, FCoords.Y, FCoords.Z,
        FCoords.W]);
  else
    Assert(False);
  end;
end;

//===================================================
initialization
//===================================================

RegisterClasses([TgxCoordinates2, TgxCoordinates3, TgxCoordinates4]);

end.
