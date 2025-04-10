ESX = exports["es_extended"]:getSharedObject()

BannedPlayers = {}

-- Funzione per il logging Discord
function SendDiscordLog(action, admin, target, duration, reason)
    if not Config.DiscordWebhook.enabled then return end

    local embed = {
        {
            ["color"] = Config.DiscordWebhook.color,
            ["title"] = "Sistema Ban Armi",
            ["description"] = string.format("**Azione:** %s\n**Admin:** %s\n**Giocatore:** %s\n**Durata:** %d minuti\n**Motivo:** %s", 
                action, admin, target, duration or 0, reason or "Nessun motivo specificato"),
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(Config.DiscordWebhook.url, function(err, text, headers) end, 'POST', json.encode({
        username = Config.DiscordWebhook.botName,
        avatar_url = Config.DiscordWebhook.botAvatar,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Funzione per il logging
function LogBan(action, admin, target, duration, reason)
    -- Log nel database
    MySQL.Async.execute('INSERT INTO weapon_ban_logs (admin_identifier, target_identifier, action, duration, timestamp) VALUES (@admin, @target, @action, @duration, @timestamp)', {
        ['@admin'] = admin,
        ['@target'] = target,
        ['@action'] = action,
        ['@duration'] = duration or 0,
        ['@timestamp'] = os.time()
    })

    -- Log su Discord
    SendDiscordLog(action, admin, target, duration, reason)
end

-- Carica i ban dal database all'avvio
Citizen.CreateThread(function()
    MySQL.Async.fetchAll('SELECT * FROM weapon_bans', {}, function(results)
        for _, ban in ipairs(results) do
            BannedPlayers[ban.identifier] = {
                end_time = ban.end_time,
                duration = ban.ban_duration
            }
        end
    end)
end)

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

RegisterCommand("checkban", function(source, args)
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
        local timeLeft = math.floor((BannedPlayers[targetPlayer.identifier].end_time - os.time()) / 60)
        TriggerClientEvent('esx:showNotification', source, "Il giocatore " .. target .. " ha ancora " .. timeLeft .. " minuti di ban armi")
    else
        TriggerClientEvent('esx:showNotification', source, "Questo giocatore non è bannato!")
    end
end)

RegisterNetEvent("custom_menu:setWeaponBan")
AddEventHandler("custom_menu:setWeaponBan", function(target, time, reason)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local targetPlayer = ESX.GetPlayerFromId(target)
    
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', _source, "Giocatore non trovato!")
        return
    end

    local currentBan = BannedPlayers[targetPlayer.identifier]
    if currentBan then
        -- Se il giocatore è già bannato, chiedi se vuoi estendere il ban
        TriggerClientEvent("custom_menu:confirmExtendBan", _source, target, time, currentBan.end_time)
    else
        local endTime = os.time() + (time * 60)
        BannedPlayers[targetPlayer.identifier] = {
            end_time = endTime,
            duration = time
        }
        
        MySQL.Async.execute('INSERT INTO weapon_bans (identifier, end_time, ban_duration) VALUES (@identifier, @end_time, @ban_duration) ON DUPLICATE KEY UPDATE end_time = @end_time, ban_duration = @ban_duration', {
            ['@identifier'] = targetPlayer.identifier,
            ['@end_time'] = endTime,
            ['@ban_duration'] = time
        })
        
        LogBan('BAN', xPlayer.identifier, targetPlayer.identifier, time, reason)
        TriggerClientEvent("custom_menu:applyWeaponBan", target, Config.BannedWeapons, time)
        TriggerClientEvent('esx:showNotification', target, "Ti è stato vietato l'uso di alcune armi per " .. time .. " minuti.")
        TriggerClientEvent('esx:showNotification', _source, "Hai bannato le armi al giocatore " .. target .. " per " .. time .. " minuti")
    end
end)

RegisterNetEvent("custom_menu:extendBan")
AddEventHandler("custom_menu:extendBan", function(target, time, reason)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local targetPlayer = ESX.GetPlayerFromId(target)
    
    if not targetPlayer then return end
    
    local currentBan = BannedPlayers[targetPlayer.identifier]
    if currentBan then
        local newEndTime = currentBan.end_time + (time * 60)
        BannedPlayers[targetPlayer.identifier] = {
            end_time = newEndTime,
            duration = currentBan.duration + time
        }
        
        MySQL.Async.execute('UPDATE weapon_bans SET end_time = @end_time, ban_duration = @ban_duration WHERE identifier = @identifier', {
            ['@identifier'] = targetPlayer.identifier,
            ['@end_time'] = newEndTime,
            ['@ban_duration'] = currentBan.duration + time
        })
        
        LogBan('EXTEND', xPlayer.identifier, targetPlayer.identifier, time, reason)
        TriggerClientEvent("custom_menu:applyWeaponBan", target, Config.BannedWeapons, math.floor((newEndTime - os.time()) / 60))
        TriggerClientEvent('esx:showNotification', target, "Il tuo ban armi è stato esteso di " .. time .. " minuti")
        TriggerClientEvent('esx:showNotification', _source, "Hai esteso il ban armi del giocatore " .. target .. " di " .. time .. " minuti")
    end
end)

-- Aggiungo un evento per gestire il login del giocatore
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    local identifier = xPlayer.identifier
    if BannedPlayers[identifier] then
        local currentTime = os.time()
        local endTime = BannedPlayers[identifier].end_time
        local timeLeft = math.floor((endTime - currentTime) / 60)
        
        if timeLeft > 0 then
            TriggerClientEvent("custom_menu:applyWeaponBan", xPlayer.source, Config.BannedWeapons, timeLeft)
        else
            BannedPlayers[identifier] = nil
            MySQL.Async.execute('DELETE FROM weapon_bans WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            })
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)

        local currentTime = os.time()
        for identifier, ban in pairs(BannedPlayers) do
            if currentTime >= ban.end_time then
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
end)

function IsPlayerAllowed(group)
    for _, v in ipairs(Config.AllowedGroups) do
        if group == v then
            return true
        end
    end
    return false
end
