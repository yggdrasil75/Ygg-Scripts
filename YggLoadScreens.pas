unit yggloadscreens;
uses yggfunctions;

var
	ArtOut: TStringDynArray;
	Screenshots: boolean;
	
function initialize: integer;
begin
	result := LoadInit;
end;

function LoadInit: integer;
var
	f: integer;
	BeginTime, EndTime: TDateTime;
	TDirectory:TDirectory;
	sDirPath:string;
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
	Screenshots := AskScreenshot;
	//converted;
	if Screenshots then
	begin
		sGamePath := Delete(DataPath,length(DataPath)-5, 5);
		ArtIn := TDirectory.GetFiles(sDirPath, '*.jpg;*.png;*.bmp', soAllDirectories);
		for i := length(ArtIn) - 1 downto 0 do begin
		AddMessage(ArtIn);
			CopyFile(ArtIn[i],DataPath+'\textures\ygg\loading\'+ArtIn[i]);
		end;
	end;
	
	ShellExecute(0,'open',DataPath+'\textures\ygg\loading\magick.bat',nil,DataPath+'\textures\ygg\loading\',1);
	sDirPath := DataPath + 'Textures\Ygg\Loading\';
	ArtOut := TDirectory.GetFiles(sDirPath, '*.dds', soAllDirectories);
	AddLoadScreen;
	result := 1;
end;

function AskScreenshot:boolean;
var
	optionAddScreenshot: integer;
	ini:TMemIniFile;
begin
	ini := TMemIniFile.Create(ScriptsPath + 'Ygg.ini');
	if ini.ReadInteger('Loading', 'screenshots', 0) = 0 then
	begin
		optionAddScreenshot := MessageDlg('Do you want to add screenshots from the game directory?', mtConfirmation, [mbYes, mbNo, mbAbort], 0);
		if optionAddScreenshot = mrAbort then
			exit
		else ini.WriteInteger('Loading', 'screenshots', optionAddScreenshot);
	end else optionAddScreenshot := ini.ReadInteger('Loading', 'Loading', 0);
	
	if optionAddScreenshot = 7 then result := true
	else result := false;
	
	Ini.UpdateFile;
end;

{function converted: boolean;
var
	ArtIn: TStringDynArray;
	TDirectory:TDirectory;
	ArtInTemp,ArtOutTemp: string;
	i:integer;
	Paths: tstringlist;
	Ini:TMemIniFile;
	MagickPath,sDirPath,TempPath:string;
begin
	//FileCreate(ScriptsPath+'Ygg.ini');
	ini := TMemIniFile.Create(ScriptsPath + 'Ygg.ini');
	TempPath := Ini.ReadString('Loading', '%k', 'a');
	if TempPath = 'a' then
	begin
		Ini.WriteString('Loading', '%k', 'a');
		//AddMessage(ShellExecute('cmd',nil,ScriptsPath+'magickpath.bat',nil,nil,1));
		ShellExecute(0,'open',ScriptsPath+'magickpath.bat',nil,nil,1);
	end;
	TempPath := 'D:\games\skyrim\skyrim tools\ImageMagick-7.0.10-Q16;C:\Program Files (x86)\Embarcadero\Studio\20.0\bin;C:\Users\Public\Documents\Embarcadero\Studio\20.0\Bpl;C:\Program Files (x86)\Embarcadero\Studio\20.0\bin64;C:\Users\Public\Documents\Embarcadero\Studio\20.0\Bpl\Win64;C:\Program Files\Python37\Scripts\;C:\Program Files\Python37\;C:\Program Files (x86)\Intel\Intel(R) Management Engine Components\iCLS\;C:\Program Files\Intel\Intel(R) Management Engine Components\iCLS\;C:\Program Files (x86)\Razer Chroma SDK\bin;C:\Program Files\Razer Chroma SDK\bin;C:\Program Files (x86)\Common Files\Oracle\Java\javapath;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\WINDOWS\System32\WindowsPowerShell\v1.0\;C:\Program Files (x86)\ATI Technologies\ATI.ACE\Core-Static;C:\WINDOWS\System32\OpenSSH\;C:\Users\yggdrasil75\AppData\Local\Microsoft\WindowsApps;C:\Program Files\Common Files\Autodesk Shared\;C:\Program Files (x86)\Intel\Intel(R) Management Engine Components\DAL;C:\Program Files\Intel\Intel(R) Management Engine Components\DAL;C:\Program Files (x86)\Intel\Intel(R) Management Engine Components\IPT;C:\Program Files\Intel\Intel(R) Management Engine Components\IPT;C:\Program Files\Microsoft SQL Server\120\Tools\Binn\;C:\Program Files (x86)\NVIDIA Corporation\PhysX\Common;C:\Program Files\WorldPainter;C:\Program Files\dotnet\;C:\Program Files\Microsoft SQL Server\130\Tools\Binn\;C:\Program Files\NVIDIA Corporation\NVIDIA NvDLISR;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\WINDOWS\System32\WindowsPowerShell\v1.0\;C:\WINDOWS\System32\OpenSSH\;C:\Program Files (x86)\Autodesk\Backburner\;C:\Program Files\nodejs\;C:\ProgramData\chocolatey\bin;C:\Program Files\Git\cmd;C:\Program Files (x86)\QuickTime\QTSystem\;C:\Users\yggdrasil75\AppData\Local\Programs\Python\Python37\Scripts\;C:\Users\yggdrasil75\AppData\Local\Programs\Python\Python37\;C:\Users\yggdrasil75\AppData\Local\Microsoft\WindowsApps;C:\ADE\aime_775015\oracle\instantclient\instantclient_18_3;C:\Users\yggdrasil75\AppData\Roaming\npm;C:\Users\yggdrasil75\.dotnet\tools;C:\Python37\Scripts;;C:\Users\yggdrasil75\AppData\Local\Microsoft\WindowsApps;C:\Users\yggdrasil75\AppData\Local\Programs\Microsoft VS Code\bin';//Ini.ReadString('Loading', '%k', 'a');
	TempPath := StringReplace(MagickPath, ';',',',[rfReplaceAll]);
	
	Paths := TStringlist.Create;
	paths.DelimitedText := TempPath;
	for i := paths.count - 1 downto 0 do
	begin
		if ContainsText('Magick', paths.strings[i]) then
		MagickPath := paths.strings[i];
	end;
	Ini.UpdateFile;
	//ArtOut := TStringList.Create;
	//ArtIn := TStringList.Create;
	//FindAllFiles(ArtIn,DataPath + 'Textures\Ygg\Loading', '*.jpg;*.png;*.bmp',true);
	//FindAllFiles(ArtOut,DataPath + 'Textures\Ygg\Loading', '*.dds',true);
	LogMessage(0,'Scanning for textures in ' + sDirPath);
	
	sDirPath := DataPath + 'Textures\Ygg\Loading\';
	if not DirectoryExists(sDirPath) then  // DirectoryExists returns true if directory path exists, can return false due to user permissions
	if not ForceDirectories(sDirPath) then  // ForceDirectories returns true if directory path was created
	
	ArtIn := TDirectory.GetFiles(sDirPath, '*.jpg;*.png;*.bmp', soAllDirectories);
	ArtOut := TDirectory.GetFiles(sDirPath, '*.dds', soAllDirectories);
	
	for i := 0 to Length(ArtIn) - 1 do
	begin
		ArtInTemp := ArtIn[i];
		ArtOutTemp := StringReplace(ArtInTemp, '.png', '.dds',[rfReplaceAll]);
		ArtOutTemp := StringReplace(ArtInTemp, '.jpg', '.dds',[rfReplaceAll]);
		ArtOutTemp := StringReplace(ArtInTemp, '.bmp', '.dds',[rfReplaceAll]);
		if ArtInTemp = ArtOutTemp then continue;
		ShellExecute(0,'open',MagickPath+'Magick.exe','convert "' + ArtIn[i] + '" -define dd:mipmaps=1 -define dds:compression=dtx5 DDS:"'+ArtOutTemp'"',nil,1);
		LogMessage(1,'Converted ' + ArtInTemp + ' to DDS');
		ArtOut.Add(ArtOutTemp);
	end;
	
	if Screenshots then
	begin
		sGamePath := Delete(DataPath,length(DataPath)-5, 5);
		ArtIn := TDirectory.GetFiles(sDirPath, '*.jpg;*.png;*.bmp', soAllDirectories);
		ArtOut := TDirectory.GetFiles(sDirPath, '*.dds', soAllDirectories);

		for i := 0 to Length(ArtIn) - 1 do
		begin
			ArtInTemp := ArtIn[i];
			ArtOutTemp := StringReplace(ArtInTemp, '.png', '.dds',[rfReplaceAll]);
			ArtOutTemp := StringReplace(ArtInTemp, '.jpg', '.dds',[rfReplaceAll]);
			ArtOutTemp := StringReplace(ArtInTemp, '.bmp', '.dds',[rfReplaceAll]);
			ArtOutTemp := 'Data\Textures\Ygg\Loading\' + ArtOutTemp;
			if ArtInTemp = ArtOutTemp then continue;
			ShellExecute(0,'open',MagickPath+'Magick.exe','convert "' + ArtIn[i] + '" -define dd:mipmaps=1 -define dds:compression=dtx5 DDS:"'+ArtOutTemp'"',nil,1);
			LogMessage(1,'Converted ' + ArtInTemp + ' to DDS');
			ArtOut.Add(ArtOutTemp);
		end;
	end;
	
	result := true;
end;}

procedure AddLoadScreen;
var
	i:integer;
	TempInt: integer;
	CurrentEDIDAddition:string;
	foobar,CurrentRecord,CurrentStat,CurrentTXST,temp: IInterface;
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
		foobar := ElementByPath(CurrentStat, 'Model\MODS');
		temp := ElementByIndex(foobar, 0);
		if not assigned(temp) then temp := ElementAssign(foobar, HighInteger, nil, false);
		if assigned(temp) then addmessage('temp');
		SetElementEditValues(CurrentStat, 'Model\MODL', 'meshes\ygg\loading\Loader');
		SetEditValue(ElementByPath(temp, 'New Texture'), Name(CurrentTXST));
		
		Add(CurrentTXST,'Textures (RGB/A)', false);
		Add(CurrentTXST,'Textures', false);
		SetElementEditValues(CurrentTXST, 'Textures (RGB/A)\TX00', 'Ygg\Loading\'+CurrentEDIDAddition+'.dds');
		
		
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
		SetElementEditValues(CurrentStat, 'DNAM\Max Angle', '90');
		
		AddCondition(CurrentRecord);
	end;
end;

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