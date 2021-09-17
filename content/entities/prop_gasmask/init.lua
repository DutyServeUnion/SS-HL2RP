AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

include("shared.lua");

include("../../../gamemode/scripted/airex/sv_airex.lua");
include("../../../gamemode/scripted/airex/sv_gasmask.lua");

function ENT:Initialize()
  if (self.MaskType == "basic") then
    self.MaskHitpoints = 15;
    self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
  elseif (self.MaskType == "metrocop") then
    self.MaskHitpoints = 30;
    self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
  elseif (self.MaskType == "officer") then
    self.MaskHitpoints = 50;
    self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
  elseif (self.MaskType == "elite") then
    self.MaskHitpoints = 70;
    self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
  elseif (self.MaskType == "squadleader") then
    self.MaskHitpoints = 80;
    self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
  elseif (self.MaskType == "divisionleader") then
    self.MaskHitpoints = 100;
    self:SetModel("models/dpfilms/metropolice/props/elite_gasmask.mdl");
  elseif (self.MaskType == "seccommand") then
    self.MaskHitpoints = 120;
    self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
  elseif (self.MaskType == "cmbofficer") then
    self.MaskHitpoints = 130;
    self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
  elseif (self.MaskType == "cityadmin") then
    self.MaskHitpoints = 140;
    self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
  elseif (self.MaskType == "sentinel") then
    self.MaskHitpoints = 150;
    self:SetModel("models/dpfilms/metropolice/props/phoenix_gasmask.mdl");
  else
    self.MaskHitpoints = 15;
    self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
  end

  self:PhysicsInit(SOLID_VPHYSICS);
  self:SetMoveType(MOVETYPE_VPHYSICS);
  self:SetSolid(SOLID_VPHYSICS);

  self:SetUseType(SIMPLE_USE);

  local physics = self:GetPhysicsObject();
  if (physics:IsValid()) then
    physics:Wake();
  end
end

function ENT:Use(ply)
  if (gasmaskHolders[ply:SteamID()] == nil) then
    self:Remove();
    airex_addGasmask(ply, self.MaskHitpoints);
    ply:EmitSound("items/battery_pickup.wav");
    ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] You picked up the gasmask.");
  else
    ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] You already have a gasmask.");
  end
end
