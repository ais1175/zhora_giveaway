-- zhora_giveaway/server.lua

function table.shallowclone(orig)
    if type(orig) ~= 'table' then return orig end
    local new_tab = {}
    for k, v in pairs(orig) do
        new_tab[k] = v
    end
    return new_tab
end

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local pendingVehicleAwards = {}
local currentGiveaway = nil
local isAdminPanelOpen = {}
local managedGiveawayItems = {}
local oxInventoryItemsCache = nil
local giveawayHistory = {}
local pendingVehicleValidations = {}


Config = Config or {}
Config.ManagedItemsFilePath = Config.ManagedItemsFilePath or "managed_items.json"
Config.GiveawayHistoryFilePath = Config.GiveawayHistoryFilePath or "giveaway_history.json"
Config.AdminGroups = Config.AdminGroups or {"admin", "superadmin"}
Config.MinGiveawayDurationMinutes = Config.MinGiveawayDurationMinutes or 1
Config.MaxGiveawayDurationMinutes = Config.MaxGiveawayDurationMinutes or 1440
Config.DefaultGiveawayDurationMinutes = Config.DefaultGiveawayDurationMinutes or 10
Config.DefaultMaxWinners = Config.DefaultMaxWinners or 1
Config.MaxPossibleWinners = Config.MaxPossibleWinners or 100
Config.MaxGiveawayHistoryEntries = Config.MaxGiveawayHistoryEntries or 50
Config.AdminCommand = Config.AdminCommand or "giveawayadmin"


Config.AnnouncementSystem = Config.AnnouncementSystem or 'chat' -- Fallback to chat if not defined
Config.Announcements = Config.Announcements or {
    chat = { type = 'function', prefix = "[Giveaway - Fallback]", template = '{0}: {1}'}
}

-- ##################################################################################
-- ## NEW: Improved Config-based Translate function                               ##
-- ##################################################################################

if Translate == nil then
    Translate = function(key, ...)
        local primaryLang = Config.Language or 'en'
        local fallbackLang = Config.FallbackLanguage or 'de'
        
        -- Try primary language first
        if Locales and Locales[primaryLang] and Locales[primaryLang][key] then
            return string.format(Locales[primaryLang][key], ...)
        end
        
        -- Try fallback language if enabled and different from primary
        if Config.UseFallbackLanguage and fallbackLang ~= primaryLang and Locales and Locales[fallbackLang] and Locales[fallbackLang][key] then
            return string.format(Locales[fallbackLang][key], ...)
        end
        
        -- Try English as last resort (if not already tried)
        if primaryLang ~= 'en' and fallbackLang ~= 'en' and Locales and Locales['en'] and Locales['en'][key] then
            return string.format(Locales['en'][key], ...)
        end
        
        -- Try German as absolute last resort (if not already tried)
        if primaryLang ~= 'de' and fallbackLang ~= 'de' and Locales and Locales['de'] and Locales['de'][key] then
            return string.format(Locales['de'][key], ...)
        end
        
        -- If nothing found, return the key with parameters
        if #{...} > 0 then
            return string.format(key .. " (" .. table.concat({...}, ", ") .. ")")
        else
            return key
        end
    end
    print("[ns_giveaway] WARNING: Global 'Translate' function not found. Using improved dummy translation.")
end
-- ##################################################################################
-- ## END: Improved Config-based Translate function                               ##
-- ##################################################################################

