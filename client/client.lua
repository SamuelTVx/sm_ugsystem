local ESX = exports['es_extended']:getSharedObject()
local dealerPed = nil
local dealerBlip = nil
local tempBlip = nil 
local supplierPed = nil
local spawnedProps = {}     
local spawnedLabProps = {}  
local isDealerRevealed = false
local myUpgrades = {} 

local function SafeLoadModel(model)
    local hash = (type(model) == 'number') and model or GetHashKey(model)
    if not IsModelInCdimage(hash) then return false end 
    RequestModel(hash)
    local attempts = 0
    while not HasModelLoaded(hash) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end
    return HasModelLoaded(hash)
end

local function getReputationVisuals(rep)
    if rep <= 20 then return '#2ecc71', 'Green (Beginner)'
    elseif rep <= 60 then return '#e67e22', 'Orange (Known Associate)'
    else return '#e74c3c', 'Red (Kingpin)'
    end
end

local function hasUpgrade(name)
    return myUpgrades[name] == true
end

local function alertPolice()
    if hasUpgrade('silent_tools') then return end 

    local coords = GetEntityCoords(cache.ped)
    if Config.Dispatch == 'cd_dispatch' then
        local data = exports['cd_dispatch']:GetPlayerInfo()
        TriggerServerEvent('cd_dispatch:AddNotification', {
            job_table = Config.PoliceJobs, 
            coords = coords,
            title = '10-90 - Material Theft',
            message = 'Someone is trying to break into shipping containers!', 
            flash = 0,
            unique_id = data.unique_id,
            sound = 1,
            blip = {sprite = 478, scale = 1.2, colour = 3, flashes = false, text = 'Material Theft', time = 5, radius = 0}
        })
    elseif Config.Dispatch == 'ox_notify' then
        TriggerServerEvent('underground:server:policeAlert', coords)
    end
end

local function doTeleport(coords, heading)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(cache.ped, heading)
    Wait(1000) 
    DoScreenFadeIn(500)
end

local function startSourcing(locationId)
    local result = exports.ox_inventory:Search('count', Config.ToolItem)
    local hasTool = 0

    if type(result) == 'table' then
        for _, count in pairs(result) do
            hasTool = hasTool + count
        end
    else
        hasTool = result
    end

    if hasTool > 0 then
        if lib.progressBar({
            duration = 6000,
            label = 'Breaking open crate...',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = {
                dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
                clip = 'machinic_loop_mechandplayer',
            }
        }) then
            if lib.skillCheck({'easy', 'medium'}, {'w', 'a', 's', 'd'}) then
                TriggerServerEvent('underground:server:giveSourceItems', locationId)
            else
                lib.notify({ title = 'Error', description = 'You failed the attempt!', type = 'error' })
                alertPolice()
            end
        end
    else
        lib.notify({ title = 'Error', description = 'You need a crowbar!', type = 'error' })
    end
end

