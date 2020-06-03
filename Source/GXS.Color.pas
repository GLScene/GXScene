//
// Graphic Scene Engine, http://glscene.org
//
{
  All color types, constants and utilities should go here
}
unit GXS.Color;

interface

{$I Scene.inc}

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  FMX.Dialogs,
  FMX.Graphics,

  Import.OpenGLx,
  Scene.VectorTypes,
  Scene.VectorGeometry,
  Scene.PersistentClasses,
  GXS.BaseClasses;

type
  PColorVector = ^TColorVector;
  TColorVector = TVector4f;

  PRGBColor = ^TRGBColor;
  TRGBColor = TVector3b;

  { Wraps an OpenVX color. }
  TgxColor = class(TgxUpdateAbleObject)
  private
    { Private Properties }
    FColor: TColorVector;
    FPDefaultColor: PColorVector;
    procedure SetColorVector(const aColor: TColorVector); overload;
    procedure SetColorComponent(index: Integer; value: Single);
    function GetColorComponent(const index: Integer): Single;
    procedure SetAsWinColor(const val: TColor);
    function GetAsWinColor: TColor;
    procedure SetDirectColorVector(const aColor: TColorVector);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadData(Stream: TStream);
    procedure WriteData(Stream: TStream);
    function GetHSVA: TVector;
    procedure SetHSVA(const hsva: TVector);
  public
    constructor Create(AOwner: TPersistent); override;
    constructor CreateInitialized(AOwner: TPersistent;
      const Color: TColorVector; changeEvent: TNotifyEvent = nil);
    destructor Destroy; override;
    procedure NotifyChange(Sender: TObject); override;
    procedure Assign(Source: TPersistent); override;
    procedure Initialize(const Color: TColorVector);
    function AsAddress: PGLFloat;
    procedure RandomColor;
    procedure SetColor(red, green, blue: Single; alpha: Single = 1); overload;
    property Color: TColorVector read FColor write SetColorVector;
    property DirectColor: TColorVector read FColor write SetDirectColorVector;
    property AsWinColor: TColor read GetAsWinColor write SetAsWinColor;
    property HSVA: TVector read GetHSVA write SetHSVA;
    property DefaultColor: TColorVector read FColor;
  published
    property Red: Single index 0 read GetColorComponent write SetColorComponent
      stored False;
    property Green: Single index 1 read GetColorComponent
      write SetColorComponent stored False;
    property Blue: Single index 2 read GetColorComponent write SetColorComponent
      stored False;
    property Alpha: Single index 3 read GetColorComponent
      write SetColorComponent stored False;
  end;

  PColorEntry = ^TColorEntry;

  TColorEntry = record
    Name: String[31];
    Color: TColorVector;
  end;

  TgxColorManager = class(TList)
  public
    destructor Destroy; override;
    procedure AddColor(const aName: String; const aColor: TColorVector);
    procedure EnumColors(Proc: TGetStrProc); overload;
    procedure EnumColors(AValues: TStrings); overload;
    function FindColor(const aName: String): TColorVector;
    { Convert a clrXxxx or a '<red green blue alpha> to a color vector }
    function GetColor(const aName: String): TColorVector;
    function GetColorName(const aColor: TColorVector): String;
    procedure RegisterDefaultColors;
    procedure RemoveColor(const aName: String);
  end;

{ Builds a TColor from Red Green Blue components,
  there is a Vcl.Imaging.GIFImg.TGIFColorMap.RGB2Color }
function RGB2Color(const r, g, b: Byte): TColor;
function ColorManager: TgxColorManager;
procedure RegisterColor(const aName: String; const aColor: TColorVector);
procedure UnRegisterColor(const aName: String);
function GetRValue(RGB: DWORD): Byte; {$NODEFINE GetRValue}
function GetGValue(RGB: DWORD): Byte; {$NODEFINE GetGValue}
function GetBValue(RGB: DWORD): Byte; {$NODEFINE GetBValue}
procedure InitGXSceneColors;
{ Converts a delphi color into its RGB fragments and correct range. }
function ConvertWinColor(AColor: TColor; alpha: Single = 1): TColorVector;

// Converts a color vector (containing float values)
function ConvertColorVector(const AColor: TColorVector): TColor; overload;
{ Converts a color vector (containing float values) and alter intensity.
  intensity is in [0..1] }
function ConvertColorVector(const AColor: TColorVector; intensity: Single): TColor; overload;
// Converts RGB components into a color vector with correct range
function ConvertRGBColor(const AColor: array of Byte): TColorVector;

// color definitions
const
  // Some extra colors, not declared in System.UITypes.pas
  clForeground = TColor(-1);
  clButton = TColor(-2);
  clLight = TColor(-3);
  clMidlight = TColor(-4);
  clDark = TColor(-5);
  clMid = TColor(-6);
  clText = TColor(-7);
  clBrightText = TColor(-8);
  clButtonText = TColor(-9);
  clBase = TColor(-10);
  clBackground = TColor(-11);
  clShadow = TColor(-12);
  clHighlight = TColor(-13);
  clHighlightedText = TColor(-14);

  { Mapped role offsets }
  cloNormal = 32;
  cloDisabled = 64;
  cloActive = 96;

  { Normal, mapped, pseudo, rgb values }
  clNormalForeground = TColor(clForeground - cloNormal);
  clNormalButton = TColor(clButton - cloNormal);
  clNormalLight = TColor(clLight - cloNormal);
  clNormalMidlight = TColor(clMidlight - cloNormal);
  clNormalDark = TColor(clDark - cloNormal);
  clNormalMid = TColor(clMid - cloNormal);
  clNormalText = TColor(clText - cloNormal);
  clNormalBrightText = TColor(clBrightText - cloNormal);
  clNormalButtonText = TColor(clButtonText - cloNormal);
  clNormalBase = TColor(clBase - cloNormal);
  clNormalBackground = TColor(clBackground - cloNormal);
  clNormalShadow = TColor(clShadow - cloNormal);
  clNormalHighlight = TColor(clHighlight - cloNormal);
  clNormalHighlightedText = TColor(clHighlightedText - cloNormal);

  { Disabled, mapped, pseudo, rgb values }
  clDisabledForeground = TColor(clForeground - cloDisabled);
  clDisabledButton = TColor(clButton - cloDisabled);
  clDisabledLight = TColor(clLight - cloDisabled);
  clDisabledMidlight = TColor(clMidlight - cloDisabled);
  clDisabledDark = TColor(clDark - cloDisabled);
  clDisabledMid = TColor(clMid - cloDisabled);
  clDisabledText = TColor(clText - cloDisabled);
  clDisabledBrightText = TColor(clBrightText - cloDisabled);
  clDisabledButtonText = TColor(clButtonText - cloDisabled);
  clDisabledBase = TColor(clBase - cloDisabled);
  clDisabledBackground = TColor(clBackground - cloDisabled);
  clDisabledShadow = TColor(clShadow - cloDisabled);
  clDisabledHighlight = TColor(clHighlight - cloDisabled);
  clDisabledHighlightedText = TColor(clHighlightedText - cloDisabled);

  { Active, mapped, pseudo, rgb values }
  clActiveForeground = TColor(clForeground - cloActive);
  clActiveButton = TColor(clButton - cloActive);
  clActiveLight = TColor(clLight - cloActive);
  clActiveMidlight = TColor(clMidlight - cloActive);
  clActiveDark = TColor(clDark - cloActive);
  clActiveMid = TColor(clMid - cloActive);
  clActiveText = TColor(clText - cloActive);
  clActiveBrightText = TColor(clBrightText - cloActive);
  clActiveButtonText = TColor(clButtonText - cloActive);
  clActiveBase = TColor(clBase - cloActive);
  clActiveBackground = TColor(clBackground - cloActive);
  clActiveShadow = TColor(clShadow - cloActive);
  clActiveHighlight = TColor(clHighlight - cloActive);
  clActiveHighlightedText = TColor(clHighlightedText - cloActive);

  clFirstSpecialColor = clActiveHighlightedText;
  clMask = TColorRec.White;
  clDontMask = TColorRec.Black;

  // Window's colors (must be filled at program
  // startup, since they depend on the desktop scheme)
const
{$J+ - allow change of the following typed constants}
  clrScrollBar: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrBackground: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrActiveCaption: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrInactiveCaption: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrMenu: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrWindow: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrWindowFrame: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrMenuText: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrWindowText: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrCaptionText: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrActiveBorder: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrInactiveBorder: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrAppWorkSpace: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrHighlight: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrHighlightText: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrBtnFace: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrBtnShadow: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrGrayText: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrBtnText: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrInactiveCaptionText: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrBtnHighlight: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clr3DDkShadow: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clr3DLight: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrInfoText: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrInfoBk: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);

