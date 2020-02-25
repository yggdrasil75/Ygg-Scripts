unit YGGArmorSplitter;

//Uses ArmorGooey;
Uses YggFunctions;

var
	Patch, itemRecord: IInterface;
	RaceList, ArmoList, LVLIList, COBJList, CONTList, NPC_List, LVLIListList, COBJListList, CONTListList, NPC_ListList, ArmoListList, OTFTList, OTFTListList: TStringList;

// runs on script start
function Initialize: integer;
var
	f: integer;
	BeginTime, EndTime: TDateTime;
begin
	Patch := SelectPatch('YGG_ArmorSplit.esp');
	PassFile(Patch);
	BeginUpdate(Patch);
	try
		AddmasterBySignature('ARMO');
		AddmasterBySignature('NPC_');
		AddmasterBySignature('COBJ');
		AddmasterBySignature('OTFT');
		AddmasterBySignature('LVLI');
		AddmasterBySignature('ARMA');
		AddmasterBySignature('ENCH');
		AddmasterBySignature('KYWD');
		AddmasterBySignature('RACE');
	finally EndUpdate(Patch);
	end;
	Randomize;
	remove(GroupBySignature(patch, 'ARMO'));
	remove(GroupBySignature(patch, 'ARMA'));
	remove(GroupBySignature(patch, 'NPC_'));
	remove(GroupBySignature(patch, 'COBJ'));
	remove(GroupBySignature(patch, 'OTFT'));
	remove(GroupBySignature(patch, 'LVLI'));
	remove(GroupBySignature(patch, 'CONT'));
	AddMessage('---Making Armor reasonably different---');
	GatherArmo;
	Copier;
	AddMessage('armoa');
	LVLIHandler;
	COBJHandler;
	OTFTHandler;
	CONTHandler;
	NPC_Handler;
end;

// runs in the end
function Finalize: integer;
begin
	CleanMasters(Patch);
	AddMessage('---Splitting process ended---');
	Sign;
	Result := 0;
end;

procedure gatherArmo;
var
	armoPlugins: TStringList;
	i, j: integer;
	CurrentGroup, CurrentRecord: IInterface;
begin
	armoPlugins := TStringList.Create;
	for i := filecount - 1 downto 0 do
	begin
		if hasGroup(fileByIndex(i), 'ARMO') then
		armoPlugins.addObject(GetfileName(FileByIndex(i)), FileByIndex(i)); 
	end;
	ArmoList := TStringList.Create;
	for i := armoPlugins.Count - 1 downto 0 do
	begin
		CurrentGroup := GroupBySignature(ObjectToElement(armoPlugins.objects[i]), 'ARMO');
		for j := ElementCount(CurrentGroup) - 1 downto 0 do
		begin
			CurrentRecord := ElementByIndex(CurrentGroup, j);
			if GetIsDeleted(CurrentRecord) then continue;
			if IntToStr(GetElementNativeValues(CurrentRecord, 'Record Header\Record Flags\Non-Playable')) < 0 then continue;
			if IntToStr(GetElementNativeValues(CurrentRecord, 'DATA\Flags\Non-Playable')) < 0 then continue;
			if pos('skin', EditorID(CurrentRecord)) > 0 then continue;
			if pos('Skin', EditorID(CurrentRecord)) > 0 then continue;
			if ISWinningOverride(CurrentRecord) then 
			ArmoList.AddObject(EditorID(CurrentRecord), CurrentRecord);
		end;
	end;
end;

procedure Copier;
var
	i, j, a: integer;
	CurrentArgonianFemale, CurrentArgonianMale, CurrentArma, CurrentFemale, CurrentFemaleArma, CurrentGroup, CurrentKhajiitFemale, CurrentKhajiitMale, CurrentOrcFemale, CurrentOrcMale, CurrentRecord, Currentmale, CurrentmaleArma: IInterface;
	LVLIAll, NewItem: IInterface;
	TempList: TStringList;
