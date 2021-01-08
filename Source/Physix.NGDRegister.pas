//
// The graphics rendering engine GXScene  http://glscene.org
//
unit Physix.NGDRegister;

(* Design time registration code for the Newton Manager *)

interface

uses
  System.Classes,
  Physix.NGDManager;

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
