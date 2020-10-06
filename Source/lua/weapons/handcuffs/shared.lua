
if SERVER then
    AddCSLuaFile("shared.lua")

    resource.AddFile("materials/katharsmodels/handcuffs/handcuffs_body.vmt")
    resource.AddFile("materials/katharsmodels/handcuffs/handcuffs_body.vtf")
    resource.AddFile("materials/katharsmodels/handcuffs/handcuffs_claw.vmt")
    resource.AddFile("materials/katharsmodels/handcuffs/handcuffs_claw.vtf")
    resource.AddFile("models/katharsmodels/handcuffs/handcuffs-1.mdl")
    resource.AddFile("models/katharsmodels/handcuffs/handcuffs-3.mdl")
    resource.AddFile("materials/katharsmodels/handcuffs/handcuffs_extras.vmt")
    resource.AddFile("materials/katharsmodels/handcuffs/handcuffs_extras.vtf")
    resource.AddFile("materials/vgui/ttt/icon_handscuffs.png")
end

if CLIENT then
   SWEP.PrintName = "Handcuffs"
   SWEP.Slot = 7

   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "Cuff someone to force them to drop weapons and prevent picking up new ones"
   }

   SWEP.Icon = "vgui/ttt/icon_handscuffs.png"

end

SWEP.Base                  = "weapon_tttbase"
SWEP.Author                = "Converted by Porter"
SWEP.PrintName             = "Handcuffs"
SWEP.Purpose               = "Make it so someone can't use weapons"
SWEP.Instructions          = "Left click to put cuffs on. Right click to take cuffs off."
SWEP.Spawnable             = false
SWEP.AdminSpawnable        = true
SWEP.HoldType              = "normal"
SWEP.UseHands              = true
SWEP.ViewModelFlip         = false
SWEP.ViewModelFOV          = 90
SWEP.ViewModel             = "models/katharsmodels/handcuffs/handcuffs-1.mdl"
SWEP.WorldModel            = "models/katharsmodels/handcuffs/handcuffs-1.mdl"
SWEP.Kind                  = WEAPON_EQUIP2
SWEP.CanBuy                = { ROLE_DETECTIVE }

SWEP.Primary.NumShots      = 1
SWEP.Primary.Delay         = 0.9
SWEP.Primary.Recoil        = 0
SWEP.Primary.Ammo          = "none"
SWEP.Primary.Damage        = 0
SWEP.Primary.Cone          = 0
SWEP.Primary.ClipSize      = -1
SWEP.Primary.DefaultClip   = -1
SWEP.Primary.Automatic     = false

SWEP.Secondary.Delay       = 0.9
SWEP.Secondary.Recoil      = 0
SWEP.Secondary.Damage      = 0
SWEP.Secondary.NumShots    = 1
SWEP.Secondary.Cone        = 0
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"


function SWEP:Reload()
end

if CLIENT then
    function SWEP:GetViewModelPosition(pos, ang)
        ang:RotateAroundAxis(ang:Forward(), 90)
        pos = pos + ang:Forward()*6
        return pos, ang
    end
end

