AddCSLuaFile();
DEFINE_BASECLASS("player_default")

local PLAYER = {} ;

PLAYER.WalkSpeed = 200;
PLAYER.RunSpeed  = 300;

function PLAYER:Loadout()

    self.Player:RemoveAllAmmo();

    self.Player:Give("weapon_crowbar");

    self.Player:GiveAmmo(64, "Pistol", true);
    self.Player:Give("weapon_pistol");

end

function PLAYER:SetModel()

	BaseClass.SetModel(self);
	
	local skin = self.Player:GetInfoNum("cl_playerskin", 0);
	self.Player:SetSkin(skin);

    local groups = self.Player:GetInfo("cl_playerbodygroups");    
    if (groups == nil) then

        groups = "";

    end

    local groups = string.Explode(" ", groups);

    for k = 0, self.Player:GetNumBodyGroups() - 1 do
        
        self.Player:SetBodygroup(k, tonumber(groups[k + 1]) or 0);
        
	end

end

function PLAYER:Spawn()

	BaseClass.Spawn(self);

	local col = self.Player:GetInfo("cl_playercolor");
	self.Player:SetPlayerColor(Vector(col));

	local col = Vector(self.Player:GetInfo("cl_weaponcolor"));
    if (col:Length() == 0) then
        
        col = Vector(0.001, 0.001, 0.001);
        
    end
    
	self.Player:SetWeaponColor(col);

end

function PLAYER:GetHandsModel()

    local cl_playermodel = self.Player:GetInfo("cl_playermodel");
    
	return player_manager.TranslatePlayerHands(cl_playermodel);

end

player_manager.RegisterClass("player_fight", PLAYER, "player_default");