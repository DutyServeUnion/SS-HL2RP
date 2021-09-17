include("../lib/server/sv_inventory_db.lua");
include("sv_inventory_items.lua");

util.AddNetworkString("InventoryServerDermaControlCommand");
util.AddNetworkString("InventoryClientDermaControlCommand");

// START OF CONFIGURATION SECTION
// Whether to reset player inventories on death.
local resetItemsOnDeath = true;
local giveNoAmmoOnWeaponSpawn = true;

// END OF CONFIGURATION SECTION - DO NOT EDIT PAST THIS LINE

local function SendNotification(ply, text, notifyType, duration, sound)
  net.Start("InventoryServerDermaControlCommand");
  net.WriteTable({command = "Notification", notify_text = text, notify_type = notifyType, notify_duration = duration, notify_sound = sound});
  net.Send(ply);
end

local function RefreshClientCategory(ply, category)
  local itemList = Inventory:GetAllItems(ply, true);

  net.Start("InventoryServerDermaControlCommand");
  net.WriteTable({command = "RefreshCategory", itemList = itemList, category = category});
  net.Send(ply);
end

// ITEM MANIPULATION METHOD SECTION
// These methods will return the item dropped (a table) on success, and false on failure.

// Drops an item. This will fail if the item is not droppable
// or if the item is currently equipped.
local function dropItem(ply, itemname)
  if (itemname == nil) then return false; end
  local realItem = Inventory:FullItemFromEntry(Inventory:GetItem(ply, itemname), 1);

  if (realItem == nil) then SendNotification(ply, "You don't have this item in your inventory.", NOTIFY_ERROR, 3, "buttons/button10.wav"); return false; end
  if (realItem.droppable == false) then SendNotification(ply, "This item is not droppable.", NOTIFY_ERROR, 3, "buttons/button10.wav"); return false; end

  Inventory:RemoveItem(ply, itemname, false, 1);
  ply:EmitSound("items/suitchargeno1.wav");

  local ent = ents.Create("prop_item");
  ent.Item = table.Copy(realItem);
  ent.ItemName = itemname;
  ent:SetPos(ply:GetEyeTrace().HitPos);
  ent:Spawn();

  return realItem;
end

// Equips an equippable item or weapon.
local function equipItem(ply, itemname)
  if (itemname == nil) then return false; end
  local realItem = Inventory:FullItemFromEntry(Inventory:GetItem(ply, itemname));
  if (realItem == nil) then SendNotification(ply, "You don't have this item in your inventory.", NOTIFY_ERROR, 3, "buttons/button10.wav"); return false; end

  if (realItem.specialType = "gasmask") then
  else
    if (realItem.weapon == nil) then SendNotification(ply, "This item is not equippable.", NOTIFY_ERROR, 3, "buttons/button10.wav"); return false; end
    if (IsValid(ply:GetWeapon(realItem.weapon)) ~= false) then SendNotification(ply, "You've already equipped this item.", NOTIFY_ERROR, 3, "buttons/button10.wav"); return false; end

    ply:Give(realItem.weapon, giveNoAmmoOnWeaponSpawn);
    if (giveNoAmmoOnWeaponSpawn) then
      local weapon = ply:GetWeapon(realItem.weapon);
      local pammo = weapon:GetPrimaryAmmoType();
      local sammo = weapon:GetSecondaryAmmoType();
      if (pammo ~= nil) then ply:RemoveAmmo(ply:GetAmmoCount(pammo), pammo); end
      if (sammo ~= nil) then ply:RemoveAmmo(ply:GetAmmoCount(sammo), sammo); end
    end
  end

  return realItem;
end

// Unequips an equippable item or weapon.
local function unequipItem(ply, itemname)
  if (itemname == nil) then return false; end
  local realItem = Inventory:FullItemFromEntry(Inventory:GetItem(ply, itemname));
  if (realItem == nil) then SendNotification(ply, "You don't have this item in your inventory.", NOTIFY_ERROR, 3, "buttons/button10.wav"); return false; end

  if (realItem.specialType = "gasmask") then
  else
    if (realItem.weapon == nil) then SendNotification(ply, "This item is not equippable.", NOTIFY_ERROR, 3, "buttons/button10.wav"); return false; end
    if (IsValid(ply:GetWeapon(realItem.weapon)) ~= true) then SendNotification(ply, "This item is not equipped.", NOTIFY_ERROR, 3, "buttons/button10.wav"); return false; end

    ply:StripWeapon(realItem.weapon);
  end

  return realItem;
end

