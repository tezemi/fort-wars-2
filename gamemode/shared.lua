--[[---------------------------------------------------------

  Sandbox Gamemode

  This is GMod's default gamemode

-----------------------------------------------------------]]

include( "player_extension.lua" )
include( "persistence.lua" )
include( "save_load.lua" )
include( "player_class/player_sandbox.lua" )
include("player_class/player_build.lua");
include("player_class/player_fight.lua");
include( "drive/drive_sandbox.lua" )
include( "editor_player.lua" )

--
-- Make BaseClass available
--
DEFINE_BASECLASS( "gamemode_base" )

GM.Name 	= "Sandbox"
GM.Author 	= "TEAM GARRY"
GM.Email 	= "teamgarry@garrysmod.com"
GM.Website 	= "www.garrysmod.com"

--
-- Constants
--
ROUND_BUILD = 0;
ROUND_FIGHT = 1;

TEAM_RED = 1;
TEAM_BLUE = 2;
TEAM_SPEC = 3;

--[[
 Note: This is so that in addons you can do stuff like
 
 if ( !GAMEMODE.IsSandboxDerived ) then return end
 
--]]

GM.IsSandboxDerived = true

cleanup.Register( "props" )
cleanup.Register( "ragdolls" )
cleanup.Register( "effects" )
cleanup.Register( "npcs" )
cleanup.Register( "constraints" )
cleanup.Register( "ropeconstraints" )
cleanup.Register( "sents" )
cleanup.Register( "vehicles" )

local physgun_limited = CreateConVar( "physgun_limited", "0", FCVAR_REPLICATED )

function fortwars.IsSpec(ply)

	return ply:GetObserverMode() ~= OBS_MODE_NONE;

end

function GM:CreateTeams()

	team.SetUp(1, "Red", Color(255, 25, 25));
	team.SetUp(2, "Blue", Color(25, 25, 255));
	team.SetUp(3, "Spectators", Color(25, 25, 25));

end

--[[---------------------------------------------------------
   Name: gamemode:CanTool( ply, trace, mode )
   Return true if the player is allowed to use this tool
-----------------------------------------------------------]]
function GM:CanTool( ply, trace, mode )

	-- The jeep spazzes out when applying something
	-- todo: Find out what it's reacting badly to and change it in _physprops
	if ( mode == "physprop" && trace.Entity:IsValid() && trace.Entity:GetClass() == "prop_vehicle_jeep" ) then
		return false
	end
	
	-- If we have a toolsallowed table, check to make sure the toolmode is in it
	if ( trace.Entity.m_tblToolsAllowed ) then
	
		local vFound = false	
		for k, v in pairs( trace.Entity.m_tblToolsAllowed ) do
			if ( mode == v ) then vFound = true end
		end

		if ( !vFound ) then return false end

	end
	
	-- Give the entity a chance to decide
	if ( trace.Entity.CanTool ) then
		return trace.Entity:CanTool( ply, trace, mode )
	end

	return true
	
end


--[[---------------------------------------------------------
   Name: gamemode:GravGunPunt( )
   Desc: We're about to punt an entity (primary fire).
		 Return true if we're allowed to.
-----------------------------------------------------------]]
function GM:GravGunPunt( ply, ent )

	if ( ent:IsValid() && ent.GravGunPunt ) then
		return ent:GravGunPunt( ply )
	end

	return BaseClass.GravGunPunt( self, ply, ent )
	
end

--[[---------------------------------------------------------
   Name: gamemode:GravGunPickupAllowed( )
   Desc: Return true if we're allowed to pickup entity
-----------------------------------------------------------]]
function GM:GravGunPickupAllowed( ply, ent )

	if ( ent:IsValid() && ent.GravGunPickupAllowed ) then
		return ent:GravGunPickupAllowed( ply )
	end

	return BaseClass.GravGunPickupAllowed( self, ply, ent )
	
end


--[[---------------------------------------------------------
   Name: gamemode:PhysgunPickup( )
   Desc: Return true if player can pickup entity
-----------------------------------------------------------]]
function GM:PhysgunPickup( ply, ent )

	-- Don't pick up persistent props
	if ( ent:GetPersistent() ) then return false end

	if ( ent:IsValid() && ent.PhysgunPickup ) then
		return ent:PhysgunPickup( ply )
	end
	
	-- Some entities specifically forbid physgun interaction
	if ( ent.PhysgunDisabled ) then return false end
	
	local EntClass = ent:GetClass()

	-- Never pick up players
	if ( EntClass == "player" ) then return false end
	
	if ( physgun_limited:GetBool() ) then
	
		if ( string.find( EntClass, "prop_dynamic" ) ) then return false end
		if ( string.find( EntClass, "prop_door" ) ) then return false end
		
		-- Don't move physboxes if the mapper logic says no
		if ( EntClass == "func_physbox" && ent:HasSpawnFlags( SF_PHYSBOX_MOTIONDISABLED ) ) then return false  end
		
		-- If the physics object is frozen by the mapper, don't allow us to move it.
		if ( string.find( EntClass, "prop_" ) && ( ent:HasSpawnFlags( SF_PHYSPROP_MOTIONDISABLED ) || ent:HasSpawnFlags( SF_PHYSPROP_PREVENT_PICKUP ) ) ) then return false end
		
		-- Allow physboxes, but get rid of all other func_'s (ladder etc)
		if ( EntClass != "func_physbox" && string.find( EntClass, "func_" ) ) then return false end

	
	end
	
	if ( SERVER ) then 
	
		ply:SendHint( "PhysgunFreeze", 2 )
		ply:SendHint( "PhysgunUse", 8 )
		
	end
	
	return true
	
