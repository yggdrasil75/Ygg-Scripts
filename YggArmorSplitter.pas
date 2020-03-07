unit YGGArmorSplitter;

//Uses ArmorGooey;
Uses YggFunctions;

var
	Patch, itemRecord: IInterface;
	RaceList, ArmoList, LVLIList, COBJList, CONTList, NPC_List, LVLIListList, ArmoListList, OTFTList, OTFTListList: TStringList;

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
	CleanPlugin;
	remove(GroupBySignature(patch, 'ARMO'));
	remove(GroupBySignature(patch, 'ARMA'));
	remove(GroupBySignature(patch, 'NPC_'));
	remove(GroupBySignature(patch, 'COBJ'));
	remove(GroupBySignature(patch, 'OTFT'));
	remove(GroupBySignature(patch, 'LVLI'));
	remove(GroupBySignature(patch, 'CONT'));
	RaceList := TStringList.create;
	RaceList.DelimitedText := 'Male_Mer,Female_Mer,Male_Argonian,Female_Argonian,Male_Orc,Female_Orc,Male_Khajiit,Female_Khajiit';
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

procedure CleanPlugin;
var
	a: integer;
begin
	for a := 2 to elementCount(Patch) do 
	remove(ElementByIndex(Patch, a));
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
	i, j, a, foobar: integer;
	CurrentArma, CurrentGroup, CurrentRecord, TempRecord, CurrentMaleArma, CurrentFemaleArma: IInterface;
	LVLIAll, NewItem: IInterface;
	TempList: TStringList;
begin
	armoListList := TStringList.Create;
	for i := ArmoList.Count - 1 downto 0 do
	begin
		Templist := TStringlist.Create;
		CurrentRecord := wbCopyElementToFile(ObjectToElement(ArmoList.Objects[i]), Patch, false, true);
		
		for foobar := 0 to RaceList.Count - 1 do
		begin
			TempRecord := wbCopyElementToFile(CurrentRecord, Patch, true, true);
			SetEditorID(TempRecord, EditorID(CurrentRecord) + RaceList.Strings[foobar]);
			SetElementEditValues(TempRecord, 'Full - Name', GetElementEditValues(CurrentRecord, 'Full - Name') + ' ' + RaceList.Strings[foobar]);
			TempList.AddObject(EditorID(TempRecord), TempRecord);
			if odd(foobar) then SetElementEditValues(Templist.Objects[foobar], 'Male world model\MOD2', GetElementEditValues(Templist.objects[foobar], 'Female world model\MOD4'));
			if not odd(foobar) then SetElementEditValues(Templist.Objects[foobar], 'Female world model\MOD4', GetElementEditValues(Templist.objects[foobar], 'Male world model\MOD2'));
		end;
		
		for j := ElementCount(ElementByPath(CurrentRecord, 'Armature')) - 1 downto 0 do
		begin
			CurrentArma := WinningOverride(LinksTo(ElementByIndex(ElementByPath(CurrentRecord, 'Armature'), j)));
			
			CurrentFemaleArma := wbCopyElementToFile(CurrentArma, Patch, true, true);
			CurrentMaleArma := wbCopyElementToFile(CurrentArma, Patch, true, true);
			SetElementEditValues(CurrentFemaleArma, 'Male world model\MOD2', GetElementEditValues(CurrentFemaleArma, 'Female world model\MOD3'));
			SetElementEditValues(CurrentmaleArma, 'Female world model\MOD3', GetElementEditValues(CurrentmaleArma, 'Male world model\MOD2'));
			SetElementEditValues(CurrentFemaleArma, 'Male 1st Person\MOD4', GetElementEditValues(CurrentFemaleArma, 'Female 1st Person\MOD5'));
			SetElementEditValues(CurrentmaleArma, 'Female 1st Person\MOD5', GetElementEditValues(CurrentmaleArma, 'Male 1st Person\MOD4'));
			SetEditorID(CurrentFemaleArma, EditorID(CurrentArma) + 'Female');
			SetEditorID(CurrentMaleArma, EditorID(CurrentArma) + 'male');
			{
			for a := ElementCount(ElementByPath(CurrentRecord, 'Armature')) - 1 downto 1 do
			begin
				remove(ElementByIndex(ElementByPath(ObjectToElement(TempList.Objects[foobar]), 'Armature'), a));
			end;
			}
			GetRaces(CurrentArma, CurrentFemaleArma, CurrentMaleArma, TempList,j);
			
		end;
		
		
		LVLIAll := AddLVLIALL(TempList);
		
		TempList.AddObject(EditorID(LVLIAll), LVLIAll);
		ArmoListList.AddObject(EditorID(CurrentRecord), Templist);
	end;
