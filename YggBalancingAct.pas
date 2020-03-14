unit YggRebalancingAct;

var
	ArmorPatch, itemRecord, copyRecord: IInterface;
	WeapList, Recipes, MasterList, RatingsByKeyword: TStringList;
	HashedRatingsByKeyword, HashedList, HashedWeapList: THashedStringList;
	YggIni: TIniFile;
	
//Uses ArmorGooey;
Uses YggFunctions;

// runs on script start
function Initialize: integer;
var
	f: integer;
begin
	
end;

function BalancingInit:integer;
var
	f:integer;
begin
	AddMessage('---Setting up tight rope---');
		ArmorPatch := SelectPatch('Ygg_Rebalance.esp');
	PassFile(ArmorPatch);
	BeginUpdate(ArmorPatch);
	try
		AddMasterBySignature('ARMO');
		AddMasterBySignature('WEAP');
		AddMasterBySignature('AMMO');
	finally EndUpdate(ArmorPatch);
	end;
	IniSettings;
	Randomize;
	remove(ElementByPath(ArmorPatch, 'WEAP'));
	remove(ElementByPath(ArmorPatch, 'ARMO'));
	remove(ElementByPath(ArmorPatch, 'AMMO'));
	InitializeRecipes;
	DefineMasters;
	InitializeArmoLists;
	InitializeWeapLists;
	AddMessage('---Tight rope in place---');
	GatherArmo;
	GatherWeap;
	GatherAMMO;
	
end;

// for every record selected in xEdit
function Process(selectedRecord: IInterface): integer;
var
	recordSignature: string;
	recipeCraft, CurrentFile: IInterface;
begin
	while readFileCount = 0 do
	begin
		if skipFileCount = 0 then
		begin
			CurrentFile := getfile(selectedRecord);
			if hasGroup(CurrentFile, 'ARMO') or hasGroup(CurrentFile, 'WEAP') or hasGroup(CurrentFile, 'AMMO') then
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
	//addMessage(signature(selectedRecord));
	itemRecord := selectedRecord;
	recordSignature := Signature(selectedRecord);
	
	if (pos('ARMO', recordSignature) > 0) or (pos('WEAP', recordSignature) > 0) or (pos('AMMO', recordSignature) > 0) then
	begin
		
		//addMessage('record being read');
		if not IsWinningOVerride(itemRecord) then
		begin
			//addmessage('checkpoint winningOverride');
			exit;
		end;
		if GetIsDeleted(itemRecord) then 
		begin
			//addmessage('checkpoint deleted');
			exit;
		end;
		if IntToStr(GetElementNativeValues(itemRecord, 'Record Header\Record Flags\Non-Playable')) < 0 then 
		begin
			//addmessage('checkpoint nonplayable');
			exit;
		end;
		PassRecord(itemRecord);
		if pos('ARMO', recordSignature) > 0 then RatingBalancer;
		if pos('WEAP', recordSignature) > 0 then WeapProcessor;
		if HashedList.IndexOf(EditorID(itemRecord)) > 0 then recipeCraft := ObjectToElement(HashedList.Objects[HashedList.IndexOf(EditorID(itemRecord))]);
		//recipeCraft := findRecipe(false);
		//recipeCraft := FindCurrentRecipe;
		//recipeCraft := FindCraftingRecipe;
		if Assigned(recipeCraft) then
		begin
			copyRecord := wbCopyElementToFile(WinningOverride(itemRecord), patch, false, true);
			BeginUpdate(recipeCraft);
			try
				//addMessage('Checkpoint recipe');
				//fixValue(recipeCraft);
				//fixweight(recipeCraft);
				fixvalueandweight(recipeCraft);
			finally EndUpdate(recipeCraft);
			end;
		end;
	end;
		//addmessage('checkpoint');
	readFileCount := readFileCount - 1;
	Result := 0;
end;

// runs in the end
function Finalize: integer;
begin
	AddMessage('---Balancing act ended---');
	Sign;
	AddMessage('---Tight rope removed---');
	Result := 0;
end;

function FindCurrentRecipe: IInterface;
var
	f: integer;
	BNAM, CurrentRecord: IInterface;
