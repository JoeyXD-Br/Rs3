local API = require("api")
local COMBAT = require("lib.combat")


API.Write_LoopyLoop(true)
API.SetDrawTrackedSkills(true)
API.SetDrawLogs(true)
Write_fake_mouse_do(false)
API.SetMaxIdleTime(6)

COMBAT.necroOpener(false)
while API.Read_LoopyLoop() do
    if API.LocalPlayer_IsInCombat_() then
        COMBAT.healthCheck(false)
        COMBAT.prayerCheck()
        COMBAT.doRotationNecro(true)
        COMBAT.prayAgainstAnimation(30629,35832,"Range",1000)
        COMBAT.prayAgainstAnimation(30629,35831,"Necro",1000)
        COMBAT.prayAgainstAnimation(30629,35833,"Melee",1000)
        COMBAT.prayAgainstAnimation(30629,-1,"SoulSplit",0)  
    end
    API.RandomSleep2(50,0,0)
end

