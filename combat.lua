local API = require("api")
local TIMER = require("utilities.timer")
COMBAT = {}

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
function SurgeIfFacing(Orientation,timeout)
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
    if TIMER:shouldRun("ELVEN") and prayer < 80 and not elvenCD.found and elvenFound > 0 then
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

local prayedMelee = 0
function COMBAT.prayMelee()
    if API.GetPray_() > 0 and os.time() > prayedMelee + 1 then
        if API.GetABs_name1("Deflect Melee").enabled and not API.Buffbar_GetIDstatus(26040).found then
            API.DoAction_Ability("Deflect Melee", 1, API.OFF_ACT_GeneralInterface_route)
            prayedMelee = os.time()
        end
        if API.GetABs_name1("Protect from Melee").enabled and not API.Buffbar_GetIDstatus(25961).found then
            API.DoAction_Ability("Protect from Melee", 1, API.OFF_ACT_GeneralInterface_route)
            prayedMelee = os.time()
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

local prayedSoulSplit = 0
function COMBAT.praySoulSplit()
    if API.GetPray_() > 0 and os.time() > prayedSoulSplit + 1 then
        if not API.Buffbar_GetIDstatus(26033).found then
            API.DoAction_Ability("Soul Split", 1, API.OFF_ACT_GeneralInterface_route)
            prayedSoulSplit = os.time()
        end
    end
end

