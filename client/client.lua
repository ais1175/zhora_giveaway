ESX = nil
local isAdminPanelVisible = false
local panelInitData = {
    managedItems = {},
    panelConfig = {},
    oxInventoryItems = {},
    giveawayHistory = {}
}
local esxReady = false 

Citizen.CreateThread(function() 
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
    Citizen.Wait(1000) 
    esxReady = true
    print("[ZhoraGiveaway-CLIENT] ESX ready.")
end)

-- [[ NEW FUNCTION: Custom license plate generation ]] -- Function from esx_vehicleshop
local NumberCharset = {}
local Charset = {}

for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end
for i = 65,  90 do table.insert(Charset, string.char(i)) end

-- for i = 97, 122 do table.insert(Charset, string.char(i)) end -- Uncomment this line if you want lowercase letters as well

function GetRandomNumber(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
	else
		return ''
	end
end

function GetRandomLetter(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)]
	else
		return ''
	end
end

function GeneratePlate()
	local generatedPlate
	local doBreak = false

	while true do
		Citizen.Wait(2)
		math.randomseed(GetGameTimer())

        -- We use the prefix from your config here and add random numbers/letters
        -- Adjust the values if you want more or fewer characters.
        -- The result would be e.g. "NS-A1B 2C3" or whatever you set in the config.
		if Config.PlateUseSpace then
			generatedPlate = string.upper(Config.Prefix .. GetRandomLetter(Config.PlateLetters) .. ' ' .. GetRandomNumber(Config.PlateNumbers))
		else
			generatedPlate = string.upper(Config.Prefix .. GetRandomLetter(Config.PlateLetters) .. GetRandomNumber(Config.PlateNumbers))
		end

        -- Make sure the license plate is not too long (max. 8 characters for GTA)
        if string.len(generatedPlate) > 8 then
            generatedPlate = string.sub(generatedPlate, 1, 8)
        end

		ESX.TriggerServerCallback('ns_giveaway:isPlateTaken', function (isPlateTaken)
			if not isPlateTaken then
				doBreak = true
			end
		end, generatedPlate)

		if doBreak then
			break
		end
	end

	return generatedPlate
end




RegisterCommand('enter', function(source, args, rawCommand)
    TriggerServerEvent('esx_giveaway:enter')
end, false)

-- Event to open/close the admin panel
RegisterNetEvent('esx_giveaway:toggleAdminPanel')
AddEventHandler('esx_giveaway:toggleAdminPanel', function(show, managedItems, panelServerConfig, oxItems, history)
    isAdminPanelVisible = show
    SendNUIMessage({
        action = 'setVisible',
        status = isAdminPanelVisible
    })

    if isAdminPanelVisible then
        panelInitData.managedItems = managedItems or {}
        panelInitData.panelConfig = panelServerConfig or {}
        panelInitData.oxInventoryItems = oxItems or {}
        panelInitData.giveawayHistory = history or {}

        SetNuiFocus(true, true)
        
        -- ##################################################################################
        -- ## NEW: Config-based language selection                                        ##
        -- ##################################################################################
        local currentLang = Config.Language or 'en'
        local fallbackLang = Config.FallbackLanguage or 'de'
        local activeLocales = nil
        
        
        if Locales and Locales[currentLang] then
            activeLocales = Locales[currentLang]
            print(("^2[ZhoraGiveaway-CLIENT]^7 Using primary language: %s"):format(currentLang))
        
        elseif Config.UseFallbackLanguage and Locales and Locales[fallbackLang] then
            activeLocales = Locales[fallbackLang]
            print(("^3[ZhoraGiveaway-CLIENT-INFO]^7 Primary language '%s' not found, using fallback '%s'"):format(currentLang, fallbackLang))
        
        elseif Locales and Locales['en'] then
            activeLocales = Locales['en']
            print("^3[ZhoraGiveaway-CLIENT-INFO]^7 Using English as last resort")
        
        elseif Locales and Locales['de'] then
            activeLocales = Locales['de']
            print("^3[ZhoraGiveaway-CLIENT-INFO]^7 Using German as absolute last resort")
        end
        
        if activeLocales then
            SendNUIMessage({
                action = 'initData',
                items = panelInitData.managedItems,
                config = panelInitData.panelConfig,
                oxInventoryItems = panelInitData.oxInventoryItems,
                giveawayHistory = panelInitData.giveawayHistory,
                locales = activeLocales,
                language = currentLang,
                languageConfig = {
                    primary = currentLang,
                    fallback = fallbackLang,
                    useFallback = Config.UseFallbackLanguage
                }
            })
        else
            print("^1[ZhoraGiveaway-CLIENT-ERROR] No valid locales found for NUI initialization!^7")
            SendNUIMessage({
                action = 'initData',
                items = panelInitData.managedItems,
                config = panelInitData.panelConfig,
                oxInventoryItems = panelInitData.oxInventoryItems,
                giveawayHistory = panelInitData.giveawayHistory,
                locales = {},
                language = currentLang,
                languageConfig = {
                    primary = currentLang,
                    fallback = fallbackLang,
                    useFallback = Config.UseFallbackLanguage
                }
            })
        end
        -- ##################################################################################
        -- ## END: Config-based language selection                                        ##
        -- ##################################################################################
    else
        SetNuiFocus(false, false)
    end
end)