begin
	armoListList := TStringList.Create;
	for i := ArmoList.Count - 1 downto 0 do
	begin
		CurrentRecord := wbCopyElementToFile(ObjectToElement(ArmoList.Objects[i]), Patch, false, true);
			CurrentFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
			SetElementEditValues(CurrentFemale, 'Full - Name', GetElementEditValues(CurrentRecord, 'Full - Name') + ' Female');
			SetEditorID(CurrentFemale, EditorID(CurrentRecord) + 'Female');
			CurrentMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
			SetElementEditValues(Currentmale, 'Full - Name', GetElementEditValues(CurrentRecord, 'Full - Name') + ' male');
			SetEditorID(Currentmale, EditorID(CurrentRecord) + 'male');
			CurrentKhajiitFemale := wbCopyElementToFile(CurrentFemale, Patch, true, true);
			CurrentKhajiitMale := wbCopyElementToFile(CurrentMale, Patch, true, true);
			CurrentOrcFemale := wbCopyElementToFile(CurrentFemale, Patch, true, true);
			CurrentOrcMale := wbCopyElementToFile(CurrentMale, Patch, true, true);
			CurrentArgonianFemale := wbCopyElementToFile(CurrentFemale, Patch, true, true);
			CurrentArgonianMale := wbCopyElementToFile(CurrentMale, Patch, true, true);
			SetEditorID(CurrentArgonianFemale, EditorID(CurrentFemale) + 'Argonian');
			SetEditorID(CurrentArgonianMale, EditorID(CurrentMale) + 'Argonian');
			SetElementEditValues(CurrentArgonianFemale, 'Full - Name', GetElementEditValues(CurrentFemale, 'Full - Name') + ' Argonian');
			SetElementEditValues(CurrentArgonianMale, 'Full - Name', GetElementEditValues(CurrentMale, 'Full - Name') + ' Argonian');
			SetEditorID(CurrentOrcFemale, EditorID(CurrentFemale) + 'Orc');
			SetEditorID(CurrentOrcMale, EditorID(CurrentMale) + 'Orc');
			SetElementEditValues(CurrentOrcFemale, 'Full - Name', GetElementEditValues(CurrentFemale, 'Full - Name') + ' Orc');
			SetElementEditValues(CurrentOrcMale, 'Full - Name', GetElementEditValues(CurrentMale, 'Full - Name') + ' Orc');
			SetEditorID(CurrentKhajiitFemale, EditorID(CurrentFemale) + 'Khajiit');
			SetEditorID(CurrentKhajiitMale, EditorID(CurrentMale) + 'Khajiit');
			SetElementEditValues(CurrentKhajiitFemale, 'Full - Name', GetElementEditValues(CurrentFemale, 'Full - Name') + ' Khajiit');
			SetElementEditValues(CurrentKhajiitMale, 'Full - Name', GetElementEditValues(CurrentMale, 'Full - Name') + ' Khajiit');
		if assigned(ElementByPath(CurrentRecord, 'Male world model\MOD2')) AND assigned(ElementByPath(CurrentRecord, 'Female world model\MOD4')) then
		begin
			SetElementEditValues(CurrentFemale, 'Male world model\MOD2', GetElementEditValues(CurrentFemale, 'Female world model\MOD4'));
			SetElementEditValues(Currentmale, 'Female world model\MOD4', GetElementEditValues(Currentmale, 'Male world model\MOD2'));
		end;
		for j := ElementCount(ElementByPath(CurrentRecord, 'Armature')) - 1 downto 0 do
		begin
			CurrentArma := WinningOverride(LinksTo(ElementByIndex(ElementByPath(CurrentRecord, 'Armature'), j)));
			CurrentFemaleArma := wbCopyElementToFile(CurrentArma, Patch, true, true);
			CurrentMaleArma := wbCopyElementToFile(CurrentArma, Patch, true, true);
			SetEditorID(CurrentFemaleArma, EditorID(CurrentArma) + 'Female');
			SetEditorID(CurrentMaleArma, EditorID(CurrentArma) + 'male');
			if assigned(ElementByPath(CurrentArma, 'Male world model\MOD2')) AND assigned(ElementByPath(CurrentArma, 'Female world model\MOD3')) then
			begin
				SetElementEditValues(CurrentFemaleArma, 'Male world model\MOD2', GetElementEditValues(CurrentFemaleArma, 'Female world model\MOD3'));
				SetElementEditValues(CurrentmaleArma, 'Female world model\MOD3', GetElementEditValues(CurrentmaleArma, 'Male world model\MOD2'));
			end;
			if assigned(ElementByPath(CurrentArma, 'Male 1st Person\MOD4')) AND assigned(ElementByPath(CurrentArma, 'Female 1st Person\MOD5')) then
			begin
				SetElementEditValues(CurrentFemaleArma, 'Male 1st Person\MOD4', GetElementEditValues(CurrentFemaleArma, 'Female 1st Person\MOD5'));
				SetElementEditValues(CurrentmaleArma, 'Female 1st Person\MOD5', GetElementEditValues(CurrentmaleArma, 'Male 1st Person\MOD4'));
			end;
			SetEditValue(ElementByIndex(ElementByPath(CurrentFemale, 'Armature'), j), IntToHex(GetLoadOrderFormID(CurrentFemaleArma),8));
			SetEditValue(ElementByIndex(ElementByPath(CurrentMale, 'Armature'), j), IntToHex(GetLoadOrderFormID(CurrentMaleArma),8));
			if pos('Human', getRaces(CurrentArma)) > 0 then continue;
			if pos('OrcRace', getRaces(CurrentArma)) > 0 then
			begin
				for a := ElementCount(ElementByPath(CurrentOrcFemale, 'Armature')) - 1 downto 1 do
				begin
					remove(ElementByIndex(ElementByPath(CurrentOrcFemale, 'Armature'), a));
				end;
				for a := ElementCount(ElementByPath(CurrentOrcMale, 'Armature')) - 1 downto 1 do
				begin
					remove(ElementByIndex(ElementByPath(CurrentOrcMale, 'Armature'), a));
				end;
				SetEditValue(ElementByIndex(ElementByPath(CurrentOrcFemale, 'Armature'), 1), IntToHex(GetLoadOrderFormID(CurrentFemaleArma),8));
				SetEditValue(ElementByIndex(ElementByPath(CurrentOrcMale, 'Armature'), 1), IntToHex(GetLoadOrderFormID(CurrentMaleArma),8));
			end;
			if pos('KhajiitRace', getRaces(CurrentArma)) > 0 then
			begin
				for a := ElementCount(ElementByPath(CurrentKhajiitFemale, 'Armature')) - 1 downto 1 do
				begin
					remove(ElementByIndex(ElementByPath(CurrentKhajiitFemale, 'Armature'), a));
				end;
				for a := ElementCount(ElementByPath(CurrentKhajiitMale, 'Armature')) - 1 downto 1 do
				begin
					remove(ElementByIndex(ElementByPath(CurrentKhajiitMale, 'Armature'), a));
				end;
				SetEditValue(ElementByIndex(ElementByPath(CurrentKhajiitFemale, 'Armature'), 1), IntToHex(GetLoadOrderFormID(CurrentFemaleArma),8));
				SetEditValue(ElementByIndex(ElementByPath(CurrentKhajiitMale, 'Armature'), 1), IntToHex(GetLoadOrderFormID(CurrentMaleArma),8));
			end;
			if pos('ArgonianRace', getRaces(CurrentArma)) > 0 then
			begin
				for a := ElementCount(ElementByPath(CurrentArgonianFemale, 'Armature')) - 1 downto 1 do
				begin
					remove(ElementByIndex(ElementByPath(CurrentArgonianFemale, 'Armature'), a));
				end;
				for a := ElementCount(ElementByPath(CurrentArgonianMale, 'Armature')) - 1 downto 1 do
				begin
					remove(ElementByIndex(ElementByPath(CurrentArgonianMale, 'Armature'), a));
				end;
				SetEditValue(ElementByIndex(ElementByPath(CurrentArgonianFemale, 'Armature'), 1), IntToHex(GetLoadOrderFormID(CurrentFemaleArma),8));
				SetEditValue(ElementByIndex(ElementByPath(CurrentArgonianMale, 'Armature'), 1), IntToHex(GetLoadOrderFormID(CurrentMaleArma),8));
			end;
			
		end;
		
		
		LVLIAll := AddLVLIALL(CurrentArgonianFemale, CurrentArgonianMale, CurrentFemale, CurrentKhajiitFemale, CurrentKhajiitMale, CurrentMale, CurrentOrcFemale, CurrentOrcMale, Currentmale);
		
		TempList := TStringList.Create;
		TempList.AddObject(EditorID(CurrentRecord), CurrentRecord);
		TempList.AddObject(EditorID(CurrentFemale), CurrentFemale);
		TempList.AddObject(EditorID(CurrentMale), CurrentMale);
		TempList.AddObject(EditorID(CurrentArgonianFemale), CurrentArgonianFemale);
		TempList.AddObject(EditorID(CurrentKhajiitFemale), CurrentKhajiitFemale);
		TempList.AddObject(EditorID(CurrentArgonianMale), CurrentArgonianMale);
		TempList.AddObject(EditorID(CurrentKhajiitMale), CurrentKhajiitMale);
		TempList.AddObject(EditorID(CurrentOrcFemale), CurrentOrcFemale);
		TempList.AddObject(EditorID(CurrentOrcMale), CurrentOrcMale);
		
		TempList.AddObject(EditorID(LVLIAll), LVLIAll);
		ArmoListList.AddObject(EditorID(CurrentRecord), Templist);
	end;
