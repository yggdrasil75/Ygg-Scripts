unit YggGoldFix;
uses YggFunctions;

var
	Patch: IInterface;
	itemRecord: IInterface;
	

function Initialize: integer;
var
	CP, Gold: IInterface;
	f: Integer;
begin
	AddMessage('Searching for winning Gold Overrides');
	Patch := SelectPatch('Ygg_COTV2Fix.esp');
	PassFile(Patch);
	BeginUpdate(Patch);
	try
	AddAllMaster;
	Finally EndUpdate(Patch);
	end;
	Gold := getRecordByFormID('0000000f');
	//AddMessage(Name(Gold));
	for f := ReferencedByCount(Gold) downto 0 do
	begin
		CP := ReferencedByIndex(Gold, f);
		if not IsWinningOverride(CP) then continue;
		if pos('Coins', GetFileName(CP)) > 0 then continue;
		if pos('Skyrim.esm', GetFileName(CP)) > 0 then continue;
		if pos('Dawnguard', GetFileName(CP)) > 0 then continue;
		if pos('HearthFires', GetFileName(CP)) > 0 then continue;
		if pos('Dragonborn', GetFileName(CP)) > 0 then continue;
		if pos('Update.esm', GetFileName(CP)) > 0 then continue;
		wbCopyElementToFile(CP, Patch, false, true);
	end;
	CleanMasters(Patch);
end;

function Process(selectedRecord: IInterface): integer;
begin
end;

function Finazlie: integer;
begin
end;

end.