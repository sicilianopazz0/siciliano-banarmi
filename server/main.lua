ESX = exports["es_extended"]:getSharedObject()

local BannedPlayers = {}
local lastCleanup = 0

-- Cache delle funzioni
local os_time = os.time
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber

-- Carica i ban dal database all'avvio
Citizen.CreateThread(function()
    MySQL.Async.fetchAll('SELECT * FROM weapon_bans', {}, function(results)
        for _, ban in ipairs(results) do
            BannedPlayers[ban.identifier] = ban.end_time
        end
    end)
end)

-- Funzione per verificare i permessi
local function IsPlayerAllowed(group)
    for _, v in ipairs(Config.AllowedGroups) do
        if group == v then
            return true
        end
    end
    return false
end

-- Comando ban armi
RegisterCommand("banarmi", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsPlayerAllowed(xPlayer.getGroup()) then
        TriggerClientEvent('esx:showNotification', source, "Non hai i permessi per usare questo comando!")
        return
    end

    local target = tonumber(args[1])
    if not target then
        TriggerClientEvent('esx:showNotification', source, "Specifica un ID valido!")
        return
    end

    local targetPlayer = ESX.GetPlayerFromId(target)
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', source, "Giocatore non trovato!")
        return
    end

    TriggerClientEvent("custom_menu:openBanMenu", source, target)
end)

-- Comando unban armi
RegisterCommand("unbanarmi", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsPlayerAllowed(xPlayer.getGroup()) then
        TriggerClientEvent('esx:showNotification', source, "Non hai i permessi per usare questo comando!")
        return
    end

    local target = tonumber(args[1])
    if not target then
        TriggerClientEvent('esx:showNotification', source, "Specifica un ID valido!")
        return
    end

    local targetPlayer = ESX.GetPlayerFromId(target)
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', source, "Giocatore non trovato!")
        return
    end

    if BannedPlayers[targetPlayer.identifier] then
        BannedPlayers[targetPlayer.identifier] = nil
        MySQL.Async.execute('DELETE FROM weapon_bans WHERE identifier = @identifier', {
            ['@identifier'] = targetPlayer.identifier
        })
        TriggerClientEvent("custom_menu:unbanWeapons", target)
        TriggerClientEvent('esx:showNotification', source, "Ban armi rimosso per il giocatore " .. target)
    else
        TriggerClientEvent('esx:showNotification', source, "Questo giocatore non è bannato!")
    end
end)

-- Evento per impostare il ban
RegisterNetEvent("custom_menu:setWeaponBan")
AddEventHandler("custom_menu:setWeaponBan", function(target, time)
    local _source = source
    local targetPlayer = ESX.GetPlayerFromId(target)
    
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', _source, "Giocatore non trovato!")
        return
    end

    if not BannedPlayers[targetPlayer.identifier] then
        local endTime = os_time() + (time * 60)
        BannedPlayers[targetPlayer.identifier] = endTime
        
        MySQL.Async.execute('INSERT INTO weapon_bans (identifier, end_time) VALUES (@identifier, @end_time) ON DUPLICATE KEY UPDATE end_time = @end_time', {
            ['@identifier'] = targetPlayer.identifier,
            ['@end_time'] = endTime
        })
        
        TriggerClientEvent("custom_menu:applyWeaponBan", target, Config.BannedWeapons, time)
        TriggerClientEvent('esx:showNotification', target, "Ti è stato vietato l'uso di alcune armi per " .. time .. " minuti.")
        TriggerClientEvent('esx:showNotification', _source, "Hai bannato le armi al giocatore " .. target .. " per " .. time .. " minuti")
    else
        TriggerClientEvent('esx:showNotification', _source, "Questo giocatore è già bannato!")
    end
end)

-- Thread per la pulizia dei ban scaduti
Citizen.CreateThread(function()
    while true do
        local currentTime = os_time()
        if currentTime - lastCleanup > 60 then
            lastCleanup = currentTime
            
            for identifier, endTime in pairs(BannedPlayers) do
                if currentTime >= endTime then
                    BannedPlayers[identifier] = nil
                    MySQL.Async.execute('DELETE FROM weapon_bans WHERE identifier = @identifier', {
                        ['@identifier'] = identifier
                    })
                    local targetPlayer = ESX.GetPlayerFromIdentifier(identifier)
                    if targetPlayer then
                        TriggerClientEvent("custom_menu:unbanWeapons", targetPlayer.source)
                    end
                end
            end
        end
        Citizen.Wait(1000)
    end
end) 
