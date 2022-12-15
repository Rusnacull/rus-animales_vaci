local QRCore = exports['qr-core']:GetCoreObject()
local VaciLoaded = false

-- use seed
QRCore.Functions.CreateUseableItem("vaca", function(source, item)
    local src = source
    local Player = QRCore.Functions.GetPlayer(src)
    local sansa = math.random(1,3)
    --print("sa punem vaca")
    if sansa == 1 then
        TriggerClientEvent('rus-animales_vaci:client:plantNewSeed', src, 'lapte_vaca', 'Mica')
        Player.Functions.RemoveItem('vaca', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items['vaca'], "remove")
    elseif sansa == 2 then
        TriggerClientEvent('rus-animales_vaci:client:plantNewSeed', src, 'lapte_vaca', 'Medie')
        Player.Functions.RemoveItem('vaca', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items['vaca'], "remove")
    else
        TriggerClientEvent('rus-animales_vaci:client:plantNewSeed', src, 'lapte_vaca', 'Mare')
        Player.Functions.RemoveItem('vaca', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items['vaca'], "remove")
    end

end)


Citizen.CreateThread(function()
    while true do
        Wait(5000)
        if VaciLoaded then
            TriggerClientEvent('rus-animales_vaci:client:updateVaciData', -1, Config.Vaci)
        end
    end
end)

Citizen.CreateThread(function()
    TriggerEvent('rus-animales_vaci:server:getVaci')
    VaciLoaded = true
end)

RegisterServerEvent('rus-animales_vaci:server:saveVaci')
AddEventHandler('rus-animales_vaci:server:saveVaci', function(data, plantId)
    local data = json.encode(data)
    MySQL.Async.execute('INSERT INTO animale_private_vaci (properties, plantid) VALUES (@properties, @plantid)', {
        ['@properties'] = data,
        ['@plantid'] = plantId
    })
end)

-- give seed
RegisterServerEvent('rus-animales_vaci:server:giveSeed')
AddEventHandler('rus-animales_vaci:server:giveSeed', function()
    local src = source
    local Player = QRCore.Functions.GetPlayer(src)
    Player.Functions.AddItem('vaca', math.random(1, 2))
    TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items['vaca'], "add")
end)

-- plant seed
RegisterServerEvent('rus-animales_vaci:server:plantNewSeed')
AddEventHandler('rus-animales_vaci:server:plantNewSeed', function(type, location, labelos)
    local src = source
    local plantId = math.random(111111, 999999)
    local Player = QRCore.Functions.GetPlayer(src)
    local SeedData = {
        id = plantId,
        type = type,
        labelos = labelos,
        x = location.x,
        y = location.y,
        z = location.z,
        hunger = Config.StartingHunger,
        thirst = Config.StartingThirst,
        growth = 0.0,
        quality = 100.0,
        grace = true,
        beingHarvested = false,
        planter = Player.PlayerData.citizenid
    }

    local VaciCount = 0

    for k, v in pairs(Config.Vaci) do
        if v.planter == Player.PlayerData.citizenid then
            VaciCount = VaciCount + 1
        end
    end

    if VaciCount >= Config.MaxVaciCount then
		TriggerClientEvent('QRCore:Notify', src, 'Deja ai : ' .. Config.MaxVaciCount .. ' din cate poti pune', 'error')
    else
        table.insert(Config.Vaci, SeedData)
        TriggerEvent('rus-animales_vaci:server:saveVaci', SeedData, plantId)
        TriggerEvent('rus-animales_vaci:server:updateVaci')
    end
end)

-- check plant
RegisterServerEvent('rus-animales_vaci:server:plantHasBeenHarvested')
AddEventHandler('rus-animales_vaci:server:plantHasBeenHarvested', function(plantId)
    for k, v in pairs(Config.Vaci) do
        if v.id == plantId then
            v.beingHarvested = true
        end
    end
    TriggerEvent('rus-animales_vaci:server:updateVaci')
end)

-- distory plant (police)
RegisterServerEvent('rus-animales_vaci:server:destroyVaci')
AddEventHandler('rus-animales_vaci:server:destroyVaci', function(plantId)
    local src = source
    local Player = QRCore.Functions.GetPlayer(src)
    for k, v in pairs(Config.Vaci) do
        if v.id == plantId then
            table.remove(Config.Vaci, k)
        end
    end
	TriggerClientEvent('rus-animales_vaci:client:removeVaciObject', src, plantId)
	TriggerEvent('rus-animales_vaci:server:VaciRemoved', plantId)
	TriggerEvent('rus-animales_vaci:server:updateVaci')
	TriggerClientEvent('QRCore:Notify', src, 'ai luat vaca', 'success')
end)