RegisterNetEvent('underground:client:useBurnerPhone', function(coords, upgradesData)
    if upgradesData then myUpgrades = upgradesData end 
    
    if isDealerRevealed then
        lib.notify({ title = 'Signal', description = 'Dealer is already on GPS!', type = 'inform' })
        return
    end

    local success = lib.skillCheck({'easy', 'medium', 'hard'}, {'w', 'a', 's', 'd'})
    
    if success then
        local duration = Config.RevealDuration
        if hasUpgrade('ghost_vpn') then duration = 300 end 

        lib.notify({ title = 'Hacking', description = 'Signal captured. You have '..duration..' seconds.', type = 'success' })
        
        if tempBlip then RemoveBlip(tempBlip) end
        tempBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(tempBlip, 110)
        SetBlipColour(tempBlip, 1)
        SetBlipScale(tempBlip, 1.0)
        SetBlipRoute(tempBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Dealer (Signal)")
        EndTextCommandSetBlipName(tempBlip)

        isDealerRevealed = true 

        SetTimeout(duration * 1000, function()
            if tempBlip then RemoveBlip(tempBlip) end
            isDealerRevealed = false 
            lib.notify({ title = 'Signal', description = 'Connection to dealer lost.', type = 'error' })
        end)
    else
        lib.notify({ title = 'Error', description = 'Encryption bypass failed.', type = 'error' })
    end
end)

local function openLaptop()
    lib.callback('underground:server:getLaptopData', false, function(data)
        myUpgrades = data.upgrades 
        local repColor, repLabel = getReputationVisuals(data.rep)

        local options = {
            {
                title = 'Statistics',
                description = 'Network Profile',
                icon = 'user-secret',
                iconColor = repColor,
                metadata = {
                    {label = 'Reputation', value = data.rep},
                    {label = 'Rank', value = repLabel},
                    {label = 'Bank Balance', value = '$'..ESX.Math.GroupDigits(data.bank)}
                },
                readOnly = true
            },
            { type = 'separator', label = 'Available Upgrades' } 
        }

        local sortedUpgrades = {}
        for key, val in pairs(Config.Upgrades) do
            val.key = key
            table.insert(sortedUpgrades, val)
        end
        table.sort(sortedUpgrades, function(a, b) return a.repRequired < b.repRequired end)

        for _, upgrade in ipairs(sortedUpgrades) do
            local key = upgrade.key
            local owned = hasUpgrade(key)
            local canBuyRep = data.rep >= upgrade.repRequired
            local canBuyMoney = data.bank >= upgrade.price or ESX.GetPlayerData().money >= upgrade.price
            
            local title = upgrade.label
            local description = upgrade.description
            local icon = upgrade.icon
            local iconColor = '#3498db' 
            local progressVal = math.min(100, (data.rep / upgrade.repRequired) * 100)
            
            local metadata = {
                {label = 'Price', value = "$" .. ESX.Math.GroupDigits(upgrade.price)},
            }

            if owned then
                title = upgrade.label .. ' (Owned)'
                description = '✅ Upgrade active.'
                iconColor = '#2ecc71'
                icon = 'circle-check'
                table.insert(metadata, {label = 'Status', value = 'Purchased'})
            elseif not canBuyRep then
                title = '🔒 ' .. upgrade.label
                description = '❌ Higher reputation required!'
                iconColor = '#e74c3c'
                icon = 'lock'
                table.insert(metadata, {
                    label = 'Required Reputation', 
                    value = string.format('%d / %d', data.rep, upgrade.repRequired),
                    progress = progressVal
                })
            else
                if not canBuyMoney then
                    description = '💸 Insufficient funds.'
                    iconColor = '#f1c40f'
                end
                table.insert(metadata, {label = 'Required Reputation', value = '✅ MET ('..upgrade.repRequired..')'})
            end
            
            table.insert(options, {
                title = title,
                description = description,
                icon = icon,
                iconColor = iconColor,
                metadata = metadata,
                disabled = owned or not canBuyRep,
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Confirm Purchase',
                        content = 'Do you want to buy **'..upgrade.label..'**?\n\nPrice: **$'..ESX.Math.GroupDigits(upgrade.price)..'**',
                        centered = true,
                        cancel = true
                    })
                    if confirm == 'confirm' then
                        TriggerServerEvent('underground:server:buyUpgrade', key)
                    end
                end
            })
        end

        lib.registerContext({
            id = 'laptop_menu',
            title = 'DarkNet Market v1.0',
            options = options
        })
        lib.showContext('laptop_menu')
    end)
end

