unit yggKeywording;
uses YggFunctions;

var
	Patch: IInterface;
	itemRecord: IInterface;
	PossibleList:TStringList;
	

function Initialize: integer;
var
	MaterialList: TStringList;
	CurrentFile, CurrentGroup, CurrentKYWD: IInterface;
	temp: String;
	f,g: integer;
begin
	AddMessage('---Labels break down society, and at the same time the build it up again---');
	Patch := SelectPatch('Ygg_Rekeywords.esp');
	PassFile(Patch);
	BeginUpdate(Patch);
	try
	AddMasterBySignature('ARMO');
	AddMasterBySignature('WEAP');
	AddMasterBySignature('AMMO');
	finally EndUpdate(Patch);
	end;
	MaterialList := TStringList.Create;
	for f := 0 to FileCount - 1 do 
	begin
		CurrentFile := FileByIndex(f);
		if HasGroup(CurrentFile, 'KYWD') then
		begin
			CurrentGroup := GroupBySignature(CurrentFile, 'KYWD');
			for g := 0 to ElementCount(CurrentGroup) - 1 do
			begin
				CurrentKYWD := ElementByIndex(CurrentGroup, g);
				if pos('material', LowerCase(EditorId(CurrentKYWD))) > 0 then
				begin
					temp := temp + ',' + EditorID(CurrentKYWD);
				end else if pos('materiel', LowerCase(EditorID(CurrentKYWD))) > 0 then
				begin
					temp := temp + ',' + EditorID(CurrentKYWD);
				end;
			end;
		end;
	end;
	AddMessage(temp);
end;

function Process(selectedRecord: IInterface): integer;
begin
	//PossibleList.Create;
	//EDIDParts;
	
	
	
	//Applicator;
	//PossibleList.Free;
	//PossibleList.Clear;
end;

function Finazlie: integer;
begin
	
end;

function nameParts: integer;
begin
	//the name determines a lot of how an item works. if it is called a shirt, then it probably is a shirt.
	
end;

function EDIDParts: integer;
var
	EDID: String;