// Uses (or "consumes") an item.
local function useItem(ply, itemname)
  if (itemname == nil) then return false; end
  local realItem = Inventory:FullItemFromEntry(Inventory:GetItem(ply, itemname));
  if (realItem == nil) then SendNotification(ply, "You don't have this item in your inventory.", NOTIFY_ERROR, 3, "buttons/button10.wav"); return false; end
  if (realItem.consumable ~= true) then SendNotification(ply, "This item is not usable.", NOTIFY_ERROR, 3, "buttons/button10.wav"); return false; end

  Inventory:RemoveItem(ply, itemname, false, 1);
  ply:EmitSound("items/suitchargeno1.wav");

  if (realItem.consumeCallback ~= nil) then realItem.consumeCallback(ply, realItem); end
  return realItem;
end

// Adds an item to a player's inventory.
// This should be used only by administrators.
local function addItem(ply, itemname)
  local realItem = Inventory:FullItemFromName(string.lower(itemname));
  if (realItem == nil) then ply:PrintMessage(HUD_PRINTTALK, "[Inventory] This item does not exist."); return false; end

  realItem.count = 1;

  Inventory:AddItem(ply, realItem, itemname);
  return realItem;
end

// END OF ITEM MANIPULATION METHODS SECTION

net.Receive("InventoryClientDermaControlCommand", function (len, ply)
  if (ply:IsValid()) then
    local itemList = Inventory:GetAllItems(ply, true);

    local rxTable = net.ReadTable();
    local command = rxTable["command"];
    local attributes = rxTable["attributes"];

    if (command == "OpenDerma") then
      net.Start("InventoryServerDermaControlCommand");
      net.WriteTable({command = "OpenDerma", itemList = itemList, categoryList = inventoryCategories});
      net.Send(ply);
    elseif (command == "OpenAdmin") then
      net.Start("InventoryServerDermaControlCommand");
      net.WriteTable({command = "OpenAdmin", userInventories = {}, smartInvSettings = {}}});
      net.Send(ply);
    elseif (command == "DropItem") then
      local realItem = dropItem(ply, rxTable["itemname"]);
      if (realItem ~= false) then
        SendNotification(ply, "Successfully dropped this item.", NOTIFY_GENERIC, 3, "buttons/button24.wav");
        RefreshClientCategory(ply, realItem.category);
      end
    elseif (command == "EquipItem") then
      local realItem = equipItem(ply, rxTable["itemname"]);
      if (realItem ~= false) then
        SendNotification(ply, "Successfully eqippped this item.", NOTIFY_GENERIC, 3, "buttons/button24.wav");
        RefreshClientCategory(ply, realItem.category);
      end
    elseif (command == "UnequipItem") then
      local realItem = unequipItem(ply, rxTable["itemname"]);
      if (realItem ~= false) then
        SendNotification(ply, "Successfully unequipped this item.", NOTIFY_GENERIC, 3, "buttons/button24.wav");
        RefreshClientCategory(ply, realItem.category);
      end
    elseif (command == "UseItem") then
      local realItem = useItem(ply, rxTable["itemname"]);
      if (realItem ~= false) then
        SendNotification(ply, "Successfully used this item.", NOTIFY_GENERIC, 3, "buttons/button24.wav");
        RefreshClientCategory(ply, realItem.category);
      end
    end
  end
end);

hook.Add("PlayerSay", "AddItem", function(ply, cmd)
  local cmdtext = string.Split(cmd, " ");

  if (cmdtext[1] == "/additem") then
    if (#cmdtext < 2) then
      ply:PrintMessage(HUD_PRINTTALK, "[Inventory] Not enough command parameters. Valid parameters are /additem <item>.");
      return;
    end

    if (ply:IsAdmin()) then
      addItem(ply, cmdtext[2]);
    else
      ply:PrintMessage(HUD_PRINTTALK, "[Inventory] You do not have permission to use this command.");
    end
  end
end);

hook.Add("PlayerSay", "DropItem", function(ply, cmd)
  local cmdtext = string.Split(cmd, " ");

  if (cmdtext[1] == "/dropitem") then
    if (#cmdtext < 2) then
      ply:PrintMessage(HUD_PRINTTALK, "[Inventory] Not enough command parameters. Valid parameters are /dropitem <item>.");
      return;
    end

    if (dropItem(ply, cmdtext[2]) ~= false) then
      ply:PrintMessage(HUD_PRINTTALK, "[Inventory] Dropped the item.");
    end
  end
end);

hook.Add("PlayerDeath", "InventoryDeath", function(ply)
  if (resetItemsOnDeath) then Inventory:ResetPlayerInventory(ply); end
end);
