local API = require("api")
local TIMER = require("utilities.timer")
--local LOOTER = require("lib.looter")
COMBAT = {}
--local looter = LOOTER:new(500)

local function waitUntil(x, timeout)
    local start = os.time()
    if type(x) == "boolean" then
      while not x and start + timeout > os.time() do
        API.RandomSleep2(50, 0, 0)
      end
      if x then
        return true
      else
        return false
      end
    else
      while not x() and start + timeout > os.time() do
          API.RandomSleep2(50, 0, 0)
      end
      if x() then
        return true
      else
        return false
      end
    end
end

  ---Surges if facing 0-360
---@param Orientation number
local function SurgeIfFacing(Orientation,timeout)
    local timer = timeout or 0.1
    local function NormalizeOrientation(value)
        return value == 360 and 0 or value
    end
    local start = os.time()
    while os.time() < start + timer and API.Read_LoopyLoop() do
      if NormalizeOrientation(Orientation) == NormalizeOrientation(math.floor(API.calculatePlayerOrientation()) ) then
        local Surge = API.GetABs_id(14233)
          if (Surge.id ~= 0 and Surge.cooldown_timer < 1) then
            API.DoAction_Ability_Direct(Surge, 1, API.OFF_ACT_GeneralInterface_route)
              return true 
          end
      end      
    end
    return false
end

------------------------------------------------- PRAYER STUFF -------------------------------------------------

