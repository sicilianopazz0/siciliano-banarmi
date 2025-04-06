ESX = exports["es_extended"]:getSharedObject()

local bannedWeapons = {}
local banEndTime = 0
local showBanUI = false
local lastWeaponCheck = 0

-- Cache delle funzioni native
local GetGameTimer = GetGameTimer
local PlayerPedId = PlayerPedId
local HasPedGotWeapon = HasPedGotWeapon
local GetHashKey = GetHashKey
local RemoveWeaponFromPed = RemoveWeaponFromPed
local DrawRect = DrawRect
local SetTextFont = SetTextFont
local SetTextScale = SetTextScale
local SetTextColour = SetTextColour
local SetTextDropshadow = SetTextDropshadow
local SetTextEdge = SetTextEdge
local SetTextDropShadow = SetTextDropShadow
local SetTextOutline = SetTextOutline
local SetTextEntry = SetTextEntry
local SetTextCentre = SetTextCentre
local AddTextComponentString = AddTextComponentString
local DrawText = DrawText

-- Funzione per formattare il tempo rimanente
local function FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%02d:%02d", minutes, secs)
    end
end

-- Funzione per disegnare l'UI
local function DrawBanUI()
    if not showBanUI then return end
    
    local currentTime = GetGameTimer() / 1000
    local timeLeft = banEndTime - currentTime
    if timeLeft <= 0 then
        showBanUI = false
        return
    end
    
    -- Disegna lo sfondo
    DrawRect(0.5, 0.95, 0.2, 0.05, 0, 0, 0, 200)
    
    -- Disegna il testo
    SetTextFont(4)
    SetTextScale(0.5, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString("~r~BAN ARMI~w~ - Tempo rimanente: " .. FormatTime(timeLeft))
    DrawText(0.5, 0.93)
end

-- Thread per aggiornare l'UI
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        DrawBanUI()
    end
end)

RegisterNetEvent("custom_menu:openBanMenu")
AddEventHandler("custom_menu:openBanMenu", function(target)
    local elements = {}

    for _, duration in ipairs(Config.BanDurations) do
        table.insert(elements, { label = duration.label, value = duration.time })
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'ban_menu', {
        title    = "Seleziona Durata Ban Armi",
        align    = 'top-left',
        elements = elements
    }, function(data, menu)
        TriggerServerEvent("custom_menu:setWeaponBan", target, data.current.value)
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end)

RegisterNetEvent("custom_menu:applyWeaponBan")
AddEventHandler("custom_menu:applyWeaponBan", function(bannedList, endTime)
    bannedWeapons = bannedList
    banEndTime = (GetGameTimer() / 1000) + (endTime * 60)
    showBanUI = true
end)

RegisterNetEvent("custom_menu:unbanWeapons")
AddEventHandler("custom_menu:unbanWeapons", function()
    bannedWeapons = {}
    showBanUI = false
end)

-- Thread ottimizzato per il controllo delle armi
Citizen.CreateThread(function()
    while true do
        local currentTime = GetGameTimer()
        if currentTime - lastWeaponCheck > 500 then
            lastWeaponCheck = currentTime
            
            local playerPed = PlayerPedId()
            for _, weapon in ipairs(bannedWeapons) do
                if HasPedGotWeapon(playerPed, GetHashKey(weapon), false) then
                    RemoveWeaponFromPed(playerPed, GetHashKey(weapon))
                    ESX.ShowNotification("Non puoi usare quest'arma al momento!")
                end
            end
        end
        Citizen.Wait(100)
    end
end) 