-- ##################################################################################
-- ## NEW: Wrapper function for announcements                                     ##
-- ##################################################################################
function SendAnnouncement(message, type) -- 'type' can be 'info', 'success', 'warning', 'error'
    local systemKey = Config.AnnouncementSystem
    local announcementConfig = Config.Announcements[systemKey]

    if not announcementConfig then
        print(('[^1ERROR^7] [GiveawayScript] Invalid or unconfigured announcement system: "%s". Fallback to server print.'):format(systemKey))
        print(('[GiveawayScript - Fallback-Announcement][%s] %s'):format(string.upper(type or "INFO"), message))
        -- Simple chat fallback if everything else fails
        TriggerClientEvent('chat:addMessage', -1, { args = { "[Giveaway] " .. message } })
        return
    end

    local messageTitle = announcementConfig.defaultSourceName or "Giveaway"
    if systemKey == 'ns_announce' and announcementConfig.defaultSourceName then
        messageTitle = announcementConfig.defaultSourceName
    elseif announcementConfig.defaultTitle then -- For custom_event_example etc.
        messageTitle = announcementConfig.defaultTitle
    end

    if announcementConfig.type == 'event' then
        if announcementConfig.trigger then
            if systemKey == 'ns_announce' then
                local style = announcementConfig.defaultStyleInfo or "info"
                if type == 'success' then style = announcementConfig.defaultStyleSuccess or "success"
                elseif type == 'warning' then style = announcementConfig.defaultStyleWarning or "warning"
                elseif type == 'error' then style = announcementConfig.defaultStyleError or "error" end
                TriggerEvent(announcementConfig.trigger, message, messageTitle, style)
                print(('[GiveawayScript] Announcement sent via "%s" event ("%s"). Type: %s'):format(systemKey, announcementConfig.trigger, style))
            else
                -- For other 'custom_event' systems. Passes message and optionally a title.
                -- If your system needs more/different parameters, you need to adjust here.
                TriggerEvent(announcementConfig.trigger, message, messageTitle, type)
                print(('[GiveawayScript] Announcement sent via custom event "%s" ("%s"). Type: %s'):format(systemKey, announcementConfig.trigger, type))
            end
        else
            print(('[^1ERROR^7] [GiveawayScript] No trigger defined for event system "%s" in Config.Announcements.'):format(systemKey))
        end
    elseif announcementConfig.type == 'export' then
        if announcementConfig.resource and announcementConfig.trigger then
            local resExports = exports[announcementConfig.resource]
            if resExports and resExports[announcementConfig.trigger] then
                -- Passes message and optionally a title. Adjust as needed.
                resExports[announcementConfig.trigger](message, messageTitle, type)
                print(('[GiveawayScript] Announcement sent via custom export "%s->%s". Type: %s'):format(announcementConfig.resource, announcementConfig.trigger, type))
            else
                print(('[^1ERROR^7] [GiveawayScript] Export for system "%s" (Resource: "%s", Export: "%s") not found or resource not started.'):format(systemKey, announcementConfig.resource, announcementConfig.trigger))
            end
        else
            print(('[^1ERROR^7] [GiveawayScript] "resource" or "trigger" not defined for export system "%s" in Config.Announcements.'):format(systemKey))
        end
    elseif announcementConfig.type == 'function' and systemKey == 'chat' then
        local prefix = announcementConfig.prefix or ""
        local finalMessage = message
        if prefix ~= "" then
            finalMessage = string.format("%s %s", prefix, message)
        end

        if announcementConfig.template and announcementConfig.template ~= "" then
             TriggerClientEvent('chat:addMessage', -1, {
                template = announcementConfig.template,
                args = { prefix, message } -- {0} is prefix, {1} is message in template
            })
        else
            TriggerClientEvent('chat:addMessage', -1, { args = { finalMessage } }) -- Simple chat message
        end
        print(('[GiveawayScript] Chat message sent: %s'):format(finalMessage))
    else
        print(('[^1ERROR^7] [GiveawayScript] Unknown or unsupported type ("%s") for announcement system "%s".'):format(announcementConfig.type or "N/A", systemKey))
    end
end
-- ##################################################################################
-- ## END: Wrapper function for announcements                                     ##
-- ##################################################################################

function loadManagedItems()
    local fileContent = LoadResourceFile(GetCurrentResourceName(), Config.ManagedItemsFilePath)
    if fileContent and fileContent ~= "" then
        if not json or not json.decode then print(("^1[GiveawayScript-ERROR]^7 json.decode not available when loading '%s'."):format(Config.ManagedItemsFilePath)); managedGiveawayItems = {}; return end
        local success, data = pcall(json.decode, fileContent)
        if success and type(data) == 'table' then managedGiveawayItems = data;
        else print(("^1[GiveawayScript-ERROR]^7 Error decoding '%s'. Error: %s"):format(Config.ManagedItemsFilePath, success and "invalid data" or data or "unknown")); managedGiveawayItems = {} end
    else
        managedGiveawayItems = {}
    end
end

function saveManagedItems()
    if not json or not json.encode then print("^1[GiveawayScript-ERROR]^7 json.encode not available. Items not saved."); return end
    local successEncode, jsonData = pcall(json.encode, managedGiveawayItems)
    if successEncode and jsonData then
        if not SaveResourceFile(GetCurrentResourceName(), Config.ManagedItemsFilePath, jsonData, -1) then print(("^1[GiveawayScript-ERROR]^7 Error saving items to '%s'."):format(Config.ManagedItemsFilePath)) end
    else print(("^1[GiveawayScript-ERROR]^7 Error encoding items! Error: %s"):format(jsonData or "unknown")) end
end

function loadGiveawayHistory()
    local fileContent = LoadResourceFile(GetCurrentResourceName(), Config.GiveawayHistoryFilePath)
    if fileContent and fileContent ~= "" then
        if not json or not json.decode then print(("^1[GiveawayScript-ERROR]^7 json.decode not available when loading '%s'."):format(Config.GiveawayHistoryFilePath)); giveawayHistory = {}; return end
        local success, data = pcall(json.decode, fileContent)
        if success and type(data) == 'table' then giveawayHistory = data;
        else print(("^1[GiveawayScript-ERROR]^7 Error decoding '%s'. Error: %s"):format(Config.GiveawayHistoryFilePath, success and "invalid data" or data or "unknown")); giveawayHistory = {} end
    else
        giveawayHistory = {}
    end
