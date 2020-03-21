unit YggBalancingAct;
uses YggFunctions;
var
	Recipes,Armo,ArmoRating,ArmoWeight : TStringList;
	ArmoValue,Ammo,AMMODamage,AMMOValue : TStringList;
	AMMOWeight,Weap,WeapValue,WeapWeight : TStringList;
	WeapDamage,WeapSpeed : TStringList;
	WeapReach,WeapCrdtDam,WeapRangeMin,TrustedPlugins,WeapRangeMax : TStringList;
	YggIni: TMemIniFile;

Function Initialize: integer;
begin
	Balancer;
end;

procedure Balancer;
var
	BeginTime, EndTime: TDateTime;
begin
	//"init"
	BeginTime := Time;
	BeginLog('Balancing Act Start');
	PassTime(Time);
	Patch := SelectPatch('Ygg_Rebalance.esp');
	PassFile(Patch);
	BeginUpdate(Patch);
	try
		AddMasterBySignature('ARMO');
		AddMasterBySignature('WEAP');
		AddMasterBySignature('AMMO');
		remove(GroupBySignature(Patch, 'WEAP'));
		remove(GroupBySignature(Patch, 'ARMO'));
		remove(GroupBySignature(Patch, 'AMMO'));
	finally EndUpdate(Patch);
	end;
	IniProcess;
	Randomize;
	InitializeLists;
	
	//processing
	LogMessage(1,'Processing Section Start');
	BalancingProcess;
	LogMessage(1,'Processing Section Done');
	
	
	//finalizing
	AddMessage('---Balancing act ended---');
	Sign;
	AddMessage('---Tight rope removed---');
	LogMessage(3,'Completed');
end;

procedure IniProcess;
begin
	TrustedPlugins := TStringList.Create;
	TrustedPlugins.Delimiter := ',';
	TrustedPlugins.StrictDelimiter := True;
	YggIni := TIniFile.Create(ScriptsPath + 'YggIni.ini');
	TrustedPlugins.DelimitedText := YggIni.ReadString('BaseData', 'sBaseMaster', '.esp');
	if not TrustedPlugins.count <= 1 then 
		YggIni.WriteString('BaseData', 'sBaseMaster', 'Skyrim.esm,Dragonborn.esm,Update.esm,Dawnguard.esm,HearthFires.esm,SkyrimSE.exe,Unofficial Skyrim Special Edition Patch.esp');
	TrustedPlugins.DelimitedText := YggIni.ReadString('BaseData', 'sBaseMaster', '.esp');
	YggIni.UpdateFile;
end;

procedure InitializeLists;
var
	i,j:integer;
	CurrentFile,CurrentGroup,CurrentItem:IInterface;
	BNAM:IInterface;
begin
	LogMessage(1,'Gathering Lists');
	
	Recipes := TStringList.Create;
	Recipes.Duplicates := DupIgnore;
	Armo := TStringList.Create;
	ArmoRating := TStringList.Create;
	ArmoWeight := TStringList.Create;
	ArmoValue := TStringList.Create;
	Ammo := TStringList.Create;
	AMMODamage := TStringList.Create;
	AMMOValue := TStringList.Create;
	AMMOWeight := TStringList.Create; //game doesnt use this unless you have survival mode
	Weap := TStringList.Create;
	WeapValue := TStringList.Create;
	WeapWeight := TStringList.Create;
	WeapDamage := TStringList.Create;
	WeapSpeed := TStringList.Create;
	WeapReach := TStringList.Create;
	WeapCrdtDam := TStringList.Create;
	WeapRangeMin := TStringList.Create;
	WeapRangeMax := TStringList.Create;
	for i := FileCount - 1 downto 0 do begin
		CurrentFile := FileByIndex(i);
		//recipes
		if HasGroup(CurrentFile, 'COBJ') then begin
			CurrentGroup := GroupBySignature(CurrentFile, 'COBJ');
			for j := ElementCount(CurrentGroup) - 1 downto 0 do begin
				CurrentItem := ElementByIndex(CurrentGroup,j);
				if TrustedPlugins.IndexOf(GetFileName(GetFile(MasterOrSelf(CurrentItem)))) < 0 then continue;
				BNAM := LinksTo(ElementByPath(CurrentItem, 'BNAM'));
				if GetLoadOrderFormid(BNAM) = $000ADB78 then continue;
				if ContainsText(LowerCase(Name(BNAM)), 'workbench') then continue;
				if ContainsText(LowerCase(Name(BNAM)), 'armortable') then continue;
				if ContainsText(LowerCase(Name(BNAM)), 'sharpeningwheel') then continue;
				if ContainsText(LowerCase(Name(BNAM)), 'grindstone') then continue;
				if ContainsText(LowerCase(Name(CurrentItem)), 'temper') then continue;
				if IsWinningOverride(CurrentItem) then Recipes.AddObject(EditorID(WinningOverride(LinksTo(ElementByPath(CurrentItem, 'CNAM')))), CurrentItem);
			end;
		end;
		LogMessage(1, 'Checked COBJ In ' + GetFileName(CurrentFile));
		//armo
		if HasGroup(CurrentFile, 'ARMO') then begin
			AddArmo(CurrentFile);
		end;
		LogMessage(1, 'Checked ARMO In ' + GetFileName(CurrentFile));
		//weap
		if HasGroup(CurrentFile, 'WEAP') then begin
			AddWeap(CurrentFile);
		end;
		LogMessage(1, 'Checked WEAP In ' + GetFileName(CurrentFile));
		//ammo
		if HasGroup(CurrentFile, 'AMMO') then begin
			AddAmmo(CurrentFile);
		end;
		LogMessage(1, 'Checked AMMO In ' + GetFileName(CurrentFile));
	end;
	
	//finalize lists
	//finalize armolists
	FinalizeArmo;
	FinalizeWeap;
	FinalizeAmmo;
