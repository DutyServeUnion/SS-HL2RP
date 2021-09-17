AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

include("shared.lua");
include("../../../gamemode/lib/server/sv_inventory_db.lua");
include("../../../gamemode/gui/sv_inventory.lua");
include("../../../gamemode/gui/sv_inventory_items.lua");

function ENT:Initialize()
  util.AddNetworkString("ItemEntityGetItem");
  util.AddNetworkString("ItemEntitySetItem");

  if (self.Item == nil) then
    self.Item = inventoryItems["misc"].nothing;
    self.ItemName = "nothing";
  end

  if (self.Item.model ~= nil) then
    self:SetModel(self.Item.model);
  else
    if (self.Item.specialType == "gasmask") then
      if (self.Item.variation == "basic") then
        self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
      elseif (self.Item.variation == "metrocop") then
        self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
      elseif (self.Item.variation == "officer") then
        self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
      elseif (self.Item.variation == "elite") then
        self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
      elseif (self.Item.variation == "squadleader") then
        self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
      elseif (self.Item.variation == "divisionleader") then
        self:SetModel("models/dpfilms/metropolice/props/elite_gasmask.mdl");
      elseif (self.Item.variation == "seccommand") then
        self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
      elseif (self.Item.variation == "cmbofficer") then
        self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
      elseif (self.Item.variation == "cityadmin") then
        self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
      elseif (self.Item.variation == "sentinel") then
        self:SetModel("models/dpfilms/metropolice/props/phoenix_gasmask.mdl");
      else
        self:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
      end
    else
      self:SetModel("models/items/item_item_crate.mdl");
    end
  end

  self:PhysicsInit(SOLID_VPHYSICS);
  self:SetMoveType(MOVETYPE_VPHYSICS);
  self:SetSolid(SOLID_VPHYSICS);
  self:SetUseType(SIMPLE_USE);

  local physics = self:GetPhysicsObject();
  if (physics:IsValid()) then
    physics:Wake();
  end

  net.Receive("ItemEntityGetItem", function(len, ply)
    net.Start("ItemEntitySetItem");

    self.Item.consumeCallback = nil;
    net.WriteTable({item = self.Item, itemname = self.ItemName});
    net.Broadcast();
  end);
end

function ENT:Use(ply)
  // Anti-cheat at its finest.
  if (self.ItemName == "nothing") then
    ply:PrintMessage(HUD_PRINTTALK, "[Inventory] Sorry, you can't pick up nothing. Why? Because it dosen't exist.");
    ply:EmitSound("buttons/button10.wav");
    return;
  end

  self:Remove();
  ply:EmitSound("items/ammo_pickup.wav");
  Inventory:AddItem(ply, self.Item, self.ItemName);
end
