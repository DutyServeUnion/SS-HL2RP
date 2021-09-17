include("shared.lua");

include("../../../gamemode/scripted/airex/sv_airex.lua");

function ENT:Initialize()
  print("[DMIControl] DMI controller entity is loading.");
end

function ENT:KeyValue(k, v)
  self:StoreOutput(k, v);
end

function ENT:AcceptInput(inputName, activator, called)
  if (inputName == "AirexStartRequested") then
    airex_Activate();
  elseif (inputName == "AirexStopRequested") then
    airex_Deactivate();
  //elseif (inputName == "AirexStartFinished") then
    //airex_ActivationFinished();
  //elseif (inputName == "AirexStopFinished") then
    //airex_DeactivationFinished();
  end
end
