
--
-- Populates the entity menu with categories and entities
--
hook.Add("PopulateFWEntities", "AddFWEntityContent", function(pnlContent, tree, node)

	local categorised = {};
    local fortWarsEntities = list.Get("FortWarsEntities");
    
	for k, v in pairs(fortWarsEntities) do

		print("Loading ent: " .. v.SpawnName .. " - " .. v.Category);
		v.Category = v.Category or "Other";
		categorised[v.Category] = categorised[v.Category] or {};
		table.insert(categorised[v.Category], v);

	end

	for categoryName, v in SortedPairs(categorised) do

        local groupIcon = "icon16/bricks.png";
		if (categoryName == "Weapons") then
			
			groupIcon = "icon16/bomb.png";

		elseif (categoryName == "Defense") then

			groupIcon = "icons16/stop.png";
		
		elseif (categoryName == "Healing") then

			groupIcon = "icons16/heart.png";

		elseif (categoryName == "Ammo") then

			groupIcon = "icons16/package.png";
			
		end
		
		local node = tree:AddNode(categoryName, groupIcon);

		node.DoPopulate = function(self)

			if (self.PropPanel) then return end

			self.PropPanel = vgui.Create("ContentContainer", pnlContent);
			self.PropPanel:SetVisible(false);
			self.PropPanel:SetTriggerSpawnlistChange(false);
			
			for k, ent in SortedPairsByMemberValue(v, "PrintName") do

				local icon = spawnmenu.CreateContentIcon( ent.ScriptedEntityType or "entity", self.PropPanel, 
				{
					nicename	= ent.PrintName or ent.ClassName,
					spawnname	= ent.SpawnName,
					material	= ent.IconOverride or "entities/" .. ent.SpawnName .. ".png",
					admin		= false
				});

				if (ENTITY_COSTS[ent.SpawnName]) then
					
					icon:SetToolTip(ent.PrintName .. " ($" .. ENTITY_COSTS[ent.SpawnName] .. ")");					
				
				else

					icon:SetToolTip(ent.PrintName .. " ($0)");

				end

			end
		end

		node.DoClick = function(self)
			
			self:DoPopulate();
			pnlContent:SwitchPanel(self.PropPanel);
			
		end

	end
    
    local firstNode = tree:Root():GetChildNode(0);
	if (IsValid(firstNode)) then
		
		firstNode:InternalDoClick();
		
	end
	
end);

--[[---------------------------------------------------------
	Name: fortwars.AddEntity(category, printName, spawnName, scriptedEntityType, iconOverride)
	Desc: Add an entity to the Fort Wars entity spawn menu.
-----------------------------------------------------------]]
function fortwars.AddEntity(category, printName, spawnName, scriptedEntityType, iconOverride)

    local ent = {};
	
	ent.Category = category;
	ent.PrintName = printName;
	ent.SpawnName = spawnName;
    ent.IconOverride = iconOverride;
	ent.ScriptedEntityType = scriptedEntityType;
	ent.AdminOnly = false;

	list.Add("FortWarsEntities", ent);
	
end

--
-- Here is where we add the default Fort Wars entities
--
fortwars.AddEntity("Defense", "Turret", "npc_turret_floor", "npc", nil);
fortwars.AddEntity("Defense", "Ceiling Turret", "npc_turret_ceiling", "npc", nil);
fortwars.AddEntity("Defense", "Camera", "npc_combine_camera", "npc", nil);
fortwars.AddEntity("Defense", "Hopper Mine", "combine_mine", "entity", nil);

fortwars.AddEntity("Healing", "Health Kit", "item_healthkit", "entity", nil);
fortwars.AddEntity("Healing", "Health Vial", "item_healthvial", "entity", nil);
fortwars.AddEntity("Healing", "Health Charger", "item_healthcharger", "entity", nil);
fortwars.AddEntity("Healing", "Suit Battery", "item_battery", "entity", nil);
fortwars.AddEntity("Healing", "Suit Charger", "item_suitcharger", "entity", nil);

fortwars.AddEntity("Weapons", "Pistol", "weapon_pistol", "weapon", nil);

fortwars.AddEntity("Ammo", "Pistol Ammo", "item_ammo_pistol", "entity", nil);

--
-- Adds the entity menu
--
spawnmenu.AddCreationTab("Entities", function()

	local ctrl = vgui.Create("SpawnmenuContentPanel");
	ctrl:EnableSearch("entities", "PopulateFWEntities");
    ctrl:CallPopulateHook("PopulateFWEntities");
    
	return ctrl;

end, "icon16/sport_8ball.png", 0);