RegisterNetEvent('esx_giveaway:updateManagedItemsList')
AddEventHandler('esx_giveaway:updateManagedItemsList', function(updatedManagedItems, updatedOxItems)
    panelInitData.managedItems = updatedManagedItems or panelInitData.managedItems
    panelInitData.oxInventoryItems = updatedOxItems or panelInitData.oxInventoryItems
    if isAdminPanelVisible then
        SendNUIMessage({
            action = 'updateItems',
            items = panelInitData.managedItems,
            oxInventoryItems = panelInitData.oxInventoryItems
        })
    end
end)

RegisterNetEvent('esx_giveaway:updateGiveawayHistory')
AddEventHandler('esx_giveaway:updateGiveawayHistory', function(updatedHistory)
    panelInitData.giveawayHistory = updatedHistory or panelInitData.giveawayHistory
    if isAdminPanelVisible then
        SendNUIMessage({
            action = 'updateHistory',
            history = panelInitData.giveawayHistory
        })
    end
end)

RegisterNetEvent('ns_giveaway:client_validateVehicleModel')
AddEventHandler('ns_giveaway:client_validateVehicleModel', function(vehicleModelName, validationId)
    local isValid = false
    local modelHash = GetHashKey(vehicleModelName)

    if vehicleModelName and vehicleModelName ~= "" and modelHash ~= 0 then
        RequestModel(modelHash)
        local attempts = 0
        while not HasModelLoaded(modelHash) and attempts < 100 do
            Citizen.Wait(100)
            attempts = attempts + 1
        end

        if HasModelLoaded(modelHash) then
            if IsModelAVehicle(modelHash) then
                isValid = true
                print(("[ZhoraGiveaway-CLIENT] Model %s (Hash: %s) successfully validated and loaded."):format(vehicleModelName, modelHash))
            else
                print(("[ZhoraGiveaway-CLIENT] Validation failed: Model %s (Hash: %s) is not a vehicle model."):format(vehicleModelName, modelHash))
            end
            SetModelAsNoLongerNeeded(modelHash)
        else
            print(("[ZhoraGiveaway-CLIENT] Validation failed: Model %s (Hash: %s) could not be loaded after %d attempts."):format(vehicleModelName, modelHash, attempts))
        end
    else
        print(("[ZhoraGiveaway-CLIENT] Validation failed: Invalid or empty vehicle model name '%s' (Hash: %s)."):format(tostring(vehicleModelName), modelHash))
    end

    TriggerServerEvent('ns_giveaway:server_receiveVehicleValidationResult', vehicleModelName, isValid, validationId)
end)


RegisterNetEvent('ns_giveaway:client_generatePlateAndFinalizeVehicle')
AddEventHandler('ns_giveaway:client_generatePlateAndFinalizeVehicle', function(vehicleModel, awardId)
    Citizen.CreateThread(function()
        while not esxReady do
            Citizen.Wait(100)
        end

        
        local plate = GeneratePlate()

        if plate and plate ~= "" then
            print(("[ZhoraGiveaway-CLIENT] Guaranteed unique license plate '%s' for vehicle %s (Award ID: %s) generated."):format(plate, vehicleModel, awardId))
        else
            print(("^1[ZhoraGiveaway-CLIENT-ERROR]^7 GeneratePlate() returned an invalid license plate (empty or nil) for Award ID %s. Plate: %s^7"):format(awardId, tostring(plate)))
            plate = nil
        end
        TriggerServerEvent('ns_giveaway:server_receiveGeneratedPlate', plate, awardId, vehicleModel)
    end)
end)

