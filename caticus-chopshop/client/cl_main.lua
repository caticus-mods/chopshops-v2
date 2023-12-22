local QBCore = exports['qb-core']:GetCoreObject()

local queued = false

local areaZone = nil
local areaBlip = nil
local blipOffset = 150.0

local chopVehicle = 0

local dropOffZone = nil
local dropOffBlip = nil

local vehMods = { -- You can add more here
    0, -- Spoiler
    1, -- Front Bumper
    2, -- Rear Bumper
    3, -- Skirt
    4, -- Exhaust
    5, -- Chassis
    6, -- Grill
    7, -- Bonnet
    8, -- Wing L
    9, -- Wing R
    10, -- Roof
    22 -- Xenon Lights
}


local LoadAnimationDict = function(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
end


local DrawText3Ds = function(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y+0.015, 0.015+ factor, 0.03, 41, 11, 41, 68)
end

local IsPlayerNearCoords = function(x, y, z)
    local playerx, playery, playerz = table.unpack(GetEntityCoords(PlayerPedId(), false))
    local dist = Vdist(playerx, playery, playerz, x, y, z)
    return dist < 1.5
end


--------------------------------------




local props = {} -- To store the spawned props



-- Function to spawn a car part in hand with adjusted position and rotation
local function SpawnCarPartInHand(partName)
    local playerPed = PlayerPedId()
    local boneIndex = GetPedBoneIndex(playerPed, 57005) -- Right Hand Bone
    local prop = CreateObject(GetHashKey(partName), 0, 0, 0, true, true, true)
    
    -- Adjusted offset values for positioning the door to the left
    local xOffset, yOffset, zOffset = 0.1, 0.5, -0.3  -- Increase xOffset to move it more to the left
    local xRot, yRot, zRot = 0.0, 0.0, 90.0          -- Rotation for upright door

    AttachEntityToEntity(prop, playerPed, boneIndex, xOffset, yOffset, zOffset, xRot, yRot, zRot, true, true, false, true, 1, true)
    return prop
end

-- Function to remove all spawned props
local function CleanupProps()
    for _, prop in ipairs(props) do
        if DoesEntityExist(prop) then
            DeleteObject(prop)
        end
    end
    props = {}
end
local function DrawMarkerAtLocation(coords)
    DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 100, false, true, 2, false, nil, nil, false)
end

local prop
local propModel = `prop_byard_machine02` -- Model name of the prop
local spawnCoords = vector4(2354.74, 3128.87, 47.21, 345.6) -- Coordinates with heading

CreateThread(function()
    -- Ensure the prop model is loaded
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do
        Wait(1)
    end

    -- Create the prop at the specified location with the given heading
    prop = CreateObject(propModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, true)
    SetEntityHeading(prop, spawnCoords.w)

    -- Make the prop static (unmovable)
    FreezeEntityPosition(prop, true)

    -- Main loop for the marker and interaction
    while true do
        Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z)) < 1.5 then
            --DrawMarkerAtLocation(vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z))
            DrawText3Ds(spawnCoords.x, spawnCoords.y, spawnCoords.z, "Press [~g~E~w~] to drop off the part")
            if IsControlJustReleased(1, 38) then -- 38 is E key
                CleanupProps()
                ClearPedTasks(PlayerPedId())
            end
        end
    end
end)