end;

function getRaces(arma: IInterface): string;
var
	CurrentEDID: String;
	AdditionalRaces: IInterface;
	i: integer;
begin
	AdditionalRaces := ElementByPath(arma, 'Additional Races');
	for i := elementCount(AdditionalRaces) - 1 downto 0 do
	begin
		CurrentEDID := EditorID(linksto(elementByIndex(AdditionalRaces, i)));
		if CurrentEDID = 'OrcRace' then result := 'OrcRace'
		else if CurrentEDID = 'OrcRaceVampire' then result := 'OrcRace'
		else if CurrentEDID = 'KhajiitRace' then result := 'KhajiitRace'
		else if CurrentEDID = 'KhajiitRaceVampire' then result := 'KhajiitRace'
		else if CurrentEDID = 'ArgonianRace' then result := 'ArgonianRace'
		else if CurrentEDID = 'ArgonianRaceVampire' then result := 'ArgonianRace'
		else result := 'Human';
	end;
end;

Procedure LVLIHandler;
begin
	GatherLVLI;
	CopierLVLI;
	AddMessage('LVLI');
end;

procedure GatherLVLI;
var
	LVLIPlugins: TStringList;
	k, i, j: integer;
	CurrentGroup, CurrentRecord, lvlo, ref, entries: IInterface;
	ContainsArmo: boolean;
begin
	LVLIPlugins := TStringList.Create;
	for i := filecount - 1 downto 0 do
	begin
		if hasGroup(fileByIndex(i), 'LVLI') then
		LVLIPlugins.addObject(GetfileName(FileByIndex(i)), FileByIndex(i)); 
	end;
	LVLIList := TStringList.Create;
	for i := LVLIPlugins.Count - 1 downto 0 do
	begin
		CurrentGroup := GroupBySignature(ObjectToElement(LVLIPlugins.objects[i]), 'LVLI');
		for j := ElementCount(CurrentGroup) - 1 downto 0 do
		begin
			ContainsArmo := false;
			CurrentRecord := ElementByIndex(CurrentGroup, j);
			if GetIsDeleted(CurrentRecord) then continue;
			entries := ElementByName(CurrentRecord, 'Leveled List Entries');
			for k := 0 to Pred(ElementCount(entries)) do
			begin
				lvlo := ElementByPath(entries, '[' + IntToStr(i) + ']\LVLO');
				ref := ElementByName(lvlo, 'Reference');
				if Signature(LinksTo(ref)) = 'ARMO' then ContainsArmo := true;
			end;
			if ContainsArmo = false then continue;
			if ISWinningOverride(CurrentRecord) then LVLIList.AddObject(EditorID(CurrentRecord), CurrentRecord);
		end;
	end;
end;

procedure CopierLVLI;
var
	i, j, a,k: integer;
	LVLIAll, NewItem: IInterface;
	CurrentArgonianFemale, CurrentArgonianMale, CurrentArma, CurrentFemale, CurrentFemaleArma, CurrentGroup, CurrentKhajiitFemale, CurrentKhajiitMale, CurrentOrcFemale, CurrentOrcMale, CurrentRecord, Currentmale, CurrentmaleArma: IInterface;
	cfa, cafa, cma, cama, ckfa, ckma, coma, cofa: IInterface;
	TempList: TStringList;
	Item, Items, entries, ref, lvlo, CurrenGroup: IInterface;
begin
	LVLIListList := TStringList.Create;
	for i := LVLIList.Count - 1 downto 0 do
	begin
		CurrentRecord := wbCopyElementToFile(ObjectToElement(LVLIList.Objects[i]), Patch, false, true);
		CurrentFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentArgonianFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentArgonianMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentKhajiitFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentKhajiitMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentOrcFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentOrcMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		SetEditorID(CurrentFemale, EditorID(CurrentRecord) + 'FemaleMer');
		SetEditorID(CurrentMale, EditorID(CurrentRecord) + 'MaleMer');
		SetEditorID(CurrentArgonianFemale, EditorID(CurrentRecord) + 'FemaleArgonian');
		SetEditorID(CurrentArgonianMale, EditorID(CurrentRecord) + 'maleArgonian');
		SetEditorID(CurrentKhajiitFemale, EditorID(CurrentRecord) + 'FemaleKhajiit');
		SetEditorID(CurrentKhajiitMale, EditorID(CurrentRecord) + 'maleKhajiit');
		SetEditorID(CurrentOrcFemale, EditorID(CurrentRecord) + 'FemaleOrc');
		SetEditorID(CurrentOrcMale, EditorID(CurrentRecord) + 'maleOrc');
		
		entries := ElementByName(CurrentRecord, 'Leveled List Entries');
		for k := 0 to Pred(ElementCount(entries)) do
		begin
			lvlo := ElementByPath(entries, '[' + IntToStr(k) + ']\LVLO');
			ref := ElementByName(lvlo, 'Reference');
			if Signature(LinksTo(ref)) = 'ARMO' then 
			begin
				templist := ArmoListList.Objects[ArmoListList.IndexOf(EditorID(LinksTo(ref)))];
				for a := templist.count - 1 downto 0 do
				begin
					if pos(templist.strings[a], 'FemaleArgonian') > 0 then cafa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'FemaleKhajiit') > 0 then ckfa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleArgonian') > 0 then cama := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleKhajiit') > 0 then ckma := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'FemaleOrc') > 0 then cofa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleOrc') > 0 then coma := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'Female') > 0 then cfa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'male') > 0 then cma := ObjectToElement(templist.objects[a]);
				end;
				SetElementEditValues(CurrentFemale, 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(cfa),8));
				SetElementEditValues(CurrentMale, 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(cma),8));
				SetElementEditValues(CurrentArgonianFemale, 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(cafa),8));
				SetElementEditValues(CurrentKhajiitFemale, 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(ckfa),8));
				SetElementEditValues(CurrentArgonianMale, 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(cama),8));
				SetElementEditValues(CurrentKhajiitMale, 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(ckma),8));
				SetElementEditValues(CurrentOrcFemale, 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(cofa),8));
				SetElementEditValues(CurrentOrcMale, 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(coma),8));
			end;
		end;
		LVLIAll := AddLVLIALL(CurrentArgonianFemale, CurrentArgonianMale, CurrentFemale, CurrentKhajiitFemale, CurrentKhajiitMale, CurrentMale, CurrentOrcFemale, CurrentOrcMale, Currentmale);
		
		TempList := TStringList.Create;
		TempList.AddObject(EditorID(CurrentRecord), CurrentRecord);
		TempList.AddObject(EditorID(CurrentFemale), CurrentFemale);
		TempList.AddObject(EditorID(CurrentMale), CurrentMale);
		TempList.AddObject(EditorID(CurrentArgonianFemale), CurrentArgonianFemale);
		TempList.AddObject(EditorID(CurrentKhajiitFemale), CurrentKhajiitFemale);
		TempList.AddObject(EditorID(CurrentArgonianMale), CurrentArgonianMale);
		TempList.AddObject(EditorID(CurrentKhajiitMale), CurrentKhajiitMale);
		TempList.AddObject(EditorID(CurrentOrcFemale), CurrentOrcFemale);
		TempList.AddObject(EditorID(CurrentOrcMale), CurrentOrcMale);
		
		TempList.AddObject(EditorID(LVLIAll), LVLIAll);
		LVLIListList.AddObject(EditorID(CurrentRecord), Templist);
	end;
