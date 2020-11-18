
AddCSLuaFile();
DEFINE_BASECLASS("base_gmodentity");

ENT.Spawnable = true;
ENT.AdminOnly = false;
ENT.PrintName = "Unassigned Spawner";

function ENT:Initialize()

	BaseClass.Initialize(self);

end

function ENT:SetupDataTables()



end

