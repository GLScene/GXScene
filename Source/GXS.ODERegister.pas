(*******************************************
*                                          *
* Graphic Scene Engine, http://glscene.org *
*                                          *
********************************************)

unit GXS.ODERegister;

(* Design time registration code for the ODE Manager *)

interface

uses
  System.Classes,
  GXS.ODEManager;

procedure Register;

// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------

procedure Register;
begin
  RegisterClasses([TgxODEManager, TgxODEJointList, TgxODEJoints, TgxODEElements]);
  RegisterComponents('GXScene',[TgxODEManager,TgxODEJointList]);
end;

end.