{$J- - disable change of other typed constants}
  // 'static' color definitions
  // sort of grays
  clrTransparent: TColorVector = (X: 0; Y: 0; Z: 0; W: 0);
  clrBlack: TColorVector = (X: 0; Y: 0; Z: 0; W: 1);
  clrGray05: TColorVector = (X: 0.05; Y: 0.05; Z: 0.05; W: 1);
  clrGray10: TColorVector = (X: 0.10; Y: 0.10; Z: 0.10; W: 1);
  clrGray15: TColorVector = (X: 0.15; Y: 0.15; Z: 0.15; W: 1);
  clrGray20: TColorVector = (X: 0.20; Y: 0.20; Z: 0.20; W: 1);
  clrGray25: TColorVector = (X: 0.25; Y: 0.25; Z: 0.25; W: 1);
  clrGray30: TColorVector = (X: 0.30; Y: 0.30; Z: 0.30; W: 1);
  clrGray35: TColorVector = (X: 0.35; Y: 0.35; Z: 0.35; W: 1);
  clrGray40: TColorVector = (X: 0.40; Y: 0.40; Z: 0.40; W: 1);
  clrGray45: TColorVector = (X: 0.45; Y: 0.45; Z: 0.45; W: 1);
  clrGray50: TColorVector = (X: 0.50; Y: 0.50; Z: 0.50; W: 1);
  clrGray55: TColorVector = (X: 0.55; Y: 0.55; Z: 0.55; W: 1);
  clrGray60: TColorVector = (X: 0.60; Y: 0.60; Z: 0.60; W: 1);
  clrGray65: TColorVector = (X: 0.65; Y: 0.65; Z: 0.65; W: 1);
  clrGray70: TColorVector = (X: 0.70; Y: 0.70; Z: 0.70; W: 1);
  clrGray75: TColorVector = (X: 0.75; Y: 0.75; Z: 0.75; W: 1);
  clrGray80: TColorVector = (X: 0.80; Y: 0.80; Z: 0.80; W: 1);
  clrGray85: TColorVector = (X: 0.85; Y: 0.85; Z: 0.85; W: 1);
  clrGray90: TColorVector = (X: 0.90; Y: 0.90; Z: 0.90; W: 1);
  clrGray95: TColorVector = (X: 0.95; Y: 0.95; Z: 0.95; W: 1);
  clrWhite: TColorVector = (X: 1; Y: 1; Z: 1; W: 1);

  // other grays
  clrDimGray: TColorVector = (X: 0.329412; Y: 0.329412; Z: 0.329412; W: 1);
  clrGray: TColorVector = (X: 0.752941; Y: 0.752941; Z: 0.752941; W: 1);
  clrLightGray: TColorVector = (X: 0.658824; Y: 0.658824; Z: 0.658824; W: 1);

  // colors en masse
  clrAquamarine: TColorVector = (X: 0.439216; Y: 0.858824; Z: 0.576471; W: 1);
  clrBlueViolet: TColorVector = (X: 0.62352; Y: 0.372549; Z: 0.623529; W: 1);
  clrBrown: TColorVector = (X: 0.647059; Y: 0.164706; Z: 0.164706; W: 1);
  clrCadetBlue: TColorVector = (X: 0.372549; Y: 0.623529; Z: 0.623529; W: 1);
  clrCoral: TColorVector = (X: 1; Y: 0.498039; Z: 0.0; W: 1);
  clrCornflowerBlue: TColorVector = (X: 0.258824; Y: 0.258824; Z: 0.435294; W: 1);
  clrDarkGreen: TColorVector = (X: 0.184314; Y: 0.309804; Z: 0.184314; W: 1);
  clrDarkOliveGreen: TColorVector = (X: 0.309804; Y: 0.309804; Z: 0.184314; W: 1);
  clrDarkOrchid: TColorVector = (X: 0.6; Y: 0.196078; Z: 0.8; W: 1);
  clrDarkSlateBlue: TColorVector = (X: 0.419608; Y: 0.137255; Z: 0.556863; W: 1);
  clrDarkSlateGray: TColorVector = (X: 0.184314; Y: 0.309804; Z: 0.309804; W: 1);
  clrDarkSlateGrey: TColorVector = (X: 0.184314; Y: 0.309804; Z: 0.309804; W: 1);
  clrDarkTurquoise: TColorVector = (X: 0.439216; Y: 0.576471; Z: 0.858824; W: 1);
  clrFirebrick: TColorVector = (X: 0.556863; Y: 0.137255; Z: 0.137255; W: 1);
  clrForestGreen: TColorVector = (X: 0.137255; Y: 0.556863; Z: 0.137255; W: 1);
  clrGold: TColorVector = (X: 0.8; Y: 0.498039; Z: 0.196078; W: 1);
  clrGoldenrod: TColorVector = (X: 0.858824; Y: 0.858824; Z: 0.439216; W: 1);
  clrGreenYellow: TColorVector = (X: 0.576471; Y: 0.858824; Z: 0.439216; W: 1);
  clrIndian: TColorVector = (X: 0.309804; Y: 0.184314; Z: 0.184314; W: 1);
  clrKhaki: TColorVector = (X: 0.623529; Y: 0.623529; Z: 0.372549; W: 1);
  clrLightBlue: TColorVector = (X: 0.74902; Y: 0.847059; Z: 0.847059; W: 1);
  clrLightSteelBlue: TColorVector = (X: 0.560784; Y: 0.560784; Z: 0.737255; W: 1);
  clrLimeGreen: TColorVector = (X: 0.196078; Y: 0.8; Z: 0.196078; W: 1);
  clrMaroon: TColorVector = (X: 0.556863; Y: 0.137255; Z: 0.419608; W: 1);
  clrMediumAquamarine: TColorVector = (X: 0.196078; Y: 0.8; Z: 0.6; W: 1);
  clrMediumBlue: TColorVector = (X: 0.196078; Y: 0.196078; Z: 0.8; W: 1);
  clrMediumForestGreen: TColorVector = (X: 0.419608; Y: 0.556863; Z: 0.137255; W: 1);
  clrMediumGoldenrod: TColorVector = (X: 0.917647; Y: 0.917647; Z: 0.678431; W: 1);
  clrMediumOrchid: TColorVector = (X: 0.576471; Y: 0.439216; Z: 0.858824; W: 1);
  clrMediumSeaGreen: TColorVector = (X: 0.258824; Y: 0.435294;  Z: 0.258824; W: 1);
  clrMediumSlateBlue: TColorVector = (X: 0.498039; Y: 0; Z: 1; W: 1);
  clrMediumSpringGreen: TColorVector = (X: 0.498039; Y: 1; Z: 0; W: 1);
  clrMediumTurquoise: TColorVector = (X: 0.439216; Y: 0.858824; Z: 0.858824; W: 1);
  clrMediumViolet: TColorVector = (X: 0.858824; Y: 0.439216; Z: 0.576471; W: 1);
  clrMidnightBlue: TColorVector = (X: 0.184314; Y: 0.184314; Z: 0.309804; W: 1);
  clrNavy: TColorVector = (X: 0.137255; Y: 0.137255; Z: 0.556863; W: 1);
  clrNavyBlue: TColorVector = (X: 0.137255; Y: 0.137255; Z: 0.556863; W: 1);
  clrOrange: TColorVector = (X: 1; Y: 0.5; Z: 0.0; W: 1);
  clrOrangeRed: TColorVector = (X: 1; Y: 0.25; Z: 0; W: 1);
  clrOrchid: TColorVector = (X: 0.858824; Y: 0.439216; Z: 0.858824; W: 1);
  clrPaleGreen: TColorVector = (X: 0.560784; Y: 0.737255; Z: 0.560784; W: 1);
  clrPink: TColorVector = (X: 0.737255; Y: 0.560784; Z: 0.560784; W: 1);
  clrPlum: TColorVector = (X: 0.917647; Y: 0.678431; Z: 0.917647; W: 1);
  clrSalmon: TColorVector = (X: 0.435294; Y: 0.258824; Z: 0.258824; W: 1);
  clrSeaGreen: TColorVector = (X: 0.137255; Y: 0.556863; Z: 0.419608; W: 1);
  clrSienna: TColorVector = (X: 0.556863; Y: 0.419608; Z: 0.137255; W: 1);
  clrSkyBlue: TColorVector = (X: 0.196078; Y: 0.6; Z: 0.8; W: 1);
  clrSlateBlue: TColorVector = (X: 0; Y: 0.498039; Z: 1; W: 1);
  clrSpringGreen: TColorVector = (X: 0; Y: 1; Z: 0.498039; W: 1);
  clrSteelBlue: TColorVector = (X: 0.137255; Y: 0.419608; Z: 0.556863; W: 1);
  clrTan: TColorVector = (X: 0.858824; Y: 0.576471; Z: 0.439216; W: 1);
  clrThistle: TColorVector = (X: 0.847059; Y: 0.74902; Z: 0.847059; W: 1);
  clrTurquoise: TColorVector = (X: 0.678431; Y: 0.917647; Z: 0.917647; W: 1);
  clrViolet: TColorVector = (X: 0.309804; Y: 0.184314; Z: 0.309804; W: 1);
  clrVioletRed: TColorVector = (X: 0.8; Y: 0.196078; Z: 0.6; W: 1);
  clrWheat: TColorVector = (X: 0.847059; Y: 0.847059; Z: 0.74902; W: 1);
  clrYellowGreen: TColorVector = (X: 0.6; Y: 0.8; Z: 0.196078; W: 1);
  clrSummerSky: TColorVector = (X: 0.22; Y: 0.69; Z: 0.87; W: 1);
  clrRichBlue: TColorVector = (X: 0.35; Y: 0.35; Z: 0.67; W: 1);
  clrBrass: TColorVector = (X: 0.71; Y: 0.65; Z: 0.26; W: 1);
  clrCopper: TColorVector = (X: 0.72; Y: 0.45; Z: 0.20; W: 1);
  clrBronze: TColorVector = (X: 0.55; Y: 0.47; Z: 0.14; W: 1);
  clrBronze2: TColorVector = (X: 0.65; Y: 0.49; Z: 0.24; W: 1);
  clrSilver: TColorVector = (X: 0.90; Y: 0.91; Z: 0.98; W: 1);
  clrBrightGold: TColorVector = (X: 0.85; Y: 0.85; Z: 0.10; W: 1);
  clrOldGold: TColorVector = (X: 0.81; Y: 0.71; Z: 0.23; W: 1);
  clrFeldspar: TColorVector = (X: 0.82; Y: 0.57; Z: 0.46; W: 1);
  clrQuartz: TColorVector = (X: 0.85; Y: 0.85; Z: 0.95; W: 1);
  clrNeonPink: TColorVector = (X: 1.00; Y: 0.43; Z: 0.78; W: 1);
  clrDarkPurple: TColorVector = (X: 0.53; Y: 0.12; Z: 0.47; W: 1);
  clrNeonBlue: TColorVector = (X: 0.30; Y: 0.30; Z: 1.00; W: 1);
  clrCoolCopper: TColorVector = (X: 0.85; Y: 0.53; Z: 0.10; W: 1);
  clrMandarinOrange: TColorVector = (X: 0.89; Y: 0.47; Z: 0.20; W: 1);
  clrLightWood: TColorVector = (X: 0.91; Y: 0.76; Z: 0.65; W: 1);
  clrMediumWood: TColorVector = (X: 0.65; Y: 0.50; Z: 0.39; W: 1);
  clrDarkWood: TColorVector = (X: 0.52; Y: 0.37; Z: 0.26; W: 1);
  clrSpicyPink: TColorVector = (X: 1.00; Y: 0.11; Z: 0.68; W: 1);
  clrSemiSweetChoc: TColorVector = (X: 0.42; Y: 0.26; Z: 0.15; W: 1);
  clrBakersChoc: TColorVector = (X: 0.36; Y: 0.20; Z: 0.09; W: 1);
  clrFlesh: TColorVector = (X: 0.96; Y: 0.80; Z: 0.69; W: 1);
  clrNewTan: TColorVector = (X: 0.92; Y: 0.78; Z: 0.62; W: 1);
  clrNewMidnightBlue: TColorVector = (X: 0.00; Y: 0.00; Z: 0.61; W: 1);
  clrVeryDarkBrown: TColorVector = (X: 0.35; Y: 0.16; Z: 0.14; W: 1);
  clrDarkBrown: TColorVector = (X: 0.36; Y: 0.25; Z: 0.20; W: 1);
  clrDarkTan: TColorVector = (X: 0.59; Y: 0.41; Z: 0.31; W: 1);
  clrGreenCopper: TColorVector = (X: 0.32; Y: 0.49; Z: 0.46; W: 1);
  clrDkGreenCopper: TColorVector = (X: 0.29; Y: 0.46; Z: 0.43; W: 1);
  clrDustyRose: TColorVector = (X: 0.52; Y: 0.39; Z: 0.39; W: 1);
  clrHuntersGreen: TColorVector = (X: 0.13; Y: 0.37; Z: 0.31; W: 1);
  clrScarlet: TColorVector = (X: 0.55; Y: 0.09; Z: 0.09; W: 1);
  clrMediumPurple: TColorVector = (X: 0.73; Y: 0.16; Z: 0.96; W: 1);
  clrLightPurple: TColorVector = (X: 0.87; Y: 0.58; Z: 0.98; W: 1);
  clrVeryLightPurple: TColorVector = (X: 0.94; Y: 0.81; Z: 0.99; W: 1);
  clrGreen: TColorVector = (X: 0; Y: 0.5; Z: 0; W: 1);
  clrOlive: TColorVector = (X: 0.5; Y: 0.5; Z: 1; W: 1);
  clrPurple: TColorVector = (X: 1; Y: 0; Z: 1; W: 1);
  clrTeal: TColorVector = (X: 0; Y: 0.5; Z: 0.5; W: 1);
  clrRed: TColorVector = (X: 1; Y: 0; Z: 0; W: 1);
  clrLime: TColorVector = (X: 0; Y: 1; Z: 0; W: 1);
  clrYellow: TColorVector = (X: 1; Y: 1; Z: 0; W: 1);
  clrBlue: TColorVector = (X: 0; Y: 0; Z: 1; W: 1);
  clrFuchsia: TColorVector = (X: 1; Y: 0; Z: 1; W: 1);
  clrAqua: TColorVector = (X: 0; Y: 1; Z: 1; W: 1);

  cDefaultNormalMapScale = 0.125;