end;

function AddLVLIALL(a,b,c,d,e,f,g,h: IInterface): IInterface;
begin
	LVLIAll := CreateRecord('LVLI');
	SetEditorID(LVLIAll, EditorID(CurrentRecord) + 'LVLIAll');
	ElementAssign(LVLIAll, HighInteger, nil, false);
	
	NewItem := ElementAssign(ElementByPath(LVLIAll, 'Leveled List Entries'), HighInteger, nil, false);
	NewItem := ElementAssign(ElementByPath(NewItem, 'Leveled List Entry'), HighInteger, nil, false);
	AddLVLIItem(a);
	AddLVLIItem(b);
	AddLVLIItem(c);
	AddLVLIItem(d);
	AddLVLIItem(e);
	AddLVLIItem(f);
	AddLVLIItem(g);
	AddLVLIItem(h);
	
end;

Procedure COBJHandler;
begin
	GatherCOBJ;
	CopierCOBJ;
	AddMessage('COBJ');
	COBJList.free;
	COBJListList.free;
end;

procedure GatherCOBJ;
var
	COBJPlugins: TStringList;
	k, i, j: integer;
	ContainsArmo: Boolean;
	CurrentGroup, CurrentRecord, lvlo, ref, entries, Item, Items: IInterface;
begin
	COBJPlugins := TStringList.Create;
	for i := filecount - 1 downto 0 do
	begin
		if hasGroup(fileByIndex(i), 'LVLI') then
		COBJPlugins.addObject(GetfileName(FileByIndex(i)), FileByIndex(i)); 
	end;
	COBJList := TStringList.Create;
	for i := COBJPlugins.Count - 1 downto 0 do
	begin
		CurrentGroup := GroupBySignature(ObjectToElement(COBJPlugins.objects[i]), 'LVLI');
		for j := ElementCount(CurrentGroup) - 1 downto 0 do
		begin
			ContainsArmo := false;
			CurrentRecord := ElementByIndex(CurrentGroup, j);
			if GetIsDeleted(CurrentRecord) then continue;
			if not pos(Signature(LinksTo(ElementByPath(CurrentRecord, 'CNAM'))), 'ARMO') > 0 then continue;
			if ISWinningOverride(CurrentRecord) then COBJList.AddObject(EditorID(CurrentRecord), CurrentRecord);
		end;
	end;
end;

procedure CopierCOBJ;
var
	i, j, a, k: integer;
	TempList: TStringList;
	CurrentArgonianFemale, CurrentArgonianMale, CurrentArma, CurrentFemale, CurrentFemaleArma, CurrentGroup, CurrentKhajiitFemale, CurrentKhajiitMale, CurrentOrcFemale, CurrentOrcMale, CurrentRecord, Currentmale, CurrentmaleArma: IInterface;
	cfa, cafa, cma, cama, ckfa, ckma, coma, cofa: IInterface;
	LVLIAll, NewItem: IInterface;
	Item, Items, entries, ref, lvlo, CurrenGroup: IInterface;
begin
	COBJListList := TStringList.Create;
	for i := COBJList.Count - 1 downto 0 do
	begin
		CurrentRecord := wbCopyElementToFile(ObjectToElement(COBJList.Objects[i]), Patch, false, true);
		if ArmoListList.IndexOf(EditorID(LinksTo(ElementByPath(CurrentRecord, 'CNAM')))) < 0 then continue;
		CurrentFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentArgonianFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentArgonianMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentKhajiitFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentKhajiitMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentOrcFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentOrcMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		SetEditorID(CurrentFemale, EditorID(CurrentRecord) + 'FemaleMer');
		SetEditorID(CurrentMale, EditorID(CurrentRecord) + 'MaleMer');
		SetEditorID(CurrentArgonianFemale, EditorID(CurrentRecord) + 'FemaleArgonian');
		SetEditorID(CurrentArgonianMale, EditorID(CurrentRecord) + 'maleArgonian');
		SetEditorID(CurrentKhajiitFemale, EditorID(CurrentRecord) + 'FemaleKhajiit');
		SetEditorID(CurrentKhajiitMale, EditorID(CurrentRecord) + 'maleKhajiit');
		SetEditorID(CurrentOrcFemale, EditorID(CurrentRecord) + 'FemaleOrc');
		SetEditorID(CurrentOrcMale, EditorID(CurrentRecord) + 'maleOrc');
		templist := ArmoListList.Objects[ArmoListList.IndexOf(EditorID(LinksTo(ElementByPath(CurrentRecord, 'CNAM'))))];
		for a := templist.count - 1 downto 0 do
		begin
			if pos(templist.strings[a], 'FemaleArgonian') > 0 then cafa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'FemaleKhajiit') > 0 then ckfa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleArgonian') > 0 then cama := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleKhajiit') > 0 then ckma := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'FemaleOrc') > 0 then cofa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleOrc') > 0 then coma := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'Female') > 0 then cfa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'male') > 0 then cma := ObjectToElement(templist.objects[a]);
		end;
		SetEditValue(ElementByPath(CurrentFemale, 'CNAM'), IntToHex(GetLoadOrderFormID(cfa),8));
		SetEditValue(ElementByPath(CurrentMale, 'CNAM'), IntToHex(GetLoadOrderFormID(cma),8));
		SetEditValue(ElementByPath(CurrentArgonianFemale, 'CNAM'), IntToHex(GetLoadOrderFormID(cafa),8));
		SetEditValue(ElementByPath(CurrentKhajiitFemale, 'CNAM'), IntToHex(GetLoadOrderFormID(ckfa),8));
		SetEditValue(ElementByPath(CurrentArgonianMale, 'CNAM'), IntToHex(GetLoadOrderFormID(cama),8));
		SetEditValue(ElementByPath(CurrentKhajiitMale, 'CNAM'), IntToHex(GetLoadOrderFormID(ckma),8));
		SetEditValue(ElementByPath(CurrentOrcFemale, 'CNAM'), IntToHex(GetLoadOrderFormID(cofa),8));
		SetEditValue(ElementByPath(CurrentOrcMale, 'CNAM'), IntToHex(GetLoadOrderFormID(coma),8));
		SetIsDeleted(CurrentRecord, true);
	end;