function SWEP:Think()
end

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
    if SERVER then
        for _, v in pairs(player.GetAll()) do
            if v:IsValid() and (v:IsPlayer() or v:IsNPC()) then
                if v:GetNWBool("FrozenYay", false) then
                    v:SetNWBool("FrozenYay", false)
                    v:SetNWBool("GotCuffed", true)
                    v:Give("weapon_zm_improvised")
                    v:Give("weapon_zm_carry")
                    v:Give("weapon_ttt_unarmed")
                end
            end
        end
    end

    local trace = { }
    trace.start = self.Owner:EyePos()
    trace.endpos = trace.start + self.Owner:GetAimVector() * 95
    trace.filter = self.Owner

    local tr = util.TraceLine(trace)
    local target = tr.Entity
    if target:IsValid() and (target:IsPlayer() or target:IsNPC()) then
        if target:GetNWBool("GotCuffed", false) or target:GetNWBool("FrozenYay", false) then
            self.Owner:PrintMessage(HUD_PRINTCENTER, "You can't cuff the same person 2 times.")
            return
        end

        self.Owner:PrintMessage(HUD_PRINTCENTER, "Player was cuffed.")
        self.Owner:EmitSound("npc/metropolice/vo/holdit.wav", 50, 100)

        target:PrintMessage(HUD_PRINTCENTER, "You was cuffed.")
        target:EmitSound("npc/metropolice/vo/holdit.wav", 50, 100)

        if not IsValid(self.Owner) then return end
        self.IsWeaponChecking = false

        timer.Create("EndCuffed", 30, 1, function()
            if SERVER then
                if target:IsValid() and (target:IsPlayer() or target:IsNPC()) then
                    if target:GetNWBool("FrozenYay", false) then
                        timer.Stop("CantPickUp")
                        target:SetNWBool("FrozenYay", false)
                        target:SetNWBool("GotCuffed", true)
                        target:Give("weapon_zm_improvised")
                        target:Give("weapon_zm_carry")
                        target:Give("weapon_ttt_unarmed")
                        target:PrintMessage(HUD_PRINTCENTER, "You are released.")
                        if IsValid(self.Owner) then
                            self.Owner:PrintMessage(HUD_PRINTCENTER, "30 seconds are up.")
                        end
                    end
                end
            end
        end)

        if CLIENT then return end

        timer.Create("CantPickUp", 0.01, 0, function()
            if not IsValid(target) or not target:IsPlayer() then return end

            target:SetNWBool("FrozenYay", true)
            for _, v in pairs(target:GetWeapons()) do
                target:DropWeapon(v)
                local class = v:GetClass()
                if SERVER then
                    target:StripWeapon(class)
                end
            end
        end)

        hook.Add("PlayerCanPickupWeapon", "noDoublePickup", function(ply, wep)
            if ply:IsValid() and ply:GetNWBool("FrozenYay", false) and ply:GetNWBool("GotCuffed", false) then
                return false
            end
        end)
    end
end

function SWEP:SecondaryAttack()
    if SERVER then
        local trace = { }
        trace.start = self.Owner:EyePos()
        trace.endpos = trace.start + self.Owner:GetAimVector() * 95
        trace.filter = self.Owner

        local tr = util.TraceLine(trace)
        local target = tr.Entity

        if target:IsValid() and target:IsPlayer() and target:Alive() then
            if target:GetNWBool("FrozenYay", false) then
                timer.Stop("CantPickUp")
                target:SetNWBool("FrozenYay", false)
                target:SetNWBool("GotCuffed", true)
                target:Give("weapon_zm_improvised")
                target:Give("weapon_zm_carry")
                target:Give("weapon_ttt_unarmed")
                target:PrintMessage(HUD_PRINTCENTER,"You are released.")
                target:EmitSound("npc/metropolice/vo/getoutofhere.wav", 50, 100)
                self.Owner:EmitSound("npc/metropolice/vo/getoutofhere.wav", 50, 100)
            elseif target:GetNWBool("GotCuffed", false) or target:GetNWBool("FrozenYay", false) then
                self.Owner:PrintMessage(HUD_PRINTCENTER, "Player isn't cuffed")
            end
        end
    end
end


local function StopCantPickUp()
    timer.Stop("EndCuffed")
    timer.Stop("CantPickUp")
    for _, v in pairs(player.GetAll()) do
        v:SetNWBool("GotCuffed", false)
        v:SetNWBool("FrozenYay", false)
    end
end
hook.Add("TTTEndRound", "CantPickUpEnd_TER", StopCantPickUp)
hook.Add("PlayerDisconnected", "CantPickUpEnd_PD", StopCantPickUp)
hook.Add("TTTBeginRound", "CantPickUpEnd_TBR", StopCantPickUp)