Config = {}

-- Lista delle armi bannate
Config.BannedWeapons = {
    -- Pistole
    "weapon_pistol",
    "weapon_pistol_mk2",
    "weapon_combatpistol",
    "weapon_appistol",
    "weapon_stungun",
    "weapon_pistol50",
    "weapon_snspistol",
    "weapon_snspistol_mk2",
    "weapon_heavypistol",
    "weapon_vintagepistol",
    "weapon_flaregun",
    "weapon_marksmanpistol",
    "weapon_revolver",
    "weapon_revolver_mk2",
    "weapon_doubleaction",
    "weapon_ceramicpistol",
    "weapon_navyrevolver",
    
    -- Automatiche
    "weapon_microsmg",
    "weapon_smg",
    "weapon_smg_mk2",
    "weapon_assaultsmg",
    "weapon_combatpdw",
    "weapon_machinepistol",
    "weapon_minismg",
    "weapon_raycarbine",
    "weapon_assaultrifle",
    "weapon_assaultrifle_mk2",
    "weapon_carbinerifle",
    "weapon_carbinerifle_mk2",
    "weapon_advancedrifle",
    "weapon_specialcarbine",
    "weapon_specialcarbine_mk2",
    "weapon_bullpuprifle",
    "weapon_bullpuprifle_mk2",
    "weapon_compactrifle",
    "weapon_militaryrifle",
    "weapon_heavyrifle",
    "weapon_tacticalrifle",
    "weapon_mg",
    "weapon_combatmg",
    "weapon_combatmg_mk2",
    "weapon_gusenberg",
    
    -- Cecchini
    "weapon_sniperrifle",
    "weapon_heavysniper",
    "weapon_heavysniper_mk2",
    "weapon_marksmanrifle",
    "weapon_marksmanrifle_mk2",
    
    -- Granate/Lancia Granate
    "weapon_rpg",
    "weapon_grenadelauncher",
    "weapon_grenadelauncher_smoke",
    "weapon_minigun",
    "weapon_firework",
    "weapon_railgun",
    "weapon_hominglauncher",
    "weapon_compactlauncher",
    "weapon_rayminigun",
    
    -- Armi Bianche
    "weapon_dagger",
    "weapon_bat",
    "weapon_bottle",
    "weapon_crowbar",
    "weapon_unarmed",
    "weapon_flashlight",
    "weapon_golfclub",
    "weapon_hammer",
    "weapon_hatchet",
    "weapon_knuckle",
    "weapon_knife",
    "weapon_machete",
    "weapon_switchblade",
    "weapon_nightstick",
    "weapon_wrench",
    "weapon_battleaxe",
    "weapon_poolcue",
    "weapon_stone_hatchet",
    
    -- Bombe
    "weapon_grenade",
    "weapon_bzgas",
    "weapon_molotov",
    "weapon_stickybomb",
    "weapon_proxmine",
    "weapon_pipebomb",
    "weapon_petrolcan",
    "weapon_fireextinguisher",
    "weapon_hazardcan"
}

-- Durate dei ban disponibili
Config.BanDurations = {
    { label = "5 Minuti", time = 5 },
    { label = "10 Minuti", time = 10 },
    { label = "15 Minuti", time = 15 },
    { label = "12 Ore", time = 720 },
    { label = "24 Ore", time = 1440 },
    { label = "48 Ore", time = 2880 }
}

-- Gruppi autorizzati a usare i comandi (gruppi base ESX)
Config.AllowedGroups = {
    "admin",
    "superadmin"
}