-- harvest plant
RegisterServerEvent('rus-animales_vaci:server:harvestVaci')
AddEventHandler('rus-animales_vaci:server:harvestVaci', function(plantId)
    local src = source
    local Player = QRCore.Functions.GetPlayer(src)
    local amount
    local label
    local item
	local poorQuality = false
    local goodQuality = false
	local exellentQuality = false
    local hasFound = false
    --print("Culeg din server")
    for k, v in pairs(Config.Vaci) do
        if v.id == plantId then
            print(plantId)
            for y = 1, #Config.YieldRewards do
                print(Config.YieldRewards)
                if v.type == Config.YieldRewards[y].type then
                    label = Config.YieldRewards[y].labelos
                    item = Config.YieldRewards[y].item
                    amount = math.random(Config.YieldRewards[y].rewardMin, Config.YieldRewards[y].rewardMax)
                    local quality = math.ceil(v.quality)
                    hasFound = true
                    table.remove(Config.Vaci, k)
					if quality > 0 and quality < 65 then -- poor
                        poorQuality = true
					elseif quality >= 65 and quality < 85 then -- good
						goodQuality = true
					elseif quality >= 85 then -- excellent
						exellentQuality = true
                    end
                end
            end
        end
    end
	-- give rewards

    if hasFound then
        --print("Culeg si dau produse")
        if poorQuality then
			local pooramount = math.random(1,3)
			Player.Functions.AddItem(item, pooramount)
			TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items[item], "add")

			Player.Functions.SetMetaData("repfermier", Player.PlayerData.metadata["repfermier"] + pooramount)
			Wait(5000)
			TriggerEvent('rus-animales_vaci:server:repfermier', src)
        elseif goodQuality then
			local goodamount = math.random(3,6)
			Player.Functions.AddItem(item, goodamount)
			TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items[item], "add")

			Player.Functions.SetMetaData("repfermier", Player.PlayerData.metadata["repfermier"] + goodamount)
			Wait(5000)
			TriggerEvent('rus-animales_vaci:server:repfermier', src)
		elseif exellentQuality then
			local exellentamount = math.random(6,12)
			Player.Functions.AddItem(item, exellentamount)
			TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items[item], "add")
			Player.Functions.AddItem('vaca', 1)
			TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items[item], "add")

			Player.Functions.SetMetaData("repfermier", Player.PlayerData.metadata["repfermier"] + exellentamount)
			Wait(5000)
			TriggerEvent('rus-animales_vaci:server:repfermier', src)
		else
			print("Ceva este in neregula cod24361 rus-animales_vaci 193!")
        end
		TriggerClientEvent('rus-animales_vaci:client:removeVaciObject', src, plantId)
        TriggerEvent('rus-animales_vaci:server:VaciRemoved', plantId)
        TriggerEvent('rus-animales_vaci:server:updateVaci')
    end
end)

RegisterServerEvent('rus-animales_vaci:server:updateVaci')
AddEventHandler('rus-animales_vaci:server:updateVaci', function()
	local src = source
    TriggerClientEvent('rus-animales_vaci:client:updateVaciData', src, Config.Vaci)
end)

-- water plant
RegisterServerEvent('rus-animales_vaci:server:waterVaci')
AddEventHandler('rus-animales_vaci:server:waterVaci', function(plantId)
    local src = source
    local Player = QRCore.Functions.GetPlayer(src)
    for k, v in pairs(Config.Vaci) do
        if v.id == plantId then
            Config.Vaci[k].thirst = Config.Vaci[k].thirst + Config.ThirstIncrease
            if Config.Vaci[k].thirst > 100.0 then
                Config.Vaci[k].thirst = 100.0
            end
        end
    end
    Player.Functions.RemoveItem('wateringcan', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items['wateringcan'], "add")
    Wait(2000)
    Player.Functions.AddItem('wateringcan_goala', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items['wateringcan_goala'], "add")
    
    
    
    TriggerEvent('rus-animales_vaci:server:updateVaci')
end)

-- feed plant
RegisterServerEvent('rus-animales_vaci:server:feedVaci')
AddEventHandler('rus-animales_vaci:server:feedVaci', function(plantId)
    local src = source
    local Player = QRCore.Functions.GetPlayer(src)
    for k, v in pairs(Config.Vaci) do
        if v.id == plantId then
            Config.Vaci[k].hunger = Config.Vaci[k].hunger + Config.HungerIncrease
            if Config.Vaci[k].hunger > 100.0 then
                Config.Vaci[k].hunger = 100.0
            end
        end
    end
    Player.Functions.RemoveItem('corn', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items['corn'], "remove")
    TriggerEvent('rus-animales_vaci:server:updateVaci')
end)

