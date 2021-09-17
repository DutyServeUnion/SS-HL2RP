AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

include("shared.lua");

include("../../../gamemode/scripted/airex/sv_airex.lua");
include("../../../gamemode/scripted/airex/sv_gasmask.lua");

function SWEP:Initialize()
	self.Active = false;
end

function SWEP:PrimaryAttack()
	local trace = self:GetOwner():GetEyeTrace();
	if IsValid(trace.Entity) and trace.Entity:GetName() == "resistance_base_bunker_door" and airexActive == true then
		self.Active = true;
	  self.Weapon:SetNWBool("Active", true)

	  timer.Create("DoorOverrideLaserTimerSuccess", 3, 1, function()
			trace.Entity:Fire("Open");

			resistanceBaseBreached = true;

	    self.Active = false;
	    self.Weapon:SetNWBool("Active", false);
	  end);
	else
		self.Failure = true;
	  self.Weapon:SetNWBool("Failure", true)

	  timer.Create("DoorOverrideLaserTimerFailure", 0.1, 1, function()
	    self.Failure = false;
	    self.Weapon:SetNWBool("Failure", false);
	  end);
	end
end

function SWEP:SecondaryAttack()
	local trace = self:GetOwner():GetEyeTrace();
	if IsValid(trace.Entity) and trace.Entity:GetName() == "resistance_base_bunker_door" and airexActive == true then
		self.Active = true;
	  self.Weapon:SetNWBool("Active", true)

	  timer.Create("DoorOverrideLaserTimerSuccess", 3, 1, function()
			trace.Entity:Fire("Close");

      timer.Create("ResistanceAirtightDoorReseal", 10, 1, function() resistanceBaseBreached = false; end);

	    self.Active = false;
	    self.Weapon:SetNWBool("Active", false);
	  end);
	else
		self.Failure = true;
	  self.Weapon:SetNWBool("Failure", true)

	  timer.Create("DoorOverrideLaserTimerFailure", 0.1, 1, function()
	    self.Failure = false;
	    self.Weapon:SetNWBool("Failure", false);
	  end);
	end
end

function SWEP:Think()
	if (self.Weapon:GetNWBool("Active") == true) then
	  local trace = self:GetOwner():GetEyeTrace();
		if (IsValid(trace.Entity) and trace.Entity:GetName() == "resistance_base_bunker_door") then
		else
			timer.Remove("DoorOverrideLaserTimerSuccess");
			self.Weapon:SetNWBool("Active", false);
			self.Weapon:SetNWBool("Failure", true)
		end
  end
end
