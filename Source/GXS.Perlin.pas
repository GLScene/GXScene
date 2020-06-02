//
// The unit is for GXScene Engine
//
{
  Classes for generating perlin noise.

  The components and classes in the unit are a base to generate textures and heightmaps from,
  A Perlin Height Data Source have been included as an example. Use this combined with a terrain renderer for an infinite random landscape

}
unit GXS.Perlin;

interface

{$I GXS.Scene.inc}

uses
  System.Classes,
  System.SysUtils,
  System.Math,
  FMX.Graphics,

  GXS.CrossPlatform,
  Scene.VectorGeometry,
  GXS.PerlinBase, 
  GXS.HeightData;

Type
  TgxPerlinInterpolation = (pi_none, pi_simple, pi_linear, pi_Smoothed,
    pi_Cosine, pi_cubic);

  TgxBasePerlinOctav = class
  private
    FAmplitude: Double;
    FScale: Double;
    FInterpolation: TgxPerlinInterpolation;
    FSmoothing: TgxPerlinInterpolation;
  public
    Procedure Generate; virtual; abstract;
    property Interpolation: TgxPerlinInterpolation read FInterpolation
      write FInterpolation;
    property Smoothing: TgxPerlinInterpolation read FSmoothing write FSmoothing;
    property Amplitude: Double read FAmplitude write FAmplitude;
    property Scale: Double read FScale write FScale;
  End;

  TgxPerlinOctav = class of TgxBasePerlinOctav;

  TgxBasePerlin = class(TComponent)
  private
    FPersistence: Double;
    FNumber_Of_Octaves: Integer;
    FOctaves: TList;
    FOctavClass: TgxPerlinOctav;
    FInterpolation: TgxPerlinInterpolation;
    FSmoothing: TgxPerlinInterpolation;
  protected
    function PerlinNoise_1D(x: Double): Double;
    function PerlinNoise_2D(x, y: Double): Double;
    function GetOctave(index: Integer): TgxBasePerlinOctav;
    Procedure SetPersistence(val: Double);
    Procedure Set_Number_Of_Octaves(val: Integer);
  public
    Constructor Create(AOwner: TComponent); override;
    Procedure Generate; virtual; abstract;
    Property Octaves[index: Integer]: TgxBasePerlinOctav read GetOctave;
  published
    property Smoothing: TgxPerlinInterpolation read FSmoothing write FSmoothing;
    property Interpolation: TgxPerlinInterpolation read FInterpolation
      write FInterpolation;
    property Persistence: Double read FPersistence write SetPersistence;
    property Number_Of_Octaves: Integer read FNumber_Of_Octaves
      write Set_Number_Of_Octaves;
  End;

  Tgx1DPerlin = class(TgxBasePerlin)
    Function GetPerlinValue_1D(x: Double): Double;
  published
  End;

  Tgx2DPerlinOctav = class(TgxBasePerlinOctav)
  public
    Data: T2DPerlinArray;
    Width, Height: Integer;
    XStart, YStart: Integer;
    XStep, YStep: Integer;
    YRate: Integer;
    Procedure Generate; override;
    Function GetDataSmoothed(x, y: Integer): Double;
    Function GetData(x, y: Integer): Double;

    Function GetCubic(x, y: Double): Double;
    Function GetCosine(x, y: Double): Double;
    Function GetPerling(x, y: Double): Double;
    Procedure Generate_CubicInterpolate;
    Procedure Generate_SmoothInterpolate;
    Procedure Generate_NonInterpolated;
  End;

  Tgx2DPerlin = class(TgxBasePerlin)
  private
  public
    Width, Height: Integer;
    XStart, YStart: Integer;
    XStep, YStep: Integer;
    MaxValue, MinValue: Double;
    Constructor Create(AOwner: TComponent); override;
    Procedure Generate; override;
    Function GetPerlinValue_2D(x, y: Double): Double;
    Procedure MakeBitmap(Param: TBitmap);
    Procedure SetHeightData(heightData: TgxHeightData);
  end;

  TgxPerlinHDS = class(TgxHeightDataSource)
  private
    FInterpolation: TgxPerlinInterpolation;
    FSmoothing: TgxPerlinInterpolation;
    FPersistence: Double;
    FNumber_Of_Octaves: Integer;
    FLines: TStrings;
    FLinesChanged: Boolean;
    FXStart, FYStart: Integer;
  public
    MaxValue, MinValue: Double;
    Stall: Boolean;
    Constructor Create(AOwner: TComponent); override;
    procedure StartPreparingData(heightData: TgxHeightData); override;
    procedure WaitFor;
    property Lines: TStrings read FLines;
    property LinesChanged: Boolean read FLinesChanged write FLinesChanged;
  published
    property Interpolation: TgxPerlinInterpolation read FInterpolation
      write FInterpolation;
    property Smoothing: TgxPerlinInterpolation read FSmoothing write FSmoothing;
    property Persistence: Double read FPersistence write FPersistence;
    property Number_Of_Octaves: Integer read FNumber_Of_Octaves
      write FNumber_Of_Octaves;
    property MaxPoolSize;
    property XStart: Integer read FXStart write FXStart;
    property YStart: Integer read FYStart write FYStart;
  End;

  TgxPerlinHDSThread = class(TgxHeightDataThread)
    Perlin: Tgx2DPerlin;
    PerlinSource: TgxPerlinHDS;
    Procedure OpdateOutSide;
    Procedure Execute; override;
  end;