{$J- - disallow change of the following typed constants}

var
  // Specifies if TgxColor should allocate memory for
  // their default values (ie. design-time) or not (run-time)
  vUseDefaultColorSets: Boolean = False;

//------------------------------------------------
implementation
//------------------------------------------------

var
  vColorManager: TgxColorManager;

function RGB2Color(const r, g, b: Byte): TColor;
begin
  Result := r or (g shl 8) or (b shl 16);
end;

function ColorManager: TgxColorManager;
begin
  if not Assigned(vColorManager) then
  begin
    vColorManager := TgxColorManager.Create;
    vColorManager.RegisterDefaultColors;
  end;
  Result := vColorManager;
end;

function ConvertWinColor(aColor: TColor; alpha: Single = 1): TColorVector;
var
  winColor: Integer;
begin
  // Convert to Windows color
  winColor := TColors.ColorToRGB(aColor);
  // convert 0..255 range into 0..1 range
  Result.X := (winColor and $FF) * (1 / 255);
  Result.Y := ((winColor shr 8) and $FF) * (1 / 255);
  Result.Z := ((winColor shr 16) and $FF) * (1 / 255);
  Result.W := alpha;
end;

function GetRValue(RGB: DWORD): Byte;
begin
  Result := Byte(RGB);
end;