end;

procedure AddArmo(CurrentFile: IInterface);
var
	i,j,k:integer;
	CurrentGroup,CurrentItem:IInterface;
	Keywords:IInterface;
	CurrentKeyword,CurrentAddress,CurrentBOD2:string;
begin
	CurrentGroup := GroupBySignature(CurrentFile, 'ARMO');
	for j := ElementCount(CurrentGroup) - 1 downto 0 do begin
		CurrentItem := ElementByIndex(CurrentGroup, j);
		if GetIsDeleted(CurrentItem) then continue;
		if ContainsText(LowerCase(Name(CurrentItem)), 'skin') then continue;
		if hasKeyword(CurrentItem, 'Dummy') then continue;
		if IsWinningOverride(CurrentItem) then begin
			LogMessage(1, 'Adding ' + name(CurrentItem) + ' to lists');
			//for processing
			Armo.AddObject(EditorID(CurrentItem), CurrentItem);
			//for calculations
			if TrustedPlugins.IndexOf(GetFileName(GetFile(MasterOrSelf(CurrentItem)))) < 0 then continue;
			Keywords := ElementByPath(CurrentItem, 'KWDA');
			for k := ElementCount(Keywords) - 1 downto 0 do begin
				CurrentKeyword := LowerCase(EditorID(WinningOverride(LinksTo(ElementByIndex(Keywords,k)))));
				if ContainsText(CurrentKeyword, 'material') OR ContainsText(CurrentKeyword, 'materiel') then
				begin
					LogMessage(1, 'Adding ' + name(CurrentItem) + ' to calculations processing');
					CurrentBOD2 := Name(ElementByIndex(ElementByPath(CurrentItem, 'BOD2\First Person Flags'),0));
					CurrentAddress := CurrentKeyword+CurrentBOD2;
					if length(GetElementEditValues(CurrentItem, 'DNAM')) > 0 then
						ArmoRating.AddObject(CurrentAddress, CurrentItem);
					if length(GetElementEditValues(CurrentItem, 'DATA\Weight')) > 0 then
						ArmoWeight.AddObject(CurrentAddress, CurrentItem);
					if length(GetElementEditValues(CurrentItem, 'DATA\Value')) > 0 then
						ArmoValue.AddObject(CurrentAddress, CurrentItem);
				end;
			end;
		end;
	end;
end;

procedure AddWeap(CurrentFile: IInterface);
var
	i,j,k:integer;
	CurrentGroup,CurrentItem:IInterface;
	Keywords:IInterface;
	CurrentKeyword,CurrentAddress,CurrentBOD2:string;
