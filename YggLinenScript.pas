unit YggLinenScript;
uses YggFunctions;

var
	Patch: IInterface;
	itemRecord: IInterface;
	

function Initialize: integer;
var
	CP, Linen: IInterface;
	f: Integer;
begin
	AddMessage('Searching for winning Linen Overrides');
	Patch := SelectPatch('Ygg_Linens.esp');
	PassFile(Patch);
	BeginUpdate(Patch);
	try
	AddAllMaster;
	Finally EndUpdate(Patch);
	end;
	Linen := getRecordByFormID('00034cd6');
	//AddMessage(Name(Linen));
	for f := ReferencedByCount(Linen) downto 0 do
	begin
		CP := ReferencedByIndex(Linen, f);
		if not IsWinningOverride(CP) then continue;
		wbCopyElementToFile(CP, Patch, false, true);
	end;
end;

function Process(selectedRecord: IInterface): integer;
begin
end;

function Finazlie: integer;
begin
	CleanMasters(Patch);
end;

end.