
--
-- Default Fortwars entity prices
--
ENTITY_COSTS = {};
ENTITY_COSTS["npc_turret_floor"] = 250;
ENTITY_COSTS["npc_turret_ceiling"] = 400;
ENTITY_COSTS["combine_mine"] = 75;

ENTITY_COSTS["weapon_pistol"] = 75;
ENTITY_COSTS["weapon_smg1"] = 100;
ENTITY_COSTS["weapon_frag"] = 250;
ENTITY_COSTS["weapon_357"] = 400;
ENTITY_COSTS["weapon_shotgun"] = 200;
ENTITY_COSTS["weapon_ar2"] = 300;
ENTITY_COSTS["weapon_rpg"] = 600;
ENTITY_COSTS["weapon_crossbow"] = 600;
ENTITY_COSTS["weapon_slam"] = 600;


--
-- Defines what entites respawn after being picked up
--
RESPAWNABLE = {};
RESPAWNABLE["item_healthkit"] = true;
RESPAWNABLE["item_healthvial"] = true;
RESPAWNABLE["item_battery"] = true;
RESPAWNABLE["item_ammo_pistol"] = true;
RESPAWNABLE["combine_mine"] = true;

RESPAWNABLE["weapon_pistol"] = true;
RESPAWNABLE["weapon_smg1"] = true;
RESPAWNABLE["weapon_frag"] = true;
RESPAWNABLE["weapon_357"] = true;
RESPAWNABLE["weapon_shotgun"] = true;
RESPAWNABLE["weapon_ar2"] = true;
RESPAWNABLE["weapon_rpg"] = true;
RESPAWNABLE["weapon_crossbow"] = true;
RESPAWNABLE["weapon_slam"] = true;

--
-- Call this to add your own entities
--
function fortwars.AssignCost(name, amount)

   ENTITY_COSTS[name] = amount;

end

--[[---------------------------------------------------------
   Name: fortwars.UpdateNPCRelationship(team, npc)
   Desc: Updates an NPC's relationships, causing the NPC to
         like people of the same team, and dislike
         anyone else.
-----------------------------------------------------------]]
function fortwars.UpdateNPCRelationship(npc)

   local npcTeam = npc:GetNWInt("FW_Team", 1);

   for k, ply in pairs(player.GetAll()) do

      if (ply:Team() == npcTeam or ply:Team() == TEAM_SPEC) then

         npc:AddEntityRelationship(ply, D_LI, 99);

      else

         npc:AddEntityRelationship(ply, D_HT, 99);

      end        

   end

   npc:SetColor(team.GetColor(npcTeam));

end

--[[---------------------------------------------------------
   Name: fortwars.UpdateNPCRelationships()
   Desc: Updates every NPC's relationship, and so more
         expensive than the single NPC counterpart. 
-----------------------------------------------------------]]
function fortwars.UpdateNPCRelationships()

   for kn, npc in pairs(ents.FindByClass("npc_*")) do

      for kp, ply in pairs(player.GetAll()) do

         if (IsValid(npc) and IsValid(ply)) then

            local npcTeam = npc:GetNWInt("FW_Team", 1);

            if (ply:Team() == npcTeam or ply:Team() == TEAM_SPEC) then
   
               npc:AddEntityRelationship(ply, D_LI, 99);
   
            else
   
               npc:AddEntityRelationship(ply, D_HT, 99);
   
            end

         end

      end

   end

end

function fortwars.ForceRespawnableRespawn(ent, solidFlags)

   if (not IsValid(ent)) then return end

   ent:SetColor(Color(255, 255, 255, 255));
   ent:SetSolidFlags(solidFlags);

   ent:CallOnRemove("FW_RespawnEntity" .. ent:GetCreationID(), function(ent)
   
      print(ent:GetClass());
      local duplicate = ents.Create(ent:GetClass());
      duplicate:SetModel(ent:GetModel());
      duplicate:SetPos(ent:GetPos());
      duplicate:Spawn();

      fortwars.MakeRespawnable(duplicate);

   end);

end

function fortwars.ForceAllRespawnablesRespawn()

   for k, v in pairs(RESPAWNABLE) do
      
      if (v) then

         for ek, ev in pairs(ents.FindByClass(k)) do
             
            fortwars.ForceRespawnableRespawn(ev, 152);

         end

      end

   end

end

