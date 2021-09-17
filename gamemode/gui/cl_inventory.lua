local dermaAlreadyOpen = false;
local tabScrollers = tabScrollers or {};
local Browser;

Inventory = {};
Inventory.__index = Inventory;

function Inventory:AddWeaponInfo(itemlist)
  for k, weapon in pairs(weapons.GetList()) do
    if (weapon.ClassName ~= nil and itemlist[weapon.ClassName] ~= nil and itemlist[weapon.ClassName].ispreregistered == true) then
      local clw = itemlist[weapon.ClassName];
      clw.name = weapon.PrintName;
    end
  end
end

local function RefreshItems(grid, itemList, name)
  if (itemList ~= nil) then
    Inventory:AddWeaponInfo(itemList);
    for k, item in pairs(itemList) do
      if (item.category == name) then
        local itemslide = vgui.Create("DPanel");
        itemslide:SetSize((ScrW() * (582 / 1920)), ScrH() * (120 / 1080));
        //itemslide:Dock(TOP);
        itemslide:DockPadding(1, 1, 1, 1);
        itemslide:DockMargin(8, 8, 8, 8);
        itemslide:SetBackgroundColor(Color(21, 18, 23, 120));

        local preview = vgui.Create("DModelPanel", itemslide);
        preview:SetLookAt(Vector(0, 0, 0));

        if (item.model ~= nil) then preview:SetModel(item.model); else preview:SetModel("models/items/item_item_crate.mdl"); end

        if (item.specialType == "gasmask") then
          if (item.variation == "basic") then
            preview:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
          elseif (item.variation == "metrocop") then
            preview:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
          elseif (item.variation == "officer") then
            preview:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
          elseif (item.variation == "elite") then
            preview:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
          elseif (item.variation == "squadleader") then
            preview:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
          elseif (item.variation == "divisionleader") then
            preview:SetModel("models/dpfilms/metropolice/props/elite_gasmask.mdl");
          elseif (item.variation == "seccommand") then
            preview:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
          elseif (item.variation == "cmbofficer") then
            preview:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
          elseif (item.variation == "cityadmin") then
            preview:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
          elseif (item.variation == "sentinel") then
            preview:SetModel("models/dpfilms/metropolice/props/phoenix_gasmask.mdl");
          else
            preview:SetModel("models/dpfilms/metropolice/props/generic_gasmask.mdl");
          end
        end

        local bound_min, bound_max = preview.Entity:GetRenderBounds();
        local bounds = 0;

        local bounds = math.max(bounds, math.abs(bound_min.x) + math.abs(bound_max.x));
        local bounds = math.max(bounds, math.abs(bound_min.y) + math.abs(bound_max.y));
        local bounds = math.max(bounds, math.abs(bound_min.z) + math.abs(bound_max.z));

        preview:SetCamPos(Vector(bounds, bounds, bounds));
        preview:SetLookAt((bound_min + bound_max) * 0.5);
        preview:SetSize(ScrW() * (100 / 1920), ScrH() * (100 / 1080));
        preview:Dock(LEFT);

        local title = vgui.Create("DLabel", itemslide);

        title:DockMargin(5, 10, 0, 0);
        title:Dock(TOP);
        title:SetFont("DermaLarge");

        if (tonumber(item.count) > 1) then
          title:SetText(item.name .. " (" .. item.count .. "x)");
        else
          title:SetText(item.name);
        end

        title:SizeToContents();

        local textx, texty = itemslide:GetPos();

        if (item.description ~= nil) then
          local description = vgui.Create("DLabel", itemslide);
          description:SetText(item.description);
          description:SetFont("DermaDefault");
          description:SetPos(textx + 108, texty + 40);
          description:SizeToContents();
        end

        if (item.contrabandLevel ~= nil) then
          local contrabandLabel = vgui.Create("DLabel", itemslide);
          local contrabandIcon = vgui.Create("DImage", itemslide);
          contrabandLabel:SetFont("DermaDefault")
          contrabandIcon:SetSize(16, 16);

          if (item.contrabandLevel == "green") then
            contrabandLabel:SetText("Class-A contraband");
            contrabandLabel:SetTextColor(Color(78, 146, 206, 255));
            contrabandIcon:SetImage("icon16/information.png");
          elseif (item.contrabandLevel == "yellow") then
            contrabandLabel:SetText("Class-B contraband");
            contrabandLabel:SetTextColor(Color(216, 210, 26, 255));
            contrabandIcon:SetImage("icon16/error.png");
          elseif (item.contrabandLevel == "red") then
            contrabandLabel:SetText("Class-C contraband");
            contrabandLabel:SetTextColor(Color(236, 95, 84, 255));
            contrabandIcon:SetImage("icon16/delete.png");
          end

          contrabandIcon:SetPos(textx + 108, texty + 60);
          contrabandLabel:SetPos(textx + 126, texty + 60);
          contrabandLabel:SizeToContents();
        end

        local dropButton = vgui.Create("DButton", itemslide);
        dropButton:SetText("Drop");
        dropButton:SetPos(textx + 108, texty + 80);
        dropButton:SetSize(100, 20);
        dropButton:SetIcon("icon16/arrow_down.png");
        dropButton.DoClick = function()
          net.Start("InventoryClientDermaControlCommand");
          net.WriteTable({command = "DropItem", itemname = k});
          net.SendToServer();
        end

        if (item.droppable == false) then dropButton:SetEnabled(false); end

        local equipButton = vgui.Create("DButton", itemslide);
        if (item.weapon ~= nil && IsValid(LocalPlayer():GetWeapon(item.weapon)) == true) then
          dropButton:SetEnabled(false);

          equipButton:SetText("Unequip");
          equipButton:SetPos(textx + 216, texty + 80);
          equipButton:SetSize(100, 20);
          equipButton:SetIcon("icon16/delete.png");
          equipButton.DoClick = function()
            net.Start("InventoryClientDermaControlCommand");
            net.WriteTable({command = "UnequipItem", itemname = k});
            net.SendToServer();
          end

          equipButton:SetEnabled(true);
        else
          equipButton:SetText("Equip");
          equipButton:SetPos(textx + 216, texty + 80);
          equipButton:SetSize(100, 20);
          equipButton:SetIcon("icon16/add.png");
          equipButton.DoClick = function()
            net.Start("InventoryClientDermaControlCommand");
            net.WriteTable({command = "EquipItem", itemname = k});
            net.SendToServer();
          end

          if (item.weapon == nil) then equipButton:SetEnabled(false); end
        end

        local useButton = vgui.Create("DButton", itemslide);
        useButton:SetText("Use");
        useButton:SetPos(textx + 324, texty + 80);
        useButton:SetSize(100, 20);
        useButton:SetIcon("icon16/briefcase.png");
        useButton.DoClick = function()
          net.Start("InventoryClientDermaControlCommand");
          net.WriteTable({command = "UseItem", itemname = k});
          net.SendToServer();
        end

        if (item.consumable ~= true) then useButton:SetEnabled(false); end

        grid:AddItem(itemslide);
      end
    end
  end

  grid:InvalidateLayout();