begin
	CurrentGroup := GroupBySignature(CurrentFile, 'WEAP');
	for j := ElementCount(CurrentGroup) - 1 downto 0 do begin
		CurrentItem := ElementByIndex(CurrentGroup, j);
		if GetIsDeleted(CurrentItem) then continue;
		if hasKeyword(CurrentItem, 'Dummy') then continue;
		if IsWinningOverride(CurrentItem) then begin
			LogMessage(1, 'Adding ' + name(CurrentItem) + ' to lists');
			//for processing
			Weap.AddObject(EditorID(CurrentItem), CurrentItem);
			//for calculations
			if TrustedPlugins.IndexOf(GetFileName(GetFile(MasterOrSelf(CurrentItem)))) < 0 then continue;
			Keywords := ElementByPath(CurrentItem, 'KWDA');
			for k := ElementCount(Keywords) - 1 downto 0 do begin
				CurrentKeyword := LowerCase(EditorID(WinningOverride(LinksTo(ElementByIndex(Keywords,k)))));
				if ContainsText(CurrentKeyword, 'material') OR ContainsText(CurrentKeyword, 'materiel') then
				begin
					LogMessage(1, 'Adding ' + name(CurrentItem) + ' to calculations processing');
					CurrentBOD2 := Name(ElementByPath(CurrentItem, 'DNAM\Animation Type'));
					CurrentAddress := CurrentKeyword+CurrentBOD2;
					if length(GetElementEditValues(CurrentItem, 'DATA\Damage')) > 0 then
						WeapDamage.AddObject(CurrentAddress, CurrentItem);
					if length(GetElementEditValues(CurrentItem, 'DATA\Weight')) > 0 then
						WeapWeight.AddObject(CurrentAddress, CurrentItem);
					if length(GetElementEditValues(CurrentItem, 'DATA\Value')) > 0 then
						WeapValue.AddObject(CurrentAddress, CurrentItem);
					if length(GetElementEditValues(CurrentItem, 'DNAM\Speed')) > 0 then
						WeapSpeed.AddObject(CurrentAddress, CurrentItem);
					if length(GetElementEditValues(CurrentItem, 'DNAM\Reach')) > 0 then
						WeapReach.AddObject(CurrentAddress, CurrentItem);
					if length(GetElementEditValues(CurrentItem, 'CRDT\Damage')) > 0 then
						WeapCrdtDam.AddObject(CurrentAddress, CurrentItem);
					if length(GetElementEditValues(CurrentItem, 'DNAM\Range Min')) > 0 then
						WeapRangeMin.AddObject(CurrentAddress, CurrentItem);
					if length(GetElementEditValues(CurrentItem, 'DNAM\Range Max')) > 0 then
						WeapRangeMax.AddObject(CurrentAddress, CurrentItem);
				end;
			end;
		end;
	end;
end;

procedure AddAmmo(CurrentFile: IInterface);
var
	i,j,k:integer;
	CurrentGroup,CurrentItem:IInterface;
	Keywords:IInterface;
	CurrentKeyword,CurrentAddress,CurrentBOD2:string;
begin
	CurrentGroup := GroupBySignature(CurrentFile, 'Ammo');
	for j := ElementCount(CurrentGroup) - 1 downto 0 do begin
		CurrentItem := ElementByIndex(CurrentGroup, j);
		if GetIsDeleted(CurrentItem) then continue;
		if hasKeyword(CurrentItem, 'Dummy') then continue;
		if IsWinningOverride(CurrentItem) then begin
			LogMessage(1, 'Adding ' + name(CurrentItem) + ' to lists');
			//for processing
			Ammo.AddObject(EditorID(CurrentItem), CurrentItem);
			//for calculations
			if TrustedPlugins.IndexOf(GetFileName(GetFile(MasterOrSelf(CurrentItem)))) < 0 then continue;
			Keywords := ElementByPath(CurrentItem, 'KWDA');
			for k := ElementCount(Keywords) - 1 downto 0 do begin
				CurrentKeyword := LowerCase(EditorID(WinningOverride(LinksTo(ElementByIndex(Keywords,k)))));
				if ContainsText(CurrentKeyword, 'material') OR ContainsText(CurrentKeyword, 'materiel') then
				begin
					LogMessage(1, 'Adding ' + name(CurrentItem) + ' to calculations processing');
					CurrentBOD2 := Name(ElementByPath(CurrentItem, 'Data\Flags\Non-Bolt'));
					CurrentAddress := CurrentKeyword+CurrentBOD2;
					if length(GetElementEditValues(CurrentItem, 'DATA\Weight')) > 0 then
						AmmoWeight.AddObject(CurrentAddress, CurrentItem);
					if length(GetElementEditValues(CurrentItem, 'DATA\Damage')) > 0 then
						AmmoDamage.AddObject(CurrentAddress, CurrentItem);
					if length(GetElementEditValues(CurrentItem, 'DATA\Value')) > 0 then
						AmmoValue.AddObject(CurrentAddress, CurrentItem);
				end;
			end;
		end;
	end;