begin
	//f := HashedList.IndexOf(EditorID(itemRecord));
	//CurrentRecord := ObjectToElement(HashedList.Objects[f]);
	//result := WinningOverride(CurrentRecord);
	result := ObjectToElement(HashedList.Objects[HashedList.IndexOf(EditorID(itemRecord))]);
	
end;

function InitializeWeapLists: integer;
var
	f, g, k: integer;
	CurrentFile, CurrentGroup, CurrentWeap, CurrentKeyword, Keywords: IInterface;
	KeywordList: TstringList;
	currentAddress: string;
begin
	WeapList := TstringList.Create;
	WeapList.Duplicates := dupAccept;
	KeywordList := TstringList.Create;
	for f :=  0 to FileCount - 1 do
	begin
		currentFile := FileByIndex(f);
		if HasGroup(currentFile, 'WEAP') then
		begin
			CurrentGroup := GroupBySignature(currentFile, 'WEAP');
			for g := 0 to ElementCount(CurrentGroup) - 1 do
			begin
				CurrentWeap := ElementByIndex(CurrentGroup, g);
				if not IsWinningOverride(CurrentWeap) then continue;
				if GetIsDeleted(CurrentWeap) then continue;
				if IntToStr(GetElementNativeValues(CurrentWeap, 'Record Header\Record Flags\Non-Playable')) < 0 then continue;
				Keywords := ElementByPath(CurrentWeap, 'KWDA');
				for k := ElementCount(Keywords) - 1 downTo 0 do
				begin
					CurrentKeyword := LowerCase(EditorId(WinningOverride(LinksTo(ElementByIndex(Keywords, k)))));
					currentAddress := CurrentKeyword + GetElementEditValues(CurrentWeap, 'DNAM\Animation Type');
					if pos('material', CurrentKeyword) > 0 then
					begin
						{//check if the keyword is in the list yet, if not, add it anyway.
						if KeywordList.IndexOf(CurrentKeyword) < 0 then
						begin
							KeywordList.Add(CurrentKeyword);
							WeapList.AddObject(currentAddress, CurrentWeap);
						//check if the bod2 is in the list yet, if not, add it anyway.
						end else if WeapList.IndexOf(currentAddress) < 0 then
						begin
							KeywordList.Add(CurrentKeyword);
							WeapList.AddObject(currentAddress, CurrentWeap);
						end else if MasterList.IndexOf(GetFileName(GetFile(MasterOrSelf(CurrentWeap)))) < 0 then continue;}
						WeapList.AddObject(currentAddress, CurrentWeap);
						continue;
					end;
				end;
			end;
		end;
	end;
	KeywordList.free;
	KeywordList.clear;
	WeapList.Sorted;
	HashedWeapList := THashedStringList.Create;
	HashedWeapList.Assign(WeapList);
end;

function WeapProcessor: integer;
var
	count, k, startIndex, f: integer;
	TotalCrit, TotalDamage, TotalReach, TotalSpeed, TotalMinRange, TotalMaxRange: double;
	OriginalCrit, OriginalDamage, OriginalReach, OriginalSpeed, OriginalMinRange, OriginalMaxRange: double;
	AverageCrit, AverageDamage, AverageReach, AverageSpeed, AverageMinRange, AverageMaxRange: double;
	TempRecord, Keywords: IInterface;
	CurrentKeyword, currentAddress: String;
