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
	sDirPath,sGamePath:string;
begin
	BeginTime := Time;
	beginLog('YggLoading');
	PassTime(Time);
	Patch := SelectPatch('Ygg_Loading.esp');
	PassFile(Patch);
	AddmasterBySignature('LSCR');
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
		ArtIn := TDirectory.GetFiles(sGamePath, '*.jpg;*.png;*.bmp', soAllDirectories);
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
	sign;
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
	j,i:integer;
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
		//CurrentTXST := CreateRecord('TXST');
		SetEditorID(CurrentStat, 'YggLoadingSTAT'+CurrentEDIDAddition);
		//SetEditorID(CurrentTXST, 'YggLoadingTXST'+CurrentEDIDAddition);
		
		SetEditorID(CurrentRecord, 'YggLoadingLSCR'+CurrentEDIDAddition);
		CopyFile('1.nif',DataPath+'\meshes\ygg\loading\'+CurrentEDIDAddition+'.nif');
		
		replaceTextureInNif(DataPath+'ygg\loading\'+CurrentEDIDAddition+'.nif','ygg\loading\1.dds',DataPath+'\textures\ygg\loading\'+CurrentEDIDAddition+'.nif');
		
		Add(CurrentStat,'Model',false);
		Add(CurrentStat,'Model\MODS',false);
		foobar := ElementAssign(ElementByName(CurrentStat, 'Model'), 2, nil, False); 
		//if assigned(foobar) then
			//addmessage('foobar');
		temp := ElementAssign(ElementByName(CurrentStat, 'Model\MODS'), 3, nil, False); 
		temp := ElementByIndex(foobar, 0);
		if not assigned(temp) then temp := ElementAssign(foobar, HighInteger, nil, false);
		//if assigned(temp) then addmessage('temp');
		//SetEditValue(ElementByPath(temp, 'New Texture'), Name(CurrentTXST));
		SetElementEditValues(CurrentStat, 'Model\MODL', 'ygg\loading\Loader.nif');
		SetEditValue(ElementByIndex(ElementByIndex(CurrentStat,4),0), '90');
		//SetElementEditValues(CurrentStat, 'Model\MODS\Alternate Texture\3D Name', 'CivilWarMap01');
		//SetElementEditValues(CurrentStat, 'Model\MODS\Alternate Texture\3D Index', '2');
		//for j := elementcount(ElementByIndex(CurrentStat,4)) - 1 downto 0 do addmessage(name(ElementByIndex(ElementByIndex(CurrentStat, 4),0)));
		
		//Add(CurrentTXST,'Textures (RGB/A)', false);
		//Add(CurrentTXST,'Textures', false);
		//SetElementEditValues(CurrentTXST, 'Textures (RGB/A)\TX00', 'Ygg\Loading\'+CurrentEDIDAddition+'.dds');
		//ElementAssign(CurrentTXST, 2, nil, false);
		//SetElementEditValues(CurrentTXST, 'Textures (RGB/A)\TX01', 'Ygg\Loading\'+CurrentEDIDAddition+'.dds');
		
		
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

procedure replaceTextureInNif(sourcenif,afind,areplace:string);
var
  TDirectory: TDirectory; // to access member functions
  i, j, k, p, Processed, Updated: integer;
  Elements: TList;
  el: TdfElement;
  Nif: TwbNifFile;
  Block: TwbNifBlock;
  BGSM: TwbBGSMFile;
  BGEM: TwbBGEMFile;
  files: TStringDynArray;
  f, f2, ext: string;
  s, s2: WideString;
  bChanged: Boolean;
begin
	Elements := TList.Create;
	Nif := TwbNifFile.Create;
	BGSM := TwbBGSMFile.Create;
	
	if ExtractFileExt(sourcenif) = '.nif' then
	begin
		Nif.LoadFromFile(sourcenif);
		for j := 0 to Nif.BlocksCount - 1 do begin
		block := Nif.Blocks[j];
		if bMaterial and (Nif.NifVersion = nfFO4) and (Block.BlockType = 'BSLightingShaderProperty') then
			Elements.Add(Block.Elements['Name'])
		else if Block.BlockType = 'BSShaderTextureSet' then begin
			el := Block.Elements['Textures'];
			for j := 0 to Pred(el.Count) do
				Elements.Add(el[j]);
		end else if Block.BlockType = 'BSEffectShaderProperty' then begin
			Elements.Add(Block.Elements['Source Texture']);
			Elements.Add(Block.Elements['Grayscale Texture']);
			Elements.Add(Block.Elements['Env Map Texture']);
			Elements.Add(Block.Elements['Normal Texture']);
			Elements.Add(Block.Elements['Env Mask Texture']);
			// BGSM/BGEM file in the Name field of FO4 meshes
			if bMaterial and (Nif.NifVersion = nfFO4) then
			Elements.Add(Block.Elements['Name']);
			end else if (Block.BlockType = 'BSShaderNoLightingProperty') or
				(Block.BlockType = 'TallGrassShaderProperty') or
				(Block.BlockType = 'TileShaderProperty')
				then
					Elements.Add(Block.Elements['File Name'])

			else if Block.BlockType = 'BSSkyShaderProperty' then
				Elements.Add(Block.Elements['Source Texture'])

			// any block inherited from NiTexture
			else if Block.IsNiObject('NiTexture', True) then
				Elements.Add(Block.Elements['File Name']);
		end; 
	end;
		
	if Elements.Count = 0 then exit;
	
	for j := 0 to Pred(Elements.Count) do begin
		if not Assigned(Elements[j]) then
			Continue
		else
			el := TdfElement(Elements[j]);

		// getting file name stored in element
		s := el.EditValue;
		// skip to the next element if empty
		if s = '' then Continue;

		// perform replacements, trim whitespaces just in case
		s2 := Trim(s);
		for k := 0 to Pred(aFind.Count) do begin
			if aFind[k] <> '' then// replace if text to find is not empty
				s2 := StringReplace(s2, afind, aReplace, [rfIgnoreCase, rfReplaceAll])
			else// prepend if empty
				s2 := aReplace[k] + s2;
		end;

		// detect an absolute path
		if (Length(s2) > 2) and (Copy(s2, 2, 1) = ':') then begin
			// remove path up to Data including it
				p := Pos('\data\', LowerCase(s2));
				if p <> 0 then
					s2 := Copy(s2, p + 6, Length(s2));
					// remove path up to Data Files including it for Morrowind
				if p = 0 then begin
					p := Pos('\data files\', LowerCase(s2));
				if p <> 0 then
					s2 := Copy(s, p + 12, Length(s2));
				end;

			// if element's value has changed
			if s <> s2 then begin// store it
				el.EditValue := s2;

			// report
			if not bChanged then
				logMessage(1,#13#10 + f);
				logMessage(1,#9 + el.Path + #13#10#9#9'"' + s + '"'#13#10#9#9'"' + el.EditValue + '"');

				// mark file to be saved
				bChanged := True;
			end;
		end;
		// create the same folders structure as the source file in the destination folder
		s := ExtractFilePath(f2);
		if not DirectoryExists(s) then
			if not ForceDirectories(s) then
				raise Exception.Create('Can not create destination directory ' + s);

		// get the root of the last processed element (the file element itself) and save
		el.Root.SaveToFile(f2);
		Inc(Updated);
	end;
	
	Elements.Free;
	Nif.Free;
	BGSM.Free;
	BGEM.Free;
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