end

-- Called to open the DMI SmartInventory admin menu.
local function ToggleAdminMenu(userInventories, smartInvSettings)
  Menu = vgui.Create("DFrame");
  Menu:SetSize(ScrW() * (500 / 1920), ScrH() * (850 / 1080));
  Menu:Center();
  Menu:SetTitle("DMI SmartInventory Admin");
  Menu:SetDraggable(true);
  Menu:ShowCloseButton(true);

  local TabView = vgui.Create("DPropertySheet", Menu);
  TabView:Dock(FILL);

  local InventoriesForm = vgui.Create("DForm", TabView);
  TabView:AddSheet("Inventories", InventoriesForm, "icon16/group.png");
  InventoryList = vgui.Create("DListView");
	InventoryList:AddColumn("Inventories");
	InventoryList:SetHeight(800);

  InventoriesForm:AddItem(InventoryList);

  local SettingsForm = vgui.Create("DForm", TabView);
  TabView:AddSheet("Settings", SettingsForm, "icon16/wrench.png");
end

-- Called when the player presses the hotkey to open the derma menu.
local function ToggleDerma(itemList, categoryList)
  if (dermaAlreadyOpen) then
    Browser:Close();
    return;
  else
    tabScrollers = {};
    dermaAlreadyOpen = true;

    local derma_h = 1000;
    local derma_w = 1200;

    Browser = vgui.Create("DFrame");
    Browser:SetSize(ScrW() * (derma_w / 1920), ScrH() * (derma_h / 1080));
    Browser:Center();
    Browser:SetTitle("Inventory Browser");
    Browser:SetDraggable(true);
    Browser:ShowCloseButton(true);
    Browser:SetBackgroundBlur(true);

    Browser.OnClose = function()
      dermaAlreadyOpen = false;
    end

    local TabView = vgui.Create("DPropertySheet", Browser);
    TabView:Dock(FILL);

    for name, category in pairs(categoryList) do
      local scroll = vgui.Create("DScrollPanel", TabView);
      TabView:AddSheet(category.name, scroll, category.icon);
      scroll:Dock(FILL);

      local grid = vgui.Create("DGrid", scroll);
      grid:Dock(FILL);
      grid:DockMargin(8, 0, 0, 0);
      grid:SetCols(2);
      grid:SetColWide(ScrW() * (590 / 1920));
      grid:SetRowHeight((ScrH() * (120 / 1080)) + 10);
      RefreshItems(grid, itemList, name);

      tabScrollers[name] = scroll;
    end

    Browser:SetVisible(true);
    Browser:MakePopup();
  end
