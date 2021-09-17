if (SERVER) then
include("../../../../gamemode/gui/sv_inventory_items.lua");
end

TOOL.Name = "Item Spawner";
TOOL.Category = "Tower HL2RP";

local SpawnerItems = {}; local listbox; local model = "models/items/item_item_crate.mdl"; local itemname = "nothing";

cleanup.Register("prop_item");

function TOOL:LeftClick(trace)
	if (trace.HitSky or !trace.HitPos or IsValid(trace.Entity) and (trace.Entity:IsPlayer() or trace.Entity:IsNPC())) then return false end
	if (CLIENT) then return true; end

	local ply = self:GetOwner();
	local ang = trace.HitNormal:Angle();
	ang.pitch = ang.pitch - 270;

	if (trace.HitNormal.z > 0.9999) then ang.y = ply:GetAngles().y + 90; end

	if (!ply:IsAdmin()) then
		notification.AddLegacy("You do not have permission to use this tool.", NOTIFY_ERROR, 3);
		surface.PlaySound("buttons/button10.wav");
		return;
	end

  local realItem = Inventory:FullItemFromName(itemname);
	if (realItem == nil) then
		notification.AddLegacy("The item selected is invalid.", NOTIFY_ERROR, 3);
		surface.PlaySound("buttons/button10.wav");
		return;
	end

  local ent = ents.Create("prop_item");
	local min = ent:OBBMins();
  ent.Item = table.Copy(realItem);
  ent.ItemName = itemname;
  ent:SetPos(trace.HitPos - trace.HitNormal * min.z);
	ent:SetAngles(ang);
  ent:Spawn();

	undo.Create("prop_item");
		undo.AddEntity(ent);
		undo.SetPlayer(ply);
	undo.Finish();

	return true;
end

function TOOL:UpdateGhostEntity(ent, ply)
	if (!IsValid(ent)) then return; end

	local trace = ply:GetEyeTrace();

	if (!trace.Hit) then return; end
	if (trace.Entity && (trace.Entity:GetClass() == "prop_item" || trace.Entity:IsPlayer())) then ent:SetNoDraw(true); return; end
	if (CLIENT) then return true; end

	local ply = self:GetOwner();
	local ang = trace.HitNormal:Angle();
	ang.pitch = ang.pitch - 270;

	if (trace.HitNormal.z > 0.9999) then ang.y = ply:GetAngles().y + 90; end

	if (!ply:IsAdmin()) then
		notification.AddLegacy("You do not have permission to use this tool.", NOTIFY_ERROR, 3);
		surface.PlaySound("buttons/button10.wav");
		return;
	end

	local min = ent:OBBMins();
	ent:SetPos(trace.HitPos - trace.HitNormal * min.z);

	ent:SetAngles(ang);
	ent:SetNoDraw(false);
end

function TOOL:Think()
	if (!IsValid(self.GhostEntity) || self.GhostEntity:GetModel() != model) then
		self:MakeGhostEntity(model, Vector(0, 0, 0), Angle(0, 0, 0));
	end

	self:UpdateGhostEntity(self.GhostEntity, self:GetOwner());
end

if (SERVER) then
util.AddNetworkString("ItemSpawnerStoolServerControlCommand");
util.AddNetworkString("ItemSpawnerStoolClientControlCommand");

net.Receive("ItemSpawnerStoolServerControlCommand", function(len, ply)
	local rxTable = net.ReadTable();
	local command = rxTable["command"];
	if (command == "ListItems") then
		local ilist = {};
		for k, v in pairs(inventoryItems) do
			for k, v in pairs(v) do
				local item = v;
				item.consumeCallback = nil;
				ilist[k] = item;
			end
		end

		net.Start("ItemSpawnerStoolClientControlCommand");
		net.WriteTable({command = "ListItems", itemList = ilist, categoryList = inventoryCategories});
		net.Send(ply);
	end
end);

elseif (CLIENT) then
language.Add("tool.prop_item", "Item Spawner");
language.Add("tool.prop_item.name", "Item Spawner Tool");
language.Add("tool.prop_item.desc", "Spawn items for use with DMI SmartInventory.");
language.Add("tool.prop_item.left", "Spawn an item");

net.Receive("ItemSpawnerStoolClientControlCommand", function()
	local rxTable = net.ReadTable();
	local command = rxTable["command"];
	if (command == "ListItems") then
		SpawnerItems = rxTable["itemList"];
		for k, v in pairs(SpawnerItems) do
			listbox:AddLine(k);
		end
	end
end);

function TOOL.BuildCPanel(panel)
	net.Start("ItemSpawnerStoolServerControlCommand");
	net.WriteTable({command = "ListItems"});
	net.SendToServer();

	//PrintTable(SpawnerItems);
	listbox = vgui.Create("DListView");
	listbox:AddColumn("Items");
	listbox:SetHeight(600);

	function listbox:OnRowSelected(index, row)
		local name = row:GetColumnText(1);
		itemname = name;

		if (SpawnerItems[itemname] ~= nil and SpawnerItems[itemname].model ~= nil) then
			model = SpawnerItems[itemname].model;
		end
	end

	local refreshbtn = vgui.Create("DButton");
	refreshbtn:SetText("Refresh");

	panel:AddItem(listbox);
	panel:AddItem(refreshbtn);
end
end