begin
	EDID := lowercase(EditorID(itemRecord));
	if pos('skin', EDID) then PossibleList.Add('ignoredskin');
	if pos('armor', EDID) then PossibleList.Add('armors');
	
	if pos('gauntlet', EDID) then PossibleList.Add('handsarmor');
	if pos('cuirass', EDID) then PossibleList.Add('fullbody');
	if pos('boots', EDID) then PossibleList.Add('feet');
	if pos('helm', EDID) then PossibleList.Add('helmet');
	if pos('shield', EDID) then PossibleList.Add('shield');
	if pos('pantie', EDID) then PossibleList.Add('underwear');
	if pos('panties', EDID) then PossibleList.Add('underwear');
	if pos('thong', EDID) then PossibleList.Add('underwear');
	if pos('inner', EDID) > 0 then PossibleList.Add('underwear');
	if pos('panty', EDID) > 0 then PossibleList.Add('underwear');
	if pos('underwear', EDID) > 0 then PossibleList.Add('underwear');
	if pos('belt', EDID) then PossibleList.Add('belt');
	if pos('leg', EDID) then PossibleList.Add('leg');
	if pos('neck', EDID) then PossibleList.Add('necklace');
	if pos('headscarf', EDID) then PossibleList.Add('hat');
	if pos('coat', EDID) then PossibleList.Add('coat');
	if pos('goggle', EDID) then PossibleList.Add('eyewear');
	if pos('legging', EDID) then PossibleList.Add('leggings');
	if pos('shirt', EDID) then PossibleList.Add('shirt');
	if pos('skirt', EDID) then PossibleList.Add('skirt');
	if pos('kasa', EDID) then PossibleList.Add('hat');
	if pos('bracer', EDID) then PossibleList.Add('brace');
	if pos('vambrace', EDID) then PossibleList.Add('brace');
	if pos('coif', EDID) then PossibleList.Add('helmet');
	if pos('bassinet', EDID) then PossibleList.Add('helmet');
	if pos('sallet', EDID) then PossibleList.Add('helmet');
	if pos('armet', EDID) then PossibleList.Add('helmet');
	if pos('gorget', EDID) then PossibleList.Add('neckarmor');
	if pos('brigandine', EDID) then PossibleList.Add('breastplate');
	if pos('hauber', EDID) then PossibleList.Add('breastplate');
	if pos('plackart', EDID) then PossibleList.Add('breastplate');
	if pos('couter', EDID) then PossibleList.Add('elbow');
	if pos('cowter', EDID) then PossibleList.Add('elbow');
	if pos('spaulder', EDID) then PossibleList.Add('pauldron');
	if pos('pauldron', EDID) then PossibleList.Add('pauldron');
	if pos('cuisse', EDID) then PossibleList.Add('cuisse');
	if pos('sabaton', EDID) then PossibleList.Add('feet');
	if pos('tuille', EDID) then PossibleList.Add('cuisse');
	if pos('buckler', EDID) then PossibleList.Add('shield');
	if pos('geta', EDID) then PossibleList.Add('shoe');
	if pos('menpo', EDID) > 0 then PossibleList.Add('mask');
	if pos('scarf', EDID) > 0 then PossibleList.Add('neck');
	if pos('mantle', EDID) > 0 then PossibleList.Add('neck');
	if pos('kilt', EDID) > 0 then PossibleList.Add('skirt');
	if pos('short', EDID) > 0 then PossibleList.Add('pant');
	if pos('pant', EDID) > 0 then PossibleList.Add('pant');
	if pos('amulet', EDID) > 0 then PossibleList.Add('neck');
	if pos('collar', EDID) > 0 then PossibleList.Add('neck');
	if pos('corset', EDID) > 0 then PossibleList.Add('shirt');
	if pos('top', EDID) > 0 then PossibleList.Add('shirt');
	if not pos('nohood', EDID) then
	begin
		if pos('hood', EDID) then PossibleList.Add('hood');
	end;
	if pos('kimono', EDID) > 0 then PossibleList.Add('fullbody');
	if pos('kyahan', EDID) > 0 then PossibleList.Add('cuisse');
	if pos('kyahan', EDID) > 0 then PossibleList.Add('lightarmor');
	if pos('legwarmer', EDID) > 0 then PossibleList.Add('cuisse');
	if pos('leg warmer', EDID) > 0 then PossibleList.Add('cuisse');
	if pos('labia', EDID) > 0 then PossibleList.Add('piercing');
	if pos('earring', EDID) > 0 then PossibleList.Add('piercing');
	if pos('cloak', EDID) > 0 then PossibleList.Add('neck');
	if pos('cloak', EDID) > 0 then PossibleList.Add('cloak');
	if pos('dress', EDID) > 0 then PossibleList.Add('fullbody');
	if pos('dress', EDID) > 0 then PossibleList.Add('clothing');
	if pos('lace', EDID) > 0 then PossibleList.Add('rich');
	if pos('lace', EDID) > 0 then PossibleList.Add('clothing');
	if pos('sandal', EDID) > 0 then PossibleList.Add('shoes');
	if pos('crown', EDID) > 0 then PossibleList.Add('hat');
	if pos('hat', EDID) then 
	begin
		PossibleList.Add('head');
		PossibleList.Add('clothing');
	end;
	if pos('robes', EDID) then 
	begin
		PossibleList.Add('body');
		PossibleList.Add('clothing');
	end;
	if pos('arms', EDID) then PossibleList.Add('arm');
	
	if pos('mage', EDID) then 
	begin
		PossibleList.Add('mage');
		PossibleList.Add('clothing');
	end;
	if pos('ench', EDID) then PossibleList.Add('enchanted');
	
	if pos('black', EDID) then PossibleList.Add('black');
	if not pos('skyblue', EDID) and not pos('Lightblue', EDID) and not pos('light blue', EDID) then 
	begin
		if pos('blue', EDID) then PossibleList.Add('blue');
	end;
	if pos('skyblue', EDID) then PossibleList.Add('lightblue');
	if pos('Lightblue', EDID) then PossibleList.Add('lightblue');
	if pos('light blue', EDID) then PossibleList.Add('lightblue');
	if pos('green', EDID) then PossibleList.Add('green');
	if pos('orange', EDID) then PossibleList.Add('orange');
	if pos('purple', EDID) then PossibleList.Add('purple');
	if pos('red', EDID) then PossibleList.Add('red');
	if pos('white', EDID) then PossibleList.Add('white');
	if pos('yellow', EDID) then PossibleList.Add('yellow');
	if pos('burgundy', EDID) > 0 then PossibleList.Add('burgundy');
	if pos('emerald', EDID) > 0 then PossibleList.Add('emerald');
	if pos('forest', EDID) > 0 then PossibleList.Add('forestgreen');
	if pos('frost', EDID) > 0 then PossibleList.Add('white');
	if pos('brown', EDID) > 0 then PossibleList.Add('brown');
	if not pos('mediumgray', EDID) > 0 and not pos('mediumgrey', EDID) > 0 then
	begin
		if not pos('darkgray', EDID) > 0 and not pos('darkgrey', EDID) > 0 then
		begin
			if not pos('lightgray', EDID) > 0 and not pos('lightgrey', EDID) > 0 then
			begin
				if pos('grey', EDID) > 0 OR pos('gray', EDID) > 0 then PossibleList.Add('grey');
			end;
		end;
	end;
	if pos('mediumgray', EDID) > 0 or pos('mediumgrey', EDID) > 0 then PossibleList.Add('mediumgray');
	if pos('darkgray', EDID) > 0 or pos('darkgrey', EDID) > 0 then PossibleList.Add('darkgray');
	if pos('lightgray', EDID) > 0 or pos('lightgrey', EDID) > 0 then PossibleList.Add('lightgray');
	if pos('goth', EDID) > 0 then PossibleList.Add('black');
	if pos('lavender', EDID) > 0 then PossibleList.Add('lavender');
	if pos('mint', EDID) > 0 then PossibleList.Add('mintgreen');
	if pos('pink', EDID) > 0 then PossibleList.Add('pink');
	
	if pos('child', EDID) then PossibleList.Add('child');
	if pos('barkeep', EDID) then PossibleList.Add('barkeep');
	if pos('smith', EDID) then PossibleList.Add('blacksmith');
	if pos('archer', EDID) then PossibleList.Add('archer');
	if pos('legwarmer', EDID) > 0 then PossibleList.Add('warm');
	if pos('leg warmer', EDID) > 0 then PossibleList.Add('warm');
	if pos('mask', EDID) > 0 then PossibleList.Add('mask');
	if pos('unique', EDID) > 0 then PossibleList.Add('ignored');
	if pos('ribbon', EDID) > 0 then PossibleList.Add('cloth');
	if pos('tassel', EDID) > 0 then PossibleList.Add('cloth');
	if pos('bard', EDID) > 0 then PossibleList.Add('cloth');
	if pos('elegant', EDID) > 0 then PossibleList.Add('rich');
	if pos('ghost', EDID) > 0 then PossibleList.Add('clear');
	if pos('clear', EDID) > 0 then PossibleList.Add('clear');
	if pos('sheer', EDID) > 0 then PossibleList.Add('clear');
	if pos('gold', EDID) > 0 then PossibleList.Add('rich');
	if pos('bandit', EDID) > 0 then PossibleList.Add('hide');
	if pos('ARMO', signature(itemRecord)) > 0 then
	begin
		if pos('blades', EDID) > 0 then PossibleList.Add('blades');
	end;
	if pos('ripped', EDID) > 0 then PossibleList.Add('damaged');
	if pos('damaged', EDID) > 0 then PossibleList.Add('damaged');
