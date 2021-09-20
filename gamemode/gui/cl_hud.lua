ir", 0.5, 0, function()
   BlinkerTextVisible = !BlinkerTextVisible;

   --IncrementScrollerText();nclude("../lib/client/cl_hud_func.lua");

local hideHUDElements = hideHUDElements or {
	-- if you DarkRP_HUD this to true, ALL of DarkRP's HUD will be disabled. That is the health bar and stuff,
	-- but also the agenda, the voice chat icons, lockdown text, player arrested text and the names above players' heads
	["DarkRP_HUD"] = true,

	-- DarkRP_EntityDisplay is the text that is drawn above a player when you look at them.
	-- This also draws the information on doors and vehicles
	["DarkRP_EntityDisplay"] = false,

	-- This is the one you're most likely to replace first
	-- DarkRP_LocalPlayerHUD is the default HUD you see on the bottom left of the screen
	-- It shows your health, job, salary and wallet, but NOT hunger (if you have hungermod enabled)
	["DarkRP_LocalPlayerHUD"] = true,

	-- If you have hungermod enabled, you will see a hunger bar in the DarkRP_LocalPlayerHUD
	-- This does not get disabled with DarkRP_LocalPlayerHUD so you will need to disable DarkRP_Hungermod too
	["DarkRP_Hungermod"] = false,

	-- Drawing the DarkRP agenda
	["DarkRP_Agenda"] = false,

	-- Lockdown info on the HUD
	["DarkRP_LockdownHUD"] = false,

	-- Arrested HUD
	["DarkRP_ArrestedHUD"] = false,
}

local tickerColours = tickerColours or {
  debug = Color(255, 255, 255, 255),
  info = Color(0, 153, 0, 255),
  warn = Color(255, 153, 0, 255),
  danger = Color(255, 0, 0, 255),
  broadcast = Color(153, 0, 255, 255)
}

local tickerFonts = tickerFonts or {
  small = "SSHL2RP_DermaMedium",
  medium = "SSHL2RP_DermaAlmostLarge",
  large = "DermaLarge"
}

local tickerSymbols = tickerSymbols or {
  combine = Material("hud/cca")
}

local RegisteredVGUI = RegisteredVGUI or {}

local scrollerTextToDraw = scrollerTextToDraw or {}
local scrollerTextDrawn = scrollerTextDrawn or {}

local BlinkerTextVisible = true;

hook.Add("HUDShouldDraw", "HideDarkRPHUD", function(name)
	if hideHUDElements[name] then return false end
end)

local drawAirexBar = false;
local airexProgress = 0;
local airexProgressVal = 0;

local airexStarted = false;

local pulse_opacity = 255;
local pulse_opacity_inc = true;

local colours = colours or {
  aw_background = {
    border = Color(190, 255, 128, 255),
    background = Color(120, 240, 0, 75)
  },

  aw_bar = {
    border = Color(255, 0, 0, 255),
    background = Color(255, 0, 0, 75),
    shade = Color(255, 104, 104, 255),
    fill = Color(253, 0, 0, 200)
  },

  health_bar = {
    border = Color(100, 0, 0, 255),
    background = Color(110, 0, 0, 25),
    shade = Color(255, 104, 104, 255),
    fill = Color(125, 0, 0, 200)
  },

  armour_bar = {
    border = Color(1, 9, 127, 255),
    background = Color(0, 12, 186, 25),
    shade = Color(104, 121, 255, 255),
    fill = Color(0, 18, 168, 200)
  },

  gasmask_bar = {
    border = Color(80, 80, 89, 255),
    background = Color(139, 140, 153, 25),
    shade = Color(117, 118, 130, 255),
    fill = Color(58, 61, 59, 200)
  }
}

local function clr(col)
  return col.r, col.g, col.b, col.a;
end

local function DrawVGUI(name, vgui)
  RegisteredVGUI[name] = vgui;
end

local function DestroyVGUI(name)
  if (RegisteredVGUI[name] ~= nil) then
    RegisteredVGUI[name]:Remove();
    RegisteredVGUI[name] = nil;
  end
end

local function DrawBlinkingText(text, x, y, col)
  if (BlinkerTextVisible == true) then
    surface.SetFont("SSHL2RP_DermaMedium");
    surface.SetTextColor(col);
    surface.SetTextPos(x, y);
    surface.DrawText(text);
  end
