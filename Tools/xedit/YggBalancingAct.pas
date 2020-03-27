unit YggBalancingAct;
uses YggFunctions;
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
	
const
	scaleFactor = Screen.PixelsPerInch / 96;

Function Initialize: integer;
begin
	Balancer;
end;

procedure Balancer;
var
	i: integer;
	BeginTime, EndTime: TDateTime;
	temp:string;
	SPM: TStringList;
begin
	//"init"
	YggLogCurrentMessages := TStringList.Create;
	BeginTime := Time;
	BeginLog('Balancing Act Start');
	TimeBegin := PassTime(Time);
	IniProcess;
	Mode := SetMode;
	InitializeCalcLists;
	if Mode = 'Fixed' then 
		FixedSettings;
	InitializeProcLists;
	MasterLines;
	Randomize;
	
	//processing
	LogMessage(1,'Processing Section Start',YggLogCurrentMessages);
	BalancingProcess;
	LogMessage(1,'Processing Section Done',YggLogCurrentMessages);
	
	
	//finalizing
	AddMessage('---Balancing act ended---');
	Sign;
	AddMessage('---Tight rope removed---');
	LogMessage(3,'Completed',YggLogCurrentMessages);
end;

procedure BalancerMode;
begin
	//balancer mode will be for someone making a new balancing mod. when used, fixed values will be used from the ini instead of dynamic
end;

procedure modDevMode;
begin
	//similar to single mode, except instead of making a patch, it directly edits the plugin. needs to confirm editability of plugin before processing.
end;

function SetMode(asCaption: String): string;
var
	frm: TForm;
	lblModes: TLabel;
	chkAddTags,chkLogging,cbbModes: TComboBox;
	btnCancel,btnOk: TButton;
	i: Integer;
begin
	YggIni := TIniFile.Create(ScriptsPath + 'Ygg.ini');
	Result := nil;

	frm := TForm.Create(TForm(frmMain));

	try
		frm.Caption := asCaption;
		frm.BorderStyle := bsToolWindow;
		frm.ClientWidth := 234 * scaleFactor;
		frm.ClientHeight := 90 * scaleFactor;
		frm.Position := poScreenCenter;
		frm.KeyPreview := True;

		lblModes := TLabel.Create(frm);
		lblModes.Parent := frm;
		lblModes.Left := 16 * scaleFactor;
		lblModes.Top := 10 * scaleFactor;
		lblModes.Width := 200 * scaleFactor;
		lblModes.Height := 16 * scaleFactor;
		lblModes.Caption := 'Select mode:';
		lblModes.AutoSize := False;

		cbbModes := TComboBox.Create(frm);
		cbbModes.Parent := frm;
		cbbModes.Left := 16 * scaleFactor;
		cbbModes.Top := 30 * scaleFactor;
		cbbModes.Width := 200 * scaleFactor;
		cbbModes.Height := 21 * scaleFactor;
		cbbModes.Style := csDropDownList;
		cbbModes.DoubleBuffered := True;
		cbbModes.TabOrder := 2;

		cbbModes.Items.Add('Default');
		cbbModes.Items.Add('Single');
		cbbModes.Items.Add('Fixed');
		cbbModes.Items.Add('Direct');

		cbbModes.ItemIndex := Pred(cbbModes.Items.Count);
		
		btnOk := TButton.Create(frm);
		btnOk.Parent := frm;
		btnOk.Left := 1 * scaleFactor;
		btnOk.Top := 55 * scaleFactor;
		btnOk.Width := 75 * scaleFactor;
		btnOk.Height := 25 * scaleFactor;
		btnOk.Caption := 'Save';
		btnOk.Default := True;
		btnOk.ModalResult := mbYes;
		btnOk.TabOrder := 3;
		
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
		
		if cbbModes.Text = 'Single' OR cbbModes.Text = 'Direct' then begin
			frm.ClientHeight := 150 * scaleFactor;
			
			lblPlugins := TLabel.Create(frm);
			lblPlugins.Parent := frm;
			lblPlugins.Left := 16 * scaleFactor;
			lblPlugins.Top := 55 * scaleFactor;
			lblPlugins.Width := 200 * scaleFactor;
			lblPlugins.Height := 16 * scaleFactor;
			lblPlugins.Caption := 'Select file to balance for single and direct modes:';
			lblPlugins.AutoSize := False;

			cbbPlugins := TComboBox.Create(frm);
			cbbPlugins.Parent := frm;
			cbbPlugins.Left := 16 * scaleFactor;
			cbbPlugins.Top := 75 * scaleFactor;
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
			btnOk.Left := 1 * scaleFactor;
			btnOk.Top := 100 * scaleFactor;
			btnOk.Width := 75 * scaleFactor;
			btnOk.Height := 25 * scaleFactor;
			btnOk.Caption := 'Save';
			btnOk.Default := True;
			btnOk.ModalResult := mbYes;
			btnOk.TabOrder := 3;
			
			btnOk := TButton.Create(frm);
			btnOk.Parent := frm;
			btnOk.Left := 62 * scaleFactor;
			btnOk.Top := 100 * scaleFactor;
			btnOk.Width := 75 * scaleFactor;
			btnOk.Height := 25 * scaleFactor;
			btnOk.Caption := 'Run';
			btnOk.Default := True;
			btnOk.ModalResult := mrOk;
			btnOk.TabOrder := 3;

			btnCancel := TButton.Create(frm);
			btnCancel.Parent := frm;
			btnCancel.Left := 143 * scaleFactor;
			btnCancel.Top := 100 * scaleFactor;
			btnCancel.Width := 75 * scaleFactor;
			btnCancel.Height := 25 * scaleFactor;
			btnCancel.Caption := 'Abort';
			btnCancel.ModalResult := mrAbort;
			btnCancel.TabOrder := 4;
			
		end else begin
			btnOk.Top := 55 * scaleFactor;
			btnCancel.Top := 55 * scaleFactor;
			btnOk.Top := 55 * scaleFactor;
		end;
		
		if frm.ShowModal = mbYes then begin
			YggIni.WriteString('Balance', 'Mode', cbbModes.Text);
			YggIni.UpdateFile;
		end;
		
		if frm.ShowModal = mrOk then begin
			Result := cbbModes.Text;
			
			if cbbModes.Text = 'Default' then begin
				Patch := SelectPatch('Ygg_Rebalance.esp')
				BeginUpdate(Patch);
				try
					remove(GroupBySignature(Patch, 'WEAP'));
					remove(GroupBySignature(Patch, 'ARMO'));
					remove(GroupBySignature(Patch, 'AMMO'));
					Cleanmasters(Patch);
					AddMasterBySignature('ARMO');
					AddMasterBySignature('WEAP');
					AddMasterBySignature('AMMO');
					AddMasterBySignature('KWDA');
					AddMasterBySignature('ARMA');
				finally EndUpdate(Patch);
				end;
				LogMessage(2, 'Using ' + GetFileName(Patch) + ' due to Default mode',YggLogCurrentMessages);
			end else if cbbModes.Text = 'Single' then begin
				temp := GetFileName(SinglePlugin);
				temp := StringReplace(temp, '.esp', '', [rfReplaceAll]);
				temp := StringReplace(temp, '.esl', '', [rfReplaceAll]);
				temp := StringReplace(temp, '.esm', '', [rfReplaceAll]);
				Patch := SelectPatch(temp+' Ygg_Rebalance.esp');
				LogMessage(2, 'Using ' + GetFileName(Patch) + ' due to single mode',YggLogCurrentMessages);
				Patch := SelectPatch('Ygg_Rebalance.esp')
				BeginUpdate(Patch);
				try
					remove(GroupBySignature(Patch, 'WEAP'));
					remove(GroupBySignature(Patch, 'ARMO'));
					remove(GroupBySignature(Patch, 'AMMO'));
					Cleanmasters(Patch);
					AddMasterBySignature('ARMO');
					AddMasterBySignature('WEAP');
					AddMasterBySignature('AMMO');
					AddMasterBySignature('KWDA');
					AddMasterBySignature('ARMA');
				finally EndUpdate(Patch);
				end;
			end else if cbbModes = 'Direct' then 
				Patch := SelectPatch(cbbPlugins.Text);
			else begin	//fixed
				//check ini to see if settings are already saved
				//patch is from ini
				
			end;
			
		end else result := 'abort';
	finally
		frm.Free;
	end;
	YggIni.Update;
