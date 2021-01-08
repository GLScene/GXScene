//
// The graphics rendering engine GXScene  http://glscene.org
//
unit GXS.SoundRegister;

(* Design time registration code for the Sounds *)

interface

uses
  System.Classes,
  Soundx.SMBASS,
  Soundx.SMFMOD,
  Soundx.SMOpenAL,
  Soundx.SMWaveOut;

procedure Register;

// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------

procedure Register;
begin
  RegisterComponents('GXScene',[TgxSMBASS,TgxSMFMOD,TgxSMOpenAL,TgxSMWaveOut]);
end;

end.
