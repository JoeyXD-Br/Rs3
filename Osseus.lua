local API = require("api")
local COMBAT = require("lib.combat")
local TIMER = require("utilities.timer")


API.Write_LoopyLoop(true)
API.SetDrawTrackedSkills(true)
API.SetDrawLogs(true)
Write_fake_mouse_do(false)
API.SetMaxIdleTime(6)

---@param adds AllObject[]
---@return integer
local function checkNearbyAdds(adds,osseus)
    local addsNearby = 0
    if #adds > 0 then 
        for _ , add in ipairs(adds) do
            if API.Math_DistanceF(add.Tile_XYZ,osseus.Tile_XYZ) < 11 and add.Life > 0 then
                addsNearby = addsNearby + 1
            end
        end
    end
    return addsNearby
end

if not API.LocalPlayer_IsInCombat_() then
    COMBAT.necroOpener(false)
    COMBAT.quickPray()
end
local adds = {}
local osseus = {}
while API.Read_LoopyLoop() do
    if API.LocalPlayer_IsInCombat_() then
        adds = API.ReadAllObjectsArray({1},{30945},{})
        osseus = API.ReadAllObjectsArray({1},{30629},{})[1]
        if osseus ~= nil then
            TIMER:runScheduledTasks()
            if checkNearbyAdds(adds,osseus) > 1 or API.Buffbar_GetIDstatus(30129,false).found then -- Threads rotation
                if TIMER:shouldRunStartsWith("GCD") then
                    local threads = API.GetABs_name1("Threads of Fate")
                    local soulsap = API.GetABs_name1("Soul Sap")
                    local volley = API.GetABs_name1("Volley of Souls")
                    if not API.Buffbar_GetIDstatus(30129,false).found and threads.id ~= 0 and threads.cooldown_timer < 2 then
                        API.logWarn("Threads of Fate")
                        API.DoAction_Ability_Direct(threads, 1, API.OFF_ACT_GeneralInterface_route)
                        TIMER:createSleep("GCD",1700)
                    elseif API.Buffbar_GetIDstatus(30129,false).found and API.Buffbar_GetIDstatus(30123,false).conv_text == 3 and volley.enabled and volley.id ~= 0 then
                        API.logDebug("Volley of Souls")
                        API.DoAction_Ability_Direct(volley, 1, API.OFF_ACT_GeneralInterface_route)
                        TIMER:createSleep("GCD",1700)
                    elseif API.Buffbar_GetIDstatus(30129,false).found and soulsap.cooldown_timer < 2 and soulsap.enabled then
                        API.logDebug("Soul Sap")
                        API.DoAction_Ability_Direct(soulsap, 1, API.OFF_ACT_GeneralInterface_route) 
                        TIMER:createSleep("GCD",1700)
                    else
                        COMBAT.doRotationNecro(true)
                    end
                end
            elseif checkNearbyAdds(adds,osseus) > 0 and API.GetABs_name1("Threads of Fate").cooldown_timer > 0 and API.ReadTargetInfo(false).Target_Name == "Osseus" and TIMER:shouldRun("OSSEUS_SWAP") then
                API.DoAction_NPC(0x2a,API.OFF_ACT_AttackNPC_route,{ 30945 },50)
                TIMER:createSleep("OSSEUS_SWAP",2000)
            elseif checkNearbyAdds(adds,osseus) == 0 and API.ReadTargetInfo(false).Target_Name ~= "Osseus" and TIMER:shouldRun("OSSEUS_SWAP") then
                API.DoAction_NPC(0x2a,API.OFF_ACT_AttackNPC_route,{ 30629 },50)
                TIMER:createSleep("OSSEUS_SWAP",2000)
            else
                COMBAT.doRotationNecro(true)
            end
            if osseus.Anim == 35833 then
                    COMBAT.resonance()
                if API.Buffbar_GetIDstatus(14222,false).found then
                    COMBAT.disablePrayer(false)
                else
                    COMBAT.prayMelee()
                end
                TIMER:createSleep("OSSEUS_SLAM",10000)
            elseif osseus.Anim == 35835 and TIMER:shouldRun("OSSEUS_ROAR") then
                COMBAT.prayAgainstAnimation(30629,35835,"Melee",200,800,3000)
                TIMER:scheduleTask("OSSEUS_ANTICIPATION",5000,function () COMBAT.anticipation() end)
                TIMER:createSleep("OSSEUS_ROAR",20000)
            elseif osseus.Anim == 35821 and TIMER:shouldRun("OSSEUS_ROAR") and TIMER:shouldRun("OSSEUS_CHOMP") then
                TIMER:scheduleTask("OSSEUS_DIVE",7500,function ()
                    local safeTiles = API.Math_FreeTiles({osseus.Tile_XYZ},6,6,{},true)
                    if safeTiles[1] ~= nil then
                        local safeTile = WPOINT.new(math.floor(safeTiles[1].x),math.floor(safeTiles[1].y),safeTiles[1].z)
                        API.DoAction_Dive_Tile_sleep(safeTile,50)
                    end
                end)
                TIMER:createSleep("OSSEUS_CHOMP",10000)
            end
            COMBAT.healthCheck(false)
            COMBAT.prayerCheck()
            COMBAT.prayAgainstAnimation(30629,35832,"Range",1600,2400,3000)
            COMBAT.prayAgainstAnimation(30629,35831,"Necro",1600,2400,3000)
            
            COMBAT.prayAgainstAnimation(30629,-1,"SoulSplit",0)  
        end
    end
    API.RandomSleep2(50,0,0)
    
end