function GetGValue(RGB: DWORD): Byte;
begin
  Result := Byte(RGB shr 8);
end;

function GetBValue(RGB: DWORD): Byte;
begin
  Result := Byte(RGB shr 16);
end;

procedure InitGXSceneColors;
begin
  clrScrollBar := ConvertWinColor(TColorRec.cSCROLLBAR);
  clrActiveCaption := ConvertWinColor(TColorRec.cACTIVECAPTION);
  clrInactiveCaption := ConvertWinColor(TColorRec.cINACTIVECAPTION);
  clrMenu := ConvertWinColor(TColorRec.cMENU);
  clrWindow := ConvertWinColor(TColorRec.cWINDOW);
  clrWindowFrame := ConvertWinColor(TColorRec.cWINDOWFRAME);
  clrMenuText := ConvertWinColor(TColorRec.cMENUTEXT);
  clrWindowText := ConvertWinColor(TColorRec.cWINDOWTEXT);
  clrCaptionText := ConvertWinColor(TColorRec.cCAPTIONTEXT);
  clrActiveBorder := ConvertWinColor(TColorRec.cACTIVEBORDER);
  clrInactiveBorder := ConvertWinColor(TColorRec.cINACTIVEBORDER);
  clrAppWorkSpace := ConvertWinColor(TColorRec.cAPPWORKSPACE);
  clrHighlightText := ConvertWinColor(TColorRec.cHIGHLIGHTTEXT);
  clrBtnFace := ConvertWinColor(TColorRec.cBTNFACE);
  clrBtnShadow := ConvertWinColor(TColorRec.cBTNSHADOW);
  clrGrayText := ConvertWinColor(TColorRec.cGRAYTEXT);
  clrBtnText := ConvertWinColor(TColorRec.cBTNTEXT);
  clrInactiveCaptionText := ConvertWinColor(TColorRec.cINACTIVECAPTIONTEXT);
  clrBtnHighlight := ConvertWinColor(TColorRec.cBTNHIGHLIGHT);
  clr3DDkShadow := ConvertWinColor(TColorRec.c3DDKSHADOW);
  clr3DLight := ConvertWinColor(TColorRec.c3DLIGHT);
  clrInfoText := ConvertWinColor(TColorRec.cINFOTEXT);
  clrInfoBk := ConvertWinColor(TColorRec.cINFOBK);
