include("controller.lua");

function dmiLoadController()
  print("[DMIControl] Now starting DMIControl " .. dmiVersion .. ".");
  print("[DMIControl] Checking current map and reading control entities.");
  print("[DMIControl] Loading control entities for map " .. game.GetMap() .. ".");

  -- Attempt to load the current map control entities.
  if dmiLoadMap(game.GetMap()) then
  print("[DMIControl] Loaded control entities successfully.");
  else
  print("[DMIControl] Couldn't load control entities! Halting initialization of DMIControl.");
  end
end
