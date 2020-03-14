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
		if not assigned(foobar) then begin
			addmessage('not foobar');
			temp := ElementAssign(foobar, HighInteger, nil, false);
		end;
		temp := ElementByIndex(foobar, 0);
		if not assigned(temp) then temp := ElementAssign(foobar, HighInteger, nil, false);
		if assigned(temp) then addmessage('temp');
		SetElementEditValues(CurrentStat, 'Model\MODL', 'meshes\ygg\loading\Loader');
		SetEditValue(ElementByPath(temp, 'New Texture'), Name(CurrentTXST));
		
		SetElementEditValues(CurrentStat, 'Model\MODL', 'ygg\loading\Loader.nif');
		SetElementEditValues(CurrentStat, 'DNAM\Max Angle', '90');
		
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