end;

function ConvertColorVector(const aColor: TColorVector): TColor;
begin
  Result := RGB2Color(Round(255 * aColor.X), Round(255 * aColor.Y),
    Round(255 * aColor.Z));
end;

function ConvertColorVector(const aColor: TColorVector;
  intensity: Single): TColor;
begin
  intensity := 255 * intensity;
  Result := RGB2Color(Round(intensity * aColor.X), Round(intensity * aColor.Y),
    Round(intensity * aColor.Z));
end;

function ConvertRGBColor(const aColor: array of Byte): TColorVector;
var
  n: Integer;
begin
  // convert 0..255 range into 0..1 range
  n := High(AColor);
  Result.X := AColor[0] * (1 / 255);
  if n > 0 then
    Result.Y := AColor[1] * (1 / 255)
  else
    Result.Y := 0;
  if n > 1 then
    Result.Z := AColor[2] * (1 / 255)
  else
    Result.Z := 0;
  if n > 2 then
    Result.W := AColor[3] * (1 / 255)
  else
    Result.W := 1;
end;

// ------------------
// ------------------ TgxColor ------------------
// ------------------

constructor TgxColor.Create(AOwner: TPersistent);
begin
  inherited;
  Initialize(clrBlack);
end;

constructor TgxColor.CreateInitialized(AOwner: TPersistent;
  const Color: TColorVector; changeEvent: TNotifyEvent = nil);
begin
  Create(AOwner);
  Initialize(Color);
  OnNotifyChange := changeEvent;
end;

destructor TgxColor.Destroy;
begin
  if Assigned(FPDefaultColor) then
    Dispose(FPDefaultColor);
  inherited;
end;

procedure TgxColor.Initialize(const Color: TColorVector);
begin
  SetVector(FColor, Color);
  if vUseDefaultColorSets then
  begin
    if not Assigned(FPDefaultColor) then
      New(FPDefaultColor);
    SetVector(FPDefaultColor^, Color);
  end;
end;

procedure TgxColor.SetColorVector(const aColor: TColorVector);
begin
  SetVector(FColor, AColor);
  NotifyChange(Self);
end;

procedure TgxColor.SetDirectColorVector(const aColor: TColorVector);
begin
  SetVector(FColor, aColor);
end;

procedure TgxColor.SetColorComponent(index: Integer; value: Single);
begin
  if FColor.V[index] <> value then
  begin
    FColor.V[index] := value;
    NotifyChange(Self);
  end;
end;

procedure TgxColor.SetAsWinColor(const val: TColor);
begin
  FColor := ConvertWinColor(val);
  NotifyChange(Self);
end;

function TgxColor.GetAsWinColor: TColor;
begin
  Result := ConvertColorVector(FColor);
