AddCSLuaFile("cl_airex.lua");

airexActive = false;
airexActivating = false;
airexDeactivating = false;

resistanceBaseBreached = false;

temporaryImmunity = temporaryImmunity or {};

local damageMultipliers = {};
local randomSfx = {"player/geiger1.wav", "player/geiger2.wav", "player/geiger3.wav"};

local function EntityFire(entity, input, delay)
  if (delay == nil) then delay = 0 end

  for k, entity in pairs(ents.FindByName(entity)) do
    entity:Fire(input, nil, delay);
  end
end

local function EntityFireParam(entity, input, param, delay)
  if (delay == nil) then delay = 0 end

  for k, entity in pairs(ents.FindByName(entity)) do
    entity:Fire(input, param, delay);
  end
end

local function CloseAllDoors()
  EntityFire("door1a", "Close");
  EntityFire("door2a", "Close");
  EntityFire("door3a", "Close");
  EntityFire("door4a", "Close");
  EntityFire("door5a", "Close");
  EntityFire("door1b", "Close");
  EntityFire("door2b", "Close");
  EntityFire("door3b", "Close");
  EntityFire("door4b", "Close");
  EntityFire("door5b", "Close");
  EntityFire("checkpointlowerdoor", "Close");
  EntityFire("checkpointlowerdoor2", "Close");
  EntityFire("checkpointdoor2", "Close");
  EntityFire("checkpointdoor3", "Close");
  EntityFire("checkpointdoor4", "Close");
  EntityFire("nd", "Close");
  EntityFire("nexusminidoor", "Close");
  EntityFire("nexusminidoor", "Lock");
end

local function OpenAllDoors()
  EntityFire("door1a", "Open");
  EntityFire("door2a", "Open");
  EntityFire("door3a", "Open");
  EntityFire("door4a", "Open");
  EntityFire("door5a", "Open");
  EntityFire("door1b", "Open");
  EntityFire("door2b", "Open");
  EntityFire("door3b", "Open");
  EntityFire("door4b", "Open");
  EntityFire("door5b", "Open");
  EntityFire("checkpointlowerdoor", "Open");
  EntityFire("checkpointlowerdoor2", "Open");
  EntityFire("checkpointdoor2", "Open");
  EntityFire("checkpointdoor3", "Open");
  EntityFire("checkpointdoor4", "Open");
  EntityFire("nd", "Open");
  EntityFire("nexusminidoor", "Open");
  EntityFire("nexusminidoor", "Unlock");
end

local function AnimateCitadelOpen()
  EntityFireParam("citadel", "SetAnimation", "open");
  EntityFire("citadel-clunk", "PlaySound");
  EntityFire("shake", "StartShake");
  EntityFire("citadel-jw", "PlaySound", 7);
  EntityFire("shake", "StartShake", 10);
  EntityFire("steam1", "TurnOn", 11);
  EntityFire("steam1", "TurnOff", 13);
  EntityFire("steam2", "TurnOn", 14);
  EntityFire("steam2", "TurnOff", 15);
  EntityFire("shake", "StartShake", 20);
  EntityFire("steam2", "TurnOn", 20);
  EntityFire("steam2", "TurnOff", 22);
end

local function AnimateCitadelClose()
  EntityFireParam("citadel", "SetAnimation", "idle");
  EntityFire("citadel-jw", "StopSound");
  EntityFire("citadel-jwoff", "PlaySound");
end

function airex_Activate()
  if (!airexActivating && !airexDeactivating && !airexActive) then
    airexActivating = true;
    airexDeactivating = false;

    resistanceBaseBreached = false;

    for k, player in pairs(player:GetAll()) do
      player:SetNWBool("StartAWTimerNow", true);
    end

    AnimateCitadelOpen();
    CloseAllDoors();

    EntityFireParam("JWButton", "SetAnimation", "Press");
    EntityFireParam("console", "SetAnimation", "alert2");
    EntityFire("autonwaiver_button", "Lock");
    EntityFire("autonomous_waiver_sound", "PlaySound", 5);
    EntityFire("resistance_base_lockdown_relay", "Trigger", 7);
    EntityFire("resistance_base_airexalert_relay", "Trigger", 50);
    EntityFire("autonwaiver_cancel_button", "Unlock", 60);

    timer.Create("Airex_ActivationTimer", 60, 1, function() airex_ActivationFinished() end);
  end
end

