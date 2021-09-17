mapIsOfficial = false;

function dmiLoadMap(mapName)
  for k, dmi_controller in pairs(ents.FindByClass("dmi_controller")) do
    print("[DMIControl] Loaded controller entity with targetname " .. dmi_controller:GetName() .. ".");
    controller_vars = dmi_controller:GetKeyValues();
    controller_flags = dmi_controller:GetSpawnFlags();

    --if (controller_vars["icl"] == "1.0") then
      if (dmi_controller:HasSpawnFlags(32)) then
        mapIsOfficial = true;
        print("[DMIControl] Map identified as official TOWER map.");
        return true;
      else
        print("[DMIControl] Map identified as a non-TOWER map.");
        return true;
      end
    --else
      --print("[DMIControl] Error loading map controller: Unsupported version");
    --end
  end
end
