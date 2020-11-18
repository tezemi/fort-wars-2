
--[[---------------------------------------------------------

	Sandbox Gamemode

	This is GMod's default gamemode

-----------------------------------------------------------]]

fortwars = {};

ENTITY_COSTS = {};

PLAYERS = {};

include( 'shared.lua' )
include( 'cl_spawnmenu.lua' )
include( 'cl_notice.lua' )
include( 'cl_hints.lua' )
include( 'cl_worldtips.lua' )
include( 'cl_search_models.lua' )
include( 'gui/IconEditor.lua' )

surface.CreateFont("Cash",
{
	font = "Trebuchet24",
	size = 24,
	weight = 800
});

local sf = surface
local dr = draw
local Tex_Corner8 = surface.GetTextureID( "gui/corner8" )

--
-- Make BaseClass available
--
DEFINE_BASECLASS( "gamemode_base" )

local lastCash = -1;
local cashCost = -1;
local physgun_halo = CreateConVar( "physgun_halo", "1", { FCVAR_ARCHIVE }, "Draw the physics gun halo?" )

function fortwars.ShowWarning(text, onContinueFunction, onCancelFunction)

	local width = 350;
	local height = 200;

	local menu = vgui.Create("DFrame");
	menu:SetTitle("WARNING")
	menu:SetSize(width, height);
	menu:Center();
	menu:MakePopup();
	menu.Paint = function(self, w, h)
		
		draw.RoundedBox(0, 0, 0, w, h, Color(104, 111, 114, 255));
		
	end

	local label = vgui.Create("DLabel", menu);
	label:SetText(text);
	label:SizeToContents();
	label:SetSize(200, 200)
	label:SetWrap(true);
	label:Center();

	local cButton = vgui.Create("DButton", menu);
	cButton:SetText("Continue");
	cButton:SetTextColor(Color(255, 255, 255, 255));
	cButton:SetPos(65, 140);
	cButton:SetSize(80, 40);
	cButton.Paint = function(self, w, h)

		draw.RoundedBox(0, 0, 0, w, h, Color(45, 45, 45, 255));

	end

	cButton.DoClick = onContinueFunction;

end

function fortwars.ShowTeamSelectMenu()

	local width = 300;
	local height = 350;

	local menu = vgui.Create("DFrame");
	menu:SetTitle("Select Team")
	menu:SetSize(width, height);
	menu:Center();
	menu:MakePopup();
	menu.Paint = function(self, w, h)
		
		draw.RoundedBox(0, 0, 0, w, h, Color(104, 111, 114, 150));
		
	end

	local buttonW = 200;
	local buttonH = 50;

	local redTeamButton = vgui.Create("DButton", menu);
	redTeamButton:SetText(team.GetName(1));
	redTeamButton:SetTextColor(Color(255, 255, 255, 255));
	redTeamButton:SetPos(width / 2 - buttonW / 2, 50);
	redTeamButton:SetSize(buttonW, buttonH);
	redTeamButton.Paint = function(self, w, h)

		draw.RoundedBox(0, 0, 0, w, h, team.GetColor(1));

	end

	redTeamButton.DoClick = function()

		--fortwars.ShowWarning("Changing teams will clean up everything you've spawned.\nAre you sure you want to switch teams?");
		net.Start("FW_RequestJoinTeam");
		net.WriteInt(1, 32);
		net.SendToServer();
		menu:Close();

	end

	local blueTeamButton = vgui.Create("DButton", menu);
	blueTeamButton:SetText(team.GetName(2));
	blueTeamButton:SetTextColor(Color(255, 255, 255, 255));
	blueTeamButton:SetPos(width / 2 - buttonW / 2, 150);
	blueTeamButton:SetSize(buttonW, buttonH);
	blueTeamButton.Paint = function(self, w, h)

		draw.RoundedBox(0, 0, 0, w, h, team.GetColor(2));

	end

	blueTeamButton.DoClick = function()

		net.Start("FW_RequestJoinTeam");
		net.WriteInt(2, 32);
		net.SendToServer();
		menu:Close();

	end

	local specButton = vgui.Create("DButton", menu);
	specButton:SetText(team.GetName(3));
	specButton:SetTextColor(Color(255, 255, 255, 255));
	specButton:SetPos(width / 2 - buttonW / 2, 250);
	specButton:SetSize(buttonW, buttonH);
	specButton.Paint = function(self, w, h)

		draw.RoundedBox(0, 0, 0, w, h, team.GetColor(3));

	end

	specButton.DoClick = function()

		net.Start("FW_RequestJoinTeam");
		net.WriteInt(3, 32);
		net.SendToServer();
		menu:Close();

	end

