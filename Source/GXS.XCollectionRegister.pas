//
// This unit is part of the GLScene Engine, http://glscene.org
//
(*
   Register TXCollection property editor 
*)
unit GXS.XCollectionRegister;

interface

{$I Scene.inc}

uses
  System.Classes,
  System.TypInfo,

///  DesignEditors, 
///  DesignIntf,

   Scene.XCollection;

type
	TXCollectionProperty = class(TClassProperty)
	public
      	  function GetAttributes: TPropertyAttributes; override;
	  procedure Edit; override;
	end;

procedure Register;

// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------

uses
  GXS.FXCollectionEditor;


//----------------- TXCollectionProperty ------------------------------------

function TXCollectionProperty.GetAttributes: TPropertyAttributes;
begin
	Result:=[paDialog];
end;

procedure TXCollectionProperty.Edit;
begin
   with FXCollectionEditor do begin
     SetXCollection(TXCollection(GetOrdValue), Self.Designer);
     Show;
   end;
end;

procedure Register;
begin
  RegisterPropertyEditor(TypeInfo(TXCollection), nil, '', TXCollectionProperty);
end;


// ------------------------------------------------------------------
initialization
// ------------------------------------------------------------------



end.
