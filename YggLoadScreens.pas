unit yggloadscreens;
uses yggfunctions;
var
	ArtOut: TStringDynArray;
function initialize: integer;
begin
	result := LoadInit;
end;

function LoadInit: integer;
var
	f: integer;
	BeginTime, EndTime: TDateTime;
begin
	BeginTime := Time;
	beginLog('YggLoading');
	PassTime(Time);
	Patch := SelectPatch('Ygg_Loading.esp');
	PassFile(Patch);
	remove(ElementByPath(Patch, 'LSCR'));
	LogMessage(0,'---Loading Is Fun---');
	AddMessage('---Loading is fun---');
	if not Converted then begin
		TalkToUser := MessageDlg('There was an error in execution of imagemagick, please check that you have it installed properly including path variables', mtInformation, [mbOk], 0);
	end;
end;

function converted: boolean;
var
	ArtIn: TStringDynArray;
	TDirectory:TDirectory;
	ArtInTemp,ArtOutTemp: string;
	i:integer;
	aFolder:string;
	Paths: tstringlist;
begin
{if StrToInt(ShellExecute(0,nil,'Magick.exe','convert "" -define dd:mipmaps=1 -define dds:compression=dtx5 DDS:""',nil,1)) = 2 then begin
		result := false;
		exit;
		end;}
	if not ContainsText('Magick', GetEnv('PATH')) then begin
		result := false;
		exit;
	end;
	
	Paths := TStringlist.Create;
	paths.DelimitedText := GetEnv('PATH');
	for i := paths.count - 1 downto 0 do
	begin
		if containtsText('Magick', paths.strings[i]) then
		MagickPath := paths.strings[i];
	end;
	
	aFolder := DataPath + IncludeTrailingBackslash('Textures\Ygg\Loading\');
	ArtOut := TStringList.Create;
	ArtIn := TStringList.Create;
	{FindAllFiles(ArtIn,DataPath + 'Textures\Ygg\Loading', '*.jpg;*.png;*.bmp',true);
	FindAllFiles(ArtOut,DataPath + 'Textures\Ygg\Loading', '*.dds',true);}
	LogMessage(0,'Scanning for textures in ' + aFolder);
	ArtIn := TDirectory.GetFiles(aFolder, '*.jpg;*.png;*.bmp', soAllDirectories);
	ArtOut := TDirectory.GetFiles(aFolder, '*.dds', soAllDirectories);
	
	for i := 0 to ArtIn.Count do
	begin
		ArtInTemp := ArtIn[i];
		ArtOutTemp := StringReplace(ArtInTemp, '.png', '.dds',[rfReplaceAll]);
		ArtOutTemp := StringReplace(ArtInTemp, '.jpg', '.dds',[rfReplaceAll]);
		ArtOutTemp := StringReplace(ArtInTemp, '.bmp', '.dds',[rfReplaceAll]);
		if ArtInTemp = ArtOutTemp then continue;
		ShellExecute(0,nil,MagickPath+'Magick.exe','convert "' + ArtIn[i] + '" -define dd:mipmaps=1 -define dds:compression=dtx5 DDS:"'+ArtOutTemp'"',nil,1);
		LogMessage(1,'Converted ' + ArtInTemp + ' to DDS');
		ArtOut.Add(ArtOutTemp);
	end;
	result := true;
end;

procedure AddLoadScreen;
var
	i:integer
	CurrentRecord,CurrentStat: IInterface;
begin
	for i := ArtOut.Count - 1 do begin
		CurrentRecord := CreateRecord('LSCR');
		CurrentStat := CreateRecord('STAT');
		SetEditorID(CurrentStat, 'YggLoadingSTAT'+ArtOut[i]);
		
		SetEditorID(CurrentRecord, 'YggLoadingLSCR'+ArtOut[i]);
		SetElementEditValues(CurrentStat, 'Model\MODL', ArtOut[i]);
		SetElementEditValues(CurrentRecord,'NNAM', name(CurrentStat));
	end;
end;

end.
