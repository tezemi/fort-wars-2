
include( "spawnmenu/spawnmenu.lua" )

--[[---------------------------------------------------------
	If false is returned then the spawn menu is never created.
	This saves load times if your mod doesn't actually use the
	spawn menu for any reason.
-----------------------------------------------------------]]
function GM:SpawnMenuEnabled()

	return true;

end

--[[---------------------------------------------------------
	Called when spawnmenu is trying to be opened.
	Return false to dissallow it.
-----------------------------------------------------------]]
function GM:SpawnMenuOpen()

	if (GetGlobalInt("FW_RoundState") == ROUND_BUILD) then

		return true;

	end

	return false;
	
end

function GM:SpawnMenuOpened()
	self:SuppressHint( "OpeningMenu" )
	self:AddHint( "OpeningContext", 20 )
	self:AddHint( "EditingSpawnlists", 5 )
end

function GM:SpawnMenuClosed()
end

function GM:SpawnMenuCreated(spawnmenu)
end

--[[---------------------------------------------------------
	If false is returned then the context menu is never created.
	This saves load times if your mod doesn't actually use the
	context menu for any reason.
-----------------------------------------------------------]]
function GM:ContextMenuEnabled()
	return false
end

--[[---------------------------------------------------------
	Called when context menu is trying to be opened.
	Return false to dissallow it.
-----------------------------------------------------------]]
function GM:ContextMenuOpen()
	return true
end

function GM:ContextMenuOpened()
	self:SuppressHint( "OpeningContext" )
	self:AddHint( "ContextClick", 20 )
end

function GM:ContextMenuClosed()
end

function GM:ContextMenuCreated()
end

--[[---------------------------------------------------------
	Backwards compatibility. Do Not Use!!!
-----------------------------------------------------------]]
function GM:GetSpawnmenuTools( name )
	return spawnmenu.GetToolMenu( name )
end

--[[---------------------------------------------------------
	Backwards compatibility. Do Not Use!!!
-----------------------------------------------------------]]
function GM:AddSTOOL( category, itemname, text, command, controls, cpanelfunction )
	self:AddToolmenuOption( "Main", category, itemname, text, command, controls, cpanelfunction )
end

function GM:PreReloadToolsMenu()
end

--[[---------------------------------------------------------
	Don't hook or override this function.
	Hook AddToolMenuTabs instead!
-----------------------------------------------------------]]
function GM:AddGamemodeToolMenuTabs()

	-- This is named like this to force it to be the first tab
	spawnmenu.AddToolTab( "Main",		"#spawnmenu.tools_tab", "icon16/wrench.png" )
	spawnmenu.AddToolTab( "Utilities",	"#spawnmenu.utilities_tab", "icon16/page_white_wrench.png" )

end

--[[---------------------------------------------------------
	Add your custom tabs here.
-----------------------------------------------------------]]
function GM:AddToolMenuTabs()

	-- Hook me!

end

--[[---------------------------------------------------------
	Add categories to your tabs
-----------------------------------------------------------]]
function GM:AddGamemodeToolMenuCategories()

	spawnmenu.AddToolCategory( "Main", "Constraints",	"#spawnmenu.tools.constraints" )
	spawnmenu.AddToolCategory( "Main", "Construction",	"#spawnmenu.tools.construction" )
	spawnmenu.AddToolCategory( "Main", "Poser",			"#spawnmenu.tools.posing" )
	spawnmenu.AddToolCategory( "Main", "Render",		"#spawnmenu.tools.render" )

end

--[[---------------------------------------------------------
	Add categories to your tabs
-----------------------------------------------------------]]
function GM:AddToolMenuCategories()

	spawnmenu.AddToolMenuOption("Utilities", "Fort Wars", "fort_wars_config", "Starting Weapons", "", "", function(panel)

		local list = vgui.Create("DListView", panel);
		panel:AddItem(list);

		list:SetSize(500, 300);
		list:SetMultiSelect(true);
		list:AddColumn("Start Weapons");

		local convar = GetConVar("fw_start_weapons");
		for i in string.gmatch(convar:GetString(), "%S+") do

			list:AddLine(i);

		end

		local removeButton = vgui.Create("DButton", panel);
		panel:AddItem(removeButton);
				
		removeButton:Dock(BOTTOM);
		removeButton:SetText("Remove");

		removeButton.DoClick = function()

			local selectedItems = list:GetSelected();
			local allItems = list:GetLines();
			for k, v in pairs(selectedItems) do
				
				for l, w in pairs(allItems) do
					
					if (v:GetColumnText(1) == w:GetColumnText(1)) then

						RunConsoleCommand("fw_start_weapon_remove", v:GetColumnText(1));
						list:RemoveLine(l);

					end
					
				end				

			end

		end

		local addButton = vgui.Create("DButton", panel);
		panel:AddItem(addButton);
				
		addButton:Dock(BOTTOM);
		addButton:SetText("Add");

		local entry = vgui.Create("DTextEntry", panel);
		entry:DockMargin(0, 10, 0, 0);
		entry:DockPadding(5, 0, 5, 0);
		entry:Dock(TOP);

		addButton.DoClick = function()

			list:AddLine(entry:GetValue());
			RunConsoleCommand("fw_start_weapon_add", entry:GetValue());

		end

	end);

end

function GM:PopulateToolMenu()
end

function GM:PostReloadToolsMenu()
end

--[[---------------------------------------------------------
	Add categories to your tabs
-----------------------------------------------------------]]
function GM:PopulatePropMenu()

	-- This function makes the engine load the spawn menu text files.
	-- We call it here so that any gamemodes not using the default
	-- spawn menu can totally not call it.
	spawnmenu.PopulateFromEngineTextFiles()

end
