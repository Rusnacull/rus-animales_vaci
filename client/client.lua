local QRCore = exports['qr-core']:GetCoreObject()
isLoggedIn = false
local isBusy = false
PlayerJob = {}

RegisterNetEvent('QRCore:Client:OnPlayerLoaded')
AddEventHandler('QRCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    PlayerJob = QRCore.Functions.GetPlayerData().job
end)

RegisterNetEvent('QRCore:Client:OnJobUpdate')
AddEventHandler('QRCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

local SpawnedVaci = {}
local InteractedVaci = nil
local HarvestedVaci = {}
local canHarvest = true
local closestVaci = nil
local isDoingAction = false

Citizen.CreateThread(function()
    while true do
    Wait(150)

    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local inRange = false

    for i = 1, #Config.Vaci do
        local dist = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config.Vaci[i].x, Config.Vaci[i].y, Config.Vaci[i].z, true)

		if dist < 50.0 then
			inRange = true
			local hasSpawned = false
			local needsUpgrade = false
			local upgradeId = nil
			local tableRemove = nil

			for z = 1, #SpawnedVaci do
				local p = SpawnedVaci[z]
				if p.id == Config.Vaci[i].id then
					hasSpawned = true
				end
			end

			if not hasSpawned then
				local hash = GetHashKey('a_c_cow')
				while not HasModelLoaded(hash) do
					Wait(10)
					RequestModel(hash)
				end
				RequestModel(hash)
				local data = {}
				data.id = Config.Vaci[i].id
				data.obj = CreatePed(hash, Config.Vaci[i].x, Config.Vaci[i].y, Config.Vaci[i].z -1.0, 200, false, true, true, true)
				Citizen.InvokeNative(0x283978A15512B2FE, data.obj, true) -- SetRandomOutfitVariation
				SetEntityNoCollisionEntity(PlayerPedId(), data.obj, false)
				SetEntityCanBeDamaged(data.obj, false)
				SetEntityInvincible(data.obj, true)
				Wait(1000)
				FreezeEntityPosition(data.obj, true) -- NPC can't escape
				SetBlockingOfNonTemporaryEvents(data.obj, true) -- NPC can't be scared
				table.insert(SpawnedVaci, data)
				hasSpawned = false
			end
		end
    end
    if not InRange then
        Wait(5000)
    end
    end
end)

-- destroy plant
function DestroyVaci()
	--print("Sterg vaca")
    local plant = GetClosestVaci()
    local hasDone = false

    for k, v in pairs(HarvestedVaci) do
        if v == plant.id then
            hasDone = true
        end
    end

    if not hasDone then
        table.insert(HarvestedVaci, plant.id)
        local ped = PlayerPedId()
        isDoingAction = true
        TriggerServerEvent('rus-animales_vaci:server:plantHasBeenHarvested', plant.id)
		TaskStartScenarioInPlace(ped, `WORLD_HUMAN_CROUCH_INSPECT`, 0, true)
		Wait(5000)
		ClearPedTasks(ped)
		SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
		TriggerServerEvent('rus-animales_vaci:server:destroyVaci', plant.id)
		isDoingAction = false
		canHarvest = true
    else
		QRCore.Functions.Notify('error', 'error')
    end
end

-- havest vaci
function HarvestVaci()
	--print("Colectez vaca")
    local plant = GetClosestVaci()
    local hasDone = false

    for k, v in pairs(HarvestedVaci) do
        if v == plant.id then
            hasDone = true
        end
    end

    if not hasDone then
        table.insert(HarvestedVaci, plant.id)
        local ped = PlayerPedId()
        isDoingAction = true
        TriggerServerEvent('rus-animales_vaci:server:plantHasBeenHarvested', plant.id)
		TaskStartScenarioInPlace(ped, `WORLD_HUMAN_CROUCH_INSPECT`, 0, true)
		Wait(10000)
		ClearPedTasks(ped)
		SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
		--print("Culeg")
		TriggerServerEvent('rus-animales_vaci:server:harvestVaci', plant.id)
		isDoingAction = false
		canHarvest = true
    else
		QRCore.Functions.Notify('error', 'error')
    end
end

function RemoveVaciFromTable(plantId)
    for k, v in pairs(Config.Vaci) do
        if v.id == plantId then
            table.remove(Config.Vaci, k)
        end
    end
