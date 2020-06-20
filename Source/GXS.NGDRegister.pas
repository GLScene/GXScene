(*******************************************
*                                          *
* Graphic Scene Engine, http://glscene.org *
*                                          *
********************************************)

unit GXS.NGDRegister;

(* Design time registration code for the Newton Manager *)

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
