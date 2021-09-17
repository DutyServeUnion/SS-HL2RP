correctionFadingRed = false;
correctionFadingBlue = false;
correctionTab = {
  ["$pp_colour_addr"] = 0,
  ["$pp_colour_addg"] = 0,
  ["$pp_colour_addb"] = 255,
  ["$pp_colour_brightness"] = 0,
  ["$pp_colour_contrast"] = 1,
  ["$pp_colour_colour"] = 1,
  ["$pp_colour_mulr"] = 1,
  ["$pp_colour_mulg"] = 1,
  ["$pp_colour_mulb"] = 1,
}

hook.Add("PreDrawHalos", "DrawSelectionOutline", function()
  local line = util.TraceLine(util.GetPlayerTrace(LocalPlayer()));
  for k, ent in pairs(ents.FindByClass("func_door")) do
    if (ent == line.Entity and LocalPlayer():GetNWBool("InsideResistanceTrigger") == true) then
      halo.Add({ent}, Color(255, 255, 255));
    end
  end
end);

hook.Add("Think", "AirexCorrectionThink", function()
  if (LocalPlayer():IsValid() and LocalPlayer():GetNWBool("ShouldFadeCorrectionIn") == true) then
    airex_fadeCorrectionIn();
  elseif (LocalPlayer():IsValid() and LocalPlayer():GetNWBool("ShouldFadeCorrectionOut") == true) then
    airex_fadeCorrectionOut();
  end
);

function airex_fadeCorrectionIn()
  if (correctionFadingRed == false) then
    correctionFadingRed = true;
    correctionFadingBlue = false;

    correctionTab = {
      ["$pp_colour_addr"] = 0,
      ["$pp_colour_addg"] = 0,
      ["$pp_colour_addb"] = 255,
      ["$pp_colour_brightness"] = 0,
      ["$pp_colour_contrast"] = 1,
      ["$pp_colour_colour"] = 1,
      ["$pp_colour_mulr"] = 1,
      ["$pp_colour_mulg"] = 1,
      ["$pp_colour_mulb"] = 1,
    }
  end
end

function airex_fadeCorrectionOut()
  if (correctionFadingBlue == false) then
    correctionFadingRed = false;
    correctionFadingBlue = true;

    correctionTab = {
      ["$pp_colour_addr"] = 255,
      ["$pp_colour_addg"] = 0,
      ["$pp_colour_addb"] = 0,
      ["$pp_colour_brightness"] = 0,
      ["$pp_colour_contrast"] = 1,
      ["$pp_colour_colour"] = 1,
      ["$pp_colour_mulr"] = 1,
      ["$pp_colour_mulg"] = 1,
      ["$pp_colour_mulb"] = 1,
    }
  end
end

--hook.Add("RenderScreenspaceEffects", "AirexCorrectionEffects", function()
  --if (correctionFadingRed == true) then
  --  if (correctionTab["$pp_colour_addr"] => 255) then
    --  correctionTab["$pp_colour_addr"] = 255;
    --  correctionTab["$pp_colour_addb"] = 0;
  --  else
  --    correctionTab["$pp_colour_addr"] = correctionTab["$pp_colour_addr"] + 1;
  --    correctionTab["$pp_colour_addb"] = correctionTab["$pp_colour_addb"] - 1;
--    end
--  elseif (correctionFadingBlue == true) then
--    if (correctionTab["$pp_colour_addb"] => 255) then
  --    correctionTab["$pp_colour_addr"] = 0;
  --    correctionTab["$pp_colour_addb"] = 255;
  --  else
  --    correctionTab["$pp_colour_addb"] = correctionTab["$pp_colour_addb"] + 1;
  --    correctionTab["$pp_colour_addb"] = correctionTab["$pp_colour_addb"] - 1;
  --  end
  --end

  --DrawColorModify(correctionTab);
--end)