//---------------------------------------------------------------------
implementation
//---------------------------------------------------------------------
function TgxBasePerlin.PerlinNoise_1D(x: Double): Double;

var
  int_x: Integer;
  frac_x: Double;

begin
  int_x := Round(Int(x));
  frac_x := x - int_x;
  case Interpolation of
    pi_none:
      Result := 0;
    pi_simple:
      Result := Perlin_Random1(int_x);
    pi_linear:
      Result := Linear_Interpolate(Perlin_Random1(int_x),
        Perlin_Random1(int_x + 1), frac_x);
    pi_cubic:
      Result := Cubic_Interpolate(Perlin_Random1(int_x - 1),
        Perlin_Random1(int_x), Perlin_Random1(int_x + 1),
        Perlin_Random1(int_x + 2), frac_x);
    pi_Cosine:
      Result := Cosine_Interpolate(Perlin_Random1(int_x),
        Perlin_Random1(int_x + 1), frac_x);
  else
    raise exception.Create
      ('TgxBasePerlin.PerlinNoise_1D, Interpolation not implemented!');
  End;
end;

function TgxBasePerlin.PerlinNoise_2D(x, y: Double): Double;
Var
  int_x, int_y: Integer;
  // frac_y,
  frac_x: Double;

Begin
  int_x := Round(Int(x));
  int_y := Round(Int(y));
  frac_x := x - int_x;
  // frac_y := y-int_y;
  case Interpolation of
    pi_none:
      Result := 0;
    pi_simple:
      Result := Perlin_Random2(int_x, int_y);
    pi_linear:
      Result := Linear_Interpolate(Perlin_Random1(int_x),
        Perlin_Random1(int_x + 1), frac_x);
    pi_cubic:
      Result := Cubic_Interpolate(Perlin_Random1(int_x - 1),
        Perlin_Random1(int_x), Perlin_Random1(int_x + 1),
        Perlin_Random1(int_x + 2), frac_x);
    pi_Cosine:
      Result := Cosine_Interpolate(Perlin_Random1(int_x),
        Perlin_Random1(int_x + 1), frac_x);
  else
    raise exception.Create
      ('TgxBasePerlin.PerlinNoise_1D, Interpolation not implemented!');
  End;
End;

function TgxBasePerlin.GetOctave(index: Integer): TgxBasePerlinOctav;
Begin
  Result := TgxBasePerlinOctav(FOctaves[index]);
End;

Procedure TgxBasePerlin.Set_Number_Of_Octaves(val: Integer);

Var
  XC: Integer;
  NewScale: Integer;
  Octav: TgxBasePerlinOctav;
