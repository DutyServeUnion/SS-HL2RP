include("shared.lua");

function ENT:Initialize()
  self.DoorOpen = false;
  self.DistanceLeft = 0;

  self.Lip = 0;
  self.Locked = false;
  self.HasReset = true;

  self.DelayBeforeReset = 0;

  self:SetSolid(SOLID_BBOX);

  local pos = self:GetPos();
  print("Innitialized scripted door entity at " .. pos .. ".")
end

local function SetPosVector(offset)
  local pos = self:GetPos();

  // Add the offset to the vector
  local pos_vec = Vector(offset, 0, 0)

  // Rotate our vector by the movement direction keyvalue
  pos_vec:Rotate(Angle(self.MovementDirection[1], self.MovementDirection[2], self.MovementDirection[3]));

  // Add the new vector to our existing vector
  pos:Add(pos_vec);

  // Set the new entity position
  self:SetPos(pos);
end

local function GetDistance()
  local colx, coly = ENT:GetCollisionBounds();
  return colx:Distance(coly);
end

local function PlayLockedSound()
  if (self.LockedSound ~= nil) then self:EmitSound(self.LockedSound) end;
end

local function PlayUnlockedSound()
  if (self.UnlockedSound ~= nil) then self:EmitSound(self.UnlockedSound) end;
end

local function PlayOpeningSound()
  if (self.StartSound ~= nil) then
    self:EmitSound(self.StartSound);
  end
end

local function PlayClosingSound()
  if (self.StartCloseSound ~= nil) then
    self:EmitSound(self.StartCloseSound);
  elseif (self.StartSound ~= nil) then
    self:EmitSound(self.StartSound);
  end
end

local function PlayOpenedSound()
  if (self.EndSound ~= nil) then self:EmitSound(self.EndSound) end;
end

local function PlayClosedSound()
  if (self.EndCloseSound ~= nil) then
    self:EmitSound(self.EndCloseSound)
  elseif (self.EndSound ~= nil) then
    self:EmitSound(self.EndSound);
  end
end

local function Open()
  if (self.Locked == false && self.HasReset == true) then
    PlayUnlockedSound();
    PlayOpeningSound();

    self.HasReset = false;

    if (timer.Exists("ResetTimer")) then
      timer.Destroy("ResetTimer");
    end

    if (timer.Exists("OpenMoveTimer")) then
      timer.Destroy("OpenMoveTimer");
    end

    local ent_dist = GetDistance();

    timer.Create("OpenMoveTimer", self.MovementSpeed, ent_dist, function()
      if (self.DistanceLeft < GetDistance() - self.Lip) then
        self.DistanceLeft = self.DistanceLeft + 1;
        self:SetPosVector(self.DistanceLeft);
      else
        self.DoorOpen = true;
        PlayOpenedSound();
      end
    end);
  else
    if (self.Locked == true) then
      PlayLockedSound();
    end
  end
end

local function Close()
  if (self.Locked == false && self.HasReset == true) then
    PlayUnlockedSound();
    PlayClosingSound();

    self.HasReset = false;

    if (timer.Exists("ResetTimer")) then
      timer.Destroy("ResetTimer");
    end

    if (timer.Exists("CloseMoveTimer")) then
      timer.Destroy("CloseMoveTimer");
    end

    timer.Create("ResetTimer", self.DelayBeforeReset, 1, function() self.HasReset = true; end);

    local ent_dist = GetDistance();

    timer.Create("CloseMoveTimer", self.MovementSpeed, ent_dist, function()
      if (self.DistanceLeft > 0 + self.Lip) then
        self.DistanceLeft = self.DistanceLeft - 1;
        self:SetPosVector(self.DistanceLeft);
      else
        self.DoorOpen = false;
        PlayClosedSound();
      end
    end);
  else
    if (self.Locked == true) then
      PlayLockedSound();
    end
  end
end

local function Toggle()
  if (self.DoorOpen == true) then
    Close();
  elseif (self.DoorOpen == false) then
    Open();
  end
end

function ENT:KeyValue(key, value)
  if (key == "") then
  elseif (key == "whitelisted_factions") then
    local wfactions = value;
    wfactions = factions:gsub("%s+", "");
    self.WhitelistedFactions = string.Split(wfactions, ",");
  elseif (key == "blacklisted_factions") then
    local bfactions = value;
    bfactions = factions:gsub("%s+", "");
    self.BlacklistedFactions = string.Split(bfactions, ",");
  elseif (key == "combinelock") then
    // bool here is either 1 or 0
    self.HasCombineLock = value;
  elseif (key == "render_halo") then
    self.RenderHalo = value;
  elseif (key == "airtight") then
    self.IsAirtight = value;

  // Door base keyvalues
  elseif (key == "movedir") then
    self.MovementDirection = string.Split(value, " ");
  elseif (key == "speed") then
    self.MovementSpeed = value;
  elseif (key == "noise1") then
    self.StartSound = value;
  elseif (key == "noise2") then
    self.EndSound = value;
  elseif (key == "startclosesound") then
    self.StartCloseSound = value;
  elseif (key == "closesound") then
    self.EndCloseSound = value;
  elseif (key == "wait") then
    self.DelayBeforeReset = value;
  elseif (key == "lip") then
    self.Lip = value;
  elseif (key == "dmg") then
    self.BlockingDamage = value;
  elseif (key == "forceclosed") then
    self.ForceClosed = value;
  elseif (key == "ignoredebris") then
    self.IgnoreDebris = value;
  elseif (key == "message") then
    self.Message = value;
  elseif (key == "health") then
    self.HealthShootOpen = value;
  elseif (key == "locked_sound") then
    self.LockedSound = value;
  elseif (key == "unlocked_sound") then
    self.UnlockedSound = value;
  elseif (key == "spawnpos") then
    self.SpawnPosition = value;

    if (value == "1") then
      self.DoorOpen = true;

      self.DistanceLeft = GetDistance();
    else
      self.DoorOpen = false;

      self.DistanceLeft = 0;
    end
  elseif (key == "spawnflags") then
    self.SpawnFlags = value;
  elseif (key == "loopmovesound") then
    self.LoopMoveSound = value;
  else
    if (v ~= nil) then
      self:StoreOutput(k, v);
    end
  end
end

function ENT:AcceptInput(inputName, activator, called)
  if (inputName == "Open") then
    Open();
  elseif (inputName == "Close") then
    Close();
  elseif (inputName == "Toggle") then
    Toggle();
  elseif (inputName == "Lock") then
    self.Locked = true;
  elseif (inputName == "Unlock") then
    self.Locked = false;
  elseif (inputName == "SetSpeed") then
  end
end

function ENT:Use(ply)

end
