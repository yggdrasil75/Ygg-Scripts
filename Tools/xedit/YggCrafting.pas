unit YggCrafting;
uses YggFunctions;
var
	Patch, CurrentItem: IInterface;
	HashedList: THashedStringList;
	Materials, MaterialList, Recipes, TempPerkListExtra: TStringList;
	ArmoList,WeapList,AMMOList: TStringList;
	CraftMult, optionAddOnly, optionPerkConditions: integer;
	Ini: TMemIniFile;
	firstRun: boolean;
	DebugLevel: integer;
	sBaseMaster: string;
	SingleFile: boolean;
	SinglePlugin: IInterface;
	TimeBegin: TDateTime;
	Temper,Breakdown,YggLogCurrentMessages: TStringList;
	
const
	scaleFactor = Screen.PixelsPerInch / 96;
	
function Initialize: integer;
begin
	result := CraftingInit;
	CraftingProcessing;
	CraftingFinal;
end;

function CraftingInit: integer;
var
	f: integer;
	BeginTime, EndTime: TDateTime;
	temp:string;
	SPM: TStringList;
begin
	YggLogCurrentMessages := TStringList.Create;
	BeginTime := Time;
	beginLog('Crafter start');
	PassTime(Time);
	firstRun := false;
	SingleMode;
	if not SingleFile then 
		Patch := SelectPatch('Ygg_Crafting.esp')
	else begin
		temp := GetFileName(SinglePlugin);
		temp := StringReplace(temp, '.esp', '', [rfReplaceAll]);
		temp := StringReplace(temp, '.esl', '', [rfReplaceAll]);
		temp := StringReplace(temp, '.esm', '', [rfReplaceAll]);
		Patch := SelectPatch(temp+' Ygg_Crafting.esp');
		LogMessage(2, 'Using ' + GetFileName(Patch) + ' due to single mode',YggLogCurrentMessages);
	end;
	BeginUpdate(Patch);
	try
		remove(GroupBySignature(Patch, 'COBJ'));
		Cleanmasters(Patch);
		AddmasterBySignature('ARMO');
		AddmasterBySignature('AMMO');
		AddmasterBySignature('WEAP');
		AddmasterBySignature('COBJ');
		AddmasterBySignature('MISC');
		MasterLines;
	finally EndUpdate(Patch);
	end;
	IniProcess;
	Randomize;
	InitializeRecipes;
	tempPerkFunctionSetup;
	LogMessage(0,'---Making Armor craftable---',YggLogCurrentMessages);
	AddMessage('---Making Armor craftable---');
	LogMessage(1, 'Initialize',YggLogCurrentMessages);
end;

function IniProcess: integer;
var
	TalkToUser: integer;
begin
	//IniStream :=
	{
	if exec(TFPHTTPClient.SimpleGet('https://www.nexusmods.com/skyrimspecialedition/mods/26549')) then begin
	}
	Ini := TMemIniFile.Create(ScriptsPath + 'Ygg.ini');
	if ini.ReadInteger('BaseData', 'FirstRun', 0) = 0 then 
	begin
		TalkToUser := MessageDlg('There will be a few settings options pop up on the first run, these settings will be saved to Ygg.ini in the folder that contains the script you are currently running. If you ever want to change them, you can delete the line from the ini, alter it manually, or just delete the ini file itself.', mtInformation, [mbOk], 0);
		ini.WriteInteger('BaseData', 'FirstRun', TalkToUser);
	end;
	if ini.ReadInteger('Crafting', 'bCraftOnly', 0) = 0 then
	begin
		optionAddOnly := MessageDlg('Do you want to only create new recipes and not update existing?', mtConfirmation, [mbYes, mbNo, mbAbort], 0);
		if optionAddOnly = mrAbort then
			exit
		else ini.WriteInteger('Crafting', 'bCraftOnly', optionAddOnly);
	end else optionAddOnly := ini.ReadInteger('Crafting', 'bCraftOnly', 0);
	if ini.ReadInteger('Crafting', 'bCraftPerks', 0) = 0 then
	begin
		optionPerkConditions := MessageDlg('Do you want recipes to have perk conditions?', mtConfirmation, [mbYes, mbNo, mbAbort], 0);
		if optionPerkConditions = mrAbort then
			exit
		else ini.WriteInteger('Crafting', 'bCraftPerks', optionPerkConditions);
	end else optionPerkConditions := ini.ReadInteger('Crafting', 'bCraftPerks', 0);
	sBaseMaster := Ini.ReadString('BaseData', 'sBaseMaster', 'Skyrim.esm,Dragonborn.esm,Update.esm,Dawnguard.esm,HearthFires.esm,SkyrimSE.exe,Unofficial Skyrim Special Edition Patch.esp');
		ini.WriteString('BaseData', 'sBaseMaster', sBaseMaster);
	firstRun := Ini.ReadBool('BaseData', 'UpdateINI', true);
	GatherMaterials; 
	CraftMult := Ini.ReadInteger('BaseData', 'iCraftingMult', 1);
	Ini.WriteInteger('BaseData', 'iCraftingMult', CraftMult);
	Ini.WriteBool('BaseData', 'UpdateINI', false);
	Ini.UpdateFile;
end;

procedure SingleMode;
var
	YggIni: TMemIniFile;
	temp,tempEvery: integer;
	bEvery:boolean;
begin
	YggIni := TIniFile.Create(ScriptsPath + 'Ygg.ini');
	if YggIni.ReadInteger('Balance', 'bAskEvery', 0) = 0 then
	begin
		tempEvery := MessageDlg('Do you want to be asked every time for single mode?', mtConfirmation, [mbYes, mbNo, mbAbort], 0);
		if tempEvery = mrAbort then
			exit
		else YggIni.WriteInteger('Balance', 'bAskEvery', tempEvery);
	end else tempEvery := YggIni.ReadInteger('Balance', 'bAskEvery', 0);
	if tempEvery = 7 then bEvery := false
	else bEvery := true;
	if YggIni.ReadInteger('Balance', 'bSingleMode', 0) = 0  then begin
		temp := MessageDlg('I have added a "single plugin" mode which uses all plugins to calculate the contents of only 1 of those plugins, instead of all requisite plugins. WARNING: this assumes all loaded plugins are "trusted", DO NOT USE IF YOU HAVEN''T WATCH THE TUTORIAL!', mtConfirmation, [mbYes, mbNo, mbAbort], 0);
		if temp = mrAbort then
			exit
		else YggIni.WriteInteger('Balance', 'bSingleMode', temp);
	end else if bEvery then begin
		temp := MessageDlg('I have added a "single plugin" mode which uses all plugins to calculate the contents of only 1 of those plugins, instead of all requisite plugins. WARNING: this assumes all loaded plugins are "trusted", DO NOT USE IF YOU HAVEN''T WATCH THE TUTORIAL!', mtConfirmation, [mbYes, mbNo, mbAbort], 0);
		if temp = mrAbort then
			exit
		else YggIni.WriteInteger('Balance', 'bSingleMode', temp);
	end else temp := YggIni.ReadInteger('Balance', 'bSingleMode', 0);
	if temp = 6 then SingleFile := true
	else SingleFile := false;
	YggIni.UpdateFile;
	if SingleFile then begin
		SinglePlugin := Configure('Balance SinglePlugin mode');
	end;
end;

function Configure(asCaption: String): IwbFile;
var
  frm: TForm;
  lblPlugins: TLabel;
  chkAddTags: TCheckBox;
  chkLogging: TCheckBox;
  cbbPlugins: TComboBox;
  btnCancel: TButton;
  btnOk: TButton;
  i: Integer;
  kFile: IwbFile;