local function openDealerMenu()
    if not isDealerRevealed then
        lib.notify({
            title = 'Unknown Contact',
            description = 'Dealer: "Who are you? Get lost!" (Signal required)',
            type = 'error',
            icon = 'user-slash'
        })
        lib.requestAnimDict('gestures@m@standing@casual')
        TaskPlayAnim(dealerPed, 'gestures@m@standing@casual', 'gesture_damn', 8.0, -8.0, -1, 0, 0, false, false, false)
        return
    end

    lib.callback('underground:server:getReputation', false, function(rep)
        rep = rep or 0
        local repColor, repLabel = getReputationVisuals(rep)
        
        lib.registerContext({
            id = 'dealer_menu',
            title = 'Black Market',
            options = {
                {
                    title = 'Reputation',
                    description = repLabel,
                    progress = rep,
                    colorScheme = 'blue',
                    metadata = {{label = 'Influence', value = string.format('%d / 100', rep)}},
                    icon = 'fa-id-card',
                    iconColor = repColor
                },
                {
                    title = 'Sell Goods',
                    description = 'Select amount to sell',
                    icon = 'fa-handshake',
                    onSelect = function()
                        local input = lib.inputDialog('Sell Goods', {
                            {type = 'number', label = 'Amount', min = 1, required = true}
                        })
                        if input and input[1] then
                            TriggerServerEvent('underground:server:sellItems', input[1])
                        end
                    end
                }
            }
        })
        lib.showContext('dealer_menu')
    end)
end

local function startProcessing()
    local count = exports.ox_inventory:Search('count', Config.RequiredItem)
    if count > 0 then
        local duration = 5000
        if hasUpgrade('fast_hands') then duration = 2500 end 

        if lib.progressBar({
            duration = duration,
            label = 'Mixing chemicals...',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true },
            anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' }
        }) then
            if lib.skillCheck({'medium', 'medium'}, {'w', 'a', 's', 'd'}) then
                TriggerServerEvent('underground:server:processItem')
            else
                TriggerServerEvent('underground:server:failProcess')
            end
        end
    else
        lib.notify({ title = 'Error', description = 'Not enough materials!', type = 'error' })
    end
end

local function spawnLabProps()
    for _, prop in pairs(spawnedLabProps) do
        if DoesEntityExist(prop) then DeleteEntity(prop) end
    end
    spawnedLabProps = {}

    local procConfig = Config.LabSetup.ProcessingStation
    if SafeLoadModel(procConfig.model) then
        local procObj = CreateObject(procConfig.model, procConfig.coords.x, procConfig.coords.y, procConfig.coords.z, false, false, false)
        SetEntityHeading(procObj, procConfig.coords.w)
        FreezeEntityPosition(procObj, true)
        table.insert(spawnedLabProps, procObj)

        exports.ox_target:addLocalEntity(procObj, {
            {
                label = 'Start Production',
                icon = 'fas fa-flask',
                onSelect = startProcessing,
                distance = 2.0
            }
        })
    end
end

local function spawnDealer(spot)
    if dealerPed then DeleteEntity(dealerPed) end
    if dealerBlip then RemoveBlip(dealerBlip) end

    if SafeLoadModel('g_m_importexport_01') then
        dealerPed = CreatePed(0, `g_m_importexport_01`, spot.coords.x, spot.coords.y, spot.coords.z - 1.0, spot.coords.w, false, false)
        FreezeEntityPosition(dealerPed, true)
        SetEntityInvincible(dealerPed, true)
        SetBlockingOfNonTemporaryEvents(dealerPed, true)

        exports.ox_target:addLocalEntity(dealerPed, {
            {
                label = 'Talk to contact',
                icon = 'fas fa-comment-dots',
                onSelect = openDealerMenu
            }
        })
    end

    if Config.Debug then
        dealerBlip = AddBlipForCoord(spot.coords.x, spot.coords.y, spot.coords.z)
        SetBlipSprite(dealerBlip, 110)
        SetBlipColour(dealerBlip, 1)
        SetBlipScale(dealerBlip, 0.8)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Dealer (DEBUG)")
        EndTextCommandSetBlipName(dealerBlip)
        lib.notify({ title = 'DEBUG', description = 'Dealer moved: ' .. spot.locationName, type = 'inform' })
    end