end

function saveGiveawayHistory()
    if not json or not json.encode then print("^1[GiveawayScript-ERROR]^7 json.encode not available. History not saved."); return end
    while #giveawayHistory > Config.MaxGiveawayHistoryEntries do table.remove(giveawayHistory, 1) end
    local successEncode, jsonData = pcall(json.encode, giveawayHistory)
    if successEncode and jsonData then
        if not SaveResourceFile(GetCurrentResourceName(), Config.GiveawayHistoryFilePath, jsonData, -1) then print(("^1[GiveawayScript-ERROR]^7 Error saving history to '%s'."):format(Config.GiveawayHistoryFilePath)) end
    else print(("^1[GiveawayScript-ERROR]^7 Error encoding history! Error: %s"):format(jsonData or "unknown")) end
end

function refreshItemCache()
    oxInventoryItemsCache = {} -- Clear cache

    if Config.InventorySystem == 'ox_inventory' then
        if exports.ox_inventory and exports.ox_inventory.Items then
            local items = exports.ox_inventory:Items()
            if items and type(items) == 'table' then
                for name, data in pairs(items) do
                    if type(data) == 'table' then
                        table.insert(oxInventoryItemsCache, {name = name, label = data.label or name, description = data.description or '', weight = data.weight or 0})
                    end
                end
                print("^5[GiveawayScript]^2 Item cache filled with 'ox_inventory' data.^7")
            else
                print("^1[GiveawayScript-ERROR]^7 Invalid item list received from ox_inventory.^7")
            end
        else
            print("^1[GiveawayScript-ERROR]^7 'ox_inventory' is selected in config, but the resource or export 'Items' was not found.^7")
        end

    elseif Config.InventorySystem == 'esx' then
        MySQL.query('SELECT name, label FROM items', {}, function(result)
            if result and #result > 0 then
                for _, item in ipairs(result) do
                    table.insert(oxInventoryItemsCache, {name = item.name, label = item.label, description = '', weight = 0})
                end
                print("^5[GiveawayScript]^2 Item cache filled with standard ESX items from database.^7")
            else
                print("^3[GiveawayScript-NOTICE]^7 'esx' is selected in config, but no items could be read from database.^7")
            end
            table.sort(oxInventoryItemsCache, function(a,b) return a.label < b.label end)
        end)
    end
    
    -- Sort for ox_inventory (for ESX it happens in callback)
    if Config.InventorySystem == 'ox_inventory' then
        table.sort(oxInventoryItemsCache, function(a,b) return (a.label or a.name) < (b.label or b.name) end)
    end
end

-- Make sure the call to the old function is also renamed:
Citizen.CreateThread(function()
    while ESX == nil do TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end); Citizen.Wait(200) end
    print("^5[GiveawayScript]^2 ESX ready."); Wait(1000); loadManagedItems(); loadGiveawayHistory(); Wait(1000); refreshItemCache()
end)

local function isAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then for _, group in ipairs(Config.AdminGroups) do if xPlayer.getGroup() == group then return true end end end; return false
end