function COMBAT.quickPray()
    if API.VB_FindPSettinOrder(1769).state ~= 2 and TIMER:shouldRun("COMBAT_QUICKPRAY") and API.GetPray_() > 50 then -- Checks if Quick Prayer is enabled
        API.DoAction_Interface(0xffffffff,0xffffffff,1,1430,16,-1,API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("COMBAT_QUICKPRAY",3000)
    end
end

local disabledPrayer = 0
function COMBAT.disablePrayer(keepQuickPray)
    local quick = keepQuickPray or false
    if os.time() > disabledPrayer + 1 then
        if API.Buffbar_GetIDstatus(25961).found then
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
        elseif API.Buffbar_GetIDstatus(26033).found then
            API.DoAction_Ability("Soul Split", 1, API.OFF_ACT_GeneralInterface_route)
        end
        if not quick and API.VB_FindPSettinOrder(1769).state == 2 then -- Checks if Quick Prayer is enabled
            API.logDebug("[COMBAT] VB 1769 = " .. API.VB_FindPSettinOrder(1769).state)
            API.DoAction_Interface(0xffffffff,0xffffffff,1,1430,16,-1,API.OFF_ACT_GeneralInterface_route)
        end
        disabledPrayer = os.time()
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
    local animationCooldown = animCooldown or 4000
    local soul = delaySoulsplit or 0
    local delay = delayPrayer or 0
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
    API.DoAction_Ability("Command Skeleton Warrior", 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1700,200,200)
    if lifeTransfer and API.DoAction_Ability_check("Life Transfer", 1, API.OFF_ACT_GeneralInterface_route,true,false,false) then
        API.RandomSleep2(1700,200,200)
        API.DoAction_Ability("Enhanced Excalibur", 1, API.OFF_ACT_GeneralInterface_route)
    end
end

local lastPlayerAnim = -1
local NecroAnimations = {
    [35502] = true, [35505] = true, [35461] = true, [35456] = true, [35472] = true, [35454] = true, [35458] = true, [35506] = true, 
    [35489] = true, [35491] = true, [35449] = true, [35493] = true, [22338] = true, [35477] = true, [35499] = true, [35469] = true, 
    [35482] = true, [35484] = true, [35475] = true, [35508] = true
}
local lastAttackTime = os.clock() -- Initialize last attack time in milliseconds

function COMBAT.doRotationNecro(shouldBloat)
    local shouldBloat = shouldBloat or false
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
    local auto = API.GetABs_name("Basic<nbsp>Attack",true)

    local playerAnim = API.ReadPlayerAnim()
    if NecroAnimations[playerAnim] and playerAnim ~= lastPlayerAnim then -- Attack was Executed
        -- API.logDebug("[COMBAT] Attack Animation: " .. playerAnim .. " | DeltaT: " .. os.clock() - lastAttackTime .. " s")
        -- lastAttackTime = os.clock()
        lastPlayerAnim = playerAnim
        TIMER:createSleep("GCD",1000)
    elseif playerAnim == -1 then
        lastPlayerAnim = -1
    end

    ------------------------------ OFF-GCD Stuff --------------------------------
    if API.Buffbar_GetIDstatus(30078).found then -- Living Death rotation
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

    if TIMER:shouldRunStartsWith("GCD") and API.LocalPlayer_IsInCombat_() and (API.ReadTargetInfo(false).Hitpoints > 0 or (#API.ReadAllObjectsArray({1},{22454,},{}) > 0 and API.ReadTargetInfo(false).Cmb_lv > 0)) then
        -- API.logDebug("[COMBAT] DeltaT: " .. os.clock() - lastAttackTime .. " s")
        lastAttackTime = os.clock()
        lastPlayerAnim = -1
        if API.Buffbar_GetIDstatus(30078).found then -- Living Death rotation
            if skull.cooldown_timer <= 1 and skull.enabled and adrenaline >= 60 then -- Death Skulls
                API.logDebug("[COMBAT] Death Skulls")
                API.DoAction_Ability_Direct(skull, 1, API.OFF_ACT_GeneralInterface_route)
            elseif touch.cooldown_timer <= 1 and touch.enabled and adrenaline < 60 then
                API.logDebug("[COMBAT] Touch of Death")
                API.DoAction_Ability_Direct(touch, 1, API.OFF_ACT_GeneralInterface_route)
            elseif (skull.cooldown_timer > 8 or adrenaline > 60 or API.GetEquipSlot(11).textitem ~= "Supreme invigorate aura") and API.Buffbar_GetIDstatus(30101,false).conv_text >= 6 then -- Finger of Death
                API.logDebug("[COMBAT] Finger of Death")
                API.DoAction_Ability_Direct(finger, 1, API.OFF_ACT_GeneralInterface_route)
            elseif touch.cooldown_timer <= 1 and touch.enabled then
                API.logDebug("[COMBAT] Touch of Death")
                API.DoAction_Ability_Direct(touch, 1, API.OFF_ACT_GeneralInterface_route)
            elseif (skull.cooldown_timer >= 8 or adrenaline > 60 or API.GetEquipSlot(11).textitem ~= "Supreme invigorate aura") and commandSkelly.cooldown_timer < 2 and commandSkelly.enabled then
                API.logDebug("[COMBAT] Command Skeleton Warrior")
                API.DoAction_Ability_Direct(commandSkelly, 1, API.OFF_ACT_GeneralInterface_route)
            else
                API.logDebug("[COMBAT] Auto Attack")
                API.DoAction_Ability_Direct(auto, 1, API.OFF_ACT_GeneralInterface_route)
            end
        else -- Outside of Living Death
            if skull.cooldown_timer <= 1 and skull.enabled and adrenaline >= 60 then -- Death Skulls
                API.logDebug("[COMBAT] Death Skulls")
                API.DoAction_Ability_Direct(skull, 1, API.OFF_ACT_GeneralInterface_route)
            elseif API.ReadTargetInfo(false).Hitpoints > 20000 and death.cooldown_timer <= 1 and death.enabled and adrenaline >= 100 then
                API.logDebug("[COMBAT] Living Death")
                API.DoAction_Ability_Direct(death, 1, API.OFF_ACT_GeneralInterface_route)
            elseif API.Buffbar_GetIDstatus(30123,false).conv_text == 3 and volley.enabled and volley.id ~= 0 then -- Volley
                API.logDebug("[COMBAT] Volley of Souls")
                API.DoAction_Ability_Direct(volley, 1, API.OFF_ACT_GeneralInterface_route)
            elseif API.Buffbar_GetIDstatus(30101,false).conv_text >= 6 and finger.enabled and finger.id ~= 0 then
                API.logDebug("[COMBAT] Finger of Death")
                API.DoAction_Ability_Direct(finger, 1, API.OFF_ACT_GeneralInterface_route)
            elseif shouldBloat and (death.cooldown_timer > 10 and adrenaline ~= 100) and not checkBloated() and API.ReadTargetInfo(false).Hitpoints > 20000 and bloat.id ~= 0 and bloat.enabled then
                API.logDebug("[COMBAT] Bloated")
                API.DoAction_Ability_Direct(bloat, 1, API.OFF_ACT_GeneralInterface_route)
            elseif (death.cooldown_timer > 10 and adrenaline ~= 100 or API.ReadTargetInfo(false).Hitpoints < 20000) and specialAttack.enabled and specialAttack.id ~= 0 and (not API.DeBuffbar_GetIDstatus(55524,false).found and not API.DeBuffbar_GetIDstatus(55480,false).found) then
                API.logDebug("[COMBAT] Special Weapon Attack")
                API.DoAction_Ability_Direct(specialAttack, 1, API.OFF_ACT_GeneralInterface_route)
            elseif army.cooldown_timer < 2 and army.enabled then
                API.logDebug("[COMBAT] Conjure Undead Army")
                API.DoAction_Ability_Direct(army, 1, API.OFF_ACT_GeneralInterface_route)
            elseif commandSkelly.cooldown_timer < 2 and commandSkelly.enabled then
                API.logDebug("[COMBAT] Command Skeleton Warrior")
                API.DoAction_Ability_Direct(commandSkelly, 1, API.OFF_ACT_GeneralInterface_route)
            elseif commandGhost.cooldown_timer < 2 and commandGhost.enabled then
                API.logDebug("[COMBAT] Command Vengeful Ghost")
                API.DoAction_Ability_Direct(commandGhost, 1, API.OFF_ACT_GeneralInterface_route)
            elseif touch.cooldown_timer < 2 and touch.enabled then
                API.logDebug("[COMBAT] Touch of Death")
                API.DoAction_Ability_Direct(touch, 1, API.OFF_ACT_GeneralInterface_route)
            elseif soulsap.cooldown_timer < 2 and soulsap.enabled then
                API.logDebug("[COMBAT] Soul Sap")
                API.DoAction_Ability_Direct(soulsap, 1, API.OFF_ACT_GeneralInterface_route) 
            else
                API.logDebug("[COMBAT] Auto Attack")
                API.DoAction_Ability_Direct(auto, 1, API.OFF_ACT_GeneralInterface_route)
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
    if TIMER:shouldRun("GCD_FREEDOM") and (Freedom.id ~= 0 and Freedom.cooldown_timer < 1) then
        API.logWarn("[COMBAT] Using Freedom")
        API.DoAction_Ability_Direct(Freedom, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_FREEDOM",1500)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.anticipation()
    local Anticipation = API.GetABs_name1("Anticipation")
    if TIMER:shouldRun("GCD_ANTICIPATE") and (Anticipation.id ~= 0 and Anticipation.cooldown_timer < 1) then
        API.logWarn("[COMBAT] Using Anticipation")
        API.DoAction_Ability_Direct(Anticipation, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_ANTICIPATE",1500)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.barricade()
    local Barricade = API.GetABs_name1("Barricade")
    if TIMER:shouldRun("GCD_BARRICADE") and (Barricade.id ~= 0 and Barricade.cooldown_timer < 1) then
        API.logWarn("[COMBAT] Using Barricade")
        API.DoAction_Ability_Direct(Barricade, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_BARRICADE",1500)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.devotion()
    local Devotion = API.GetABs_name1("Devotion")
    if TIMER:shouldRun("GCD_DEVOTION") and (Devotion.id ~= 0 and Devotion.cooldown_timer < 1) then
        API.logWarn("[COMBAT] Using Devotion")
        API.DoAction_Ability_Direct(Devotion, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_DEVOTION",1500)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.reflect()
    local Reflect = API.GetABs_name1("Reflect")
    if TIMER:shouldRun("GCD_REFLECT") and (Reflect.id ~= 0 and Reflect.cooldown_timer < 1) then
        API.logWarn("[COMBAT] Using Reflect")
        API.DoAction_Ability_Direct(Reflect, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_REFLECT",1500)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.debilitate()
    local Debilitate = API.GetABs_name1("Debilitate")
    if TIMER:shouldRun("GCD_DEBILITATE") and (Debilitate.id ~= 0 and Debilitate.cooldown_timer < 1) then
        API.logWarn("[COMBAT] Using Debilitate")
        API.DoAction_Ability_Direct(Debilitate, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_DEBILITATE",1500)
        return true
    else
        return false
    end
end

---@return boolean
function COMBAT.resonance()
    local Resonance = API.GetABs_name1("Resonance")
    if TIMER:shouldRun("GCD_RESONANCE") and (Resonance.id ~= 0 and Resonance.cooldown_timer < 1) then
        API.logWarn("[COMBAT] Using Resonance")
        API.DoAction_Ability_Direct(Resonance, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:createSleep("GCD_RESONANCE",1500)
        return true
    else
        return false
    end
end

function COMBAT.healthCheck(teleportOut)
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
    elseif TIMER:shouldRun("EAT") and hp < 40 and eatFoodAB.id ~= 0 and eatFoodAB.enabled then
        API.logDebug("[COMBAT] Eating")
        API.DoAction_Ability_Direct(eatFoodAB, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:randomThreadedSleep("EAT",1800,1850)
    elseif TIMER:shouldRun("DRINK") and hp < 30 and brew.id ~= 0 and brew.enabled then
        API.logDebug("[COMBAT] Drinking Saradomin Brew")
        API.DoAction_Ability_Direct(brew, 1, API.OFF_ACT_GeneralInterface_route)
        TIMER:randomThreadedSleep("DRINK",1800,1850)
    elseif TIMER:shouldRun("COMBAT_TELEPORT") and teleport and hp < 15 then
        API.logDebug("[COMBAT] Teleporting away")
        TIMER:createSleep("COMBAT_TELEPORT",3000)
        COMBAT.reset(true)

    end
end

----------------------------------------------------------------- WAR'S RETREAT STUFF --------------------------------------------------------------------

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
        COMBAT.disablePrayer()
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
    COMBAT.retreatTeleport()
    API.RandomSleep2(1200,100,200)
    COMBAT.doPrayer()
    COMBAT.doBank(BoB)
    COMBAT.doAdrenaline()
end

----------------------------------------------------------- UTILITIES ----------------------------------------------------------------

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

return COMBAT