end;

Procedure TrustSelection(Sender: TObject);
var
	lblAddPlugin: TLabel;
	btnAdd, btnOk, btnCancel, btnRemove: TButton;	
	ddAddPlugin, ddDetectedFile: TComboBox;
	slTemp, slFiles: TStringList;
	ALLAfile, tempFile, tempRecord: IInterface;
	frm: TForm;
	i, x, y: Integer;
begin
	
	slFiles := TStringList.Create;
	slTemp := TStringList.Create;
	
	for i := 0 to Pred(FileCount) do
	begin
		kFile := FileByIndex(i);
		if IsEditable(kFile) then
			cbbPlugins.Items.Add(GetFileName(kFile));
	end;
	
	frm := TForm.Create(nil);
	try	
		btnOK := nil;
		btnCancel := nil;
			
		frm.Width := 200 * scaleFactor;
		frm.Height := 75 * scaleFactor;
		frm.Position := poScreenCenter;
		frm.Caption := 'Add Trusted Plugins here';
		
		ScrollFrm := TScrollBox.Create(frm);
		ScrollFrm.Parent := frm;
		ScrollFrm.Height := 25 * scaleFactor;
		ScrollFrm.Top := 25 * scaleFactor;
		ScrollFrm.Left := 20 * scaleFactor;
		
		lblAddPlugin := TLabel.Create(ScrollFrm);
		lblAddPlugin.Parent := frm;
		lblAddPlugin.Height := 24;
		lblAddPlugin.Top := 68+24+24;
		lblAddPlugin.Left := 60;
		lblAddPlugin.Caption := 'Add Plugin: ';
		if frm.Height > 500 then begin
			frm.Height := frm.Height+lblAddPlugin.Height+12;
			ScrollFrm.Height := lblAddPlugin.Height;
		end else begin
			frm.Height := 500;
		end;
		
		// Add Plugin Drop Down
		ddAddPlugin := TComboBox.Create(frm);
		ddAddPlugin.Parent := frm;
		ddAddPlugin.Height := lblAddPlugin.Height;
		ddAddPlugin.Top := lblAddPlugin.Top - 2;		
		ddAddPlugin.Left := ddDetectedFile.Left;
		ddAddPlugin.Width := 480;
		for i := 0 to FileCount-1 do
			if not (StrEndsWith(GetFileName(FileByIndex(i)), '.exe') or slContains(slGlobal, GetFileName(FileByIndex(i)))) then
				ddAddPlugin.Items.Add(GetFileName(FileByIndex(i)));
		ddAddPlugin.AutoComplete := True;

		// Add Button
		btnAdd := TButton.Create(frm);
		btnAdd.Parent := frm;
		btnAdd.Caption := 'Add';
		btnAdd.Left := ddAddPlugin.Left+ddAddPlugin.Width+8;
		btnAdd.Top := lblAddPlugin.Top;
		btnAdd.Width := 100;
		btnAdd.OnClick := Btn_AddOrRemove_OnClick;
		
		// Ok Button
		btnOk := TButton.Create(frm);
		btnOk.Parent := frm;
		btnOk.Caption := 'Ok';		
		btnOk.Left := (frm.Width div 2)-btnOk.Width-8;
		btnOk.Top := frm.Height-80;
		btnOk.ModalResult := mrOk;
	
		// Cancel Button
		btnCancel := TButton.Create(frm);
		btnCancel.Parent := frm;
		btnCancel.Caption := 'Cancel';	
		btnCancel.Left := btnOk.Left+btnOk.Width+16;
		btnCancel.Top := btnOk.Top;	
		btnCancel.ModalResult := mrCancel;
		
		frm.ShowModal;
		if frm.ModalResult = mrOk then begin
			
		end else begin
			
		end;
	finally
		frm.Free;
	end;
	
	// Finalize
	slFiles.Free;
	slTemp.Free;