end

-- This function draws text at the specified location.
-- A character will be drawn every 0.5s. (same as blinker timer).
local function DrawScrollerText(text, x, y, col)
  local split = {}
  text:gsub(".", function(c) table.insert(split, c) end);

  local val = {
    sposx = x,
    spoxy = y,
    colour = col,
    text = split,
    ot = text
  }

  table.insert(scrollerTextToDraw, val);
end

-- This function is called by the timer and inserts
-- a character into the scroller draw stack every 0.5 seconds
local function IncrementScrollerText()
  if (scrollerTextToDraw[1] ~= nil) then
    local dr = scrollerTextToDraw[1];

    if (dr.text[1] ~= nil) then
      local ins = {
        sposx = dr.x,
        spoxy = dr.y,
        colour = dr.col,
        char = dr.text[1],
        ot = dr.text
      }

      table.insert(scrollerTextDrawn, ins);
      table.remove(scrollerTextToDraw[1].text, 1);
    else
      table.remove(scrollerTextToDraw, 1);
    end
  end
end

-- This function is called by the game renderer
-- and actually draws the scrolled text.
local function RenderScrollerText()
  local prev_xoffset = 0;
  local prev_str = nil;

  for k, v in pairs(scrollerTextDrawn) do
    if (prev_str == v.ot) then
      local w, h = surface.GetTextSize(v.char);
      prev_xoffset = w;
    else
      prev_xoffset = 0;
    end

    surface.SetFont("SSHL2RP_DermaMedium");
    surface.SetTextColor(v.colour);
    surface.SetTextPos(v.sposx + prev_xoffset, v.sposy);
    surface.DrawText(v.char);
  end
end

local function DrawIcon(x, y, icon, name)
  if (RegisteredVGUI[name] == nil) then
    local img = vgui.Create("DImage");
    img:SetSize(16, 16);
    img:SetPos(x, y);
    img:SetImage(icon);
    img:ParentToHUD();

    DrawVGUI(name, img);
  end
end

local function DrawProgressBar(x, y, w, h, col, val)
  surface.SetDrawColor(clr(col.border));
  surface.DrawOutlinedRect(x, y, w, h);

  x = x + 1;
  y = y + 1;
  w = w - 2;
  h = h - 2;

  surface.SetDrawColor(clr(col.background));
  surface.DrawRect(x, y, w, h);

  local width = w * val;
  local offset = 4;

  surface.SetDrawColor(clr(col.shade));
  surface.DrawRect(x, y, w, offset);
  surface.SetDrawColor(clr(col.fill));
  surface.DrawRect(x, y + offset, width, h - offset);
end

local function DrawTextConstraint(text, x, y, col)
  surface.SetFont("SSHL2RP_DermaMedium");
  surface.SetTextColor(col);
  surface.SetTextPos(x, y);
  surface.DrawText(text);
end

local function DrawTextCustom(text, x, y, col, font)
  surface.SetFont(font);
  surface.SetTextColor(col);
  surface.SetTextPos(x, y);
  surface.DrawText(text);
end

local function DrawProgressBarText(x, y, w, h, col, val, text, col2)
  DrawProgressBar(x, y, w, h, col, val);
  DrawTextConstraint(text, x + 2, (y + (h / 4)), col2);
end

local function DrawProgressBarTextWithLabel(x, y, w, h, col, val, text, col2, text2)
  surface.SetFont("SSHL2RP_DermaMedium");
  local tw, th = surface.GetTextSize(text2);

  DrawProgressBarText(x, y, w, h, col, val, text, col2);
  DrawTextConstraint(text2, (x + (w / 2)) - (tw / 2), (y + (h / 4)) - 1, col2)
end

