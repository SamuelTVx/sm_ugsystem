local ESX = exports['es_extended']:getSharedObject()
math.randomseed(os.time())
local currentSpot = Config.DealerSpots[math.random(#Config.DealerSpots)]
print('^2[Underground]^7 Script restarted. Dealer location: ' .. currentSpot.locationName)
local sourcingStates = {}

local function SQL(query, params)
    local p = promise.new()
    exports.oxmysql:execute(query, params, function(result) p:resolve(result) end)
    return Citizen.Await(p)
end

for _, loc in ipairs(Config.SourcingLocations) do sourcingStates[loc.id] = true end


local function validateDistance(source, targetCoords, maxDist, eventName)
    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)
    local target = vector3(targetCoords.x, targetCoords.y, targetCoords.z)
    local dist = #(playerCoords - target)

    if dist > maxDist then
        print(string.format('^1[CHEATER ALARM] ID: %s tried to execute %s from far away! (%s m)', source, eventName, math.floor(dist)))
        -- TriggerEvent('anticheat:ban', source)
        return false
    end
    return true
end


local function getStats(identifier)
    local result = SQL('SELECT reputation, upgrades FROM underground_stats WHERE identifier = ?', {identifier})
    if result and result[1] then 
        local upgrades = json.decode(result[1].upgrades) or {}
        return result[1].reputation or 0, upgrades
    end
    SQL('INSERT INTO underground_stats (identifier, reputation, upgrades) VALUES (?, ?, ?)', {identifier, 0, '[]'})
    return 0, {}
end

local function updateReputation(identifier, amount)
    local rep, upgrades = getStats(identifier)
    local newRep = math.min(100, math.max(0, rep + amount))
    SQL('UPDATE underground_stats SET reputation = ? WHERE identifier = ?', {newRep, identifier})
end

local function addUpgrade(identifier, upgradeName)
    local rep, upgrades = getStats(identifier)
    upgrades[upgradeName] = true
    SQL('UPDATE underground_stats SET upgrades = ? WHERE identifier = ?', {json.encode(upgrades), identifier})
end

lib.callback.register('underground:server:getLaptopData', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end
    local rep, upgrades = getStats(xPlayer.identifier)
    local bank = xPlayer.getAccount('bank').money
    return {
        rep = rep,
        upgrades = upgrades,
        bank = bank
    }
end)

RegisterNetEvent('underground:server:buyUpgrade', function(upgradeName)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local upgrade = Config.Upgrades[upgradeName]

    if not xPlayer or not upgrade then return end
    if not validateDistance(src, Config.LabSetup.LaptopStation.coords, 5.0, 'buyUpgrade') then return end

    local rep, upgrades = getStats(xPlayer.identifier)

    if upgrades[upgradeName] then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = 'You already own this upgrade!', type = 'error'})
        return
    end

    if rep < upgrade.repRequired then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = 'Insufficient reputation!', type = 'error'})
        return
    end

    if xPlayer.getMoney() >= upgrade.price then
        xPlayer.removeMoney(upgrade.price)
        addUpgrade(xPlayer.identifier, upgradeName)
        TriggerClientEvent('ox_lib:notify', src, {title = 'DarkNet', description = 'Purchased: '..upgrade.label, type = 'success'})
    elseif xPlayer.getAccount('bank').money >= upgrade.price then
        xPlayer.removeAccountMoney('bank', upgrade.price)
        addUpgrade(xPlayer.identifier, upgradeName)
        TriggerClientEvent('ox_lib:notify', src, {title = 'DarkNet', description = 'Purchased: '..upgrade.label, type = 'success'})
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = 'Insufficient funds!', type = 'error'})
    end
end)

ESX.RegisterUsableItem(Config.PhoneItem, function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local items = exports.ox_inventory:GetInventoryItems(src)
    local phoneSlot, phoneData

    for _, item in pairs(items) do
        if item.name == Config.PhoneItem then
            phoneSlot = item.slot
            phoneData = item
            break
        end
    end

    if phoneSlot then
        local metadata = phoneData.metadata or {}
        local durability = metadata.durability or 100
        local newDurability = durability - 10

        if newDurability > 0 then
            exports.ox_inventory:SetMetadata(src, phoneSlot, {durability = newDurability})
            local dealerCoords = vector3(currentSpot.coords.x, currentSpot.coords.y, currentSpot.coords.z)
            local _, upgrades = getStats(xPlayer.identifier)
            TriggerClientEvent('underground:client:useBurnerPhone', src, dealerCoords, upgrades)
        else
            exports.ox_inventory:RemoveItem(src, Config.PhoneItem, 1, nil, phoneSlot)
            TriggerClientEvent('ox_lib:notify', src, {title = 'Burner Phone', description = 'The phone is broken.', type = 'error'})
        end
    end
end)

