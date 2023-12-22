local QBCore = exports['qb-core']:GetCoreObject()

local rewardTable = {
    [1] = "metalscrap",
    [2] = "plastic",
    [3] = "copper",
    [4] = "iron",
    [5] = "aluminum",
    [6] = "steel",
    [7] = "glass"
}

--- Returns a random license plate and checks for duplicates
local GeneratePlate = function()
    local plate = QBCore.Shared.RandomInt(1)..QBCore.Shared.RandomStr(2)..QBCore.Shared.RandomInt(3)..QBCore.Shared.RandomStr(2)
    local result = MySQL.Sync.fetchScalar('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
    if result then
        return GeneratePlate()
    else
        return plate:upper()
    end
end

RegisterNetEvent('caticus-chopshop:server:Reward', function(type)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if type == 'door' then
        local rndm = math.random(3) -- 3 item drops
        for i=1, rndm do
            local randItem = rewardTable[math.random(#rewardTable)]
            local amount = math.random(8, 12) -- amount is between 8 and 12
            Player.Functions.AddItem(randItem, amount, false)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[randItem], "add", amount)
            Wait(250)
        end
    elseif type == 'hood' then
        local rndm = math.random(6)
        for i=1, rndm do
            local randItem = rewardTable[math.random(#rewardTable)]
            local amount = math.random(8, 12)
            Player.Functions.AddItem(randItem, amount, false)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[randItem], "add", amount)
            Wait(250)
        end
    elseif type == 'wheel' then
        local rndm = math.random(3)
        for i=1, rndm do
            local randItem = rewardTable[math.random(#rewardTable)]
            local amount = math.random(8, 12)
            Player.Functions.AddItem(randItem, amount, false)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[randItem], "add", amount)
            Wait(250)
        end
    elseif type == 'trunk' then
        local rndm = math.random(6)
        for i=1, rndm do
            local randItem = rewardTable[math.random(#rewardTable)]
            local amount = math.random(8, 12)
            Player.Functions.AddItem(randItem, amount, false)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[randItem], "add", amount)
            Wait(250)
        end
    elseif type == 'cash' then
        local payout = math.random(810, 2190) -- cash payout between 810 and 2.190
        Player.Functions.AddMoney('cash', payout, 'chopshop-reward')
    end
end)




RegisterNetEvent('caticus-chopshop:server:DeleteVehicle', function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
	DeleteEntity(vehicle)
end)

QBCore.Functions.CreateCallback('caticus-chopshop:server:GetPlate', function(source, cb)
    local plate = GeneratePlate()
    cb(plate)
end)

QBCore.Functions.CreateCallback('caticus-chopshop:server:SpawnVehicle', function(source, cb, model, loc, plate)
    local veh = CreateVehicle(model, loc.x, loc.y, loc.z, loc.w, true, false)
    SetVehicleNumberPlateText(veh, plate)
    SetVehicleDoorsLocked(veh, 1)  -- Unlocking the vehicle
    while not DoesEntityExist(veh) do Wait(10) end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    cb(netId)
end)


CreateThread(function() -- This will check if all the vehicles in the config are in the QBCore Shared Vehicles
    Wait(1000)
    for i=1, #Shared.Vehicles do
        local veh = Shared.Vehicles[i]
        if not QBCore.Shared.Vehicles[veh] then
            print("^3[caticus-chopshop] ^5"..Shared.Vehicles[i].." is not in the QBCore Shared Vehicles!^7")
        end
    end
    print("^3[caticus-chopshop] ^5Done checking vehicles in config.^7")
end)

CreateThread(function() -- This deletes all old emails when the script starts (when the server starts up)
    if Shared.ClearMails then
        MySQL.Async.execute("DELETE FROM player_mails WHERE sender = ? AND subject = ?", {
            Shared.MailAuthor, 
            Shared.MailTitle
        })
        print("^3[caticus-chopshop] ^5Deleted old mails from database.^7")
    end
end)