end;

Procedure OTFTHandler;
begin
	GatherOTFT;
	CopierOTFT;
	AddMessage('OTFT');
end;

procedure GatherOTFT;
var
	OTFTPlugins: TStringList;
	k, i, j: integer;
	CurrentGroup, CurrentRecord, lvlo, ref: IInterface;
	ContainsArmo: boolean;
begin
	OTFTPlugins := TStringList.Create;
	for i := filecount - 1 downto 0 do
	begin
		if hasGroup(fileByIndex(i), 'OTFT') then
		OTFTPlugins.addObject(GetfileName(FileByIndex(i)), FileByIndex(i)); 
	end;
	OTFTList := TStringList.Create;
	for i := OTFTPlugins.Count - 1 downto 0 do
	begin
		CurrentGroup := GroupBySignature(ObjectToElement(OTFTPlugins.objects[i]), 'OTFT');
		for j := ElementCount(CurrentGroup) - 1 downto 0 do
		begin
			ContainsArmo := false;
			CurrentRecord := ElementByIndex(CurrentGroup, j);
			if GetIsDeleted(CurrentRecord) then continue;
			if ISWinningOverride(CurrentRecord) then OTFTList.AddObject(EditorID(CurrentRecord), CurrentRecord);
		end;
	end;
end;

procedure CopierOTFT;
var
	i, j, a, k: integer;
	LVLIAll, NewItem: IInterface;
	lvlo, ref: IInterface;
	NPC_ainsArmo: boolean;
	TempList: TStringList;
	CurrentArgonianFemale, CurrentArgonianMale, CurrentArma, CurrentFemale, CurrentFemaleArma, CurrentGroup, CurrentKhajiitFemale, CurrentKhajiitMale, CurrentOrcFemale, CurrentOrcMale, CurrentRecord, Currentmale, CurrentmaleArma: IInterface;
	cfa, cafa, cma, cama, ckfa, ckma, coma, cofa, Items, Item: IInterface;
begin
	OTFTListList := TStringList.Create;
	for i := OTFTList.Count - 1 downto 0 do
	begin
		CurrentRecord := wbCopyElementToFile(ObjectToElement(OTFTList.Objects[i]), Patch, false, true);
		CurrentFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentArgonianFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentArgonianMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentKhajiitFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentKhajiitMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentOrcFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentOrcMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		SetEditorID(CurrentFemale, EditorID(CurrentRecord) + 'FemaleMer');
		SetEditorID(CurrentMale, EditorID(CurrentRecord) + 'MaleMer');
		SetEditorID(CurrentArgonianFemale, EditorID(CurrentRecord) + 'FemaleArgonian');
		SetEditorID(CurrentArgonianMale, EditorID(CurrentRecord) + 'maleArgonian');
		SetEditorID(CurrentKhajiitFemale, EditorID(CurrentRecord) + 'FemaleKhajiit');
		SetEditorID(CurrentKhajiitMale, EditorID(CurrentRecord) + 'maleKhajiit');
		SetEditorID(CurrentOrcFemale, EditorID(CurrentRecord) + 'FemaleOrc');
		SetEditorID(CurrentOrcMale, EditorID(CurrentRecord) + 'maleOrc');
		
		Items := ElementByName(CurrentRecord, 'INAM');
		for k := 0 to Pred(ElementCount(Items)) do
		begin
			Item := ElementByIndex(Items, k);
			if Signature(LinksTo(Item)) = 'ARMO' then 
			begin
				if ArmoListList.IndexOf(EditorID(LinksTo(ref))) < 0 then continue;
				templist := ArmoListList.Objects[ArmoListList.IndexOf(EditorID(LinksTo(ref)))];
				for a := templist.count - 1 downto 0 do
				begin
					if pos(templist.strings[a], 'FemaleArgonian') > 0 then cafa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'FemaleKhajiit') > 0 then ckfa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleArgonian') > 0 then cama := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleKhajiit') > 0 then ckma := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'FemaleOrc') > 0 then cofa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleOrc') > 0 then coma := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'Female') > 0 then cfa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'male') > 0 then cma := ObjectToElement(templist.objects[a]);
				end;
				SetEditValue(ElementByIndex(ElementByName(CurrentFemale, 'INAM'), k), IntToHex(GetLoadOrderFormID(cfa),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentMale, 'INAM'), k), IntToHex(GetLoadOrderFormID(cma),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentArgonianFemale, 'INAM'), k), IntToHex(GetLoadOrderFormID(cafa),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentKhajiitFemale, 'INAM'), k), IntToHex(GetLoadOrderFormID(ckfa),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentArgonianMale, 'INAM'), k), IntToHex(GetLoadOrderFormID(cama),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentKhajiitMale, 'INAM'), k), IntToHex(GetLoadOrderFormID(ckma),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentOrcFemale, 'INAM'), k), IntToHex(GetLoadOrderFormID(cofa),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentOrcMale, 'INAM'), k), IntToHex(GetLoadOrderFormID(coma),8));
			end else if Signature(LinksTo(Item)) = 'LVLI' then
			begin
				if LVLIListList.IndexOf(EditorID(LinksTo(ref))) < 0 then continue;
				templist := LVLIListList.Objects[LVLIListList.IndexOf(EditorID(LinksTo(ref)))];
				for a := templist.count - 1 downto 0 do
				begin
					if pos(templist.strings[a], 'FemaleArgonian') > 0 then cafa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'FemaleKhajiit') > 0 then ckfa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleArgonian') > 0 then cama := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleKhajiit') > 0 then ckma := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'FemaleOrc') > 0 then cofa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleOrc') > 0 then coma := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'Female') > 0 then cfa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'male') > 0 then cma := ObjectToElement(templist.objects[a]);
				end;
				SetEditValue(ElementByIndex(ElementByName(CurrentFemale, 'INAM'), k), IntToHex(GetLoadOrderFormID(cfa),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentMale, 'INAM'), k), IntToHex(GetLoadOrderFormID(cma),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentArgonianFemale, 'INAM'), k), IntToHex(GetLoadOrderFormID(cafa),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentKhajiitFemale, 'INAM'), k), IntToHex(GetLoadOrderFormID(ckfa),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentArgonianMale, 'INAM'), k), IntToHex(GetLoadOrderFormID(cama),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentKhajiitMale, 'INAM'), k), IntToHex(GetLoadOrderFormID(ckma),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentOrcFemale, 'INAM'), k), IntToHex(GetLoadOrderFormID(cofa),8));
				SetEditValue(ElementByIndex(ElementByName(CurrentOrcMale, 'INAM'), k), IntToHex(GetLoadOrderFormID(coma),8));
			end;
		end;
		
	end;