Begin
  If val <> FNumber_Of_Octaves then
  Begin
    FNumber_Of_Octaves := val;
    For XC := FOctaves.Count to FNumber_Of_Octaves - 1 do
    Begin
      Octav := FOctavClass.Create;
      If FPersistence = 0 then
        Octav.FAmplitude := 0
      else
        Octav.FAmplitude := exp(ln(FPersistence) * (XC + 1));
      Octav.FInterpolation := Interpolation;
      Octav.FSmoothing := Smoothing;
      FOctaves.Add(Octav);
    End;
    For XC := FOctaves.Count - 1 downto FNumber_Of_Octaves do
    Begin
      Octav := Octaves[XC];
      FOctaves.Delete(XC);
      Octav.Free;
    End;

    NewScale := 1;
    For XC := FOctaves.Count - 1 downto 0 do
    Begin
      Octaves[XC].Scale := NewScale;
      NewScale := NewScale shl 1;
    End;

  End;
end;

Procedure TgxBasePerlin.SetPersistence(val: Double);

Var
  XC: Integer;
Begin
  If FPersistence <> val then
  Begin
    FPersistence := val;
    For XC := FOctaves.Count to FNumber_Of_Octaves - 1 do
    Begin
      Octaves[XC].FAmplitude := exp(ln(FPersistence) * XC);
    End;
  End;
End;

Constructor TgxBasePerlin.Create(AOwner: TComponent);

Begin
  inherited;
  FOctaves := TList.Create;
  FNumber_Of_Octaves := 0;
  FInterpolation := pi_Cosine;
  FSmoothing := pi_cubic;
End;

Function Tgx1DPerlin.GetPerlinValue_1D(x: Double): Double;
Var
  total, p, frequency, Amplitude: Double;
  n, i: Integer;
Begin
  total := 0;
  p := Persistence;
  n := Number_Of_Octaves - 1;

  For i := 0 to n do
  Begin

    frequency := 2 * i;
    Amplitude := p * i;

    total := total + PerlinNoise_1D(x * frequency) * Amplitude;

  end;

  Result := total;
End;

Procedure Tgx2DPerlinOctav.Generate;

Var
  YC: Integer;

Begin
  SetLength(Data, Height + 3); // needed for smoothing
  For YC := 0 to Height + 2 do
    SetLength(Data[YC], Width + 3); // needed for smoothing
  case Smoothing of
    pi_cubic:
      Begin
        Generate_CubicInterpolate;
      End;
    pi_Smoothed:
      Begin
        Generate_SmoothInterpolate;
      End;
    pi_none:
      ;
    pi_simple:
      Begin
        Generate_NonInterpolated;
      End;
  End;
End;

Function Tgx2DPerlinOctav.GetPerling(x, y: Double): Double;

Begin
  Result := 0;
  case Interpolation of
    pi_cubic:
      Begin
        Result := GetCubic(x, y);
      End;
    pi_Smoothed:
      Begin
      End;
    pi_Cosine:
      Begin
        Result := GetCosine(x, y);
      End;
  End;
End;

Procedure Tgx2DPerlinOctav.Generate_CubicInterpolate;

Var
  B1, B2, B3, B4, T1: T1DPerlinArray;
  StripWidth: Integer;
  Offset: Integer;
  YC: Integer;

Begin
  T1 := Nil;
  StripWidth := Width + 6;
  SetLength(B1, StripWidth);
  SetLength(B2, StripWidth);
  SetLength(B3, StripWidth);
  SetLength(B4, StripWidth);
  Offset := (XStart - 1) + (YStart - 1) * YStep * YRate;
  Perlin_Random1DStrip(Offset, StripWidth, XStep, FAmplitude, B1);
  inc(Offset, YRate * YStep);
  Perlin_Random1DStrip(Offset, StripWidth, XStep, FAmplitude, B2);
  inc(Offset, YRate * YStep);
  Perlin_Random1DStrip(Offset, StripWidth, XStep, FAmplitude, B3);
  inc(Offset, YRate * YStep);
  For YC := 0 to Height + 2 do
  Begin
    Perlin_Random1DStrip(Offset, StripWidth, XStep, FAmplitude, B4);
    inc(Offset, YRate * YStep);
    Cubic_Interpolate_Strip(B1, B2, B3, B4, Data[YC], Width + 3);
    T1 := B1;
    B1 := B2;
    B2 := B3;
    B3 := B4;
    B4 := T1;
  End;
  SetLength(B1, 0);
  SetLength(B2, 0);
  SetLength(B3, 0);
  SetLength(B4, 0);
