program Project1;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {FixedSettings};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFixedSettings, FixedSettings);
  Application.Run;
end.