end;

Procedure FixedSettings;
var
    FixedSetting: TLabel;
    FixedScrollBox: TScrollBox;
    Save: TButton;
    Finish: TButton;
    ArmoWeapAmmoSelect: TComboBox;
    AddressValue: TListView;
    Reset: TButton;
begin
	
end;

procedure IniProcess;
var
	kFile: IInterface;
	i: integer;
begin
	TrustedPlugins := TStringList.Create;
	TrustedPlugins.Delimiter := ',';
	TrustedPlugins.StrictDelimiter := True;
	YggIni := TIniFile.Create(ScriptsPath + 'Ygg.ini');
	TrustedPlugins.DelimitedText := YggIni.ReadString('BaseData', 'sBaseMaster', '.esp');
	if not TrustedPlugins.count <= 1 then 
		YggIni.WriteString('BaseData', 'sBaseMaster', 'Skyrim.esm,Dragonborn.esm,Update.esm,Dawnguard.esm,HearthFires.esm,SkyrimSE.exe,Unofficial Skyrim Special Edition Patch.esp');
	TrustedPlugins.DelimitedText := YggIni.ReadString('BaseData', 'sBaseMaster', '.esp');
	YggIni.UpdateFile;
	if SingleFile then begin
		for i := 0 to Pred(FileCount) do
		begin
			kFile := FileByIndex(i);
			if not equals(SinglePlugin,kFile) then
				TrustedPlugins.Add(GetFileName(kFile));
		end;
	end;
end;

procedure InitializeCalcLists;
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

procedure InitializeProcLists;
var
	i,j:integer;
	CurrentFile,CurrentGroup,CurrentItem:IInterface;
	BNAM:IInterface;
begin
	LogMessage(1,'Gathering Lists',YggLogCurrentMessages);
	
	Armo := TStringList.Create;
	Ammo := TStringList.Create;
	Weap := TStringList.Create;
	for i := FileCount - 1 downto 0 do begin
		CurrentFile := FileByIndex(i);
		//armo
		if HasGroup(CurrentFile, 'ARMO') then begin
			AddProcArmo(CurrentFile);
			LogMessage(1, 'Checked ARMO In ' + GetFileName(CurrentFile),YggLogCurrentMessages);
		end;
		//weap
		if HasGroup(CurrentFile, 'WEAP') then begin
			AddProcWeap(CurrentFile);
			LogMessage(1, 'Checked WEAP In ' + GetFileName(CurrentFile),YggLogCurrentMessages);
		end;
		//ammo
		if HasGroup(CurrentFile, 'AMMO') then begin
			AddProcAmmo(CurrentFile);
			LogMessage(1, 'Checked AMMO In ' + GetFileName(CurrentFile),YggLogCurrentMessages);
		end;
	end;
end;

procedure AddArmo(CurrentFile: IInterface);
var
	i,j,k:integer;
	CurrentGroup,CurrentItem:IInterface;
	wo,Keywords:IInterface;
	CurrentKeyword,CurrentAddress,CurrentBOD2:string;
begin
	CurrentGroup := GroupBySignature(CurrentFile, 'ARMO');
	for j := ElementCount(CurrentGroup) - 1 downto 0 do begin
		CurrentItem := ElementByIndex(CurrentGroup, j);
		if GetIsDeleted(CurrentItem) then continue;
		if ContainsText(LowerCase(Name(CurrentItem)), 'skin') then continue;
		if hasKeyword(CurrentItem, 'Dummy') then continue;
		LogMessage(1, 'Adding ' + name(CurrentItem) + ' to lists',YggLogCurrentMessages);//for calculations
		if TrustedPlugins.IndexOf(GetFileName(GetFile(MasterOrSelf(CurrentItem)))) < 0 then continue;
		if IsWinningOverride(CurrentItem) then begin
			Keywords := ElementByPath(CurrentItem, 'KWDA');
			for k := ElementCount(Keywords) - 1 downto 0 do begin
				CurrentKeyword := LowerCase(EditorID(WinningOverride(LinksTo(ElementByIndex(Keywords,k)))));
				if ContainsText(CurrentKeyword, 'material') then begin
					LogMessage(1, 'Adding ' + name(CurrentItem) + ' to calculations processing',YggLogCurrentMessages);
					CurrentBOD2 := Name(ElementByIndex(ElementByPath(CurrentItem, 'BOD2\First Person Flags'),0));
					CurrentAddress := CurrentKeyword+CurrentBOD2;
					if assigned(GetElementEditValues(CurrentItem, 'DNAM')) then
						ArmoRating.AddObject(CurrentAddress, CurrentItem);
					if assigned(GetElementEditValues(CurrentItem, 'DATA\Weight')) then
						ArmoWeight.AddObject(CurrentAddress, CurrentItem);
					if assigned(GetElementEditValues(CurrentItem, 'DATA\Value')) then
						ArmoValue.AddObject(CurrentAddress, CurrentItem);
				end;
				if ContainsText(CurrentKeyword, 'materiel') then begin
					LogMessage(1, 'Adding ' + name(CurrentItem) + ' to calculations processing',YggLogCurrentMessages);
					CurrentBOD2 := Name(ElementByIndex(ElementByPath(CurrentItem, 'BOD2\First Person Flags'),0));
					CurrentAddress := CurrentKeyword+CurrentBOD2;
					if assigned(GetElementEditValues(CurrentItem, 'DNAM')) then
						ArmoRating.AddObject(CurrentAddress, CurrentItem);
					if assigned(GetElementEditValues(CurrentItem, 'DATA\Weight')) then
						ArmoWeight.AddObject(CurrentAddress, CurrentItem);
					if assigned(GetElementEditValues(CurrentItem, 'DATA\Value')) then
						ArmoValue.AddObject(CurrentAddress, CurrentItem);
				end;
			end;
		end;
	end;