function fortwars.MakeRespawnable(ent)

   ent:SetRenderMode(RENDERMODE_TRANSCOLOR);
   ent:SetColor(Color(255, 255, 255, 127));
   
   local normalFlags = ent:GetSolidFlags();
   print(normalFlags);

   ent:SetSolidFlags(FSOLID_FORCE_WORLD_ALIGNED);

   if (GetGlobalInt("FW_RoundState", ROUND_BUILD) == ROUND_FIGHT) then

      timer.Simple(GetConVar("fw_entity_respawn_time"):GetInt(), function()

         fortwars.ForceRespawnableRespawn(ent, normalFlags);

      end);

   end

end

--[[---------------------------------------------------------
   Name: fortwars.SetTeam(ply, team)
   Desc: Sets the player's team and forces a respawn.
-----------------------------------------------------------]]
function fortwars.SetTeam(ply, teamID)

   ply:SetTeam(teamID);
   ply:Spawn();
   PrintMessage(HUD_PRINTTALK, ply:Nick() .. " joined the " .. team.GetName(teamID) .. " team.");
   fortwars.UpdateNPCRelationships();
   cleanup.CC_Cleanup(ply, "gmod_cleanup", {});

end

--
-- Gives a arbitrary cost for a prop based on its size
--
function fortwars.GetPropCost(ent)

   local propSize = ent:GetModelBounds().x + ent:GetModelBounds().y + ent:GetModelBounds().z;
   propSize = math.abs(propSize);

   local cost = propSize / 3;
   cost = math.floor(cost);

   return cost;

end

function RequestJoinTeam(len, ply)

   local teamID = net.ReadInt(32);
   fortwars.SetTeam(ply, teamID);

end
net.Receive("FW_RequestJoinTeam", RequestJoinTeam);

function SpawnWeapon(len, ply)

   local weaponPos = net.ReadVector();
   local class = net.ReadString();

   local e = ents.Create(class);
   e:SetPos(weaponPos);
   e:Spawn();

   fortwars.MakeRespawnable(e);

end
net.Receive("FW_SpawnWeapon", SpawnWeapon);


--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnObject( ply )
   Desc: Called to ask whether player is allowed to spawn any objects
-----------------------------------------------------------]]
function GM:PlayerSpawnObject( ply )
	return true
end

--[[---------------------------------------------------------
   Name: gamemode:CanPlayerUnfreeze( )
   Desc: Can the player unfreeze this entity & physobject
-----------------------------------------------------------]]
function GM:CanPlayerUnfreeze( ply, entity, physobject )

	if ( entity:GetPersistent() ) then return false end

	return true
end

--[[---------------------------------------------------------
   Name: LimitReachedProcess
-----------------------------------------------------------]]
local function LimitReachedProcess( ply, str )

	if ( !IsValid( ply ) ) then return true end

	return ply:CheckLimit( str )

end


--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnRagdoll( ply, model )
   Desc: Return true if it's allowed 
-----------------------------------------------------------]]
function GM:PlayerSpawnRagdoll( ply, model )

	return LimitReachedProcess( ply, "ragdolls" )

end


--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnProp( ply, model )
   Desc: Return true if it's allowed 
-----------------------------------------------------------]]
function GM:PlayerSpawnProp( ply, model )

	return LimitReachedProcess( ply, "props" )

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnEffect( ply, model )
   Desc: Return true if it's allowed 
-----------------------------------------------------------]]
function GM:PlayerSpawnEffect( ply, model )

	return LimitReachedProcess( ply, "effects" )

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnVehicle( ply, model, vname, vtable )
   Desc: Return true if it's allowed 
-----------------------------------------------------------]]
function GM:PlayerSpawnVehicle( ply, model, vname, vtable )

	return LimitReachedProcess( ply, "vehicles" )

end


--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnSWEP( ply, wname, wtable )
   Desc: Return true if it's allowed 
-----------------------------------------------------------]]
function GM:PlayerSpawnSWEP( ply, wname, wtable )

	return LimitReachedProcess( ply, "sents" )
	
end


--[[---------------------------------------------------------
   Name: gamemode:PlayerGiveSWEP( ply, wname, wtable )
   Desc: Return true if it's allowed 
-----------------------------------------------------------]]
function GM:PlayerGiveSWEP( ply, wname, wtable )

	return true

end


--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnSENT( ply, name )
   Desc: Return true if player is allowed to spawn the SENT
-----------------------------------------------------------]]
function GM:PlayerSpawnSENT( ply, name )

   if (ENTITY_COSTS[name]) then

      local amountAfterBuy = ply:GetNWInt("FW_Cash", 0) - ENTITY_COSTS[name];
      if (amountAfterBuy >= 0) then

         return LimitReachedProcess(ply, "sents");

      else

         return false;

      end

   end

	return LimitReachedProcess(ply, "sents");

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnNPC( ply, npc_type )
   Desc: Return true if player is allowed to spawn the NPC