end;

function BodySlots: integer;
begin
	//30 - head - report as broken
	//31 - hair - report as broken (might be wig?)
	//32 - body (full) - cuirass or clothing body (cuirass is innacurate anyway)
	//33 - hands - gauntlets and gloves
	//34 - forearms - vambrace
	//35 - amulet - necklace
	//36 - ring - ring
	//37 - feet - shoes or boots
	//38 - calves - greaves
	//39 - shield - shield
	//40 - tail - broken or as cloak(?) maybe tail
	//41 - long hair - broken or wig
	//42 - circlet - circlet
	//43 - ears - wig, circlet, broken, maybe ears
	//50 - decapitated head - broken
	//51 - decapitate - broken
	//61 - FX01 - no idea
	//44 - Used in bloodied dragon heads, so it is free for NPCs - nothing
	//45 - Used in bloodied dragon wings, so it is free for NPCs - nothing
	//47 - Used in bloodied dragon tails, so it is free for NPCs - nothing
	//130 - Used in helmetts that conceal the whole head and neck inside - full helmet
	//131 - Used in open faced helmets\hoods (Also the nightingale hood) - hood
	//141 - Disables Hair Geometry like 131 and 31 - wig or hood.
	//142 - Used in circlets - circlet
	//143 - Disabled Ear geometry to prevent clipping issues? - wig, circlet, broken, maybe ears
	//150 - The gore that covers a decapitated head neck - broken
	//230 - Neck, where 130 and this meets is the decapitation point of the neck - broken
	//44 - face/mouth - teeth or broken
	//45 - neck (like a cape, scarf, or shawl, neck-tie etc) - cape (maybe gorget)
	//46 - chest primary or outergarment - shirt maybe
	//47 - back (like a backpack/wings etc) - backpack unless wing is in name
	//48 - misc/FX (use for anything that doesnt fit in the list) - broken
	//49 - pelvis primary or outergarment - pants probably
	//52 - pelvis secondary or undergarment - underwear
	//53 - leg primary or outergarment or right leg - cuisse
	//54 - leg secondary or undergarment or leftt leg - cuisse again?
	//55 - face alternate or jewelry - mask
	//56 - chest secondary or undergarment - bra/underwear top
	//57 - shoulder - pauldron
	//58 - arm secondary or undergarment or left arm - besagew
	//59 - arm primary or outergarment or right arm - cowter
	//60 - misc/FX (use for anything that doesnt fit in the list) - broken
	
	{if the nif uses niskininstance then can change the body slot. if it uses bsdismemberskininstance cant change it}
	
	
end;

procedure NifSetPartitionSlot(aFileName, aBodyPart: string);
var
  nif: TwbNifFile;
  b: TwbNifBlock;
  parts: TdfElement;
  i, j: integer;
begin
  nif := TwbNifFile.Create;
  try
    nif.LoadFromFile(aFileName);
    
    for i := 0 to Pred(nif.BlocksCount) do begin
      b := nif.Blocks[i];
      if b.BlockType <> 'BSDismemberSkinInstance' then
        Continue;
      
      parts := b.Elements['Partitions'];
      if Assigned(parts) then
        for j := 0 to Pred(parts.Count) do
          parts[j].EditValues['Body Part'] := aBodyPart;
    end;
    
    nif.SaveToFile(aFileName);
  finally
    nif.Free;
  end;
end;

{function Initialize: Integer;
begin
  NifSetPartitionSlot('e:\a.nif', 'SBP_30_HEAD');
  Result := 1;
end;
//implementation of NifSetPartitionSlot
}

function KeywordList: integer;
begin
	
end;

function existingCrafting: integer;
begin
	
end;

function Applicator: integer;
begin
	
end;

function kywdComparator: integer;
begin

end;

end.