function airex_Deactivate()
  if (!airexActivating && !airexDeactivating && airexActive) then
    airexActivating = false;
    airexDeactivating = true;
    airexActive = false;

    for k, player in pairs(player:GetAll()) do
      player:SetNWBool("EndAWStatusNow", true);
      airex_StopTakingDamage(player);
    end

    AnimateCitadelClose();

    EntityFire("airex_mapcorrect", "Disable");
    EntityFire("airex_mapsfx", "StopSound");
    EntityFire("airex_smokestack", "TurnOff");
    EntityFire("airex_skybox_sprites_on", "HideSprite");
    EntityFire("airex_skybox_sprites_off", "ShowSprite");

    timer.Create("Airex_DeactivationTimer", 10, 1, function() airex_DeactivationFinished() end);
  end
end

function airex_ActivationFinished()
  airexActivating = false;
  airexActive = true;

  EntityFire("airex_mapcorrect", "Enable");
  EntityFire("airex_mapsfx", "PlaySound");
  EntityFire("airex_smokestack", "TurnOn");
  EntityFire("airex_skybox_sprites_on", "ShowSprite");
  EntityFire("airex_skybox_sprites_off", "HideSprite");

  for k, player in pairs(player:GetAll()) do
    player:SetNWBool("StartAWTimerNow", false);
  end
end

function airex_DeactivationFinished()
  airexActivating = false;
  airexDeactivating = false;
  airexActive = false;

  resistanceBaseBreached = false;

  for k, player in pairs(player:GetAll()) do
    player:SetNWBool("EndAWStatusNow", false);
    airex_takeOffGasmask(player);
  end

  OpenAllDoors();

  EntityFireParam("console", "SetAnimation", "idle");
  EntityFire("resistance_base_airexunalert_relay", "Trigger");
  EntityFire("autonwaiver_button", "Unlock");
  EntityFire("autonwaiver_cancel_button", "Lock");
  EntityFire("resistance_base_unlockdown_relay", "Trigger");
end

function airex_TakeDamage(ply, multiplier)
  if (ply:IsValid()) then
    if (gasmaskWearers[ply:SteamID()] == true) then
      if (gasmaskHitpoints[ply:SteamID()] > 0) then
        if (multiplier ~= nil) then
          local dinfo = DamageInfo();
          dinfo:SetDamage(1 * multiplier * (math.random(8, 10) / 10) * (10 - (gasmaskHitpoints[ply:SteamID()]) / 2.2));
          dinfo:SetDamageType(DMG_RADIATION);
          ply:TakeDamageInfo(dinfo);
        else
          local dinfo = DamageInfo();
          dinfo:SetDamage(1 * (math.random(8, 10) / 10) * (10 - (gasmaskHitpoints[ply:SteamID()]) / 2.2));
          dinfo:SetDamageType(DMG_RADIATION);
          ply:TakeDamageInfo(dinfo);
        end

        if (math.random(1, 2) == 1) then
          gasmaskHitpoints[ply:SteamID()] = gasmaskHitpoints[ply:SteamID()] - 1;
          ply:SetNWInt("PlayerGasmaskStrength", gasmaskHitpoints[ply:SteamID()]);
          --ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] Your gasmask has taken damage! Remaining strength: " .. gasmaskHitpoints[ply:SteamID()] .. ".");
        end
      else
        airex_breakGasmask(ply);
        ply:EmitSound("items/suitchargeno1.wav");
        ply:PrintMessage(HUD_PRINTTALK, "[Gasmask] Your gasmask has broken and is rendered useless!");
      end
    else
      if (multiplier ~= nil) then
        local dinfo = DamageInfo();
        dinfo:SetDamage(5 * multiplier * (math.random(8, 10) / 10) * damageMultipliers[ply:SteamID()]);
        dinfo:SetDamageType(DMG_RADIATION);
        ply:TakeDamageInfo(dinfo);
      else
        local dinfo = DamageInfo();
        dinfo:SetDamage(5 * (math.random(8, 10) / 10) * damageMultipliers[ply:SteamID()]);
        dinfo:SetDamageType(DMG_RADIATION);
        ply:TakeDamageInfo(dinfo);
      end
    end
    ply:EmitSound(randomSfx[math.random(1, 3)]);
  end

end

function airex_IncreaseDamage(ply)
  for k, v in pairs(damageMultipliers) do
    if (gasmaskWearers[ply:SteamID()] == nil and damageMultipliers[ply:SteamID()] < 10) then
      damageMultipliers[ply:SteamID()] = v * 2;
    end
  end
end

