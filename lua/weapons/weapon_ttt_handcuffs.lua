
if SERVER then
    AddCSLuaFile()

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

if engine.ActiveGamemode() == "terrortown" then
    SWEP.Base              = "weapon_tttbase"
else
    SWEP.Base              = "weapon_base"
end
SWEP.Author                = "Converted by Porter. Updated by Malivil"
SWEP.Category              = "Other"
SWEP.PrintName             = "Handcuffs"
SWEP.ClassName             = "weapon_ttt_handcuffs"
SWEP.Purpose               = "Make it so someone can't use weapons"
SWEP.Instructions          = "Left click to put cuffs on. Right click to take cuffs off."
SWEP.Spawnable             = true
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

    function SWEP:PrimaryAttack() end
    function SWEP:SecondaryAttack() end
end

function SWEP:Think()
end

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
end

if SERVER then
    local saveBlocklist = {"weapon_zm_carry", "weapon_ttt_unarmed"}
    local playerNonDroppables = {}

    local function ReleasePlayer(ply)
        ply:SetNWBool("IsCuffed", false)
        ply:SetNWEntity("CuffedBy", nil)
        ply:SetNWBool("WasCuffed", true)

        local sid64 = ply:SteamID64()
        local hasCrowbar = false
        if playerNonDroppables[sid64] then
            for _, data in ipairs(playerNonDroppables[sid64]) do
                local wep = ply:Give(data.class)
                wep:SetClip1(data.clip1)
                wep:SetClip2(data.clip2)

                if data.class == "weapon_kil_crowbar" then
                    hasCrowbar = true
                end
            end
            playerNonDroppables[sid64] = nil
        end
        if not hasCrowbar then
            ply:Give("weapon_zm_improvised")
        end
        ply:Give("weapon_zm_carry")
        ply:Give("weapon_ttt_unarmed")
        ply:PrintMessage(HUD_PRINTCENTER, "You are released.")
    end

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        -- Release the other players cuffed by this person
        for _, v in pairs(player.GetAll()) do
            if v:IsValid() and (v:IsPlayer() or v:IsNPC()) and v:GetNWBool("IsCuffed", false) and v:GetNWEntity("CuffedBy", nil) == owner then
                ReleasePlayer(v)
                owner:PrintMessage(HUD_PRINTTALK, "Other cuffed player was released.")
                break
            end
        end

        local trace = {}
        trace.start = owner:EyePos()
        trace.endpos = trace.start + owner:GetAimVector() * 95
        trace.filter = owner

        local tr = util.TraceLine(trace)
        local target = tr.Entity
        if target:IsValid() and (target:IsPlayer() or target:IsNPC()) then
            if not IsValid(owner) then return end
            if target:GetNWBool("WasCuffed", false) or target:GetNWBool("IsCuffed", false) then
                owner:PrintMessage(HUD_PRINTCENTER, "You can't cuff the same person 2 times.")
                return
            end

            owner:PrintMessage(HUD_PRINTCENTER, "Player was cuffed.")
            owner:EmitSound("npc/metropolice/vo/holdit.wav", 50, 100)

            target:SetNWBool("IsCuffed", true)
            target:SetNWEntity("CuffedBy", owner)
            target:PrintMessage(HUD_PRINTCENTER, "You was cuffed.")
            target:EmitSound("npc/metropolice/vo/holdit.wav", 50, 100)

            timer.Create(target:Nick() .. "_EndCuffed", 30, 1, function()
                if target:IsValid() and (target:IsPlayer() or target:IsNPC()) and target:GetNWBool("IsCuffed", false) then
                    ReleasePlayer(target)
                    if IsValid(owner) then
                        owner:PrintMessage(HUD_PRINTCENTER, "30 seconds are up.")
                    end
                end
            end)

            local sid64 = target:SteamID64()
            playerNonDroppables[sid64] = {}

            for _, v in pairs(target:GetWeapons()) do
                local class = v:GetClass()
                -- Don't drop crowbar since a new one is given
                if class ~= "weapon_zm_improvised" then
                    -- Only drop droppables (but skip the Killer crowbar)
                    if v.AllowDrop and class ~= "weapon_kil_crowbar" then
                        target:DropWeapon(v)
                    -- Save everything else to give back to the player later
                    elseif not table.HasValue(saveBlocklist, class) then
                        table.insert(playerNonDroppables[sid64], {
                            class = class,
                            clip1 = v:Clip1(),
                            clip2 = v:Clip2()
                        })
                    end
                end
                target:StripWeapon(class)
            end
        end
    end

    function SWEP:SecondaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        local trace = { }
        trace.start = owner:EyePos()
        trace.endpos = trace.start + owner:GetAimVector() * 95
        trace.filter = owner

        local tr = util.TraceLine(trace)
        local target = tr.Entity

        if target:IsValid() and target:IsPlayer() and target:Alive() then
            if target:GetNWBool("IsCuffed", false) then
                ReleasePlayer(target)
                target:EmitSound("npc/metropolice/vo/getoutofhere.wav", 50, 100)
                owner:EmitSound("npc/metropolice/vo/getoutofhere.wav", 50, 100)
            elseif target:GetNWBool("WasCuffed", false) or not target:GetNWBool("IsCuffed", false) then
                owner:PrintMessage(HUD_PRINTCENTER, "Player isn't cuffed")
            end
        end
    end

    local function ClearPlayer(ply)
        ply:SetNWBool("WasCuffed", false)
        ply:SetNWBool("IsCuffed", false)
        ply:SetNWEntity("CuffedBy", nil)
        timer.Stop(ply:Nick() .. "_EndCuffed")
    end

    local function StopCantPickUp()
        for _, v in pairs(player.GetAll()) do
            ClearPlayer(v)
        end
    end
    hook.Add("TTTEndRound", "HandCuffs_TER", StopCantPickUp)
    hook.Add("TTTBeginRound", "HandCuffs_TBR", StopCantPickUp)

    hook.Add("PlayerDeath", "HandCuffs_PDTH", function(victim, infl, attacker)
        ClearPlayer(victim)
    end)
    hook.Add("PlayerDisconnected", "HandCuffs_PDC", ClearPlayer)

    hook.Add("PlayerCanPickupWeapon", "HandCuffs_PCPW", function(ply, wep)
        if ply:IsValid() and ply:GetNWBool("IsCuffed", false) then
            return false
        end
    end)
end