end;

procedure AddWeap(CurrentFile: IInterface);
var
	i,j,k,code:integer;
	CurrentGroup,CurrentItem:IInterface;
	wo,Keywords:IInterface;
	CurrentKeyword,CurrentAddress,CurrentBOD2:string;
begin
	CurrentGroup := GroupBySignature(CurrentFile, 'WEAP');
	for j := ElementCount(CurrentGroup) - 1 downto 0 do begin
		CurrentItem := ElementByIndex(CurrentGroup, j);
		if GetIsDeleted(CurrentItem) then continue;
		if hasKeyword(CurrentItem, 'Dummy') then continue;
		LogMessage(1, 'Adding ' + name(CurrentItem) + ' to lists',YggLogCurrentMessages);
		//for processing
		if TrustedPlugins.IndexOf(GetFileName(GetFile(MasterOrSelf(CurrentItem)))) < 0 then continue;
		if IsWinningOverride(CurrentItem) then begin
			Keywords := ElementByPath(CurrentItem, 'KWDA');
			for k := ElementCount(Keywords) - 1 downto 0 do begin
				CurrentKeyword := LowerCase(EditorID(WinningOverride(LinksTo(ElementByIndex(Keywords,k)))));
				if ContainsText(CurrentKeyword, 'material') then begin
					LogMessage(1, 'Adding ' + name(CurrentItem) + ' to calculations processing',YggLogCurrentMessages);
					CurrentBOD2 := Name(ElementByPath(CurrentItem, 'DNAM\Animation Type'));
					CurrentAddress := CurrentKeyword+CurrentBOD2;
						if assigned(GetElementEditValues(CurrentItem, 'DATA\Damage')) then
							WeapDamage.AddObject(CurrentAddress, CurrentItem);
						if assigned(GetElementEditValues(CurrentItem, 'DATA\Weight')) then
							WeapWeight.AddObject(CurrentAddress, CurrentItem);
						if assigned(GetElementEditValues(CurrentItem, 'DATA\Value')) then
							WeapValue.AddObject(CurrentAddress, CurrentItem);
						if assigned(GetElementEditValues(CurrentItem, 'DNAM\Speed')) then
							WeapSpeed.AddObject(CurrentAddress, CurrentItem);
						if assigned(GetElementEditValues(CurrentItem, 'DNAM\Reach')) then
							WeapReach.AddObject(CurrentAddress, CurrentItem);
						if assigned(GetElementEditValues(CurrentItem, 'CRDT\Damage')) then
							WeapCrdtDam.AddObject(CurrentAddress, CurrentItem);
					if not StrToFloat(GetElementEditValues(CurrentItem, 'DNAM\Range Max')) = 0 then begin
						if assigned(GetElementEditValues(CurrentItem, 'DNAM\Range Min')) then
							WeapRangeMin.AddObject(CurrentAddress, CurrentItem);
						if assigned(GetElementEditValues(CurrentItem, 'DNAM\Range Max')) then
							WeapRangeMax.AddObject(CurrentAddress, CurrentItem);
					end;
				end;
				if ContainsText(CurrentKeyword, 'materiel') then begin
					LogMessage(1, 'Adding ' + name(CurrentItem) + ' to calculations processing',YggLogCurrentMessages);
					CurrentBOD2 := Name(ElementByPath(CurrentItem, 'DNAM\Animation Type'));
					CurrentAddress := CurrentKeyword+CurrentBOD2;
						if assigned(GetElementEditValues(CurrentItem, 'DATA\Damage')) then
							WeapDamage.AddObject(CurrentAddress, CurrentItem);
						if assigned(GetElementEditValues(CurrentItem, 'DATA\Weight')) then
							WeapWeight.AddObject(CurrentAddress, CurrentItem);
						if assigned(GetElementEditValues(CurrentItem, 'DATA\Value')) then
							WeapValue.AddObject(CurrentAddress, CurrentItem);
						if assigned(GetElementEditValues(CurrentItem, 'DNAM\Speed')) then
							WeapSpeed.AddObject(CurrentAddress, CurrentItem);
						if assigned(GetElementEditValues(CurrentItem, 'DNAM\Reach')) then
							WeapReach.AddObject(CurrentAddress, CurrentItem);
						if assigned(GetElementEditValues(CurrentItem, 'CRDT\Damage')) then
							WeapCrdtDam.AddObject(CurrentAddress, CurrentItem);
					if not StrToFloat(GetElementEditValues(CurrentItem, 'DNAM\Range Max')) = 0 then begin
						if assigned(GetElementEditValues(CurrentItem, 'DNAM\Range Min')) then
							WeapRangeMin.AddObject(CurrentAddress, CurrentItem);
						if assigned(GetElementEditValues(CurrentItem, 'DNAM\Range Max')) then
							WeapRangeMax.AddObject(CurrentAddress, CurrentItem);
					end;
				end;
			end;
		end;
	end;
end;