RegisterCommand(Config.AdminCommand, function(source, args, rawCommand)
    if isAdmin(source) then
        isAdminPanelOpen[source] = not isAdminPanelOpen[source]
        if isAdminPanelOpen[source] and (not oxInventoryItemsCache or #oxInventoryItemsCache == 0) then refreshItemCache() end
        TriggerClientEvent('esx_giveaway:toggleAdminPanel', source, isAdminPanelOpen[source], managedGiveawayItems, {defaultDuration = Config.DefaultGiveawayDurationMinutes, minDuration = Config.MinGiveawayDurationMinutes, maxDuration = Config.MaxGiveawayDurationMinutes, defaultWinners = Config.DefaultMaxWinners, maxWinners = Config.MaxPossibleWinners}, oxInventoryItemsCache or {}, giveawayHistory or {})
    else TriggerClientEvent('esx:showNotification', source, Translate('not_admin'), 'error') end
end, false)

RegisterNetEvent('esx_giveaway:adminPanelClosedByUI')
AddEventHandler('esx_giveaway:adminPanelClosedByUI', function() local src = source; isAdminPanelOpen[src] = false; end)

RegisterNetEvent('esx_giveaway:saveItemDefinition')
AddEventHandler('esx_giveaway:saveItemDefinition', function(itemDef)
    local src = source; if not isAdmin(src) then return end
    if itemDef.type == 'item' then
        local isValidItem = false
        if oxInventoryItemsCache then
            for _, oxItem in ipairs(oxInventoryItemsCache) do
                if oxItem.name == itemDef.item_name then
                    isValidItem = true
                    break
                end
            end
        end
        if not isValidItem then
            TriggerClientEvent('esx:showNotification', src, Translate('invalid_item_name_esx', itemDef.item_name), 'error')
            return
        end
        ProcessSaveItemDefinition(src, itemDef)
    elseif itemDef.type == 'vehicle' then
        if itemDef.item_name == nil or string.gsub(itemDef.item_name, "%s+", "") == "" then 
            TriggerClientEvent('esx:showNotification', src, Translate('vehicle_spawncode_empty'), 'error'); 
            return 
        end
        local validationId = "val_" .. src .. "_" .. math.random(10000, 99999); pendingVehicleValidations[validationId] = itemDef
        TriggerClientEvent('ns_giveaway:client_validateVehicleModel', src, itemDef.item_name, validationId)
    else ProcessSaveItemDefinition(src, itemDef) end
end)

RegisterNetEvent('ns_giveaway:server_receiveVehicleValidationResult')
AddEventHandler('ns_giveaway:server_receiveVehicleValidationResult', function(vehicleModel, isValid, validationId)
    local src = source; local itemDef = pendingVehicleValidations[validationId]
    if not itemDef then return end
    pendingVehicleValidations[validationId] = nil
    if itemDef.item_name ~= vehicleModel then 
        TriggerClientEvent('esx:showNotification', src, Translate('vehicle_validation_error'), 'error'); 
        return 
    end
    if isValid then ProcessSaveItemDefinition(src, itemDef)
    else TriggerClientEvent('esx:showNotification', src, Translate('invalid_vehicle_model_esx', vehicleModel), 'error') end
end)

function ProcessSaveItemDefinition(adminSource, itemDef)
    local itemValue = tonumber(itemDef.value) or 1
    if (itemDef.type == 'item' or itemDef.type == 'money' or itemDef.type == 'black_money') and itemValue < 1 then itemValue = 1 elseif (itemDef.type == 'license' or itemDef.type == 'vehicle') then itemValue = 1 end
    local existingIndex = nil; if itemDef.id then for i, existingItem in ipairs(managedGiveawayItems) do if existingItem.id == itemDef.id then existingIndex = i; break end end end
    for i, existingItem in ipairs(managedGiveawayItems) do if existingItem.label == itemDef.label and (not itemDef.id or existingItem.id ~= itemDef.id) then TriggerClientEvent('esx:showNotification', adminSource, Translate('item_def_label_exists'), 'error'); return end end
    local newItemDefData = {id = itemDef.id or (GetCurrentResourceName().."_"..os.time().."-"..math.random(1000,9999)), label = itemDef.label, type = itemDef.type, item_name = itemDef.item_name, value = itemValue}
    if existingIndex then managedGiveawayItems[existingIndex] = newItemDefData else table.insert(managedGiveawayItems, newItemDefData) end
    saveManagedItems(); TriggerClientEvent('esx:showNotification', adminSource, Translate('item_saved'), 'success'); TriggerClientEvent('esx_giveaway:updateManagedItemsList', -1, managedGiveawayItems, oxInventoryItemsCache or {})
end

RegisterNetEvent('esx_giveaway:deleteItemDefinition')
AddEventHandler('esx_giveaway:deleteItemDefinition', function(itemDefId)
    local src = source; if not isAdmin(src) then return end; local foundIndex = nil
    for i, item in ipairs(managedGiveawayItems) do if item.id == itemDefId then foundIndex = i; break end end
    if foundIndex then table.remove(managedGiveawayItems, foundIndex); saveManagedItems(); TriggerClientEvent('esx:showNotification', src, Translate('item_deleted'), 'success'); TriggerClientEvent('esx_giveaway:updateManagedItemsList', -1, managedGiveawayItems, oxInventoryItemsCache or {})
    else TriggerClientEvent('esx:showNotification', src, Translate('item_definition_not_found'), 'error') end
end)

RegisterNetEvent('esx_giveaway:startGiveaway')
AddEventHandler('esx_giveaway:startGiveaway', function(data)
    local src = source
    if not isAdmin(src) then TriggerClientEvent('esx:showNotification', src, Translate('not_admin'), 'error'); return end
    if currentGiveaway and currentGiveaway.announced then 
        TriggerClientEvent('esx:showNotification', src, Translate('giveaway_already_running'), 'warning'); 
        return 
    end

    local selectedItemConfig = nil
    for _, itemCfg in ipairs(managedGiveawayItems) do
        if itemCfg.id == data.itemId then
            selectedItemConfig = itemCfg
            break
        end
    end

    if not selectedItemConfig then 
        TriggerClientEvent('esx:showNotification', src, Translate('selected_item_not_found'), 'error'); 
        return 
    end

    local durationMinutes = tonumber(data.durationMinutes)
    local maxWinners = tonumber(data.maxWinners)

    if not durationMinutes or not maxWinners or durationMinutes < Config.MinGiveawayDurationMinutes or durationMinutes > Config.MaxGiveawayDurationMinutes or maxWinners < 1 or maxWinners > Config.MaxPossibleWinners then
        TriggerClientEvent('esx:showNotification', src, Translate('invalid_duration_or_winners'), 'error')
        return
    end

    local itemCountToGive = tonumber(data.itemCount) or 1
    if (selectedItemConfig.type == 'item' or selectedItemConfig.type == 'money' or selectedItemConfig.type == 'black_money') and itemCountToGive < 1 then
        itemCountToGive = 1
    elseif (selectedItemConfig.type == 'license' or selectedItemConfig.type == 'vehicle') then
        itemCountToGive = 1
    end

    currentGiveaway = {
        item = selectedItemConfig,
        itemCount = itemCountToGive,
        durationSeconds = durationMinutes * 60,
        maxWinners = maxWinners,
        participants = {},
        startTime = os.time(),
        timer = nil,
        announced = true,
        creatorName = GetPlayerName(src)
    }

    local prizeDisplay = currentGiveaway.item.label
    local prizeAmountForAnnounce = ""
    if selectedItemConfig.type ~= 'license' and selectedItemConfig.type ~= 'vehicle' then
         prizeAmountForAnnounce = ESX.Math.GroupDigits(currentGiveaway.itemCount)
    end

    -- Use Translate for announcement message, fallback to standard string if not found
    local announceMessageStart = Translate('giveaway_started_by',
        currentGiveaway.creatorName,
        currentGiveaway.item.label,
        prizeAmountForAnnounce,
        currentGiveaway.maxWinners,
        durationMinutes
    )

    SendAnnouncement(announceMessageStart, "info") -- NEW way of announcing
    print(('^2[GiveawayScript]^7 Giveaway started by %s: %s (Item: %s, Amount: %s), %s winners, Duration: %s min.'):format(currentGiveaway.creatorName, currentGiveaway.item.label, currentGiveaway.item.item_name, currentGiveaway.itemCount, currentGiveaway.maxWinners, durationMinutes))

    currentGiveaway.timer = SetTimeout(currentGiveaway.durationSeconds * 1000, endGiveaway)
    TriggerClientEvent('esx:showNotification', src, Translate('giveaway_started_successfully'), 'success')
    if isAdminPanelOpen[src] then isAdminPanelOpen[src] = false; TriggerClientEvent('esx_giveaway:toggleAdminPanel', src, false) end
end)

RegisterNetEvent('esx_giveaway:enter')
AddEventHandler('esx_giveaway:enter', function()
    local src = source; local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    if not currentGiveaway or not currentGiveaway.announced then TriggerClientEvent('esx:showNotification', src, Translate('no_giveaway_active'), 'warning'); return end
    if currentGiveaway.participants[xPlayer.identifier] then TriggerClientEvent('esx:showNotification', src, Translate('already_entered'), 'info'); return end

    currentGiveaway.participants[xPlayer.identifier] = { source = src, name = GetPlayerName(src) }
    TriggerClientEvent('esx:showNotification', src, Translate('entered_giveaway', currentGiveaway.item.label), 'success')
end)

function endGiveaway()
    if not currentGiveaway then
        print("^1[GiveawayScript-ERROR] endGiveaway called, but currentGiveaway is nil!^7")
        return
    end

    local giveawayDataForCallbacks = {
        itemDefinition = table.shallowclone(currentGiveaway.item),
        itemCount = currentGiveaway.itemCount,
        creatorName = currentGiveaway.creatorName,
        maxWinners = currentGiveaway.maxWinners,
        participants = table.shallowclone(currentGiveaway.participants)
    }
    local giveawayItemLabel = giveawayDataForCallbacks.itemDefinition.label
    local giveawayItemTechName = giveawayDataForCallbacks.itemDefinition.item_name
    local giveawayItemType = giveawayDataForCallbacks.itemDefinition.type

    if currentGiveaway.timer then ClearTimeout(currentGiveaway.timer) end
    local tempCurrentGiveawayCreatorName = currentGiveaway.creatorName
    currentGiveaway = nil -- End giveaway here before starting async operations

    local participantsList = {}
    for identifier, pData in pairs(giveawayDataForCallbacks.participants) do
        if GetPlayerName(pData.source) then
            table.insert(participantsList, { identifier = identifier, source = pData.source, name = pData.name })
        end
    end

    local winnersDataForHistory = {}
    local winnerNamesForChat = {}
    local announceMessageEnd = ""

    if #participantsList == 0 then
        announceMessageEnd = Translate('giveaway_ended_no_participants', giveawayItemLabel)
        SendAnnouncement(announceMessageEnd, "warning")

        print(('^1[GiveawayScript]^7 Giveaway for %s ended. No participants.'):format(giveawayItemLabel))
        table.insert(giveawayHistory, {
            id = GetCurrentResourceName().."_"..os.time().."_hist_"..math.random(1000,9999),
            timestamp = os.time(),
            prize = {label = giveawayItemLabel, type = giveawayItemType, technicalName = giveawayItemTechName, count = giveawayDataForCallbacks.itemCount},
            winners = {},
            endedBy = tempCurrentGiveawayCreatorName
        })
        saveGiveawayHistory()
        return
    end

    local numWinnersToDraw = math.min(giveawayDataForCallbacks.maxWinners, #participantsList)
    local notificationForNotAllWinners = ""
    if giveawayDataForCallbacks.maxWinners > #participantsList and #participantsList > 0 then
        notificationForNotAllWinners = " " .. Translate('not_enough_participants_for_all_winners', giveawayDataForCallbacks.maxWinners, numWinnersToDraw)
    end

    local actualWinnersAwardedDetails = {}
    for i = 1, numWinnersToDraw do
        if #participantsList == 0 then break end
        local randomIndex = math.random(#participantsList)
        local winnerCandidate = participantsList[randomIndex]
        table.remove(participantsList, randomIndex)

        local xPlayerWinner = ESX.GetPlayerFromId(winnerCandidate.source)
        if xPlayerWinner then
            local playerSource = winnerCandidate.source
            local prizeGivenSuccessfully = false
            local rewardMsgKey = 'congratulations_reward'
            local rewardArg1 = giveawayItemLabel
            local rewardArg2 = nil

            if giveawayItemType == 'vehicle' then
                local awardId = "award_" .. playerSource .. "_" .. math.random(10000, 99999)
                pendingVehicleAwards[awardId] = {
                    winnerIdentifier = xPlayerWinner.identifier,
                    winnerName = winnerCandidate.name,
                    winnerSource = playerSource,
                    vehicleModel = giveawayItemTechName,
                    giveawayItemLabel = giveawayItemLabel,
                    originalGiveawayCreator = giveawayDataForCallbacks.creatorName,
                    prizeTechnicalName = giveawayItemTechName,
                    prizeCount = giveawayDataForCallbacks.itemCount
                }
                TriggerClientEvent('ns_giveaway:client_generatePlateAndFinalizeVehicle', playerSource, giveawayItemTechName, awardId)
                table.insert(winnerNamesForChat, winnerCandidate.name .. " (" .. Translate('vehicle_pending') .. "*)")
            else
                -- FROM HERE NEW ITEM GIVING
                if giveawayItemType == 'money' then
                    xPlayerWinner.addMoney(giveawayDataForCallbacks.itemCount)
                    rewardArg1 = ESX.Math.GroupDigits(giveawayDataForCallbacks.itemCount) .. "$"
                    prizeGivenSuccessfully = true
                elseif giveawayItemType == 'black_money' then
                    xPlayerWinner.addAccountMoney('black_money', giveawayDataForCallbacks.itemCount)
                    rewardArg1 = ESX.Math.GroupDigits(giveawayDataForCallbacks.itemCount) .. "$ " .. Translate('black_money_suffix')
                    prizeGivenSuccessfully = true
                elseif giveawayItemType == 'item' then
                    if Config.InventorySystem == 'ox_inventory' then
                        if exports.ox_inventory and exports.ox_inventory.AddItem then
                            local oxSuccess, oxReason = exports.ox_inventory:AddItem(playerSource, giveawayItemTechName, giveawayDataForCallbacks.itemCount)
                            if oxSuccess then
                                rewardMsgKey = 'congratulations_reward_item'
                                rewardArg1 = giveawayDataForCallbacks.itemCount
                                local oxItemInfo = exports.ox_inventory:Items(giveawayItemTechName)
                                rewardArg2 = oxItemInfo and oxItemInfo.label or giveawayItemTechName
                                prizeGivenSuccessfully = true
                            else
                                print(("^1[GiveawayScript-ERROR]^7 Error giving item '%s' to %s via ox_inventory. Reason: %s^7")
                                    :format(giveawayItemTechName, winnerCandidate.name, oxReason or "Unknown"))
                                TriggerClientEvent('esx:showNotification', playerSource,
                                    Translate('failed_to_give_item_ox', giveawayItemTechName, oxReason or "Unknown"), 'error', 7000)
                            end
                        else
                            print("^1[GiveawayScript-ERROR]^7 ox_inventory is not available although it's in the config.")
                            TriggerClientEvent('esx:showNotification', playerSource, Translate('inventory_system_unavailable'), 'error', 7000)
                        end
                    elseif Config.InventorySystem == 'esx' then
                        xPlayerWinner.addInventoryItem(giveawayItemTechName, giveawayDataForCallbacks.itemCount)
                        -- Try to find item label
                        local itemLabel = giveawayItemTechName
                        for _, item in ipairs(oxInventoryItemsCache) do
                            if item.name == giveawayItemTechName then
                                itemLabel = item.label
                                break
                            end
                        end
                        rewardMsgKey = 'congratulations_reward_item'
                        rewardArg1 = giveawayDataForCallbacks.itemCount
                        rewardArg2 = itemLabel
                        prizeGivenSuccessfully = true
                    end
                elseif giveawayItemType == 'license' then
                    TriggerEvent('esx_license:addLicense', playerSource, giveawayItemTechName, function()
                        TriggerClientEvent('esx:showNotification', playerSource,
                            Translate('congratulations_reward_license', giveawayItemLabel), 'success')
                    end)
                    rewardMsgKey = 'congratulations_reward_license'
                    prizeGivenSuccessfully = true
                end

                if prizeGivenSuccessfully then
                    table.insert(actualWinnersAwardedDetails, {name = winnerCandidate.name, identifier = xPlayerWinner.identifier, type = giveawayItemType})
                    table.insert(winnerNamesForChat, winnerCandidate.name)
                    if giveawayItemType ~= 'license' then
                        TriggerClientEvent('esx:showNotification', playerSource,
                            Translate(rewardMsgKey, rewardArg1, rewardArg2), 'success', 7000)
                    end
                    print(('^2[GiveawayScript]^7 %s (%s) won: %s (TechName: %s, Amount: %s).')
                        :format(winnerCandidate.name, xPlayerWinner.identifier, giveawayItemLabel, giveawayItemTechName, giveawayDataForCallbacks.itemCount))
                end
            end
        end
    end

    local winnersStringForChat = #winnerNamesForChat > 0 and table.concat(winnerNamesForChat, ", ") or Translate('no_winners_offline')
    announceMessageEnd = Translate('giveaway_ended_winners', giveawayItemLabel, winnersStringForChat) .. notificationForNotAllWinners

    SendAnnouncement(announceMessageEnd, "success")
    print(('^2[GiveawayScript]^7 Giveaway for %s ended. Winners: %s%s'):format(giveawayItemLabel, winnersStringForChat, notificationForNotAllWinners))

    for _, winnerDetail in ipairs(actualWinnersAwardedDetails) do
        table.insert(winnersDataForHistory, { name = winnerDetail.name, identifier = winnerDetail.identifier })
    end
    table.insert(giveawayHistory, {
        id = GetCurrentResourceName().."_"..os.time().."_hist_"..math.random(1000,9999).."_main",
        timestamp = os.time(),
        prize = {label = giveawayItemLabel, type = giveawayItemType, technicalName = giveawayItemTechName, count = giveawayDataForCallbacks.itemCount},
        winners = winnersDataForHistory,
        endedBy = giveawayDataForCallbacks.creatorName
    })
    saveGiveawayHistory()
    for adminSrc, isOpen in pairs(isAdminPanelOpen) do
        if isOpen then
            TriggerClientEvent('esx_giveaway:updateGiveawayHistory', adminSrc, giveawayHistory)
        end
    end
end

RegisterNetEvent('ns_giveaway:server_receiveGeneratedPlate')
AddEventHandler('ns_giveaway:server_receiveGeneratedPlate', function(plate, awardId, vehicleModelGiven)
    local src = source; local awardData = pendingVehicleAwards[awardId]
    if not awardData then print(("^3[GiveawayScript-WARN]^7 No pendingVehicleAward data found for AwardID %s."):format(awardId)); return end; pendingVehicleAwards[awardId] = nil
    if awardData.winnerSource ~= src then print(("^3[GiveawayScript-WARN]^7 Source conflict during plate handover for AwardID %s."):format(awardId)); return end
    if awardData.vehicleModel ~= vehicleModelGiven then TriggerClientEvent('esx:showNotification', src, Translate('plate_handover_model_conflict'), 'error'); return end
    if not plate or plate == "" then TriggerClientEvent('esx:showNotification', src, Translate('plate_generation_failed'), 'error'); return end

    local vehicleData = { model = GetHashKey(awardData.vehicleModel), plate = plate, plateIndex = 1,
        bodyHealth = 1000.0, engineHealth = 1000.0, fuelLevel = 100.0, dirtLevel = 0.0, color1 = 0, color2 = 0, pearlescentColor = 0, wheelColor = 0, wheels = 0, windowTint = 0, neonEnabled = {false, false, false, false}, neonColor = {255, 0, 255}, extras = {}, tyreSmokeColor = {255, 255, 255}, modSpoilers = -1, modFrontBumper = -1, modRearBumper = -1, modSideSkirt = -1, modExhaust = -1, modFrame = -1, modGrille = -1, modHood = -1, modFender = -1, modRightFender = -1, modRoof = -1, modEngine = -1, modBrakes = -1, modTransmission = -1, modHorns = -1, modSuspension = -1, modArmor = -1, modTurbo = false, modSmokeEnabled = false, modXenon = false, modFrontWheels = -1, modBackWheels = -1, modPlateHolder = -1, modVanityPlate = -1, modTrimA = -1, modOrnaments = -1, modDashboard = -1, modDial = -1, modDoorSpeaker = -1, modSeats = -1, modSteeringWheel = -1, modShifterLeavers = -1, modAPlate = -1, modSpeakers = -1, modTrunk = -1, modHydro = -1, modEngineBlock = -1, modAirFilter = -1, modStruts = -1, modArchCover = -1, modAerials = -1, modTrimB = -1, modTank = -1, modWindows = -1, modLivery = -1
    }
    local vehiclePropsJson = json.encode(vehicleData)

    local query = [[INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (@owner, @plate, @vehicle_props, @type, @stored)]]
    local params = { owner = awardData.winnerIdentifier, plate = plate, vehicle_props = vehiclePropsJson, type = 'car', stored = 1 }

    local success_db, result_db = pcall(MySQL.insert, query, params)
    if success_db then
        print(("^2[GiveawayScript-Vehicle]^7 Vehicle '%s' (Plate: %s) for %s (ID: %s) entered in DB."):format(awardData.vehicleModel, plate, awardData.winnerName, awardData.winnerIdentifier))
        TriggerClientEvent('esx:showNotification', awardData.winnerSource, Translate('congratulations_reward', awardData.giveawayItemLabel .. " (" .. awardData.vehicleModel .. ")"), 'success', 7000)

        local historyUpdated = false
        for i = #giveawayHistory, 1, -1 do
            local histEntry = giveawayHistory[i]
            if histEntry.prize.technicalName == awardData.prizeTechnicalName and histEntry.endedBy == awardData.originalGiveawayCreator and histEntry.id and string.find(histEntry.id, "_main$") then
                if not histEntry.winners then histEntry.winners = {} end
                for j = #histEntry.winners, 1, -1 do if histEntry.winners[j].identifier == awardData.winnerIdentifier and histEntry.winners[j].type == "vehicle_pending" then table.remove(histEntry.winners, j); break end end
                table.insert(histEntry.winners, { name = awardData.winnerName, identifier = awardData.winnerIdentifier, type = "vehicle_confirmed" }); historyUpdated = true; break
            end
        end
         if not historyUpdated then
             print(("^3[GiveawayScript-WARN]^7 Could not precisely assign main history entry for vehicle win for %s."):format(awardData.winnerName))
             table.insert(giveawayHistory, {id = GetCurrentResourceName().."_"..os.time().."_hist_veh_"..math.random(1000,9999), timestamp = os.time(), prize = {label = awardData.giveawayItemLabel, type = "vehicle", technicalName = awardData.vehicleModel, count = 1}, winners = {{ name = awardData.winnerName, identifier = awardData.winnerIdentifier, type = "vehicle_confirmed" }}, endedBy = awardData.originalGiveawayCreator})
        end
        saveGiveawayHistory()
        for adminSrc, isOpen in pairs(isAdminPanelOpen) do
            if isOpen then TriggerClientEvent('esx_giveaway:updateGiveawayHistory', adminSrc, giveawayHistory) end
        end
    else
        print(("^1[GiveawayScript-ERROR]^7 Error entering vehicle '%s' for %s in DB: %s"):format(awardData.vehicleModel, awardData.winnerName, result_db or "Unknown"))
        TriggerClientEvent('esx:showNotification', awardData.winnerSource, Translate('vehicle_save_failed'), 'error')
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if isAdminPanelOpen[src] then isAdminPanelOpen[src] = nil; end
    if currentGiveaway and currentGiveaway.participants then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and currentGiveaway.participants[xPlayer.identifier] then
            currentGiveaway.participants[xPlayer.identifier] = nil
        end
    end
    for awardId, awardData in pairs(pendingVehicleAwards) do
        if awardData.winnerSource == src then
            pendingVehicleAwards[awardId] = nil
        end
    end
end)

ESX.RegisterServerCallback('ns_giveaway:isPlateTaken', function(source, cb, plate)
    MySQL.scalar('SELECT 1 FROM owned_vehicles WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        if result then
            cb(true) -- Plate is taken
        else
            cb(false) -- Plate is free
        end
    end)
end)

RegisterCommand('cancelgiveaway', function(source, args, rawCommand)
    local src = source
    if not isAdmin(src) then TriggerClientEvent('esx:showNotification', src, Translate('not_admin'), 'error'); return end
    if not currentGiveaway or not currentGiveaway.announced then TriggerClientEvent('esx:showNotification', src, Translate('no_giveaway_active'), 'warning'); return end

    if currentGiveaway.timer then ClearTimeout(currentGiveaway.timer); currentGiveaway.timer = nil end
    local itemLabel = currentGiveaway.item.label
    local adminName = GetPlayerName(src)
    currentGiveaway = nil -- Important: Only set to nil here after itemLabel and adminName are secured

    local cancelMessage = Translate('giveaway_cancelled', itemLabel)

    SendAnnouncement(cancelMessage, "error") -- NEW way of announcing

    print(('^1[GiveawayScript]^7 Giveaway for %s was cancelled by %s.'):format(itemLabel, adminName))
    TriggerClientEvent('esx:showNotification', src, Translate('giveaway_cancelled_successfully'), 'success')
end, false)

print("^5[Zhora-Giveaway]^2 Script loaded.^7")