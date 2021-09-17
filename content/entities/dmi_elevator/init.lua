include("shared.lua");

function ENT:Initialize()
  self.initialized = false;
  self.floorsReady = false;

  self.nodeList = {};
  self.doorList = {};
  self.carCalls = {};
  self.carDoors = nil;
  self.doorsOpen = false;
  self.moving = false;

  self.destinationFloor = 0;
  self.lastFloor = 0;

  print("[DMIControl] Found a dynamic elevator. Loading it.");
  if (self:populateNodeList() == true) then
    self:populateDoorList();
    self:populateCarDoors();

    if (self:populateTracktrain() == true) then
      print("[DMIControl] Finished initializing this dynamic elevator.");
      self.initialized = true;
    else
      print("[DMIControl] Couldn't load this dynamic elevator! No tracktrain entity found!");
      self:Remove();
    end

  else
    print("[DMIControl] Couldn't load this dynamic elevator! Not enough track nodes!");
    self:Remove();
  end
end

function ENT:KeyValue(key, value)
  if (key == "initfloor") then

    self.lastFloor = value;
    self.destinationFloor = value;

    self.floorsReady = true;
  else
    self:StoreOutput(key, value);
  end
end

function ENT:Think()
  --if (self.initialized == true and self.floorsReady == true and self.doorsOpen == false) then
  if (self.initialized == true and self.doorsOpen == false) then
    if (self.destinationFloor ~= 0 and self.destinationFloor ~= self.lastFloor) then
      if (self.lastFloor ~= 0) then

        -- Calculate the next floor to stop on.
        self:calculateNextFloor();
        if (self.lastFloor > self.destinationFloor) then
          if (self.moving == false) then
            self.moving = true;
            self.trackTrain:Fire("StartBackward");
          end
        elseif (self.lastFloor < self.destinationFloor) then
          if (self.moving == false) then
            self.moving = true;
            self.trackTrain:Fire("StartForward");
          end
        else
          self.destinationFloor = self.nodeList[1];
        end
      end
    else
      self:calculateNextFloor();
    end
  end
end

function ENT:getNodeValid(entPrefix, ent)
  if (ent:IsValid() and ent:GetName() ~= nil) then
    -- Make sure our entity is a valid path_track with a name matching that of the control entity.
    if (ent:GetClass() == "path_track") then
      return true;
    else
      return false;
    end
  else
    return false;
  end
end

function ENT:populateTracktrain()
  -- Get the prefix of the current elevator control entity.
  local entPrefix = self:GetName() .. "_tracktrain";

  for k, ent in pairs(ents.GetAll()) do
    if (ent:IsValid() and ent:GetName() == entPrefix) then
      self.trackTrain = ent;
    end
  end

  if (self.trackTrain ~= nil) then
    return true;
  else
    return false;
  end
end

function ENT:populateNodeList()
  -- Get the prefix of the current elevator control entity.
  local nodePrefix = self:GetName() .. "_node_";

  -- Find path_track entities matching the elevator classname
  for k, ent in pairs(ents.FindByClass("path_track")) do
    -- Get the name of the entity.
    local entPrefix = ent:GetName();

    -- Make sure our current entity is valid.
    if (self:getNodeValid(entPrefix, ent) == true) then
      -- Add the floor to the floors table.
      local nodeFloor = tonumber(string.sub(entPrefix, (string.len(nodePrefix) + 1)));
      print("[DMIControl] Found dynamic elevator floor node, number: " .. nodeFloor .. ".");
      table.insert(self.nodeList, nodeFloor);
    end
  end

  if (table.Count(self.nodeList) >= 2) then
    return true;
  else
    return false;
  end
end

function ENT:populateDoorList()
  -- Get the prefix of the current elevator control entity.

  -- Find door entities matching the elevator classname
  for k, v in pairs(self.nodeList) do
    for num, ent in pairs(ents.FindByName(self:GetName() .. "_door_" .. k)) do
      self.doorList[v] = ent;
    end

    if (self.doorList[v] ~= nil) then
      print("[DMIControl] Found dynamic elevator outer door model for floor " .. k .. ".");
    else
      print("[DMIControl] Error! Couldn't find a suitable door entity for floor " .. k .. "!");
    end
  end
end

function ENT:populateCarDoors()
  for num, ent in pairs(ents.FindByName(self:GetName() .. "_cardoor")) do
    self.carDoors = ent;
  end

  if (self.carDoors ~= nil) then
    print("[DMIControl] Found dynamic elevator inner door model.");
  else
    print("[DMIControl] Error! Couldn't find a suitable inner door entity!");
  end
end

