unit yggloadscreens;
uses yggfunctions;
function initialize: integer;
begin
	result := LoadInit;
end;

function LoadInit: integer;
begin
	
end;

function converted: boolean;
var
	Art:TStringList:
begin
	ArtIn := TStringList.Create;
	FindAllFiles(ArtIn,DataPath + 'Textures\Ygg\Loading', '*.jpg;*.png;*.bmp',true);
	
	for i := 0 to ArtIn.Count do
	begin
		ArtInTemp := ArtIn.strings[i];
		ArtOutTemp := StringReplace(ArtInTemp, '.png', '.dds',[rfReplaceAll]);
		ArtOutTemp := StringReplace(ArtInTemp, '.jpg', '.dds',[rfReplaceAll]);
		ArtOutTemp := StringReplace(ArtInTemp, '.bmp', '.dds',[rfReplaceAll]);
		ShellExecute(0,nil,'Magick.exe','convert "' + ArtIn.Strings[i] + '" -define dd:mipmaps=1 -define dds:compression=dtx5 DDS:"'+ArtOutTemp'"',nil,1);
		LogMessage(1,'Converted ' + ArtInTemp + ' to DDS');
	end;
end;

procedure AddLoadScreen;
begin

end;