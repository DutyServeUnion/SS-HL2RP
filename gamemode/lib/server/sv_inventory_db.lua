Inventory = {};
Inventory.__index = Inventory;

-- !!!!!
-- BEFORE PROD MAKE SURE DATABASE USES VAR NAME OF ITEM INSTEAD OF DESC. NAME
-- !!!!!

-- Initializes the database if it dosen't already exist.
function Inventory:InitializeDatabase()
  sql.Query("CREATE TABLE IF NOT EXISTS dmi_inventory(steamid TEXT, itemname TEXT, variation TEXT, map TEXT, count INTEGER, confiscated INTEGER, durability INTEGER, maxdurability INTEGER)");
end

-- Wipes the database clean.
function Inventory:DestroyDatabase()
  sql.Query("DROP TABLE dmi_inventory");
end

-- Adds an item to the database.
-- If the item already exists, it just increments the item count.
function Inventory:AddItem(ply, item, itemname)
  if (!IsValid(ply) or item == nil or itemname == nil) then print("[Inventory] Tried to add item with invalid player or null itemname! Contact a developer.") return; end
  if (item.specialType == "cid") then
  ply:SetNWBool("HasUnionIDCard", true);
  end

  local pre_item = Inventory:GetItem(ply, itemname);

  local confiscated = 0;
  local durability = 0;
  local maxdurability = 0;
  local variation = "none";

  if (item.confiscated) then confiscated = 1 end
  if (item.durability ~= nil) then durability = item.durability end
  if (item.maxdurability ~= nil) then maxdurability = item.maxdurability end
  if (item.variation ~= nil) then variation = item.variation end
  if (item.count == nil) then item.count = 1 end

  if (pre_item ~= nil) then
    local newCount = pre_item.count + item.count;
    local query = "UPDATE dmi_inventory SET count=" .. newCount .. " WHERE steamid=" .. sql.SQLStr(ply:SteamID()) .. " AND itemname=" .. sql.SQLStr(itemname) .. " AND map=" .. sql.SQLStr(game.GetMap());
    sql.Query(query);
  else
    local query = "INSERT INTO dmi_inventory(steamid, itemname, variation, map, count, confiscated, durability, maxdurability) VALUES(" .. sql.SQLStr(ply:SteamID()) .. ", " .. sql.SQLStr(itemname) .. ", " .. sql.SQLStr(variation) .. ", " .. sql.SQLStr(game.GetMap()) .. ", " .. sql.SQLStr(item.count) .. ", " .. sql.SQLStr(confiscated) .. ", " .. sql.SQLStr(durability) .. ", " .. sql.SQLStr(maxdurability) .. ")";
    sql.Query(query);
  end
end

-- Updates the item with new data.
-- Should only need to be used when changing the durability.
function Inventory:UpdateItem(ply, item, itemname)
  local pre_item = Inventory:GetItem(ply, itemname);

  local confiscated = 0;
  local durability = 0;
  local maxdurability = 0;
  local variation = "none";

  if (item.confiscated) then confiscated = 1 end
  if (item.durability ~= nil) then durability = item.durability end
  if (item.maxdurability ~= nil) then maxdurability = item.maxdurability end
  if (item.variation ~= nil) then variation = item.variation end

  if (pre_item ~= nil) then
    local query = "UPDATE dmi_inventory SET steamid=" .. sql.SQLStr(ply:SteamID()) .. ", itemname=" .. sql.SQLStr(itemname) .. ", variation=" .. sql.SQLStr(variation) .. ", map=" .. sql.SQLStr(game.GetMap()) .. ", count=" .. sql.SQLStr(item.count) .. ", confiscated=" .. sql.SQLStr(item.confiscated) .. ", durability=" .. sql.SQLStr(item.durability) .. ", maxdurability=" .. sql.SQLStr(item.maxdurability) .. " WHERE steamid=" .. sql.SQLStr(ply:SteamID()) .. " AND itemname=" .. sql.SQLStr(itemname) .. " AND map=" .. sql.SQLStr(game.GetMap());
    sql.Query(query);
  end
end