end


--[[---------------------------------------------------------
   Name: gamemode:EntityKeyValue( ent, key, value )
   Desc: Called when an entity has a keyvalue set
	      Returning a string it will override the value
-----------------------------------------------------------]]
function GM:EntityKeyValue( ent, key, value )

	-- Physgun not allowed on this prop..
	if ( key == "gmod_allowphysgun" && value == '0' ) then
		ent.PhysgunDisabled = true
	end

	-- Prop has a list of tools that are allowed on it.
	if ( key == "gmod_allowtools" ) then
		ent.m_tblToolsAllowed = string.Explode( " ", value )
	end
	
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerNoClip( player, bool )
   Desc: Player pressed the noclip key, return true if
		  the player is allowed to noclip, false to block
-----------------------------------------------------------]]
function GM:PlayerNoClip(ply, on)

	if (not IsValid(ply) or ply:InVehicle() or not ply:Alive()) then

		return false;

	end

	if (GetConVarNumber("sv_cheats") == 1 or GetGlobalInt("FW_RoundState", 0) == ROUND_BUILD) then

		return true;

	end

	return false;

end

function GM:PlayerFootstep(ply, pos, foot, sound, volume, rf)

	if (IsValid(ply) and fortwars.IsSpec(ply)) then

	   return true;

	end

 end 

--[[---------------------------------------------------------
   Name: gamemode:CanProperty( pl, property, ent )
   Desc: Can the player do this property, to this entity?
-----------------------------------------------------------]]
function GM:CanProperty( pl, property, ent )
	
	--
	-- Always a chance some bastard got through
	--
	if ( !IsValid( ent ) ) then return false end


	--
	-- If we have a toolsallowed table, check to make sure the toolmode is in it
	-- This is used by things like map entities
	--
	if ( ent.m_tblToolsAllowed ) then
	
		local vFound = false	
		for k, v in pairs( ent.m_tblToolsAllowed ) do
			if ( property == v ) then vFound = true end
		end

		if ( !vFound ) then return false end

	end

	--
	-- Who can who bone manipulate?
	--
	if ( property == "bonemanipulate" ) then

		if ( game.SinglePlayer() ) then return true end

		if ( ent:IsNPC() ) then return GetConVarNumber( "sbox_bonemanip_npc" ) != 0 end
		if ( ent:IsPlayer() ) then return GetConVarNumber( "sbox_bonemanip_player" ) != 0 end
		
		return GetConVarNumber( "sbox_bonemanip_misc" ) != 0

	end

	--
	-- Weapons can only be property'd if nobody is holding them
	--
	if ( ent:IsWeapon() and IsValid( ent:GetOwner() ) ) then
		return false
	end

	-- Give the entity a chance to decide
	if ( ent.CanProperty ) then
		return ent:CanProperty( pl, property )
	end

	return true
	
end

--[[---------------------------------------------------------
   Name: gamemode:CanDrive( pl, ent )
   Desc: Return true to let the entity drive.
-----------------------------------------------------------]]
function GM:CanDrive( pl, ent )
	
	local classname = ent:GetClass();

	--
	-- Only let physics based NPCs be driven for now
	--
	if ( ent:IsNPC() ) then

		if ( classname == "npc_cscanner" ) then return true end
		if ( classname == "npc_clawscanner" ) then return true end
		if ( classname == "npc_manhack" ) then return true end
		if ( classname == "npc_turret_floor" ) then return true end
		if ( classname == "npc_rollermine" ) then return true end
		
		return false

	end

	if ( classname == "prop_dynamic" ) then return false end
	if ( classname == "prop_door" ) then return false end

	--
	-- I'm guessing we'll find more things we don't want the player to fly around during development
	--

	return true
	
end


--[[---------------------------------------------------------
	To update the player's animation during a drive
-----------------------------------------------------------]]
function GM:PlayerDriveAnimate( ply ) 

	local driving = ply:GetDrivingEntity()
	if ( !IsValid( driving ) ) then return end

	ply:SetPlaybackRate( 1 )
	ply:ResetSequence( ply:SelectWeightedSequence( ACT_HL2MP_IDLE_MAGIC ) )

	--
	-- Work out the direction from the player to the entity, and set parameters 
	--
	local DirToEnt = driving:GetPos() - ( ply:GetPos() + Vector( 0, 0, 50 ) )
	local AimAng = DirToEnt:Angle()

	if ( AimAng.p > 180 ) then
		AimAng.p = AimAng.p - 360
	end

	ply:SetPoseParameter( "aim_yaw",		0 )
	ply:SetPoseParameter( "aim_pitch",		AimAng.p )
	ply:SetPoseParameter( "move_x",			0 )
	ply:SetPoseParameter( "move_y",			0 )
	ply:SetPoseParameter( "move_yaw",		0 )
	ply:SetPoseParameter( "move_scale",		0 )

	AimAng.p = 0;
	AimAng.r = 0;

	ply:SetRenderAngles( AimAng )
	ply:SetEyeTarget( driving:GetPos() )

end
