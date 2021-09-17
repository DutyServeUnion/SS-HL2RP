-- Example Item Fields
-- MANDATORY STRING name - The display name of the item.
-- STRING description - Optional string to describe the item.
-- INTEGER value - The base value used by vendors for calculating the final price. Defaults to 0, which is "free".
-- INTEGER sellValue - The base value for selling the item. If not defined, value is used instead.
-- STRING model - The model of the item. If not defined, a crate model is used. Must be a physics-compatible model!
-- STRING weapon - (For use in weapon entities only) Defines the weapon entity this item uses when it is equipped.
-- INTEGER weight - The weight of the item. If not defined, the item has no weight.
-- TABLE ENUM whitelistedFactions - Table of factions that are allowed to buy the item. Examples: all, cwu, combine, amaria, resistance. If undefined, all factions are assumed.
-- TABLE ENUM blacklistedFactions - Table of factions that are NOT allowed to buy the item. This overrides whitelistedFactions. If undefined, no factions are assumed.
-- STRING contrabandLevel - Punishment level if a citizen is found with this item without a license. Can be green, yellow, or red. This places a contraband dot in the inventory browser, and a warning on pickup. If undefined, no restrictions.
-- BOOL consumable - Whether the item is consumable or not. If undefined, assumed to not be.
-- BOOL droppable - Whether the item can be dropped by the player or not. If undefined, assumed to be.
-- BOOL sellable - Whether the item can be sold to a vendor or not. If undefined, assumed to not be.
-- STRING consumableType - The type of consumable. Examples: food, medical, resource.
-- FUNCTION consumeCallback(ply, item) - The action to perform when the player consumes the item.
-- STRING specialType - Used for special items such as a CID card or license.

inventoryCategories = {
  consumables = {
    name = "Consumables",
    icon = "icon16/pill.png"
  },

  utility = {
    name = "Utility",
    icon = "icon16/wrench.png"
  },

  weapons = {
    name = "Weapons",
    icon = "icon16/gun.png"
  },

  misc = {
    name = "Misc",
    icon = "icon16/rainbow.png"
  },
}

local healthRestoreCallback = function(ply, item)
  local maxHealth = ply:GetMaxHealth();
  if ((ply:Health() + item.healthamount) > maxHealth) then
    ply:SetHealth(maxHealth);
  else
    ply:SetHealth(ply:Health() + item.healthamount);
  end
end

local registerWeapons = function()
  local weaponList = inventoryItems["weapons"];
  for k, weapon in pairs(weapons.GetList()) do
    if (weapon.ClassName == nil) then return; end

    inventoryItems["weapons"][weapon.ClassName] = {};
    local newwp = inventoryItems["weapons"][weapon.ClassName];
    if (weapon.WorldModel ~= nil) then newwp.model = weapon.WorldModel; else newwp.model = weapon.WM; end
    newwp.weapon = weapon.ClassName;
    newwp.contrabandLevel = "red";
    newwp.description = "Sample weapon description goes here";
    newwp.ispreregistered = true;
    if (weapon.Description ~= nil) then newwp.description = weapon.Description; end
  end

  //PrintTable(inventoryItems["weapons"]);
end

inventoryItems = {
  consumables = {
    healthkit = {
      name = "Health Kit",
      description = "Restores 25 HP.",
      model = "models/Items/HealthKit.mdl",
      healthamount = 25,
      consumable = true,
      consumeCallback = healthRestoreCallback,
    },

    healthvial = {
      name = "Health Vial",
      description = "Restores 10 HP.",
      model = "models/healthvial.mdl",
      healthamount = 10,
      consumable = true,
      consumeCallback = healthRestoreCallback,
    },
  },

  utility = {
    gasmask = {
      name = "Gas Mask",
      weight = 5,
      specialType = "gasmask",
      contrabandLevel = "yellow"
    },

    dooroverride = {
      name = "Door Override Remote",
      description = "Keyed to Resistance doors.",
      model = "models/weapons/w_Pistol.mdl",
      weight = 0,
    },

    controlremote = {
      name = "Base Control Remote",
      model = "models/weapons/w_stunbaton.mdl",
      weight = 0,
      droppable = false,
      contrabandLevel = "green",
    },
  },

  weapons = {
  },

  misc = {
    nothing = {
      name = "Nothing",
      description = "Literally nothing.",
      droppable = false,
    },

    cid = {
      name = "CID Card",
      model = "models/props_lab/clipboard.mdl",
      droppable = false,
      specialType = "cid"
    }
  }
}

registerWeapons();
