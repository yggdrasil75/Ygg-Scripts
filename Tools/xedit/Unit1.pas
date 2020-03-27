unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Data.Bind.EngExt, Vcl.Bind.DBEngExt, System.Rtti, System.Bindings.Outputs,
  Vcl.Bind.Editors, Data.Bind.Components,YggFunctions,YggBalancingAct;
var
	Recipes,Armo,ArmoRating,ArmoWeight : TStringList;
	ArmoValue,Ammo,AMMODamage,AMMOValue : TStringList;
	AMMOWeight,Weap,WeapValue,WeapWeight : TStringList;
	WeapReach,WeapDamage,WeapSpeed : TStringList;
	WeapCrdtDam,WeapRangeMin,TrustedPlugins,WeapRangeMax : TStringList;
	YggIni: TMemIniFile;
	Mode,C_FName:string;
	Patch,CurrentItem: IInterface;
	TimeBegin: TDateTime;
	YggLogCurrentMessages: TStringList;
	DebugLevel: integer;
	SingleFile: boolean;
	SinglePlugin: IInterface;

type
  TFixedSettings = class(TForm)
    FixedSetting: TLabel;
    FixedScrollBox: TScrollBox;
    Save: TButton;
    Finish: TButton;
    ArmoWeapAmmoSelect: TComboBox;
    AddressValueArmo: TListView;
    AddressValueWeap: TListView;
    AddressValueAmmo: TListView;
    Reset: TButton;
    procedure InitializeCalcLists(Sender: TObject);
    procedure mrOk(Sender: TObject);
    procedure SaveToIni(Sender: TObject);
    procedure ArmoWeapAmmoSelectSelect(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FixedSettings: TFixedSettings;

implementation

{$R *.dfm}

procedure TFixedSettings.ArmoWeapAmmoSelectSelect(Sender: TObject);
begin
	if ArmoWeapAmmoSelect.Text = 'Armo' then
    begin
        AddressValueArmo.Visible := true;
		AddressValueWeap.visible := false;
		AddressValueAmmo.Visible := false;
    end;
	if ArmoWeapAmmoSelect.Text = 'Weap' then
    begin
        AddressValueWeap.Visible := true;
		AddressValueArmo.Visible := false;
		AddressValueAmmo.Visible := false;
    end;
	if ArmoWeapAmmoSelect.Text = 'Ammo' then
    begin
        AddressValueWeap.Visible := false;
		AddressValueArmo.Visible := false;
		AddressValueAmmo.Visible := true;
    end;
end;

procedure TFixedSettings.InitializeCalcLists(Sender: TObject);
var
	i,j:integer;
	CurrentFile,CurrentGroup,CurrentItem:IInterface;
	BNAM:IInterface;
begin
	LogMessage(1,'Gathering Lists',YggLogCurrentMessages);
	
	Recipes := TStringList.Create;
	Recipes.Duplicates := DupIgnore;
	ArmoRating := TStringList.Create;
	ArmoWeight := TStringList.Create;
	ArmoValue := TStringList.Create;
	AMMODamage := TStringList.Create;
	AMMOValue := TStringList.Create;
	AMMOWeight := TStringList.Create; //game doesnt use this unless you have survival mode
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
			LogMessage(1, 'Checked COBJ In ' + GetFileName(CurrentFile),YggLogCurrentMessages);
		end;
		//armo
		if HasGroup(CurrentFile, 'ARMO') then begin
			AddArmo(CurrentFile);
			LogMessage(1, 'Checked ARMO In ' + GetFileName(CurrentFile),YggLogCurrentMessages);
		end;
		//weap
		if HasGroup(CurrentFile, 'WEAP') then begin
			AddWeap(CurrentFile);
			LogMessage(1, 'Checked WEAP In ' + GetFileName(CurrentFile),YggLogCurrentMessages);
		end;
		//ammo
		if HasGroup(CurrentFile, 'AMMO') then begin
			AddAmmo(CurrentFile);
			LogMessage(1, 'Checked AMMO In ' + GetFileName(CurrentFile),YggLogCurrentMessages);
		end;
	end;
	
	//finalize lists
	FinalizeArmo;
	FinalizeWeap;
	FinalizeAmmo;
end;

procedure TFixedSettings.SaveToIni(Sender: TObject);
var
  i: Integer;
	TempList: TStringList;
begin
	YggIni := TIniFile.Create(ScriptsPath + 'Ygg.ini');
	for i := 0 to ArmoListList.count do begin
		TempList := ArmoListList.objects[i];
		YggIni.WriteString('Balance',TempList.strings[0],TempList.Strings[1]+ '|' + TempList.Strings[2] + TempList.Strings[3]);
    end;
end;

end.