end;

procedure FinalizeArmo;
begin
	LogMessage(1,'processing ratings');
	averager('DNAM',ArmoRating);
	
	LogMessage(1,'processing Armo Weight');
	averager('DATA\Weight',ArmoWeight);
	
	LogMessage(1,'processing armo Value');
	averager('DATA\Weight',ArmoValue);
	
end;

procedure FinalizeWeap;
begin
	LogMessage(1,'processing weap Damage');
	averager('DATA\Damage',WeapDamage);
	LogMessage(1,'processing weap Weight');
	averager('DATA\Weight',WeapWeight);
	LogMessage(1,'processing weap Value');
	averager('DATA\Value',WeapValue);
	LogMessage(1,'processing weap speed');
	averager('DNAM\Speed',WeapSpeed);
	LogMessage(1,'processing weap reach');
	averager('DNAM\Reach',WeapReach);
	LogMessage(1,'processing weap critical damage');
	averager('CRDT\Damage',WeapCrdtDam);
	LogMessage(1,'processing weap minimum range');
	averager('DNAM\Range Min',WeapRangeMin);
	LogMessage(1,'processing weap maximum range');
	averager('DNAM\Range Max',WeapRangeMax);
end;

procedure FinalizeAmmo;
begin
	LogMessage(1,'processing Damage of ammos');
	averager('DATA\Damage',AmmoDamage);
	
	LogMessage(1,'processing Ammo Weight');
	averager('DATA\Weight',AmmoWeight);
	
	LogMessage(1,'processing ammo value');
	averager('DATA\Weight',AmmoValue);
	
end;

procedure averager(Path:string; out List:TStringList);
var
	i,j:integer;
	TempListA,TempListB:TStringList;
	ratings,ara,inda:string;
	rating:double;
	CompleteAverage:double;
begin
	TempListA := TStringList.Create;
	for i := List.Count - 1 downto 0 do begin
		ara := List.Strings[i];
		inda := TempListA.IndexOf(ara);
		ratings := GetElementEditValues(ObjectToElement(List.objects[i]), Path);
		if inda < 0 then
			TempListB := TStringList.Create
		else
			TempListB := TempListA.objects[inda];
		TempListB.Add(ratings);
		TempListA.AddObject(ara,TempListB);
	end;
	List.free;
	List := TStringList.Create;
	for i := TempListA.Count - 1 downto 0 do begin
		TempListB := TempListA.objects[i];
		rating := 0;
		for j := TempListB.count - 1 downto 0 do begin
			rating := rating + TryStrToFloat(TempListB.strings[j],5.0);
		end;
		rating := rating / TempListB.count;
		List.AddObject(TempListA.strings[i],rating);
		completeAverage := CompleteAverage + Rating;
	end;
	CompleteAverage := CompleteAverage / TempListA.Count;
	List.AddObject('averageofall',CompleteAverage);
	TempListA.free;
end;

procedure BalancingProcess;
var
	i,j:integer;
	CurrentItem:IInterface;
	Keywords:IInterface;
	CurrentKeyword,CurrentAddress,CurrentBOD2:string;