begin
  Result := nil;

  frm := TForm.Create(TForm(frmMain));

  try
    frm.Caption := asCaption;
    frm.BorderStyle := bsToolWindow;
    frm.ClientWidth := 234 * scaleFactor;
    frm.ClientHeight := 90 * scaleFactor;
    frm.Position := poScreenCenter;
    frm.KeyPreview := True;

    lblPlugins := TLabel.Create(frm);
    lblPlugins.Parent := frm;
    lblPlugins.Left := 16 * scaleFactor;
    lblPlugins.Top := 10 * scaleFactor;
    lblPlugins.Width := 200 * scaleFactor;
    lblPlugins.Height := 16 * scaleFactor;
    lblPlugins.Caption := 'Select file to Craft:';
    lblPlugins.AutoSize := False;

    cbbPlugins := TComboBox.Create(frm);
    cbbPlugins.Parent := frm;
    cbbPlugins.Left := 16 * scaleFactor;
    cbbPlugins.Top := 30 * scaleFactor;
    cbbPlugins.Width := 200 * scaleFactor;
    cbbPlugins.Height := 21 * scaleFactor;
    cbbPlugins.Style := csDropDownList;
    cbbPlugins.DoubleBuffered := True;
    cbbPlugins.TabOrder := 2;

	for i := 0 to Pred(FileCount) do
	begin
		kFile := FileByIndex(i);
		if IsEditable(kFile) then
			cbbPlugins.Items.Add(GetFileName(kFile));
	end;

    cbbPlugins.ItemIndex := Pred(cbbPlugins.Items.Count);

    btnOk := TButton.Create(frm);
    btnOk.Parent := frm;
    btnOk.Left := 62 * scaleFactor;
    btnOk.Top := 55 * scaleFactor;
    btnOk.Width := 75 * scaleFactor;
    btnOk.Height := 25 * scaleFactor;
    btnOk.Caption := 'Run';
    btnOk.Default := True;
    btnOk.ModalResult := mrOk;
    btnOk.TabOrder := 3;

    btnCancel := TButton.Create(frm);
    btnCancel.Parent := frm;
    btnCancel.Left := 143 * scaleFactor;
    btnCancel.Top := 55 * scaleFactor;
    btnCancel.Width := 75 * scaleFactor;
    btnCancel.Height := 25 * scaleFactor;
    btnCancel.Caption := 'Abort';
    btnCancel.ModalResult := mrAbort;
    btnCancel.TabOrder := 4;

    if frm.ShowModal = mrOk then
      Result := FileByName(cbbPlugins.Text);
  finally
    frm.Free;
  end;
end;

procedure gatherArmo;
var
	armoPlugins: TStringList;
	i, j: integer;
	CurrentGroup, CurrentItem: IInterface;
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
			CurrentItem := ElementByIndex(CurrentGroup, j);
			if GetIsDeleted(CurrentItem) then continue;
			if IntToStr(GetElementNativeValues(CurrentItem, 'Record Header\Record Flags\Non-Playable')) < 0 then continue;
			if IntToStr(GetElementNativeValues(CurrentItem, 'DATA\Flags\Non-Playable')) < 0 then continue;
			if pos('skin', EditorID(CurrentItem)) > 0 then continue;
			if HasKeyword(CurrentItem, 'noCraft') then continue;
			if hasKeyword(CurrentItem, 'Dummy') then continue;
			if GetElementNativeValues(CurrentItem, 'EITM') > 0 then continue;
			if ISWinningOverride(CurrentItem) then 
			if SingleFile then begin
				if equals(GetFile(CurrentItem), SinglePlugin) then begin
					ArmoList.AddObject(EditorID(CurrentItem), CurrentItem);
					continue;
				end;
			end;
			ArmoList.AddObject(EditorID(CurrentItem), CurrentItem);
		end;
	end;
end;

procedure gatherWeap;
var
	WeapPlugins: TStringList;
	i, j: integer;
	CurrentGroup, CurrentItem: IInterface;
begin
	WeapPlugins := TStringList.Create;
	for i := filecount - 1 downto 0 do
	begin
		if hasGroup(fileByIndex(i), 'Weap') then
		WeapPlugins.addObject(GetfileName(FileByIndex(i)), FileByIndex(i)); 
	end;
	WeapList := TStringList.Create;
	for i := WeapPlugins.Count - 1 downto 0 do
	begin
		CurrentGroup := GroupBySignature(ObjectToElement(WeapPlugins.objects[i]), 'Weap');
		for j := ElementCount(CurrentGroup) - 1 downto 0 do
		begin
			CurrentItem := ElementByIndex(CurrentGroup, j);
			if GetIsDeleted(CurrentItem) then continue;
			if IntToStr(GetElementNativeValues(CurrentItem, 'Record Header\Record Flags\Non-Playable')) < 0 then continue;
			if IntToStr(GetElementNativeValues(CurrentItem, 'DATA\Flags\Non-Playable')) < 0 then continue;
			if HasKeyword(CurrentItem, 'noCraft') then continue;
			if GetElementNativeValues(CurrentItem, 'EITM') > 0 then continue;
			if hasKeyword(CurrentItem, 'Dummy') then continue;
			if ISWinningOverride(CurrentItem) then 
			if SingleFile then begin
				if equals(GetFile(CurrentItem), SinglePlugin) then begin
					WeapList.AddObject(EditorID(CurrentItem), CurrentItem);
					continue;
				end;
			end;
			WeapList.AddObject(EditorID(CurrentItem), CurrentItem);
		end;
	end;
end;

procedure gatherAMMO;
var
	AMMOPlugins: TStringList;
	i, j: integer;
	CurrentGroup, CurrentItem: IInterface;
begin
	AMMOPlugins := TStringList.Create;
	for i := filecount - 1 downto 0 do
	begin
		if hasGroup(fileByIndex(i), 'AMMO') then
		AMMOPlugins.addObject(GetfileName(FileByIndex(i)), FileByIndex(i)); 
	end;
	AMMOList := TStringList.Create;
	for i := AMMOPlugins.Count - 1 downto 0 do
	begin
		CurrentGroup := GroupBySignature(ObjectToElement(AMMOPlugins.objects[i]), 'AMMO');
		for j := ElementCount(CurrentGroup) - 1 downto 0 do
		begin
			CurrentItem := ElementByIndex(CurrentGroup, j);
			if GetIsDeleted(CurrentItem) then continue;
			if IntToStr(GetElementNativeValues(CurrentItem, 'Record Header\Record Flags\Non-Playable')) < 0 then continue;
			if IntToStr(GetElementNativeValues(CurrentItem, 'DATA\Flags\Non-Playable')) < 0 then continue;
			if HasKeyword(CurrentItem, 'noCraft') then continue;
			if hasKeyword(CurrentItem, 'Dummy') then continue;
			if GetElementNativeValues(CurrentItem, 'EITM') > 0 then continue;
			if ISWinningOverride(CurrentItem) then 
			if SingleFile then begin
				if equals(GetFile(CurrentItem), SinglePlugin) then begin
					AMMOList.AddObject(EditorID(CurrentItem), CurrentItem);
					continue;
				end;
			end;
			AMMOList.AddObject(EditorID(CurrentItem), CurrentItem);
		end;
	end;
end;

procedure CraftingProcessing;
var
	recordSignature: string;
	recipeCraft: IInterface;
	CurrentFile: IInterface;
	i: integer;
begin
	GatherArmo;
	GatherWeap;
	GatherAMMO;
	for i := ArmoList.count - 1 downto 0 do begin
		CurrentItem := ObjectToElement(ArmoList.Objects[i]);
		MakeCraftable;
	end;
	ArmoList.free;
	for i := WeapList.count - 1 downto 0 do begin
		CurrentItem := ObjectToElement(WeapList.Objects[i]);
		MakeCraftable;
	end;
	WeapList.Free;
	for i := AMMOList.count - 1 downto 0 do begin
		CurrentItem := ObjectToElement(AMMOList.Objects[i]);
		MakeCraftable;
	end;
	AMMOList.Free;
end;

function CraftingFinal: integer;
begin
	CleanMasters(Patch);
	LogMessage(1,'---Craftable process ended---',YggLogCurrentMessages);
	AddMessage('---Craftable process ended---');
	LogMessage(0, 'Ended',YggLogCurrentMessages);
	Sign;
	LogMessage(0, 'Signed',YggLogCurrentMessages);
	Result := 0;
end;

procedure makeCraftable;
var
  recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems, keywords: IInterface;
  amountOfMainComponent, ki, amountOfAdditionalComponent, e: integer;