End;

Procedure Tgx2DPerlinOctav.Generate_SmoothInterpolate;

Var
  B1, B2, B3, T1: T1DPerlinArray;
  StripWidth: Integer;
  Offset: Integer;
  YC: Integer;

Begin
  T1 := Nil;
  StripWidth := Width + 5;
  SetLength(B1, StripWidth);
  SetLength(B2, StripWidth);
  SetLength(B3, StripWidth);
  Offset := (XStart - 1) + (YStart - 1) * YStep * YRate;
  Perlin_Random1DStrip(Offset, StripWidth, XStep, FAmplitude, B1);
  inc(Offset, YRate * YStep);
  Perlin_Random1DStrip(Offset, StripWidth, XStep, FAmplitude, B2);
  inc(Offset, YRate * YStep);
  For YC := 0 to Height + 2 do
  Begin
    Perlin_Random1DStrip(Offset, StripWidth, XStep, FAmplitude, B3);
    inc(Offset, YRate * YStep);
    Smooth_Interpolate_Strip(B1, B2, B3, Data[YC], Width + 3);
    T1 := B1;
    B1 := B2;
    B2 := B3;
    B3 := T1;
  End;
  SetLength(B1, 0);
  SetLength(B2, 0);
  SetLength(B3, 0);
End;

Procedure Tgx2DPerlinOctav.Generate_NonInterpolated;

Var
  Offset: Integer;
  YC: Integer;

Begin
  Offset := XStart + YStart * YStep * YRate;
  For YC := 0 to Height + 2 do
  Begin
    Perlin_Random1DStrip(Offset, Width + 3, XStep, FAmplitude, Data[YC]);
    inc(Offset, YRate * YStep);

  End;
End;

Function Tgx2DPerlinOctav.GetDataSmoothed(x, y: Integer): Double;

Begin
  Result := (Data[y][x] + Data[y][x + 2] + Data[y + 2][x] + Data[y + 2][x + 2])
    / 16 + (Data[y + 1][x] + Data[y + 1][x + 2] + Data[y][x + 1] + Data[y + 2]
    [x + 1]) / 8 + Data[y + 1][x + 1] / 4; { }
End;

Function Tgx2DPerlinOctav.GetData(x, y: Integer): Double;

Begin
  Result := Data[y][x];
End;

Function Tgx2DPerlinOctav.GetCubic(x, y: Double): Double;

Var
  X_Int: Integer;
  Y_Int: Integer;
  X_Frac, Y_Frac: Double;

Begin
  X_Int := Round(Int(x));
  Y_Int := Round(Int(y));
  X_Frac := x - X_Int;
  Y_Frac := y - Y_Int;

  Result := (Cubic_Interpolate(GetData(X_Int, Y_Int + 1), GetData(X_Int + 1,
    Y_Int + 1), GetData(X_Int + 2, Y_Int + 1), GetData(X_Int + 3, Y_Int + 1),
    X_Frac) + Cubic_Interpolate(GetData(X_Int + 1, Y_Int), GetData(X_Int + 1,
    Y_Int + 1), GetData(X_Int + 1, Y_Int + 2), GetData(X_Int + 1, Y_Int + 3),
    Y_Frac)) / 2;
End;

Function Tgx2DPerlinOctav.GetCosine(x, y: Double): Double;

Var
  X_Int: Integer;
  Y_Int: Integer;
  X_Frac, Y_Frac: Double;

