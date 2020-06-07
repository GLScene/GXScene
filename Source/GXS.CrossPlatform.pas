(* ********************************************
  *                                           *
  *  Graphic Scene Engine, http://glscene.org *
  *                                           *
  ******************************************** *)

unit GXS.CrossPlatform;

(*
   Cross platform support functions and types.
   Ultimately, *no* cross-platform or cross-version defines should be present
   in the core units, and have all moved here instead.
*)

interface

{$I Scene.inc}

uses
  Winapi.Windows,
  Winapi.ShellApi,
  System.Types,
  System.UITypes,
  System.Classes,
  System.SysUtils,
  System.StrUtils,

  FMX.Types,
  FMX.Objects,
  FMX.Consts,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs;

type
  THalfFloat = type Word;
  PHalfFloat = ^THalfFloat;

  TGraphicClass = class of TBitmap; // class of TGraphic in VCL

  TgxTextLayout = (tlTop, tlCenter, tlBottom);

  TgxMouseEvent = procedure(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer) of object;

  EGLOSError = EOSError;

  TProjectTargetNameFunc = function(): string;

  // Several define from unit Consts
const
  sAllFilter: string = SMsgDlgAll; //in VCL -> sAllFilter;

  FONT_CHARS_COUNT = 2024;

var
  IsDesignTime: Boolean = False;
  vProjectTargetName: TProjectTargetNameFunc;

function GetRectangle(const aLeft, aTop, aRight, aBottom: Integer): TRect;
(* Increases or decreases the width and height of the specified rectangle.
   Adds dx units to the left and right ends of the rectangle and dy units to
   the top and bottom. *)
procedure InflateRectangle(var aRect: TRect; dx, dy: Integer);
procedure IntersectRectangle(var aRect: TRect; const rect2: TRect);

procedure RaiseLastOSError;

(* Number of pixels per logical inch along the screen width for the device.
   Under Win32 awaits a HDC and returns its LOGPIXELSX. *)
function GetDeviceLogicalPixelsX(device: THandle): Integer; ///in VCL -> HDC
// Number of bits per pixel for the current desktop resolution.
function GetCurrentColorDepth: Integer;
// Returns the number of color bits associated to the given pixel format.
function PixelFormatToColorBits(aPixelFormat: TPixelFormat): Integer;

// Returns the bitmap's scanline for the specified row.
function BitmapScanLine(aBitmap: TBitmap; aRow: Integer): Pointer;

// Replace path delimiter to delimiter of the current platform.
procedure FixPathDelimiter(var S: string);
// Remove if possible part of path witch leads to project executable.
function RelativePath(const S: string): string;
(* Returns the current value of the highest-resolution counter.
   If the platform has none, should return a value derived from the highest
   precision time reference available, avoiding, if possible, timers that
   allocate specific system resources. *)
procedure QueryPerformanceCounter(var val: Int64);
(* Returns the frequency of the counter used by QueryPerformanceCounter.
   Return value is in ticks per second (Hz), returns False if no precision
   counter is available. *)
function QueryPerformanceFrequency(var val: Int64): Boolean;

(* Starts a precision timer.
   Returned value should just be considered as 'handle', even if it ain't so.
   Default platform implementation is to use QueryPerformanceCounter and
   QueryPerformanceFrequency, if higher precision references are available,
   they should be used. The timer will and must be stopped/terminated/released
   with StopPrecisionTimer. *)
function StartPrecisionTimer: Int64;
(* Computes time elapsed since timer start.
   Return time lap in seconds. *)
function PrecisionTimerLap(const precisionTimer: Int64): Double;
(* Computes time elapsed since timer start and stop timer.
   Return time lap in seconds. *)
function StopPrecisionTimer(const precisionTimer: Int64): Double;

// Returns time in millisecond from application start.
function AppTime: Double;

function MessageBoxOK(const Text, Caption: string): Integer;
procedure GLLoadBitmapFromInstance(Instance: LongInt; ABitmap: TBitmap; AName: string);
procedure ShowHTMLUrl(Url: string);
//function GLGetTickCount: int64;
procedure SetExeDirectory;

// StrUtils.pas
function AnsiStartsText(const ASubText, AText: string): Boolean;

// Classes.pas
function IsSubComponent(const AComponent: TComponent): Boolean;
procedure MakeSubComponent(const AComponent: TComponent; const Value: Boolean);

function FindUnitName(anObject: TObject): string; overload;
function FindUnitName(aClass: TClass): string; overload;

function FloatToHalf(Float: Single): THalfFloat;
function HalfToFloat(Half: THalfFloat): Single;

function GetValueFromStringsIndex(const AStrings: TStrings; const AIndex: Integer): string;

// Determine if the directory is writable.
function IsDirectoryWriteable(const AName: string): Boolean;

