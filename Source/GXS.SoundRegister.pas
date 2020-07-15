(*******************************************
*                                          *
* Graphic Scene Engine, http://glscene.org *
*                                          *
********************************************)

unit GXS.SoundRegister;

(* Design time registration code for the Sounds *)

interface

uses
  System.Classes,
  GXS.SMBASS,
  GXS.SMFMOD,
  GXS.SMOpenAL,
  GXS.SMWaveOut;

procedure Register;

// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------

procedure Register;
begin
  RegisterComponents('GXScene',[TgxSMBASS,TgxSMFMOD,TgxSMOpenAL,TgxSMWaveOut]);
end;

end.