end

-- trigger actions
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
		local InRange = false
		local ped = PlayerPedId()
		local pos = GetEntityCoords(ped)

		for k, v in pairs(Config.Vaci) do
			if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, v.x, v.y, v.z, true) < 1.3 and not isDoingAction and not v.beingHarvested and not IsPedInAnyVehicle(PlayerPedId(), false) then
				if PlayerJob.name == 'police' then
					local plant = GetClosestVaci()
					DrawText3D(v.x, v.y, v.z, 'Vaca: ' .. v.labelos)
					DrawText3D(v.x, v.y, v.z - 0.18, 'Apa: ' .. v.thirst .. '% - Mancare: ' .. v.hunger .. '%')
					DrawText3D(v.x, v.y, v.z - 0.36, 'Crestere: ' ..  v.growth .. '% -  Fericire: ' .. v.quality.. '%')
					DrawText3D(v.x, v.y, v.z - 0.54, 'Confisca Vaca [G]')
					if IsControlJustPressed(0, QRCore.Shared.Keybinds['G']) then
						if v.id == plant.id then
							DestroyVaci()
						end
					end
				else
					if v.growth < 100 then
						local plant = GetClosestVaci()
						DrawText3D(v.x, v.y, v.z, 'Vaca: ' .. v.labelos)
						DrawText3D(v.x, v.y, v.z - 0.18, 'Apa: ' .. v.thirst .. '% - Mancare: ' .. v.hunger .. '%')
						DrawText3D(v.x, v.y, v.z - 0.36, 'Crestere: ' ..  v.growth .. '% -  Fericire: ' .. v.quality.. '%')
						DrawText3D(v.x, v.y, v.z - 0.54, 'Dai Apa [G] : Dai de Mancare [J]')
						if IsControlJustPressed(0, QRCore.Shared.Keybinds['G']) then
							if v.id == plant.id then
								TriggerEvent('rus-animales_vaci:client:waterVaci')
							end
						elseif IsControlJustPressed(0, QRCore.Shared.Keybinds['J']) then
							if v.id == plant.id then
								TriggerEvent('rus-animales_vaci:client:feedVaci')
							end
						end
					else
						DrawText3D(v.x, v.y, v.z, 'Vaca: ' .. v.labelos)
						DrawText3D(v.x, v.y, v.z - 0.18, '[Fericire: ' .. v.quality .. ']')
						DrawText3D(v.x, v.y, v.z - 0.36, 'Colecteaza [E]')

						if IsControlJustReleased(0, QRCore.Shared.Keybinds['E']) and canHarvest then
							local plant = GetClosestVaci()
							local callpolice = math.random(1,100)
							if v.id == plant.id then
								HarvestVaci()
								if callpolice > 95 then
									local coords = GetEntityCoords(PlayerPedId())
									-- alert police action here
								end
							end
						end
					end
				end
			end
		end
    end
end)

function GetClosestVaci()
    local dist = 1000
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local plant = {}
    for i = 1, #Config.Vaci do
        local xd = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config.Vaci[i].x, Config.Vaci[i].y, Config.Vaci[i].z, true)
        if xd < dist then
            dist = xd
            plant = Config.Vaci[i]
        end
    end
    return plant
end

RegisterNetEvent('rus-animales_vaci:client:removeVaciObject')
AddEventHandler('rus-animales_vaci:client:removeVaciObject', function(plant)
    for i = 1, #SpawnedVaci do
        local o = SpawnedVaci[i]
        if o.id == plant then
			SetEntityAsMissionEntity(o.obj, false)
            FreezeEntityPosition(o.obj, false)
			SetEntityInvincible(o.obj, false)
			Wait(60000)
			if o.obj then
			DeleteEntity(o.obj)
			end
        end
    end
end)