function airex_StartTakingDamage(ply, multiplier)
  if (ply:IsValid()) then
    if (timer.Exists(ply:SteamID() .. " Base") != true) then
      if (gasmaskWearers[ply:SteamID()] ~= nil) then
        damageMultipliers[ply:SteamID()] = 0.5;
        timer.Create(ply:SteamID() .. " Base", 3, 0, function() airex_TakeDamage(ply, multiplier) end);
        timer.Create(ply:SteamID() .. " Multiplier", 12, 0, function() airex_IncreaseDamage(ply) end);
      else
        damageMultipliers[ply:SteamID()] = 1;
        timer.Create(ply:SteamID() .. " Base", 2, 0, function() airex_TakeDamage(ply, multiplier) end);
        timer.Create(ply:SteamID() .. " Multiplier", 5, 0, function() airex_IncreaseDamage(ply) end);
      end
    end
  end
end

function airex_StopTakingDamage(ply)
  if (ply:IsValid()) then
    if (timer.Exists(ply:SteamID() .. " Base")) then
      damageMultipliers[ply:SteamID()] = nil;
      timer.Remove(ply:SteamID() .. " Base");
      timer.Remove(ply:SteamID() .. " Multiplier");
    end
  end
end

function airex_sendFadeCorrectionIn(ply)
  ply:SetNWBool("ShouldFadeCorrectionIn", true);
end

function airex_sendFadeCorrectionOut(ply)
  ply:SetNWBool("ShouldFadeCorrectionOut", true);
end

hook.Add("PlayerDeath", "AirexDeath", function(ply)
  airex_StopTakingDamage(ply);
  temporaryImmunity[ply:SteamID()] = true;

  if (timer.Exists(ply:SteamID() .. " TemporaryImmunity") ~= true) then
    timer.Create(ply:SteamID() .. " TemporaryImmunity", 1, 1, function() temporaryImmunity[ply:SteamID()] = nil; end);
  else
    timer.Remove(ply:SteamID() .. " TemporaryImmunity");
    timer.Create(ply:SteamID() .. " TemporaryImmunity", 1, 1, function() temporaryImmunity[ply:SteamID()] = nil; end);
  end
end);

hook.Add("PlayerSay", "StartJudgementWaiver", function(ply, cmd)
  if (cmd == "/startjw") then
    if (ply:IsAdmin()) then
      if (airexActivating == true or airexDeactivating == true or airexActive == true) then
        ply:PrintMessage(HUD_PRINTTALK, "[Judgement Waiver] Another administrative mandate is already in effect. Please end that before initiating this action.");
      else
        for k, entity in pairs(ents.FindByClass("dmi_controller")) do
          entity:TriggerOutput("WaiverStartRequested");
        end
      end
    else
      ply:PrintMessage(HUD_PRINTTALK, "[Judgement Waiver] You do not have permission to use this administrative mandate.");
    end
  end
end);

hook.Add("PlayerSay", "StartAutoWaiver", function(ply, cmd)
  if (cmd == "/startaw") then
    if (ply:IsAdmin()) then
      if (airexActivating == true or airexDeactivating == true or airexActive == true) then
        ply:PrintMessage(HUD_PRINTTALK, "[Autonomous Waiver] Cannot start the Autonomous Waiver. Please ensure that the current waiver is completely stopped before starting a new waiver.");
      else
        airex_Activate();
        for k, entity in pairs(ents.FindByClass("dmi_controller")) do
          entity:TriggerOutput("AutonWaiverStartRequested");
        end

        ply:PrintMessage(HUD_PRINTTALK, "[Autonomous Waiver] Starting Autonomous Waiver. Please move to a safe location.");
      end
    else
      ply:PrintMessage(HUD_PRINTTALK, "[Autonomous Waiver] You do not have permission to use this administrative mandate.");
    end
  end
end);

hook.Add("PlayerSay", "EndAutoWaiver", function(ply, cmd)
  if (cmd == "/endaw") then
    if (ply:IsAdmin()) then
      if (airexActivating == true or airexDeactivating == true or airexActivated == false) then
        ply:PrintMessage(HUD_PRINTTALK, "[Autonomous Waiver] Cannot end the Autonomous Waiver. Please ensure that the current waiver is completely started before stopping the current waiver.");
      else
        airex_Deactivate();
        for k, entity in pairs(ents.FindByClass("dmi_controller")) do
          entity:TriggerOutput("AutonWaiverStopRequested");
        end

        ply:PrintMessage(HUD_PRINTTALK, "[Autonomous Waiver] Ending Autonomous Waiver.");
      end
    else
      ply:PrintMessage(HUD_PRINTTALK, "[Autonomous Waiver] You do not have permission to use this administrative mandate.");
    end
  end
end);