begin
	Keywords := ElementByPath(itemRecord, 'KWDA');
	count := 0;
	TotalSpeed := 0;
	TotalReach := 0;
	TotalDamage := 0;
	TotalCrit := 0;
	TotalMinRange := 0;
	TotalMaxRange := 0;
	OriginalSpeed := tryStrToFloat(GetElementEditValues(itemRecord, 'DNAM\Speed'), 1);
	OriginalReach := tryStrToFloat(GetElementEditValues(itemRecord, 'DNAM\Reach'), 1);
	OriginalDamage := tryStrToFloat(GetElementEditValues(itemRecord, 'DATA\Damage'), 9);
	OriginalCrit := tryStrToFloat(GetElementEditValues(itemRecord, 'CRDT\Damage'), 3);
	OriginalMinRange := tryStrToFloat(GetElementEditValues(itemRecord, 'DNAM\Range Min'), 500);
	OriginalMaxRange := tryStrToFloat(GetElementEditValues(itemRecord, 'DNAM\Range Max'), 2000);
	for k := ElementCount(Keywords) - 1 downTo 0 do
	begin
		CurrentKeyword := EditorId(WinningOverride(LinksTo(ElementByIndex(Keywords, k))));
		if pos('material', CurrentKeyword) > 0 then
		begin
			currentAddress := CurrentKeyword + GetElementEditValues(itemRecord, 'DNAM\Animation Type');
			StartIndex := HashedWeapList.IndexOf(currentAddress);
			if startIndex > 0 then
			begin
				for f := startIndex to HashedWeapList.Count - 1 do
				begin
					if pos(HashedWeapList.Strings[f], currentAddress) > 0 then
					begin
						TempRecord := ObjectToElement(HashedWeapList.Objects[f]);
						Count := Count + 1;
						TotalSpeed := TotalSpeed + tryStrToFloat(GetElementEditValues(TempRecord, 'DNAM\Speed'), 1);
						TotalReach := TotalReach + tryStrToFloat(GetElementEditValues(TempRecord, 'DNAM\Reach'), 1);
						TotalDamage := TotalDamage + tryStrToFloat(GetElementEditValues(TempRecord, 'DATA\Damage'), 9);
						TotalCrit := TotalCrit + tryStrToFloat(GetElementEditValues(TempRecord, 'CRDT\Damage'), 3);
						TotalMinRange := TotalMinRange + tryStrToFloat(GetElementEditValues(itemRecord, 'DNAM\Range Min'), 500);
						TotalMaxRange := TotalMaxRange + tryStrToFloat(GetElementEditValues(itemRecord, 'DNAM\Range Max'), 2000);
					end else
					begin
						break;
					end;
				end;
			end;
		end;
	end;
	if count = 0 then
	begin
		count := 1;
		TotalSpeed := OriginalSpeed;
		TotalReach := OriginalReach;
		TotalDamage := OriginalDamage;
		TotalCrit := OriginalCrit;
		TotalMinRange := OriginalMinRange;
		TotalMaxRange := OriginalMaxRange;
	end;
	AverageSpeed := TotalSpeed / count;
	AverageReach := TotalReach / count;
	AverageDamage := TotalDamage / count;
	AverageCrit := TotalCrit / count;
	AverageMinRange := TotalMinRange / count;
	AverageMaxRange := TotalMaxRange / count;
	if pos('Bow', GetElementEditValues(itemRecord, 'DNAM\Animation Type')) > 0 then
	begin
		if OriginalMinRange > AverageMinRange then
		begin
			SetElementEditValues(CopyRecord, 'DNAM\Range Min', FloatToStr(AverageMinRange * (random(0.75) + 1)));
		end else if OriginalMinRange < AverageMinRange then
		begin
			SetElementEditValues(CopyRecord, 'DNAM\Range Min', FloatToStr(AverageMinRange * (random(0.5) + 0.5)));
		end else
		begin
			SetElementEditValues(CopyRecord, 'DNAM\Range Min', FloatToStr(AverageMinRange * (random(0.2) + 0.9)));
		end;
		if OriginalMaxRange > AverageMaxRange then
		begin
			SetElementEditValues(CopyRecord, 'DNAM\Range Max', FloatToStr(AverageMaxRange * (random(0.75) + 1)));
		end else if OriginalMaxRange < AverageMaxRange then
		begin
			SetElementEditValues(CopyRecord, 'DNAM\Range Max', FloatToStr(AverageMaxRange * (random(0.5) + 0.5)));
		end else
		begin
			SetElementEditValues(CopyRecord, 'DNAM\Range Max', FloatToStr(AverageMaxRange * (random(0.2) + 0.9)));
		end;
	end;
	if OriginalSpeed > AverageSpeed then
	begin
		SetElementEditValues(CopyRecord, 'DNAM\Speed', FloatToStr(AverageSpeed * (random(0.75) + 1)));
	end else if OriginalSpeed < AverageSpeed then
	begin
		SetElementEditValues(CopyRecord, 'DNAM\Speed', FloatToStr(AverageSpeed * (random(0.5) + 0.5)));
	end else
	begin
		SetElementEditValues(CopyRecord, 'DNAM\Speed', FloatToStr(AverageSpeed * (random(0.2) + 0.9)));
	end;
	if OriginalReach > AverageReach then
	begin
		SetElementEditValues(CopyRecord, 'DNAM\Reach', FloatToStr(AverageReach * (random(0.75) + 1)));
	end else if OriginalReach < AverageReach then
	begin
		SetElementEditValues(CopyRecord, 'DNAM\Reach', FloatToStr(AverageReach * (random(0.5) + 0.5)));
	end else
	begin
		SetElementEditValues(CopyRecord, 'DNAM\Reach', FloatToStr(AverageReach * (random(0.2) + 0.9)));
	end;
	if OriginalDamage > AverageDamage then
	begin
		SetElementEditValues(CopyRecord, 'DATA\Damage', IntToStr(floor(AverageDamage * (random(0.75) + 1))));
	end else if OriginalDamage < AverageDamage then
	begin
		SetElementEditValues(CopyRecord, 'DATA\Damage', IntToStr(floor(AverageDamage * (random(0.5) + 0.5))));
	end else
	begin
		SetElementEditValues(CopyRecord, 'DATA\Damage', IntToStr(floor(AverageDamage * (random(0.2) + 0.9))));
	end;
	if OriginalCrit > AverageCrit then
	begin
		SetElementEditValues(CopyRecord, 'CRDT\Damage', IntToStr(floor(AverageCrit * (random(0.75) + 1))));
	end else if OriginalCrit < AverageCrit then
	begin
		SetElementEditValues(CopyRecord, 'CRDT\Damage', IntToStr(floor(AverageCrit * (random(0.5) + 0.5))));
	end else
	begin
		SetElementEditValues(CopyRecord, 'CRDT\Damage', IntToStr(floor(AverageCrit * (random(0.2) + 0.9))));
	end;