-- water vaci
RegisterNetEvent('rus-animales_vaci:client:waterVaci')
AddEventHandler('rus-animales_vaci:client:waterVaci', function()
    local entity = nil
    local plant = GetClosestVaci()
    local ped = PlayerPedId()
    isDoingAction = true
    for k, v in pairs(SpawnedVaci) do
        if v.id == plant.id then
            entity = v.obj
        end
    end
	local hasItem = QRCore.Functions.HasItem('wateringcan', 1)
	if hasItem then
		Citizen.InvokeNative(0x5AD23D40115353AC, ped, entity, -1)
		TaskStartScenarioInPlace(ped, `WORLD_HUMAN_CROUCH_INSPECT`, 0, true)
		Wait(10000)
		ClearPedTasks(ped)
		SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
		TriggerServerEvent('rus-animales_vaci:server:waterVaci', plant.id)
		isDoingAction = false
	else
		QRCore.Functions.Notify('Nu ai Adus apa ce vrei sa ii dai sa bea?', 'error')
		Wait(5000)
		isDoingAction = false
	end
end)

-- feed vaci
RegisterNetEvent('rus-animales_vaci:client:feedVaci')
AddEventHandler('rus-animales_vaci:client:feedVaci', function()
    local entity = nil
    local plant = GetClosestVaci()
    local ped = PlayerPedId()
    isDoingAction = true
    for k, v in pairs(SpawnedVaci) do
        if v.id == plant.id then
            entity = v.obj
        end
    end
	local hasItem = QRCore.Functions.HasItem('wheat', 1)
	if hasItem then
		Citizen.InvokeNative(0x5AD23D40115353AC, ped, entity, -1)
		TaskStartScenarioInPlace(ped, `WORLD_HUMAN_FEED_CHICKEN`, 0, true)
		Wait(14000)
		ClearPedTasks(ped)
		SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
		TriggerServerEvent('rus-animales_vaci:server:feedVaci', plant.id)
		isDoingAction = false
	else
		QRCore.Functions.Notify('Nu ai Grau la tine !', 'error')
		Wait(5000)
		isDoingAction = false
	end
end)

RegisterNetEvent('rus-animales_vaci:client:updateVaciData')
AddEventHandler('rus-animales_vaci:client:updateVaciData', function(data)
    Config.Vaci = data
end)

RegisterNetEvent('rus-animales_vaci:client:plantNewSeed')
AddEventHandler('rus-animales_vaci:client:plantNewSeed', function(type, labelos)
    local pos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.5, 0.0)
	local ped = PlayerPedId()
    if CanVaciSeedHere(pos) and not IsPedInAnyVehicle(PlayerPedId(), false) then
		TaskStartScenarioInPlace(ped, `WORLD_HUMAN_CROUCH_INSPECT`, 0, true)
		Wait(10000)
		ClearPedTasks(ped)
		SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
		TaskStartScenarioInPlace(ped, `WORLD_HUMAN_CROUCH_INSPECT`, 0, true)
		Wait(20000)
		ClearPedTasks(ped)
		SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
		TriggerServerEvent('rus-animales_vaci:server:plantNewSeed', type, pos, labelos)
    else
		QRCore.Functions.Notify('Mult prea aproape de alt animal!', 'error')
		TriggerServerEvent('rus-animales_vaci:server:giveSeed')
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
    SetTextScale(0.25, 0.25)
    SetTextFontForCurrentCommand(9)
    SetTextColor(255, 255, 255, 215)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    SetTextCentre(1)
    DisplayText(str,_x,_y)
end

function CanVaciSeedHere(pos)
    local canVaci = true

    for i = 1, #Config.Vaci do
        if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config.Vaci[i].x, Config.Vaci[i].y, Config.Vaci[i].z, true) < 1.3 then
            canVaci = false
        end
    end

    return canVaci
end

----------------------------------------------------------------------------------------------



---Culege Fetilizant

RegisterNetEvent('rus-animales_vaci:client:CulegeFetilizant')
AddEventHandler('rus-animales_vaci:client:CulegeFetilizant', function()
	local ped = PlayerPedId()

	isDoingAction = true

	local hasItem = QRCore.Functions.HasItem('grebla', 1)
	if hasItem then
		Citizen.InvokeNative(0x5AD23D40115353AC, ped, entity, -1)
		TaskStartScenarioInPlace(ped, `WORLD_HUMAN_FARMER_RAKE`, 0, true)
		Wait(20000)

		ClearPedTasks(ped)
		SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
		TriggerServerEvent('rus-animales_vaci:server:CulegeFertilizant')
		isDoingAction = false
	else
		QRCore.Functions.Notify(' Nu ai grebla la tine !!!', 'error')
		Wait(5000)
		isDoingAction = false
	end


end)