end;

Procedure CONTHandler;
begin
	GatherCONT;
	CopierCONT;
	AddMessage('CONT');
	CONTList.Free;
	CONTListList.Free;
end;

procedure GatherCONT;
var
	CONTPlugins: TStringList;
	k, i, j: integer;
	CurrentGroup, CurrentRecord, lvlo, ref, Items, Item: IInterface;
	ContainsArmo: boolean;
begin
	CONTPlugins := TStringList.Create;
	for i := filecount - 1 downto 0 do
	begin
		if hasGroup(fileByIndex(i), 'CONT') then
		CONTPlugins.addObject(GetfileName(FileByIndex(i)), FileByIndex(i)); 
	end;
	CONTList := TStringList.Create;
	for i := CONTPlugins.Count - 1 downto 0 do
	begin
		CurrentGroup := GroupBySignature(ObjectToElement(CONTPlugins.objects[i]), 'CONT');
		for j := ElementCount(CurrentGroup) - 1 downto 0 do
		begin
			ContainsArmo := false;
			CurrentRecord := ElementByIndex(CurrentGroup, j);
			Items:= ElementByName(CurrentRecord, 'Items');
			for k := 0 to Pred(ElementCount(Items)) do
			begin
				Item := ElementByIndex(Items, i);
				ref := ElementByName(Item, 'CNTO\Item');
				if Signature(LinksTo(ref)) = 'ARMO' then ContainsArmo := true;
				if Signature(LinksTo(ref)) = 'OTFT' then ContainsArmo := true;
				if Signature(LinksTo(ref)) = 'LVLI' then ContainsArmo := true;
			end;
			if ContainsArmo = false then continue;
			if GetIsDeleted(CurrentRecord) then continue;
			if ISWinningOverride(CurrentRecord) then CONTList.AddObject(EditorID(CurrentRecord), CurrentRecord);
		end;
	end;
end;

procedure CopierCONT;
var
	i, j, a, k: integer;
	lvlo, ref: IInterface;
	NPC_ainsArmo: boolean;
	TempList: TStringList;
	CurrentArgonianFemale, CurrentArgonianMale, CurrentArma, CurrentFemale, CurrentFemaleArma, CurrentGroup, CurrentKhajiitFemale, CurrentKhajiitMale, CurrentOrcFemale, CurrentOrcMale, CurrentRecord, Currentmale, CurrentmaleArma: IInterface;
	cfa, cafa, cma, cama, ckfa, ckma, coma, cofa, Items, Item: IInterface;
begin
	CONTListList := TStringList.Create;
	for i := CONTList.Count - 1 downto 0 do
	begin
		CurrentRecord := wbCopyElementToFile(ObjectToElement(CONTList.Objects[i]), Patch, false, true);
		CurrentFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentArgonianFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentArgonianMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentKhajiitFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentKhajiitMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentOrcFemale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		CurrentOrcMale := wbCopyElementToFile(CurrentRecord, Patch, true, true);
		SetEditorID(CurrentFemale, EditorID(CurrentRecord) + 'FemaleMer');
		SetEditorID(CurrentMale, EditorID(CurrentRecord) + 'MaleMer');
		SetEditorID(CurrentArgonianFemale, EditorID(CurrentRecord) + 'FemaleArgonian');
		SetEditorID(CurrentArgonianMale, EditorID(CurrentRecord) + 'maleArgonian');
		SetEditorID(CurrentKhajiitFemale, EditorID(CurrentRecord) + 'FemaleKhajiit');
		SetEditorID(CurrentKhajiitMale, EditorID(CurrentRecord) + 'maleKhajiit');
		SetEditorID(CurrentOrcFemale, EditorID(CurrentRecord) + 'FemaleOrc');
		SetEditorID(CurrentOrcMale, EditorID(CurrentRecord) + 'maleOrc');
		
		Items := ElementByName(CurrentRecord, 'Items');
		for k := 0 to Pred(ElementCount(Items)) do
		begin
			Item := ElementByPath(ElementByIndex(Items, k), 'CNTO\Item');
			if Signature(LinksTo(Item)) = 'ARMO' then 
			begin
				if ArmoListList.IndexOf(EditorID(LinksTo(ref))) < 0 then continue;
				templist := ArmoListList.Objects[ArmoListList.IndexOf(EditorID(LinksTo(ref)))];
				for a := templist.count - 1 downto 0 do
				begin
					if pos(templist.strings[i], 'LVLIAll') > 0 then cfa := ObjectToElement(templist.objects[i]);
				end;
				SetEditValue(ElementByIndex(ElementByName(CurrentFemale, 'INAM'), k), IntToHex(GetLoadOrderFormID(cfa),8));
			end else if Signature(LinksTo(Item)) = 'LVLI' then
			begin
				if LVLIListList.IndexOf(EditorID(LinksTo(ref))) < 0 then continue;
				templist := LVLIListList.Objects[LVLIListList.IndexOf(EditorID(LinksTo(ref)))];
				for a := templist.count - 1 downto 0 do
				begin
					else if pos(templist.strings[i], 'LVLI') > 0 then cfa := ObjectToElement(ObjectToElement(templist.objects[i]));
				end;
				SetEditValue(ElementByIndex(ElementByName(CurrentFemale, 'INAM'), k), IntToHex(GetLoadOrderFormID(cfa),8));
			end;
		end;
	end;
	AddMessage('CONT');
