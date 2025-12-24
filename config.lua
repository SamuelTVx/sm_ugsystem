Config = {}
Config.Debug = false 

Config.RequiredItem = "radioactive_waste" 
Config.ProcessedItem = "refined_chemical"
Config.ToolItem = "weapon_crowbar" 

Config.Dispatch = 'cd_dispatch' -- Options: 'cd_dispatch', 'ox_notify'
Config.PoliceJobs = { 'police', 'sheriff' }

-- Burner Phone Settings
Config.PhoneItem = "burner_phone"
Config.RevealDuration = 120 -- Duration in seconds for dealer visibility
Config.PhoneChance = 100 

Config.SourcingCooldown = 10 
Config.DealerRotationTime = 15 -- Dealer moves every 15 minutes

-- Starter NPC Supplier
Config.Supplier = {
    coords = vec4(321.86, -1284.39, 30.56, 228.55), -- Strawberry Alley
    model = 'g_m_y_strpunk_01', 
    items = {
        { name = 'burner_phone', price = 500, label = 'Burner Phone' },
        { name = 'weapon_crowbar', price = 250, label = 'Crowbar' },
    }
}

Config.LabAccess = {
    Enter = vec4(1239.42, -3173.59, 7.16, 270), 
    Exit = vector4(997.0, -3200.6, -36.4, 270.0) 
}

-- Laboratory Props & Setup
Config.LabSetup = {
    -- Main processing station
    ProcessingStation = {
        model = 'prop_meth_setup_01',
        coords = vector4(1004.60, -3193.247, -39.25, 188.785)
    },
    
    -- Laptop target zone
    LaptopStation = {
        coords = vector3(1001.91, -3194.29, -39.07),
        rotation = 180.0
    }
}

Config.Upgrades = {
    ghost_vpn = { 
        label = 'Ghost VPN', 
        description = 'Burner Phone signal lasts 5 minutes.', 
        price = 50000, 
        repRequired = 30, 
        icon = 'wifi' 
    },
    silent_tools = { 
        label = 'Silent Tools', 
        description = 'Police are not alerted upon lockpick failure.', 
        price = 100000, 
        repRequired = 50, 
        icon = 'mask' 
    },
    fast_hands = { 
        label = 'Rapid Processing', 
        description = 'Processing speed is doubled.', 
        price = 150000, 
        repRequired = 70, 
        icon = 'flask' 
    },
    better_prices = { 
        label = 'Certified Export', 
        description = 'Permanent +15% bonus to sell prices.', 
        price = 300000, 
        repRequired = 90, 
        icon = 'money-bill-trend-up' 
    }
}

Config.DealerSpots = {
    { coords = vector4(-22.2, -1494.6, 30.3, 102.9), locationName = "South Los Santos" },
    { coords = vector4(244.8, 130.5, 102.5, 130.2), locationName = "Vinewood" },
    { coords = vector4(1264.3, 343.0, 81.9, 328.5), locationName = "Diamond Casino" },
    { coords = vec4(2872.8, 1501.6, 24.5, 309.6), locationName = "Cypress Flats" },
    { coords = vec4(-50.548031, -2255.7, 7.8, 178.6), locationName = "Docks" }
}

Config.SourcingLocations = {
    { id = 1, coords = vector3(464.637512, -3277.737549, 6.069232), model = 'bkr_prop_crate_set_01a' },
    { id = 2, coords = vector3(464.435974, -3272.315430, 6.069264), model = 'bkr_prop_crate_set_01a' },
    { id = 3, coords = vector3(591.054077, -3189.595215, 6.069344), model = 'bkr_prop_crate_set_01a' },
    { id = 4, coords = vector3(599.659302, -3134.137695, 6.069254), model = 'bkr_prop_crate_set_01a' },
    { id = 5, coords = vector3(465.142365, -3179.296143, 6.069534), model = 'bkr_prop_crate_set_01a' },
    { id = 6, coords = vector3(504.284760, -3128.333252, 6.069681), model = 'bkr_prop_crate_set_01a' }
}

Config.LabLocation = vector3(1166.0, -3192.5, -39.0)