procedure AddAmmo(CurrentFile: IInterface);
var
	i,j,k:integer;
	CurrentGroup,CurrentItem:IInterface;
	wo,Keywords:IInterface;
	CurrentKeyword,CurrentAddress,CurrentBOD2:string;
begin
	LogMessage(0, 'ammoprocessing',YggLogCurrentMessages);
	CurrentGroup := GroupBySignature(CurrentFile, 'AMMO');
	for j := ElementCount(CurrentGroup) - 1 downto 0 do begin
		LogMessage(1, 'Adding ' + GetFileName(CurrentGroup) + ' to ammo lists',YggLogCurrentMessages);
		CurrentItem := ElementByIndex(CurrentGroup, j);
		if GetIsDeleted(CurrentItem) then continue;
		if hasKeyword(CurrentItem, 'Dummy') then continue;
		LogMessage(1, 'Adding ' + name(CurrentItem) + ' to lists',YggLogCurrentMessages);
		//for calculations
		if TrustedPlugins.IndexOf(GetFileName(GetFile(MasterOrSelf(CurrentItem)))) < 0 then continue;
		if IsWinningOverride(CurrentItem) then begin
			Keywords := ElementByPath(CurrentItem, 'KWDA');
			for k := ElementCount(Keywords) - 1 downto 0 do begin
				CurrentKeyword := LowerCase(EditorID(WinningOverride(LinksTo(ElementByIndex(Keywords,k)))));
				LogMessage(1, 'Adding ' + name(CurrentItem) + ' to calculations processing',YggLogCurrentMessages);
				CurrentBOD2 := Name(ElementByPath(CurrentItem, 'Data\Flags\Non-Bolt'));
				CurrentAddress := CurrentKeyword+CurrentBOD2;
				if assigned(GetElementEditValues(CurrentItem, 'DATA\Weight')) then
					AmmoWeight.AddObject(CurrentAddress, CurrentItem);
				if assigned(GetElementEditValues(CurrentItem, 'DATA\Damage')) then
					AmmoDamage.AddObject(CurrentAddress, CurrentItem);
				if assigned(GetElementEditValues(CurrentItem, 'DATA\Value')) then
					AmmoValue.AddObject(CurrentAddress, CurrentItem);
			end;
		end;
	end;
end;

procedure AddProcArmo(CurrentFile: IInterface);
var
	i,j,k:integer;
	CurrentGroup,CurrentItem:IInterface;
	wo,Keywords:IInterface;
	CurrentKeyword,CurrentAddress,CurrentBOD2:string;
begin
	CurrentGroup := GroupBySignature(CurrentFile, 'ARMO');
	for j := ElementCount(CurrentGroup) - 1 downto 0 do begin
		CurrentItem := ElementByIndex(CurrentGroup, j);
		if GetIsDeleted(CurrentItem) then continue;
		if ContainsText(LowerCase(Name(CurrentItem)), 'skin') then continue;
		if hasKeyword(CurrentItem, 'Dummy') then continue;
		LogMessage(1, 'Adding ' + name(CurrentItem) + ' to lists',YggLogCurrentMessages);
		//for processing
		if mode = 'Single' or mode = 'Direct' then begin
			if equals(getFile(CurrentItem), SinglePlugin) then begin
				wo := WinningOverride(CurrentItem);
				Armo.AddObject(EditorID(wo), wo);
			end
		end else if IsWinningOverride(CurrentItem) then Armo.AddObject(EditorID(CurrentItem), CurrentItem);
	end;
end;

procedure AddProcWeap(CurrentFile: IInterface);
var
	i,j,k,code:integer;
	CurrentGroup,CurrentItem:IInterface;
	wo,Keywords:IInterface;
	CurrentKeyword,CurrentAddress,CurrentBOD2:string;
begin
	CurrentGroup := GroupBySignature(CurrentFile, 'WEAP');
	for j := ElementCount(CurrentGroup) - 1 downto 0 do begin
		CurrentItem := ElementByIndex(CurrentGroup, j);
		if GetIsDeleted(CurrentItem) then continue;
		if hasKeyword(CurrentItem, 'Dummy') then continue;
		LogMessage(1, 'Adding ' + name(CurrentItem) + ' to lists',YggLogCurrentMessages);
		//for processing
		if mode = 'Single' or mode = 'Direct' then begin
			if equals(getFile(CurrentItem), SinglePlugin) then begin
				wo := WinningOverride(CurrentItem);
				Weap.AddObject(EditorID(wo), wo);
			end
		end else if IsWinningOverride(CurrentItem) then Weap.AddObject(EditorID(CurrentItem), CurrentItem);
	end;
end;

procedure AddProcAmmo(CurrentFile: IInterface);
var
	i,j,k:integer;
	CurrentGroup,CurrentItem:IInterface;
	wo,Keywords:IInterface;
	CurrentKeyword,CurrentAddress,CurrentBOD2:string;
begin
	LogMessage(0, 'ammoprocessing',YggLogCurrentMessages);
	CurrentGroup := GroupBySignature(CurrentFile, 'AMMO');
	for j := ElementCount(CurrentGroup) - 1 downto 0 do begin
		LogMessage(1, 'Adding ' + GetFileName(CurrentGroup) + ' to ammo lists',YggLogCurrentMessages);
		CurrentItem := ElementByIndex(CurrentGroup, j);
		if GetIsDeleted(CurrentItem) then continue;
		if hasKeyword(CurrentItem, 'Dummy') then continue;
		LogMessage(1, 'Adding ' + name(CurrentItem) + ' to lists',YggLogCurrentMessages);
		//for processing
		if mode = 'Single' or mode = 'Direct' then begin
			if equals(getFile(CurrentItem), SinglePlugin) then begin
				WO := WinningOverride(CurrentItem);
				Ammo.AddObject(EditorID(WO), WO);
			end
		end else if IsWinningOverride(CurrentItem) then Ammo.AddObject(EditorID(CurrentItem), CurrentItem);
	end;