end;

procedure getRaces(arma,CurrentFemaleArma,CurrentMaleArma: IInterface; out TempList: TStringList; j: integer);
var
	CurrentEDID: String;
	AdditionalRaces: IInterface;
	i: integer;
begin
	AdditionalRaces := ElementByPath(arma, 'Additional Races');
	for i := elementCount(AdditionalRaces) - 1 downto 0 do
	begin
		CurrentEDID := EditorID(linksto(elementByIndex(AdditionalRaces, i)));
		if ContainsText('Orc', CurrentEDID) then
		begin
			SetEditValue(ElementByIndex(ElementByPath(ObjectToElement(TempList.objects[4]), 'Armature'), j), IntToHex(GetLoadOrderFormID(CurrentMaleArma),8));
			SetEditValue(ElementByIndex(ElementByPath(ObjectToElement(TempList.objects[5]), 'Armature'), j), IntToHex(GetLoadOrderFormID(CurrentFemaleArma),8));
		end else if ContainsText('Khajiit', CurrentEDID) then 
		begin
			SetEditValue(ElementByIndex(ElementByPath(ObjectToElement(TempList.objects[6]), 'Armature'), j), IntToHex(GetLoadOrderFormID(CurrentMaleArma),8));
			SetEditValue(ElementByIndex(ElementByPath(ObjectToElement(TempList.objects[7]), 'Armature'), j), IntToHex(GetLoadOrderFormID(CurrentFemaleArma),8));
		end else if ContainsText('Argonian', CurrentEDID) then begin
			SetEditValue(ElementByIndex(ElementByPath(ObjectToElement(TempList.objects[2]), 'Armature'), j), IntToHex(GetLoadOrderFormID(CurrentMaleArma),8));
			SetEditValue(ElementByIndex(ElementByPath(ObjectToElement(TempList.objects[3]), 'Armature'), j), IntToHex(GetLoadOrderFormID(CurrentFemaleArma),8));
		end else
		begin
			SetEditValue(ElementByIndex(ElementByPath(ObjectToElement(TempList.objects[0]), 'Armature'), j), IntToHex(GetLoadOrderFormID(CurrentMaleArma),8));
			SetEditValue(ElementByIndex(ElementByPath(ObjectToElement(TempList.objects[1]), 'Armature'), j), IntToHex(GetLoadOrderFormID(CurrentFemaleArma),8));
		end;
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
	i, j, a,k,foobar: integer;
	LVLIAll, NewItem: IInterface;
	CurrentGroup, CurrentRecord, TempRecord: IInterface;
	cfa, cafa, cma, cama, ckfa, ckma, coma, cofa: IInterface;
	TempList: TStringList;
	Item, Items, entries, ref, lvlo, CurrenGroup: IInterface;
begin
	LVLIListList := TStringList.Create;
	for i := LVLIList.Count - 1 downto 0 do
	begin
		CurrentRecord := wbCopyElementToFile(ObjectToElement(LVLIList.Objects[i]), Patch, false, true);
		TempList := TStringList.Create;
		
		for foobar := 0 to RaceList.Count - 1 do
		begin
			TempRecord := wbCopyElementToFile(CurrentRecord, Patch, true, true);
			SetEditorID(TempRecord, EditorID(CurrentRecord) + RaceList.Strings[foobar]);
			SetElementEditValues(TempRecord, 'Full - Name', GetElementEditValues(CurrentRecord, 'Full - Name') + ' ' + RaceList.Strings[foobar]);
			TempList.AddObject(EditorID(TempRecord), TempRecord);
		end;
		
		entries := ElementByName(CurrentRecord, 'Leveled List Entries');
		for k := 0 to Pred(ElementCount(entries)) do
		begin
			lvlo := ElementByPath(entries, '[' + IntToStr(k) + ']\LVLO');
			ref := ElementByName(lvlo, 'Reference');
			
			if not GetStuff(ref,cafa,ckfa,cama,ckma,cofa,coma,cfa,cma, 'ARMO') then continue;
			SetElementEditValues(ObjectToElement(TempList.Objects[1]), 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(cfa),8));
			SetElementEditValues(ObjectToElement(TempList.Objects[0]), 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(cma),8));
			SetElementEditValues(ObjectToElement(TempList.Objects[3]), 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(cafa),8));
			SetElementEditValues(ObjectToElement(TempList.Objects[7]), 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(ckfa),8));
			SetElementEditValues(ObjectToElement(TempList.Objects[2]), 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(cama),8));
			SetElementEditValues(ObjectToElement(TempList.Objects[6]), 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(ckma),8));
			SetElementEditValues(ObjectToElement(TempList.Objects[5]), 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(cofa),8));
			SetElementEditValues(ObjectToElement(TempList.Objects[4]), 'Leveled List Entries\[' + IntToStr(k) + ']\LVLO', IntToHex(GetLoadOrderFormID(coma),8));
		end;
		
		LVLIAll := AddLVLIALL(TempList);
		
		TempList.AddObject(EditorID(LVLIAll), LVLIAll);
		LVLIListList.AddObject(EditorID(CurrentRecord), Templist);
	end;
