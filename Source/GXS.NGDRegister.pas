//
// The unit for GXScene Engine
//
(*
  Design time registration code for the Newton Manager.
*)

unit GXS.NGDRegister;

interface

uses
  System.Classes,
  GXS.NGDManager;

procedure register;

//=========================================================
implementation
//=========================================================

procedure register;
begin
  RegisterClasses([TgxNGDManager, TgxNGDDynamic, TgxNGDStatic]);
  RegisterComponents('GXScene', [TgxNGDManager]);
end;

end.