-- Calculate which floor should be served next.
function ENT:calculateNextFloor()
  if (table.Count(self.carCalls) >= 1) then
    local nextCall = self:getNearestFloorCall(self.lastFloor);
    if (nextCall ~= nil) then
      self.destinationFloor = nextCall;
    else
      self.destinationFloor = self.carCalls[1];
    end
  else

    -- Couldn't find any calls! Just stop at the nearest floor.
    local nextFloor = self.lastFloor;
    if (nextFloor ~= nil) then
      self.destinationFloor = nextFloor;
    else
      -- Failsafe
      print("[DMIControl] Error! Failsafe triggered! Something really bad happened in code. Please report this!");
      self.destinationFloor = self.nodeList[1];
    end
  end
end

function ENT:getNearestFloorCall(floor)
  local currSmallest;
  local currIndex;

  for i, y in ipairs(self.carCalls) do
    if not currIndex or (math.abs(floor-y) < currSmallest) then
      currSmallest = math.abs(floor-y);
      currIndex = i;
    end
  end
  return self.carCalls[currIndex];
end

function ENT:getNearestFloor(floor)
  local currSmallest;
  local currIndex;

  for i, y in ipairs(self.nodeList) do
    if not currIndex or (math.abs(floor-y) < currSmallest) then
      currSmallest = math.abs(floor-y);
      currIndex = i;
    end
  end
  return currIndex;
end

function ENT:openDoors(floor)
  for num, door in pairs(self.doorList) do
    if (door:GetName() == self:GetName() .. "_door_" .. floor) then
      door:Fire("SetAnimation", "open");
    end
  end
end

function ENT:closeDoors(floor)
  for num, door in pairs(self.doorList) do
    if (door:GetName() == self:GetName() .. "_door_" .. floor) then
      door:Fire("SetAnimation", "close");
    end
  end
end

-- Add a pending car call on the specified floor.
function ENT:addCarCall(floor)
  if (table.KeyFromValue(self.nodeList, floor) ~= nil) then
    if (table.KeyFromValue(self.carCalls, floor) == nil) then
      table.insert(self.carCalls, floor);
    end

    --Screw the math for now, I'm too tired for this.
    --if (self.lastFloor ~= floor and self:getNearestFloorCall(floor) <= self:getNearestFloorCall(self.desinationFloor)) then
      --self.destinationFloor = floor;
    --end
  end
end

-- Remove a pending car call on the specified floor.
function ENT:removeCarCall(floor)
  table.RemoveByValue(self.carCalls, floor);
end

-- Should be called when the car arrives on the specified floor.
function ENT:floorArrive(floor)
  if (table.KeyFromValue(self.nodeList, floor) ~= nil) then
    self:removeCarCall(floor);

    self:openDoors(floor);
    self.carDoors:Fire("SetAnimation", "open");

    self.doorsOpen = true;

    timer.Create("ElevatorAutoCloseTimer_" .. self:GetName(), 5, 1, function()
      self.carDoors:Fire("SetAnimation", "close");
      self:closeDoors(floor);

      timer.Create("ElevatorAnimDoorCloseTimer_" .. self:GetName(), 2, 1, function()
        self.doorsOpen = false;
      end);
    end);
  end
end

function ENT:bumpDoorsOpen(floor)
  if (table.KeyFromValue(self.nodeList, floor) ~= nil) then
    self:openDoors(floor);
    self.doorsOpen = true;

    timer.Create("ElevatorAutoCloseTimer_" .. self:GetName(), 5, 1, function()
      self:closeDoors(floor);

      timer.Create("ElevatorAnimDoorCloseTimer_" .. self:GetName(), 2, 1, function()
        self.doorsOpen = false;
      end);
    end);
  end
end

function ENT:bumpCarDoorsOpen()
  self.carDoors:Fire("SetAnimation", "open");
  self.doorsOpen = true;

  timer.Create("ElevatorAutoCloseTimerCar_" .. self:GetName(), 5, 1, function()
    self.carDoors:Fire("SetAnimation", "close");

    timer.Create("ElevatorAnimDoorCloseTimerCar_" .. self:GetName(), 2, 1, function()
      self.doorsOpen = false;
    end);
  end);
end