end;

function AddLVLIALL(aTempList: TStringList): IInterface;
var
	LVLIAll, NewItem: IInterface;
	foobar: integer;
begin
	LVLIAll := CreateRecord('LVLI');
	SetEditorID(LVLIAll, EditorID(ObjectToElement(aTempList.Objects[0])) + 'LVLIAll');
	ElementAssign(LVLIAll, HighInteger, nil, false);
	
	NewItem := ElementAssign(ElementByPath(LVLIAll, 'Leveled List Entries'), HighInteger, nil, false);
	NewItem := ElementAssign(ElementByPath(NewItem, 'Leveled List Entry'), HighInteger, nil, false);
	for foobar := aTempList.count - 1 downto 0 do
	begin
	AddLVLIItem(LVLIAll, ObjectToElement(aTempList.objects[foobar]));
	end;
	result := LVLIAll;
end;

Procedure COBJHandler;
begin
	GatherCOBJ;
	CopierCOBJ;
	AddMessage('COBJ');
	COBJList.free;
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
	for i := COBJList.Count - 1 downto 0 do
	begin
		CurrentRecord := wbCopyElementToFile(ObjectToElement(COBJList.Objects[i]), Patch, false, true);
		if not GetStuff(LinksTo(ElementByPath(CurrentRecord, 'CNAM')),cafa,ckfa,cama,ckma,cofa,coma,cfa,cma, 'ARMO') then continue;
		
		for foobar := 0 to RaceList.Count - 1 do
		begin
			TempRecord := wbCopyElementToFile(CurrentRecord, Patch, true, true);
			SetEditorID(TempRecord, EditorID(CurrentRecord) + RaceList.Strings[foobar]);
			SetElementEditValues(TempRecord, 'Full - Name', GetElementEditValues(CurrentRecord, 'Full - Name') + ' ' + RaceList.Strings[foobar]);
			TempList.AddObject(EditorID(TempRecord), TempRecord);
			
		end;
		
		SetEditValue(ElementByPath(ObjectToElement(TempList.Objects[1]), 'CNAM'), IntToHex(GetLoadOrderFormID(cfa),8));
		SetEditValue(ElementByPath(ObjectToElement(TempList.Objects[0]), 'CNAM'), IntToHex(GetLoadOrderFormID(cma),8));
		SetEditValue(ElementByPath(ObjectToElement(TempList.Objects[3]), 'CNAM'), IntToHex(GetLoadOrderFormID(cafa),8));
		SetEditValue(ElementByPath(ObjectToElement(TempList.Objects[7]), 'CNAM'), IntToHex(GetLoadOrderFormID(ckfa),8));
		SetEditValue(ElementByPath(ObjectToElement(TempList.Objects[2]), 'CNAM'), IntToHex(GetLoadOrderFormID(cama),8));
		SetEditValue(ElementByPath(ObjectToElement(TempList.Objects[6]), 'CNAM'), IntToHex(GetLoadOrderFormID(ckma),8));
		SetEditValue(ElementByPath(ObjectToElement(TempList.Objects[5]), 'CNAM'), IntToHex(GetLoadOrderFormID(cofa),8));
		SetEditValue(ElementByPath(ObjectToElement(TempList.Objects[4]), 'CNAM'), IntToHex(GetLoadOrderFormID(coma),8));
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
				ReplaceDynamic(CurrentRecord, 'ARMO', 'INAM', k);
			end else if Signature(LinksTo(Item)) = 'LVLI' then
			begin
				ReplaceDynamic(CurrentRecord, 'LVLI', 'INAM', k);
			end;
		end;
		
	end;
