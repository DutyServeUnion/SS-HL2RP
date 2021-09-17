include("shared.lua");

local dermaAlreadyOpen = false;

local vendorNames = {
  "C. Johnson",
};

function ENT:Initialize()
  net.Receive("VendorServerDermaControlCommand", function()
    local rxTable = net.ReadTable();
    local command = rxTable["command"];
    if (command == "OpenDerma") then
      if (dermaAlreadyOpen == false) then
        self:OpenDerma(rxTable["entlist"], rxTable["currentCredits"]);
      end
    elseif (command == "ItemBought") then
      notification.AddLegacy("You bought this item successfully!", NOTIFY_GENERIC, 3);
      surface.PlaySound("buttons/button24.wav");
    elseif (command == "NotEnoughCredits") then
      notification.AddLegacy("Not enough credits to buy this item! You need " .. (rxTable["entityItem"]["entPrice"] - rxTable["currentCredits"]) .. " more credits!", NOTIFY_ERROR, 3);
      surface.PlaySound("buttons/button10.wav");
    end
  end);
end

function ENT:ClickDermaItem(ent)
  net.Start("VendorClientDermaControlCommand");
  net.WriteTable({command = "BuyItem", attributes = {
    item = ent,
  }});

  net.SendToServer();
end

function ENT:OpenDerma(entList, credits)
  local NPCShop = vgui.Create("DFrame");
  NPCShop:SetPos(0, 0);
  NPCShop:SetSize(ScrW() * (600 / 1920), ScrH() * (400 / 1080));
  NPCShop:Center();
  NPCShop:SetTitle("NPC Vendor: " .. vendorNames[1]);
  NPCShop:SetDraggable(true);
  NPCShop:ShowCloseButton(true);

  NPCShop.OnClose = function()
    dermaAlreadyOpen = false;
  end

  local ShopHelpLabel = vgui.Create("DLabel", NPCShop);

  ShopHelpLabel:DockMargin(3, 0, 0, 3);
  ShopHelpLabel:Dock(TOP);
  ShopHelpLabel:SetFont("SSHL2RP_DermaMedium");
  ShopHelpLabel:SetText("Click on the item image to purchase the item.");

  local NPCScroll = vgui.Create("DScrollPanel", NPCShop);
  -- Width: 400, Height: 100
  NPCScroll:SetSize(ScrW() * (600 / 1920), ScrH() * (400 / 1080));
  NPCScroll:Dock(FILL);

  for className, ent in pairs(entList) do
    local EntSlide = vgui.Create("DPanel");

    -- Width: 400, Height: 95
    EntSlide:SetSize(ScrW() * (590 / 1920), ScrH() * (100 / 1080));
    EntSlide:Dock(RIGHT);
    EntSlide:DockPadding(1, 1, 1, 1);

    local EntImageBox;

    if (ent["entThumbType"] == "model") then
      EntImageBox = vgui.Create("DAdjustableModelPanel", EntSlide);
      EntImageBox:SetLookAt(Vector(0, 0, 0));
      EntImageBox:SetModel(ent["entThumbModel"]);

      local bound_min, bound_max = EntImageBox.Entity:GetRenderBounds();
      local bounds = 0;

      local bounds = math.max(bounds, math.abs(bound_min.x) + math.abs(bound_max.x));
      local bounds = math.max(bounds, math.abs(bound_min.y) + math.abs(bound_max.y));
      local bounds = math.max(bounds, math.abs(bound_min.z) + math.abs(bound_max.z));

      EntImageBox:SetCamPos(Vector(bounds, bounds, bounds));
      EntImageBox:SetLookAt((bound_min + bound_max) * 0.5);
    elseif (ent["entThumbType"] == "image") then
      EntImageBox = vgui.Create("DImageButton", EntSlide);
      EntImageBox:SetImage(ent["entThumbImage"]);
    end
    -- Width: 90, Height: 90

    EntImageBox:SetSize(ScrW() * (100 / 1920), ScrH() * (100 / 1080));
    EntImageBox:Dock(LEFT);

    EntImageBox.DoClick = function() self:ClickDermaItem(ent); end

    local slide_x, slide_y = EntSlide:GetSize();
    local image_x, image_y = EntImageBox:GetSize();

    local EntTitleLabel = vgui.Create("DLabel", EntSlide);

    EntTitleLabel:DockMargin(10, 3, 0, 0);
    EntTitleLabel:Dock(TOP);
    EntTitleLabel:SetFont("DermaLarge");
    EntTitleLabel:SetText(ent["entTitle"]);

    local EntTypeLabel = vgui.Create("DLabel", EntTitleLabel);

    EntTypeLabel:DockMargin((EntTitleLabel:GetSize() * 2) + 40, 8, 0, 0);
    EntTypeLabel:Dock(LEFT);
    EntTypeLabel:SetFont("SSHL2RP_DermaMedium");
    EntTypeLabel:SetText(ent["entType"]);

    local EntDescriptionLabel = vgui.Create("DLabel", EntSlide);

    EntDescriptionLabel:DockMargin(10, 3, 0, 0);
    EntDescriptionLabel:Dock(TOP);
    EntDescriptionLabel:SetFont("SSHL2RP_DermaMedium");
    EntDescriptionLabel:SetText(ent["entDescription"]);
    EntDescriptionLabel:SetAutoStretchVertical(true);
    EntDescriptionLabel:SetWrap(true);

    local EntPriceLabel = vgui.Create("DLabel", EntSlide);

    EntPriceLabel:DockMargin(10, 0, 0, 3);
    EntPriceLabel:Dock(BOTTOM);
    EntPriceLabel:SetFont("DermaLarge");
    EntPriceLabel:SetText(("£" .. ent["entPrice"]));

    if (credits < ent["entPrice"]) then
      EntSlide:SetBackgroundColor(Color(21, 18, 23, 210));
      EntImageBox:SetFGColor(Color(21, 18, 23, 210));
      EntPriceLabel:SetFGColor(Color(212, 58, 58, 255));
    else
      EntSlide:SetBackgroundColor(Color(21, 18, 23, 120));
      EntPriceLabel:SetFGColor(Color(69, 212, 58, 255));
    end

    NPCScroll:AddItem(EntSlide);
  end

  NPCShop:SetVisible(true);
  NPCShop:MakePopup();
end

function ENT:Draw()
  self:DrawModel();
end