end;


Procedure NPC_Handler;
begin
	GatherNPC_;
	CopierNPC_;
	AddMessage('NPC_');
	NPC_List.free;
	NPC_ListList.free;
end;

procedure GatherNPC_;
var
	NPC_Plugins: TStringList;
	k, i, j: integer;
	CurrentGroup, CurrentRecord, lvlo, ref: IInterface;
	NPC_ainsArmo: boolean;
begin
	NPC_Plugins := TStringList.Create;
	for i := filecount - 1 downto 0 do
	begin
		if hasGroup(fileByIndex(i), 'NPC_') then
		NPC_Plugins.addObject(GetfileName(FileByIndex(i)), FileByIndex(i)); 
	end;
	NPC_List := TStringList.Create;
	NPC_List := TStringList.Create;
	for i := NPC_Plugins.Count - 1 downto 0 do
	begin
		CurrentGroup := GroupBySignature(ObjectToElement(NPC_Plugins.objects[i]), 'NPC_');
		for j := ElementCount(CurrentGroup) - 1 downto 0 do
		begin
			NPC_ainsArmo := false;
			CurrentRecord := ElementByIndex(CurrentGroup, j);
			if GetIsDeleted(CurrentRecord) then continue;
			if ISWinningOverride(CurrentRecord) then NPC_List.AddObject(EditorID(CurrentRecord), CurrentRecord);
		end;
	end;
end;

procedure CopierNPC_;
var
	i, j, k, a: integer;
	lvlo, ref: IInterface;
	Gender, NPC_ainsArmo: boolean;
	TempList: TStringList;
	Race: string;
	CurrentArgonianFemale, CurrentArgonianMale, CurrentArma, CurrentFemale, CurrentFemaleArma, CurrentGroup, CurrentKhajiitFemale, CurrentKhajiitMale, CurrentOrcFemale, CurrentOrcMale, CurrentRecord, Currentmale, CurrentmaleArma: IInterface;
	cfa, cafa, cma, cama, ckfa, ckma, coma, cofa, Item, Items: IInterface;