end;

procedure ReplaceDynamic(ref: IInterface; sig, Path: string; loop:integer);
begin
	if not GetStuff(ref,cafa,ckfa,cama,ckma,cofa,coma,cfa,cma, sig) then exit;
	SetEditValue(ElementByIndex(ElementByName(CurrentFemale, path), loop), IntToHex(GetLoadOrderFormID(cfa),8));
	SetEditValue(ElementByIndex(ElementByName(CurrentMale, path), loop), IntToHex(GetLoadOrderFormID(cma),8));
	SetEditValue(ElementByIndex(ElementByName(CurrentArgonianFemale, path), loop), IntToHex(GetLoadOrderFormID(cafa),8));
	SetEditValue(ElementByIndex(ElementByName(CurrentKhajiitFemale, path), loop), IntToHex(GetLoadOrderFormID(ckfa),8));
	SetEditValue(ElementByIndex(ElementByName(CurrentArgonianMale, path), loop), IntToHex(GetLoadOrderFormID(cama),8));
	SetEditValue(ElementByIndex(ElementByName(CurrentKhajiitMale, path), loop), IntToHex(GetLoadOrderFormID(ckma),8));
	SetEditValue(ElementByIndex(ElementByName(CurrentOrcFemale, path), loop), IntToHex(GetLoadOrderFormID(cofa),8));
	SetEditValue(ElementByIndex(ElementByName(CurrentOrcMale, path), loop), IntToHex(GetLoadOrderFormID(coma),8));
end;

Procedure CONTHandler;
begin
	GatherCONT;
	CopierCONT;
	AddMessage('CONT');
	CONTList.Free;
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
	for i := CONTList.Count - 1 downto 0 do
	begin
		CurrentRecord := wbCopyElementToFile(ObjectToElement(CONTList.Objects[i]), Patch, false, true);
		
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
	for i := NPC_List.Count - 1 downto 0 do
	begin
		CurrentRecord := wbCopyElementToFile(ObjectToElement(NPC_List.Objects[i]), Patch, false, true);
		if Assigned(ElementByPath(CurrentRecord, 'ACBS\Flags\Female')) then Gender := true //true is female, false is male to simplify
		else Gender := false;
		if pos(GetElementEditValues(CurrentRecord, 'RNAM'), 'Khajiit') > 0 then Race := 'Khajiit'
		else if pos(GetElementEditValues(CurrentRecord, 'RNAM'), 'Argonian') > 0 then Race := 'Argonian'
		else if pos(GetElementEditValues(CurrentRecord, 'RNAM'), 'Orc') > 0 then Race := 'Orc'
		else Race := 'Mer';
		
		Items := ElementByName(CurrentRecord, 'Items');
		for k := 0 to Pred(ElementCount(Items)) do
		begin
			Item := ElementByPath(ElementByIndex(Items, k), 'CNTO\Item');
			if Signature(LinksTo(Item)) = 'ARMO' then 
			begin
				ReplaceDynamicNPC(CurrentRecord, 'ARMO', 'CNTO\Item', Race, k, Gender);
			end else if Signature(LinksTo(Item)) = 'LVLI' then
			begin
				ReplaceDynamicNPC(CurrentRecord, 'LVLI', 'CNTO\Item', Race, k, Gender);
			end else if Signature(LinksTo(Item)) = 'OTFT' then
			begin
				ReplaceDynamicNPC(CurrentRecord, 'OTFT', 'CNTO\Item', Race, k, Gender);
			end;
		end;
		ref := ElementByPath(CurrentRecord, 'DOFT');
		ReplaceFixed(ref, 'OTFT');
		ref := ElementByPath(CurrentRecord, 'SOFT');
		ReplaceFixed(ref, 'OTFT');
		ref := ElementByPath(CurrentRecord, 'WNAM');
		ReplaceFixed(ref, 'ARMO');
		ref := ElementByPath(CurrentRecord, 'INAM');
		ReplaceFixed(ref, 'LVLI');
	end;
end;

