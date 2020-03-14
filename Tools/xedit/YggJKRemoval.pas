unit JKRemoval;

var
	SCityKeep: string;
	PluginsToPatch: TStringList;

function initialize: integer;
begin
	Ini := TMemIniFile.Create(ScriptsPath + 'Ygg.ini');
	SCityKeep := Ini.ReadString('CityPatcher', 'sCitiesToKeep', 'DawnStar,DragonBridge,Falkreath,Ivarstead,Markarth,Morthal,Riften,Riverwood,Rorikstead,Skaal,Skyhaven,Solitude,Whiterun,Windhelm,Winterhold');
		ini.WriteString('CityPatcher', 'sCitiesToKeep', SCityKeep);
	
end;

procedure FindRecipients;
var
	i: integer;
begin
	PluginsToPatch := TStringList.Create;
	for i := fileCount - 1 downto 0 do begin
		if HasMaster(FileByIndex(i), 'JK''s Skyrim') then PluginsToPatch.AddObject(GetFileName(FileByIndex(i)), FileByIndex(i));
	end;
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
function CellByBlockSubBlock(plugin: IInterface; block,subblock: integer): IInterface;
begin
	//FindChildGroup(ChildGroup(Cell), 9, cell);
	//something about gridcell
end;

procedure DawnStar;
begin
	remove(TrueRecordByEDID(XJKDawnstarShipInterior))
end;



end.