-- update plant
RegisterServerEvent('rus-animales_vaci:server:updateIndianVaci')
AddEventHandler('rus-animales_vaci:server:updateIndianVaci', function(id, data)
    local result = MySQL.query.await('SELECT * FROM animale_private_vaci WHERE plantid = @plantid', {
        ['@plantid'] = id
    })
    if result[1] then
        local newData = json.encode(data)
        MySQL.Async.execute('UPDATE animale_private_vaci SET properties = @properties WHERE plantid = @id', {
            ['@properties'] = newData,
            ['@id'] = id
        })
    end
end)

-- remove plant
RegisterServerEvent('rus-animales_vaci:server:VaciRemoved')
AddEventHandler('rus-animales_vaci:server:VaciRemoved', function(plantId)
    local result = MySQL.query.await('SELECT * FROM animale_private_vaci')
    if result then
        for i = 1, #result do
            local plantData = json.decode(result[i].properties)
            if plantData.id == plantId then
                MySQL.Async.execute('DELETE FROM animale_private_vaci WHERE id = @id', {
                    ['@id'] = result[i].id
                })
                for k, v in pairs(Config.Vaci) do
                    if v.id == plantId then
                        table.remove(Config.Vaci, k)
                    end
                end
            end
        end
    end
end)

-- get plant
RegisterServerEvent('rus-animales_vaci:server:getVaci')
AddEventHandler('rus-animales_vaci:server:getVaci', function()
    local data = {}
    local result = MySQL.query.await('SELECT * FROM animale_private_vaci')
    if result[1] then
        for i = 1, #result do
            local plantData = json.decode(result[i].properties)
            print('Incarc Vacile cu ID: '..plantData.id)
            table.insert(Config.Vaci, plantData)
        end
    end
end)

-- plant timer
Citizen.CreateThread(function()
    while true do
        Wait(Config.GrowthTimer*60)
        for i = 1, #Config.Vaci do
            if Config.Vaci[i].growth < 100 then
                if Config.Vaci[i].grace then
                    Config.Vaci[i].grace = false
                else
                    Config.Vaci[i].thirst = Config.Vaci[i].thirst - 0.5
                    Config.Vaci[i].hunger = Config.Vaci[i].hunger - 0.5
                    Config.Vaci[i].growth = Config.Vaci[i].growth + 1

                    if Config.Vaci[i].quality > 100 then
                        Config.Vaci[i].quality = 100
                    end

                    if Config.Vaci[i].growth > 100 then
                        Config.Vaci[i].growth = 100
                    end

                    if Config.Vaci[i].hunger < 0 then
                        Config.Vaci[i].hunger = 0
                    end

                    if Config.Vaci[i].thirst < 0 then
                        Config.Vaci[i].thirst = 0
                    end

                    if Config.Vaci[i].quality < 25 then
                        Config.Vaci[i].quality = 25
                    end

                    if Config.Vaci[i].thirst < 85 or Config.Vaci[i].hunger < 85 then
                        Config.Vaci[i].quality = Config.Vaci[i].quality - 0.5
                    end

                    if Config.Vaci[i].thirst > 90 and Config.Vaci[i].hunger > 90 and Config.Vaci[i].quality < 100 then
                        Config.Vaci[i].quality = Config.Vaci[i].quality + 4
                        Config.Vaci[i].growth = Config.Vaci[i].growth + 4
                    end
                end
            end
            TriggerEvent('rus-animales_vaci:server:updateIndianVaci', Config.Vaci[i].id, Config.Vaci[i])
        end
        TriggerEvent('rus-animales_vaci:server:updateVaci')
    end
end)

-- used by harvest to show new dealer reputation
RegisterServerEvent('rus-animales_vaci:server:repfermier')
AddEventHandler('rus-animales_vaci:server:repfermier', function(source)
    local src = source
	local Player = QRCore.Functions.GetPlayer(src)
	local curRep = Player.PlayerData.metadata["repfermier"]
	TriggerClientEvent('QRCore:Notify', src, 'Ai Crescut Reputatia cu '.. curRep, 'primary')
end)



RegisterNetEvent('rus-animales_vaci:server:CulegeFertilizant', function()
    local src = source
    local Player = QRCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveItem("wateringcan_goala", 1) then
            Player.Functions.AddItem('fertilizer', 1)
            TriggerClientEvent("inventory:client:ItemBox", src, QRCore.Shared.Items["fertilizer"], "add")
    else
        TriggerClientEvent('QRCore:Notify', src, "Nu ai galeata in ce vrei sa strangi Fetilizantul", 'error')
    end
end)