begin
	recipeCraft := FindRecipe(false,HashedList);
	if assigned(recipeCraft) then begin
		if optionAddOnly = 6 then begin
			remove(recipeCraft);
			exit(recipeCraft);
		end;
		if optionAddOnly = 7 then begin
			beginUpdate(recipeCraft);
			try
				for e := ElementCount(ElementByPath(recipeCraft, 'Items')) - 1 downto 0 do
				begin
					RemoveByIndex(ElementByPath(recipeCraft, 'Items'), e, false);
				end;
				for e := ElementCount(ElementByPath(recipeCraft, 'Conditions')) - 1 downto 0 do
				begin
					RemoveByIndex(ElementByPath(recipeCraft, 'Conditions'), e, false);
				end;
			finally endUpdate(recipeCraft);
			end;
		end;
	end;
	if not assigned(RecipeCraft) then begin
		recipeCraft := createRecord('COBJ');
		LogMessage(1,'No Recipe Found for: ' + Name(CurrentItem) + ' Generating new one',YggLogCurrentMessages);

		// add reference to the created object
		SetElementEditValues(recipeCraft, 'CNAM', Name(CurrentItem));
		// set Created Object Count
		SetElementEditValues(recipeCraft, 'NAM1', '1');
	end;
	//addmessage('checkpoint');
	//recipeCraft := FindCraftingRecipe;
	// add required items list
	Add(recipeCraft, 'items', true);
	// get reference to required items list inside recipe
	recipeItems := ElementByPath(recipeCraft, 'items');
	// trying to figure out propper requirements amount  
	if hasKeyword(CurrentItem, 'ArmorHeavy') then 
	begin //if it is heavy armor, base the amount of materials on the weight
		amountOfMainComponent := MaterialAmountHeavy(amountOfMainComponent, amountOfAdditionalComponent, recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems);
		amountOfAdditionalComponent := ceil(2);
		Keywords := ElementByPath(CurrentItem, 'KWDA');
		for ki := 0 to ElementCount(Keywords) do
		begin
			MatByKYWD(EditorID(LinksTo(ElementByIndex(Keywords, ki))), RecipeItems, AmountOfMainComponent);
		end;
	end else if hasKeyword(CurrentItem, 'ArmorLight') then 
	begin //Light armor is based on rating
		amountOfMainComponent := floor(StrToFloat(GetElementEditValues(CurrentItem, 'DNAM - Armor Rating')) * 0.2);
		amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfMainComponent < 1 then amountOfMainComponent := 1;
		if amountOfMainComponent > 10 then amountOfMainComponent := 10;
		if amountOfAdditionalComponent > 15 then amountOfAdditionalComponent := 15;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		Keywords := ElementByPath(CurrentItem, 'KWDA');
		for ki := 0 to ElementCount(Keywords) do
		begin
			MatByKYWD(EditorID(LinksTo(ElementByIndex(Keywords, ki))), RecipeItems, AmountOfMainComponent);
		end;
	end else if hasKeyword(CurrentItem, 'ArmorClothing') then 
	begin
	//uses -1.4ln(x/10)+10 for value to get amount 
		LogMessage(0,Name(CurrentItem) + ' is Clothing',YggLogCurrentMessages);
		if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Value')) < 42 then 
		begin
			amountOfMainComponent := 5;
		end else if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Value')) < 173 then 
		begin 
			amountOfMainComponent := 4;
		end else if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Value')) < 730 then
		begin 
			amountOfMainComponent := 3;
		end else if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Value')) < 3020 then 
		begin
			amountOfMainComponent := 2;
		end else if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Value')) > 3020 then amountOfMainComponent := 1;
		
		//uses -2.5ln(-x+51)+10 for weight to get a second amount and add to first. 
		if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Weight')) >= 50 then
		begin
			amountOfMainComponent := amountOfMainComponent + 5;
		end else if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Weight')) > 48 then
		begin
			amountOfMainComponent := amountOfMainComponent + 4;
		end else if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Weight')) > 46 then 
		begin
			amountOfMainComponent := amountOfMainComponent + 3;
		end else if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Weight')) > 40 then
		begin
			amountOfMainComponent := amountOfMainComponent + 2;
		end else if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Weight')) > 26 then
		begin
			amountOfMainComponent := amountOfMainComponent + 1;
		end else amountOfMainComponent := amountOfMainComponent + 0;
			amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfMainComponent < 1 then amountOfMainComponent := 1;
		
		Clothing(amountOfMainComponent, recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems);
	
	end else if hasKeyword(CurrentItem, 'ArmorJewelry') then
	begin 
		LogMessage(0,Name(CurrentItem) + ' is Jewelry',YggLogCurrentMessages);
		if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Value')) < 42 then 
		begin
			amountOfMainComponent := 5;
		end else if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Value')) < 173 then 
		begin 
			amountOfMainComponent := 4;
		end else if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Value')) < 730 then
		begin 
			amountOfMainComponent := 3;
		end else if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Value')) < 3020 then 
		begin
			amountOfMainComponent := 2;
		end else if StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Value')) > 3020 then amountOfMainComponent := 1;
			amountOfAdditionalComponent := floor(StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Weight')) * 0.2 / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfMainComponent < 1 then amountOfMainComponent := 1;
	
		addItem(recipeItems, getRecordByFormID('0005AD9E'), amountOfMainComponent); // gold
		Keywords := ElementByPath(CurrentItem, 'KWDA');
		for ki := 0 to ElementCount(Keywords) do
		begin
			MatByKYWD(EditorID(LinksTo(ElementByIndex(Keywords, ki))), RecipeItems, AmountOfMainComponent);
		end;
	end else begin
		AmountOfMainComponent := 3;
		AmountOfAdditionalComponent := 2;
		Keywords := ElementByPath(CurrentItem, 'KWDA');
		for ki := 0 to ElementCount(Keywords) do
		begin
			LogMessage(0, GetEditValue(ElementByIndex(Keywords, ki)),YggLogCurrentMessages);
			MatByKYWD(EditorID(LinksTo(ElementByIndex(Keywords, ki))), RecipeItems, AmountOfMainComponent);
		end;
	end;
		
	if hasKeyword(CurrentItem, 'Tailored') or hasKeyword(CurrentItem, 'ExtraMaterialCloth') then
	begin
		Clothing(amountOfAdditionalComponent, recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems);
	end;
	// set EditorID for recipe
	if pos('ARMO', signature(CurrentItem)) > 0 then SetElementEditValues(recipeCraft, 'EDID', 'RecipeArmor' + GetElementEditValues(CurrentItem, 'EDID'));
	if pos('AMMO', signature(CurrentItem)) > 0 then SetElementEditValues(recipeCraft, 'EDID', 'RecipeAmmo' + GetElementEditValues(CurrentItem, 'EDID'));
	if pos('WEAP', signature(CurrentItem)) > 0 then SetElementEditValues(recipeCraft, 'EDID', 'RecipeWeapon' + GetElementEditValues(CurrentItem, 'EDID'));

	// add reference to the workbench keyword
	Workbench(amountOfMainComponent, amountOfAdditionalComponent, recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems);
	
	if hasKeyword(CurrentItem, 'ArmorMaterialJeweled') then
		jeweled(amountOfMainComponent, amountOfAdditionalComponent, recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems);
	
	if Assigned(FileByName('Art Of Magicka Ygg Edition.esp')) then
		Dyed(amountOfAdditionalComponent, recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems);
	
	// remove nil record in items requirements, if any
	removeInvalidEntries(recipeCraft);

	if GetElementEditValues(recipeCraft, 'COCT') = '' then begin
		LogMessage(2,'no item requirements was specified for - ' + Name(CurrentItem),YggLogCurrentMessages);
		remove(recipeCraft);
		//addItem(recipeItems, getRecordByFormID('0005AD9E'), 10); // gold
	end	else if not assigned(ElementByPath(recipeCraft, 'COCT')) then begin
		LogMessage(2,'no item requirements was specified for - ' + Name(CurrentItem),YggLogCurrentMessages);
		remove(recipeCraft);
		//addItem(recipeItems, getRecordByFormID('0005AD9E'), 10); // gold
	end else if not assigned(ElementByPath(recipeCraft, 'Items')) then begin
		LogMessage(2,'no item requirements was specified for - ' + Name(CurrentItem),YggLogCurrentMessages);
		remove(recipeCraft);
		//addItem(recipeItems, getRecordByFormID('0005AD9E'), 10); // gold
	end else if ElementCount(ElementByPath(recipeCraft, 'Items')) < 1 then begin
		LogMessage(2,'no item requirements was specified for - ' + Name(CurrentItem),YggLogCurrentMessages);
		remove(recipeCraft);
		//addItem(recipeItems, getRecordByFormID('0005AD9E'), 10); // gold
	end;

  
end;

procedure makeBreakdown;
begin
	//make stuff uncraftable
	recipeCraft := FindRecipe(false,Breakdown);
	
end;

procedure makeTemper;
begin
	//make stuff temperable
	recipeCraft := FindRecipe(false,Temper);
end;

procedure CCORCompat;
begin
	
end;

function MaterialAmountHeavy(amountOfMainComponent, amountOfAdditionalComponent: integer; recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems: IInterface): integer;
var
	temp: Double;
begin
	temp := StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Weight'));
	if hasKeyword(CurrentItem, 'ArmorCuirass') then
	begin
		amountOfMainComponent := floor(temp * 0.3);
		if amountOfMainComponent < 10 then amountOfMainComponent := 10;
		if amountOfMainComponent > 15 then amountOfMainComponent := 15;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 5);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end else if hasKeyword(CurrentItem, 'ArmorBoots') then
	begin
		amountOfMainComponent := ceil(temp * 0.7);
		if amountOfMainComponent < 3 then amountOfMainComponent := 3;
		if amountOfMainComponent > 7 then amountOfMainComponent := 7;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end else if hasKeyword(CurrentItem, 'ArmorGauntlets') then
	begin
		amountOfMainComponent := floor(temp * 0.7);
		if amountOfMainComponent < 4 then amountOfMainComponent := 4;
		if amountOfMainComponent > 7 then amountOfMainComponent := 7;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end else if hasKeyword(CurrentItem, 'ArmorHelmet') then
	begin
		amountOfMainComponent := ceil(temp * 0.3);
		if amountOfMainComponent < 2 then amountOfMainComponent := 2;
		if amountOfMainComponent > 5 then amountOfMainComponent := 5;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end else if hasKeyword(CurrentItem, 'ArmorPants') then
	begin
		amountOfMainComponent := floor(temp * 0.7);
		if amountOfMainComponent < 3 then amountOfMainComponent := 3;
		if amountOfMainComponent > 8 then amountOfMainComponent := 8;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end else if hasKeyword(CurrentItem, 'ArmorUnderwear') then
	begin
		amountOfMainComponent := 1;
	end else if hasKeyword(CurrentItem, 'ArmorUnderwearTop') then
	begin
		amountOfMainComponent := 2;
	end else if hasKeyword(CurrentItem, 'ArmorShirt') then
	begin
		amountOfMainComponent := floor(temp * 0.7);
		if amountOfMainComponent < 3 then amountOfMainComponent := 3;
		if amountOfMainComponent > 8 then amountOfMainComponent := 8;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end else
	begin
		amountOfMainComponent := ceil(random(5));
		if amountOfMainComponent < 1 then amountOfMainComponent := 1;
		if amountOfMainComponent > 5 then amountOfMainComponent := 5;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end;
	result := amountOfMainComponent;