local ChopVehicle = function(veh)
    local ped = PlayerPedId()

    TaskLeaveVehicle(ped, veh, 0)
    FreezeEntityPosition(veh, true)
    Wait(1500)

    local chopParts = {
        { part = 0, bone = 'door_dside_f', text = 'Front Left Door', prop = "prop_car_door_01" },
        { part = 2, bone = 'door_dside_r', text = 'Rear Left Door', condition = function(v) return GetVehicleMaxNumberOfPassengers(v) > 1 end, prop = "prop_car_door_01" },
        { part = 3, bone = 'door_pside_r', text = 'Rear Right Door', condition = function(v) return GetVehicleMaxNumberOfPassengers(v) > 1 end, prop = "prop_car_door_01" },
        { part = 1, bone = 'door_pside_f', text = 'Front Right Door', prop = "prop_car_door_01" },
        { part = 4, bone = 'bonnet', text = 'Hood', prop = "prop_car_bonnet_02" },
        { part = 0, bone = 'wheel_lf', text = 'Front Left Wheel', isWheel = true, prop = "prop_wheel_01" },
        { part = 4, bone = 'wheel_lr', text = 'Rear Left Wheel', isWheel = true, prop = "prop_wheel_01" },
        { part = 5, bone = 'wheel_rr', text = 'Rear Right Wheel', isWheel = true, prop = "prop_wheel_01" },
        { part = 1, bone = 'wheel_rf', text = 'Front Right Wheel', isWheel = true, prop = "prop_wheel_01" }
    }

    for _, partInfo in ipairs(chopParts) do
        if not partInfo.condition or partInfo.condition(veh) then
            local coords = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, partInfo.bone))
            
            while true do
                Wait(0)
                DrawText3Ds(coords.x, coords.y, coords.z, "Press [~g~E~w~] to chop ".. partInfo.text)
                if IsPlayerNearCoords(coords.x, coords.y, coords.z) and IsControlJustReleased(1, 38) then
                    break
                end
            end

            SetVehicleDoorOpen(veh, partInfo.part, false, false)
            TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_WELDING', 0, true)
            Wait(14000) -- Wait for welding animation to complete

            -- Clear the welding task
            ClearPedTasksImmediately(ped)

            -- Now spawn the prop and play box carry animation
            local prop = SpawnCarPartInHand(partInfo.prop)
            table.insert(props, prop)

            -- Load and play box carry animation
            RequestAnimDict("anim@heists@box_carry@")
            while not HasAnimDictLoaded("anim@heists@box_carry@") do
                Wait(100)
            end
            TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 50, 0, false, false, false)

            if partInfo.isWheel then
                SetVehicleTyreBurst(veh, partInfo.part, true, 1000.0)
            else
                SetVehicleDoorBroken(veh, partInfo.part, true)
            end

            TriggerServerEvent('caticus-chopshop:server:Reward', partInfo.text:gsub(" ", "_"):lower())
        end
    end

    -- Notification and cleanup
    TriggerEvent('QBCore:Notify', 'You have finished chopping', 'success')
    TriggerServerEvent('caticus-chopshop:server:Reward', 'cash')
    chopVehicle = 0
    Wait(5000)
    NetworkFadeOutEntity(veh, true, false)
    Wait(2000)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent("caticus-chopshop:server:DeleteVehicle", netId)
end


RegisterCommand('hoodtest', function()
    local playerPed = PlayerPedId()
    local prop = SpawnCarPartInHand("imp_prop_impexp_bonnet_02a") -- Change this to the desired hood prop name
    table.insert(props, prop)

    RequestAnimDict("anim@heists@box_carry@")
    while not HasAnimDictLoaded("anim@heists@box_carry@") do
        Wait(100)
    end
    TaskPlayAnim(playerPed, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 50, 0, false, false, false)
end, false)

RegisterCommand('doortest', function()
    local playerPed = PlayerPedId()
    local prop = SpawnCarPartInHand("prop_car_door_01")
    table.insert(props, prop)

    RequestAnimDict("anim@heists@box_carry@")
    while not HasAnimDictLoaded("anim@heists@box_carry@") do
        Wait(100)
    end
    TaskPlayAnim(playerPed, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 50, 0, false, false, false)
end, false)





local CreateAreaBlip = function(coords)
    local offsetSign = math.random(-100, 100)/100
    local blip = AddBlipForRadius(coords.x + (offsetSign*blipOffset), coords.y + (offsetSign*blipOffset), coords.z + (offsetSign*blipOffset), 250.00)
    SetBlipHighDetail(blip, true)
    SetBlipAlpha(blip, 100)
    SetBlipColour(blip, 2)
    return blip
end


local CreateDropOffBlip = function(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 227)
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 0.80)
    AddTextEntry('MYBLIP', "Dropoff Location")
    BeginTextCommandSetBlipName('MYBLIP')
    AddTextComponentSubstringPlayerName('Vehicle Drop off')
    EndTextCommandSetBlipName(blip)
    return blip
end


local SetRandomCosmetics = function(vehicle)
    -- Colours
    local c1, c2 = math.random(160), math.random(160)
    SetVehicleColours(vehicle, c1, c2)
    -- Cosmetics
    SetVehicleModKit(vehicle, 0)
    for i=1, #vehMods, 1 do
        local modAmount = GetNumVehicleMods(vehicle, vehMods[i])
        local rndm = math.random(modAmount)
        SetVehicleMod(vehicle, vehMods[i], rndm, false)
    end
end


local EnableUpgrades = function(vehicle)
    SetVehicleModKit(vehicle, 0)
    ToggleVehicleMod(vehicle, 18, true) -- Turbo
    SetVehicleMod(vehicle, 11, 2, false) -- Engine
    SetVehicleMod(vehicle, 12, 1, false) -- Brakes
    SetVehicleMod(vehicle, 13, 1, false) -- Transmission
end

