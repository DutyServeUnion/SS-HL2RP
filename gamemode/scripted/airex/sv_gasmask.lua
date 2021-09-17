-- Table containing gasmask holder Steam IDs.
gasmaskHolders = gasmaskHolders or {};

-- Table containing gasmask hitpoints and Steam IDs.
gasmaskHitpoints = gasmaskHitpoints or {};

-- Table containing Steam IDs of players who are currently wearing a gasmask.
gasmaskWearers = gasmaskWearers or {};

function airex_putOnGasmask(ply)
  if (gasmaskHolders[ply:SteamID()] ~= nil and gasmaskWearers[ply:SteamID()] == nil) then
    gasmaskWearers[ply:SteamID()] = true;

    if (timer.Exists(ply:SteamID() .. " Base")) then
      timer.Remove(ply:SteamID() .. " Base");
      timer.Create(ply:SteamID() .. " Base", 3, 0, function() airex_TakeDamage(ply) end);
    end

    if (timer.Exists(ply:SteamID() .. " Multiplier")) then
      timer.Remove(ply:SteamID() .. " Multiplier");
      timer.Create(ply:SteamID() .. " Multiplier", 12, 0, function() airex_IncreaseDamage(ply) end);
    end

  end
end

function airex_takeOffGasmask(ply)
  if (gasmaskHolders[ply:SteamID()] ~= nil and gasmaskWearers[ply:SteamID()] ~= nil) then
    gasmaskWearers[ply:SteamID()] = nil;

    if (timer.Exists(ply:SteamID() .. " Base")) then
      timer.Remove(ply:SteamID() .. " Base");
      timer.Create(ply:SteamID() .. " Base", 2, 0, function() airex_TakeDamage(ply) end);
    end

    if (timer.Exists(ply:SteamID() .. " Multiplier")) then
      timer.Remove(ply:SteamID() .. " Multiplier");
      timer.Create(ply:SteamID() .. " Multiplier", 5, 0, function() airex_IncreaseDamage(ply) end);
    end

  end
end

function airex_breakGasmask(ply)
  gasmaskHolders[ply:SteamID()] = nil;
  gasmaskHitpoints[ply:SteamID()] = nil;
  gasmaskWearers[ply:SteamID()] = nil;

  ply:SetNWBool("PlayerHasGasmask", false);
end

function airex_addGasmask(ply, hitpoints)
  if (gasmaskHolders[ply:SteamID()] == nil) then

    gasmaskHolders[ply:SteamID()] = true;

    gasmaskHitpoints[ply:SteamID()] = hitpoints;
  end

  ply:SetNWInt("PlayerGasmaskMaxStrength", hitpoints);
  ply:SetNWInt("PlayerGasmaskStrength", gasmaskHitpoints[ply:SteamID()]);
  ply:SetNWBool("PlayerHasGasmask", true);
end

hook.Add("OnPlayerChangedTeam", "MaskCombineGive", function(ply)
  if (ply:getDarkRPVar("job") ~= nil) then
    airex_breakGasmask(ply);

    if (ply:getDarkRPVar("job") == "Civil Protection") then
      airex_addGasmask(ply, 30);
    elseif (ply:getDarkRPVar("job") == "Civil Protection Officer") then
      airex_addGasmask(ply, 50);
    elseif (ply:getDarkRPVar("job") == "Elite Protection Unit" or ply:getDarkRPVar("job") == "Sniper Unit" or ply:getDarkRPVar("job") == "Medic Unit") then
      airex_addGasmask(ply, 70);
    elseif (ply:getDarkRPVar("job") == "Squad Leader") then
      airex_addGasmask(ply, 80);
    elseif (ply:getDarkRPVar("job") == "Division Leader") then
      airex_addGasmask(ply, 100);
    elseif (ply:getDarkRPVar("job") == "Sector Commander") then
      airex_addGasmask(ply, 120);
    elseif (ply:getDarkRPVar("job") == "Union Officer") then
      airex_addGasmask(ply, 130);
    elseif (ply:getDarkRPVar("job") == "City Administrator") then
      airex_addGasmask(ply, 140);
    elseif (ply:getDarkRPVar("job") == "Combine Sentinel Unit") then
      airex_addGasmask(ply, 150);
    end
  end
end);