end;

function TgxColor.GetColorComponent(const index: Integer): Single;
begin
  Result := FColor.V[Index];
end;

procedure TgxColor.Assign(Source: TPersistent);
begin
  if Assigned(Source) and (Source is TgxColor) then
  begin
    FColor := TgxColor(Source).FColor;
    NotifyChange(Self);
  end
  else
    inherited;
end;

procedure TgxColor.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineBinaryProperty('Color', ReadData, WriteData,
    not(Assigned(FPDefaultColor) and VectorEquals(FColor, FPDefaultColor^)));
end;

procedure TgxColor.ReadData(Stream: TStream);
begin
  Stream.Read(FColor, SizeOf(FColor));
end;

procedure TgxColor.WriteData(Stream: TStream);
begin
  Stream.Write(FColor, SizeOf(FColor));
end;

procedure TgxColor.NotifyChange(Sender: TObject);
var
  intf: IgxNotifyable;
begin
  if Assigned(Owner) then
  begin
    if Supports(Owner, IgxNotifyable, intf) then
      intf.NotifyChange(Self);
    //  if Owner is TgxBaseSceneObject then
    // TgxBaseSceneObject(Owner).StructureChanged;
    inherited;
  end;
end;

function TgxColor.AsAddress: PGLfloat;
begin
  Result := @FColor;
end;

procedure TgxColor.RandomColor;
begin
  red := Random;
  green := Random;
  blue := Random;
end;

procedure TgxColor.SetColor(red, green, blue: Single; alpha: Single = 1);
begin
  FColor.X := red;
  FColor.Y := green;
  FColor.Z := blue;
  FColor.W := alpha;
  NotifyChange(Self);
end;

function TgxColor.GetHSVA: TVector;
var
  delta, min: Single;
const
  H = 0;
  S = 1;
  V = 2;
begin
  min := MinFloat(PFloatVector(@FColor), 3);
  Result.V[V] := MaxFloat(PFloatVector(@FColor), 3);
  delta := Result.V[V] - min;

  // saturation is zero if R, G & B are zero
  // hue undefined (zero) if saturation is zero or color is gray (delta=zero)
  if (Result.V[V] = 0) or (delta = 0) then
  begin
    Result.V[S] := 0;
    Result.V[H] := 0;
  end
  else
  begin
    Result.V[S] := delta / Result.V[V];
    if red = Result.V[V] then
      // between yellow and magenta
      Result.V[H] := 60 * (green - blue) / delta
    else if green = Result.V[V] then
      // between cyan and yellow
      Result.V[H] := 120 + 60 * (blue - red) / delta
    else // between magenta and cyan
      Result.V[H] := 240 + 60 * (red - green) / delta;
    if Result.V[H] < 0 then // normalize H
      Result.V[H] := Result.V[H] + 360;
  end;
  Result.W := alpha;
end;

procedure TgxColor.SetHSVA(const hsva: TVector);
var
  f, hTemp, p, q, t: Single;
const
  H = 0;
  S = 1;
  V = 2;
begin
  if hsva.V[S] = 0 then
  begin
    // gray (ignore hue)
    FColor.X := hsva.V[V];
    FColor.Y := hsva.V[V];
    FColor.Z := hsva.V[V];
  end
  else
  begin
    hTemp := hsva.V[H] * (1 / 60);
    f := Frac(hTemp);

    p := hsva.V[V] * (1 - hsva.V[S]);
    q := hsva.V[V] * (1 - (hsva.V[S] * f));
    t := hsva.V[V] * (1 - (hsva.V[S] * (1 - f)));

    case Trunc(hTemp) mod 6 of
      0:
        begin
          FColor.X := hsva.V[V];
          FColor.Y := t;
          FColor.Z := p;
        end;
      1:
        begin
          FColor.X := q;
          FColor.Y := hsva.V[V];
          FColor.Z := p;
        end;
      2:
        begin
          FColor.X := p;
          FColor.Y := hsva.V[V];
          FColor.Z := t;
        end;
      3:
        begin
          FColor.X := p;
          FColor.Y := q;
          FColor.Z := hsva.V[V];
        end;
      4:
        begin
          FColor.X := t;
          FColor.Y := p;
          FColor.Z := hsva.V[V];
        end;
      5:
        begin
          FColor.X := hsva.V[V];
          FColor.Y := p;
          FColor.Z := q;
        end;
    end
  end;
  FColor.W := hsva.W;
  NotifyChange(Self);
end;

// ------------------
// ------------------ TgxColorManager ------------------
// ------------------

function TgxColorManager.FindColor(const aName: String): TColorVector;
var
  i: Integer;
begin
  Result := clrBlack;
  for i := 0 to Count - 1 do
    if CompareText(string(TColorEntry(Items[i]^).Name), aName) = 0 then
    begin
      SetVector(Result, TColorEntry(Items[i]^).Color);
      Break;
    end;
end;

function TgxColorManager.GetColor(const aName: String): TColorVector;
var
  workCopy: String;
  delimiter: Integer;
begin
  if aName = '' then
    Result := clrBlack
  else
  begin
    workCopy := Trim(aName);
    if CharInSet(aName[1], ['(', '[', '<']) then
      workCopy := Copy(workCopy, 2, Length(aName) - 2);
    if CompareText(Copy(workCopy, 1, 3), 'clr') = 0 then
      SetVector(Result, FindColor(workCopy))
    else
      try
        // initialize result
        Result := clrBlack;
        workCopy := Trim(workCopy);
        delimiter := Pos(' ', workCopy);
        if (Length(workCopy) > 0) and (delimiter > 0) then
        begin
          Result.X := StrToFloat(Copy(workCopy, 1, delimiter - 1));
          System.Delete(workCopy, 1, delimiter);
          workCopy := TrimLeft(workCopy);
          delimiter := Pos(' ', workCopy);
          if (Length(workCopy) > 0) and (delimiter > 0) then
          begin
            Result.Y := StrToFloat(Copy(workCopy, 1, delimiter - 1));
            System.Delete(workCopy, 1, delimiter);
            workCopy := TrimLeft(workCopy);
            delimiter := Pos(' ', workCopy);
            if (Length(workCopy) > 0) and (delimiter > 0) then
            begin
              Result.Z := StrToFloat(Copy(workCopy, 1, delimiter - 1));
              System.Delete(workCopy, 1, delimiter);
              workCopy := TrimLeft(workCopy);
              Result.W := StrToFloat(workCopy);
            end
            else
              Result.Z := StrToFloat(workCopy);
          end
          else
            Result.Y := StrToFloat(workCopy);
        end
        else
          Result.X := StrToFloat(workCopy);
      except
        ShowMessage('Wrong vector format. Use: ''<red green blue alpha>''!');
        Abort;
      end;
  end;