local ReceiveMission = function()
    SetTimeout(math.random(2500, 4000), function()
        local charinfo = QBCore.Functions.GetPlayerData().charinfo
        local model = Shared.Vehicles[math.random(#Shared.Vehicles)]
        QBCore.Functions.TriggerCallback('caticus-chopshop:server:GetPlate', function(result)
            local plate = result
            -- Directly accept the mission
            TriggerEvent('caticus-chopshop:client:AcceptMission', { model = model, plate = plate })
        end)
    end)
end

RegisterNetEvent('caticus-chopshop:client:AcceptMission', function(data)
    local model = data.model
    local plate = data.plate
    

    -- Random Location
    local randLoc = math.random(#Shared.Locations)
    local vehLoc = Shared.Locations[randLoc]
    SetNewWaypoint(vehLoc.x, vehLoc.y)
    TriggerEvent('QBCore:Notify', 'A waypoint has been set to the search area.', 'success')
    -- ...
    
    -- Area Zone
    areaBlip = CreateAreaBlip(vehLoc)
    areaZone = CircleZone:Create(vehLoc, 200.00, {
        name = "chopshop_veharea",
        debugPoly = false
    })
    areaZone:onPlayerInOut(function(isPointInside, point)
        if isPointInside then
            -- Spawn Car
            QBCore.Functions.TriggerCallback('caticus-chopshop:server:SpawnVehicle', function(netId)
                while not NetworkDoesEntityExistWithNetworkId(netId) do Wait(10) end
                chopVehicle = NetworkGetEntityFromNetworkId(netId)
                SetRandomCosmetics(chopVehicle)
                EnableUpgrades(chopVehicle)
                SetVehicleDoorsLocked(chopVehicle, 1)  -- Locking the vehicle
            end, model, vehLoc, plate)
            -- Destroy Zone
            areaZone:destroy()
            -- Notify
            TriggerEvent('QBCore:Notify', 'find and steal the wanted vehicle', 'success')
        end
    end)
    
    -- Wait until car found
    local madeDropOffZone = false
    while not madeDropOffZone do
        Wait(1000)
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if GetVehicleNumberPlateText(veh) == plate then
            chopVehicle = veh
            --exports[Shared.FuelScript]:SetFuel(chopVehicle, 80.00)
            -- Alert Cops
            --TriggerEvent('QBCore:Notify', 'Brint it to the chop shop', 'success')
            RemoveBlip(areaBlip)
            madeDropOffZone = true
        end
    end

    -- Drop-off Zone
    local dropOffLoc = Shared.DropOffLocations[math.random(#Shared.DropOffLocations)]
    -- Set waypoint to the drop-off zone
    SetNewWaypoint(dropOffLoc.x, dropOffLoc.y)
    TriggerEvent('QBCore:Notify', 'Head to chop shop', 'success')

    dropOffBlip = CreateDropOffBlip(dropOffLoc)
    dropOffZone = CircleZone:Create(dropOffLoc, 4.0, {
        name = "chopshop_dropOffArea",
        debugPoly = false
    })

    local inZone = false
    dropOffZone:onPlayerInOut(function(isPointInside, point)
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if isPointInside then
            inZone = true
            if chopVehicle == veh then
                exports['qb-core']:DrawText('[E] - Chop Vehicle', 'left')
                -- E to start chopping vehicle
                CreateThread(function()
                    while inZone and chopVehicle == veh do
                        if IsControlJustPressed(0, 38) then
                            exports['qb-core']:HideText()
                            TriggerEvent('QBCore:Notify', 'Start chopping the vehicle', 'success')
                            dropOffZone:destroy()
                            RemoveBlip(dropOffBlip)
                            ChopVehicle(chopVehicle)
                            return
                        end
                        Wait(3)
                    end
                end)
            end
        else
            inZone = false
            exports['qb-core']:HideText()
        end
    end)
end)

RegisterNetEvent('caticus-chopshop:client:StartChopShop', function()
    queued = not queued
    if queued then 

        CreateThread(function()
            --Wait(Shared.Time*60*1000)
            if not queued then return end
            ReceiveMission()
            queued = false
        end)
    else
    end
end)

local pedCreated = false -- Add this line

CreateThread(function()
    if not pedCreated then -- Check if the ped hasn't been created yet
        exports['qb-target']:SpawnPed({
            model = 'ig_josef',
            coords = vector4(2339.44, 3051.93, 48.15, 273.39),
            minusOne = true,
            freeze = true,
            invincible = true,
            blockevents = true,
            scenario = '',
            target = {
                options = {
                    {
                        type = "client",
                        event = "caticus-chopshop:client:StartChopShop",
                        icon = 'fas fa-user-secret',
                        label = 'Start Chop Shop'
                    }
                },
                distance = 1.5
            },
        })
        pedCreated = true -- Set pedCreated to true to indicate that the ped has been created
    end
end)






