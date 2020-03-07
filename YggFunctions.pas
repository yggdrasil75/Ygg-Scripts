unit YggFunctions;

var
	Patch: IInterface;
	CurrentRecord: IInterface;
	StartTime: TDateTime;
	YggLog: TextFile;

function PassFile(PatchToBe: IInterface): integer;
begin
	Patch := PatchToBe;
	result := 0;
end;

function getPatch: IInterface;
begin
	result := Patch;
end;

function PassRecord(itemRecord: IInterface): integer;
begin
	CurrentRecord := itemRecord;
	result := 0;
end;

procedure PassTime(Start: TDateTime);
begin
	StartTime := Start;
end;

function tryStrToFloat(item: string; default: double): double;
begin
	if length(item) = 0 then
	begin
		elementassign(copyRecord, -1, Nil, false);
		addMessage('item ' + name(CurrentRecord) + ' is missing required data');
		result := default;
	end else result := StrToFloat(item);
end;

function tryStrToInt(item: string; default: integer): integer;
begin
	if length(item) = 0 then
	begin
		elementassign(copyRecord, -1, Nil, false);
		addMessage('item ' + name(CurrentRecord) + ' is missing required data');
		result := default;
	end else result := StrToFloat(item);
end;

function AddMasterBySignature(Sig: String): integer;
var
i: integer;
temp: IInterface;
begin
	for i := 0 to fileCount - 1 do
	begin
		temp := FileByIndex(i);
		if pos(GetFileName(patch), GetFileName(temp)) < 1 then
		begin
			if HasGroup(temp, sig) then
			begin
				AddMasterIfMissing(Patch, GetFileName(temp));
			end;
		end;
	end;
end;

function FileByName(s: string): IInterface;
var
	i: integer;
	temp: IInterface;
begin
	for i := 0 to FileCount - 1 do
	begin
		temp := FileByIndex(i);
		if LowerCase(GetFileName(temp)) = LowerCase(s) then
		begin
			Result := temp;
			break;
		end;
	end;
end;

function ProperOverride(e: IInterface; Improper: TStringList): IInterface;
var
	m, ovr : IInterface;
	b2, b, i: integer;
begin
	m := MasterOrSelf(e);
	b2 := 0;
	for i := Pred(OverrideCount(m)) downto 0 do
	begin
		ovr := OverrideByIndex(m, i);
		if not equals(GetFile(WinningOverride(ovr)), patch) then
		begin
			for b := 0 to Improper.Count - 1 do
			begin
				if not CompareText(LowerCase(GetFileName(GetFile(ovr))), LowerCase(Improper.ValueFromIndex[b])) == 1 then
				begin
					b2 := b2 + 1;
				end;
			end;
			if b2 = 0 then 
			begin
				result := WinningOverride(wbCopyElementToFile(ovr, Patch, false, true));
			end else 
			begin
				result := WinningOverride(wbCopyElementToFile(WinningOverride(m), Patch, false, true));
			end;
		end else
		begin
			result := WinningOverride(ovr)
		end;
	end;
end;

function getRecordByFormID(id: string): IInterface;
var
  tmp: IInterface;
begin
  // basically we took record like 00049BB7, and by slicing 2 first symbols, we get its file index, in this case Skyrim (00)
  tmp := FileByLoadOrder(StrToInt('$' + Copy(id, 1, 2)));
  //AddMessage(GetFileName(tmp));

  // file was found
  if Assigned(tmp) then begin
    // look for this record in founded file, and return it
    tmp := RecordByFormID(tmp, StrToInt('$' + id), true);

    // check that record was found
    if Assigned(tmp) then begin
      Result := tmp;
    end else begin // return nil if not
      Result := nil;
    end;

  end else begin // return nil if not
    Result := nil;
  end;
end;

// checks the provided keyword inside record
function hasKeyword(keywordEditorID: string): boolean;
var
  tmpKeywordsCollection: IInterface;
  i: integer;
begin
	Result := false;
	// get all keyword entries of provided record
	tmpKeywordsCollection := ElementByPath(CurrentRecord, 'KWDA');
	// loop through each
	for i := 0 to ElementCount(tmpKeywordsCollection) - 1 do
	begin
		if GetElementEditValues(LinksTo(ElementByIndex(tmpKeywordsCollection, i)), 'EDID') = keywordEditorID then
		begin
			Result := true;
			Break;
		end;
	end;
end;

function addKeyword(keyword: String): integer;
var
	foobar, KYWD, keywordRef: IInterface;