-----------------------------------------------------------]]
function GM:PlayerSpawnNPC(ply, npc_type, equipment)

   if (ENTITY_COSTS[npc_type]) then

      local amountAfterBuy = ply:GetNWInt("FW_Cash", 0) - ENTITY_COSTS[npc_type];
      if (amountAfterBuy >= 0) then

         return LimitReachedProcess(ply, "npcs");

      else

         return false;

      end

   end

	return LimitReachedProcess(ply, "npcs");

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnedRagdoll( ply, model, ent )
   Desc: Called after the player spawned a ragdoll
-----------------------------------------------------------]]
function GM:PlayerSpawnedRagdoll( ply, model, ent )

	ply:AddCount( "ragdolls", ent )

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnedProp( ply, model, ent )
   Desc: Called after the player spawned a prop
-----------------------------------------------------------]]
function GM:PlayerSpawnedProp( ply, model, ent )

   local cost = fortwars.GetPropCost(ent);
   local amountAfterBuy = ply:GetNWInt("FW_Cash", 0) - cost;

   if (amountAfterBuy >= 0) then

      ply:SetNWInt("FW_Cash", amountAfterBuy);

   else

      ent:Remove();

   end
   
   ply:AddCount("props", ent);
   ent:SetNWEntity("FW_PlayerOwner", ply);

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnedEffect( ply, model, ent )
   Desc: Called after the player spawned an effect
-----------------------------------------------------------]]
function GM:PlayerSpawnedEffect( ply, model, ent )

	ply:AddCount( "effects", ent )

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnedVehicle( ply, ent )
   Desc: Called after the player spawned a vehicle
-----------------------------------------------------------]]
function GM:PlayerSpawnedVehicle( ply, ent )

	ply:AddCount( "vehicles", ent )

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnedNPC( ply, ent )
   Desc: Called after the player spawned an NPC
-----------------------------------------------------------]]
function GM:PlayerSpawnedNPC(ply, ent)

   if (ENTITY_COSTS[ent:GetClass()]) then

      local amountAfterBuy = ply:GetNWInt("FW_Cash", 0) - ENTITY_COSTS[ent:GetClass()];
      ply:SetNWInt("FW_Cash", amountAfterBuy);

   end
   
   ply:AddCount("npcs", ent);
   ent:SetNWEntity("FW_PlayerOwner", ply);
   ent:SetNWInt("FW_Team", ply:Team());
   fortwars.UpdateNPCRelationship(ent);

end


--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnedSENT( ply, ent )
   Desc: Called after the player has spawned a SENT
-----------------------------------------------------------]]
function GM:PlayerSpawnedSENT(ply, ent)

   if (ENTITY_COSTS[ent:GetClass()]) then

      local amountAfterBuy = ply:GetNWInt("FW_Cash", 0) - ENTITY_COSTS[ent:GetClass()];
      ply:SetNWInt("FW_Cash", amountAfterBuy);

   end

   ply:AddCount("sents", ent);
   ent:SetNWEntity("FW_PlayerOwner", ply);

   if (RESPAWNABLE[ent:GetClass()]) then -- TODO: Testing respawning

      fortwars.MakeRespawnable(ent);

   end

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawnedWeapon( ply, ent )
   Desc: Called after the player has spawned a Weapon
-----------------------------------------------------------]]
function GM:PlayerSpawnedSWEP( ply, ent )

	-- This is on purpose..
	ply:AddCount( "sents", ent )

end

--[[---------------------------------------------------------
   Name: gamemode:PlayerEnteredVehicle( player, vehicle, role )
   Desc: Player entered the vehicle fine
-----------------------------------------------------------]]
function GM:PlayerEnteredVehicle( player, vehicle, role )

	player:SendHint( "VehicleView", 2 )

end

--[[---------------------------------------------------------
	These are buttons that the client is pressing. They're used
	in Sandbox mode to control things like wheels, thrusters etc.
-----------------------------------------------------------]]
function GM:PlayerButtonDown( ply, btn ) 

	numpad.Activate( ply, btn )

end

--[[---------------------------------------------------------
	These are buttons that the client is pressing. They're used
	in Sandbox mode to control things like wheels, thrusters etc.
-----------------------------------------------------------]]
function GM:PlayerButtonUp( ply, btn ) 

	numpad.Deactivate( ply, btn )

end

function GM:PlayerDisconnected(ply)

   cleanup.CC_Cleanup(ply, "gmod_cleanup", {});

end
