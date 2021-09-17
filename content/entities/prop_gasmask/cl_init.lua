include("shared.lua");

function ENT:Draw()
  self:DrawModel();
end

hook.Add("PreDrawHalos", "DrawSelectionOutline", function()
  local line = util.TraceLine(util.GetPlayerTrace(LocalPlayer()));
  for k, ent in pairs(ents.FindByClass("prop_gasmask")) do
    if ent == line.Entity then
      halo.Add({ent}, Color(255, 255, 255));
    end
  end
end);