end

function GetEntityCosts(len, ply)

	ENTITY_COSTS = net.ReadTable();

end
net.Receive("FW_EntityCosts", GetEntityCosts);

function GetPlayerTable(len, ply)

	PLAYERS = net.ReadTable();

end
net.Receive("FW_SendPlayerTable", GetPlayerTable);

function GetRoundState(len, ply)

	

end
net.Receive("FW_RoundState", GetRoundState);

function GM:Initialize()

	BaseClass.Initialize(self);

	fortwars.ShowTeamSelectMenu();

end

function GM:LimitHit( name )

	self:AddNotify( "#SBoxLimit_" .. name, NOTIFY_ERROR, 6 )
	surface.PlaySound( "buttons/button10.wav" )

end

function GM:OnUndo( name, strCustomString )

	if ( !strCustomString ) then
		local str = "#Undone_" .. name
		local translated = language.GetPhrase( str )
		if ( str == translated ) then
			-- No translation available, apply our own
			translated = string.format( language.GetPhrase( "hint.undoneX" ), language.GetPhrase( name ) )
		else
			-- Try to translate some of this
			local strmatch = string.match( translated, "^Undone (.*)$" )
			if ( strmatch ) then
				translated = string.format( language.GetPhrase( "hint.undoneX" ), language.GetPhrase( strmatch ) )
			end
		end

		self:AddNotify( translated, NOTIFY_UNDO, 2 )
	else
		-- This is a hack for SWEPs, etc, to support #translations from server
		local str = string.match( strCustomString, "^Undone (.*)$" )
		if ( str ) then
			strCustomString = string.format( language.GetPhrase( "hint.undoneX" ), language.GetPhrase( str ) )
		end

		self:AddNotify( strCustomString, NOTIFY_UNDO, 2 )
	end

	-- Find a better sound :X
	surface.PlaySound( "buttons/button15.wav" )

end

function GM:OnCleanup( name )

	self:AddNotify( "#Cleaned_" .. name, NOTIFY_CLEANUP, 5 )

	-- Find a better sound :X
	surface.PlaySound( "buttons/button15.wav" )

end

function GM:UnfrozeObjects( num )

	self:AddNotify( string.format( language.GetPhrase( "hint.unfrozeX" ), num ), NOTIFY_GENERIC, 3 )

	-- Find a better sound :X
	surface.PlaySound( "npc/roller/mine/rmine_chirp_answer1.wav" )

end

local function ShadowedText(text, font, x, y, color, xalign, yalign)

	dr.SimpleText(text, font, x + 2, y + 2, Color(0, 0, 0, 255), xalign, yalign); 
	dr.SimpleText(text, font, x, y, color, xalign, yalign);

 end

local function RoundedMeter( bs, x, y, w, h, color)
	surface.SetDrawColor(color)
 
	surface.DrawRect( x+bs, y, w-bs*2, h )
	surface.DrawRect( x, y+bs, bs, h-bs*2 )
 
	surface.SetTexture( Tex_Corner8 )
	surface.DrawTexturedRectRotated( x + bs/2 , y + bs/2, bs, bs, 0 )
	surface.DrawTexturedRectRotated( x + bs/2 , y + h -bs/2, bs, bs, 90 )
 
	if w > 14 then
	   surface.DrawRect( x+w-bs, y+bs, bs, h-bs*2 )
	   surface.DrawTexturedRectRotated( x + w - bs/2 , y + bs/2, bs, bs, 270 )
	   surface.DrawTexturedRectRotated( x + w - bs/2 , y + h - bs/2, bs, bs, 180 )
	else
	   surface.DrawRect( x + math.max(w-bs, bs), y, bs/2, h )
	end
 
 end
 

local function PaintBar(x, y, w, h, colors, value)
	-- Background
	-- slightly enlarged to make a subtle border
	draw.RoundedBox(8, x-1, y-1, w+2, h+2, Color(0, 0, 10, 200))
 
	-- Fill
	local width = w * math.Clamp(value, 0, 1)
 
	if width > 0 then
	   RoundedMeter(8, x, y, width, h, Color(25, 200, 25, 200))
	end
 end