end;

procedure FinalizeArmo;
begin
	LogMessage(1,'processing ratings',YggLogCurrentMessages);
	averager('DNAM',ArmoRating,Armo);
	
	LogMessage(1,'processing Armo Weight',YggLogCurrentMessages);
	averager('DATA\Weight',ArmoWeight,Armo);
	
	LogMessage(1,'processing armo Value',YggLogCurrentMessages);
	averager('DATA\Value',ArmoValue,Armo);
	
end;

procedure FinalizeWeap;
begin
	LogMessage(1,'processing weap Damage',YggLogCurrentMessages);
	averager('DATA\Damage',WeapDamage,Weap);
	LogMessage(1,'processing weap Weight',YggLogCurrentMessages);
	averager('DATA\Weight',WeapWeight,Weap);
	LogMessage(1,'processing weap Value',YggLogCurrentMessages);
	averager('DATA\Value',WeapValue,Weap);
	LogMessage(1,'processing weap speed',YggLogCurrentMessages);
	averager('DNAM\Speed',WeapSpeed,Weap);
	LogMessage(1,'processing weap reach',YggLogCurrentMessages);
	averager('DNAM\Reach',WeapReach,Weap);
	LogMessage(1,'processing weap critical damage',YggLogCurrentMessages);
	averager('CRDT\Damage',WeapCrdtDam,Weap);
	LogMessage(1,'processing weap minimum range',YggLogCurrentMessages);
	averager('DNAM\Range Min',WeapRangeMin,Weap);
	LogMessage(1,'processing weap maximum range',YggLogCurrentMessages);
	averager('DNAM\Range Max',WeapRangeMax,Weap);
end;

procedure FinalizeAmmo;
begin
	LogMessage(1,'processing Damage of ammos',YggLogCurrentMessages);
	averager('DATA\Damage',AmmoDamage,Ammo);
	
	LogMessage(1,'processing Ammo Weight',YggLogCurrentMessages);
	averager('DATA\Weight',AmmoWeight,Ammo);
	
	LogMessage(1,'processing ammo value',YggLogCurrentMessages);
	averager('DATA\Value',AmmoValue,Ammo);
	
end;

procedure averager(Path:string; out List:TStringList;backup: TStringList);
var
	i,listcount,j:integer;
	TempListA,TempListB:TStringList;
	backupcount:integer;
	TempbackupA,TempbackupB:TStringList;
	ratings,ara,inda:string;
	rating:double;
	CompleteAverage:double;
begin
	listcount := list.count;
	TempListA := TStringList.Create;
	for i := listcount - 1 downto 0 do begin
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
	List.clear;
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
	if listcount > 0 then
		CompleteAverage := CompleteAverage / listcount
	else begin
		backupcount := backup.count;
		TempbackupA := TStringList.Create;
		for i := backupcount - 1 downto 0 do begin
			ara := backup.Strings[i];
			inda := TempbackupA.IndexOf(ara);
			ratings := GetElementEditValues(ObjectToElement(backup.objects[i]), Path);
			if inda < 0 then
				TempbackupB := TStringList.Create
			else
				TempbackupB := TempbackupA.objects[inda];
			TempbackupB.Add(ratings);
			TempbackupA.AddObject(ara,TempbackupB);
		end;
		backup.clear;
		for i := TempbackupA.Count - 1 downto 0 do begin
			TempbackupB := TempbackupA.objects[i];
			rating := 0;
			for j := TempbackupB.count - 1 downto 0 do begin
				rating := rating + TryStrToFloat(TempbackupB.strings[j],5.0);
			end;
			rating := rating / TempbackupB.count;
			backup.AddObject(TempbackupA.strings[i],rating);
			completeAverage := CompleteAverage + Rating;
		end;
	
		CompleteAverage := 0;
		LogMessage(3, 'List contained no items, path: ' + path,YggLogCurrentMessages);
	end;
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
		CurrentItem := wbCopyElementToFile(CurrentItem, Patch, false,true);
		LogMessage(1,'Now Processing: ' + Name(CurrentItem),YggLogCurrentMessages);
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
		CurrentItem := wbCopyElementToFile(CurrentItem, Patch, false,true);
		LogMessage(1,'Now Processing: ' + Name(CurrentItem),YggLogCurrentMessages);
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
		CurrentItem := wbCopyElementToFile(CurrentItem, Patch, false,true);
		LogMessage(1,'Now Processing: ' + Name(CurrentItem),YggLogCurrentMessages);
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
	AddIndex:integer;
begin
	LogMessage(1,'Rating: ' + Name(item),YggLogCurrentMessages);
	OriginalRating := TryStrToFloat(GetElementEditValues(item, 'DNAM'),0);
	AddIndex := ArmoRating.IndexOf(address);
	if not AddIndex < 0 then
		averageRating := ArmoRating.objects[AddIndex]
	else AverageRating := ArmoRating.Objects[ArmoRating.IndexOf('averageofall')];
	temp := BalanceRandomizerfloat(OriginalRating,averageRating,7);
	SetElementEditValues(item, 'DNAM', FloatToStr(temp));
end;

Procedure Weight(item:IInterface;address:string);
var
	i,l,j:integer;
	cobjitem,path,cobj: IInterface;
	weightedAverage,WeightCobj,WeightExisting,Weight:double;
	temp: double;
	Amount,AddIndex,VaritionDiff:integer;
	breaker:integer;