end;

function fixvalueandweight(recipeCraft: IInterface): integer;
var
	weightOriginal, weightNew: double;
	ValueOriginal, ValueNew: Double;
	amount, i, l: integer;
	item, path: IInterface;
begin
	weightOriginal := tryStrToFloat(GetElementEditValues(itemRecord, 'DATA\Weight'), 10);
	ValueOriginal := tryStrToFloat(GetElementEditValues(itemRecord, 'DATA\Value'), 10);
	weightNew := 0;
	ValueNew := 0;
	path := ElementByPath(recipeCraft, 'Items');
	l := pred(tryStrToInt(GetElementEditValues(recipeCraft, 'COCT'), 1));
	if assigned(ElementByPath(recipeCraft, 'COCT')) then
	begin
		for i := l downto 0 do
		begin
			item := LinksTo(ElementByIndex(ElementByIndex(ElementByIndex(path, i), 0), 0));
			if not assigned(item) then continue;
			Amount := tryStrToInt(GetEditValue(ElementByIndex(ElementByIndex(ElementByIndex(path, i), 0), 1)), 1);
			if pos(signature(item), 'ALCH') > 0 then
			begin
				weightNew := amount * tryStrToFloat(GetElementEditValues(item, 'DATA - Weight'), weightOriginal) + weightNew;
				ValueNew := amount * tryStrToFloat(GetElementEditValues(item, 'ENIT\Value'), ValueOriginal) + ValueNew;
			end else
			begin
				weightNew := amount * tryStrToFloat(GetElementEditValues(item, 'DATA\Weight'), weightOriginal) + weightNew;
				ValueNew := amount * tryStrToFloat(GetElementEditValues(item, 'DATA\Value'), ValueOriginal) + ValueNew;
			end;
		end;
	end;
	if pos(signature(itemRecord), 'ARMO') > 0 then
	begin
		if hasKeyword(CurrentRecord, 'ArmorClothing') then
		begin
			if weightNew > weightOriginal then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Weight', FloatToStr(weightNew * (random(1) + 1)));
			end else if weightOriginal > weightNew then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Weight', FloatToStr(weightNew * (random(0.75) + 0.25)));
			end else if weightNew = weightOriginal then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Weight', FloatToStr(weightNew * (random(0.25)+ 0.9)));
			end;
			if ValueNew > ValueOriginal then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(1) + 1))));
			end else if ValueOriginal > ValueNew then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(0.75) + 0.25))));
			end else if ValueNew = ValueOriginal then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(0.25)+ 0.9))));
			end;
		end;
		if hasKeyword(CurrentRecord, 'ArmorHeavy') then
		begin
			if weightNew > weightOriginal then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Weight', FloatToStr(weightNew * (random(3) + 1)));
			end else if weightOriginal > weightNew then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Weight', FloatToStr(weightNew * (random(0.5) + 0.5)));
			end else if weightNew = weightOriginal then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Weight', FloatToStr(weightNew * (random(0.25)+ 0.9)));
			end;
			if ValueNew > ValueOriginal then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(3) + 1))));
			end else if ValueOriginal > ValueNew then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(0.5) + 0.5))));
			end else if ValueNew = ValueOriginal then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(0.25)+ 0.9))));
			end;
		end;
		if hasKeyword(CurrentRecord, 'ArmorLight') then
		begin
			if weightNew > (2 * weightOriginal) then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Weight', FloatToStr(weightNew * (random(2) + 2)));
			end else
			begin
				SetElementEditValues(CopyRecord, 'DATA\Weight', FloatToStr(weightNew * (random(1) + 1)));
			end;
			if ValueNew > (2 * ValueOriginal) then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(2) + 2))));
			end else
			begin
				SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(1) + 1))));
			end;
		end;
		if hasKeyword(CurrentRecord, 'ArmorJewelry') then
		begin
			if weightNew > (1 * weightOriginal) then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Weight', FloatToStr(weightNew * (random(0.5) + 1)));
			end else if weightNew > (0.5 * weightOriginal) then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Weight', FloatToStr(weightNew * random(0.5) + 0.5));
			end else if weightNew > (0.25 * weightOriginal) then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Weight', FloatToStr(weightNew * random(0.25) + 0.25));
			end else
			begin
				SetElementEditValues(CopyRecord, 'DATA\Weight', FloatToStr(weightNew * random(0.25) + 0.01));
			end;
			if ValueNew > (5 * ValueOriginal) then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(5) + 5))));
			end else if ValueNew > (2 * ValueOriginal) then
			begin
				SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(3) + 2))));
			end else
			begin
				SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(2)+ 1))));
			end;
		end;
	end;
	if pos(signature(itemRecord), 'AMMO') > 0 then
	begin
		weightNew := weightNew * 0.05;
		ValueNew := ValueNew * 0.05;
		if weightNew > (1 * weightOriginal) then
		begin
			SetElementEditValues(CopyRecord, 'DATA\Weight', (weightNew * (random(0.5) + 1)));
		end else if weightNew > (0.5 * weightOriginal) then
		begin
			SetElementEditValues(CopyRecord, 'DATA\Weight', (weightNew * random(0.5) + 0.5));
		end else if weightNew > (0.25 * weightOriginal) then
		begin
			SetElementEditValues(CopyRecord, 'DATA\Weight', (weightNew * random(0.25) + 0.25));
		end else
		begin
			SetElementEditValues(CopyRecord, 'DATA\Weight', (weightNew * random(0.25) + 0.01));
		end;
		if ValueNew > (5 * ValueOriginal) then
		begin
			SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(5) + 5))));
		end else if ValueNew > (2 * ValueOriginal) then
		begin
			SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(3) + 2))));
		end else
		begin
			SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(2)+ 1))));
		end;
	end;
	if pos(signature(itemRecord), 'WEAP') > 0 then
	begin
		if weightNew > weightOriginal then
		begin
			SetElementEditValues(CopyRecord, 'DATA\Weight', (weightNew * (random(3) + 1)));
		end else if weightOriginal > weightNew then
		begin
			SetElementEditValues(CopyRecord, 'DATA\Weight', (weightNew * (random(0.5) + 0.5)));
		end else if weightNew = weightOriginal then
		begin
			SetElementEditValues(CopyRecord, 'DATA\Weight', (weightNew * (random(0.25)+ 0.9)));
		end;
		if ValueNew > ValueOriginal then
		begin
			SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(3) + 1))));
		end else if ValueOriginal > ValueNew then
		begin
			SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(0.5) + 0.5))));
		end else if ValueNew = ValueOriginal then
		begin
			SetElementEditValues(CopyRecord, 'DATA\Value', IntToStr(floor(ValueNew * (random(0.25)+ 0.9))));
		end;
   
	end;
	AddMessage('weight and value done: ' + name(itemRecord));
