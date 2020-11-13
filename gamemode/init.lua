--[[---------------------------------------------------------

  Fortwars 2 Gamemode

  Based on Sandbox, modified for fort builting and fighting!

-----------------------------------------------------------]]

--
-- Defines fortwars prefix for API function calls
--
fortwars = {};

--
-- These files get sent to the client
--
AddCSLuaFile("cl_hints.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("cl_notice.lua");
AddCSLuaFile("cl_search_models.lua");
AddCSLuaFile("cl_spawnmenu.lua");
AddCSLuaFile("cl_worldtips.lua");
AddCSLuaFile("persistence.lua");
AddCSLuaFile("player_extension.lua");
AddCSLuaFile("save_load.lua");
AddCSLuaFile("shared.lua");
AddCSLuaFile("gui/IconEditor.lua");

--
-- Includes
--
include("shared.lua");
include("commands.lua");
include("player.lua");
include("spawnmenu/init.lua");

--
-- Convars
--
CreateConVar("fw_start_weapons", "weapon_crowbar weapon_pistol", FCVAR_NOTIFY + FCVAR_REPLICATED);
CreateConVar("fw_start_cash", "3000", FCVAR_NOTIFY + FCVAR_REPLICATED);

--
-- Network Strings
--
util.AddNetworkString("FW_RoundState");
util.AddNetworkString("FW_EntityCosts");
util.AddNetworkString("FW_RequestJoinTeam");

--
-- Global Variables
--
SetGlobalFloat("fw_build_end", -1);

--
-- Make BaseClass available
--
DEFINE_BASECLASS("gamemode_base");

--
-- API Functions
--
function fortwars.SendRoundState(state, ply)

	net.Start("FW_RoundState");
	net.WriteInt(state, 32);

	return ply and net.Send(ply) or net.Broadcast();

 end

function fortwars.GetRoundState()

	return GAMEMODE.roundState;

end

function fortwars.SetRoundState(state)

	GAMEMODE.roundState = state;
 
	fortwars.SendRoundState(state);

end

--[[---------------------------------------------------------
	Name: gamemode:Initialize()
	Desc: Called when the gamemode starts
-----------------------------------------------------------]]
function GM:Initialize()

	GAMEMODE.roundState = ROUND_BUILD;

end

--[[---------------------------------------------------------
	Name: gamemode:PlayerSpawn()
	Desc: Called when a player spawns
-----------------------------------------------------------]]
function GM:PlayerSpawn(ply, transiton)
	
	if (ply:Team() == TEAM_SPEC) then

		ply:StripAmmo();
		ply:StripWeapons();
		ply:Spectate(OBS_MODE_ROAMING);
		ply:SetObserverMode(OBS_MODE_ROAMING);

		return;

	else

		ply:UnSpectate();
		ply:SetObserverMode(OBS_MODE_NONE);

	end

	if (fortwars.GetRoundState() == ROUND_BUILD) then

		player_manager.SetPlayerClass(ply, "player_build");
	
	else

		player_manager.SetPlayerClass(ply, "player_fight");

	end

	BaseClass.PlayerSpawn(self, ply, transiton);

end

--[[---------------------------------------------------------
	Called once on the player's first spawn
-----------------------------------------------------------]]
function GM:PlayerInitialSpawn(ply, transiton)

	--BaseClass.PlayerInitialSpawn(self, ply, transiton);

	ply:SetNWInt("FW_Cash", tonumber(GetConVar("fw_start_cash"):GetInt()));

	net.Start("FW_EntityCosts");
	net.WriteTable(ENTITY_COSTS);
	net.Send(ply);

	fortwars.SetTeam(ply, TEAM_SPEC);	-- Player first spawns as spectator

end

function GM:EntityRemoved(ent)

	local plyOwner = ent:GetNWEntity("FW_PlayerOwner");

	if (ent:GetNWEntity("FW_PlayerOwner") and ENTITY_COSTS[ent:GetClass()]) then

		plyOwner:SetNWInt("FW_Cash", plyOwner:GetNWInt("FW_Cash", 0) + ENTITY_COSTS[ent:GetClass()]);

	elseif (ent:GetNWEntity("FW_PlayerOwner") and ent:GetClass() == "prop_physics") then

		plyOwner:SetNWInt("FW_Cash", plyOwner:GetNWInt("FW_Cash", 0) + fortwars.GetPropCost(ent));

	end

end

--[[---------------------------------------------------------
	Name: gamemode:OnPhysgunFreeze( weapon, phys, ent, player )
	Desc: The physgun wants to freeze a prop
-----------------------------------------------------------]]
function GM:OnPhysgunFreeze( weapon, phys, ent, ply )

	-- Don't freeze persistent props (should already be froze)
	if ( ent:GetPersistent() ) then return false end

	BaseClass.OnPhysgunFreeze( self, weapon, phys, ent, ply )

	ply:SendHint( "PhysgunUnfreeze", 0.3 )
	ply:SuppressHint( "PhysgunFreeze" )

end

--[[---------------------------------------------------------
	Name: gamemode:OnPhysgunReload( weapon, player )
	Desc: The physgun wants to unfreeze
-----------------------------------------------------------]]
function GM:OnPhysgunReload( weapon, ply )

	local num = ply:PhysgunUnfreeze()

	if ( num > 0 ) then
		ply:SendLua( "GAMEMODE:UnfrozeObjects(" .. num .. ")" )
	end

	ply:SuppressHint( "PhysgunUnfreeze" )

end

--[[---------------------------------------------------------
	Name: gamemode:PlayerShouldTakeDamage
	Return true if this player should take damage from this attacker
	Note: This is a shared function - the client will think they can
		damage the players even though they can't. This just means the
		prediction will show blood.
-----------------------------------------------------------]]
function GM:PlayerShouldTakeDamage( ply, attacker )

	-- Global godmode, players can't be damaged in any way
	if ( cvars.Bool( "sbox_godmode", false ) ) then return false end

	-- No player vs player damage
	if ( attacker:IsValid() && attacker:IsPlayer() && ply != attacker ) then
		return cvars.Bool( "sbox_playershurtplayers", true )
	end

	-- Default, let the player be hurt
	return true

end

--[[---------------------------------------------------------
	Show the search when f1 is pressed
-----------------------------------------------------------]]
function GM:ShowHelp( ply )

	ply:SendLua( "hook.Run( 'StartSearch' )" )

end

function GM:EntityTakeDamage(target, dmg)

	print(target:GetClass());

	if (target:GetClass() == "npc_turret_floor") then

		target:SetHealth(target:Health() - dmg:GetDamage());

		if (target:Health() <= 0) then

			target:Input("SelfDestruct", target, target);

		end

	end

	print(target:Health());

end

--[[---------------------------------------------------------
	A ragdoll of an entity has been created
-----------------------------------------------------------]]
function GM:CreateEntityRagdoll( entity, ragdoll )

	-- Replace the entity with the ragdoll in cleanups etc
	undo.ReplaceEntity( entity, ragdoll )
	cleanup.ReplaceEntity( entity, ragdoll )

end

--[[---------------------------------------------------------
	Player unfroze an object
-----------------------------------------------------------]]
function GM:PlayerUnfrozeObject( ply, entity, physobject )

	local effectdata = EffectData()
	effectdata:SetOrigin( physobject:GetPos() )
	effectdata:SetEntity( entity )
	util.Effect( "phys_unfreeze", effectdata, true, true )

end

--[[---------------------------------------------------------
	Player froze an object
-----------------------------------------------------------]]
function GM:PlayerFrozeObject( ply, entity, physobject )

	if ( DisablePropCreateEffect ) then return end

	local effectdata = EffectData()
	effectdata:SetOrigin( physobject:GetPos() )
	effectdata:SetEntity( entity )
	util.Effect( "phys_freeze", effectdata, true, true )

end

--
-- Who can edit variables?
-- If you're writing prop protection or something, you'll
-- probably want to hook or override this function.
--
function GM:CanEditVariable( ent, ply, key, val, editor )

	-- Only allow admins to edit admin only variables!
	if ( editor.AdminOnly ) then
		return ply:IsAdmin()
	end

	-- This entity decides who can edit its variables
	if ( isfunction( ent.CanEditVariables ) ) then
		return ent:CanEditVariables( ply )
	end

	-- default in sandbox is.. anyone can edit anything.
	return true

end

--
-- Console Commands
--
local function ForceRoundChange(ply, command, args, argsStr)

	if (not IsValid(ply)) or ply:IsAdmin() or ply:IsSuperAdmin() or cvars.Bool("sv_cheats", 0) then

		if (args[1] ~= "ROUND_BUILD" and args[1] ~= "ROUND_FIGHT" and args[1] ~= "0" and args[1] ~= "1") then

			ply:PrintMessage(HUD_PRINTCONSOLE, "Not a valid round state. Must be ROUND_BUILD or ROUND_FIGHT, or 0 or 1.");

			return;

		end

		local state = 0;
		if (args[1] == "0" or args[1] == "1") then

			state = tonumber(args[1]);

		elseif (args[1] == "ROUND_BUILD") then

			state = 0;

		elseif (args[1] == "ROUND_FIGHT") then

			state = 1;

		end

		fortwars.SetRoundState(state);

	else

		ply:PrintMessage(HUD_PRINTCONSOLE, "Can't run this command. You must be an admin or must enable sv_cheats.");

	end

end
concommand.Add("fw_force_round_change", ForceRoundChange);

local function AddStartWeapon(ply, command, args, argsStr)

	if (not IsValid(ply)) or ply:IsAdmin() or ply:IsSuperAdmin() or cvars.Bool("sv_cheats", 0) then

		local convar = GetConVar("fw_start_weapons");
		convar:SetString(convar:GetString() .. " " ..  args[1]);

	else

		ply:PrintMessage(HUD_PRINTCONSOLE, "Can't run this command. You must be an admin or must enable sv_cheats.");

	end

end
concommand.Add("fw_start_weapon_add", AddStartWeapon);

local function RemoveStartWeapon(ply, command, args, argsStr)

	if (not IsValid(ply)) or ply:IsAdmin() or ply:IsSuperAdmin() or cvars.Bool("sv_cheats", 0) then

		local convar = GetConVar("fw_start_weapons");
		local currentString = convar:GetString();

		if (string.match(currentString, args[1])) then

			local removedWeapons = currentString:gsub("%" .. args[1], "");
			local trimmed = string.gsub(removedWeapons, '^%s*(.-)%s*$', '%1');
			convar:SetString(trimmed);

		else
			
			ply:PrintMessage(HUD_PRINTCONSOLE, "Can't remove " .. args[1] .. " from the start weapon list. It doesn't exist.");

		end

	else

		ply:PrintMessage(HUD_PRINTCONSOLE, "Can't run this command. You must be an admin or must enable sv_cheats.");

	end

end
concommand.Add("fw_start_weapon_remove", RemoveStartWeapon);

local function RemoveStartWeapon(ply, command, args, argsStr)

	if (not IsValid(ply)) or ply:IsAdmin() or ply:IsSuperAdmin() or cvars.Bool("sv_cheats", 0) then

		if (args[1]) then

			local value = tonumber(args[1]);
			ply:SetNWInt("FW_Cash", value);

		end

	else

		ply:PrintMessage(HUD_PRINTCONSOLE, "Can't run this command. You must be an admin or must enable sv_cheats.");

	end

end
concommand.Add("fw_cash", RemoveStartWeapon);

local function SetTeamCommand(ply, command, args, argsStr)

	if (IsValid(ply) and args[1]) then

		if (args[1] == "TEAM_RED" or tonumber(args[1]) == 1) then

			fortwars.SetTeam(ply, TEAM_RED);

		elseif (args[1] == "TEAM_BLUE" or tonumber(args[1]) == 2) then

			fortwars.SetTeam(ply, TEAM_BLUE);

		elseif (args[1] == "TEAM_SPEC" or tonumber(args[1]) == 3) then

			fortwars.SetTeam(ply, TEAM_SPEC);

		else

			ply:PrintMessage(HUD_PRINTCONSOLE, "Not a valid team. 1 = red, 2 = blue, and 3 = spec.");

		end

	end

end
concommand.Add("fw_team", SetTeamCommand);