local function DrawStatusElements()
  local statbox_x = 25;
  local statbox_y = ScrH() - 180;

  local statbox_w = ScrW() * (400 / 1920);

  local statbox_h;

  if (LocalPlayer():IsValid() and LocalPlayer():GetNWBool("PlayerHasGasmask") == false) then
    statbox_h = ScrH() * (130 / 1080);
  else
    statbox_h = ScrH() * (155 / 1080);
  end

  -- Create the statbox outline
  surface.SetDrawColor(Color(78, 78, 78));
  surface.DrawOutlinedRect(statbox_x, statbox_y, statbox_w, statbox_h);

  -- Create the statbox
  surface.SetDrawColor(Color(100, 100, 100, 20));
  surface.DrawRect(statbox_x, statbox_y, statbox_w, statbox_h)

  -- Calculate player stats
  local hp = client:Health();
  local armour = client:Armor();

	local funds = 0;
	local salary = 0;
	local role = "NO DATA";
	local rpname = "NO DATA";

	if (client["getDarkRPVar"] ~= nil) then
		funds = client:getDarkRPVar("money");
	  salary = client:getDarkRPVar("salary");
	  role = client:getDarkRPVar("job");
	  rpname = client:getDarkRPVar("rpname");
	end

  -- Draw the progress bars for health, armour, gasmask integrity, etc

  -- Health Bar
  DrawProgressBarTextWithLabel(statbox_x + 10, statbox_y + 75, statbox_w - 20, 20, colours.health_bar, math.Clamp(hp / 100, 0, 1), "Health", Color(255, 255, 255, 255), hp .. "/100");

  -- Armour Bar
  DrawProgressBarTextWithLabel(statbox_x + 10, statbox_y + 100, statbox_w - 20, 20, colours.armour_bar, math.Clamp(armour / 100, 0, 1), "Armour", Color(255, 255, 255, 255), armour .. "/100");

  if (LocalPlayer():IsValid() and LocalPlayer():GetNWBool("PlayerHasGasmask") == true) then
    -- Gasmask Bar
    DrawProgressBarTextWithLabel(statbox_x + 10, statbox_y + 125, statbox_w - 20, 20, colours.gasmask_bar, math.Clamp(LocalPlayer():GetNWInt("PlayerGasmaskStrength") / LocalPlayer():GetNWInt("PlayerGasmaskMaxStrength"), 0, 1), "Gasmask", Color(255, 255, 255, 255), LocalPlayer():GetNWInt("PlayerGasmaskStrength") .. "/" .. LocalPlayer():GetNWInt("PlayerGasmaskMaxStrength"));
  end

  -- Draw labels for wallet, bank account, and job.
  surface.SetTextColor(255, 255, 255, 255);

  surface.SetFont("SSHL2RP_DermaAlmostLarge");

  surface.SetTextPos(statbox_x + 10, statbox_y + 10);
  surface.DrawText("Wallet: £" .. funds);

  if (ARCBank ~= nil) then
    --local bank_bal = ARCBank.Accounts

    surface.SetTextPos(statbox_x + 10, statbox_y + 40);
    surface.DrawText("Bank: £0");
    local bank_tw, bank_th = surface.GetTextSize("Bank: £0");

    surface.SetTextPos(bank_tw + 37, statbox_y + 40);
    surface.DrawText("+£" .. salary);

    surface.SetTextPos(bank_tw + 50, statbox_y + 51);
    surface.DrawText("/hr");
  end

  local rpname_tw, rpname_th = surface.GetTextSize(rpname);
  surface.SetTextPos(statbox_w - 50 - rpname_tw, statbox_y + 10);
  surface.DrawText(rpname);

  surface.SetFont("SSHL2RP_DermaSubtitle");

  local role_tw, role_th = surface.GetTextSize(role);
  surface.SetTextPos(statbox_w - 50 - role_tw, statbox_y + 40);
  surface.DrawText(role);

  surface.SetFont("SSHL2RP_DermaMedium");

  -- Draw the player Steam profile image or character model image.

  if (RegisteredVGUI["avatar_image"] == nil) then
    --PlayerImage = vgui.Create("AvatarImage");
    --PlayerImage:SetPos(statbox_w - 45, statbox_y + 10);
    --PlayerImage:SetSize(60, 60);
    --PlayerImage:SetPlayer(LocalPlayer(), 60);
    --PlayerImage:SetPaintBorderEnabled(true);

    PlayerImage = vgui.Create("DModelPanel", EntSlide);
    PlayerImage:SetPos(statbox_w - 45, statbox_y + 10);
    PlayerImage:SetSize(60, 60);
    PlayerImage:SetLookAt(Vector(0, 0, 0));
    PlayerImage:SetModel(LocalPlayer():GetModel());

    //local bound_min, bound_max = PlayerImage.Entity:GetRenderBounds();
    //local bounds = 0;

    //local bounds = math.max(bounds, math.abs(bound_min.x) + math.abs(bound_max.x));
    //local bounds = math.max(bounds, math.abs(bound_min.y) + math.abs(bound_max.y));
    //local bounds = math.max(bounds, math.abs(bound_min.z) + math.abs(bound_max.z));

    local lookpos = PlayerImage.Entity:GetBonePosition(PlayerImage.Entity:LookupBone("ValveBiped.Bip01_Head1"));

    PlayerImage:SetLookAt(lookpos);
    PlayerImage:SetCamPos(lookpos - Vector(-16, 0, 0));
    PlayerImage.Entity:SetEyeTarget(lookpos - Vector(-12, 0, 0));
    PlayerImage:SetAnimated(false);
    function PlayerImage:LayoutEntity(ent) end
    PlayerImage:ParentToHUD();
    DrawVGUI("avatar_image", PlayerImage);
  end

  -- Draw player special effects

  -- Player has a warrant / arrest out for them from Civil Protection

  if (client:getDarkRPVar("wanted") == true) then
    surface.SetTextPos(statbox_x + 10, statbox_y - 20);
    surface.SetTextColor(Color(255, 0, 0, pulse_opacity));
    surface.DrawText("YOU ARE UNDER CIVIL AUTHORITY ARREST");
  end

  local se_height_offset = 20;

  -- Player has Union ID Card
  if (LocalPlayer():GetNWBool("HasUnionIDCard") == true) then
    surface.SetTextPos(statbox_w + 64, statbox_y + se_height_offset);
    surface.SetTextColor(Color(255, 255, 255, 255));

    surface.DrawText("Union CID Card")

    DrawIcon(statbox_w + 45, statbox_y + se_height_offset, "icon16/vcard.png", "union_idcard");

    se_height_offset = se_height_offset + 18;
  else
    DestroyVGUI("union_idcard");
  end

  -- Player has Weapon License

  if (client:getDarkRPVar("HasGunlicense") == true) then
    surface.SetTextPos(statbox_w + 64, statbox_y + se_height_offset);
    surface.SetTextColor(Color(255, 255, 255, 255));

    surface.DrawText("Weapon License")

    DrawIcon(statbox_w + 45, statbox_y + se_height_offset, "icon16/key.png", "weapon_license");

    se_height_offset = se_height_offset + 18;
  else
    DestroyVGUI("weapon_license");
  end

  se_height_offset = se_height_offset + 2;

  -- No need to draw the status box outline if there are no status effects
  if (se_height_offset ~= 22) then
    -- Draw box for permissions
    local sef_tw, sef_th = surface.GetTextSize("Privileges");
    surface.SetTextPos(statbox_w + 10 + (sef_tw / 2), statbox_y + 3);
    surface.SetTextColor(Color(255, 255, 255, 255));
    surface.DrawText("Status Effects")

    surface.SetDrawColor(Color(78, 78, 78));
    surface.DrawOutlinedRect(statbox_w + 40, statbox_y, ScrW() * (125 / 1920), ScrH() * (se_height_offset / 1080));
    surface.SetDrawColor(Color(100, 100, 100, 20));
    surface.DrawRect(statbox_w + 40, statbox_y, ScrW() * (125 / 1920), ScrH() * (se_height_offset / 1080));
  end