end;

function InitializeArmoLists: integer;
var
	f, g, k: integer;
	CurrentFile, CurrentGroup, CurrentArmo, CurrentKeyword, Keywords: IInterface;
	KeywordList: TstringList;
	currentAddress: string;
begin
	RatingsByKeyword := TstringList.Create;
	RatingsByKeyword.Duplicates := dupAccept;
	KeywordList := TstringList.Create;
	for f :=  0 to FileCount - 1 do
	begin
		currentFile := FileByIndex(f);
		if HasGroup(currentFile, 'ARMO') then
		begin
			CurrentGroup := GroupBySignature(currentFile, 'ARMO');
			for g := 0 to ElementCount(CurrentGroup) - 1 do
			begin
				CurrentArmo := ElementByIndex(CurrentGroup, g);
				if not IsWinningOverride(CurrentArmo) then continue;
				if GetIsDeleted(CurrentArmo) then continue;
				if IntToStr(GetElementNativeValues(CurrentArmo, 'Record Header\Record Flags\Non-Playable')) < 0 then continue;
				Keywords := ElementByPath(CurrentArmo, 'KWDA');
				for k := ElementCount(Keywords) - 1 downTo 0 do
				begin
					CurrentKeyword := LowerCase(EditorId(WinningOverride(LinksTo(ElementByIndex(Keywords, k)))));
					currentAddress := CurrentKeyword + Name(ElementByIndex(ElementByPath(CurrentArmo, 'BOD2\First Person Flags'), 0));
					if ContainsText('material', CurrentKeyword) OR ContainsText('materiel', CurrentKeyword) then
					begin
						{//check if the keyword is in the list yet, if not, add it anyway.
						if KeywordList.IndexOf(CurrentKeyword) < 0 then
						begin
							KeywordList.Add(CurrentKeyword);
							RatingsByKeyword.AddObject(currentAddress, CurrentArmo);
						//check if the bod2 is in the list yet, if not, add it anyway.
						end else if RatingsByKeyword.IndexOf(currentAddress) < 0 then
						begin
							KeywordList.Add(CurrentKeyword);
							RatingsByKeyword.AddObject(currentAddress, CurrentArmo);
						end else if MasterList.IndexOf(GetFileName(GetFile(MasterOrSelf(CurrentArmo)))) < 0 then continue;}
						RatingsByKeyword.AddObject(currentAddress, CurrentArmo);
						continue;
					end;
				end;
			end;
		end;
	end;
	KeywordList.free;
	KeywordList.clear;
	RatingsByKeyword.Sorted;
	HashedRatingsByKeyword := THashedStringList.Create;
	HashedRatingsByKeyword.Assign(RatingsByKeyword);