end

concommand.Add("dmi_toggleinventory", function(ply, cmd, args, argStr)
  print("Toggling DMI inventory");

  net.Start("InventoryClientDermaControlCommand");
  net.WriteTable({command = "OpenDerma"});
  net.SendToServer();
 end);

 concommand.Add("dmi_toggleadmin", function(ply, cmd, args, argStr)
   print("Toggling DMI administration panel");

   net.Start("InventoryClientDermaControlCommand");
   net.WriteTable({command = "OpenAdmin"});
   net.SendToServer();
  end);

 net.Receive("InventoryServerDermaControlCommand", function()
   local rxTable = net.ReadTable();
   local command = rxTable["command"];
   if (command == "OpenDerma") then
     ToggleDerma(rxTable["itemList"], rxTable["categoryList"]);
   elseif (command == "OpenAdmin") then
     ToggleAdmin(rxTable["userInventories"], rxTable["smartInvSettings"]);
   elseif (command == "Notification") then
     notification.AddLegacy(rxTable["notify_text"], rxTable["notify_type"], rxTable["notify_duration"]);
     surface.PlaySound(rxTable["notify_sound"]);
   elseif (command == "RefreshCategory") then
     tabScrollers[rxTable["category"]]:Clear();

     local grid = vgui.Create("DGrid", tabScrollers[rxTable["category"]]);
     grid:Dock(FILL);
     grid:DockMargin(8, 0, 0, 0);
     grid:SetCols(2);
     grid:SetColWide(ScrW() * (590 / 1920));
     grid:SetRowHeight((ScrH() * (120 / 1080)) + 10);
     RefreshItems(grid, rxTable["itemList"], rxTable["category"]);

   --elseif (command == "NotEnoughCredits") then
   --  notification.AddLegacy("Not enough credits to buy this item! You need " .. (rxTable["entityItem"]["entPrice"] - rxTable["currentCredits"]) .. " more credits!", NOTIFY_ERROR, 3);
   --  surface.PlaySound("buttons/button10.wav");
   end
 end);