end;

function MaterialAmountLight(amountOfMainComponent, amountOfAdditionalComponent: integer; recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems: IInterface): integer;
var
	temp: double;
begin
	temp := StrToFloat(GetElementEditValues(CurrentItem, 'DATA\Weight'));
	if hasKeyword(CurrentItem, 'ArmorCuirass') then
	begin
		amountOfMainComponent := floor(temp * 0.3);
		if amountOfMainComponent < 10 then amountOfMainComponent := 10;
		if amountOfMainComponent > 15 then amountOfMainComponent := 15;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 5);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end else if hasKeyword(CurrentItem, 'ArmorBoots') then
	begin
		amountOfMainComponent := ceil(temp * 0.7);
		if amountOfMainComponent < 3 then amountOfMainComponent := 3;
		if amountOfMainComponent > 7 then amountOfMainComponent := 7;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end else if hasKeyword(CurrentItem, 'ArmorGauntlets') then
	begin
		amountOfMainComponent := floor(temp * 0.7);
		if amountOfMainComponent < 4 then amountOfMainComponent := 4;
		if amountOfMainComponent > 7 then amountOfMainComponent := 7;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end else if hasKeyword(CurrentItem, 'ArmorHelmet') then
	begin
		amountOfMainComponent := ceil(temp * 0.3);
		if amountOfMainComponent < 2 then amountOfMainComponent := 2;
		if amountOfMainComponent > 5 then amountOfMainComponent := 5;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end else if hasKeyword(CurrentItem, 'ArmorPants') then
	begin
		amountOfMainComponent := floor(temp * 0.7);
		if amountOfMainComponent < 3 then amountOfMainComponent := 3;
		if amountOfMainComponent > 8 then amountOfMainComponent := 8;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end else if hasKeyword(CurrentItem, 'ArmorUnderwear') then
	begin
		amountOfMainComponent := 1;
	end else if hasKeyword(CurrentItem, 'ArmorUnderwearTop') then
	begin
		amountOfMainComponent := 2;
	end else if hasKeyword(CurrentItem, 'ArmorShirt') then
	begin
		amountOfMainComponent := floor(temp * 0.7);
		if amountOfMainComponent < 3 then amountOfMainComponent := 3;
		if amountOfMainComponent > 8 then amountOfMainComponent := 8;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end else
	begin
		amountOfMainComponent := ceil(random(5));
		if amountOfMainComponent < 1 then amountOfMainComponent := 1;
		if amountOfMainComponent > 5 then amountOfMainComponent := 5;
		amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
		if amountOfAdditionalComponent < 1 then amountOfAdditionalComponent := 1;
		if amountOfAdditionalComponent > 3 then amountOfAdditionalComponent := 3;
		addItem(recipeItems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
		addItem(recipeItems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
	end;
	result := amountOfMainComponent;
end;

function Workbench(amountOfMainComponent, amountOfAdditionalComponent: integer; recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems: IInterface): IInterface;
begin
	if Assigned(FileByName('Tailoring Workbench.esp')) then
	begin
		if hasKeyword(CurrentItem, 'ArmorClothing') then
		begin
			SetElementEditValues(recipeCraft, 'BNAM', GetEditValue(MainRecordByEditorID(GroupBySignature(FileByName('Tailoring Workbench.esp'), 'KYWD'),'CraftingTailoring')));
		end else
		begin
			SetElementEditValues(recipeCraft, 'BNAM', GetEditValue(getRecordByFormID('00088105')));
		end;
	end else if Assigned(FileByName('Art Of Magicka Ygg Edition.esp')) then
	begin
		if isDyed then
		begin
			SetElementEditValues(recipeCraft, 'BNAM', GetEditValue(MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'KYWD'),'AOMFontIMBUEMENTkywd')));
		end;
	end else
	begin
		if signature(CurrentItem) = 'ARMO' then
		begin
			if HasKeyword(CurrentItem, 'ArmorClothing') then SetElementEditValues(recipeCraft, 'BNAM', GetEditValue(getRecordByFormID('0007866A'))) //tanning rack for clothing
			else SetElementEditValues(recipeCraft, 'BNAM', GetEditValue(getRecordByFormID('00088105'))); //forge
		end;
		if signature(CurrentItem) = 'AMMO' then SetElementEditValues(recipeCraft, 'BNAM', GetEditValue(getRecordByFormID('00088108'))); //Sharpening wheel
		if signature(CurrentItem) = 'WEAP' then SetElementEditValues(recipeCraft, 'BNAM', GetEditValue(getRecordByFormID('00088105'))); //forge
	end;
	LogMessage(0, 'Finished Tailoring',YggLogCurrentMessages);
end;

function Clothing(amountOfMainComponent: integer; recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems: IInterface): IInterface;
var
	count,ccount: integer;
begin
	count := ClothSplitCount(amountOfMainComponent);
	if not Assigned(FileByName('Art Of Magicka Ygg Edition.esp')) or count = 0 then begin
		addItem(recipeitems, getRecordByFormID('00034CD6'), amountOfMainComponent); // Cloth (linens)
		addItem(recipeitems, getRecordByFormID('000800E4'), floor(amountOfMainComponent / 3)); // leather strips
	end else 
	begin
		ccount := ceil(count/amountOfMainComponent);
		if hasKeyword(CurrentItem, 'ClothColorBlack') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenBLACK'), ccount); // black linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorBlue') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenBLUE'), ccount); // blue linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorGreen') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenGREEN'), ccount); // green linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorGray') or hasKeyword(CurrentItem, 'ClothColorGrey') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenGREY'), ccount); // gray linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorOrange') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenORANGE'), ccount); // orange linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorPink') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenPINK'), ccount); // pink linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorPurple') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenPURPLE'), ccount); // purple linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorYellow') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenYELLOW'), ccount); // yellow linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorRed') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenRED'), ccount); // red linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorWhite') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenWHITE'), ccount); // white linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorLightBlue') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenLIGHTBlue'), ccount); // light blue linens
		end;
		if hasKeyword(CurrentItem, 'AOMGhost') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenGHOST'), ccount); // ghost (see through) linens
		end;
		if hasKeyword(CurrentItem, 'ArmorMaterialLace') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenELEGANT'), ccount); // elegant linens (lace)
		end;
		if hasKeyword(CurrentItem, 'ClothColorLavender') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenLavender'), ccount); // lavender linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorBrown') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenBrown'), ccount); // Brown linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorBurgundy') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenBurgundy'), ccount); // Burgundy linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorDarkGray') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenDarkGray'), ccount); // Dark Gray linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorEmerald') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenEmerald'), ccount); // Emerald linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorForestGreen') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenForestGreen'), ccount); // Forest Green linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorLightGray') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenLightGray'), ccount); // Light Gray linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorMediumGray') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenMediumGray'), ccount); // Medium Gray linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorMintGreen') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenMintGreen'), ccount); // Mint Green linens
		end;
		if hasKeyword(CurrentItem, 'ClothColorTeal') then
		begin
			addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMlinenTeal'), ccount); // Teal linens
		end;
	end;
	LogMessage(0, 'Finished Clothing',YggLogCurrentMessages);
end;

