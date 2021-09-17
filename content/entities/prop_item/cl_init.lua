include("shared.lua");
include("../../../gamemode/gui/cl_inventory.lua");

function ENT:Initialize()
  self.Rotation = 0;
  self.LastTime = SysTime();
  self.Hovering = false;

  net.Receive("ItemEntitySetItem", function()
    local rxTable = net.ReadTable();
    self.Item = rxTable["item"];
    self.ItemName = rxTable["itemname"];

    if (self.Item.weapon ~= nil) then
      for k, weapon in pairs(weapons.GetList()) do
        if (weapon.ClassName ~= nil and self.ItemName == weapon.ClassName and self.Item.ispreregistered == true) then
          self.Item.name = weapon.PrintName;
          break;
        end
      end
    end
  end);

  net.Start("ItemEntityGetItem");
  net.SendToServer();
end

local function DrawInContext(pos, ang1, ang2, func)
  cam.Start3D2D(pos + ang1:Up() * 0, ang1, 0.2);
  func();
  cam.End3D2D();

  cam.Start3D2D(pos + ang2:Up() * 0, ang2, 0.2);
  func();
  cam.End3D2D();
end

function ENT:Draw()
  self:DrawModel();

  local line = util.TraceLine(util.GetPlayerTrace(LocalPlayer()));
  for k, ent in pairs(ents.FindByClass("prop_item")) do
    if ent == line.Entity then
      ent.Hovering = true;
    else
      ent.Hovering = false;
    end
  end

  if (self.Item != null && self.Hovering == true) then
    local pos = self:GetPos();
    local offset = Vector(0, 0, 30);
    local ang1 = Angle(0, 0, 90);
    local ang2 = Angle(0, 0, 90);

    local max = self:OBBMaxs() - self:OBBMins();
    local pos = pos + Vector(0, 0, max.z + 10);

    ang1:RotateAroundAxis(ang1:Right(), self.Rotation);
    ang2:RotateAroundAxis(ang2:Right(), self.Rotation + 180);

    DrawInContext(pos, ang1, ang2, function()
      draw.DrawText(self.Item.name, "DermaLarge", 0, -50, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER);
      draw.DrawText("Press E to pick up.", "SSHL2RP_DermaMedium", 0, -20, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER);

      if (self.Item.contrabandLevel == "green") then
        draw.DrawText("Class-A contraband", "SSHL2RP_DermaMedium", 0, 0, Color(255, 215, 70, 255), TEXT_ALIGN_CENTER);
      end

      if (self.Item.contrabandLevel == "yellow") then
        draw.DrawText("Class-B contraband", "SSHL2RP_DermaMedium", 0, 0, Color(216, 210, 26, 255), TEXT_ALIGN_CENTER);
      end

      if (self.Item.contrabandLevel == "red") then
        draw.DrawText("Class-C contraband", "SSHL2RP_DermaMedium", 0, 0, Color(216, 70, 26, 255), TEXT_ALIGN_CENTER);
      end
    end);

    if (self.Rotation > 359) then self.Rotation = 0; end
    self.Rotation = self.Rotation - (100 * (self.LastTime - SysTime()));
    self.LastTime = SysTime();
  end
end

hook.Add("PreDrawHalos", "DrawSelectionOutline", function()
  local line = util.TraceLine(util.GetPlayerTrace(LocalPlayer()));
  for k, ent in pairs(ents.FindByClass("prop_item")) do
    if ent == line.Entity then
      if (ent.Item ~= nil && ent.Item.contrabandLevel ~= nil) then
        if (ent.Item.contrabandLevel == "green") then
          halo.Add({ent}, Color(255, 215, 70));
        elseif (ent.Item.contrabandLevel == "yellow") then
          halo.Add({ent}, Color(216, 210, 26));
        elseif (ent.Item.contrabandLevel == "red") then
          halo.Add({ent}, Color(216, 70, 26));
        end
      else
        halo.Add({ent}, Color(255, 255, 255));
      end
    end
  end
end);