begin
	for i := Armo.Count - 1 downto 0 do begin
		CurrentItem := ObjectToElement(Armo.objects[i]);
		Keywords := ElementByPath(CurrentItem, 'KWDA');
		for j := ElementCount(Keywords) - 1 downto 0 do begin
			CurrentKeyword := LowerCase(EditorID(WinningOverride(LinksTo(ElementByIndex(Keywords,j)))));
			if ContainsText(CurrentKeyword, 'material') OR ContainsText(CurrentKeyword, 'materiel') then
			begin
				CurrentBOD2 := Name(ElementByIndex(ElementByPath(CurrentItem, 'BOD2\First Person Flags'),0));
				CurrentAddress := CurrentKeyword+CurrentBOD2;
			end;
		end;
		Ratings(CurrentItem,CurrentAddress);
		Weight(CurrentItem,CurrentAddress);
		Value(CurrentItem,CurrentAddress);
	end;
	Armo.Free;
	for i := Weap.Count - 1 downto 0 do begin
		CurrentItem := ObjectToElement(Weap.Objects[i]);
		Keywords := ElementByPath(CurrentItem, 'KWDA');
		for j := ElementCount(Keywords) - 1 downto 0 do begin
			CurrentKeyword := LowerCase(EditorID(WinningOverride(LinksTo(ElementByIndex(Keywords,j)))));
			if ContainsText(CurrentKeyword, 'material') OR ContainsText(CurrentKeyword, 'materiel') then
			begin
				CurrentBOD2 := Name(ElementByPath(CurrentItem, 'DNAM\Animation Type'));
				CurrentAddress := CurrentKeyword+CurrentBOD2;
			end;
		end;
		Weight(CurrentItem,CurrentAddress);
		Value(CurrentItem,CurrentAddress);
		WeapProcess(CurrentItem,CurrentAddress);
	end;
	Weap.Free;
	for i := Ammo.Count - 1 downto 0 do begin
		CurrentItem := ObjectToElement(Ammo.Objects[i]);
		Keywords := ElementByPath(CurrentItem, 'KWDA');
		for j := ElementCount(Keywords) - 1 downto 0 do begin
			CurrentKeyword := LowerCase(EditorID(WinningOverride(LinksTo(ElementByIndex(Keywords,j)))));
			if ContainsText(CurrentKeyword, 'material') OR ContainsText(CurrentKeyword, 'materiel') then
			begin
				CurrentBOD2 := Name(ElementByPath(CurrentItem, 'Data\Flags\Non-Bolt'));
				CurrentAddress := CurrentKeyword+CurrentBOD2;
			end;
		end;
		Weight(CurrentItem,CurrentAddress);
		Value(CurrentItem,CurrentAddress);
		AmmoProcess(CurrentItem,CurrentAddress);
	end;
end;

procedure Ratings(item:IInterface;address:string);
var
	temp,OriginalRating,AverageRating: double;
begin
	OriginalRating := TryStrToFloat(GetElementEditValues(item, 'DNAM'),0);
	AddIndex := ArmoRating.IndexOf(address);
	if AddIndex < 0 then
		averageRating := ArmoRating.objects[AddIndex];
	else ArmoRating.Objects[ArmoRating.IndexOf('averageofall')];
	temp := BalanceRandomizerfloat(OriginalRating,averageRating,7);
	SetElementEditValues(item, 'DNAM', FloatToStr(temp));
end;

Procedure Weight(item:IInterface;address:string);
var
	i,l,j:integer;
	cobj: IInterface;
	WeightCobj,WeightExisting,Weight:double;
	temp: double;