-- Should be called when the tracktrain passes a path_track entity.
function ENT:nodePass(nodeEntity)
  if (self.initialized == true) then
    -- Get the prefix of the current elevator control entity.
    local nodePrefix = self:GetName() .. "_node_";
    local entPrefix = nodeEntity:GetName();

    -- Make sure our current entity is valid.
    if (self:getNodeValid(entPrefix, nodeEntity) == true) then
      local nodeFloor = tonumber(string.sub(entPrefix, (string.len(nodePrefix) + 1)));

      if (nodeFloor ~= nil) then
        self.lastFloor = nodeFloor;

        if (self.destinationFloor ~= nodeFloor) then
          self:calculateNextFloor();
        end

        -- Check whether this floor is our destination.
        if (self.destinationFloor == nodeFloor) then
          -- Stop the train!
          self.trackTrain:Fire("Stop");
          self.trackTrain:Fire("TeleportToPathTrack", ents.FindByName(self:GetName() .. "_node_" .. nodeFloor)[1]:GetName());
          self.moving = false;

          -- Arrive at the floor.
          self:floorArrive(nodeFloor);
        else
          self:calculateNextFloor();
        end
      else
        -- Throw an error and ignore the floor.
        print("[DMIControl] Internal error! Dynamic elevator passed invalid floor: " .. nodeFloor .. ". Ignoring.");
      end
    end
  end
end

-- Should be called when someone presses the up button on the specified floor.
function ENT:upButtonPressed(buttonEntity)
  if (self.initialized == true) then
    -- Get the prefix of the current elevator control entity.
    local buttonPrefix = self:GetName() .. "_upbutton_";
    local entPrefix = buttonEntity:GetName();

    -- Make sure our current entity is valid.
    --if (self:getNodeValid(entPrefix, buttonEntity) == true) then
      local buttonFloor = tonumber(string.sub(entPrefix, (string.len(buttonPrefix) + 1)));
      if (table.KeyFromValue(self.nodeList, buttonFloor) ~= nil) then
        if (self.lastFloor == self.destinationFloor and self.lastFloor == buttonFloor and self.doorsOpen == false) then
          self:bumpDoorsOpen(buttonFloor);
          self:bumpCarDoorsOpen();
        else
          if (table.KeyFromValue(self.carCalls, buttonFloor) == nil) then
            self:addCarCall(buttonFloor);
          end
        end
      else
        -- Throw an error and ignore the button.
        print("[DMIControl] Internal error! Dynamic elevator pressed up button for invalid floor: " .. nodeFloor .. ". Ignoring.");
      end
    --end
  end
end

-- Should be called when someone presses the down button on the specified floor.
function ENT:downButtonPressed(buttonEntity)
  if (self.initialized == true) then
    -- Get the prefix of the current elevator control entity.
    local buttonPrefix = self:GetName() .. "_downbutton_";
    local entPrefix = buttonEntity:GetName();

    -- Make sure our current entity is valid.
    --if (self:getNodeValid(entPrefix, buttonEntity) == true) then
      local buttonFloor = tonumber(string.sub(entPrefix, (string.len(buttonPrefix) + 1)));
      if (table.KeyFromValue(self.nodeList, buttonFloor) ~= nil) then
        if (self.lastFloor == self.destinationFloor and self.lastFloor == buttonFloor and self.doorsOpen == false) then
          self:bumpDoorsOpen(buttonFloor);
          self:bumpCarDoorsOpen();
        else
          if (table.KeyFromValue(self.carCalls, buttonFloor) == nil) then
            self:addCarCall(buttonFloor);
          end
        end
      else
        -- Throw an error and ignore the button.
        print("[DMIControl] Internal error! Dynamic elevator pressed down button for invalid floor: " .. nodeFloor .. ". Ignoring.");
      end
    --end
  end
end

function ENT:carUpButtonPressed()
  if (table.KeyFromValue(self.nodeList, (self.lastFloor + 1)) ~= nil) then
    --if (self.lastFloor == self.destinationFloor and self.doorsOpen == false) then
    --  self:bumpDoorsOpen(self.lastFloor);
    --  self:bumpCarDoorsOpen();
    --else
      if (table.KeyFromValue(self.carCalls, self.destinationFloor) == nil) then
        self:addCarCall(self.lastFloor + 1);
      end
    --end
  end
end

function ENT:carDownButtonPressed()
  if (table.KeyFromValue(self.nodeList, (self.lastFloor - 1)) ~= nil) then
    --if (self.lastFloor == self.destinationFloor and self.doorsOpen == false) then
      --self:bumpDoorsOpen(self.lastFloor);
      --self:bumpCarDoorsOpen();
    --else
      if (table.KeyFromValue(self.carCalls, self.destinationFloor) == nil) then

        self:addCarCall(self.lastFloor - 1);
      end
    --end
  end
end

function ENT:AcceptInput(inputName, activator, called)
  if (inputName == "PassFloor" and called:IsValid()) then
    self:nodePass(called);
  elseif (inputName == "FloorCallUp" and called:IsValid()) then
    self:upButtonPressed(called);
  elseif (inputName == "FloorCallDown" and called:IsValid()) then
    self:downButtonPressed(called);
  elseif (inputName == "CarCallUp") then
    self:carUpButtonPressed();
  elseif (inputName == "CarCallDown") then
    self:carDownButtonPressed();
  end
end