procedure ReplaceDynamicNPC(ref: IInterface; sig, Path, Race: String; loop: integer; gender: Boolean);
var
	a: integer
	cfa,cafa,cma,cama,ckfa,ckma,coma,cofa: IInterface;
begin
	if not GetStuff(ref,cafa,ckfa,cama,ckma,cofa,coma,cfa,cma, sig) then exit;
	if Race = 'Khajiit' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(ref, path), loop), IntToHex(GetLoadOrderFormID(ckfa),8));
	if Race = 'Orc' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(ref, path), loop), IntToHex(GetLoadOrderFormID(ckfa),8));
	if Race = 'Mer' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(ref, path), loop), IntToHex(GetLoadOrderFormID(ckfa),8));
	if Race = 'Argonian' AND Gender = true then SetEditValue(ElementByIndex(ElementByPath(ref, path), loop), IntToHex(GetLoadOrderFormID(ckfa),8));
	if Race = 'Khajiit' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(ref, path), loop), IntToHex(GetLoadOrderFormID(ckfa),8));
	if Race = 'Orc' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(ref, path), loop), IntToHex(GetLoadOrderFormID(ckfa),8));
	if Race = 'Mer' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(ref, path), loop), IntToHex(GetLoadOrderFormID(ckfa),8));
	if Race = 'Argonian' AND Gender = false then SetEditValue(ElementByIndex(ElementByPath(ref, path), loop), IntToHex(GetLoadOrderFormID(ckfa),8));
end;

function GetStuff(ref, out cafa, out ckfa, out cama, out ckma, out cofa, out coma, out cfa, out cma: IInterface; sig: string): Boolean;
var
	TempList: TStringList;
	a: integer;
begin
	if sig = 'OTFT' then begin
		if OTFTListList.IndexOf(EditorID(LinksTo(ref))) < 0 then result := false;
		templist := OTFTListList.Objects[OTFTListList.IndexOf(EditorID(LinksTo(ref)))];
	end else if sig = 'ARMO' then begin
		if ArmoListList.IndexOf(EditorID(LinksTo(ref))) < 0 then result := false;
		templist := ArmoListList.Objects[ArmoListList.IndexOf(EditorID(LinksTo(ref)))];
	end else if sig = 'LVLI' then begin
		if LVLIListList.IndexOf(EditorID(LinksTo(ref))) < 0 then result := false;
		templist := LVLIListList.Objects[LVLIListList.IndexOf(EditorID(LinksTo(ref)))];
	end;
	for a := templist.count - 1 downto 0 do
	begin
		if pos(templist.strings[a], 'Female_Argonian') > 0 then cafa := ObjectToElement(templist.objects[a])
		else if pos(templist.strings[a], 'Female_Khajiit') > 0 then ckfa := ObjectToElement(templist.objects[a])
		else if pos(templist.strings[a], 'Male_Argonian') > 0 then cama := ObjectToElement(templist.objects[a])
		else if pos(templist.strings[a], 'Male_Khajiit') > 0 then ckma := ObjectToElement(templist.objects[a])
		else if pos(templist.strings[a], 'Female_Orc') > 0 then cofa := ObjectToElement(templist.objects[a])
		else if pos(templist.strings[a], 'Male_Orc') > 0 then coma := ObjectToElement(templist.objects[a])
		else if pos(templist.strings[a], 'Female') > 0 then cfa := ObjectToElement(templist.objects[a])
		else if pos(templist.strings[a], 'Male') > 0 then cma := ObjectToElement(templist.objects[a]);
	end;
	result := true;
end;

procedure ReplaceFixed(ref: IInterface; Sig: String);
var
	a: integer
	cfa,cafa,cma,cama,ckfa,ckma,coma,cofa: IInterface;
begin
	if not GetStuff(ref,cafa,ckfa,cama,ckma,cofa,coma,cfa,cma, sig) then exit;
	if Race = 'Khajiit' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(ckfa),8));
	if Race = 'Orc' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cofa),8));
	if Race = 'Mer' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cfa),8));
	if Race = 'Argonian' AND Gender = true then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cafa),8));
	if Race = 'Khajiit' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(ckma),8));
	if Race = 'Orc' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(coma),8));
	if Race = 'Mer' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cma),8));
	if Race = 'Argonian' AND Gender = false then SetEditValue(ref, IntToHex(GetLoadOrderFormID(cama),8));
end;

end.