function Dyed(amountOfAdditionalComponent: IInterface; recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems: IInterface): IInterface;
begin
	if hasKeyword(CurrentItem, 'DyeColorBlack') then
	begin
		addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMpigmentBLK'), amountOfAdditionalComponent); // black pigments
	end;
	if hasKeyword(CurrentItem, 'DyeColorBlue') then
	begin
		addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMpigmentBLU'), amountOfAdditionalComponent); // blue pigments
	end;
	if hasKeyword(CurrentItem, 'DyeColorGreen') then
	begin
		addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMpigmentGRN'), amountOfAdditionalComponent); // green pigments
	end;
	if hasKeyword(CurrentItem, 'DyeColorGray') or hasKeyword(CurrentItem, 'DyeColorGrey') then
	begin
		addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMpigmentBLKGRY'), amountOfAdditionalComponent); // gray pigments
	end;
	if hasKeyword(CurrentItem, 'DyeColorOrange') then
	begin
		addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMpigmentORN'), amountOfAdditionalComponent); // orange pigments
	end;
	if hasKeyword(CurrentItem, 'DyeColorPink') then
	begin
		addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMpigmentPNK'), amountOfAdditionalComponent); // pink pigments
	end;
	if hasKeyword(CurrentItem, 'DyeColorPurple') then
	begin
		addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMpigmentPUR'), amountOfAdditionalComponent); // purple pigments
	end;
	if hasKeyword(CurrentItem, 'DyeColorYellow') then
	begin
		addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMpigmentYEL'), amountOfAdditionalComponent); // yellow pigments
	end;
	if hasKeyword(CurrentItem, 'DyeColorRed') then
	begin
		addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMpigmentRED'), amountOfAdditionalComponent); // red pigments
	end;
	if hasKeyword(CurrentItem, 'DyeColorWhite') then
	begin
		addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMpigmentWHT'), amountOfAdditionalComponent); // white pigments
	end;
	if hasKeyword(CurrentItem, 'DyeColorLightBlue') then
	begin
		addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('Art Of Magicka Ygg Edition.esp'), 'MISC'),'AOMpigmentBLUlite'), amountOfAdditionalComponent); // light blue pigments
	end;
	LogMessage(0, 'Finished Dyeing',YggLogCurrentMessages);
end;

function Jeweled(amountOfMainComponent, amountOfAdditionalComponent: IInterface; recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems: IInterface): IInterface;
begin
	LogMessage(0,'jeweled stuff',YggLogCurrentMessages);
	if hasKeyword(CurrentItem, 'TGCMLGemstones') then
	begin
		//AddMasterIfMissing(GetFile(CurrentItem), 'thegemstonecollector.esp');
		if hasKeyword(CurrentItem, 'GemColorBlack') then
		begin
			AddMessage(Name(recipeCraft) + ' has black gemstones from TGCML adding master if missing');
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGemCut291OpalBlack'), 1); // Cut Opal
				AddMessage('Cut Opal was added, change if you want');
			end else
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem033OnyxBlack'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem071MoonstoneBlack'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem073MarbleBlack'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem291OpalBlack'), 1); //onyx
				AddMessage('Onyx, black moonstone, black marble, and black opal were added, change if you want');
			end;
		end;	
		if hasKeyword(CurrentItem, 'GemColorBlue') then
		AddMessage(Name(recipeCraft) + ' has Blue gemstones from TGCML adding master if missing');
		begin
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGemCut055QuartzBlue'), 1); // Cut Opal
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGemCut211MoonstoneBlueSheen'), 1); // Cut Opal
				AddMessage('Blue quartz, and Blue Moonstone were added, change if you want');
			end else
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem048CoralBlue'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem055QuartzBlue'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem063AgateBlueLace'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem087ChalcedonyBlue'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem144SapphireBlue'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem145TopazBlue'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem169ObsidianBlue'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem195ZirconBlue'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem211MoonstoneBlueSheen'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem251AmberBlue'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem298GarnetBlue'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem702GoldstoneBlue'), 1); //onyx
				AddMessage('Blue Coral, Blue Quartz, Blue lace Agate, Blue Chalcedony, Blue Sapphire, Blue Topaz, Blue Obsidian, Blue Zircon, Blue Moonstone, Blue amber, Blue Garnet, and Blue Goldstone were added, change if you want');
			end;
		end;
		if hasKeyword(CurrentItem, 'GemColorGreen') then
		begin
			AddMessage(Name(recipeCraft) + ' has Green gemstones from TGCML adding master if missing');
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem401EmeraldTrapiche'), 1); // Cut Opal
				AddMessage('Cut Opal was added, change if you want');
			end else
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem023OnyxGreen'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem036CalciteGreen'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem183SapphireGreen'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem703GoldstoneGreen'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem806JasperGreen'), 1); //onyx
				AddMessage('Onyx was added, change if you want');
			end;
		end;
		if hasKeyword(CurrentItem, 'GemColorGrey') or hasKeyword(CurrentItem, 'GemColorGray') then
		begin
			AddMessage(Name(recipeCraft) + ' has black gemstones from TGCML adding master if missing');
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem506MoonstoneStar'), 1); // Cut Opal
				AddMessage('Cut Opal was added, change if you want');
			end else
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGemCut211MoonstoneBlueSheen'), 1); //onyx
				AddMessage('Onyx was added, change if you want');
			end;
		end;
		if hasKeyword(CurrentItem, 'GemColorOrange') then
		begin
			AddMessage(Name(recipeCraft) + ' has black gemstones from TGCML adding master if missing');
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGemCut198TopazImperial'), 1); // Cut Opal
				AddMessage('Cut Opal was added, change if you want');
			end else
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem035CalciteOrange'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem118SapphireOrange'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem198TopazImperial'), 1); //onyx
				AddMessage('Onyx was added, change if you want');
			end;
		end;
		if hasKeyword(CurrentItem, 'GemColorPink') then
		begin
			AddMessage(Name(recipeCraft) + ' has black gemstones from TGCML adding master if missing');
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGemCut021QuartzRose'), 1); // Cut Opal
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem507QuartzRoseStar'), 1); // Cut Opal
				AddMessage('Cut Opal was added, change if you want');
			end else
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem137SapphirePink'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem213TanzanitePink'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem021QuartzRose'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem208Roselite'), 1); //onyx
				AddMessage('Onyx was added, change if you want');
			end;
		end;
		if hasKeyword(CurrentItem, 'GemColorPurple') then
		begin
			AddMessage(Name(recipeCraft) + ' has black gemstones from TGCML adding master if missing');
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'GemAmethystFlawless'), 1); // Cut Opal
				AddMessage('Cut Opal was added, change if you want');
			end else
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem030Amethyst'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem819JasperPurple'), 1); //onyx
				AddMessage('Onyx was added, change if you want');
			end;
		end;
		if hasKeyword(CurrentItem, 'GemColorRed') then
		begin
			AddMessage(Name(recipeCraft) + ' has black gemstones from TGCML adding master if missing');
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem402RubyTrapiche'), 1); // Cut Opal
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem501RubyStar'), 1); // Cut Opal
				AddMessage('Cut Opal was added, change if you want');
			end else
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem151CoralRed'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem293EmeraldRed'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem299DiamondRed'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem172Ruby'), 1); //onyx
				AddMessage('Onyx was added, change if you want');
			end;
		end;
		if hasKeyword(CurrentItem, 'GemColorWhite') then
		begin
			AddMessage(Name(recipeCraft) + ' has black gemstones from TGCML adding master if missing');
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'GemDiamondFlawless'), 1); // Cut Opal
				AddMessage('Cut Opal was added, change if you want');
			end else
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem199Diamond'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem214SapphireWhite'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem072OpalWhite'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem019CoralWhite'), 1); //onyx
				AddMessage('Onyx was added, change if you want');
			end;
		end;
		if hasKeyword(CurrentItem, 'GemColorYellow') then
		begin
			AddMessage(Name(recipeCraft) + ' has black gemstones from TGCML adding master if missing');
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem503ChrysoberylStar'), 1); // Cut Opal
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGemCut175Citrine'), 1); // Cut Opal
				AddMessage('Cut Opal was added, change if you want');
			end else
			begin
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem082Zircon'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem175Citrine'), 1); //onyx
				addItem(recipeitems, MainRecordByEditorID(GroupBySignature(FileByName('thegemstonecollector.esp'), 'MISC'),'TGSCGem132SapphireYellow'), 1); //onyx
				AddMessage('Onyx was added, change if you want');
			end;
		end;
			AddMessage(Name(recipeCraft) + ' has black gemstones from TGCML adding master if missing');
	end else
	begin
		if hasKeyword(CurrentItem, 'GemColorBlack') then
		begin
			AddMessage('the game has a copper and onyx circlet, good luck finding the onyx');
		end;
		if hasKeyword(CurrentItem, 'GemColorBlue') then
		begin
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
			begin
				addItem(recipeitems, getRecordByFormID('00068523'), 1);
				end else
			begin
				addItem(recipeitems, getRecordByFormID('00063B44'), 1);
			end;
		end;
		if hasKeyword(CurrentItem, 'GemColorGreen') then
		begin
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
			begin
				addItem(recipeitems, getRecordByFormID('00068520'), 1);
			end else
			begin
				addItem(recipeitems, getRecordByFormID('00063B42'), 1);
			end;
		end;
			if hasKeyword(CurrentItem, 'GemColorGrey') then
			begin
				AddMessage('the game has a copper and onyx circlet, good luck finding the onyx');
			end;
			if hasKeyword(CurrentItem, 'GemColorOrange') then
			begin
				AddMessage('Maybe Ruby, but then it duplicates.');
			end;
			if hasKeyword(CurrentItem, 'GemColorPink') then
			begin
				AddMessage('Would Coral Work? there is a coral claw, but no coral gemstone.');
			end;
			if hasKeyword(CurrentItem, 'GemColorPurple') then
			begin
				if hasKeyword(CurrentItem, 'JewelryExpensive') then
				begin
					addItem(recipeitems, getRecordByFormID('0006851E'), 1);
				end else
				begin
					addItem(recipeitems, getRecordByFormID('00063B46'), 1);
				end;
			end;
			if hasKeyword(CurrentItem, 'GemColorRed') then
			begin
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
				begin
				addItem(recipeitems, getRecordByFormID('00068522'), 1);
				addItem(recipeitems, getRecordByFormID('00068521'), 1);
				end else
			begin
				addItem(recipeitems, getRecordByFormID('00063B42'), 1);
				addItem(recipeitems, getRecordByFormID('00063B45'), 1);
			end;
		end;
		if hasKeyword(CurrentItem, 'GemColorWhite') then
		begin
			if hasKeyword(CurrentItem, 'JewelryExpensive') then
			begin
				addItem(recipeitems, getRecordByFormID('0006851F'), 1);
			end else
			begin
				addItem(recipeitems, getRecordByFormID('00063B47'), 1);
			end;
		end;
	end;
	if hasKeyword(CurrentItem, 'GemColorYellow') then
	begin
		LogMessage(0,'Maybe I should just use gold?',YggLogCurrentMessages);
	end;
	LogMessage(0, 'Finished Jeweled Armor',YggLogCurrentMessages);
