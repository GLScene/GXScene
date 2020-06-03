//
// Graphic Scene Engine, http://glscene.org
//
(*
   An abstract scripting interface for GLScene
   This unit provides the base methods for compiling and executing scripts as
   well as calling scripted functions. No scripting APIs are implemented here,
   only abstracted functions.

*)
unit GXS.ScriptBase;

interface

uses
  System.Classes, 
  XCollection;

type
  TgxScriptState = ( ssUncompiled,    // The script has yet to be compiled.
                     ssCompileErrors, // Errors occurred while compiling.
                     ssCompiled,      // The script has been compiled and is
                                      // ready to be executed/started.
                     ssRunningErrors, // Errors occured while the script was
                                      // running.
                     ssRunning );     // The script is currently active and
                                      // is running without error.

  // TgxScriptBase
  //
  { The base script class that defines the abstract functions and properties. 
     Don't use this class directly, use the script classes descended from this 
     base class.  }
  TgxScriptBase = class(TXCollectionItem)
		private
      
      FText : TStringList;
      FDescription : String;
      FErrors : TStringList; // not persistent

		protected
			
      procedure WriteToFiler(writer : TWriter); override;
      procedure ReadFromFiler(reader : TReader); override;
      function GetState : TgxScriptState; virtual; abstract;
      procedure SetText(const Value : TStringList);
      procedure Notification(AComponent: TComponent; Operation: TOperation); virtual;

		public
      
      constructor Create(aOwner : TXCollection); override;
      destructor Destroy; override;

      procedure Assign(Source: TPersistent); override;

      procedure Compile; virtual; abstract;
      procedure Start; virtual; abstract;
      procedure Stop; virtual; abstract;
      procedure Execute; virtual; abstract;
      procedure Invalidate; virtual; abstract;
      function Call(aName : String;
        aParams : array of Variant) : Variant; virtual; abstract;
      

      property Errors : TStringList read FErrors;
      property State : TgxScriptState read GetState;

		published
      
      property Text : TStringList read FText write SetText;
      property Description : String read FDescription write FDescription;

  end;

  // TgxScripts
  //
  { XCollection descendant for storing and handling scripts. }
  TgxScripts = class(TXCollection)
		private
			

		protected
			
      function GetItems(index : Integer) : TgxScriptBase;

		public
			
			procedure Assign(Source: TPersistent); override;

      class function ItemsClass : TXCollectionItemClass; override;

      function CanAdd(aClass : TXCollectionItemClass) : Boolean; override;
      property Items[index : Integer] : TgxScriptBase read GetItems; default;

  end;

  // TgxScriptLibrary
  //
  { Encapsulation of the scripts XCollection to help with script handling at
     design-time. Links the scripts to Delphi's persistence model. }
  TgxScriptLibrary = class (TComponent)
    private
      
      FScripts : TgxScripts;

    protected
      
      procedure DefineProperties(Filer : TFiler); override;
      procedure WriteScriptsData(Stream : TStream);
      procedure ReadScriptsData(Stream : TStream);
      procedure Loaded; override;
      procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    public
      
      constructor Create(AOwner : TComponent); override;
      destructor Destroy; override;

    published
      
      property Scripts : TgxScripts read FScripts;

  end;

implementation

// ---------------
// --------------- TgxScriptBase ---------------
// ---------------

// Create
//
constructor TgxScriptBase.Create(aOwner: TXCollection);
begin
  inherited;
  FText:=TStringList.Create;
  FErrors:=TStringList.Create;
end;

// Destroy
//
destructor TgxScriptBase.Destroy;
begin
  FText.Free;
  FErrors.Free;
  inherited;
end;

// Assign
//
procedure TgxScriptBase.Assign(Source: TPersistent);
begin
  inherited;
  if Source is TgxScriptBase then begin
    Text.Assign(TgxScriptBase(Source).Text);
    Description:=TgxScriptBase(Source).Description;
  end;
end;

// ReadFromFiler
//
procedure TgxScriptBase.ReadFromFiler(reader: TReader);
var
  archiveVersion : Integer;
begin
  inherited;
  archiveVersion:=reader.ReadInteger;
  Assert(archiveVersion = 0);

  with reader do begin
    FText.Text:=ReadString;
    FDescription:=ReadString;
  end;
end;

// WriteToFiler
//
procedure TgxScriptBase.WriteToFiler(writer: TWriter);
begin
  inherited;
  writer.WriteInteger(0);

  with writer do begin
    WriteString(FText.Text);
    WriteString(FDescription);
  end;
end;

// SetText
//
procedure TgxScriptBase.SetText(const Value : TStringList);
begin
  Text.Assign(Value);
end;

// Notification
//
procedure TgxScriptBase.Notification(AComponent: TComponent; Operation: TOperation);
begin
  // Virtual
end;

// ---------------
// --------------- TgxScripts ---------------
// ---------------

// Assign
//
procedure TgxScripts.Assign(Source: TPersistent);
begin
  inherited;
  // Nothing yet
end;

// GetItems
//
function TgxScripts.GetItems(index: Integer): TgxScriptBase;
begin
  Result:=TgxScriptBase(inherited GetItems(index));
end;

// ItemsClass
//
class function TgxScripts.ItemsClass: TXCollectionItemClass;
begin
  Result:=TgxScriptBase;
end;

// CanAdd
//
function TgxScripts.CanAdd(aClass: TXCollectionItemClass): Boolean;
begin
  Result:=aClass.InheritsFrom(TgxScriptBase);
end;


// ---------------
// --------------- TgxScriptLibrary ---------------
// ---------------

// Create
//
constructor TgxScriptLibrary.Create(AOwner : TComponent);
begin
  inherited;
  FScripts:=TgxScripts.Create(Self);
end;

// Destroy
//
destructor TgxScriptLibrary.Destroy;
begin
  FScripts.Free;
  inherited;
end;

// DefineProperties
//
procedure TgxScriptLibrary.DefineProperties(Filer : TFiler);
begin
  inherited;
  Filer.DefineBinaryProperty('ScriptsData',
    ReadScriptsData, WriteScriptsData, (Scripts.Count>0));
end;

// WriteScriptsData
//
procedure TgxScriptLibrary.WriteScriptsData(Stream : TStream);
var
  writer : TWriter;
begin
  writer:=TWriter.Create(stream, 16384);
  try
    Scripts.WriteToFiler(writer);
  finally
    writer.Free;
  end;
end;

// ReadScriptsData
//
procedure TgxScriptLibrary.ReadScriptsData(Stream : TStream);
var
  reader : TReader;
begin
  reader:=TReader.Create(stream, 16384);
  try
    Scripts.ReadFromFiler(reader);
  finally
    reader.Free;
  end;
end;

// Loaded
//
procedure TgxScriptLibrary.Loaded;
begin
  inherited;
  Scripts.Loaded;
end;

// Notification
//
procedure TgxScriptLibrary.Notification(AComponent: TComponent; Operation: TOperation);
var
  i : Integer;
begin
  if Assigned(Scripts) then
    for i:=0 to Scripts.Count-1 do
      Scripts[i].Notification(AComponent, Operation);
  inherited;
end;

initialization

  RegisterClasses([TgxScriptLibrary, TgxScripts, TgxScriptBase]);

end.