end;

function RatingBalancer: integer;
var
	startIndex, k, f, count: integer;
	TotalRating, AverageRating, OriginalRating: Double;
	tempRecord, CurrentKeyword, Keywords: IInterface;
	currentAddress: String;
begin
	Count := 0;
	TotalRating := 0;
	Keywords := ElementByPath(itemRecord, 'KWDA');
	OriginalRating := tryStrToFloat(GetElementEditValues(itemRecord, 'DNAM'), 0);
	for k := ElementCount(Keywords) - 1 downTo 0 do
	begin
		CurrentKeyword := EditorID(WinningOverride(LinksTo(ElementByIndex(Keywords, k))));
		if pos('material', CurrentKeyword) > 0 then
		begin
			currentAddress := CurrentKeyword + Name(ElementByIndex(ElementByPath(itemRecord, 'BOD2\First Person Flags'), 0));
			startIndex := HashedRatingsByKeyword.IndexOf(currentAddress);
			if startIndex > 0 then
			begin
				for f := startIndex to HashedRatingsByKeyword.Count - 1 do
				begin
					if pos(HashedRatingsByKeyword.Strings[f], currentAddress) > 0 then
					begin
						TempRecord := ObjectToElement(HashedRatingsByKeyword.Objects[f]);
						Count := Count + 1;
						TotalRating := TotalRating + tryStrToFloat(GetElementEditValues(TempRecord, 'DNAM'), 0);
					end else
					begin
						break;
					end;
				end;
			end else
			begin
				count := 1;
				TotalRating := OriginalRating;
			end;
		end;
	end;
	if count = 0 then
	begin
		count := 1;
		TotalRating := OriginalRating;
	end;
	AverageRating := TotalRating / count;
	if OriginalRating > TotalRating then
	begin
		SetElementEditValues(CopyRecord, 'DNAM', FloatToStr(AverageRating * (random(0.75) + 1)));
	end else if OriginalRating < TotalRating then
	begin
		SetElementEditValues(CopyRecord, 'DNAM', FloatToStr(AverageRating * (random(0.5) + 0.5)));
	end else
	begin
		//SetElementEditValues(CopyRecord, 'DNAM', FloatToStr(AverageRating * (random(0.2) + 0.9)));
	end;