end;

function Jewelry(amountOfMainComponent, amountOfAdditionalComponent: IInterface; recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeItems: IInterface): IInterface;
begin
	
end;

function isDyed: boolean;
begin
	if hasKeyword(CurrentItem, 'dyeColorBlack') then result := true;
	if hasKeyword(CurrentItem, 'dyeColorBlue') then result := true;
	if hasKeyword(CurrentItem, 'dyeColorGray') then result := true;
	if hasKeyword(CurrentItem, 'dyeColorGreen') then result := true;
	if hasKeyword(CurrentItem, 'dyeColorGrey') then result := true;
	if hasKeyword(CurrentItem, 'dyeColorLightBlue') then result := true;
	if hasKeyword(CurrentItem, 'dyeColorOrange') then result := true;
	if hasKeyword(CurrentItem, 'dyeColorPink') then result := true;
	if hasKeyword(CurrentItem, 'dyeColorPurple') then result := true;
	if hasKeyword(CurrentItem, 'dyeColorRed') then result := true;
	if hasKeyword(CurrentItem, 'dyeColorWhite') then result := true;
	if hasKeyword(CurrentItem, 'dyeColorYellow') then result := true;
end;

function ClothSplitCount(ComponentAmount: IInterface): integer;
var
	count: integer;
begin
	count := 0;

	if hasKeyword(CurrentItem, 'ClothColorBlack') then count := count + 1;
	
	if hasKeyword(CurrentItem, 'ClothColorBlue') then	count := count + 1;
	if hasKeyword(CurrentItem, 'ClothColorGreen') then count := count + 1;
	if hasKeyword(CurrentItem, 'ClothColorGray') or hasKeyword(CurrentItem, 'ClothColorGrey') then count := count + 1;
	if hasKeyword(CurrentItem, 'ClothColorOrange') then count := count + 1;
	if hasKeyword(CurrentItem, 'ClothColorPink') then count := count + 1;
	if hasKeyword(CurrentItem, 'ClothColorPurple') then count := count + 1;
	if hasKeyword(CurrentItem, 'ClothColorYellow') then count := count + 1;
	if hasKeyword(CurrentItem, 'ClothColorRed') then count := count + 1;
	if hasKeyword(CurrentItem, 'ClothColorWhite') then count := count + 1;
	if hasKeyword(CurrentItem, 'ClothColorLightBlue') then count := count + 1;
	if hasKeyword(CurrentItem, 'AOMGhost') then count := count + 1;
	if hasKeyword(CurrentItem, 'ArmorMaterialLace') then
	begin
		count := count + 1;
	end;
	if hasKeyword(CurrentItem, 'ClothColorLavender') then
	begin
		count := count + 1;
	end;
	if hasKeyword(CurrentItem, 'ClothColorBurgundy') then
	begin
		count := count + 1;
	end;
	if hasKeyword(CurrentItem, 'ClothColorBrown') then
	begin
		count := count + 1;
	end;
	if hasKeyword(CurrentItem, 'ClothColorTeal') then
	begin
		count := count + 1;
	end;
	if hasKeyword(CurrentItem, 'ClothColorLightGray') then
	begin
		count := count + 1;
	end;
	if hasKeyword(CurrentItem, 'ClothColorMediumGray') then
	begin
		count := count + 1;
	end;
	if hasKeyword(CurrentItem, 'ClothColorDarkGray') then
	begin
		count := count + 1;
	end;
	if hasKeyword(CurrentItem, 'ClothColorMintGreen') then
	begin
		count := count + 1;
	end;
	if hasKeyword(CurrentItem, 'ClothColorForestGreen') then
	begin
		count := count + 1;
	end;
	if hasKeyword(CurrentItem, 'ClothColorEmerald') then
	begin
		count := count + 1;
	end;
	result := count;
end;

function FindRecipe(Create: boolean; List:TStringList): IInterface;
var
	recipeCraft: IInterface;
begin
	if List.IndexOf(LowerCase(EditorID(WinningOverride(CurrentItem)))) >= 0 then
	begin
		result := wbCopyElementToFile(ObjectToElement(List.Objects[List.IndexOf(EditorID(CurrentItem))]), Patch, false, true);
	end else
	begin
		if create then
		begin
			recipeCraft := createRecord('COBJ');
			LogMessage(0, 'No Recipe Found',YggLogCurrentMessages);

			// add reference to the created object
			SetElementEditValues(recipeCraft, 'CNAM', Name(CurrentItem));
			// set Created Object Count
			SetElementEditValues(recipeCraft, 'NAM1', '1');
			Result := recipeCraft;
		end;
	end;
end;

function InitializeRecipes: integer;
var
	f, r: integer;
	BNAM, currentFile, CurrentGroup, CurrentItem: IInterface;
	StationEDID,temp: string;
begin
	Recipes := TStringList.Create;
	Recipes.Duplicates := dupIgnore;
	Recipes.Sorted;
	Temper := TStringList.Create;
	Temper.Duplicates := dupIgnore;
	Temper.Sorted;
	Breakdown := TStringList.Create;
	Breakdown.Duplicates := dupIgnore;
	Breakdown.Sorted;
	
	for f := FileCount - 1 downto 0 do
	begin
		currentFile := FileByIndex(f);
		if HasGroup(currentFile, 'COBJ') then
		begin
			CurrentGroup := GroupBySignature(currentFile, 'COBJ');
			for r := ElementCount(CurrentGroup) - 1 downto 0 do
			begin
				CurrentItem := ElementByIndex(CurrentGroup, r);
				BNAM := LinksTo(ElementByPath(CurrentItem, 'BNAM'));
				temp := LowerCase(EditorID(WinningOverride(LinksTo(ElementByPath(CurrentItem, 'CNAM')))));
				StationEDID := LowerCase(EditorID(BNAM));
				if IsWinningOverride(CurrentItem) then
				begin
					if not (ContainsText(StationEDID,'armortable')) and 
						not (ContainsText(StationEDID,'sharpening')) and 
						(not (ContainsText(StationEDID,'forge')) 
							OR (ContainsText(StationEDID,'skyforge'))) and 
						not (ContainsText(StationEDID,'cook')) then 
							Recipes.AddObject(temp, CurrentItem)
					else if ContainsText(StationEDID, 'sharpening') or ContainsText(StationEDID, 'armortable') then
						Temper.AddObject(temp, CurrentItem)
					else if (StationEDID = 'Smelter') then begin
						Items := ElementByPath(CurrentItem, 'Items');
						for i := ElementCount(Items) - 1 downto 0 do begin
							Item := WinningOverride(LinksTo(ElementByPath(ElementByIndex(Items, i), 'CNTO\Item')));
							sigItem := Signature(Item);
							if sigItem = 'ARMO' or sigItem = 'WEAP' or sigItem = 'AMMO' then
								Breakdown.AddObject(LowerCase(EditorID(Item)), CurrentItem);
						end;
					end;
				end;
			end;
		end else
		begin
			continue;
		end;
	end;
	HashedList := THashedStringList.Create;
	HashedList.Assign(Recipes);