function CharToWideChar(const AChar: AnsiChar): WideChar;

//----------------------------------------------------------------------
implementation
//----------------------------------------------------------------------

var
  vInvPerformanceCounterFrequency: Double;
  vInvPerformanceCounterFrequencyReady: Boolean = False;
  vLastProjectTargetName: string;

function IsSubComponent(const AComponent: TComponent): Boolean;
begin
  Result := (csSubComponent in AComponent.ComponentStyle);
end;

procedure MakeSubComponent(const AComponent: TComponent; const Value: Boolean);
begin
  AComponent.SetSubComponent(Value);
end;

function AnsiStartsText(const ASubText, AText: string): Boolean;
begin
  Result := AnsiStartsText(ASubText, AText);
end;

function MessageBoxOK(const Text, Caption: string): Integer;
begin
  Application.ProcessMessages;
  Result := MB_OK; //<- Instead of Result := Application.MessageBox(PChar(Text), PChar(Caption), MB_OK);
end;

procedure GLLoadBitmapFromInstance(Instance: LongInt; ABitmap: TBitmap; AName: string);
begin
  /// TODO : Cannot assign to a read-only property E2129
  /// ABitmap.Handle := LoadBitmap(Instance, PChar(AName));
end;

function GLGetTickCount: int64;
begin
  result := TThread.GetTickCount;
end;

procedure ShowHTMLUrl(Url: string);
begin
  ShellExecute(0, 'open', PChar(Url), nil, nil, SW_SHOW);
end;

function GetRectangle(const aLeft, aTop, aRight, aBottom: Integer): TRect;
begin
  Result.Left := aLeft;
  Result.Top := aTop;
  Result.Right := aRight;
  Result.Bottom := aBottom;
end;

procedure InflateRectangle(var aRect: TRect; dx, dy: Integer);
begin
  aRect.Left := aRect.Left - dx;
  aRect.Right := aRect.Right + dx;
  if aRect.Right < aRect.Left then
    aRect.Right := aRect.Left;
  aRect.Top := aRect.Top - dy;
  aRect.Bottom := aRect.Bottom + dy;
  if aRect.Bottom < aRect.Top then
    aRect.Bottom := aRect.Top;
end;

procedure IntersectRectangle(var aRect: TRect; const rect2: TRect);
var
  a: Integer;
begin
  if (aRect.Left > rect2.Right) or (aRect.Right < rect2.Left)
    or (aRect.Top > rect2.Bottom) or (aRect.Bottom < rect2.Top) then
  begin
    // no intersection
    a := 0;
    aRect.Left := a;
    aRect.Right := a;
    aRect.Top := a;
    aRect.Bottom := a;
  end
  else
  begin
    if aRect.Left < rect2.Left then
      aRect.Left := rect2.Left;
    if aRect.Right > rect2.Right then
      aRect.Right := rect2.Right;
    if aRect.Top < rect2.Top then
      aRect.Top := rect2.Top;
    if aRect.Bottom > rect2.Bottom then
      aRect.Bottom := rect2.Bottom;
  end;
end;

procedure RaiseLastOSError;
var
  e: EGLOSError;
begin
  e := EGLOSError.Create('OS Error : ' + SysErrorMessage(GetLastError));
  raise e;
end;

type
  TDeviceCapabilities = record
    Xdpi, Ydpi: integer; // Number of pixels per logical inch.
    Depth: integer; // The bit depth.
    NumColors: integer; // Number of entries in the device's color table.
  end;

function GetDeviceCapabilities: TDeviceCapabilities;
var
  Device: HDC;
begin
  Device := GetDC(0);
  try
    result.Xdpi := GetDeviceCaps(Device, LOGPIXELSX);
    result.Ydpi := GetDeviceCaps(Device, LOGPIXELSY);
    result.Depth := GetDeviceCaps(Device, BITSPIXEL);
    result.NumColors := GetDeviceCaps(Device, NUMCOLORS);
  finally
    ReleaseDC(0, Device);
  end;
end;

function GetDeviceLogicalPixelsX(device: THandle): Integer;
begin
  result := GetDeviceCapabilities().Xdpi;
end;

function GetCurrentColorDepth: Integer;
begin
  result := GetDeviceCapabilities().Depth;
end;

function PixelFormatToColorBits(aPixelFormat: TPixelFormat): Integer;
begin
  case aPixelFormat of
    TPixelFormat.None: Result := GetCurrentColorDepth; // use current color depth
    TPixelFormat.BGR5_A1: Result := 1;
    TPixelFormat.BGRA4: Result := 4;
    TPixelFormat.RGBA: Result := 8;
    TPixelFormat.RGBA16: Result := 16;
    TPixelFormat.RGBA32F: Result := 32;
  else
    Result := 24;
  end;