-- NUI Callbacks
RegisterNUICallback('startGiveaway', function(data, cb)
    if data and data.itemId and data.durationMinutes and data.maxWinners then
        TriggerServerEvent('esx_giveaway:startGiveaway', data)
        cb({ok = true, msg = Translate('giveaway_starting') or "Giveaway is starting..."})
    else
        cb({ok = false, error = Translate('invalid_data_received') or "Invalid data received from panel."})
    end
end)

RegisterNUICallback('saveItemDefinition', function(itemDef, cb)
    if itemDef and itemDef.label and itemDef.type and itemDef.item_name then
        TriggerServerEvent('esx_giveaway:saveItemDefinition', itemDef)
        cb({ok = true, msg = Translate('item_save_request_sent') or "Save request for item definition sent..."})
    else
        cb({ok = false, error = Translate('invalid_item_definition_data') or "Invalid item definition data."})
    end
end)

RegisterNUICallback('deleteItemDefinition', function(itemDefId, cb)
    if itemDefId then
        TriggerServerEvent('esx_giveaway:deleteItemDefinition', itemDefId)
        cb({ok = true})
    else
        cb({ok = false, error = Translate('no_item_id_to_delete') or "No item ID received for deletion."})
    end
end)

RegisterNUICallback('closeAdminPanel', function(data, cb)
    isAdminPanelVisible = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setVisible', status = false })
    TriggerServerEvent('esx_giveaway:adminPanelClosedByUI')
    cb({ok = true})
end)

-- Thread to close panel with ESC
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isAdminPanelVisible and IsControlJustReleased(0, 177) then -- VK_BACK (ESC Key)
            isAdminPanelVisible = false
            SetNuiFocus(false, false)
            SendNUIMessage({
                action = 'setVisible',
                status = false
            })
            TriggerServerEvent('esx_giveaway:adminPanelClosedByUI')
        end
    end
end)

-- ##################################################################################
-- ## OPTIONAL: Client-side language helper functions                             ##
-- ##################################################################################


function GetCurrentLanguage()
    return Config and Config.Language or 'en'
end


function GetAvailableLanguages()
    if not Locales then return {} end
    local langs = {}
    for lang, _ in pairs(Locales) do
        table.insert(langs, lang)
    end
    return langs
end


function ClientTranslate(key, ...)
    if Translate then
        return Translate(key, ...)
    end
    
    
    local currentLang = GetCurrentLanguage()
    
    if Locales and Locales[currentLang] and Locales[currentLang][key] then
        return string.format(Locales[currentLang][key], ...)
    elseif Locales and Locales['en'] and Locales['en'][key] then
        return string.format(Locales['en'][key], ...)
    elseif Locales and Locales['de'] and Locales['de'][key] then
        return string.format(Locales['de'][key], ...)
    else
        return "Translation not found: " .. key
    end
end


function PrintClientLanguageInfo()
    print("^5[ZhoraGiveaway-CLIENT]^7 Language Configuration:")
    print(("  Primary Language: %s"):format(Config and Config.Language or 'unknown'))
    print(("  Fallback Language: %s"):format(Config and Config.FallbackLanguage or 'unknown'))
    print(("  Use Fallback: %s"):format(Config and tostring(Config.UseFallbackLanguage) or 'unknown'))
    
    if Locales then
        local availableLangs = GetAvailableLanguages()
        print(("  Available Languages: %s"):format(table.concat(availableLangs, ", ")))
    else
        print("  Available Languages: None (Locales not loaded)")
    end
end


Citizen.CreateThread(function()
    Wait(3000) 
    if Config then
        print(("^5[ZhoraGiveaway-CLIENT]^2 Loaded with language: %s^7"):format(Config.Language or 'en'))
        -- Uncomment next line for detailed language info on startup:
        -- PrintClientLanguageInfo()
    end
end)

-- ##################################################################################
-- ## END: Client-side language helper functions                                  ##
-- ##################################################################################