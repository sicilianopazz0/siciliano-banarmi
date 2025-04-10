ESX = exports["es_extended"]:getSharedObject()

local bannedWeapons = {}
local banEndTime = 0
local showBanUI = false

-- Funzione per formattare il tempo rimanente
function FormatTime(seconds)
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
function DrawBanUI()
    if not showBanUI then return end
    
    local currentTime = GetGameTimer() / 1000
    local timeLeft = banEndTime - currentTime
    if timeLeft <= 0 then
        showBanUI = false
        return
    end
    
    -- Disegna lo sfondo con bordi arrotondati
    DrawRect(0.5, 0.95, 0.2, 0.05, 0, 0, 0, 200)
    
    -- Disegna il testo con stile migliorato
    SetTextFont(4)
    SetTextScale(0.5, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(true)
    
    -- Aggiungi icona e testo
    AddTextComponentString("~r~🔫 BAN ARMI ~w~| Tempo rimanente: " .. FormatTime(timeLeft))
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
        ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'ban_reason', {
            title = 'Inserisci il motivo del ban'
        }, function(data2, menu2)
            local reason = data2.value
            if reason == nil then
                ESX.ShowNotification('Devi inserire un motivo!')
            else
                TriggerServerEvent("custom_menu:setWeaponBan", target, data.current.value, reason)
                menu2.close()
                menu.close()
            end
        end, function(data2, menu2)
            menu2.close()
        end)
    end, function(data, menu)
        menu.close()
    end)
end)

RegisterNetEvent("custom_menu:applyWeaponBan")
AddEventHandler("custom_menu:applyWeaponBan", function(bannedList, endTime)
    bannedWeapons = bannedList
    banEndTime = (GetGameTimer() / 1000) + (endTime * 60) -- Convertiamo i minuti in secondi
    showBanUI = true
end)

RegisterNetEvent("custom_menu:unbanWeapons")
AddEventHandler("custom_menu:unbanWeapons", function()
    bannedWeapons = {}
    showBanUI = false
end)

RegisterNetEvent("custom_menu:confirmExtendBan")
AddEventHandler("custom_menu:confirmExtendBan", function(target, time, currentEndTime)
    local elements = {
        {label = "Sì, estendi il ban", value = "yes"},
        {label = "No, annulla", value = "no"}
    }

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'extend_ban_menu', {
        title    = "Il giocatore è già bannato. Vuoi estendere il ban?",
        align    = 'top-left',
        elements = elements
    }, function(data, menu)
        if data.current.value == "yes" then
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'extend_reason', {
                title = 'Inserisci il motivo dell\'estensione'
            }, function(data2, menu2)
                local reason = data2.value
                if reason == nil then
                    ESX.ShowNotification('Devi inserire un motivo!')
                else
                    TriggerServerEvent("custom_menu:extendBan", target, time, reason)
                    menu2.close()
                    menu.close()
                end
            end, function(data2, menu2)
                menu2.close()
            end)
        end
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end)

-- Aggiungi notifica quando si prova a usare un'arma vietata
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        local playerPed = PlayerPedId()
        for _, weapon in ipairs(bannedWeapons) do
            if HasPedGotWeapon(playerPed, GetHashKey(weapon), false) then
                RemoveWeaponFromPed(playerPed, GetHashKey(weapon))
                ESX.ShowNotification("~r~ATTENZIONE~w~\nNon puoi usare quest'arma al momento!\nTempo rimanente: " .. FormatTime(banEndTime - (GetGameTimer() / 1000)))
            end
        end
    end
end)
