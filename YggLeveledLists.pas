unit YggLeveledLists;

uses YggFunctions;

var
	Patch, itemRecord: IInterface;
	HashedList: THashedStringList;
	MaterialList: TStringList;
	skipFileCount, readFileCount, optionAddOnly, : integer;
	Ini: TMemIniFile;
	debug, firstRun: boolean;
	sBaseMaster: string;


function Initialize: integer;
var
	BeginTime, EndTime: TDateTime;
	f: integer;
begin
	BeginTime := Time;
	beginLog('Leveled List start');
	PassTime(Time);
	debug := false;
	firstRun := false;
	Patch := SelectPatch('Ygg_Leveled.esp');
	PassFile(Patch);
	BeginUpdate(Patch);
	try
		AddmasterBySignature('ARMO');
		AddmasterBySignature('AMMO');
		AddmasterBySignature('WEAP');
		AddmasterBySignature('COBJ');
		AddmasterBySignature('MISC');
		MasterLines;
	finally EndUpdate(Patch);
	end;
	IniProcess;
	skipFileCount := 0;
	readFileCount := 0;
	remove(ElementByPath(Patch, 'COBJ'));
	armo := false;
	Randomize;
	InitializeRecipes;
	AddMessage('---Making stuff worldly---');
	EndTime := Time;
	LogMessage(1, TimeBtwn(BeginTime, EndTime) + 'Initialize');
end;

function IniProcess: integer;
var
	TalkToUser: integer;
begin
	BeginTime := Time;
	Ini := TMemIniFile.Create(ScriptsPath + 'Ygg.ini');
	TalkToUser := ini.ReadInteger('BaseData', 'FirstRun', MessageDlg('There will be a few settings options pop up on the first run, these settings will be saved to Ygg.ini in the folder that contains the script you are currently running. if you ever want to change them, you can delete the line from the ini, alter it manually, or just delete the ini file itself.', mtInformation, [mbOk], 0));
	ini.WriteInteger('BaseData', 'FirstRun', TalkToUser);
	GenderSplitNeeded := ini.ReadInteger('Crafting', 'bGenderSplit', MessageDlg('some items often have missing male versions, which can cause various issues like invisible bodies.'
	 + 'should the script attempt to split female leveled lists and male leveled lists?', mtConfirmation, [mbYes, mbNo, mbAbort], 0));
	if GenderSplitNeeded = mrAbort then
		exit
	else ini.WriteInteger('Crafting', 'bGenderSplit', GenderSplitNeeded);
	genderSplitAlways := ini.ReadInteger('Crafting', 'bGenderSplitFull', MessageDlg('it doesnt make sense that when a woman wears a piece of armor it looks one way, but when a man wears it it is very different. '
	 + 'this option will duplicate every armor that has a male and a female version, set one to only have the male version, the other to only have the female version no matter who wears it.' + 
	 'any armor that only has 1 gender or uses the same mesh already for both genders will remain as such.', mtConfirmation, [mbYes, mbNo, mbAbort], 0));
	if genderSplitAlways = mrAbort then
		exit
	else ini.WriteInteger('Crafting', 'bGenderSplitFull', genderSplitAlways);
	sBaseMaster := Ini.ReadString('BaseData', 'sBaseMaster', 'Skyrim.esm,Dragonborn.esm,Update.esm,Dawnguard.esm,HearthFires.esm,SkyrimSE.exe,Unofficial Skyrim Special Edition Patch.esp')
		ini.WriteString('BaseData', 'sBaseMaster', sBaseMaster);
	firstRun := Ini.ReadBool('Leveled Lists', 'UpdateINI', true);
	CreateBase; 
	//CraftMult := Ini.ReadInteger('BaseData', 'iCraftingMult', 1);
	//Ini.WriteInteger('BaseData', 'iCraftingMult', CraftMult);
	Ini.WriteBool('Leveled Lists', 'UpdateINI', false);
	Ini.UpdateFile;
	EndTime := Time;
	LogMessage(1, TimeBtwn(BeginTime, EndTime) + 'Initialize');
end;

// for every record selected in xEdit
function Process(selectedRecord: IInterface): integer;
var
	recordSignature: string;
	recipeCraft: IInterface;
	CurrentFile: IInterface;
begin
	while readFileCount = 0 do
	begin
		if skipFileCount = 0 then
		begin
			CurrentFile := getfile(selectedRecord);
			if hasGroup(CurrentFile, 'ARMO') OR hasGroup(currentFile, 'WEAP') OR hasGroup(CurrentFile, 'AMMO') then
			begin
				readFileCount := elementCount(CurrentFile);
				//addMessage('plugin has armor, weapons, and/or ammo. attempting process');
			end else
			begin
				skipFileCount := elementCount(CurrentFile) - 1;
				//addMessage('plugin contains no armor, weapons or ammo, skipping.');
				exit;
			end;
		end else
		begin
			//addMessage('skipped record');
			skipFileCount := skipFileCount - 1;
			exit;
		end;
	end;
	itemRecord := selectedRecord;
	if not IsWinningOVerride(itemRecord) then 
	begin
		exit;
	end;
	PassRecord(itemRecord);
	//recordSignature := Signature(selectedRecord);
	// filter selected records, which are not valid
	// NOTE: only armors are exepted, for now
	if GetIsDeleted(itemRecord) then 
	begin
		exit;
	end;
	
	if not GetElementNativeValues(itemRecord, 'EITM') > 0 then 
	begin
		exit;
	end;

	if IntToStr(GetElementNativeValues(itemRecord, 'Record Header\Record Flags\Non-Playable')) < 0 then exit;
	if IntToStr(GetElementNativeValues(itemRecord, 'DATA\Flags\Non-Playable')) < 0 then exit;
	if hasKeyword('Dummy') then exit;
	//AddMessage('recipe done');
	
	Result := 0;
end;

// runs in the end
function Finalize: integer;
begin
	CleanMasters(Patch);
	AddMessage('---Items in Leveled Lists---');
	Sign;
	Result := 0;
end;

procedure CreateBase;
begin
	
end;

end.