begin
	LogMessage(1,'Weighing: ' + Name(item),YggLogCurrentMessages);
	//estimating weight
	
	if signature(item) = 'ARMO' then begin
		AddIndex := ArmoWeight.IndexOf(address);
		if not AddIndex < 0 then
			WeightExisting := ArmoWeight.objects[AddIndex]
		else ArmoWeight.Objects[ArmoWeight.IndexOf('averageofall')];
	end else if signature(item) = 'WEAP' then begin
		AddIndex := WeapWeight.IndexOf(address);
		if not AddIndex < 0 then
			WeightExisting := WeapWeight.objects[AddIndex]
		else WeapWeight.Objects[WeapWeight.IndexOf('averageofall')];
	end else begin
		AddIndex := AmmoWeight.IndexOf(address);
		if not AddIndex < 0 then
			WeightExisting := AmmoWeight.objects[AddIndex]
		else AmmoWeight.Objects[AmmoWeight.IndexOf('averageofall')];
	end;
	
	WeightCobj := 0;
	AddIndex := Recipes.IndexOf(EditorID(item));
	if not AddIndex < 0 then begin
		cobj := Recipes.objects[AddIndex];
		path := ElementByPath(cobj, 'Items');
		LogMessage(1,'processing cobj for item: ' + name(item),YggLogCurrentMessages);
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
	end else WeightCobj := WeightExisting;
	if Signature(item) = 'AMMO' then WeightCobj := WeightCobj / 24;
	if WeightExisting = 0 then WeightExisting := WeightCobj;
	weight := TryStrToFloat(GetElementEditValues(item, 'DATA\Weight'),0.0);
	LogMessage(1, 'the estimated weight based on cobj is: ' + FloatToStr(WeightCobj) + ' the estimated weight based on included items is: ' + FloatToStr(WeightExisting) + 'the current weight is: ' + FloatToStr(weight),YggLogCurrentMessages);
	if signature(item) = 'AMMO' then weightedAverage := WeightCobj * 0.7 + WeightExisting * 0.3
	else weightedAverage := WeightCobj * 0.3 + WeightExisting * 0.7;
	
	if weightedAverage = 0 then weightedAverage := weight;
	LogMessage(1,'averaged stuff out',YggLogCurrentMessages);
	VaritionDiff := 7;
	if weight > weightedAverage then
	begin
		temp := weightedAverage * (random(0.5) + 0.5);
	end else if weight < weightedAverage then
	begin
		temp := weightedAverage * (random(0.3) + 0.5);
	end else
	begin
		temp := weightedAverage * (random(0.4) + 0.5);
	end;
	breaker := 0;
	while temp > weightedAverage + VaritionDiff do begin
		if temp > weightedAverage then
		begin
			temp := temp - (VaritionDiff * (random(0.5) + 1));
		end else if temp < weightedAverage then
		begin
			temp := temp + (VaritionDiff * (random(0.5) + 0.5));
		end;
		if breaker > 5 then break;
		inc(breaker);
	end;
	breaker := 0;
	while temp < weightedAverage - VaritionDiff do begin
		if temp > weightedAverage then
		begin
			temp := temp - (VaritionDiff * (random(0.5) + 1));
		end else if temp < weightedAverage then
		begin
			temp := temp + (VaritionDiff * (random(0.5) + 0.5));
		end;
		if breaker > 5 then break;
		inc(breaker);
	end;
	LogMessage(1,'randomized weight',YggLogCurrentMessages);
	SetElementEditValues(item, 'Data\Weight', FloatToStr(temp));
end;

procedure Value(item:IInterface;address:string);
var
	i,j,l:integer;
	ValueAverage,ValueCobj,ValueExisting:double;
	Value:int;
	temp: double;
	Amount,AddIndex:integer;
	cobjitem,path,cobj: IInterface;
begin
	LogMessage(1,'valuing: ' + Name(item),YggLogCurrentMessages);
	
	if signature(item) = 'ARMO' then begin
		AddIndex := Armovalue.IndexOf(address);
		if not AddIndex < 0 then
			valueExisting := Armovalue.objects[AddIndex]
		else Armovalue.Objects[Armovalue.IndexOf('averageofall')];
	end else if signature(item) = 'WEAP' then begin
		AddIndex := Weapvalue.IndexOf(address);
		if not AddIndex < 0 then
			valueExisting := Weapvalue.objects[AddIndex]
		else Weapvalue.Objects[Weapvalue.IndexOf('averageofall')];
	end else begin 
		AddIndex := Ammovalue.IndexOf(address);
		if not AddIndex < 0 then
			valueExisting := Ammovalue.objects[AddIndex]
		else Ammovalue.Objects[Ammovalue.IndexOf('averageofall')];
	end;
	
	ValueCobj := 0;
	AddIndex := Recipes.IndexOf(EditorID(item));
	if not AddIndex < 0 then begin
		cobj := ObjectToElement(recipes.objects[Recipes.IndexOf(EditorID(item))]);
		path := ElementByPath(cobj, 'Items');
		LogMessage(1,'processing cobj for item: ' + name(item),YggLogCurrentMessages);
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
	end else ValueCobj := valueExisting;
	if valueExisting = 0 then valueExisting := ValueCobj;
	
	Value := tryStrToInt(GetElementEditValues(item, 'DATA\Value'),0.0);
	LogMessage(1, 'the estimated Value based on cobj is: ' + FloatToStr(ValueCobj) + ' the estimated Value based on included items is: ' + FloatToStr(ValueExisting) + 'the current Value is: ' + FloatToStr(Value),YggLogCurrentMessages);
	
	if signature(item) = 'AMMO' then ValueAverage := ValueCobj * 0.7 + valueExisting * 0.3
	else ValueAverage := ValueCobj * 0.3 + valueExisting * 0.7;
	if ValueAverage = 0 then ValueAverage := Value;
	
	temp := BalanceRandomizerInt(Value,ValueAverage,500);
	SetElementEditValues(item, 'Data\Value', IntToStr(floor(temp)));
end;

procedure WeapProcess(item:IInterface;address:string);
var
	original,temp,existing: double;
	originali,tempi: int;
	AddIndex:integer;