end;

// ------------------------------------------------------------------------------

function TgxColorManager.GetColorName(const aColor: TColorVector): String;

const
  MinDiff = 1E-6;

var
  i: Integer;

begin
  for i := 0 to Count - 1 do
    with TColorEntry(Items[i]^) do
      if (Abs(Color.X - aColor.X) < MinDiff) and
        (Abs(Color.Y - aColor.Y) < MinDiff) and
        (Abs(Color.Z - aColor.Z) < MinDiff) and
        (Abs(Color.W - aColor.W) < MinDiff) then
        Break;
  if i < Count then
    Result := string(TColorEntry(Items[i]^).Name)
  else
    Result := Format('<%.3f %.3f %.3f %.3f>', [aColor.X, aColor.Y, aColor.Z,
      aColor.W]);
end;

destructor TgxColorManager.Destroy;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    FreeMem(Items[i], SizeOf(TColorEntry));
  inherited Destroy;
end;

procedure TgxColorManager.AddColor(const aName: String;
  const aColor: TColorVector);
var
  newEntry: PColorEntry;
begin
  New(newEntry);
  if newEntry = nil then
    raise Exception.Create('Could not allocate memory for color registration!');
  with newEntry^ do
  begin
    Name := shortstring(aName);
    SetVector(Color, aColor);
  end;
  Add(newEntry);
end;

procedure TgxColorManager.EnumColors(Proc: TGetStrProc);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Proc(string(TColorEntry(Items[i]^).Name));
end;

procedure TgxColorManager.EnumColors(AValues: TStrings);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    AValues.Add(string(TColorEntry(Items[i]^).Name));
end;