-- Removes the item from the database.
function Inventory:RemoveItem(ply, itemname, ignoreCount, count)
  local curItem = Inventory:GetItem(ply, itemname);
  if (curItem == nil) then return; end
  if (count == nil) then count = 1; end

  // Remove one item
  if (tonumber(curItem.count) > count && ignoreCount == false) then
    local newCount = tonumber(curItem.count) - count;
    local query = "UPDATE dmi_inventory SET count=" .. newCount .. " WHERE steamid=" .. sql.SQLStr(ply:SteamID()) .. " AND itemname=" .. sql.SQLStr(itemname) .. " AND map=" .. sql.SQLStr(game.GetMap());
    sql.Query(query);
    return;
  end

  local fullItem = Inventory:FullItemFromEntry(curItem);

  if (fullItem.specialType == "cid") then
  ply:SetNWBool("HasUnionIDCard", false);
  end

  // Delete the remaining entry
  local query = "DELETE FROM dmi_inventory WHERE steamid=" .. sql.SQLStr(ply:SteamID()) .. " AND itemname=" .. sql.SQLStr(itemname) .. " AND map=" .. sql.SQLStr(game.GetMap());
  sql.Query(query);
end

-- Gets the item instance from a player.
-- Returns nil if the player has none of the item.
function Inventory:GetItem(ply, itemname)
  local query = "SELECT * FROM dmi_inventory WHERE itemname = " .. sql.SQLStr(itemname) .. " AND steamid = " .. sql.SQLStr(ply:SteamID()) .. " AND map=" .. sql.SQLStr(game.GetMap()) .. " LIMIT 1";
  local result = sql.Query(query);

  if (result ~= nil && result ~= false) then
    return result[1];
  else
    return nil;
  end
end

-- Gets a table containing item instances from a player.
-- If the player has no items (unlikely), returns nil.
function Inventory:GetAllItems(ply, netSafe)
  local query = "SELECT * FROM dmi_inventory WHERE steamid = " .. sql.SQLStr(ply:SteamID()) .. " AND map=" .. sql.SQLStr(game.GetMap());
  local results = sql.Query(query);

  if (results ~= nil && result ~= false) then
    local fullResults = {};
    for k, v in pairs(results) do
      local item = Inventory:FullItemFromEntry(v);
      if (item ~= nil && item.category ~= nil) then
        if (netSafe == true) then item.consumeCallback = nil end
        fullResults[v.itemname] = item;
      end
    end

    return fullResults;
  else
    return nil;
  end
end

function Inventory:ResetPlayerInventory(ply)
  local items = Inventory:GetAllItems(ply);
  if (items ~= nil) then
    for k, item in pairs(items) do
      Inventory:RemoveItem(ply, k, true);
    end
  end
end

function Inventory:FullItemFromEntry(dbitem, countOverride)
  if (dbitem == nil) then return nil; end

  for k1, category in pairs(table.Copy(inventoryItems)) do
    if (category[dbitem.itemname] ~= nil) then
      local item = category[dbitem.itemname];
      item.category = k1;
      if (countOverride ~= nil) then
        item.count = countOverride;
      else
        item.count = dbitem.count;
      end

      item.variation = dbitem.variation;
      return item;
    end
  end

  return nil;
end

function Inventory:FullItemFromName(name)
  for k1, category in pairs(table.Copy(inventoryItems)) do
    if (category[name] ~= nil) then
      local item = category[name];
      item.category = k1;
      return item;
    end
  end

  return nil;
end

function Inventory:GetAllUserInventories()
  local query = "SELECT * FROM dmi_inventory WHERE map=" .. sql.SQLStr(game.GetMap());
  local results = sql.Query(query);
  if (results == nil) then return {}; end

  local steamids = {};

  for k, entry in pairs(results) do
    if (steamids[entry.steamid] == nil) then
      steamids[entry.steamid] = entry.steamid;
    end
  end

  return steamids;
end

hook.Add("PlayerSpawn", "InventorySpecialActionsHook", function(ply)
  local cid = Inventory:GetItem(ply, "cid");
  if (cid ~= nil && cid.specialType == "cid") then
    ply:SetNWBool("HasUnionIDCard", true);
  else
    ply:SetNWBool("HasUnionIDCard", false);
  end
end);