end;

function MaterialListPrinter(CurrentKYWDName: string): integer;
var
	ValidSignatures, perks, Output, Input, TempList, tempperklist: TStringList;
	EDID,TempSig, PEDID: String;
	item, cc, perk, CurrentKYWD, CurrentItem, CurrentReference, ConPath: IInterface;
	itemIndex, RecipeCount, k, a, i, l, p, LimitIndex: Integer;
	y, amount, limit: double;
	perkcheck: boolean;
	perkcounter: integer;
begin
	ValidSignatures := TStringList.Create;
	ValidSignatures.DelimitedText := 'AMMO,ARMO,WEAP,SLGM';
	input := TStringList.Create;
	Output := TStringList.Create;
	perks := TStringList.Create;
	//tempperklist := TStringList.Create;
	CurrentKYWD := TrueRecordByEDID(CurrentKYWDName);
	if not Assigned(CurrentKYWD) then exit;
	RecipeCount := 0;
	for k := referencedByCount(CurrentKYWD) - 1 downto 0 do
	begin
		LogMessage(0, 'Cycle ' + IntToStr(k),YggLogCurrentMessages);
		CurrentItem := ReferencedByIndex(CurrentKYWD, k);
		TempSig := Signature(CurrentItem);
		if ValidSignatures.IndexOf(TempSig) < 0 then continue;
		if IntToStr(GetElementNativeValues(CurrentItem, 'DATA\Flags\Non-Playable')) < 0 then continue;
		if IntToStr(GetElementNativeValues(CurrentItem, 'Record Header\Record Flags\Non-Playable')) < 0 then exit;
		if GetElementNativeValues(CurrentItem, 'EITM') > 0 then continue;
		LogMessage(0, 'Passed Signature',YggLogCurrentMessages);
		for a := ReferencedByCount(CurrentItem) - 1 downto 0 do
		begin
			LogMessage(0, 'Recipe Search ' + IntToStr(a),YggLogCurrentMessages);
			CurrentReference := ReferencedByIndex(CurrentItem, a);
			if not pos('COBJ', signature(CurrentReference)) > 0 then continue;
			LogMessage(0, 'it is a recipe',YggLogCurrentMessages);
			if not equals(CurrentItem, LinksTo(ElementByPath(CurrentReference, 'CNAM'))) then continue;
			LogMessage(0, 'output is the same',YggLogCurrentMessages);
			if GetLoadOrderFormID(LinksTo(ElementByPath(CurrentReference, 'BNAM'))) = $000ADB78 then continue;
			if GetLoadOrderFormID(LinksTo(ElementByPath(CurrentReference, 'BNAM'))) = $00088108 then continue;
			if not IsWinningOverride(CurrentReference) then continue;
			if length(GetElementEditValues(CurrentReference, 'COCT')) = 0 then continue
			else l := tryStrToInt(GetElementEditValues(CurrentReference, 'COCT'), 0) - 1;
			LogMessage(0, 'standard recipe limitations',YggLogCurrentMessages);
			for i := l downto 0 do
			begin
				TempList := TStringList.Create;
				item := LinksTo(ElementByIndex(ElementByIndex(ElementByIndex(ElementByPath(CurrentReference, 'Items'), i), 0), 0));
				if ValidSignatures.IndexOf(signature(item)) >= 0 then continue;
				EDID := EditorID(item);
				ItemIndex := Input.IndexOf(EDID);
				LogMessage(0, IntToStr(TempList.Count),YggLogCurrentMessages);
				if ItemIndex < 0 then 
				begin
					TempList.Add(EDID);
					TempList.Add(IntToStr(1));
					TempList.Add(IntToStr(1));
					TempList.Objects[0] := item;
					ItemIndex := Input.AddObject(EDID, TempList);
				end else TempList.Assign(Input.Objects[ItemIndex]);
				TempList.strings[1] := IntToStr(tryStrToInt(TempList.strings[1], 0) + 1);
				TempList.strings[2] := IntToStr(tryStrToInt(TempList.strings[2], 0) + GetEditValue(ElementByIndex(ElementByIndex(ElementByIndex(ElementByPath(CurrentReference, 'Items'), i), 0), 1))); 
				Input.Objects[ItemIndex] := TempList;
			end;
			{ConPath := ElementByPath(CurrentReference, 'Conditions');
			if not Assigned(ConPath) then continue;
			for i := ElementCount(ConPath) downto 0 do
			begin
				cc := ElementByPath(ElementByIndex(ConPath, i), 'CTDA');
				Logmessage(0,EditorID(LinksTo(ElementByPath(ElementByPath(ElementByIndex(ElementByPath(CurrentReference, 'Conditions'), 1), 'CTDA'), 'Perk'))),YggLogCurrentMessages);
				if not pos('HasPerk', GetEditValue(ElementByPath(CC, 'Function'))) > 0 then continue;
				Perk := LinksTo(ElementByPath(cc, 'Perk'));
				if not assigned(Perk) then continue;
				PEDID := EditorID(Perk);
				ItemIndex := Perks.IndexOf(PEDID);
				if ItemIndex < 0 then 
				begin
					tempperklist.add(EditorID(Perk));
					tempperklist.add(IntToStr(1));
					tempperklist.strings[1] := IntToStr(1);
					tempperklist.Objects[0] := Perk;
					ItemIndex := Perks.AddObject(PEDID, tempperklist);
				end;
				tempperklist.Assign(Perks.Objects[itemIndex]);
				tempperklist.strings[1] := IntToStr(TryStrToInt(tempperklist.strings[1], 0) + 1);
				perks.objects[itemIndex] := tempperklist;
			end;}
			RecipeCount := RecipeCount + 1;
		end;
	end;
	Limit := 0;
	for a := Input.Count - 1 downto 0 do
	begin
		TempList := input.objects[a];
		if length(TempList.strings[1]) = 0 then 
		begin
			input.Delete[a];
			continue;
		end;
		if length(TempList.Strings[2]) = 0 then
		begin
			input.Delete[a];
			continue;
		end;
		if tryStrToInt(TempList.strings[1], 0) < (recipeCount / 2) then input.Delete(a);
		if not tryStrToFloat(tryStrToInt(TempList.Strings[1], 0) / tryStrToInt(TempList.strings[2], 1), 1) > Limit then continue;
		Limit := tryStrToInt(TempList.Strings[1], 0) / tryStrToInt(TempList.Strings[2], 1);
		LimitIndex := a;
	end;
	if limit > 0 then y := 1 / limit
	else y := 1;
	
	
	{if perks.count > 0 then
	begin
		for a := perks.count - 1 downto 0 do
		begin
			tempperklist := perks.objects[a];
			if length(tempperklist.strings[0]) = 0 then continue;
			if not assigned(ObjectToElement(tempperklist.objects[0])) then continue;
			if length(tempperklist.strings[1]) = 0 then continue;
			if not tryStrToInt(tempperklist.strings[1], 0) > (recipecount * 0.25) then continue;
			if tempperklist.strings[1] > perkcounter then perkcounter := a;
		end;
		tempperklist := perks.objects[perkcounter];
		output.add('p:' + GetFileName(GetFile(ObjectToElement(tempperklist.Objects[0]))) + '|' + tempperklist.Strings[0]);
	end;}

	for a := input.count - 1 downto 0 do
	begin
		TempList := input.objects[a];
		if TempList.count < 0 then continue;
		item := ObjectToElement(TempList.Objects[0]);
		Edid := TempList.strings[0];
		if tryStrToInt(TempList.Strings[2], 0) > 0 then
		amount := StrToFloat(TempList.Strings[1]) / StrToFloat(TempList.Strings[2])
		else continue;
		if amount = 0.0 then continue;
		output.add('i' + signature(item) + ':' + GetFileName(GetFile(MasterOrSelf(item))) + '|' + EDID + '=' + FloatToStr(Amount * y));
	end;
	if ContainsText('Clothing',CurrentKYWDName) then begin
		if output.length < 1 then
		begin
			output.add('iMISC:Skyrim.esm|RuinsLinenPile01=1.0');
		end;
	end;
	input.free;
	perks.free;
	ini.WriteString('Crafting', CurrentKYWDName, output.commatext);
	ini.UpdateFile;
	output.free;
end;

function IniToMatList: integer;
var
	i, t, f, as, MLI: integer;
	cs, cg, cf, ce, ca: string;
	MaterialsSublist, TempList: TStringList;
	item: IInterface;