begin
	LogMessage(1,'sharpening: ' + Name(item),YggLogCurrentMessages);
	original := tryStrToFloat(GetElementEditValues(item, 'DNAM\Speed'), 1.0);
		AddIndex := WeapSpeed.IndexOf(address);
		if not AddIndex < 0 then
			existing := WeapSpeed.objects[AddIndex]
		else WeapSpeed.Objects[WeapSpeed.IndexOf('averageofall')];
	temp := BalanceRandomizerfloat(original,existing,0.5);
	SetElementEditValues(item, 'DNAM\Speed', FloatToStr(temp));
	
	originali := tryStrToInt(GetElementEditValues(item, 'DATA\Damage'), 1);
		AddIndex := WeapDamage.IndexOf(address);
		if not AddIndex < 0 then
			existing := WeapDamage.objects[AddIndex]
		else WeapDamage.Objects[WeapDamage.IndexOf('averageofall')];
	tempi := BalanceRandomizerInt(original,existing,5);
	SetElementEditValues(item, 'DATA\Damage', IntToStr(temp));
	
	original := tryStrToFloat(GetElementEditValues(item, 'DNAM\Reach'), 1.0);
		AddIndex := WeapReach.IndexOf(address);
		if not AddIndex < 0 then
			existing := WeapReach.objects[AddIndex]
		else WeapReach.Objects[WeapReach.IndexOf('averageofall')];
	temp := BalanceRandomizerfloat(original,existing,0.5);
	SetElementEditValues(item, 'DNAM\Reach', FloatToStr(temp));
	
	originali := tryStrToInt(GetElementEditValues(item, 'CRDT\Damage'), 1);
		AddIndex := WeapCrdtDam.IndexOf(address);
		if not AddIndex < 0 then
			existing := WeapCrdtDam.objects[AddIndex]
		else WeapCrdtDam.Objects[WeapCrdtDam.IndexOf('averageofall')];
	tempi := BalanceRandomizerInt(original,existing,5);
	SetElementEditValues(item, 'CRDT\Damage', IntToStr(temp));
	if not TryStrToFloat(GetElementEditValues(CurrentItem, 'DNAM\Range Min'), 0) = 0 then begin
		original := tryStrToFloat(GetElementEditValues(item, 'DNAM\Range Min'), 1.0);
			AddIndex := WeapRangeMin.IndexOf(address);
			if not AddIndex < 0 then
				existing := WeapRangeMin.objects[AddIndex]
			else WeapRangeMin.Objects[WeapRangeMin.IndexOf('averageofall')];
		temp := BalanceRandomizerfloat(original,existing,500);
		SetElementEditValues(item, 'DNAM\Range Min', FloatToStr(temp));
		
		original := tryStrToFloat(GetElementEditValues(item, 'DNAM\Range Max'), 1.0);
			AddIndex := WeapRangeMax.IndexOf(address);
			if not AddIndex < 0 then
				existing := WeapRangeMax.objects[AddIndex]
			else WeapRangeMax.Objects[WeapRangeMax.IndexOf('averageofall')];
		temp := BalanceRandomizerfloat(original,existing,500);
		SetElementEditValues(item, 'DNAM\Range Max', FloatToStr(temp));
	end;
end;

procedure AmmoProcess(item:IInterface;address:string);
var
	original,temp,existing: double;
	originali,tempi: int;
	AddIndex:integer;
begin
	LogMessage(1,'firing: ' + Name(item),YggLogCurrentMessages);
	original := tryStrToFloat(GetElementEditValues(item, 'DATA\Damage'), 1.0);
		AddIndex := AMMODamage.IndexOf(address);
		if not AddIndex < 0 then
			existing := AMMODamage.objects[AddIndex]
		else AMMODamage.Objects[AMMODamage.IndexOf('averageofall')];
	temp := BalanceRandomizerfloat(original,existing,5);
	SetElementEditValues(item, 'DATA\Damage', IntToStr(floor(temp)));
end;

function BalanceRandomizerInt(original:int;existing:float;VaritionDiff:float):int;
var
	temp:double;
	breaker:integer;
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
	breaker := 0;
	while temp > existing + VaritionDiff do begin
		if temp > existing then
		begin
			temp := temp - (VaritionDiff * (random(0.5) + 1));
		end else if temp < existing then
		begin
			temp := temp + (VaritionDiff * (random(0.5) + 0.5));
		end;
		if breaker > 5 then break;
		inc(breaker);
	end;
	breaker := 0;
	while temp < existing - VaritionDiff do begin
		if temp > existing then
		begin
			temp := temp - (VaritionDiff * (random(0.5) + 1));
		end else if temp < existing then
		begin
			temp := temp + (VaritionDiff * (random(0.5) + 0.5));
		end;
		if breaker > 5 then break;
		inc(breaker);
	end;
	result := floor(temp);
end;

function BalanceRandomizerfloat(original,existing:float;VaritionDiff:float):float;
var
	temp: double;
	breaker:integer;
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
	breaker := 0;
	while temp > existing + VaritionDiff do begin
		if temp > existing then
		begin
			temp := temp - (VaritionDiff * (random(0.5) + 1));
		end else if temp < existing then
		begin
			temp := temp + (VaritionDiff * (random(0.5) + 0.5));
		end;
		if breaker > 5 then break;
		inc(breaker);
	end;
	breaker := 0;
	while temp < existing - VaritionDiff do begin
		if temp > existing then
		begin
			temp := temp - (VaritionDiff * (random(0.5) + 1));
		end else if temp < existing then
		begin
			temp := temp + (VaritionDiff * (random(0.5) + 0.5));
		end;
		if breaker > 5 then break;
		inc(breaker);
	end;
	result := temp;
end;

end.