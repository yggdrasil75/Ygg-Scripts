unit yggloadscreens;
uses yggfunctions;
uses sysutils;
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
	remove(GroupBySignature(Patch, 'LSCR'));
	remove(GroupBySignature(Patch, 'STAT'));
	remove(GroupBySignature(Patch, 'TXST'));
	LogMessage(0,'---Loading Is Fun---');
	AddMessage('---Loading is fun---');
	if not Converted then begin
		TalkToUser := MessageDlg('There was an error in execution of imagemagick, please check that you have it installed properly including path variables', mtInformation, [mbOk], 0);
	end;
	AddLoadScreen;
	result := 1;
end;

function converted: boolean;
var
	ArtIn: TStringDynArray;
	TDirectory:TDirectory;
	ArtInTemp,ArtOutTemp: string;
	i:integer;
	aFolder:string;
	Paths: tstringlist;
	Ini:TMemIniFile;
	MagickPath,sDirPath:string;
begin
	{Paths := TStringlist.Create;
	paths.DelimitedText := SysUtils.GetEnvironmentVariable('PATH');
	for i := paths.count - 1 downto 0 do
	begin
		if containtsText('Magick', paths.strings[i]) then
		MagickPath := paths.strings[i];
	end;}
	ini := TMemIniFile.Create(ScriptsPath + 'Ygg.ini');
	Ini.WriteString('BaseData', '%K', '0');
	//AddMessage(ShellExecute('cmd',nil,ScriptsPath+'magickpath.bat',nil,nil,1));
	ShellExecute(0,nil,ScriptsPath+'magickpath.bat',nil,nil,1);
	MagickPath := Ini.ReadString('BaseData', '%K', 'a');
	aFolder := DataPath + IncludeTrailingBackslash('Textures\Ygg\Loading\');
	//ArtOut := TStringList.Create;
	//ArtIn := TStringList.Create;
	{FindAllFiles(ArtIn,DataPath + 'Textures\Ygg\Loading', '*.jpg;*.png;*.bmp',true);
	FindAllFiles(ArtOut,DataPath + 'Textures\Ygg\Loading', '*.dds',true);}
	LogMessage(0,'Scanning for textures in ' + aFolder);
	
	sDirPath := DataPath + 'Textures\Ygg\Loading\';
	if not DirectoryExists(sDirPath) then  // DirectoryExists returns true if directory path exists, can return false due to user permissions
	if not ForceDirectories(sDirPath) then  // ForceDirectories returns true if directory path was created
	
	ArtIn := TDirectory.GetFiles(aFolder, '*.jpg;*.png;*.bmp', soAllDirectories);
	ArtOut := TDirectory.GetFiles(aFolder, '*.dds', soAllDirectories);
	
	for i := 0 to Length(ArtIn) - 1 do
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
	i:integer;
	TempInt: integer;
	CurrentEDIDAddition:string;
	CurrentRecord,CurrentStat,CurrentTXST: IInterface;
begin
	for i := Length(ArtOut) - 1 downto 0 do begin
		tempint := length(artout[i]) - pos('\', ReverseString(ArtOut[i]))+2;
		CurrentEDIDAddition := copy(ArtOut[i], tempint, length(artout[i]));
		CurrentEDIDAddition := StringReplace(CurrentEDIDAddition, '.dds', '',[rfReplaceAll]);
		CurrentRecord := CreateRecord('LSCR');
		CurrentStat := CreateRecord('STAT');
		CurrentTXST := CreateRecord('TXST');
		SetEditorID(CurrentStat, 'YggLoadingSTAT'+CurrentEDIDAddition);
		SetEditorID(CurrentTXST, 'YggLoadingTXST'+CurrentEDIDAddition);
		
		SetEditorID(CurrentRecord, 'YggLoadingLSCR'+CurrentEDIDAddition);
		
		Add(CurrentStat,'Model',false);
		Add(CurrentStat,'Model\MODS',false);
		ElementAssign(ElementByPath(CurrentStat, 'Model\MODS'), HighInteger, nil, false);
		SetElementEditValues(CurrentStat, 'Model\MODL', 'meshes\ygg\loading\Loader');
		SetElementEditValues(CurrentStat, 'Model\MODS\Alternate Texture', Name(CurrentTXST));
		
		Add(CurrentTXST,'Textures (RGB/A)', false);
		Add(CurrentTXST,'Textures', false);
		SetElementEditValues(CurrentTXST, 'Textures (RGB/A)\TX00', CurrentEDIDAddition+'.dds');
		
		
		Add(CurrentRecord,'NNAM', false);
		Add(CurrentRecord,'SNAM', false);
		Add(CurrentRecord,'RNAM', false);
		Add(CurrentRecord,'XNAM', false);
		Add(CurrentRecord,'ONAM', false);
		
		SetElementEditValues(CurrentRecord,'NNAM', name(CurrentStat));
		SetElementEditValues(CurrentRecord, 'SNAM', '2.0');
		SetElementEditValues(CurrentRecord, 'RNAM\X', '-90');
		SetElementEditValues(CurrentRecord, 'XNAM\X', '-45');
		
		SetElementEditValues(CurrentStat, 'Model\MODL', 'ygg\loading\Loader.nif');
		if assigned(CurrentTXST) then addmessage('txst?');
		SetElementEditValues(CurrentStat, 'Model\MODS', name(CurrentTXST));
		SetElementEditValues(CurrentStat, 'DNAM\Max Angle', '90');
		
		//meshes\ygg\loading\Loader.nif
		AddCondition(CurrentRecord);
	end;
end;

// adds requirement 'HasPerk' to Conditions list
function AddCondition(list: IInterface): IInterface;
var
  newCondition, tmp: IInterface;
begin
	if not (Name(list) = 'Conditions') then begin
		if Signature(list) = 'LSCR' then begin // record itself was provided
			tmp := ElementByPath(list, 'Conditions');
			if not Assigned(tmp) then begin
				Add(list, 'Conditions', true);
				list := ElementByPath(list, 'Conditions');
				newCondition := ElementByIndex(list, 0); // xEdit will create dummy condition if new list was added
			end else begin
				list := tmp;
			end;
		end;
	end;

	if not Assigned(newCondition) then begin
	// create condition
		newCondition := ElementAssign(list, HighInteger, nil, false);
	end;

	// set type to Equal to
	SetElementEditValues(newCondition, 'CTDA\Type', '10100000');

	// set some needed properties
	SetElementEditValues(newCondition, 'CTDA\Comparison Value', '100');
	SetElementEditValues(newCondition, 'CTDA\Function', 'GetRandomPercent');
	SetElementEditValues(newCondition, 'CTDA\None', '00000000');
	SetElementEditValues(newCondition, 'CTDA\Run On', 'Subject');
	// don't know what is this, but it should be equal to -1, if Function Runs On Subject
	SetElementEditValues(newCondition, 'CTDA\Parameter #3', '-1');

	// remove nil records from list
	removeInvalidEntries(list);

	Result := newCondition;
end;

Function ReverseString(AText: string): string;
var
    i,j:longint;
begin
  setlength(result,length(atext));
  i:=1;
  j:=length(atext);
  while (i<=j) do
    begin
      result[i]:=atext[j-i+1];
      inc(i);
    end;
end;

end.