begin
	foobar := TrueRecordByEDID(keyword);
	if not hasKeyword(keyword) then 
	begin
		KYWD := ElementByPath(CurrentRecord, 'KWDA');
		if not Assigned(KYWD) then 
		begin
			Add(CurrentRecord, 'KWDA', true);
		end;
		keywordRef := ElementAssign(KYWD, HighInteger, foobar, false);
		AddMessage(FullPath(keywordRef));
		SetEditValue(ElementByIndex(KYWD, IndexOf(KYWD, keywordRef)), GetEditValue(foobar));
	end;
end;

function RecipeOut(Recipe: IInterface): IInterface;
begin
	result := LinksTo(ElementByPath(Recipe, 'CNAM'));
end;

function TrueRecordByEDID(edid: String): IInterface;
var
	a: integer;
	temp: IInterface;
begin
	for a := fileCount - 1 downto 0 do
	begin
		temp := MainRecordByEditorID(GroupBySignature(FileByIndex(a), 'KYWD'), edid);
		if assigned(temp) then break;
	end;
	if not assigned(temp) then
	begin
		addmessage('there is a typo in a edid');
	end;
	result := temp;
end;

function odd(iInput: Integer): boolean;
begin
	if ((iInput mod 2) == 0) then result := false
	else result := true;
end;

// creates new record inside provided file
function createRecord(recordSignature: string): IInterface;
var
  newRecordGroup: IInterface;
begin
	// get category in file
	newRecordGroup := GroupBySignature(Patch, recordSignature);

	// check the category is there
	if not Assigned(newRecordGroup) then begin
		newRecordGroup := Add(Patch, recordSignature, true);
	end;

	// create record and return it
	Result := Add(newRecordGroup, recordSignature, true);
end;

procedure removeInvalidEntries(rec: IInterface);
var
  i, num: integer;
  lst, ent: IInterface;
  recordSignature, refName, countname: string;
begin
	recordSignature := Signature(rec);

	// containers and constructable objects
	if (recordSignature = 'CONT') or (recordSignature = 'COBJ') then 
		begin
		lst := ElementByName(rec, 'Items');
		refName := 'CNTO\Item';
		countname := 'COCT';
	end

	num := ElementCount(lst);
	// check from the end since removing items will shift indexes
	for i := num - 1 downto 0 do 
	begin
		// get individual entry element
		ent := ElementByIndex(lst, i);
		// Check() returns error string if any or empty string if no errors
	if Check(ElementByPath(ent, refName)) <> '' then Remove(ent);
	end;

	// has counter
	if Assigned(countname) then 
	begin
		// update counter subrecord
		if num <> ElementCount(lst) then 
		begin
			  num := ElementCount(lst);
			  // set new value or remove subrecord if list is empty (like CK does)
			  if num > 0 then SetElementNativeValues(rec, countname, num)
			  else RemoveElement(rec, countname);
		end;
	end;
end;

// adds item record reference to the list
function addItem(list: IInterface; item: IInterface; amount: integer): IInterface;
var
  newItem: IInterface;
  listName: string;
begin
	// add new item to list
	newItem := ElementAssign(list, HighInteger, nil, false);
	listName := Name(list);
	//AddMessage(name(newItem));
	if Length(listName) = 0 then 
	begin
		AddMessage('Broken');
		exit;
	end;
	// COBJ
	if listName = 'Items' then begin
		// set item reference
		SetElementEditValues(newItem, 'CNTO - Item\Item', GetEditValue(item));
		// set amount
		SetElementEditValues(newItem, 'CNTO - Item\Count', amount);
	end;
	//AddMessage('test');
	// remove nil records from list
	removeInvalidEntries(list);

	Result := newItem;
end;

// adds requirement 'HasPerk' to Conditions list
function addPerkCondition(list: IInterface; perk: IInterface): IInterface;
var
  newCondition, tmp: IInterface;
begin
	if not (Name(list) = 'Conditions') then begin
		if Signature(list) = 'COBJ' then begin // record itself was provided
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
	SetElementEditValues(newCondition, 'CTDA\Type', '10000000');

	// set some needed properties
	SetElementEditValues(newCondition, 'CTDA\Comparison Value', '1');
	SetElementEditValues(newCondition, 'CTDA\Function', 'HasPerk');
	SetElementEditValues(newCondition, 'CTDA\Perk', GetEditValue(perk));
	SetElementEditValues(newCondition, 'CTDA\Run On', 'Subject');
	// don't know what is this, but it should be equal to -1, if Function Runs On Subject
	SetElementEditValues(newCondition, 'CTDA\Parameter #3', '-1');

	// remove nil records from list
	removeInvalidEntries(list);

	Result := newCondition;
