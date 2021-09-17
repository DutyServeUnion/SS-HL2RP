include("shared.lua");

include("../../../gamemode/dmi/control/loader.lua");
include("../../../gamemode/scripted/airex/sv_airex.lua");
include("../../../gamemode/scripted/airex/sv_gasmask.lua");

function ENT:Initialize()
  self:SetTrigger(true);
  self:SetNotSolid(true);
end

function ENT:Touch(ply)
  if (ply:IsValid() and ply:IsPlayer()) then
    if (airexActive == true and temporaryImmunity[ply:SteamID()] == nil) then
      if (ply:IsValid() and ply:IsPlayer()) then
        for k, ply in pairs(player:GetAll()) do

          local kv = self.ZoneType;
          if (kv == "0") then
            local multiplier = 1;

            if (self.UseCC == "1") then
              airex_sendFadeCorrectionIn(ply);
            end

            airex_StartTakingDamage(ply, multiplier);
          elseif (kv == "1") then
            local multiplier = 0;
          elseif (kv == "2") then
            local multiplier = 0.8;

            if (self.UseCC == "1") then
              airex_sendFadeCorrectionIn(ply);
            end

            airex_StartTakingDamage(ply, multiplier);
          elseif (kv == "3") then
            if (resistanceBaseBreached == true) then
              local multiplier = 0.8;
            else
              local multiplier = 0.3;
            end

            if (self.UseCC == "1") then
              airex_sendFadeCorrectionIn(ply);
            end

            airex_StartTakingDamage(ply, multiplier);
          elseif (kv == "4") then

            if (resistanceBaseBreached == true) then
              local multiplier = 0.8;
              airex_StartTakingDamage(ply, multiplier);
            end

            airex_sendFadeCorrectionIn(ply);
          end
        end
      end
    elseif (self.ZoneType == "4" or self.ZoneType == "3") then
      ply:SetNWBool("InsideResistanceTrigger", true);
    end
  end
end

function ENT:KeyValue(key, value)
  if (key == "zonetype") then
    self.ZoneType = value;
  elseif (key == "usecc") then
    self.UseCC = value;
  end
end

function ENT:EndTouch(ply)
  if (ply:IsValid() and ply:IsPlayer()) then
    for k, player in pairs(player:GetAll()) do
      if (self.UseCC == "1") then
        local kv = self.ZoneType;
        if (kv == "1") then
          airex_sendFadeCorrectionOut(ply);
        elseif (kv == "4") then
          airex_sendFadeCorrectionOut(ply);
        end
      end
      airex_StopTakingDamage(player);
    end
  end
end
