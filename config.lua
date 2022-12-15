Config = Config or {}
Config.Vaci = {}

-- start plant settings
Config.GrowthTimer = 1000 --  1000 = 1 minut
Config.StartingThirst = math.random(70.0,100.0) -- starting plan thirst percentage
Config.StartingHunger = math.random(70.0,100.0) -- starting plan hunger percentage
Config.HungerIncrease = 30.0 -- amount increased when watered
Config.ThirstIncrease = 30.0 -- amount increased when fertilizer is used
Config.Degrade = {min = 1, max = 5}
Config.QualityDegrade = {min = 2, max = 12}
Config.GrowthIncrease = {min = 10, max = 20}
Config.MaxVaciCount = 2 -- maximum plants play can have at any one time
Config.DrugEffect = false -- true/false if you want to have drug effect occur
Config.DrugEffectTime = 300000 -- drug effect time in milliseconds
Config.YieldRewards = {
    {type = "lapte_vaca",            rewardMin = 1, rewardMax = 3, 	    item = 'lapte_vaca',        labelos = 'Mica'},
    {type = "lapte_vaca",            rewardMin = 3, rewardMax = 6, 	    item = 'lapte_vaca',        labelos = 'Media'},
    {type = "lapte_vaca",            rewardMin = 6, rewardMax = 12, 	item = 'lapte_vaca',        labelos = 'Mare'},

}
-- end plant settings
