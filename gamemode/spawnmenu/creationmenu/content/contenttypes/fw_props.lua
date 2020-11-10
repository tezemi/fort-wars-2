
hook.Add("PopulateFWProps", "AddFWEntityContent", function(pnlContent, tree, node)

	local categorised = {};
    local fortWarsProps = list.Get("FortWarsPropPaths");
    
	for k, v in pairs(fortWarsProps) do

		v.Category = v.Category or "Other";
		categorised[v.Category] = categorised[v.Category] or {};
        table.insert(categorised[v.Category], v);

	end

	for categoryName, v in SortedPairs(categorised) do

        local node = tree:AddNode(categoryName, "icon16/brick.png");
                
		node.DoPopulate = function(self)

			if (self.PropPanel) then return end

			self.PropPanel = vgui.Create("ContentContainer", pnlContent);
			self.PropPanel:SetVisible(false);
            self.PropPanel:SetTriggerSpawnlistChange(false);
                        
			for k, path in SortedPairsByMemberValue(v, "PrintName") do

                if (path.IsPath) then

                    local nodePath = path.PathToProps;
                    local searchString = nodePath .. "/*.mdl";
            
                    local models = file.Find(searchString, "GAME")
                    if (models) then
    
                        for k, v in pairs(models) do
    
                            local fun = spawnmenu.GetContentType("model");
                            if (fun) then
    
                                fun(self.PropPanel, { model = nodePath .. "/" .. v });
    
                            end
    
                        end
    
                    end

                else

                    local fun = spawnmenu.GetContentType("model");
                    if (fun) then

                        fun(self.PropPanel, { model = path.PathToProps });

                    end

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
	Name: fortwars.AddPropFolder(pathToProps)
    Desc: Add a path to Fort Wars's prop list, loading all
          props for use.
-----------------------------------------------------------]]
function fortwars.AddPropFolder(category, pathToProps)

    local path = {};

    path.Category = category;
    path.PathToProps = pathToProps;
    path.IsPath = true;

    list.Add("FortWarsPropPaths", path);
	
end

--[[---------------------------------------------------------
	Name: fortwars.AddProp(pathToProps)
	Desc: Add a prop to a category.
-----------------------------------------------------------]]
function fortwars.AddProp(category, pathToProp)

    local prop = {};

    prop.Category = category;
    prop.PathToProps = pathToProp;
    prop.IsPath = false;

    list.Add("FortWarsPropPaths", prop);
	
end

-- Default Fort Wars prop folders
fortwars.AddPropFolder("Blocks", "models/hunter/blocks");
fortwars.AddPropFolder("Plates", "models/hunter/plates");
fortwars.AddPropFolder("Solid Steel", "models/mechanics/solid_steel");
fortwars.AddPropFolder("Super Flat Plates", "models/squad/sf_plates");

-- Default props
fortwars.AddProp("Dangerous", "models/props_c17/oildrum001_explosive.mdl");
fortwars.AddProp("Dangerous", "models/props_junk/gascan001a.mdl");
fortwars.AddProp("Dangerous", "models/props_junk/sawblade001a.mdl");
fortwars.AddProp("Misc", "models/props_c17/concrete_barrier001a.mdl");
fortwars.AddProp("Misc", "models/props_c17/furniturebathtub001a.mdl");
fortwars.AddProp("Misc", "models/props_c17/furniturechair001a.mdl");
fortwars.AddProp("Misc", "models/props_c17/furniturecouch001a.mdl");
fortwars.AddProp("Misc", "models/props_c17/furniturecouch002a.mdl");
fortwars.AddProp("Misc", "models/props_c17/furnituredrawer001a.mdl");
fortwars.AddProp("Misc", "models/props_c17/furnituretable001a.mdl");

spawnmenu.AddCreationTab("Props", function()

	local ctrl = vgui.Create("SpawnmenuContentPanel");
	ctrl:EnableSearch("props", "PopulateFWProps");
    ctrl:CallPopulateHook("PopulateFWProps");
    
	return ctrl;

end, "icon16/brick.png", 0);