end;

function DefineMasters: integer;
begin
	MasterList := TstringList.Create;
	MasterList.Delimiter := ',';
	MasterList.StrictDelimiter := True;
	MasterList.DelimitedText := YggIni.ReadString('BaseData', 'sBaseMaster', 'Skyrim.esm,Dragonborn.esm,Update.esm,Dawnguard.esm,HearthFires.esm,SkyrimSE.exe,Unofficial Skyrim Special Edition Patch.esp');
end;
 
function InitializeRecipes: integer;
var
	f, r: integer;
	BNAM, currentFile, CurrentGroup, CurrentRecord: IInterface;
begin
	Recipes := TStringList.Create;
	Recipes.Duplicates := dupIgnore;
	for f := FileCount - 1 downto 0 do
	begin
		currentFile := FileByIndex(f);
		if HasGroup(currentFile, 'COBJ') then
		begin
			CurrentGroup := GroupBySignature(currentFile, 'COBJ');
			for r := ElementCount(CurrentGroup) - 1 downto 0 do
			begin
				CurrentRecord := ElementByIndex(CurrentGroup, r);
				BNAM := LinksTo(ElementByPath(CurrentRecord, 'BNAM'));
				if GetLoadOrderFormID(BNAM) = $000ADb78 then continue;
				if IsWinningOverride(CurrentRecord) then
				begin
					Recipes.AddObject(LowerCase(EditorID(WinningOverride(LinksTo(ElementByPath(CurrentRecord, 'CNAM'))))), CurrentRecord);
				end;
			end;
		end else
		begin
			continue;
		end;
	end;
	Recipes.Sorted;
	//MiddleChar := LeftStr(Recipes.Strings[Recipes.Count / 2], 1);
	HashedList := THashedStringList.Create;
	HashedList.Assign(Recipes);
end;

function IniSettings: integer;
begin
	YggIni := TIniFile.Create(ScriptsPath + 'YggIni.ini');
	if not length(YggIni.ReadString('BaseData', 'sBaseMaster', '.esp')) > 4 then YggIni.WriteString('BaseData', 'sBaseMaster', 'Skyrim.esm,Dragonborn.esm,Update.esm,Dawnguard.esm,HearthFires.esm,SkyrimSE.exe,Unofficial Skyrim Special Edition Patch.esp');
	YggIni.UpdateFile;
end;

end.