end

-- Draws the HUD elements for the Air Exchange "time to start" timer.
local function DrawAirexElements()
  if (drawAirexBar == true) then
    local w = 0.25 * ScrW();
    local h = 0.25 * ScrH();

    local pb_width = w;
    local pb_height = 20;

    local pb_locx = (ScrW() / 2) - (w / 2);
    local pb_locy = 25;

    -- Draw the progress bar at x=30, y=30
    DrawProgressBar(pb_locx, pb_locy, pb_width, pb_height, colours.aw_bar, airexProgressVal);

    -- Draw the text bar at the progress bar's origin (pb_locx) in the middle of the progress bar (pb_width / 16)
    DrawTextConstraint("Alert: The Air Exchange is now starting. Move to a safe location immediately.", pb_locx + (pb_width / 16), pb_locy - 20, Color(255, 0, 0, pulse_opacity));
  end
end

-- Draws the HUD elements for the CCA "ticker" display.
-- Whether to show the ticker or not should be a configurable option.
local function DrawTickerElements()
  local tickerbox_x = 25;
  local tickerbox_y = 25;

  local tickerbox_w = ScrW() * (300 / 1920);
  local tickerbox_h = ScrH() * (600 / 1080);

  -- Draw outer box
  DrawOutlinedBox(tickerbox_x, tickerbox_y, tickerbox_w, tickerbox_h, Color(78, 78, 78), Color(100, 100, 100, 20));

  DrawTextCustom("COMBINE CIVIL AUTHORITY", tickerbox_x + 5, tickerbox_y, Color(100, 100, 100, 120), tickerFonts.medium);

  -- Draw inner box
  surface.DrawOutlinedRect(tickerbox_x + 10, tickerbox_y + 30, tickerbox_w - 20, tickerbox_h - 40, Color(78, 78, 78));

  -- Draw custom combine claw texture
  surface.SetMaterial(tickerSymbols.combine);
  surface.SetDrawColor(Color(100, 100, 100, 20));
  surface.DrawTexturedRect((tickerbox_x + (tickerbox_w / 2)) - 150, (tickerbox_y + (tickerbox_h / 2)) - 150, 300, 300);
