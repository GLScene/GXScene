//
// The unit for GXScene Engine
//
(*
  Design time registration code for the Sounds
*)
unit GXS.SoundRegister;

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