end;

function SelectPatch(PatchName: String): IInterface;
begin
	if Assigned(FileByName(PatchName)) then
	begin
		Patch := FileByName(PatchName);
		Result := Patch;
	end else 
	begin
		if not FileExists(DataPath + PatchName) then 
		begin
			result := AddNewFileName(PatchName, false);
		end else
		begin
			ShowMessage('The Patch exists, but is not loaded, creating a new patch');
			result := AddNewFile;
		end;
	end;
end;

function AddLVLIItem(LVLI, a: IInterface): IInterface;
var
	NewItem: IInterface;
begin
	NewItem := ElementAssign(ElementByName(LVLI, 'Leveled List Entries'), HighInteger, nil, false);
	SetElementEditValues(newItem, 'LVLO\Reference', IntToHex(FormID(a),8));
	SetElementEditValues(newItem, 'LVLO\Level', '1');
	SetElementEditValues(newItem, 'LVLO\Count', '1');
	result := NewItem
end;

function AddAllMaster: integer;
var
	f: integer;
begin
	for f := 0 to FileCount - 2 do
	begin
		AddMasterIfMissing(Patch, GetFileName(FileByIndex(f)));
	end;
end;

function sign: integer;
begin
	SetElementEditValues(ElementByIndex(patch,0),'CNAM - Author', 'Yggdrasil75');
end;

function GatherRecipes(sig: String; List: TList): integer;
var
	i1, i2: integer;
	cg: IInterface;
begin
    for i1 := FileCount - 1 downto 0 do
    begin
        if HasGroup(FileByIndex(i1), 'COBJ') then
        begin
            cg := GroupBySignature(FileByIndex(i1), 'COBJ');
            for i2 := 0 to ElementCount(Cg) - 1 do 
            begin
                if HasSignature(LinksTo(MasterOrSelf(ElementByPath(CurrentRecord, 'CNAM'))), sig) then
                begin
                    List.Add(MasterOrSelf(ElementByPath(CurrentRecord, 'CNAM')));
                end;
            end;
        end;
    end;
end;

function hasSignature(rec: IInterface; sig: String): boolean;
begin
    if signature(rec) = sig then 
	begin
		result := true;
    end else 
	begin
		result := false;
	end;
end;

{procedure BeginLog(Who: String);
var
	C_FName: string;
begin
	C_FName := ScriptsPath + 'Ygg.Log';//nothing currently, but will probably have this set to an ini later. might make it dynamically named based on time.
	AssignFile(YggLog, C_FName);
	Rewrite(YggLog);
	writeln(YggLog, who);
end;

function TimeBtwn(Start, Stop: TDateTime): string;
begin
	Result := intToStr(((3600*GetHours(Stop))+(60*GetMinutes(Stop))+GetSeconds(Stop))-((3600*GetHours(Start))+(60*GetMinutes(Start))+GetSeconds(Start)));
end;

procedure LogMessage(level: integer; LogItem: string);
var
	currenttime: TDateTime;
begin
	currenttime := Time;
	if level = 0 then
	begin
		LogItem := '[Info]: ' + TimeBtwn(timebegin, currenttime) + ' '  + LogItem;
	end else if level = 1 then
	begin
		LogItem := '[Debug]: ignore this, it is just to track slow sections.' + LogItem;
	end else if level = 2 then 
	begin
		LogItem := '[Error]: ' + TimeBtwn(timebegin, currenttime) + ' '  + LogItem;
	end else if level = 3 then
	begin
		LogItem := '[Warning]: ' + TimeBtwn(timebegin, currenttime) + ' ' + LogItem;
	end;
	
	if debuglevel = 0 then //only output to log file
	begin
		if level > 2 then addMessage(LogItem);
	end else if debuglevel = 1 then //output to log file all info and most minor issues, output to xedit major issues
	begin
		if level > 1 then addMessage(LogItem);
	end else if debuglevel = 2 then //output all issues to xedit and log info
	begin
		if level > 0 then addMessage(LogItem);
	end else if debuglevel = 3 then //output all info to xedit
	begin
		addmessage(LogItem);
	end;
	writeln(YggLog, LogItem);
end;

procedure MasterLines;
var
  m: TMemo;
  i: Integer;
begin
	m := TMemo(TForm(frmMain).FindComponent('mmoMessages'));
	for i := Pred(m.Lines.Count) downto m.Lines.Count - MasterCount(patch) do
		logMessage(1, m.Lines[i]);
end;}

end.