end

-- Starts the Air Exchange "time to start" timer.
function BeginStartAirexTimer()
  drawAirexBar = true;

  airexProgress = 0;
  airexProgressVal = 0;

  if (timer.Exists("AirExchangeTickTimer")) then
    timer.Destroy("AirExchangeTickTimer");
  end

  if (timer.Exists("AirExchangeFinishTimer")) then
    timer.Destroy("AirExchangeFinishTimer");
  end

  timer.Create("AirExchangeTickTimer", 0.6, 100, function()
    airexProgress = airexProgress + 1;
    airexProgressVal = math.Clamp(airexProgress / 100, 0, 1);
  end);
end

-- Main function to paint the HUD.
local function HUDPaint()
  client = client or LocalPlayer();
  if (!client:Alive()) then return; end

  -- Do a simple fade of any GUI elements that need to be faded.
  local fadespeed = 5;

  if (pulse_opacity_inc == true) then
    pulse_opacity = pulse_opacity + fadespeed;
    if (pulse_opacity >= 255) then
      pulse_opacity = pulse_opacity - fadespeed;
      pulse_opacity_inc = false;
    end
  else
    pulse_opacity = pulse_opacity - fadespeed;
    if (pulse_opacity <= 0) then
      pulse_opacity = pulse_opacity + fadespeed;
      pulse_opacity_inc = true;
    end
  end

  DrawStatusElements();
  DrawAirexElements();
  DrawTickerElements();

  --RenderScrollerText();
end

hook.Add("HUDPaint", "PaintAirexHud", HUDPaint);

hook.Add("Think", "AirexHudDataThink", function()
  if (LocalPlayer():IsValid() and LocalPlayer():GetNWBool("StartAWTimerNow") == true) then
    if (airexStarted == false) then
      airexStarted = true;

      BeginStartAirexTimer();
    end
  elseif (LocalPlayer():IsValid() and LocalPlayer():GetNWBool("EndAWStatusNow") == true) then
    if (airexStarted == true) then
      airexStarted = false;
      airexProgress = 0;
      airexProgressVal = 0;

      drawAirexBar = false;

      if (timer.Exists("AirExchangeTickTimer")) then
        timer.Destroy("AirExchangeTickTimer");
      end

      if (timer.Exists("AirExchangeFinishTimer")) then
        timer.Destroy("AirExchangeFinishTimer");
      end
    end
  end
end);

hook.Add("OnPlayerChangedTeam", "AirexHudJobGC", function()
  DestroyVGUI("avatar_image");
end);

hook.Add("RenderScreenspaceEffects", "AirexHudDeathGC", function()
  if (!LocalPlayer():Alive()) then
    for k, v in pairs(RegisteredVGUI) do
      DestroyVGUI(k);
    end
  end
end);

concommand.Add("refresh_clhudvgui", function(ply, cmd, args, argStr)
  for k, v in pairs(RegisteredVGUI) do
    DestroyVGUI(k);
  end
 end, nil, "Refreshes the VGUI elements of the HL2RP HUD.");

 timer.Create("TextBlinkerTime
 end);