hook.Add("PlayerDeath", "GasmaskDeath", function(ply)
  if (gasmaskWearers[ply:SteamID()] == true) then
    airex_breakGasmask(ply);
    ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] You lost your gasmask because you died.");
  end
end);

hook.Add("PlayerSpawn", "GasmaskPlayerSpawnHook", function(ply)
  airex_takeOffGasmask(ply);
end);

hook.Add("PlayerDisconnected", "GasmaskPlayerDisconnectHook", function(ply)
  airex_takeOffGasmask(ply);
end);

hook.Add("PlayerSay", "GasmaskOn", function(ply, cmd)
  if (cmd == "/maskon") then
    if (gasmaskHolders[ply:SteamID()] ~= nil) then
      if (airexActive == true or airexActivating == true) then
        airex_putOnGasmask(ply);
        ply:EmitSound("items/battery_pickup.wav");
        ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] You put on your anti-rad gasmask.");
      else
        ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] There's no need to put on your gasmask, there is no radiation hazard.");
      end
    else
      ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] You don't have a gas mask to put on!");
    end
  end
end);

hook.Add("PlayerSay", "GasmaskOff", function(ply, cmd)
  if (cmd == "/maskoff") then
    if (gasmaskWearers[ply:SteamID()] ~= nil) then
      airex_takeOffGasmask(ply);
      ply:EmitSound("items/suitchargeno1.wav");
      ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] You took off your anti-rad gasmask.");
    else
      ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] You're not wearing a gas mask.");
    end
  end
end);

hook.Add("PlayerSay", "GasmaskDrop", function(ply, cmd)
  if (cmd == "/maskdrop") then
    if (gasmaskHolders[ply:SteamID()] ~= nil) then
      local gasmask = ents.Create("prop_gasmask");
      if (IsValid(gasmask)) then
        airex_takeOffGasmask(ply);
        airex_breakGasmask(ply);
        ply:EmitSound("items/suitchargeno1.wav");

        if (ply:getDarkRPVar("job") ~= nil) then
          if (ply:getDarkRPVar("job") == "Civil Protection") then
            gasmask.MaskType = "metrocop";
          elseif (ply:getDarkRPVar("job") == "Civil Protection Officer") then
            gasmask.MaskType = "officer";
          elseif (ply:getDarkRPVar("job") == "Elite Protection Unit" or ply:getDarkRPVar("job") == "Sniper Unit" or ply:getDarkRPVar("job") == "Medic Unit") then
            gasmask.MaskType = "elite";
          elseif (ply:getDarkRPVar("job") == "Squad Leader") then
            gasmask.MaskType = "squadleader";
          elseif (ply:getDarkRPVar("job") == "Division Leader") then
            gasmask.MaskType = "divisionleader";
          elseif (ply:getDarkRPVar("job") == "Sector Commander") then
            gasmask.MaskType = "seccommand";
          elseif (ply:getDarkRPVar("job") == "Union Officer") then
            gasmask.MaskType = "cmbofficer";
          elseif (ply:getDarkRPVar("job") == "City Administrator") then
            gasmask.MaskType = "cityadmin";
          elseif (ply:getDarkRPVar("job") == "Combine Sentinel Unit") then
            gasmask.MaskType = "sentinel";
          else
            gasmask.MaskType = "basic";
          end
        end

        gasmask:SetPos(ply:GetEyeTrace().HitPos);
        gasmask:Spawn();
        ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] You dropped your gas mask.");
      else
        ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] Couldn't drop your gasmask!");
      end
    else
      ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] You don't have a gas mask to drop!");
    end
  end
end);

hook.Add("PlayerSay", "GasmaskAdd", function(ply, cmd)
  if (string.sub(cmd, 1, 8) == "/maskadd") then
    if (ply:IsAdmin()) then
      if (gasmaskHolders[ply:SteamID()] == nil) then
        airex_addGasmask(ply, 150);
        ply:EmitSound("items/suitchargeok1.wav");
        ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] Gave a gas mask to yourself.");
      else
        ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] You already have a gas mask.");
      end
    else
      ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] You must be an administrator to use this command.");
    end
  end
end);