begin
	for MLI := MaterialList.Count - 1 downto 0 do
	begin
		TempList := TStringList.Create;
		MaterialsSublist := TStringList.Create;
		TempList.DelimitedText := Ini.ReadString('Crafting', MaterialList.strings[MLI], '');
		for i := TempList.count - 1 downto 0 do
		begin
			cs := TempList.Strings[i];
			t := pos(':', cs);
			f := pos('|', cs);
			as := pos('=', cs);
			if copy(cs, 0, 1) = 'i' then
			begin
				cg := UpperCase(Copy(cs, 2, 4));
				cf := copy(cs, t+1, f-t-1);
				ce := copy(cs, f+1, as-f-1);
				ca := copy(cs, as+1, length(cs) - as);
				item := MainRecordByEditorID(GroupBySignature(FileByName(cf), cg), ce);
				LogMessage(0, 'IniToMatList: ' + cg + ' ' + cf + ' ' + ce + ' ' + ca,YggLogCurrentMessages);
				MaterialsSublist.AddObject(ca, item);
				LogMessage(0, 'IniToMatList: ' + FloatToStr(ca) + EditorID(item) + ' ' + EditorID(ObjectToElement(MaterialsSublist.Objects[MaterialsSublist.IndexOf(ca)])),YggLogCurrentMessages);
			end else if pos('p', copy(cs, 0, 1)) = 0 then
			begin
				cf := copy(cs, t+1,f-1);
				ce := copy(cs,f+1,length(cs) - 1);
				//MaterialsSublist.AddObject('Perk', MainRecordByEditorID(GroupBySignature(FileByName(cf), 'PERK'), ce));
				MaterialsSublist.AddObject('Perk', RecordByEDID(FileByName(cf), ce));
				LogMessage(1, 'IniToMatList: ' + EditorID(item) + ' ' + EditorID(ObjectToElement(MaterialsSublist.Objects[MaterialsSublist.IndexOf(ca)])),YggLogCurrentMessages);
			end;
		end;
		MaterialList.objects[MLI] := MaterialsSublist;
		//MaterialList.Objects[MLI] := TempList;
	end;
end;

function MatByKYWD(Keyword: String; RecipeItems: IInterface; AmountOfMainComponent: integer): integer;
var
	CurrentMaterials: IInterface;
	a: integer;
begin
	if MaterialList.IndexOf(keyword) < 0 then exit;
	LogMessage(0, 'work',YggLogCurrentMessages);
	CurrentMaterials := MaterialList.Objects[MaterialList.IndexOf(keyword)];
	for a := CurrentMaterials.count - 1 downto 0 do
	begin
		LogMessage(0, 'work 2',YggLogCurrentMessages);
		if pos('Perk', CurrentMaterials.strings[a]) > 0 then
		begin
			LogMessage(0, 'work 3 perk',YggLogCurrentMessages);
			//AddPerkCondition(recipeitems, ObjectToElement(CurrentMaterials.Objects[a]));
		end else
		begin
			LogMessage(1,'MatByKYWD: '+Name(ObjectToElement(CurrentMaterials.objects[a])),YggLogCurrentMessages);
			AddItem(RecipeItems, ObjectToElement(CurrentMaterials.objects[a]), ceil(StrToFloat(CurrentMaterials.strings[a]) * AmountOfMainComponent * (random(1) + CraftMult)));
		end;
		tempPerkFunction(Keyword, RecipeItems, AmountOfMainComponent);
	end;
end;

function tempPerkFunction(Keyword: String; RecipeItems: IInterface; AmountOfMainComponent: integer): integer;
var
	CurrentMaterials: IInterface;
	a: integer;
begin
	if TempPerkListExtra.IndexOf(Keyword) < 0 then exit;
	AddPerkCondition(recipeitems, ObjectToElement(TempPerkListExtra.Objects[TempPerkListExtra.IndexOf(Keyword)]));
end;

procedure tempPerkFunctionSetup;
begin
	TempPerkListExtra := TStringList.Create;
	TempPerkListExtra.sorted := true;
	TempPerkListExtra.duplicates := dupIgnore;
	TempPerkListExtra.AddObject('ArmorMaterialDragonscale', getRecordByFormID('00052190'));
	TempPerkListExtra.AddObject('ArmorMaterialDragonplate', getRecordByFormID('00052190'));
	TempPerkListExtra.AddObject('ArmorMaterialDaedric', getRecordByFormID('000CB413'));
	TempPerkListExtra.AddObject('ArmorMaterialDwarven', getRecordByFormID('000CB40E'));
	TempPerkListExtra.AddObject('ArmorMaterialEbony', getRecordByFormID('000CB412'));
	TempPerkListExtra.AddObject('ArmorMaterialElven', getRecordByFormID('000CB40F'));
	TempPerkListExtra.AddObject('ArmorMaterialElvenGilded', getRecordByFormID('000CB40F'));
	TempPerkListExtra.AddObject('ArmorMaterialBonemoldHeavy', getRecordByFormID('000CB40D'));
	TempPerkListExtra.AddObject('DLC2ArmorMaterialBonemoldHeavy', getRecordByFormID('000CB40D'));
	TempPerkListExtra.AddObject('ArmorMaterialGlass', getRecordByFormID('000CB411'));
	TempPerkListExtra.AddObject('ArmorMaterialImperialHeavy', getRecordByFormID('000CB40D'));
	TempPerkListExtra.AddObject('ArmorMaterialOrcish', getRecordByFormID('000CB410'));
	TempPerkListExtra.AddObject('ArmorMaterialScaled', getRecordByFormID('000CB414'));
	TempPerkListExtra.AddObject('ArmorMaterialSteel', getRecordByFormID('000CB40D'));
	TempPerkListExtra.AddObject('ArmorMaterialSteelPlate', getRecordByFormID('000CB414'));
	TempPerkListExtra.AddObject('ArmorMaterialNordicHeavy', getRecordByFormID('000CB414'));
	TempPerkListExtra.AddObject('DLC2ArmorMaterialNordicHeavy', getRecordByFormID('000CB414'));
	TempPerkListExtra.AddObject('ArmorMaterialStalhrimHeavy', getRecordByFormID('000CB412'));
	TempPerkListExtra.AddObject('DLC2ArmorMaterialStalhrimHeavy', getRecordByFormID('000CB412'));
	TempPerkListExtra.AddObject('ArmorMaterialStalhrimLight', getRecordByFormID('000CB412'));
	TempPerkListExtra.AddObject('DLC2ArmorMaterialStalhrimLight', getRecordByFormID('000CB412'));
	TempPerkListExtra.AddObject('ArmorMaterialBonemoldHeavy2', getRecordByFormID('000CB40D'));
	TempPerkListExtra.AddObject('ArmorMaterialChitinHeavy', getRecordByFormID('000CB40F'));
	TempPerkListExtra.AddObject('DLC2ArmorMaterialChitinHeavy', getRecordByFormID('000CB40F'));
	TempPerkListExtra.AddObject('ArmorMaterialChitinLight', getRecordByFormID('000CB40F'));
	TempPerkListExtra.AddObject('DLC2ArmorMaterialChitinLight', getRecordByFormID('000CB40F'));
end;

function GatherMaterials: integer;
var
	TempList: TStringList;
	FileIndex, GroupIndex, f: integer;
	CurrentFile, CurrentGroup, CurrentKYWD: IInterface;
begin
	MaterialList := TStringList.Create;
	MaterialList.Sorted := true;
	MaterialList.Duplicates := dupIgnore;
	MaterialList.NameValueSeparator := ';';
	for FileIndex := 0 to FileCount - 1 do
	begin
		CurrentFile := FileByIndex(FileIndex);
		if HasGroup(CurrentFile, 'KYWD') then
		begin
			CurrentGroup := GroupBySignature(CurrentFile, 'KYWD');
			for GroupIndex := 0 to ElementCount(CurrentGroup) - 1 do
			begin
				CurrentKYWD := EditorID(ElementByIndex(CurrentGroup, GroupIndex));
				if pos('material', LowerCase(CurrentKYWD)) > 0 then
				begin
					MaterialList.Add(CurrentKYWD);
				end else if pos('materiel', LowerCase(CurrentKYWD)) > 0 then
				begin
					MaterialList.Add(CurrentKYWD);
				end else if pos('clothing', LowerCase(CurrentKYWD)) > 0 then 
				begin
					MaterialList.Add(CurrentKYWD);
				end;
			end;
		end;
	end;
	TempList := TStringList.Create;
	TempList.DelimitedText := Ini.ReadString('Crafting', 'sKYWDList', '');
	if firstRun then
	begin
		for f := 0 to TempList.count - 1 do
		begin
			MaterialListPrinter(TempList.strings[f]);
		end;
	end;
	for f := MaterialList.count - 1 downto 0 do
	begin
		if TempList.indexof(MaterialList.strings[f]) < 0 then MaterialListPrinter(MaterialList.strings[f]);
	end;
	MaterialList.AddStrings(TempList);
	TempList.Free;
	TempList.Clear;
	Ini.WriteString('Crafting', 'sKYWDList', MaterialList.CommaText);
	Ini.UpdateFile;
	IniToMatList;
end;

end.