Begin
  X_Int := Round(Int(x));
  Y_Int := Round(Int(y));
  X_Frac := x - X_Int;
  Y_Frac := y - Y_Int;

  Result := Cosine_Interpolate(Cosine_Interpolate(GetData(X_Int, Y_Int),
    GetData(X_Int + 1, Y_Int), X_Frac),
    Cosine_Interpolate(GetData(X_Int, Y_Int + 1), GetData(X_Int + 1, Y_Int + 1),
    X_Frac), Y_Frac);
End;

Constructor Tgx2DPerlin.Create(AOwner: TComponent);

Begin
  inherited;
  Width := 256;
  Height := 256;
  XStart := 0;
  YStart := 0;
  XStep := 1;
  YStep := 1;
  FOctavClass := Tgx2DPerlinOctav;
End;

Procedure Tgx2DPerlin.Generate;

Var
  i: Integer;

Begin
  For i := 0 to Number_Of_Octaves - 1 do
    With Tgx2DPerlinOctav(Octaves[i]) do
    Begin
      Width := Round(Ceil(self.Width / Scale));
      Height := Round(Ceil(self.Height / Scale));
      XStart := Round(self.XStart / Scale);
      YStart := Round(self.YStart / Scale);
      XStep := self.XStep;
      YStep := self.YStep;
      YRate := 243 * 57 * 57;
      Generate;
    end;
End;

Function Tgx2DPerlin.GetPerlinValue_2D(x, y: Double): Double;
Var
  total, frequency, Amplitude: Double;
  i: Integer;
Begin
  total := 0;
  For i := 0 to Number_Of_Octaves - 1 do
  Begin

    frequency := 2 * i;
    Amplitude := Persistence * i;

    total := total + PerlinNoise_2D(x * frequency, y * frequency) * Amplitude;

  end;

  Result := total;
End;

Procedure Tgx2DPerlin.MakeBitmap(Param: TBitmap);

Var
  XC, YC: Integer;
  Octaver: Integer;
  Posi: PByte;
  B: Integer;
  Value: Double;
  S: String;

Begin

  MaxValue := -1;
  MinValue := 100;

  Param.Width := Width;
  Param.Height := Height;

  For YC := 0 to Height - 1 do
  Begin
    Posi := BitmapScanLine(Param, YC);
    For XC := 0 to Width - 1 do
    Begin
      Value := 0;
      For Octaver := 0 to FNumber_Of_Octaves - 1 do
        With Tgx2DPerlinOctav(Octaves[Octaver]) do
          Value := Value + GetPerling(XC / Scale, YC / Scale);

      Value := Value + 0.5;
      If MaxValue < Value then
        MaxValue := Value;

      If MinValue > Value then
        MinValue := Value;

      If Value > 1.0 then
      Begin
        S := '';
        For Octaver := 0 to FNumber_Of_Octaves - 1 do
          With Tgx2DPerlinOctav(Octaves[Octaver]) do
            S := S + FloatToStr(GetPerling(XC / Scale, YC / Scale)) + ' ,';
        Delete(S, Length(S) - 1, 2);
        // raise Exception.create('In Cubic_Interpolate_Strip a value greater than 1 occured! value = '+FloatToStr(Value)+' values=['+S+']');
      End;

      B := Round(Value * $FF) and $FF;
      Posi^ := B;
      inc(Posi);
    End;
  End;
End;

Procedure Tgx2DPerlin.SetHeightData(heightData: TgxHeightData);

Var
  XC, YC: Integer;
  Octaver: Integer;
  Posi: PSmallInt;
  Value: Double;
  S: String;