end;

function BitmapScanLine(aBitmap: TBitmap; aRow: Integer): Pointer;
var
  BitmapData : TBitmapData;
begin
  aBitmap.Map(TMapAccess.ReadWrite, BitmapData);
  Result := BitmapData.GetScanline(aRow); //in VCL the Result := aBitmap.ScanLine[aRow];
end;

procedure FixPathDelimiter(var S: string);
var
  I: Integer;
begin
  for I := Length(S) downto 1 do
    if (S[I] = '/') or (S[I] = '\') then
      S[I] := PathDelim;
end;

function RelativePath(const S: string): string;
var
  path: UTF8String;
begin
  Result := S;
  if IsDesignTime then
  begin
    if Assigned(vProjectTargetName) then
    begin
      path :=  vProjectTargetName();
      if Length(path) = 0 then
        path := vLastProjectTargetName
      else
        vLastProjectTargetName := path;
      path := IncludeTrailingPathDelimiter(ExtractFilePath(path));
    end
    else
      exit;
  end
  else
  begin
    path := ExtractFilePath(ParamStr(0));
    path := IncludeTrailingPathDelimiter(path);
  end;
  if Pos(path, S) = 1 then
    Delete(Result, 1, Length(path));
end;

procedure QueryPerformanceCounter(var val: Int64);
begin
  QueryPerformanceCounter(val);
end;

function QueryPerformanceFrequency(var val: Int64): Boolean;
begin
  Result := Boolean(QueryPerformanceFrequency(val));
end;

function StartPrecisionTimer: Int64;
begin
  QueryPerformanceCounter(Result);
end;

function PrecisionTimerLap(const precisionTimer: Int64): Double;
begin
  // we can do this, because we don't really stop anything
  Result := StopPrecisionTimer(precisionTimer);
end;

function StopPrecisionTimer(const precisionTimer: Int64): Double;
var
  cur, freq: Int64;
begin
  QueryPerformanceCounter(cur);
  if not vInvPerformanceCounterFrequencyReady then
  begin
    QueryPerformanceFrequency(freq);
    vInvPerformanceCounterFrequency := 1.0 / freq;
    vInvPerformanceCounterFrequencyReady := True;
  end;
  Result := (cur - precisionTimer) * vInvPerformanceCounterFrequency;
end;

var
  vSStartTime : TDateTime;
  vLastTime: TDateTime;
  vDeltaMilliSecond: TDateTime;

function AppTime: Double;
var
  SystemTime: TSystemTime;
begin
  GetLocalTime(SystemTime);
  with SystemTime do
    Result := (wHour * (MinsPerHour * SecsPerMin * MSecsPerSec) +
             wMinute * (SecsPerMin * MSecsPerSec) +
             wSecond * MSecsPerSec +
             wMilliSeconds) - vSStartTime;
  // Hack to fix time precession
  if Result - vLastTime = 0 then
  begin
    Result := Result + vDeltaMilliSecond;
    vDeltaMilliSecond := vDeltaMilliSecond + 0.1;
  end
  else begin
    vLastTime := Result;
    vDeltaMilliSecond := 0.1;
  end;
end;

function FindUnitName(anObject: TObject): string;
begin
  if Assigned(anObject) then
    Result := anObject.UnitName
  else
    Result := '';
end;

function FindUnitName(aClass: TClass): string;
begin
  if Assigned(aClass) then
    Result := aClass.UnitName
  else
    Result := '';
end;

procedure SetExeDirectory;
var
  path: string;
begin
  if IsDesignTime then
  begin
    if Assigned(vProjectTargetName) then
    begin
      path :=  vProjectTargetName();
      if Length(path) = 0 then
        path := vLastProjectTargetName
      else
        vLastProjectTargetName := path;
      path := IncludeTrailingPathDelimiter(ExtractFilePath(path));
      SetCurrentDir(path);
    end;
  end
  else
  begin
    path := ExtractFilePath(ParamStr(0));
    path := IncludeTrailingPathDelimiter(path);
    SetCurrentDir(path);
  end;
end;

function HalfToFloat(Half: THalfFloat): Single;
var
  Dst, Sign, Mantissa: LongWord;
  Exp: LongInt;
begin
  // extract sign, exponent, and mantissa from half number
  Sign := Half shr 15;
  Exp := (Half and $7C00) shr 10;
  Mantissa := Half and 1023;

  if (Exp > 0) and (Exp < 31) then
  begin
    // common normalized number
    Exp := Exp + (127 - 15);
    Mantissa := Mantissa shl 13;
    Dst := (Sign shl 31) or (LongWord(Exp) shl 23) or Mantissa;
    // Result := Power(-1, Sign) * Power(2, Exp - 15) * (1 + Mantissa / 1024);
  end
  else if (Exp = 0) and (Mantissa = 0) then
  begin
    // zero - preserve sign
    Dst := Sign shl 31;
  end
  else if (Exp = 0) and (Mantissa <> 0) then
  begin
    // denormalized number - renormalize it
    while (Mantissa and $00000400) = 0 do
    begin
      Mantissa := Mantissa shl 1;
      Dec(Exp);
    end;
    Inc(Exp);
    Mantissa := Mantissa and not $00000400;
    // now assemble normalized number
    Exp := Exp + (127 - 15);
    Mantissa := Mantissa shl 13;
    Dst := (Sign shl 31) or (LongWord(Exp) shl 23) or Mantissa;
    // Result := Power(-1, Sign) * Power(2, -14) * (Mantissa / 1024);
  end
  else if (Exp = 31) and (Mantissa = 0) then
  begin
    // +/- infinity
    Dst := (Sign shl 31) or $7F800000;
  end
  else //if (Exp = 31) and (Mantisa <> 0) then
  begin
    // not a number - preserve sign and mantissa
    Dst := (Sign shl 31) or $7F800000 or (Mantissa shl 13);
  end;

  // reinterpret LongWord as Single
  Result := PSingle(@Dst)^;
end;

function FloatToHalf(Float: Single): THalfFloat;
var
  Src: LongWord;
  Sign, Exp, Mantissa: LongInt;
begin
  Src := PLongWord(@Float)^;
  // extract sign, exponent, and mantissa from Single number
  Sign := Src shr 31;
  Exp := LongInt((Src and $7F800000) shr 23) - 127 + 15;
  Mantissa := Src and $007FFFFF;

  if (Exp > 0) and (Exp < 30) then
  begin
    // simple case - round the significand and combine it with the sign and exponent
    Result := (Sign shl 15) or (Exp shl 10) or ((Mantissa + $00001000) shr 13);
  end
  else if Src = 0 then
  begin
    // input float is zero - return zero
    Result := 0;
  end
  else
  begin
    // difficult case - lengthy conversion
    if Exp <= 0 then
    begin
      if Exp < -10 then
      begin
        // input float's value is less than HalfMin, return zero
        Result := 0;
      end
      else
      begin
        // Float is a normalized Single whose magnitude is less than HalfNormMin.
        // We convert it to denormalized half.
        Mantissa := (Mantissa or $00800000) shr (1 - Exp);
        // round to nearest
        if (Mantissa and $00001000) > 0 then
          Mantissa := Mantissa + $00002000;
        // assemble Sign and Mantissa (Exp is zero to get denotmalized number)
        Result := (Sign shl 15) or (Mantissa shr 13);
      end;
    end
    else if Exp = 255 - 127 + 15 then
    begin
      if Mantissa = 0 then
      begin
        // input float is infinity, create infinity half with original sign
        Result := (Sign shl 15) or $7C00;
      end
      else
      begin
        // input float is NaN, create half NaN with original sign and mantissa
        Result := (Sign shl 15) or $7C00 or (Mantissa shr 13);
      end;
    end
    else
    begin
      // Exp is > 0 so input float is normalized Single

      // round to nearest
      if (Mantissa and $00001000) > 0 then
      begin
        Mantissa := Mantissa + $00002000;
        if (Mantissa and $00800000) > 0 then
        begin
          Mantissa := 0;
          Exp := Exp + 1;
        end;
      end;

      if Exp > 30 then
      begin
        // exponent overflow - return infinity half
        Result := (Sign shl 15) or $7C00;
      end
      else
        // assemble normalized half
        Result := (Sign shl 15) or (Exp shl 10) or (Mantissa shr 13);
    end;
  end;
end;

function GetValueFromStringsIndex(const AStrings: TStrings; const AIndex: Integer): string;
begin
  Result := AStrings.ValueFromIndex[AIndex];
end;

function IsDirectoryWriteable(const AName: string): Boolean;
var
  LFileName: String;
  LHandle: THandle;
begin
  LFileName := IncludeTrailingPathDelimiter(AName) + 'chk.tmp';
  LHandle := CreateFile(PChar(LFileName), GENERIC_READ or GENERIC_WRITE, 0, nil,
    CREATE_NEW, FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_DELETE_ON_CLOSE, 0);
  Result := LHandle <> INVALID_HANDLE_VALUE;
  if Result then
    CloseHandle(LHandle);
end;


function CharToWideChar(const AChar: AnsiChar): WideChar;
var
  lResult: PWideChar;
begin
  GetMem(lResult, 2);
  MultiByteToWideChar(CP_ACP, 0, @AChar, 1, lResult, 2);
  Result := lResult^;
  FreeMem(lResult, 2);
end;

//-------------------------------------------
initialization
//-------------------------------------------

  vSStartTime := AppTime;

end.
