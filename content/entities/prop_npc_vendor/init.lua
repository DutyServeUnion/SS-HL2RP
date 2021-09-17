AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

include("shared.lua");

-- List of random NPC models.
local randomModels = {
  "models/player/group02/male_02.mdl",
  "models/player/group02/male_04.mdl",
  "models/player/group02/male_06.mdl",
  "models/player/group02/male_08.mdl",
};

local entCategoryList = {
  aid = {
    categoryName = "Aid",
    categoryColour = Color(244, 66, 66, 255),
  }
}

local entList = {
  prop_gasmask = {
    entCategory = entCategoryList["aid"],

    entTitle = "Gas Mask",
    entDescription = "A basic gas mask, crudely made from several scavenged materials found around the city. Has 15 \"mask hitpoints\".",
    entType = "Disposable",
    entClassname = "prop_gasmask",

    entThumbType = "image",
    entThumbImage = "entities/prop_gasmask.png",
    entThumbModel = "models/dpfilms/metropolice/props/generic_gasmask.mdl",

    entPrice = 1000,
    entJobRestrictions = nil,
  },

  weapon_dooroverride = {
    entCategory = entCategoryList["tools"],

    entTitle = "Door Override",
    entDescription = "A tool used to force unlock doors in your faction, during a base lockdown. Use with extreme caution.",
    entType = "Tool",
    entClassname = "weapon_dooroverride",

    entThumbType = "image",
    entThumbImage = "entities/weapon_dooroverride.png",

    entPrice = 100,
    entJobRestrictions = nil,
  },
}

net.Receive("VendorClientDermaControlCommand", function(len, ply)
  local money = ply:getDarkRPVar("money")

  if (ply:IsValid()) then
    local rxTable = net.ReadTable();
    local command = rxTable["command"];
    local attributes = rxTable["attributes"];
    if (command == "BuyItem") then
      className = attributes["item"]["entClassname"];
      if (className == entList[className]["entClassname"]) then
        if (money >= entList[className]["entPrice"]) then
          local boughtEntity = ents.Create(entList[className]["entClassname"]);

          ply:addMoney(-entList[className]["entPrice"]);

          boughtEntity:SetPos(ply:GetEyeTrace().HitPos);
          boughtEntity:Spawn();

          net.Start("VendorServerDermaControlCommand");
          net.WriteTable({command = "ItemBought", entityItem = entList[className]});
          net.Send(ply);
        else
          net.Start("VendorServerDermaControlCommand");
          net.WriteTable({command = "NotEnoughCredits", entityItem = entList[className], currentCredits = money});
          net.Send(ply);
        end
      end
    end
  end
end);

-- Function to initialize the NPC.
function ENT:Initialize()
  util.AddNetworkString("VendorServerDermaControlCommand");
  util.AddNetworkString("VendorClientDermaControlCommand");

  -- Pick us a random model.
  self:SetModel(randomModels[math.random(1, 4)]);

  -- Initialize the "NPC" so it can't move.
  self:PhysicsInit(SOLID_VPHYSICS);
  self:SetMoveType(MOVETYPE_NONE);
  self:SetSolid(SOLID_VPHYSICS);

  self:SetUseType(SIMPLE_USE);
end

-- Handle the use key.
function ENT:Use(ply)
  local money = ply:getDarkRPVar("money")

  net.Start("VendorServerDermaControlCommand");
  net.WriteTable({command = "OpenDerma", entlist = entList, currentCredits = money});
  net.Send(ply);
end