Begin

  MaxValue := -1;
  MinValue := 100;

  heightData.Allocate(hdtSmallInt);

  Posi := @heightData.SmallIntData^[0];
  For YC := 0 to Height - 1 do
  Begin
    For XC := 0 to Width - 1 do
    Begin
      Value := 0;
      For Octaver := 0 to FNumber_Of_Octaves - 1 do
        With Tgx2DPerlinOctav(Octaves[Octaver]) do
          Value := Value + GetPerling(XC / Scale, YC / Scale);

      // value = [-0,5 .. 0,5]
      Posi^ := Round(Value * 256 * 100);
      // 100 instead of 128 to keep it well in range!

      If MaxValue < Value then
        MaxValue := Value;

      If MinValue > Value then
        MinValue := Value;

      If Value > 1.0 then
      Begin
        S := '';
        For Octaver := 0 to FNumber_Of_Octaves - 1 do
          With Tgx2DPerlinOctav(Octaves[Octaver]) do
            S := S + FloatToStr(GetPerling(XC / Scale, YC / Scale)) + ' ,';
        Delete(S, Length(S) - 1, 2);
        // raise Exception.create('In Cubic_Interpolate_Strip a value greater than 1 occured! value = '+FloatToStr(Value)+' values=['+S+']');
      End;

      inc(Posi);
    End;
  End;
End;

Constructor TgxPerlinHDS.Create(AOwner: TComponent);

Begin
  inherited;
  FLines := TStringList.Create;
  FInterpolation := pi_Cosine;
  FSmoothing := pi_cubic;
  FPersistence := 0.4;
  FNumber_Of_Octaves := 6;
  MaxValue := -MaxInt;
  MinValue := MaxInt;
  MaxThreads := 1;
End;

procedure TgxPerlinHDS.StartPreparingData(heightData: TgxHeightData);

Var
  Perlin: Tgx2DPerlin;
  Thread: TgxPerlinHDSThread;

Begin
  If Stall then
    heightData.DataState := hdsNone
  else
    heightData.DataState := hdsPreparing;
  Perlin := Tgx2DPerlin.Create(self);
  Perlin.Width := heightData.Size;
  Perlin.Height := heightData.Size;
  Perlin.XStart := heightData.XLeft + XStart;
  Perlin.YStart := heightData.YTop + YStart;

  Perlin.Interpolation := Interpolation;
  Perlin.Smoothing := Smoothing;
  Perlin.Persistence := Persistence;
  Perlin.Number_Of_Octaves := Number_Of_Octaves;

  If MaxThreads > 1 then
  Begin
    Thread := TgxPerlinHDSThread.Create(True);
    Thread.FreeOnTerminate := True;
    heightData.Thread := Thread;
    Thread.FHeightData := heightData;
    Thread.Perlin := Perlin;
    Thread.PerlinSource := self;
    Thread.Start;
  End
  else
  Begin
    Perlin.Generate;
    Perlin.SetHeightData(heightData);
    heightData.DataState := hdsReady;

    If MaxValue < Perlin.MaxValue then
      MaxValue := Perlin.MaxValue;

    If MinValue < Perlin.MinValue then
      MinValue := Perlin.MinValue;
    Perlin.Free;
  end;

  Lines.Add('Prepared Perlin (' + IntToStr(Perlin.XStart) + ',' +
    IntToStr(Perlin.YStart) + ') size ' + IntToStr(Perlin.Width));
  LinesChanged := True;
End;

procedure TgxPerlinHDS.WaitFor;

Var
  HDList: TList;
  HD: TgxHeightData;
  XC: Integer;
Begin
  Repeat
    HDList := Data.LockList;
    try
      HD := Nil;
      For XC := 0 to HDList.Count - 1 do
      Begin
        HD := TgxHeightData(HDList[XC]);
        If HD.DataState <> hdsReady then
          Break;
      End;
      If Assigned(HD) then
        If HD.DataState = hdsReady then
          Break;
    finally
      Data.UnlockList;
    End;
    Sleep(10);
  Until False;
End;

Procedure TgxPerlinHDSThread.Execute;

Begin
  Perlin.Generate;
  Perlin.SetHeightData(FHeightData);
  FHeightData.DataState := hdsReady;

  If PerlinSource.MaxValue < Perlin.MaxValue then
    PerlinSource.MaxValue := Perlin.MaxValue;

  If PerlinSource.MinValue < Perlin.MinValue then
    PerlinSource.MinValue := Perlin.MinValue;
  Perlin.Free;
end;

Procedure TgxPerlinHDSThread.OpdateOutSide;

Begin
End;

initialization

RegisterClasses([TgxPerlinHDS]);

end.
