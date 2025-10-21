ESX = exports["es_extended"]:getSharedObject()

BannedPlayers = {}

-- Funzione per ottenere il tag Discord del giocatore
function GetPlayerDiscordTag(identifier)
    local player = ESX.GetPlayerFromIdentifier(identifier)
    if player then
        -- Prova a ottenere il Discord ID se disponibile
        for _, v in pairs(GetPlayerIdentifiers(player.source)) do
            if string.match(v, 'discord:') then
                local discordId = string.gsub(v, 'discord:', '')
                return "<@" .. discordId .. ">"
            end
        end
    end
    
    -- Se il giocatore non è online, prova a recuperare il Discord ID dal database
    -- Prima prova nella tabella users
    local result = MySQL.Sync.fetchAll('SELECT discord_id FROM users WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })
    if result[1] and result[1].discord_id then
        return "<@" .. result[1].discord_id .. ">"
    end
    
    -- Se non trova nella tabella users, prova in una tabella discord_identifiers se esiste
    local discordResult = MySQL.Sync.fetchAll('SELECT discord_id FROM discord_identifiers WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })
    if discordResult[1] and discordResult[1].discord_id then
        return "<@" .. discordResult[1].discord_id .. ">"
    end
    
    -- Se non trova Discord ID, prova a recuperare il nome Discord
    local nameResult = MySQL.Sync.fetchAll('SELECT discord_name FROM users WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })
    if nameResult[1] and nameResult[1].discord_name then
        return nameResult[1].discord_name
    end
    
    return "Giocatore Sconosciuto"
end

-- Funzione per il logging Discord
function SendDiscordLog(action, adminIdentifier, targetIdentifier, duration, reason)
    if not Config.DiscordWebhook.enabled then return end

    local adminTag = GetPlayerDiscordTag(adminIdentifier)
    local targetTag = GetPlayerDiscordTag(targetIdentifier)
    
    local embed = {
        {
            ["color"] = Config.DiscordWebhook.color,
            ["title"] = "Sistema Ban Armi",
            ["description"] = string.format("**Azione:** %s\n**Admin:** %s\n**Giocatore:** %s\n**Durata:** %d minuti\n**Motivo:** %s", 
                action, adminTag, targetTag, duration or 0, reason or "Nessun motivo specificato"),
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
    MySQL.Async.execute('INSERT INTO weapon_ban_logs (admin_identifier, target_identifier, action, duration, reason, timestamp) VALUES (@admin, @target, @action, @duration, @reason, @timestamp)', {
        ['@admin'] = admin,
        ['@target'] = target,
        ['@action'] = action,
        ['@duration'] = duration or 0,
        ['@reason'] = reason or "Nessun motivo specificato",
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

-- Funzione per verificare i permessi
function IsPlayerAllowed(group)
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

-- Comando checkban
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
        
        LogBan('UNBAN', xPlayer.identifier, targetPlayer.identifier, 0, "Ban rimosso manualmente")
        TriggerClientEvent("custom_menu:unbanWeapons", target)
        TriggerClientEvent('esx:showNotification', source, "Ban armi rimosso per il giocatore " .. target)
    else
        TriggerClientEvent('esx:showNotification', source, "Questo giocatore non è bannato!")
    end
end)

-- Evento per impostare il ban
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

-- Evento per estendere il ban
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

-- Thread per la pulizia dei ban scaduti
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