begin
	//estimating weight
	
	WeightCobj := 0;
	cobj := ObjectToElement(recipes.objects[Recipes.IndexOf(EditorID(item))]);
	path := ElementByPath(cobj, 'Items');
	LogMessage(1,'processing cobj for item: ' + name(item));
	l := pred(tryStrToInt(GetElementEditValues(cobj, 'COCT'), 1));
	if assigned(ElementByPath(cobj, 'COCT')) then begin
		for i := l downto 0 do begin
			cobjitem := LinksTo(ElementByIndex(ElementByIndex(ElementByIndex(path, i), 0), 0));
			Amount := tryStrToInt(GetEditValue(ElementByIndex(ElementByIndex(ElementByIndex(path, i), 0), 1)), 1);
			if pos(signature(cobjitem), 'ALCH') > 0 then
			begin
				WeightCobj := amount * tryStrToFloat(GetElementEditValues(cobjitem, 'DATA - Weight'), weightOriginal) + WeightCobj;
			end else
			begin
				WeightCobj := amount * tryStrToFloat(GetElementEditValues(cobjitem, 'DATA\Weight'), weightOriginal) + WeightCobj;
			end;
		end;
	end;
	
	if signature(item) = 'ARMO' then begin
		AddIndex := ArmoWeight.IndexOf(address);
		if AddIndex < 0 then
			WeightExisting := ArmoWeight.objects[AddIndex];
		else ArmoWeight.Objects[ArmoWeight.IndexOf('averageofall')];
	end else if signature(item) = 'WEAP' then begin
		AddIndex := WeapWeight.IndexOf(address);
		if AddIndex < 0 then
			WeightExisting := WeapWeight.objects[AddIndex];
		else WeapWeight.Objects[WeapWeight.IndexOf('averageofall')];
	end else begin
		AddIndex := AmmoWeight.IndexOf(address);
		if AddIndex < 0 then
			WeightExisting := AmmoWeight.objects[AddIndex];
		else AmmoWeight.Objects[AmmoWeight.IndexOf('averageofall')];
	end;
	
	weight := TryStrToFloat(GetElementEditValues(item, 'DATA\Weight'),0.0);
	LogMessage(1, 'the estimated weight based on cobj is: ' + IntToStr(WeightCobj) + ' the estimated weight based on included items is: ' + IntToStr(WeightExisting) + 'the current weight is: ' + weight);
	weightedAverage := WeightCobj * 0.3 + WeightExisting * 0.7;
	temp := BalanceRandomizerfloat(weight,weightedAverage,7);
	SetElementEditValues(item. 'Data\Weight', FloatToStr(temp);
end;

procedure Value(item:IInterface;address:string);
var
	i,j,l:integer;
	ValueAverage,ValueCobj,ValueExisting:double;
	Value:int;
	temp: double;
begin
	
	ValueCobj := 0;
	cobj := ObjectToElement(recipes.objects[Recipes.IndexOf(EditorID(item))]);
	path := ElementByPath(cobj, 'Items');
	LogMessage(1,'processing cobj for item: ' + name(item));
	l := pred(tryStrToInt(GetElementEditValues(cobj, 'COCT'), 1));
	if assigned(ElementByPath(cobj, 'COCT')) then begin
		for i := l downto 0 do begin
			cobjitem := LinksTo(ElementByIndex(ElementByIndex(ElementByIndex(path, i), 0), 0));
			Amount := tryStrToInt(GetEditValue(ElementByIndex(ElementByIndex(ElementByIndex(path, i), 0), 1)), 1);
			if pos(signature(cobjitem), 'ALCH') > 0 then
			begin
				ValueCobj := amount * tryStrToInt(GetElementEditValues(cobjitem, 'ENIT\Value'), Value) + ValueCobj;
			end else
			begin
				ValueCobj := amount * tryStrToInt(GetElementEditValues(cobjitem, 'DATA\Value'), Value) + ValueCobj;
			end;
		end;
	end;
	
	if signature(item) = 'ARMO' then begin
		AddIndex := Armovalue.IndexOf(address);
		if AddIndex < 0 then
			valueExisting := Armovalue.objects[AddIndex];
		else Armovalue.Objects[Armovalue.IndexOf('averageofall')];
	end else if signature(item) = 'WEAP' then begin
		AddIndex := Weapvalue.IndexOf(address);
		if AddIndex < 0 then
			valueExisting := Weapvalue.objects[AddIndex];
		else Weapvalue.Objects[Weapvalue.IndexOf('averageofall')];
	end else begin 
		AddIndex := Ammovalue.IndexOf(address);
		if AddIndex < 0 then
			valueExisting := Ammovalue.objects[AddIndex];
		else Ammovalue.Objects[Ammovalue.IndexOf('averageofall')];
	end;
	
	Value := tryStrToInt(GetElementEditValues(item, 'DATA\Value'),0.0);
	LogMessage(1, 'the estimated Value based on cobj is: ' + IntToStr(ValueCobj) + ' the estimated Value based on included items is: ' + IntToStr(ValueExisting) + 'the current Value is: ' + Value);
	ValueAverage := ValueCobj * 0.3 + ValueExisting * 0.7;
	temp := BalanceRandomizerInt(Value,ValueAverage,500);
	SetElementEditValues(item. 'Data\Value', IntToStr(floor(temp));
end;

procedure WeapProcess(item:IInterface;address:string);
var
	original,temp,existing: double;
	originali,tempi: int;
begin
	original := tryStrToFloat(GetElementEditValues(item, 'DNAM\Speed'), 1.0);
		AddIndex := WeapSpeed.IndexOf(address);
		if AddIndex < 0 then
			existing := WeapSpeed.objects[AddIndex];
		else WeapSpeed.Objects[WeapSpeed.IndexOf('averageofall')];
	existing := WeapSpeed.objects[WeapSpeed.IndexOf(address)];
	temp := BalanceRandomizerfloat(original,existing,0.5);
	SetElementEditValues(item, 'DNAM\Speed', FloatToStr(temp));
	
	originali := tryStrToInt(GetElementEditValues(item, 'DATA\Damage'), 1);
		AddIndex := WeapDamage.IndexOf(address);
		if AddIndex < 0 then
			existing := WeapDamage.objects[AddIndex];
		else WeapDamage.Objects[WeapDamage.IndexOf('averageofall')];
	tempi := BalanceRandomizerInt(original,existing,5);
	SetElementEditValues(item, 'DATA\Damage', IntToStr(temp));
	
	original := tryStrToFloat(GetElementEditValues(item, 'DNAM\Reach'), 1.0);
		AddIndex := WeapReach.IndexOf(address);
		if AddIndex < 0 then
			existing := WeapReach.objects[AddIndex];
		else WeapReach.Objects[WeapReach.IndexOf('averageofall')];
	temp := BalanceRandomizerfloat(original,existing,0.5);
	SetElementEditValues(item, 'DNAM\Reach', FloatToStr(temp));
	
	originali := tryStrToInt(GetElementEditValues(item, 'CRDT\Damage'), 1);
		AddIndex := WeapCrdtDam.IndexOf(address);
		if AddIndex < 0 then
			existing := WeapCrdtDam.objects[AddIndex];
		else WeapCrdtDam.Objects[WeapCrdtDam.IndexOf('averageofall')];
	tempi := BalanceRandomizerInt(original,existing,5);
	SetElementEditValues(item, 'CRDT\Damage', IntToStr(temp));
	
	original := tryStrToFloat(GetElementEditValues(item, 'DNAM\Range Min'), 1.0);
		AddIndex := WeapRangeMin.IndexOf(address);
		if AddIndex < 0 then
			existing := WeapRangeMin.objects[AddIndex];
		else WeapRangeMin.Objects[WeapRangeMin.IndexOf('averageofall')];
	temp := BalanceRandomizerfloat(original,existing,500);
	SetElementEditValues(item, 'DNAM\Range Min', FloatToStr(temp));
	
	original := tryStrToFloat(GetElementEditValues(item, 'DNAM\Range Max'), 1.0);
		AddIndex := WeapRangeMax.IndexOf(address);
		if AddIndex < 0 then
			existing := WeapRangeMax.objects[AddIndex];
		else WeapRangeMax.Objects[WeapRangeMax.IndexOf('averageofall')];
	temp := BalanceRandomizerfloat(original,existing,500);
	SetElementEditValues(item, 'DNAM\Range Max', FloatToStr(temp));
end;

procedure AmmoProcess(item:IInterface;address:string);
var
	original,temp,existing: double;
	originali,tempi: int;
begin
	original := tryStrToFloat(GetElementEditValues(item, 'DATA\Damage'), 1.0);
		AddIndex := AMMODamage.IndexOf(address);
		if AddIndex < 0 then
			existing := AMMODamage.objects[AddIndex];
		else AMMODamage.Objects[AMMODamage.IndexOf('averageofall')];
	temp := BalanceRandomizerfloat(original,existing,5);
	SetElementEditValues(item, 'DATA\Damage', IntToStr(floor(temp)));
end;

function BalanceRandomizerInt(original:int,existing:float;VaritionDiff:float):int;
begin
	if Original > existing then
	begin
		temp := existing * (random(0.5) + 1);
	end else if Original < existing then
	begin
		temp := existing * (random(0.5) + 0.5);
	end else
	begin
		temp := existing * (random(0.4) + 0.8);
	end;
	while temp > existing + 0.5 OR temp < existing - 0.5 do begin
		if temp > existing then
		begin
			temp := temp - 5 * (random(0.5) + 1);
		end else if temp < existing then
		begin
			temp := temp + 5 * (random(0.5) + 0.5);
		end;
	end;
	result := floor(temp);
end;

function BalanceRandomizerfloat(original,existing:float;VaritionDiff:float):float;
begin
	if Original > existing then
	begin
		temp := existing * (random(0.5) + 1);
	end else if Original < existing then
	begin
		temp := existing * (random(0.5) + 0.5);
	end else
	begin
		temp := existing * (random(0.4) + 0.8);
	end;
	while temp > existing + VaritionDiff OR temp < existing - VaritionDiff do begin
		if temp > existing then
		begin
			temp := temp - VaritionDiff * (random(0.5) + 1);
		end else if temp < existing then
		begin
			temp := temp + VaritionDiff * (random(0.5) + 0.5);
		end;
	end;
	result := temp;
end;

end.