begin
	NPC_ListList := TStringList.Create;
	for i := NPC_List.Count - 1 downto 0 do
	begin
		CurrentRecord := wbCopyElementToFile(ObjectToElement(NPC_List.Objects[i]), Patch, false, true);
		if Assigned(ElementByPath(CurrentRecord, 'ACBS\Flags\Female')) then Gender := true //true is female, false is male to simplify
		else Gender := false;
		if pos(GetElementEditValues(CurrentRecord, 'RNAM'), 'Imperial') > 0 then Race := 'Mer'
		else if pos(GetElementEditValues(CurrentRecord, 'RNAM'), 'Breton') > 0 then Race := 'Mer'
		else if pos(GetElementEditValues(CurrentRecord, 'RNAM'), 'Elf') > 0 then Race := 'Mer'
		else if pos(GetElementEditValues(CurrentRecord, 'RNAM'), 'Nord') > 0 then Race := 'Mer'
		else if pos(GetElementEditValues(CurrentRecord, 'RNAM'), 'Khajiit') > 0 then Race := 'Khajiit'
		else if pos(GetElementEditValues(CurrentRecord, 'RNAM'), 'Argonian') > 0 then Race := 'Argonian'
		else if pos(GetElementEditValues(CurrentRecord, 'RNAM'), 'Orc') > 0 then Race := 'Orc'
		else Race := 'Mer';
		
		Items := ElementByName(CurrentRecord, 'Items');
		for k := 0 to Pred(ElementCount(Items)) do
		begin
			Item := ElementByPath(ElementByIndex(Items, k), 'CNTO\Item');
			if Signature(LinksTo(Item)) = 'ARMO' then 
			begin
				if ArmoListList.IndexOf(EditorID(LinksTo(ref))) < 0 then continue;
				templist := ArmoListList.Objects[ArmoListList.IndexOf(EditorID(LinksTo(ref)))];
				for a := templist.count - 1 downto 0 do
				begin
					if pos(templist.strings[a], 'FemaleArgonian') > 0 then cafa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'FemaleKhajiit') > 0 then ckfa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleArgonian') > 0 then cama := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleKhajiit') > 0 then ckma := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'FemaleOrc') > 0 then cofa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleOrc') > 0 then coma := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'Female') > 0 then cfa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'male') > 0 then cma := ObjectToElement(templist.objects[a]);
				end;
				if Race = 'Khajiit' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(ckfa),8));
				if Race = 'Orc' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cofa),8));
				if Race = 'Mer' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cfa),8));
				if Race = 'Argonian' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cafa),8));
				if Race = 'Khajiit' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(ckma),8));
				if Race = 'Orc' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(coma),8));
				if Race = 'Mer' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cma),8));
				if Race = 'Argonian' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cama),8));
				
			end else if Signature(LinksTo(Item)) = 'LVLI' then
			begin
				if LVLIListList.IndexOf(EditorID(LinksTo(ref))) < 0 then continue;
				templist := LVLIListList.Objects[LVLIListList.IndexOf(EditorID(LinksTo(ref)))];
				for a := templist.count - 1 downto 0 do
				begin
					if pos(templist.strings[a], 'FemaleArgonian') > 0 then cafa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'FemaleKhajiit') > 0 then ckfa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleArgonian') > 0 then cama := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleKhajiit') > 0 then ckma := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'FemaleOrc') > 0 then cofa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleOrc') > 0 then coma := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'Female') > 0 then cfa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'male') > 0 then cma := ObjectToElement(templist.objects[a]);
				end;
				if Race = 'Khajiit' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(ckfa),8));
				if Race = 'Orc' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cofa),8));
				if Race = 'Mer' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cfa),8));
				if Race = 'Argonian' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cafa),8));
				if Race = 'Khajiit' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(ckma),8));
				if Race = 'Orc' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(coma),8));
				if Race = 'Mer' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cma),8));
				if Race = 'Argonian' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cama),8));
				
			end else if Signature(LinksTo(Item)) = 'OTFT' then
			begin
				if OTFTListList.IndexOf(EditorID(LinksTo(ref))) < 0 then continue;
				templist := OTFTListList.Objects[OTFTListList.IndexOf(EditorID(LinksTo(ref)))];
				for a := templist.count - 1 downto 0 do
				begin
					if pos(templist.strings[a], 'FemaleArgonian') > 0 then cafa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'FemaleKhajiit') > 0 then ckfa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleArgonian') > 0 then cama := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleKhajiit') > 0 then ckma := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'FemaleOrc') > 0 then cofa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'maleOrc') > 0 then coma := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'Female') > 0 then cfa := ObjectToElement(templist.objects[a])
					else if pos(templist.strings[a], 'male') > 0 then cma := ObjectToElement(templist.objects[a]);
				end;
				if Race = 'Khajiit' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(ckfa),8));
				if Race = 'Orc' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cofa),8));
				if Race = 'Mer' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cfa),8));
				if Race = 'Argonian' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cafa),8));
				if Race = 'Khajiit' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(ckma),8));
				if Race = 'Orc' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(coma),8));
				if Race = 'Mer' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cma),8));
				if Race = 'Argonian' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(CurrentRecord, 'CNTO\Item'), k), IntToHex(GetLoadOrderFormID(cama),8));
			end;
		end;
		ref := ElementByPath(CurrentRecord, 'DOFT');
		if OTFTListList.IndexOf(EditorID(LinksTo(ref))) < 0 then continue;
		templist := OTFTListList.Objects[OTFTListList.IndexOf(EditorID(LinksTo(ref)))];
		for a := templist.count - 1 downto 0 do
		begin
			if pos(templist.strings[a], 'FemaleArgonian') > 0 then cafa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'FemaleKhajiit') > 0 then ckfa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleArgonian') > 0 then cama := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleKhajiit') > 0 then ckma := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'FemaleOrc') > 0 then cofa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleOrc') > 0 then coma := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'Female') > 0 then cfa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'male') > 0 then cma := ObjectToElement(templist.objects[a]);
		end;
		if Race = 'Khajiit' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(ckfa),8));
		if Race = 'Orc' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cofa),8));
		if Race = 'Mer' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cfa),8));
		if Race = 'Argonian' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cafa),8));
		if Race = 'Khajiit' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(ckma),8));
		if Race = 'Orc' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(coma),8));
		if Race = 'Mer' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cma),8));
		if Race = 'Argonian' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cama),8));
		
		ref := ElementByPath(CurrentRecord, 'SOFT');
		if OTFTListList.IndexOf(EditorID(LinksTo(ref))) < 0 then continue;
		templist := OTFTListList.Objects[OTFTListList.IndexOf(EditorID(LinksTo(ref)))];
		for a := templist.count - 1 downto 0 do
		begin
			if pos(templist.strings[a], 'FemaleArgonian') > 0 then cafa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'FemaleKhajiit') > 0 then ckfa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleArgonian') > 0 then cama := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleKhajiit') > 0 then ckma := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'FemaleOrc') > 0 then cofa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleOrc') > 0 then coma := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'Female') > 0 then cfa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'male') > 0 then cma := ObjectToElement(templist.objects[a]);
		end;
		if Race = 'Khajiit' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(ckfa),8));
		if Race = 'Orc' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cofa),8));
		if Race = 'Mer' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cfa),8));
		if Race = 'Argonian' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cafa),8));
		if Race = 'Khajiit' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(ckma),8));
		if Race = 'Orc' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(coma),8));
		if Race = 'Mer' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cma),8));
		if Race = 'Argonian' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cama),8));
		
		ref := ElementByPath(CurrentRecord, 'WNAM');
		if ArmoListList.IndexOf(EditorID(LinksTo(ref))) < 0 then continue;
		templist := ArmoListList.Objects[ArmoListList.IndexOf(EditorID(LinksTo(ref)))];
		for a := templist.count - 1 downto 0 do
		begin
			if pos(templist.strings[a], 'FemaleArgonian') > 0 then cafa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'FemaleKhajiit') > 0 then ckfa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleArgonian') > 0 then cama := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleKhajiit') > 0 then ckma := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'FemaleOrc') > 0 then cofa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleOrc') > 0 then coma := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'Female') > 0 then cfa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'male') > 0 then cma := ObjectToElement(templist.objects[a]);
		end;
		if Race = 'Khajiit' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(ckfa),8));
		if Race = 'Orc' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cofa),8));
		if Race = 'Mer' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cfa),8));
		if Race = 'Argonian' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cafa),8));
		if Race = 'Khajiit' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(ckma),8));
		if Race = 'Orc' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(coma),8));
		if Race = 'Mer' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cma),8));
		if Race = 'Argonian' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cama),8));
		
		ref := ElementByPath(CurrentRecord, 'INAM');
		if LVLIListList.IndexOf(EditorID(LinksTo(ref))) < 0 then continue;
		templist := LVLIListList.Objects[LVLIListList.IndexOf(EditorID(LinksTo(ref)))];
		for a := templist.count - 1 downto 0 do
		begin
			if pos(templist.strings[a], 'FemaleArgonian') > 0 then cafa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'FemaleKhajiit') > 0 then ckfa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleArgonian') > 0 then cama := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleKhajiit') > 0 then ckma := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'FemaleOrc') > 0 then cofa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'maleOrc') > 0 then coma := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'Female') > 0 then cfa := ObjectToElement(templist.objects[a])
			else if pos(templist.strings[a], 'male') > 0 then cma := ObjectToElement(templist.objects[a]);
		end;
		if Race = 'Khajiit' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(ckfa),8));
		if Race = 'Orc' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cofa),8));
		if Race = 'Mer' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cfa),8));
		if Race = 'Argonian' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cafa),8));
		if Race = 'Khajiit' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(ckma),8));
		if Race = 'Orc' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(coma),8));
		if Race = 'Mer' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cma),8));
		if Race = 'Argonian' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cama),8));
	end;
end;


procedure CleanDuplicates;
begin
	
end;

end.