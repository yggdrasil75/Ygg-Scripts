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
		ShellExecute(0,nil,'ImageMagick.exe','convert ' + ArtIn.Strings[i] + ' -define dd:mipmaps=1 -define dds:compression=dtx5 DDS:output_file.dds',nil,1);
		LogMessage(1,'Converted ' + ArtIn.Strings[i] + ' to DDS');
	end;
end;

function 