procedure TgxColorManager.RegisterDefaultColors;
begin
  Capacity := 150;
  AddColor('clrTransparent', clrTransparent);
  AddColor('clrBlack', clrBlack);
  AddColor('clrGray05', clrGray05);
  AddColor('clrGray10', clrGray10);
  AddColor('clrGray15', clrGray15);
  AddColor('clrGray20', clrGray20);
  AddColor('clrGray25', clrGray25);
  AddColor('clrGray30', clrGray30);
  AddColor('clrGray35', clrGray35);
  AddColor('clrGray40', clrGray40);
  AddColor('clrGray45', clrGray45);
  AddColor('clrGray50', clrGray50);
  AddColor('clrGray55', clrGray55);
  AddColor('clrGray60', clrGray60);
  AddColor('clrGray65', clrGray65);
  AddColor('clrGray70', clrGray70);
  AddColor('clrGray75', clrGray75);
  AddColor('clrGray80', clrGray80);
  AddColor('clrGray85', clrGray85);
  AddColor('clrGray90', clrGray90);
  AddColor('clrGray95', clrGray95);
  AddColor('clrWhite', clrWhite);
  AddColor('clrDimGray', clrDimGray);
  AddColor('clrGray', clrGray);
  AddColor('clrLightGray', clrLightGray);
  AddColor('clrAquamarine', clrAquamarine);
  AddColor('clrBakersChoc', clrBakersChoc);
  AddColor('clrBlueViolet', clrBlueViolet);
  AddColor('clrBrass', clrBrass);
  AddColor('clrBrightGold', clrBrightGold);
  AddColor('clrBronze', clrBronze);
  AddColor('clrBronze2', clrBronze2);
  AddColor('clrBrown', clrBrown);
  AddColor('clrCadetBlue', clrCadetBlue);
  AddColor('clrCoolCopper', clrCoolCopper);
  AddColor('clrCopper', clrCopper);
  AddColor('clrCoral', clrCoral);
  AddColor('clrCornflowerBlue', clrCornflowerBlue);
  AddColor('clrDarkBrown', clrDarkBrown);
  AddColor('clrDarkGreen', clrDarkGreen);
  AddColor('clrDarkOliveGreen', clrDarkOliveGreen);
  AddColor('clrDarkOrchid', clrDarkOrchid);
  AddColor('clrDarkPurple', clrDarkPurple);
  AddColor('clrDarkSlateBlue', clrDarkSlateBlue);
  AddColor('clrDarkSlateGray', clrDarkSlateGray);
  AddColor('clrDarkSlateGrey', clrDarkSlateGrey);
  AddColor('clrDarkTan', clrDarkTan);
  AddColor('clrDarkTurquoise', clrDarkTurquoise);
  AddColor('clrDarkWood', clrDarkWood);
  AddColor('clrDkGreenCopper', clrDkGreenCopper);
  AddColor('clrDustyRose', clrDustyRose);
  AddColor('clrFeldspar', clrFeldspar);
  AddColor('clrFirebrick', clrFirebrick);
  AddColor('clrFlesh', clrFlesh);
  AddColor('clrForestGreen', clrForestGreen);
  AddColor('clrGold', clrGold);
  AddColor('clrGoldenrod', clrGoldenrod);
  AddColor('clrGreenCopper', clrGreenCopper);
  AddColor('clrGreenYellow', clrGreenYellow);
  AddColor('clrHuntersGreen', clrHuntersGreen);
  AddColor('clrIndian', clrIndian);
  AddColor('clrKhaki', clrKhaki);
  AddColor('clrLightBlue', clrLightBlue);
  AddColor('clrLightPurple', clrLightPurple);
  AddColor('clrLightSteelBlue', clrLightSteelBlue);
  AddColor('clrLightWood', clrLightWood);
  AddColor('clrLimeGreen', clrLimeGreen);
  AddColor('clrMandarinOrange', clrMandarinOrange);
  AddColor('clrMaroon', clrMaroon);
  AddColor('clrMediumAquamarine', clrMediumAquamarine);
  AddColor('clrMediumBlue', clrMediumBlue);
  AddColor('clrMediumForestGreen', clrMediumForestGreen);
  AddColor('clrMediumGoldenrod', clrMediumGoldenrod);
  AddColor('clrMediumOrchid', clrMediumOrchid);
  AddColor('clrMediumPurple', clrMediumPurple);
  AddColor('clrMediumSeaGreen', clrMediumSeaGreen);
  AddColor('clrMediumSlateBlue', clrMediumSlateBlue);
  AddColor('clrMediumSpringGreen', clrMediumSpringGreen);
  AddColor('clrMediumTurquoise', clrMediumTurquoise);
  AddColor('clrMediumViolet', clrMediumViolet);
  AddColor('clrMediumWood', clrMediumWood);
  AddColor('clrMidnightBlue', clrMidnightBlue);
  AddColor('clrNavy', clrNavy);
  AddColor('clrNavyBlue', clrNavyBlue);
  AddColor('clrNeonBlue', clrNeonBlue);
  AddColor('clrNeonPink', clrNeonPink);
  AddColor('clrNewMidnightBlue', clrNewMidnightBlue);
  AddColor('clrNewTan', clrNewTan);
  AddColor('clrOldGold', clrOldGold);
  AddColor('clrOrange', clrOrange);
  AddColor('clrOrangeRed', clrOrangeRed);
  AddColor('clrOrchid', clrOrchid);
  AddColor('clrPaleGreen', clrPaleGreen);
  AddColor('clrPink', clrPink);
  AddColor('clrPlum', clrPlum);
  AddColor('clrQuartz', clrQuartz);
  AddColor('clrRichBlue', clrRichBlue);
  AddColor('clrSalmon', clrSalmon);
  AddColor('clrScarlet', clrScarlet);
  AddColor('clrSeaGreen', clrSeaGreen);
  AddColor('clrSemiSweetChoc', clrSemiSweetChoc);
  AddColor('clrSienna', clrSienna);
  AddColor('clrSilver', clrSilver);
  AddColor('clrSkyBlue', clrSkyBlue);
  AddColor('clrSlateBlue', clrSlateBlue);
  AddColor('clrSpicyPink', clrSpicyPink);
  AddColor('clrSpringGreen', clrSpringGreen);
  AddColor('clrSteelBlue', clrSteelBlue);
  AddColor('clrSummerSky', clrSummerSky);
  AddColor('clrTan', clrTan);
  AddColor('clrThistle', clrThistle);
  AddColor('clrTurquoise', clrTurquoise);
  AddColor('clrViolet', clrViolet);
  AddColor('clrVioletRed', clrVioletRed);
  AddColor('clrVeryDarkBrown', clrVeryDarkBrown);
  AddColor('clrVeryLightPurple', clrVeryLightPurple);
  AddColor('clrWheat', clrWheat);
  AddColor('clrYellowGreen', clrYellowGreen);
  AddColor('clrGreen', clrGreen);
  AddColor('clrOlive', clrOlive);
  AddColor('clrPurple', clrPurple);
  AddColor('clrTeal', clrTeal);
  AddColor('clrRed', clrRed);
  AddColor('clrLime', clrLime);
  AddColor('clrYellow', clrYellow);
  AddColor('clrBlue', clrBlue);
  AddColor('clrFuchsia', clrFuchsia);
  AddColor('clrAqua', clrAqua);
  AddColor('clrScrollBar', clrScrollBar);
  AddColor('clrBackground', clrBackground);
  AddColor('clrActiveCaption', clrActiveCaption);
  AddColor('clrInactiveCaption', clrInactiveCaption);
  AddColor('clrMenu', clrMenu);
  AddColor('clrWindow', clrWindow);
  AddColor('clrWindowFrame', clrWindowFrame);
  AddColor('clrMenuText', clrMenuText);
  AddColor('clrWindowText', clrWindowText);
  AddColor('clrCaptionText', clrCaptionText);
  AddColor('clrActiveBorder', clrActiveBorder);
  AddColor('clrInactiveBorder', clrInactiveBorder);
  AddColor('clrAppWorkSpace', clrAppWorkSpace);
  AddColor('clrHighlight', clrHighlight);
  AddColor('clrHighlightText', clrHighlightText);
  AddColor('clrBtnFace', clrBtnFace);
  AddColor('clrBtnShadow', clrBtnShadow);
  AddColor('clrGrayText', clrGrayText);
  AddColor('clrBtnText', clrBtnText);
  AddColor('clrInactiveCaptionText', clrInactiveCaptionText);
  AddColor('clrBtnHighlight', clrBtnHighlight);
  AddColor('clr3DDkShadow', clr3DDkShadow);
  AddColor('clr3DLight', clr3DLight);
  AddColor('clrInfoText', clrInfoText);
  AddColor('clrInfoBk', clrInfoBk);
end;

procedure TgxColorManager.RemoveColor(const aName: String);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
  begin
    if CompareText(string(TColorEntry(Items[i]^).Name), aName) = 0 then
    begin
      Delete(i);
      Break;
    end;
  end;
end;

procedure RegisterColor(const aName: String; const aColor: TColorVector);
begin
  ColorManager.AddColor(aName, aColor);
end;

procedure UnRegisterColor(const aName: String);
begin
  ColorManager.RemoveColor(aName);
end;

//====================================================
initialization
//====================================================

InitGXSceneColors;

finalization

vColorManager.Free;

end.