local function DrawBg(x, y, width, height, client)
	-- Traitor area sizes
	local th = 30
	local tw = 170
 
	-- Adjust for these
	y = y - th
	height = height + th
 
	-- main bg area, invariant
	-- encompasses entire area
	draw.RoundedBox(8, x, y, width, height, Color(0, 0, 10, 200))
 
	-- main border, traitor based
	local col = Color(25, 200, 25, 200)
	 
	draw.RoundedBox(8, x, y, tw, th, col)
end

function GM:HUDPaint()

	if (fortwars.IsSpec(LocalPlayer())) then

		-- Put spectator HUD here

		return;	-- Don't draw normal HUD

	end

	self:PaintWorldTips()

	-- Draw all of the default stuff
	BaseClass.HUDPaint( self )

	local client = LocalPlayer();

	--
	-- Paint Ready Up
	--
	


	--
	-- Paint Cash
	--
	local cashBackW = 90;
	local cashBackH = 40;
	local cashOffsetFromCenter = 1.06;

	PaintBar(ScrW() / 2 - cashBackW / 2 + 1, ScrH() / cashOffsetFromCenter - cashBackH / 2 + 2, cashBackW, cashBackH, Color(25, 200, 25, 200), 1);

	ShadowedText(tostring("$" .. client:GetNWInt("FW_Cash", 0)), "Cash", ScrW() / 2, (ScrH() / cashOffsetFromCenter), Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER);	

	local cashCostTimeName = "FW_CashCostTimer";

	if (lastCash ~= client:GetNWInt("FW_Cash", 0)) then

		if (lastCash ~= -1) then

			cashCost = client:GetNWInt("FW_Cash", 0) - lastCash;

			if (timer.Exists(cashCostTimeName)) then

				timer.Start(cashCostTimeName);

			else

				timer.Create(cashCostTimeName, 3, 0, function()

					cashCost = -1;

				end);

			end		

		end

		lastCash = client:GetNWInt("FW_Cash", 0);

	end

	local cashCostOffset = 1.1;

	if (cashCost ~= -1) then

		local color = Color(255, 25, 25, 255);
		if (cashCost > 0) then

			color = Color(25, 255, 25, 255);

		end

		ShadowedText(tostring("$" .. cashCost), "Cash", ScrW() / 2, (ScrH() / cashCostOffset), color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER);	

	end

	self:PaintNotes()

end

--[[---------------------------------------------------------
	Draws on top of VGUI..
-----------------------------------------------------------]]
function GM:PostRenderVGUI()

	BaseClass.PostRenderVGUI( self )

end

local PhysgunHalos = {}

--[[---------------------------------------------------------
	Name: gamemode:DrawPhysgunBeam()
	Desc: Return false to override completely
-----------------------------------------------------------]]
function GM:DrawPhysgunBeam( ply, weapon, bOn, target, boneid, pos )

	if ( physgun_halo:GetInt() == 0 ) then return true end

	if ( IsValid( target ) ) then
		PhysgunHalos[ ply ] = target
	end

	return true

end

hook.Add( "PreDrawHalos", "AddPhysgunHalos", function()

	if ( !PhysgunHalos || table.IsEmpty( PhysgunHalos ) ) then return end

	for k, v in pairs( PhysgunHalos ) do

		if ( !IsValid( k ) ) then continue end

		local size = math.random( 1, 2 )
		local colr = k:GetWeaponColor() + VectorRand() * 0.3

		halo.Add( PhysgunHalos, Color( colr.x * 255, colr.y * 255, colr.z * 255 ), size, size, 1, true, false )

	end

	PhysgunHalos = {}

end )


--[[---------------------------------------------------------
	Name: gamemode:NetworkEntityCreated()
	Desc: Entity is created over the network
-----------------------------------------------------------]]
function GM:NetworkEntityCreated( ent )

	--
	-- If the entity wants to use a spawn effect
	-- then create a propspawn effect if the entity was
	-- created within the last second (this function gets called
	-- on every entity when joining a server)
	--

	if ( ent:GetSpawnEffect() && ent:GetCreationTime() > ( CurTime() - 1.0 ) ) then

		local ed = EffectData()
			ed:SetOrigin( ent:GetPos() )
			ed:SetEntity( ent )
		util.Effect( "propspawn", ed, true, true )

	end

end

local function ShowTeamSelectMenuCommand(ply, command, args, argsStr)

	fortwars.ShowTeamSelectMenu();

end
concommand.Add("fw_team_select_menu", ShowTeamSelectMenuCommand);