RegisterNetEvent('underground:server:policeAlert', function(coords)
    if not validateDistance(source, coords, 10.0, 'policeAlert') then return end

    local players = ESX.GetPlayers()
    for _, playerId in ipairs(players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            for _, job in ipairs(Config.PoliceJobs) do
                if xPlayer.job.name == job then
                    TriggerClientEvent('ox_lib:notify', playerId, {title = 'DISPATCH 10-90', description = 'Illegal activity reported!', type = 'error', duration = 10000, icon = 'shield-halved'})
                end
            end
        end
    end
end)

lib.callback.register('underground:server:getReputation', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    local rep, _ = getStats(xPlayer.identifier)
    return rep
end)

local function shuffleDealer()
    currentSpot = Config.DealerSpots[math.random(#Config.DealerSpots)]
    TriggerClientEvent('underground:client:syncDealer', -1, currentSpot)
    print('^2[Underground]^7 Dealer moved to: ' .. currentSpot.locationName)
end

CreateThread(function()
    while true do Wait(Config.DealerRotationTime * 60000) shuffleDealer() end
end)

RegisterNetEvent('underground:server:requestSync', function()
    local src = source
    TriggerClientEvent('underground:client:syncDealer', src, currentSpot)
    TriggerClientEvent('underground:client:updateProps', src, sourcingStates)
end)

AddEventHandler('esx:playerLoaded', function(source)
    local src = source
    TriggerClientEvent('underground:client:syncDealer', src, currentSpot)
    TriggerClientEvent('underground:client:updateProps', src, sourcingStates)
end)


RegisterNetEvent('underground:server:giveSourceItems', function(locationId)
    local src = source
    
    local locData = nil
    for _, loc in ipairs(Config.SourcingLocations) do
        if loc.id == locationId then locData = loc break end
    end
    
    if not locData then return end 

    if not validateDistance(src, locData.coords, 5.0, 'giveSourceItems') then return end

    local hasTool = exports.ox_inventory:Search(src, 'count', Config.ToolItem)
    if type(hasTool) == 'table' then
        local count = 0
        for _, c in pairs(hasTool) do count = count + c end
        hasTool = count
    end
    
    if hasTool <= 0 then
        print('^1[CHEATER ALARM] ID: '..src..' tried to loot without crowbar!')
        return 
    end

    if not sourcingStates[locationId] then 
        TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = 'This crate is empty!', type = 'error'})
        return 
    end 

    local amount = math.random(1, 3)
    if exports.ox_inventory:AddItem(src, Config.RequiredItem, amount) then
        sourcingStates[locationId] = false 
        TriggerClientEvent('underground:client:updateProps', -1, sourcingStates)
        SetTimeout(Config.SourcingCooldown * 60000, function()
            sourcingStates[locationId] = true
            TriggerClientEvent('underground:client:updateProps', -1, sourcingStates)
        end)
    end
end)

RegisterNetEvent('underground:server:sellItems', function(countInput)
    local src = source
    local count = tonumber(countInput)
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer or not count or count <= 0 then return end

    if not validateDistance(src, currentSpot.coords, 5.0, 'sellItems') then return end

    local currentCount = exports.ox_inventory:Search(src, 'count', Config.ProcessedItem)
    if currentCount >= count then
        if exports.ox_inventory:RemoveItem(src, Config.ProcessedItem, count) then
            local rep, upgrades = getStats(xPlayer.identifier)
            
            local bonus = 1.0 + (rep / 100)
            if upgrades['better_prices'] then bonus = bonus + 0.15 end

            local reward = math.floor((count * 1000) * bonus)
            exports.ox_inventory:AddItem(src, 'money', reward)
            updateReputation(xPlayer.identifier, 2)
            
            TriggerClientEvent('ox_lib:notify', src, {title = 'Dealer', description = 'Goods sold for $'..reward, type = 'success'})
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = 'You do not have enough goods!', type = 'error'})
    end
end)

RegisterNetEvent('underground:server:processItem', function()
    local src = source
    
    if not validateDistance(src, Config.LabSetup.ProcessingStation.coords, 5.0, 'processItem') then return end

    if exports.ox_inventory:RemoveItem(src, Config.RequiredItem, 1) then
        exports.ox_inventory:AddItem(src, Config.ProcessedItem, 1)
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = 'Missing required items!', type = 'error'})
    end
end)

RegisterNetEvent('underground:server:failProcess', function()
    local src = source
    if not validateDistance(src, Config.LabSetup.ProcessingStation.coords, 5.0, 'failProcess') then return end
    
    exports.ox_inventory:RemoveItem(src, Config.RequiredItem, 1)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    
    exports.ox_inventory:RegisterShop('underground_supplier', {
        name = 'Dark Alley',
        inventory = Config.Supplier.items
    })
end)