local oldNecklace = 0
--- Need to have whatever potion you're using - prayer renewal, super restore, or prayer potions - set in one of your ability bars
function COMBAT.prayerCheck()
    local prayer = API.GetPrayPrecent()
    local elvenCD = API.DeBuffbar_GetIDstatus(43358, false)
    local elvenFound = API.InvItemcount_1(43358)
    local dragontoothFound = API.InvItemcount_1(19887)
    if TIMER:shouldRun("ELVEN") and prayer < 70 and not elvenCD.found and elvenFound > 0 then
        API.logDebug("[COMBAT] Using Elven Shard")
        API.DoAction_Inventory1(43358, 0, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:randomThreadedSleep("ELVEN",800,1000)
    elseif TIMER:shouldRun("PRAYERPOT") and prayer < 50 and (API.InvItemcount_String("Prayer renewal") > 0) and not API.Buffbar_GetIDstatus(14695,false).found then
        API.logDebug("[COMBAT] Using Prayer renewal")
        API.DoAction_Ability("Prayer renewal potion", 1, API.OFF_ACT_GeneralInterface_route,true)
        TIMER:randomThreadedSleep("PRAYERPOT",800,1000)
    elseif TIMER:shouldRun("PRAYERPOT") and prayer < 20 and (API.InvItemcount_String("Super restore") > 0) and not API.Buffbar_GetIDstatus(14695,false).found then
        API.logDebug("[COMBAT] Using Super restore")
        API.DoAction_Ability("Super restore potion", 1, API.OFF_ACT_GeneralInterface_route,true)
        TIMER:randomThreadedSleep("PRAYERPOT",800,1000)
    elseif TIMER:shouldRun("PRAYERPOT") and prayer < 20 and (API.InvItemcount_String("Prayer potion") > 0) then
        API.logDebug("[COMBAT] Using Prayer Potion")
        API.DoAction_Ability("Prayer potion", 1, API.OFF_ACT_GeneralInterface_route,true)
        TIMER:randomThreadedSleep("PRAYERPOT",800,1000)
    elseif TIMER:shouldRun("DRAGONTOOTH") and prayer < 20 and dragontoothFound > 0 and API.GetEquipSlot(2).itemid1 ~= -1 and API.GetEquipSlot(2).itemid1 ~= 19887 then
        API.logDebug("[COMBAT] Swapping to Dragontooth")
        oldNecklace = API.GetEquipSlot(2).itemid1
        API.DoAction_Inventory1(19887,0,2,API.OFF_ACT_GeneralInterface_route)
        TIMER:randomThreadedSleep("DRAGONTOOTH",800,1000)
    elseif TIMER:shouldRun("DRAGONTOOTH") and oldNecklace ~= 0 and prayer > 95 then
        API.logDebug("[COMBAT] Swapping back to original necklace")
        API.DoAction_Inventory1(oldNecklace,0,2,API.OFF_ACT_GeneralInterface_route)
        oldNecklace = 0
        TIMER:randomThreadedSleep("DRAGONTOOTH",800,1000)
    end
end

function COMBAT.prayMage()
    if API.GetPray_() > 0 and TIMER:shouldRun("PRAYER_MAGE") then
        if API.GetABs_name1("Deflect Magic").enabled and not API.Buffbar_GetIDstatus(26041).found then
            API.DoAction_Ability("Deflect Magic", 1, API.OFF_ACT_GeneralInterface_route)
            TIMER:createSleep("PRAYER_MAGE",700)
        elseif API.GetABs_name1("Protect from Magic").enabled and not API.Buffbar_GetIDstatus(25959).found then
            API.DoAction_Ability("Protect from Magic", 1, API.OFF_ACT_GeneralInterface_route)
            TIMER:createSleep("PRAYER_MAGE",700)
        end
    end
end


function COMBAT.prayRanged()
    if API.GetPray_() > 0 and TIMER:shouldRun("PRAYER_RANGE") then
        if API.GetABs_name1("Deflect Ranged").enabled and not API.Buffbar_GetIDstatus(26044).found then
            API.DoAction_Ability("Deflect Ranged", 1, API.OFF_ACT_GeneralInterface_route)
            TIMER:createSleep("PRAYER_RANGE",700)
        elseif API.GetABs_name1("Protect from Ranged").enabled and not API.Buffbar_GetIDstatus(25960).found then
            API.DoAction_Ability("Protect from Ranged", 1, API.OFF_ACT_GeneralInterface_route)
            TIMER:createSleep("PRAYER_RANGE",700)
        end
    end
end

function COMBAT.prayMelee()
    if API.GetPray_() > 0 and TIMER:shouldRun("PRAYER_MELEE") then
        if API.GetABs_name1("Deflect Melee").enabled and not API.Buffbar_GetIDstatus(26040).found then
            API.DoAction_Ability("Deflect Melee", 1, API.OFF_ACT_GeneralInterface_route)
            TIMER:createSleep("PRAYER_MELEE",700)
        end
        if API.GetABs_name1("Protect from Melee").enabled and not API.Buffbar_GetIDstatus(25961).found then
            API.DoAction_Ability("Protect from Melee", 1, API.OFF_ACT_GeneralInterface_route)
            TIMER:createSleep("PRAYER_MELEE",700)
        end
    end
end

local prayedNecro = 0
function COMBAT.prayNecro()
    if API.GetPray_() > 0 and os.time() > prayedNecro + 1 then
        if API.GetABs_name1("Deflect Necromancy").enabled and not API.Buffbar_GetIDstatus(30745).found then
            API.DoAction_Ability("Deflect Necromancy", 1, API.OFF_ACT_GeneralInterface_route)
            prayedNecro = os.time()
        end
        if API.GetABs_name1("Protect from Necromancy").enabled and not API.Buffbar_GetIDstatus(30831).found then
            API.DoAction_Ability("Protect from Necromancy", 1, API.OFF_ACT_GeneralInterface_route)
            prayedNecro = os.time()
        end
    end
end

function COMBAT.praySoulSplit()
    if API.GetPray_() > 0 and TIMER:shouldRun("COMBAT_PRAYSOULSPLIT") then
        if not API.Buffbar_GetIDstatus(26033).found then
            API.DoAction_Ability("Soul Split", 1, API.OFF_ACT_GeneralInterface_route)
            TIMER:createSleep("COMBAT_PRAYSOULSPLIT",1800)
        end
    end
end

function COMBAT.quickPray()
    local qp = API.ScanForInterfaceTest2Get(false, { {1430,0,-1,0}, {1430,4,-1,0}, {1430,12,-1,0}, {1430,13,-1,0} })[1]
    if API.Mem_Read_int(qp.memloc + I_slides) == 18619 and TIMER:shouldRun("COMBAT_QUICKPRAY") and API.GetPray_() > 50 then -- Checks if Quick Prayer is enabled
        API.logDebug("Enabling QuickPray")
        API.DoAction_Interface(0xffffffff,0xffffffff,1,1430,16,-1,API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("COMBAT_QUICKPRAY",3000)
        TIMER:createSleep("COMBAT_PRAYSOULSPLIT",1800)
    end
end

function COMBAT.disablePrayer(keepQuickPray)
    local quick = keepQuickPray or false
    if TIMER:shouldRun("DISABLE_PRAYER") then
        API.logDebug("[COMBAT] Disabling Prayer")
        TIMER:createSleep("DISABLE_PRAYER",4000)
        local qp = API.ScanForInterfaceTest2Get(false, { {1430,0,-1,0}, {1430,4,-1,0}, {1430,12,-1,0}, {1430,13,-1,0} })[1]
        if not quick and API.Mem_Read_int(qp.memloc + I_slides) == 18620 then -- Checks if Quick Prayer is enabled
            API.logDebug("[COMBAT] Disabling QuickPray")
            API.DoAction_Interface(0xffffffff,0xffffffff,1,1430,16,-1,API.OFF_ACT_GeneralInterface_route)
        elseif API.Buffbar_GetIDstatus(25961).found then
            API.DoAction_Ability("Protect from Melee", 1, API.OFF_ACT_GeneralInterface_route)
        elseif API.Buffbar_GetIDstatus(26040).found then
            API.DoAction_Ability("Deflect Melee", 1, API.OFF_ACT_GeneralInterface_route)
        elseif API.Buffbar_GetIDstatus(25960).found then
            API.DoAction_Ability("Protect from Ranged", 1, API.OFF_ACT_GeneralInterface_route)
        elseif API.Buffbar_GetIDstatus(26044).found then
            API.DoAction_Ability("Deflect Ranged", 1, API.OFF_ACT_GeneralInterface_route)
        elseif API.Buffbar_GetIDstatus(25959).found then
            API.DoAction_Ability("Protect from Magic", 1, API.OFF_ACT_GeneralInterface_route)
        elseif API.Buffbar_GetIDstatus(26041).found then
            API.DoAction_Ability("Deflect Magic", 1, API.OFF_ACT_GeneralInterface_route)
        elseif API.Buffbar_GetIDstatus(30831).found then
            API.DoAction_Ability("Protect from Necromancy", 1, API.OFF_ACT_GeneralInterface_route)
        elseif API.Buffbar_GetIDstatus(30745).found then
            API.DoAction_Ability("Deflect Necromancy", 1, API.OFF_ACT_GeneralInterface_route)
        elseif API.Buffbar_GetIDstatus(26033).found then
            API.DoAction_Ability("Soul Split", 1, API.OFF_ACT_GeneralInterface_route)
        elseif API.Buffbar_GetIDstatus(26048).found then
            API.DoAction_Ability("Light Form", 1, API.OFF_ACT_GeneralInterface_route)
        end
    end
end

---@param projectileId integer ID of the mob
---@param prayer string (Range,Mage,Melee,Necro,SoulSplit)
---@param delayPrayer integer Delay from seeing the animation before triggering the prayer in ms
---@param delaySoulsplit integer Delay from seeing the animation before going back to soulsplit, this should be larger than delay
---@param projectileCooldown integer Cooldown at which seeing the projectile again would be considered a new attack (should be just longer than the projectile's duration)
function COMBAT.prayAgainstProjectile(projectileId,prayer,delayPrayer,delaySoulsplit,projectileCooldown)
    local projCooldown = projectileCooldown or 4000
    local soul = delaySoulsplit or 0
    local delay = delayPrayer or 0
    if API.GetPray_() > 0 then
        if TIMER:shouldRun(projectileId) then
            if #API.ReadAllObjectsArray({5},{projectileId},{}) > 0 then
                --API.logDebug("Found matching ´projectile")
                TIMER:createSleep(projectileId,projCooldown)
                TIMER.tasks["Soul"] = nil
                --API.logDebug("[COMBAT] Removing Soul")
                if prayer == "Range" then
                    --API.logDebug("[COMBAT] Scheduling Ranged for: " .. delay)
                    TIMER:scheduleTask(projectileId,delay,function() COMBAT.prayRanged() end) 
                    if soul > 0 and (API.GetHPrecent() < 95 or API.Buffbar_GetIDstatus(26033,false).found) then TIMER:scheduleTask("Soul",soul,function() COMBAT.praySoulSplit() end) 
                    elseif soul > 0 then TIMER:scheduleTask("Soul",soul,function() COMBAT.disablePrayer(true) end) end
                elseif prayer == "Mage" then
                    --API.logDebug("[COMBAT] Scheduling Mage for: " .. delay)
                    TIMER:scheduleTask(projectileId,delay,function() COMBAT.prayMage() end) 
                    if soul > 0 and (API.GetHPrecent() < 95 or API.Buffbar_GetIDstatus(26033,false).found) then TIMER:scheduleTask("Soul",soul,function() COMBAT.praySoulSplit() end) 
                    elseif soul > 0 then TIMER:scheduleTask("Soul",soul,function() COMBAT.disablePrayer(true) end) end
                elseif prayer == "Melee" then
                    --API.logDebug("[COMBAT] Scheduling Melee for: " .. delay)
                    TIMER:scheduleTask(projectileId,delay,function() COMBAT.prayMelee() end) 
                    if soul > 0 and (API.GetHPrecent() < 95 or API.Buffbar_GetIDstatus(26033,false).found) then TIMER:scheduleTask("Soul",soul,function() COMBAT.praySoulSplit() end)
                    elseif soul > 0 then TIMER:scheduleTask("Soul",soul,function() COMBAT.disablePrayer(true) end) end
                elseif prayer == "Necro" then
                    TIMER:scheduleTask(projectileId,delay,function() COMBAT.prayNecro() end) 
                    if soul > 0 and (API.GetHPrecent() < 95 or API.Buffbar_GetIDstatus(26033,false).found) then TIMER:scheduleTask("Soul",soul,function() COMBAT.praySoulSplit() end) 
                    elseif soul > 0 then TIMER:scheduleTask("Soul",soul,function() COMBAT.disablePrayer(true) end) end
                elseif prayer == "SoulSplit" and TIMER:shouldRunWithBaseDelay(projectileId,delay) then
                    COMBAT.praySoulSplit()
                end
            end
        end
    end
end

local lastSeenAnim = 0
---@param mobId integer ID of the mob
---@param animation integer ID of the animation
---@param prayer string (Range,Mage,Melee,Necro,SoulSplit)
---@param delayPrayer integer Delay from seeing the animation before triggering the prayer in ms
---@param delaySoulsplit integer Delay from seeing the animation before going back to soulsplit, this should be larger than delay
---@param animCooldown integer Cooldown at which seeing the animation again would be considered a new attack (This is used as a backup and should be just longer than the animation's duration)
function COMBAT.prayAgainstAnimation(mobId,animation,prayer,delayPrayer,delaySoulsplit,animCooldown)
    local soul = delaySoulsplit or 0
    local delay = delayPrayer or 0
    local animationCooldown = animCooldown or (delay + soul + 600)
    local mobs = API.ReadAllObjectsArray({1},{mobId},{})
    if API.GetPray_() > 0 then
        for _ , mob in ipairs(mobs) do 
            if mob.Anim ~= lastSeenAnim then
                TIMER.timers[lastSeenAnim] = 0
            end
            if TIMER:shouldRun(animation) then
                if mob.Anim == animation then
                    --API.logDebug("Found matching animation")
                    TIMER:createSleep(animation,animationCooldown)
                    TIMER.tasks["Soul"] = nil
                    --API.logDebug("[COMBAT] Removing Soul")
                    if prayer == "Range" then
                        --API.logDebug("[COMBAT] Scheduling Ranged for: " .. delay)
                        TIMER:scheduleTask(animation,delay,function() COMBAT.prayRanged() end) 
                        if soul > 0 and (API.GetHPrecent() < 95 or API.Buffbar_GetIDstatus(26033,false).found) then TIMER:scheduleTask("Soul",soul,function() COMBAT.praySoulSplit() end) 
                        elseif soul > 0 then TIMER:scheduleTask("Soul",soul,function() COMBAT.disablePrayer(true) end) end
                    elseif prayer == "Mage" then
                        --API.logDebug("[COMBAT] Scheduling Mage for: " .. delay)
                        TIMER:scheduleTask(animation,delay,function() COMBAT.prayMage() end) 
                        if soul > 0 and (API.GetHPrecent() < 95 or API.Buffbar_GetIDstatus(26033,false).found) then TIMER:scheduleTask("Soul",soul,function() COMBAT.praySoulSplit() end) 
                        elseif soul > 0 then TIMER:scheduleTask("Soul",soul,function() COMBAT.disablePrayer(true) end) end
                    elseif prayer == "Melee" then
                        --API.logDebug("[COMBAT] Scheduling Melee for: " .. delay)
                        TIMER:scheduleTask(animation,delay,function() COMBAT.prayMelee() end) 
                        if soul > 0 and (API.GetHPrecent() < 95 or API.Buffbar_GetIDstatus(26033,false).found) then TIMER:scheduleTask("Soul",soul,function() COMBAT.praySoulSplit() end)
                        elseif soul > 0 then TIMER:scheduleTask("Soul",soul,function() COMBAT.disablePrayer(true) end) end
                    elseif prayer == "Necro" then
                        TIMER:scheduleTask(animation,delay,function() COMBAT.prayNecro() end) 
                        if soul > 0 and (API.GetHPrecent() < 95 or API.Buffbar_GetIDstatus(26033,false).found) then TIMER:scheduleTask("Soul",soul,function() COMBAT.praySoulSplit() end) 
                        elseif soul > 0 then TIMER:scheduleTask("Soul",soul,function() COMBAT.disablePrayer(true) end) end
                    elseif prayer == "SoulSplit" and TIMER:shouldRunWithBaseDelay(animation,delay) then
                        COMBAT.praySoulSplit()
                    end
                    break
                end
            end
        end
    end
end

--------------------------------------------- NECRO ROTATION ----------------------------------------------------------


local function checkBloated()
    if API.ReadTargetInfo(false).Hitpoints ~= 0 then
        Buff_stack = API.ReadTargetInfo(true).Buff_stack
        for _ , buff in ipairs(Buff_stack) do
            if buff == 30098 then
                return true
            end
        end
        return false
    end
end

function COMBAT.necroOpener(lifeTransfer)
    API.DoAction_Ability("Conjure Vengeful Ghost", 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1700,200,200)
    API.DoAction_Ability("Conjure Skeleton Warrior", 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1700,200,200)
    API.DoAction_Ability("Command Vengeful Ghost", 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1700,200,200)
    if lifeTransfer and API.DoAction_Ability_check("Life Transfer", 1, API.OFF_ACT_GeneralInterface_route,true,false,false) then
        API.RandomSleep2(1700,200,200)
        API.DoAction_Ability("Enhanced Excalibur", 1, API.OFF_ACT_GeneralInterface_route)
    end
    API.DoAction_Ability("Invoke Death", 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1700,200,200)
    API.DoAction_Ability("Command Skeleton Warrior", 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1700,200,200)
end

local lastPlayerAnim = -1
local NecroAnimations = {
    [35502] = true, [35505] = true, [35461] = true, [35456] = true, [35472] = true, [35454] = true, [35458] = true, [35506] = true, 
    [35489] = true, [35491] = true, [35449] = true, [35493] = true, [22338] = true, [35477] = true, [35499] = true, [35469] = true, 
    [35482] = true, [35484] = true, [35475] = true, [35508] = true
}
local lastAttackTime = os.clock() -- Initialize last attack time in milliseconds

COMBAT.shouldSplitSoul = false
COMBAT.shouldAddrenaline = false
COMBAT.shouldBloat = false
COMBAT.shouldStormShards = false
COMBAT.shouldUseSkull = true -- Default true
COMBAT.shouldUseLivingDeath = true -- Default true
COMBAT.shouldAttack = true
COMBAT.shouldUseThresholds = true
function COMBAT.doRotationNecro()
    local bloat = API.GetABs_name1("Bloat")
    local specialAttack = API.GetABs_name1("Weapon Special Attack")
    local volley = API.GetABs_name1("Volley of Souls")
    local finger = API.GetABs_name1("Finger of Death")
    local skull = API.GetABs_name1("Death Skulls")
    local touch = API.GetABs_name1("Touch of Death")
    local soulsap = API.GetABs_name1("Soul Sap")
    local death = API.GetABs_name1("Living Death")
    local adrenaline = API.GetAddreline_()
    local army = API.GetABs_name1("Conjure Undead Army")
    local commandGhost = API.GetABs_name1("Command Vengeful Ghost")
    local commandSkelly = API.GetABs_name1("Command Skeleton Warrior")
    local commandZombie = API.GetABs_name1("Command Putrid Zombie")  
    local splitSoul = API.GetABs_name1("Split Soul")
    local stormShards = API.GetABs_name1("Storm Shards")
    local auto = API.GetABs_name("Basic<nbsp>Attack",true)
    local necrosis = API.Buffbar_GetIDstatus(30101,false).conv_text
    local souls = API.Buffbar_GetIDstatus(30123,false).conv_text

    local playerAnim = API.ReadPlayerAnim()
    if TIMER:shouldRunStartsWith("GCD_DEFENSIVE") and NecroAnimations[playerAnim] and playerAnim ~= lastPlayerAnim then -- Attack was Executed
        API.logDebug("[COMBAT] Attack Animation: " .. playerAnim .. " | DeltaT: " .. os.clock() - lastAttackTime .. " s")
        lastAttackTime = os.clock()
        lastPlayerAnim = playerAnim
        TIMER:createSleep("GCD",1000)
    elseif playerAnim == -1 then
        API.logDebug("[COMBAT] detected animation -1 ")
        lastPlayerAnim = -1
    end

    ------------------------------ OFF-GCD Stuff --------------------------------
    if API.Buffbar_GetIDstatus(30078).found and COMBAT.shouldAddrenaline then -- Living Death rotation
        if not API.DeBuffbar_GetIDstatus(26094).found and TIMER:shouldRun("ADRENALINE") then
            if API.InvItemcount_String("Adrenaline potion") > 0 then
                API.logDebug("[COMBAT] Adrenaline Potion")
                API.DoAction_Inventory3("Adrenaline potion",0,1,API.OFF_ACT_GeneralInterface_route)
            elseif API.InvItemcount_String("Replenishment potion") > 0 then
                API.logDebug("[COMBAT] Replenishment Potion")
                API.DoAction_Inventory3("Replenishment potion",0,1,API.OFF_ACT_GeneralInterface_route)
            end
            TIMER:createSleep("ADRENALINE",2000)
        end
    end

    ------------------------------ GCD Stuff --------------------------------

    if TIMER:shouldRunStartsWith("GCD") and API.LocalPlayer_IsInCombat_() and (API.ReadTargetInfo(true).Hitpoints > 0 or #API.ReadAllObjectsArray({1},{22454,30165},{}) > 0) then
        TIMER:scheduleTask("COMBAT_ANIMADJUST",800, function() lastPlayerAnim = -1 end)
        if API.Buffbar_GetIDstatus(30129,false).found then -- Threads Rotation
            if souls >= 5 and volley.enabled and volley.id ~= 0 then
                API.logDebug("[COMBAT] Volley of Souls")
                API.DoAction_Ability_Direct(volley, 1, API.OFF_ACT_GeneralInterface_route)
            elseif soulsap.cooldown_timer < 2 and soulsap.enabled then
                API.logDebug("[COMBAT] Soul Sap")
                API.DoAction_Ability_Direct(soulsap, 1, API.OFF_ACT_GeneralInterface_route) 
            elseif souls >= 3 and volley.enabled and volley.id ~= 0 then
                API.logDebug("[COMBAT] Volley of Souls")
                API.DoAction_Ability_Direct(volley, 1, API.OFF_ACT_GeneralInterface_route)
            elseif necrosis >= 6 and finger.enabled and finger.id ~= 0 then
                API.logDebug("[COMBAT] Finger of Death")
                API.DoAction_Ability_Direct(finger, 1, API.OFF_ACT_GeneralInterface_route)
            elseif specialAttack.enabled and specialAttack.id ~= 0 and (not API.DeBuffbar_GetIDstatus(55524,false).found and not API.DeBuffbar_GetIDstatus(55480,false).found) then
                API.logDebug("[COMBAT] Special Weapon Attack")
                API.DoAction_Ability_Direct(specialAttack, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldBloat and not checkBloated() and (API.ReadTargetInfo(false).Hitpoints > 20000 or #API.ReadAllObjectsArray({1},{22454,30165},{}) > 0) and bloat.id ~= 0 and bloat.enabled then
                API.logDebug("[COMBAT] Bloated")
                API.DoAction_Ability_Direct(bloat, 1, API.OFF_ACT_GeneralInterface_route)
            elseif touch.cooldown_timer < 2 and touch.enabled then
                API.logDebug("[COMBAT] Touch of Death")
                API.DoAction_Ability_Direct(touch, 1, API.OFF_ACT_GeneralInterface_route)
            else
                API.logDebug("[COMBAT] Auto Attack")
                API.DoAction_Ability_Direct(auto, 1, API.OFF_ACT_GeneralInterface_route)
            end

            ------------------------------------------- Living Death rotation ----------------------------------------------
        elseif API.Buffbar_GetIDstatus(30078).found then 
            if COMBAT.shouldSplitSoul and API.Buffbar_GetIDstatus(30078).conv_text <= 26 and adrenaline >= 60 and splitSoul.enabled and splitSoul.cooldown_timer <= 1 then
                API.logDebug("[COMBAT] Split Soul")
                API.DoAction_Ability_Direct(splitSoul, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and COMBAT.shouldUseSkull and skull.cooldown_timer <= 1 and skull.enabled and adrenaline >= 60 then -- Death Skulls
                API.logDebug("[COMBAT] Death Skulls")
                API.DoAction_Ability_Direct(skull, 1, API.OFF_ACT_GeneralInterface_route)
            elseif touch.cooldown_timer <= 1 and touch.enabled and adrenaline < 60 and COMBAT.shouldAddrenaline and COMBAT.shouldUseSkull then
                API.logDebug("[COMBAT] Touch of Death")
                API.DoAction_Ability_Direct(touch, 1, API.OFF_ACT_GeneralInterface_route)
            elseif necrosis == 12 then -- Finger of Death
                API.logDebug("[COMBAT] Finger of Death")
                API.DoAction_Ability_Direct(finger, 1, API.OFF_ACT_GeneralInterface_route)
            elseif touch.cooldown_timer <= 1 and touch.enabled then
                API.logDebug("[COMBAT] Touch of Death")
                API.DoAction_Ability_Direct(touch, 1, API.OFF_ACT_GeneralInterface_route)
            elseif commandZombie.cooldown_timer < 2 and commandZombie.enabled and (1 < API.Buffbar_GetIDstatus(34179,false).conv_text and API.Buffbar_GetIDstatus(34179,false).conv_text < 10) then
                API.logDebug("[COMBAT] Command Putrid Zombie")
                API.DoAction_Ability_Direct(commandZombie, 1, API.OFF_ACT_GeneralInterface_route)
            elseif (skull.cooldown_timer >= 8 or adrenaline > 60 or not COMBAT.shouldUseSkull) and commandSkelly.cooldown_timer < 2 and commandSkelly.enabled then
                API.logDebug("[COMBAT] Command Skeleton Warrior")
                API.DoAction_Ability_Direct(commandSkelly, 1, API.OFF_ACT_GeneralInterface_route)
            elseif not (API.Buffbar_GetIDstatus(34177,false).found or API.Buffbar_GetIDstatus(34178,false).found or API.Buffbar_GetIDstatus(34179,false).found) and army.cooldown_timer < 2 and army.enabled then
                API.logDebug("[COMBAT] Conjure Undead Army")
                API.DoAction_Ability("Conjure Undead Army", 1, API.OFF_ACT_GeneralInterface_route,false)
            elseif ((skull.cooldown_timer > 8 or adrenaline > 60) or not COMBAT.shouldUseSkull) and necrosis >= 6 then -- Finger of Death
                API.logDebug("[COMBAT] Finger of Death")
                API.DoAction_Ability_Direct(finger, 1, API.OFF_ACT_GeneralInterface_route)
            elseif soulsap.cooldown_timer < 2 and soulsap.enabled and souls < 5 then
                API.logDebug("[COMBAT] Soul Sap")
                API.DoAction_Ability_Direct(soulsap, 1, API.OFF_ACT_GeneralInterface_route) 
            else
                API.logDebug("[COMBAT] Auto Attack")
                API.DoAction_Ability_Direct(auto, 1, API.OFF_ACT_GeneralInterface_route)
            end
            ------------------------------------------- Split-Soul rotation (outside of living death) ----------------------------------------------
        elseif API.Buffbar_GetIDstatus(30126).found then
            if COMBAT.shouldAttack and COMBAT.shouldUseThresholds and COMBAT.shouldUseSkull and skull.cooldown_timer <= 1 and skull.enabled and adrenaline >= 60 then -- Death Skulls
                API.logDebug("[COMBAT] Death Skulls")
                API.DoAction_Ability_Direct(skull, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and COMBAT.shouldUseLivingDeath and (API.ReadTargetInfo(false).Hitpoints > 20000 or (#API.ReadAllObjectsArray({1},{22454,30165},{}) > 0 and API.ReadTargetInfo(false).Cmb_lv > 0)) and death.cooldown_timer <= 1 and death.enabled and adrenaline >= 100 then
                API.logDebug("[COMBAT] Living Death")
                API.DoAction_Ability_Direct(death, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and souls >= 4 and volley.enabled and volley.id ~= 0 then -- Volley
                API.logDebug("[COMBAT] Volley of Souls")
                API.DoAction_Ability_Direct(volley, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and COMBAT.shouldBloat and TIMER:shouldRun("BLOAT") and (death.cooldown_timer > 10 or adrenaline == 100 or not COMBAT.shouldUseLivingDeath) and (adrenaline > 85 or skull.cooldown_timer > 10 or not COMBAT.shouldUseSkull) and not checkBloated() and (API.ReadTargetInfo(false).Hitpoints > 20000 or (#API.ReadAllObjectsArray({1},{22454,30165},{}) > 0)) and bloat.id ~= 0 and bloat.enabled then
                API.logDebug("[COMBAT] Bloated")
                API.DoAction_Ability_Direct(bloat, 1, API.OFF_ACT_GeneralInterface_route)
                TIMER:createSleep("BLOAT",18000)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and (API.GetEquipSlot(2).itemid1 == 50467 or API.InvItemFound1(50467)) and necrosis >= 8 and adrenaline > 25 and (((death.cooldown_timer > 10 or adrenaline == 100 or not COMBAT.shouldUseLivingDeath) and (adrenaline > 85 or skull.cooldown_timer > 10 or not COMBAT.shouldUseSkull)) or (API.ReadTargetInfo(false).Hitpoints < 40000 and API.ReadTargetInfo(false).Hitpoints > 10000)) and not API.DeBuffbar_GetIDstatus(55524,false).found then
                local previousNecklace = API.GetEquipSlot(2).itemid1
                if API.InvItemFound1(50467) then -- Need to equip before using
                    API.logDebug("[COMBAT] Equipping Essence of Finality")
                    API.DoAction_Inventory1(50467,0,2,API.OFF_ACT_GeneralInterface_route)
                    API.RandomSleep2(100,100,200)
                    TIMER:scheduleTask("COMBAT_EQUIP",1000,function() API.DoAction_Inventory1(previousNecklace,0,2,API.OFF_ACT_GeneralInterface_route) end)
                end
                API.logDebug("[COMBAT] Death Guard EoF with " .. necrosis .. " stacks") 
                API.DoAction_Ability("Essence of Finality", 1, API.OFF_ACT_GeneralInterface_route,true)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and (API.GetEquipSlot(3).itemid1 == 55540 or API.GetEquipSlot(3).itemid1 == 55544 or API.InvItemFound1(55540) or API.InvItemFound1(55544)) and ((death.cooldown_timer > 10 or adrenaline == 100 or not COMBAT.shouldUseLivingDeath) and (adrenaline > 85 or skull.cooldown_timer > 10 or not COMBAT.shouldUseSkull) or (API.ReadTargetInfo(false).Hitpoints < 40000 and API.ReadTargetInfo(false).Hitpoints > 10000)) and necrosis >= 8 and adrenaline > 25 and not API.DeBuffbar_GetIDstatus(55524,false).found then
                local previousMainhand = API.GetEquipSlot(3).itemid1
                if API.InvItemFound1(55540) or API.InvItemFound1(55544) then -- Need to equip before using
                    API.logDebug("[COMBAT] Equipping Death Guard")
                    API.DoAction_Inventory1(55540,0,2,API.OFF_ACT_GeneralInterface_route)
                    API.RandomSleep2(100,100,200)
                    TIMER:scheduleTask("COMBAT_EQUIP",1000,function() API.DoAction_Inventory1(previousMainhand,0,2,API.OFF_ACT_GeneralInterface_route) end)
                end
                API.logDebug("[COMBAT] Death Guard Special Weapon Attack") 
                API.DoAction_Ability_Direct(specialAttack, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and (API.GetEquipSlot(3).itemid1 == 55480 or API.GetEquipSlot(3).itemid1 == 55484) and (((death.cooldown_timer > 10 or adrenaline == 100 or not COMBAT.shouldUseLivingDeath) and (adrenaline > 85 or skull.cooldown_timer > 10 or not COMBAT.shouldUseSkull)) or (API.ReadTargetInfo(false).Hitpoints < 40000 and API.ReadTargetInfo(false).Hitpoints > 10000)) and adrenaline > 30 and specialAttack.enabled and specialAttack.id ~= 0 and not API.DeBuffbar_GetIDstatus(55480,false).found then
                API.logDebug("[COMBAT] Omni Guard Special Weapon Attack") 
                API.DoAction_Ability_Direct(specialAttack, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and soulsap.cooldown_timer < 2 and soulsap.enabled and souls < 5 and necrosis == 12 then
                API.logDebug("[COMBAT] Soul Sap")
                API.DoAction_Ability_Direct(soulsap, 1, API.OFF_ACT_GeneralInterface_route) 
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and necrosis == 12 and finger.enabled and finger.id ~= 0 then
                API.logDebug("[COMBAT] Finger of Death")
                API.DoAction_Ability_Direct(finger, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and touch.cooldown_timer < 2 and touch.enabled then
                API.logDebug("[COMBAT] Touch of Death")
                API.DoAction_Ability_Direct(touch, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and soulsap.cooldown_timer < 2 and soulsap.enabled then
                API.logDebug("[COMBAT] Soul Sap")
                API.DoAction_Ability_Direct(soulsap, 1, API.OFF_ACT_GeneralInterface_route) 
            elseif COMBAT.shouldAttack then
                API.logDebug("[COMBAT] Auto Attack")
                API.DoAction_Ability_Direct(auto, 1, API.OFF_ACT_GeneralInterface_route)
            end
            ------------------------------------------- Normal rotation ----------------------------------------------
        else
            if COMBAT.shouldAttack and COMBAT.shouldUseThresholds and COMBAT.shouldUseSkull and skull.cooldown_timer <= 1 and skull.enabled and adrenaline >= 60 then -- Death Skulls
                API.logDebug("[COMBAT] Death Skulls")
                API.DoAction_Ability_Direct(skull, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and COMBAT.shouldUseLivingDeath and (API.ReadTargetInfo(false).Hitpoints > 20000 or (#API.ReadAllObjectsArray({1},{22454,30165},{}) > 0 and API.ReadTargetInfo(false).Cmb_lv > 0)) and death.cooldown_timer <= 1 and death.enabled and adrenaline >= 100 then
                API.logDebug("[COMBAT] Living Death")
                API.DoAction_Ability_Direct(death, 1, API.OFF_ACT_GeneralInterface_route)
            elseif not (API.Buffbar_GetIDstatus(34177,false).found or API.Buffbar_GetIDstatus(34178,false).found or API.Buffbar_GetIDstatus(34179,false).found) and army.cooldown_timer < 2 and army.enabled then
                API.logDebug("[COMBAT] Conjure Undead Army")
                API.DoAction_Ability("Conjure Undead Army", 1, API.OFF_ACT_GeneralInterface_route,false)
            elseif commandGhost.cooldown_timer < 2 and commandGhost.enabled then
                API.logDebug("[COMBAT] Command Vengeful Ghost")
                API.DoAction_Ability_Direct(commandGhost, 1, API.OFF_ACT_GeneralInterface_route)
            elseif commandZombie.cooldown_timer < 2 and commandZombie.enabled and  (1 < API.Buffbar_GetIDstatus(34179,false).conv_text and API.Buffbar_GetIDstatus(34179,false).conv_text < 10) then
                API.logDebug("[COMBAT] Command Putrid Zombie")
                API.DoAction_Ability_Direct(commandZombie, 1, API.OFF_ACT_GeneralInterface_route)
            elseif commandSkelly.cooldown_timer < 2 and commandSkelly.enabled then
                API.logDebug("[COMBAT] Command Skeleton Warrior")
                API.DoAction_Ability_Direct(commandSkelly, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and souls >= 5 and volley.enabled and volley.id ~= 0 and soulsap.cooldown_timer < 2 then -- Volley
                API.logDebug("[COMBAT] Volley of Souls")
                API.DoAction_Ability_Direct(volley, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and necrosis == 12 and API.DeBuffbar_GetIDstatus(55524,false).found and finger.enabled and finger.id ~= 0 and API.ReadTargetInfo(false).Hitpoints < 30000 then
                API.logDebug("[COMBAT] Finger of Death")
                API.DoAction_Ability_Direct(finger, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and COMBAT.shouldBloat and TIMER:shouldRun("BLOAT") and (death.cooldown_timer > 10 or adrenaline == 100 or not COMBAT.shouldUseLivingDeath) and (adrenaline > 85 or skull.cooldown_timer > 10 or not COMBAT.shouldUseSkull) and not checkBloated() and (API.ReadTargetInfo(false).Hitpoints > 20000 or (#API.ReadAllObjectsArray({1},{22454,30165},{}) > 0)) and bloat.id ~= 0 and bloat.enabled then
                API.logDebug("[COMBAT] Bloated")
                API.DoAction_Ability_Direct(bloat, 1, API.OFF_ACT_GeneralInterface_route)
                TIMER:createSleep("BLOAT",18000)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and (API.GetEquipSlot(2).itemid1 == 50467 or API.InvItemFound1(50467)) and necrosis >= 8 and adrenaline > 25 and (((death.cooldown_timer > 10 or adrenaline == 100 or not COMBAT.shouldUseLivingDeath) and (adrenaline > 85 or skull.cooldown_timer > 10 or not COMBAT.shouldUseSkull)) or (API.ReadTargetInfo(false).Hitpoints < 40000 and API.ReadTargetInfo(false).Hitpoints > 10000)) and not API.DeBuffbar_GetIDstatus(55524,false).found then
                local previousNecklace = API.GetEquipSlot(2).itemid1
                if API.InvItemFound1(50467) then -- Need to equip before using
                    API.logDebug("[COMBAT] Equipping Essence of Finality")
                    API.DoAction_Inventory1(50467,0,2,API.OFF_ACT_GeneralInterface_route)
                    API.RandomSleep2(100,100,200)
                    TIMER:scheduleTask("COMBAT_EQUIP",1000,function() API.DoAction_Inventory1(previousNecklace,0,2,API.OFF_ACT_GeneralInterface_route) end)
                end
                API.logDebug("[COMBAT] Death Guard EoF with " .. necrosis .. " stacks") 
                API.DoAction_Ability("Essence of Finality", 1, API.OFF_ACT_GeneralInterface_route,true)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and (API.GetEquipSlot(3).itemid1 == 55540 or API.GetEquipSlot(3).itemid1 == 55544 or API.InvItemFound1(55540) or API.InvItemFound1(55544)) and ((death.cooldown_timer > 10 or adrenaline == 100 or not COMBAT.shouldUseLivingDeath) and (adrenaline > 85 or skull.cooldown_timer > 10 or not COMBAT.shouldUseSkull) or (API.ReadTargetInfo(false).Hitpoints < 40000 and API.ReadTargetInfo(false).Hitpoints > 10000)) and necrosis >= 8 and adrenaline > 25 and not API.DeBuffbar_GetIDstatus(55524,false).found then
                local previousMainhand = API.GetEquipSlot(3).itemid1
                if API.InvItemFound1(55540) or API.InvItemFound1(55544) then -- Need to equip before using
                    API.logDebug("[COMBAT] Equipping Death Guard")
                    API.DoAction_Inventory1(55540,0,2,API.OFF_ACT_GeneralInterface_route)
                    API.RandomSleep2(100,100,200)
                    TIMER:scheduleTask("COMBAT_EQUIP",1000,function() API.DoAction_Inventory1(previousMainhand,0,2,API.OFF_ACT_GeneralInterface_route) end)
                end
                API.logDebug("[COMBAT] Death Guard Special Weapon Attack") 
                API.DoAction_Ability_Direct(specialAttack, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and (API.GetEquipSlot(3).itemid1 == 55480 or API.GetEquipSlot(3).itemid1 == 55484) and (((death.cooldown_timer > 10 or adrenaline == 100 or not COMBAT.shouldUseLivingDeath) and (adrenaline > 85 or skull.cooldown_timer > 10 or not COMBAT.shouldUseSkull)) or (API.ReadTargetInfo(false).Hitpoints < 40000 and API.ReadTargetInfo(false).Hitpoints > 10000)) and adrenaline > 30 and specialAttack.enabled and specialAttack.id ~= 0 and not API.DeBuffbar_GetIDstatus(55480,false).found then
                API.logDebug("[COMBAT] Omni Guard Special Weapon Attack") 
                API.DoAction_Ability_Direct(specialAttack, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and soulsap.cooldown_timer < 2 and soulsap.enabled and souls < 5 and necrosis == 12 then
                API.logDebug("[COMBAT] Soul Sap")
                API.DoAction_Ability_Direct(soulsap, 1, API.OFF_ACT_GeneralInterface_route) 
            elseif COMBAT.shouldAttack and COMBAT.shouldStormShards and stormShards.cooldown_timer < 2 and stormShards.enabled then
                API.logDebug("[COMBAT] Storm Shards")
                API.DoAction_Ability_Direct(stormShards, 1, API.OFF_ACT_GeneralInterface_route) 
            elseif COMBAT.shouldAttack and COMBAT.shouldUseThresholds and necrosis == 12 and finger.enabled and finger.id ~= 0 then
                API.logDebug("[COMBAT] Finger of Death")
                API.DoAction_Ability_Direct(finger, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and touch.cooldown_timer < 2 and touch.enabled then
                API.logDebug("[COMBAT] Touch of Death")
                API.DoAction_Ability_Direct(touch, 1, API.OFF_ACT_GeneralInterface_route)
            elseif COMBAT.shouldAttack and soulsap.cooldown_timer < 2 and soulsap.enabled then
                API.logDebug("[COMBAT] Soul Sap")
                API.DoAction_Ability_Direct(soulsap, 1, API.OFF_ACT_GeneralInterface_route) 
            elseif COMBAT.shouldAttack then
                API.logDebug("[COMBAT] Auto Attack")
                API.DoAction_Ability_Direct(auto, 1, API.OFF_ACT_GeneralInterface_route)
            else
                API.logDebug("[COMBAT] No valid rotation move")
            end
        end
        
        TIMER:createSleep("GCD",1700)
    end
end
----------------------------------------------------- DEFENSIVES ----------------------------------------------------------


function COMBAT.excalibur()
    local excalCD = API.DeBuffbar_GetIDstatus(14632, false)
    local excalFound = API.InvItemcount_1(14632)
    if not excalCD.found and excalFound > 0 then
        print("[COMBAT] Using Excalibur")
        API.DoAction_Ability("Enhanced Excalibur", 1, API.OFF_ACT_GeneralInterface_route,true)
        TIMER:randomThreadedSleep("EXCAL",800,1000)
    end
end

---@return boolean
function COMBAT.freedom()
    local Freedom = API.GetABs_name1("Freedom")
    if TIMER:shouldRun("GCD_DEFENSIVE_FREEDOM") and (Freedom.enabled and Freedom.id ~= 0 and Freedom.cooldown_timer < 1) and not API.Buffbar_GetIDstatus(14220,false).found then
        API.logWarn("[COMBAT] Using Freedom")
        API.DoAction_Ability_Direct(Freedom, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_DEFENSIVE_FREEDOM",3000)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.cease()
    local Cease = API.GetABs_name1("Cease")
    if TIMER:shouldRun("CEASE") and (Cease.enabled and Cease.id ~= 0) then
        API.logWarn("[COMBAT] Using Cease")
        API.DoAction_Ability_Direct(Cease, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("CEASE",1800)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.anticipation()
    local Anticipation = API.GetABs_name1("Anticipation")
    if TIMER:shouldRun("GCD_DEFENSIVE_ANTICIPATE") and (Anticipation.enabled and Anticipation.id ~= 0 and Anticipation.cooldown_timer < 1) and not API.Buffbar_GetIDstatus(14219,false).found then
        API.logWarn("[COMBAT] Using Anticipation")
        API.DoAction_Ability_Direct(Anticipation, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_DEFENSIVE_ANTICIPATE",3000)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.barricade()
    local Barricade = API.GetABs_name1("Barricade")
    if TIMER:shouldRun("GCD_DEFENSIVE_BARRICADE") and (Barricade.enabled and Barricade.id ~= 0 and Barricade.cooldown_timer < 1) and API.GetAddreline_() == 100 then
        API.logWarn("[COMBAT] Using Barricade")
        API.DoAction_Ability_Direct(Barricade, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_DEFENSIVE_BARRICADE",3000)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.devotion()
    local Devotion = API.GetABs_name1("Devotion")
    if TIMER:shouldRun("GCD_DEFENSIVE_DEVOTION") and (Devotion.id ~= 0 and Devotion.cooldown_timer < 1) and API.GetAddreline_() > 50 then
        API.logWarn("[COMBAT] Using Devotion")
        API.DoAction_Ability_Direct(Devotion, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_DEFENSIVE_DEVOTION",3000)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.reflect()
    local Reflect = API.GetABs_name1("Reflect")
    if TIMER:shouldRun("GCD_DEFENSIVE_REFLECT") and (Reflect.id ~= 0 and Reflect.cooldown_timer < 1) and API.GetAddreline_() > 50 then
        API.logWarn("[COMBAT] Using Reflect")
        API.DoAction_Ability_Direct(Reflect, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_DEFENSIVE_REFLECT",3000)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.debilitate()
    local Debilitate = API.GetABs_name1("Debilitate")
    if TIMER:shouldRun("GCD_DEFENSIVE_DEBILITATE") and (Debilitate.enabled and Debilitate.id ~= 0 and Debilitate.cooldown_timer < 1) and API.GetAddreline_() > 50 then
        API.logWarn("[COMBAT] Using Debilitate")
        API.DoAction_Ability_Direct(Debilitate, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_DEFENSIVE_DEBILITATE",3000)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.resonance()
    local Resonance = API.GetABs_name1("Resonance")
    if not API.Buffbar_GetIDstatus(14222,false).found and TIMER:shouldRun("GCD_DEFENSIVE_RESONANCE") and (Resonance.enabled and Resonance.id ~= 0 and Resonance.cooldown_timer < 1) then
        API.logWarn("[COMBAT] Using Resonance")
        API.DoAction_Ability_Direct(Resonance, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_DEFENSIVE_RESONANCE",3000)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.disruptionShield()
    local DisruptionShield = API.GetABs_name1("Disruption Shield")
    if not API.Buffbar_GetIDstatus(14450,false).found and TIMER:shouldRun("DISRUPTION_SHIELD") and (DisruptionShield.enabled and DisruptionShield.id ~= 0 and DisruptionShield.cooldown_timer == 0) then
        API.logWarn("[COMBAT] Using Disruption Shield")
        API.DoAction_Ability_Direct(DisruptionShield, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("DISRUPTION_SHIELD",2000)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.vengeance()
    local Vengeance = API.GetABs_name1("Vengeance")
    if not API.Buffbar_GetIDstatus(14450,false).found and TIMER:shouldRun("VENGEANCE") and (Vengeance.enabled and Vengeance.id ~= 0 and Vengeance.cooldown_timer == 0) then
        API.logWarn("[COMBAT] Using Vengeance")
        API.DoAction_Ability_Direct(Vengeance, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("VENGEANCE",2000)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.maintainDarkness()
    local Darkness = API.GetABs_name1("Darkness")
    if not API.Buffbar_GetIDstatus(30122,false).found and TIMER:shouldRun("DARKNESS") and (Darkness.enabled and Darkness.id ~= 0 and Darkness.enabled) then
        API.logWarn("[COMBAT] Darkness: " .. tostring(API.Buffbar_GetIDstatus(30122,true).found))
        API.logWarn("[COMBAT] Using Darkness")
        API.DoAction_Ability_check("Darkness",1,API.OFF_ACT_GeneralInterface_route,true,false,true)
        TIMER:createSleep("GCD_DEFENSIVE_DARKNESS",2000)
        TIMER:createSleep("DARKNESS",60*11*1000)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.shatter()
    local Shatter = API.GetABs_name1("Shatter")
    if TIMER:shouldRun("SHATTER") and (Shatter.enabled and Shatter.id ~= 0 and Shatter.cooldown_timer < 1) and API.Buffbar_GetIDstatus(19227,false).conv_text > 3 then
        API.logWarn("[COMBAT] Using Shatter")
        API.DoAction_Ability_Direct(Shatter, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_DEFENSIVE_SHATTER",2000)
        TIMER:createSleep("SHATTER",60000)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.threads()
    local Threads = API.GetABs_name1("Threads of Fate")
    if TIMER:shouldRun("GCD_DEFENSIVE_THREADS") and (Threads.id ~= 0 and Threads.cooldown_timer < 1 and Threads.enabled) then
        API.logWarn("[COMBAT] Using Threads")
        API.DoAction_Ability_Direct(Threads, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_DEFENSIVE_THREADS",2000)
        return true
    else
        return false
    end
end

function COMBAT.freedomAgainstStun(bindToo)
    if API.DeBuffbar_GetIDstatus(26103,false).found or (bindToo and API.DeBuffbar_GetIDstatus(14392,false).found) then
        COMBAT.freedom()
    end
end

function COMBAT.healthCheck(teleportOut,eatThreshold)
    local eatThreshold = eatThreshold or 40
    local teleport = teleportOut or false
    local excalCD = API.DeBuffbar_GetIDstatus(14632, false)
    local excalFound = API.InvItemcount_1(14632)
    local hp = API.GetHPrecent()
    local eatFoodAB = API.GetABs_name1("Eat Food")
    local brew = API.GetABs_name1("Saradomin brew")
    if TIMER:shouldRun("EXCAL") and hp < 50 and not excalCD.found and excalFound > 0 then
        print("[COMBAT] Using Excalibur")
        API.DoAction_Ability("Enhanced Excalibur", 1, API.OFF_ACT_GeneralInterface_route,true)
        TIMER:randomThreadedSleep("EXCAL",800,1000)
    elseif TIMER:shouldRun("EAT") and hp < eatThreshold and eatFoodAB.id ~= 0 and eatFoodAB.enabled then
        API.logDebug("[COMBAT] Eating")
        API.DoAction_Ability_Direct(eatFoodAB, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:randomThreadedSleep("EAT",1800,1850)
    elseif TIMER:shouldRun("DRINK") and hp < eatThreshold + 5 and brew.id ~= 0 and brew.enabled then
        API.logDebug("[COMBAT] Drinking Saradomin Brew")
        API.DoAction_Ability_Direct(brew, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:randomThreadedSleep("DRINK",1800,1850)
    elseif TIMER:shouldRun("COMBAT_TELEPORT") and TIMER:shouldRun("DRINK") and TIMER:shouldRun("EAT") and teleport and hp < 10 then
        API.logDebug("[COMBAT] Teleporting away")
        TIMER:createSleep("COMBAT_TELEPORT",3000)
        COMBAT.reset(true)

    end
end

----------------------------------------------------------------- WAR'S RETREAT STUFF --------------------------------------------------------------------
function COMBAT.resetMinions()
    if API.GetEquipSlot(5).itemid1 == 55542 and not API.InvFull_() then
        API.DoAction_Interface(0xffffffff,0xd8f6,1,1464,15,5,API.OFF_ACT_GeneralInterface_route) -- Remove lantern
        API.RandomSleep2(1200,100,200)
        API.DoAction_Inventory1(55542,0,2,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(1200,100,200)
    elseif API.GetEquipSlot(5).itemid1 == 55482 and not API.InvFull_() then
        API.DoAction_Interface(0xffffffff,0xd8ba,1,1464,15,5,API.OFF_ACT_GeneralInterface_route) -- Remove lantern
        API.RandomSleep2(1200,100,200)
        API.DoAction_Inventory1(55482,0,2,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(1200,100,200)
    end
end


function COMBAT.doBank(BoB)
    local doBoB = BoB or false
    if API.Read_LoopyLoop() then
        if doBoB then
            API.DoAction_Object1(0x2e,API.OFF_ACT_GeneralObject_route1,{ 114750 },50)
            API.RandomSleep2(600,50,50)
            if waitUntil(API.BankOpen2,10) then
                API.logDebug("[COMBAT] Emptying BoB")
                API.KeyboardPress2(0x35,100,200)
                API.RandomSleep2(1500,100,200)
            end
        end
        API.logDebug("[COMBAT] Loading last preset")
        API.DoAction_Object1(0x33,API.OFF_ACT_GeneralObject_route3,{ 114750 },50)
        API.RandomSleep2(1200,100,200)
        local start = os.time()
        while start + 10 > os.time() and (API.GetHPrecent() < 100 or API.ReadPlayerMovin2()) and API.Read_LoopyLoop() do
            API.RandomSleep2(100,50,50)
        end
    end
end


function COMBAT.doPrayer() 
    if API.Read_LoopyLoop() then
        COMBAT.disablePrayer(false)
        if API.GetPrayPrecent() < 100 or API.GetSummoningPoints_() < (API.GetSummoningMax_() - 100) then
            API.logDebug("[COMBAT] Getting Prayer")
            API.DoAction_Object1(0x3d, 0, {114748}, 75) -- Clicks on Altar of War 
            API.RandomSleep2(1500,50,50)
            local start = os.time()
            while start + 10 > os.time() and (API.GetPrayPrecent() < 100 or API.GetSummoningPoints_() < (API.GetSummoningMax_() - 100)) and API.Read_LoopyLoop() do
                API.RandomSleep2(100,50,50)
            end
        end
        
    end
end


function COMBAT.doAdrenaline() 
    if API.Read_LoopyLoop() then
        if API.GetAddreline_() < 100 then
            API.logDebug("[COMBAT] Getting Adrenaline")
            API.DoAction_Object1(0x29, 0, {114749}, 75)
            API.RandomSleep2(1200,50,50)
            SurgeIfFacing(360,5)
            API.RandomSleep2(400,200,300)
            API.DoAction_Object1(0x29, 0, {114749}, 75) 
            local start = os.time()
            while API.GetAddreline_() < 100 and start + 20 > os.time() and API.Read_LoopyLoop() do
                API.RandomSleep2(100,50,50)
            end
            if API.GetAddreline_() == 100 then API.logDebug("[COMBAT] Successfully got Adren") 
            else API.logError("[COMBAT] Failed to get Adren") end
        end
    end
 end

function COMBAT.retreatTeleport()
    if not (#API.ReadAllObjectsArray({12},{114750},{}) > 0) then
        API.logDebug("[COMBAT] Retreat Teleport")
        API.DoAction_Ability("Retreat Teleport", 1, API.OFF_ACT_GeneralInterface_route)
        local start = os.time()
        while API.Read_LoopyLoop() and #API.GetAllObjArray1({114750},40,{12}) == 0 and start + 8 > os.time() do
            API.RandomSleep2(100,0,0)
        end
    end
end

function COMBAT.reset(BoB)
    if API.Read_LoopyLoop() then
        COMBAT.retreatTeleport()
        API.RandomSleep2(1200,100,200)
        COMBAT.doPrayer()
        COMBAT.doBank(BoB)
        COMBAT.resetMinions()
        COMBAT.doAdrenaline()

        COMBAT.shouldSplitSoul = false
        COMBAT.shouldAddrenaline = false
        COMBAT.shouldBloat = false
        COMBAT.shouldStormShards = false
        COMBAT.shouldUseSkull = true -- Default true
        COMBAT.shouldUseLivingDeath = true -- Default true
        COMBAT.shouldAttack = true
        COMBAT.shouldUseThresholds = true
    end
end

----------------------------------------------------------- UTILITIES ----------------------------------------------------------------

-- function COMBAT.loot(itemstoLoot)
-- local start = os.time()
--     while start + 10 > os.time() and API.Read_LoopyLoop() and #API.ReadAllObjectsArray({3}, itemstoLoot,{}) == 0 do
--         API.RandomSleep2(50,0,0)
--     end
--     while API.Read_LoopyLoop() and #API.ReadAllObjectsArray({3}, itemstoLoot,{}) > 0 and not API.InvFull_() do
--         API.RandomSleep2(50,0,0)
--         looter:lootSelectedItemsAndBasedOnPrice(itemstoLoot,100000,30)
--     end
-- end

-- function COMBAT.lootAll()
--     local start = os.time()
--         while start + 10 > os.time() and API.Read_LoopyLoop() and #API.ReadAllObjectsArray({3}, {-1},{}) == 0 do
--             API.RandomSleep2(50,0,0)
--         end
--         while API.Read_LoopyLoop() and #API.ReadAllObjectsArray({3}, {-1},{}) > 0 and not API.InvFull_() do
--             API.RandomSleep2(50,0,0)
--             API.DoAction_G_Items1(0x29, {API.ReadAllObjectsArray({3}, {-1},{})[1].Id}, 30)
--             API.RandomSleep2(500,100,100)
--             local timeout = os.time() + 10
--             while API.Read_LoopyLoop() and not API.LootWindowOpen_2() and #API.ReadAllObjectsArray({3}, {-1},{}) > 0 and timeout > os.time() do
--                 API.RandomSleep2(50,0,0)
--             end
--             API.DoAction_LootAll_Button()
--             return
--         end
--     end


function COMBAT.maintainAgressionPot()
    if not API.Buffbar_GetIDstatus(37969,false).found and TIMER:shouldRun("AGGROPOT") then
        if API.InvItemcount_String("Aggression potion") > 0 then
            TIMER:createSleep("AGGROPOT",2000)
            API.DoAction_Inventory3("Aggression potion",0,1,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            API.logError("[COMBAT] No Aggression Potions found")
            return false
        end
    else
        return true
    end
end

function COMBAT.antiPoison()
    if API.InvItemcount_String("Antipoison") > 0 and API.DeBuffbar_GetIDstatus(30097,false).found and TIMER:shouldRun("COMBAT_ANTIPOISON") then
        API.DoAction_Inventory3("Antipoison",0,1,API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("COMBAT_ANTIPOISON",2000)
        return true
    else
        return false
    end
end

function COMBAT.vitalityPowerburst()
    if API.InvItemcount_String("Powerburst of vitality") > 0 and not API.DeBuffbar_GetIDstatus(38075,false).found and TIMER:shouldRun("COMBAT_POWERBURSTVITALITY") then
        API.DoAction_Inventory3("Powerburst of vitality",0,1,API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("COMBAT_POWERBURSTVITALITY",1200)
        return true
    else
        return false
    end
end


function COMBAT.maintainOverload()
    if (not API.Buffbar_GetIDstatus(26093,false).found and not API.Buffbar_GetIDstatus(33210,false).found and not API.Buffbar_GetIDstatus(49039,false).found) and TIMER:shouldRun("OVERLOAD") then
        if API.InvItemcount_String("overload salve") > 0 then
            TIMER:createSleep("OVERLOAD",2000)
            API.DoAction_Inventory3("overload salve",0,1,API.OFF_ACT_GeneralInterface_route)
            return true
        elseif API.InvItemcount_String("overload potion") > 0 then
            TIMER:createSleep("OVERLOAD",2000)
            API.DoAction_Inventory3("overload potion",0,1,API.OFF_ACT_GeneralInterface_route)
            return true
        else
            API.logError("[COMBAT] No Overload Potions/Salves found")
            TIMER:createSleep("OVERLOAD",20000)
            return false
        end
    else
        return true
    end
end

---Returns cooldown of an ability
---@param ability string
---@return number
function COMBAT.abilityCooldown(ability)
    local abil = API.GetABs_name(ability,true)
    return abil.cooldown_timer
end

return COMBAT