end

local function spawnSupplier()
    if supplierPed then DeleteEntity(supplierPed) end
    
    local supConfig = Config.Supplier
    if SafeLoadModel(supConfig.model) then
        supplierPed = CreatePed(0, GetHashKey(supConfig.model), supConfig.coords.x, supConfig.coords.y, supConfig.coords.z - 1.0, supConfig.coords.w, false, false)
        FreezeEntityPosition(supplierPed, true)
        SetEntityInvincible(supplierPed, true)
        SetBlockingOfNonTemporaryEvents(supplierPed, true)

        exports.ox_target:addLocalEntity(supplierPed, {
            {
                label = 'View Offer',
                icon = 'fas fa-shopping-basket',
                onSelect = function()
                    exports.ox_inventory:openInventory('shop', { type = 'underground_supplier' })
                end
            }
        })
    end
end

RegisterNetEvent('underground:client:updateProps', function(locationsState)
    for k, v in pairs(spawnedProps) do
        if DoesEntityExist(v) then DeleteEntity(v) end
    end
    spawnedProps = {}
    for _, loc in ipairs(Config.SourcingLocations) do
        if locationsState[loc.id] then
            if SafeLoadModel(loc.model) then
                local obj = CreateObject(loc.model, loc.coords.x, loc.coords.y, loc.coords.z, false, false, false)
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                exports.ox_target:addLocalEntity(obj, {
                    { label = 'Break open crate', icon = 'fas fa-box-open', onSelect = function() startSourcing(loc.id) end }
                })
                spawnedProps[loc.id] = obj
            end
        end
    end
end)

RegisterNetEvent('underground:client:syncDealer', function(spotData)
    spawnDealer(spotData)
end)

CreateThread(function()
    spawnLabProps()
    spawnSupplier()

    -- Laptop Target
    local lapCoords = Config.LabSetup.LaptopStation.coords
    exports.ox_target:addBoxZone({
        coords = lapCoords,
        size = vector3(0.6, 0.5, 0.4),
        rotation = Config.LabSetup.LaptopStation.rotation,
        debug = Config.Debug,
        options = {{ label = 'Open DarkNet', icon = 'fas fa-laptop-code', onSelect = openLaptop }}
    })

    -- Lab Entrance
    exports.ox_target:addBoxZone({
        coords = vector3(Config.LabAccess.Enter.x, Config.LabAccess.Enter.y, Config.LabAccess.Enter.z),
        size = vector3(1.5, 1.5, 2.5),
        rotation = Config.LabAccess.Enter.w,
        options = {{ label = 'Enter Laboratory', icon = 'fas fa-door-open', onSelect = function() doTeleport(Config.LabAccess.Exit, Config.LabAccess.Exit.w) end }}
    })

    -- Lab Exit
    exports.ox_target:addBoxZone({
        coords = vector3(Config.LabAccess.Exit.x, Config.LabAccess.Exit.y, Config.LabAccess.Exit.z),
        size = vector3(1.5, 1.5, 2.5),
        rotation = Config.LabAccess.Exit.w,
        options = {{ label = 'Exit Laboratory', icon = 'fas fa-door-closed', onSelect = function() doTeleport(Config.LabAccess.Enter, Config.LabAccess.Enter.w) end }}
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    for _, prop in pairs(spawnedLabProps) do if DoesEntityExist(prop) then DeleteEntity(prop) end end
    for _, prop in pairs(spawnedProps) do if DoesEntityExist(prop) then DeleteEntity(prop) end end
    if DoesEntityExist(dealerPed) then DeleteEntity(dealerPed) end
    if DoesEntityExist(supplierPed) then DeleteEntity(supplierPed) end
    if DoesEntityExist(dealerBlip) then RemoveBlip(dealerBlip) end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    TriggerServerEvent('underground:server:requestSync')
end)