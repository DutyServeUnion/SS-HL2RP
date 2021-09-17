include("shared.lua");

SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

local laserMaterial = Material("trails/laser");

function SWEP:Setup(ply)
	self.SoundEmittedSuccess = false;
	self.SoundEmittedFailure = false;

	if ply.GetViewModel and ply:GetViewModel():IsValid() then
		local attachmentIndex = ply:GetViewModel():LookupAttachment("muzzle");
		if attachmentIndex == 0 then attachmentIndex = ply:GetViewModel():LookupAttachment("1") end
		if LocalPlayer():GetAttachment(attachmentIndex) then
			self.VM = ply:GetViewModel();
			self.Attach = attachmentIndex;
		end
	end
	if ply:IsValid() then
		local attachmentIndex = ply:LookupAttachment("anim_attachment_RH")
		if ply:GetAttachment(attachmentIndex) then
			self.WM = ply;
			self.WAttach = attachmentIndex;
		end
	end
end

function SWEP:Initialize()
	self:Setup(self:GetOwner());
end

function SWEP:Deploy(ply)
	self:Setup(self:GetOwner());
end

function SWEP:ViewModelDrawn()
	if self.Weapon:GetNWBool("Active") and self.VM then

    render.SetMaterial(laserMaterial);
    local hit = self:GetOwner():GetEyeTrace().HitPos;
		render.DrawBeam(self.VM:GetAttachment(self.Attach).Pos, hit, 2, 0, 12.5, Color(255, 255, 255, 255));

    local ed = EffectData();
    ed:SetOrigin(hit);

    util.Effect("ManhackSparks", ed);

    if (self.SoundEmittedSuccess == false) then
			self.SoundEmittedSuccess = true;
			timer.Create("DoorOverrideLaserSfxTimer", 0.5, 5, function() EmitSound("buttons/button17.wav", hit, LocalPlayer():EntIndex(), CHAN_WEAPON, 1, SNDLVL_75dB); end);
			surface.PlaySound("npc/manhack/grind1.wav");
		end
  elseif (self.Weapon:GetNWBool("Failure")) then
		self.SoundEmittedSuccess = false;
    local hit = self:GetOwner():GetEyeTrace().HitPos;

		if (self.SoundEmittedFailure == false) then
			self.SoundEmittedFailure = true;
			surface.PlaySound("buttons/button8.wav");
		end
	else
		timer.Remove("DoorOverrideLaserSfxTimer");
		self.SoundEmittedSuccess = false;
		self.SoundEmittedFailure = false;
	end
end

function SWEP:DrawWorldModel()
	self.Weapon:DrawModel()
	if self.Weapon:GetNWBool("Active") and self.WM then
    render.SetMaterial(laserMaterial);
		local posang = self.WM:GetAttachment(self.WAttach);
		if not posang then self.WM = nil; return end
		render.DrawBeam(posang.Pos + posang.Ang:Forward()*10 + posang.Ang:Up()*4.4 + posang.Ang:Right(), self:GetOwner():GetEyeTrace().HitPos, 2, 0, 12.5, Color(255, 0, 0, 255));
    end
end
