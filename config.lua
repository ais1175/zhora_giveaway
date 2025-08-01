Config = {}

-- ##################################################################################
-- ## NEUE: Language                                                     ##
-- ##################################################################################
Config.Language = 'de' -- de or en (default is 'de' for German)
Config.UseFallbackLanguage = true -- If true, fallback to Config.FallbackLanguage if primary language translation is missing
Config.FallbackLanguage = 'de' -- Fallback Translation

Config.InventorySystem = 'ox_inventory' -- 'ox_inventory' or 'esx' (for ESX Legacy)

Config.AdminGroups = {
    'superadmin',
    'admin',
}

Config.AdminCommand = 'giveaway'

Config.Prefix = 'NS' -- Prefix for vehicle license plates
Config.PlateLetters = 0 -- NEW: Number of random letters
Config.PlateNumbers = 4 -- NEW: Number of random numbers
Config.PlateUseSpace = false -- NEW: true if there should be a space between letters and numbers

Config.DefaultGiveawayDurationMinutes = 5
Config.MinGiveawayDurationMinutes = 1
Config.MaxGiveawayDurationMinutes = 120
Config.DefaultMaxWinners = 1
Config.MaxPossibleWinners = 10

Config.ManagedItemsFilePath = 'giveaway_managed_items.json'
Config.GiveawayHistoryFilePath = 'giveaway_history.json' 
Config.MaxGiveawayHistoryEntries = 30 

-- ##################################################################################
-- ## NEW: Configuration for Announcements                                        ##
-- ##################################################################################
-- Choose the system that should be used for announcements here.
-- Possible values: 'ns_announce', 'chat', 'custom_event', 'custom_export'
-- You can define additional systems in Config.Announcements below.
Config.AnnouncementSystem = 'ns_announce' -- Default is ns_announce

Config.Announcements = {
    -- Configuration for ns_announce (Popular announcement system)
    ns_announce = {
        type = 'event',                                 -- Type of interaction: 'event' or 'export'
        trigger = 'ns_announce:trigger',                -- Name of the server event or export function                  
                                                        -- Parameters for ns_announce: message, source_name, style
        defaultSourceName = "🎁 Giveaway 🎁",          -- Default sender name for the announcement
        defaultStyleInfo = "info",                      -- Default style for info messages
        defaultStyleSuccess = "success",                -- Default style for success messages
        defaultStyleWarning = "warning",                -- Default style for warning messages
        defaultStyleError = "error"                     -- Default style for error messages
    },

    -- Configuration for simple chat messages as fallback or alternative
    chat = {
        type = 'function',                              -- Special type to use internal chat function
        prefix = "[Giveaway]",                          -- Optional prefix for the chat message
        template = '<div style="padding: 0.4vw; margin: 0.4vw; background-color: rgba(50, 150, 255, 0.25); border-left: 3px solid #0A84FF; border-radius: 3px; color: #FFFFFF;"><i class="fas fa-gift" style="margin-right: 5px;"></i><strong>{0}:</strong> {1}</div>'
        -- {0} will be replaced with the prefix, {1} with the actual message.
        -- Make sure your chat supports HTML templates if you use this.
        -- For simple messages without HTML: TriggerClientEvent('chat:addMessage', -1, { args = { chatMessage } }) in server.lua
    },

    -- Example for another custom event-based system
    custom_event_example = {
        type = 'event',
        trigger = 'myCustomAnnouncer:announceGlobal',   -- Replace this with your event name
        -- Adjust the parameter passing in the SendAnnouncement function in server.lua,
        -- if your event expects different parameters than (message, title, style/type).
        -- For a simple version that only passes the message, no adjustment is needed.
        defaultTitle = "System Notification"
    },

    -- Example for an export-based system
    custom_export_example = {
        type = 'export',
        resource = 'myAnnounceResource',                -- Name of the resource that provides the export
        trigger = 'SendAnnouncementToAll',              -- Name of the export function
        -- Adjust the parameter passing in server.lua if your export expects different parameters.
        defaultTitle = "Important Info"
    }
    -- Add more configurations for other announcement systems here
}
-- ##################################################################################
-- ## END: Configuration for Announcements                                        ##
-- ##################################################################################


-- Translations
Locales = {
    ['de'] = {
        -- [[ German translations ]] --
        ['not_admin'] = "Du bist nicht berechtigt, diesen Befehl zu verwenden.",
        ['no_giveaway_active'] = "Aktuell läuft kein Giveaway.",
        ['already_entered'] = "Du nimmst bereits am Giveaway teil.",
        ['entered_giveaway'] = "Du nimmst jetzt am Giveaway für %s teil!",
        ['invalid_item_name_esx'] = "FEHLER: Der Item-Name '%s' existiert im aktuellen Inventarsystem nicht oder konnte nicht validiert werden.",
        ['failed_to_give_item_ox'] = "Fehler bei der Item-Vergabe für Item: %s. Grund: %s",
        ['item_def_type_item'] = "Item (aus Inventar)",
        ['item_def_ox_item_label'] = "Item (aus aktivem Inventar):",
        ['failed_to_give_item_esx'] = "Fehler bei der Item-Vergabe. Stelle sicher, dass du genug Platz für '%s' hast.",
        ['giveaway_started_by'] = "🎉 <b>GIVEAWAY GESTARTET!</b> 🎉<br><b>Admin:</b> %s<br><b>Verlost wird:</b> %s<br><b>Anzahl/Betrag:</b> %s<br><b>Es gibt %s Gewinner.</b><br><b>Teilnahme mit:</b> `/enter`.<br><b>Das Giveaway endet in %s Minuten.</b>",
        ['giveaway_ended_no_participants'] = "Das Giveaway für %s ist beendet. Leider hat niemand teilgenommen.",
        ['giveaway_ended_winners'] = "Das Giveaway für %s ist beendet!\nHerzlichen Glückwunsch an: %s!",
        ['giveaway_cancelled'] = "Das Giveaway für %s wurde von einem Admin abgebrochen.",
        ['not_enough_participants_for_all_winners'] = "Nicht genügend Teilnehmer, um %s Gewinner auszulosen. Es wurden %s Gewinner gezogen.",
        ['congratulations_reward'] = "🎉 GLÜCKWUNSCH! 🎉\nDu hast %s gewonnen!",
        ['congratulations_reward_item'] = "🎉 GLÜCKWUNSCH! 🎉\nDu hast %sx %s gewonnen!",
        ['congratulations_reward_license'] = "🎉 GLÜCKWUNSCH! 🎉\nDu hast die Lizenz '%s' gewonnen!",
        ['item_saved'] = "Item-Konfiguration erfolgreich gespeichert.",
        ['item_deleted'] = "Item-Konfiguration erfolgreich gelöscht.",
        ['invalid_vehicle_model_esx'] = "FEHLER: Das Fahrzeugmodell '%s' scheint ungültig zu sein.",
        ['item_def_label_exists'] = "Eine Item-Definition mit diesem Label existiert bereits.",
        ['confirm_delete_item_def'] = "Möchtest du die Item-Definition '%s' wirklich löschen?",
        ['ox_inventory_not_ready'] = "ox_inventory ist noch nicht bereit oder nicht gefunden. Item-Liste konnte nicht geladen werden.",
        ['giveaway_config_panel_title'] = "Giveaway Admin Panel",
        ['tab_start_giveaway'] = "Giveaway starten",
        ['tab_manage_items'] = "Items verwalten",
        ['configure_new_giveaway_title'] = "Neues Giveaway konfigurieren",
        ['select_giveaway_item_label'] = "Item auswählen:",
        ['select_giveaway_item_placeholder'] = "Bitte ein konfiguriertes Item auswählen",
        ['item_count_label_giveaway'] = "Anzahl / Betrag für dieses Giveaway:",
        ['duration_label_giveaway'] = "Dauer (in Minuten):",
        ['max_winners_label_giveaway'] = "Maximale Gewinner:",
        ['start_announce_button'] = "Giveaway starten & Ankündigen",
        ['manage_item_definitions_title'] = "Item-Definitionen für Giveaways verwalten",
        ['btn_close_form'] = "Formular schließen",
        ['btn_cancel_edit'] = "Bearbeitung abbrechen",
        ['btn_new_item_definition'] = "Neues Item definieren",
        ['edit_item_title'] = "Item bearbeiten",
        ['new_item_title'] = "Neues Item definieren",
        ['item_def_label_label'] = "Anzeige-Label (z.B. \"10x Brot\", \"Seltenes Auto\"):",
        ['item_def_type_label'] = "Typ:",
        ['item_def_type_money'] = "Bargeld (ESX)",
        ['item_def_type_black_money'] = "Schwarzgeld (ESX)",
        ['item_def_type_license'] = "Lizenz (ESX)",
        ['item_def_type_vehicle'] = "Fahrzeug (ESX Spawncode)",
        ['item_def_ox_item_placeholder'] = "Bitte Item wählen...",
        ['item_def_ox_item_hint'] = "Wähle ein Item aus der ox_inventory Liste.",
        ['item_def_tech_name_label'] = "Technischer Name / Spawncode:",
        ['item_def_tech_name_hint_item'] = "z.B. 'bread', 'water' (ESX Item Name - wird von ox_inventory Auswahl gefüllt)",
        ['item_def_tech_name_hint_money'] = "z.B. 'money' (wird für ESX addMoney verwendet)",
        ['item_def_tech_name_hint_black_money'] = "z.B. 'black_money' (für ESX addAccountMoney)",
        ['item_def_tech_name_hint_license'] = "z.B. 'weapon', 'drive' (ESX Lizenz Name)",
        ['item_def_tech_name_hint_vehicle'] = "z.B. 'adder', 'sultan' (Fahrzeug Spawncode)",
        ['item_def_default_value_label'] = "Standard Menge/Betrag (für dieses Item):",
        ['item_def_default_value_hint'] = "Dieser Wert wird beim Starten eines Giveaways als Voreinstellung für die Menge/den Betrag verwendet, kann aber dort überschrieben werden.",
        ['item_def_license_vehicle_info'] = "Lizenzen und Fahrzeuge werden immer 1x verlost. Die Menge wird ignoriert.",
        ['btn_save_item_changes'] = "Änderungen speichern",
        ['btn_save_item_definition'] = "Item-Definition speichern",
        ['btn_cancel'] = "Abbrechen",
        ['defined_items_title'] = "Definierte Items:",
        ['btn_edit'] = "Bearbeiten",
        ['btn_delete'] = "Löschen",
        ['no_items_defined_yet'] = "Noch keine Items für Giveaways definiert.",
        ['btn_close_admin_panel'] = "Admin Panel schließen",
        ['error_fill_all_fields'] = "Bitte alle Felder korrekt ausfüllen.",
        ['error_item_definition_fields'] = "Bitte alle erforderlichen Felder für die Item-Definition ausfüllen.",
        ['error_saving_item_def'] = "Fehler beim Speichern der Item-Definition.",
        ['error_unknown_giveaway_start'] = "Unbekannter Fehler beim Starten des Giveaways.",
        ['error_nui_communication'] = "Fehler bei der Kommunikation mit dem Server.",
        ['invalid_duration_or_winners'] = "Ungültige Eingabe für Dauer oder Anzahl der Gewinner.",
        ['duration_too_short'] = "Dauer muss mindestens %s Minute(n) betragen.",
        ['duration_too_long'] = "Dauer darf maximal %s Minute(n) betragen.",
        ['winners_too_few'] = "Es muss mindestens 1 Gewinner geben.",
        ['winners_too_many'] = "Die maximale Anzahl an Gewinnern ist %s.",
        ['tab_giveaway_history'] = "Verlauf",
        ['giveaway_history_title'] = "Vergangene Giveaways",
        ['history_date_time'] = "Datum/Zeit",
        ['history_prize'] = "Gewinn",
        ['history_winners'] = "Gewinner",
        ['history_no_entries'] = "Keine vergangenen Giveaways gefunden.",
        ['history_item_details'] = "%sx %s", -- e.g. 10x Bread
        ['history_money_details'] = "%s$", -- e.g. 10000$
        ['history_black_money_details'] = "%s$ (Schwarzgeld)", -- e.g. 5000$ (Black Money)
        ['history_license_details'] = "Lizenz: %s", -- e.g. License: Weapon License
        ['history_vehicle_details'] = "Fahrzeug: %s", -- e.g. Vehicle: Adder
        ['vehicle_spawncode_empty'] = "Fahrzeug-Spawncode darf nicht leer sein.",
        ['vehicle_validation_error'] = "Fehler bei Fahrzeugvalidierung (Modellkonflikt).",
        ['item_definition_not_found'] = "Item-Definition nicht gefunden.",
        ['giveaway_already_running'] = "Ein Giveaway läuft bereits.",
        ['selected_item_not_found'] = "Ausgewähltes Item nicht gefunden.",
        ['giveaway_started_successfully'] = "Giveaway erfolgreich gestartet!",
        ['vehicle_pending'] = "Fahrzeug",
        ['black_money_suffix'] = "Schwarzgeld",
        ['inventory_system_unavailable'] = "Fehler: Inventarsystem nicht verfügbar.",
        ['no_winners_offline'] = "Niemand (möglicherweise Offline)",
        ['plate_handover_model_conflict'] = "Fehler: Kennzeichenübergabe (Modellkonflikt).",
        ['plate_generation_failed'] = "Fehler: Kennzeichen nicht generiert.",
        ['vehicle_save_failed'] = "Fehler: Fahrzeug konnte nicht in deiner Garage gespeichert werden.",
        ['giveaway_cancelled_successfully'] = "Giveaway erfolgreich abgebrochen.",
    },

    ['en'] = {
        -- [[ English translations ]] --
        ['not_admin'] = "You are not authorized to use this command.",
        ['no_giveaway_active'] = "There is currently no active giveaway.",
        ['already_entered'] = "You are already participating in the giveaway.",
        ['entered_giveaway'] = "You are now participating in the giveaway for %s!",
        ['invalid_item_name_esx'] = "ERROR: The item name '%s' does not exist in the current inventory system or could not be validated.",
        ['failed_to_give_item_ox'] = "Failed to give item: %s. Reason: %s",
        ['item_def_type_item'] = "Item (from inventory)",
        ['item_def_ox_item_label'] = "Item (from active inventory):",
        ['failed_to_give_item_esx'] = "Failed to give item. Make sure you have enough space for '%s'.",
        ['giveaway_started_by'] = "🎉 <b>GIVEAWAY STARTED!</b> 🎉<br><b>Admin:</b> %s<br><b>Prize:</b> %s<br><b>Amount:</b> %s<br><b>There are %s winners.</b><br><b>Enter with:</b> `/enter`.<br><b>The giveaway ends in %s minutes.</b>",
        ['giveaway_ended_no_participants'] = "The giveaway for %s has ended. Unfortunately, no one participated.",
        ['giveaway_ended_winners'] = "The giveaway for %s has ended!\nCongratulations to: %s!",
        ['giveaway_cancelled'] = "The giveaway for %s was cancelled by an admin.",
        ['not_enough_participants_for_all_winners'] = "Not enough participants to draw %s winners. %s winners were drawn.",
        ['congratulations_reward'] = "🎉 CONGRATULATIONS! 🎉\nYou won %s!",
        ['congratulations_reward_item'] = "🎉 CONGRATULATIONS! 🎉\nYou won %sx %s!",
        ['congratulations_reward_license'] = "🎉 CONGRATULATIONS! 🎉\nYou won the license '%s'!",
        ['item_saved'] = "Item configuration successfully saved.",
        ['item_deleted'] = "Item configuration successfully deleted.",
        ['invalid_vehicle_model_esx'] = "ERROR: The vehicle model '%s' appears to be invalid.",
        ['item_def_label_exists'] = "An item definition with this label already exists.",
        ['confirm_delete_item_def'] = "Do you really want to delete the item definition '%s'?",
        ['ox_inventory_not_ready'] = "ox_inventory is not ready or not found. Item list could not be loaded.",
        ['giveaway_config_panel_title'] = "Giveaway Admin Panel",
        ['tab_start_giveaway'] = "Start Giveaway",
        ['tab_manage_items'] = "Manage Items",
        ['configure_new_giveaway_title'] = "Configure New Giveaway",
        ['select_giveaway_item_label'] = "Select Item:",
        ['select_giveaway_item_placeholder'] = "Please select a configured item",
        ['item_count_label_giveaway'] = "Amount / Quantity for this giveaway:",
        ['duration_label_giveaway'] = "Duration (in minutes):",
        ['max_winners_label_giveaway'] = "Maximum Winners:",
        ['start_announce_button'] = "Start & Announce Giveaway",
        ['manage_item_definitions_title'] = "Manage Item Definitions for Giveaways",
        ['btn_close_form'] = "Close Form",
        ['btn_cancel_edit'] = "Cancel Edit",
        ['btn_new_item_definition'] = "Define New Item",
        ['edit_item_title'] = "Edit Item",
        ['new_item_title'] = "Define New Item",
        ['item_def_label_label'] = "Display Label (e.g. \"10x Bread\", \"Rare Car\"):",
        ['item_def_type_label'] = "Type:",
        ['item_def_type_money'] = "Cash (ESX)",
        ['item_def_type_black_money'] = "Black Money (ESX)",
        ['item_def_type_license'] = "License (ESX)",
        ['item_def_type_vehicle'] = "Vehicle (ESX Spawncode)",
        ['item_def_ox_item_placeholder'] = "Please select item...",
        ['item_def_ox_item_hint'] = "Choose an item from the ox_inventory list.",
        ['item_def_tech_name_label'] = "Technical Name / Spawncode:",
        ['item_def_tech_name_hint_item'] = "e.g. 'bread', 'water' (ESX Item Name - filled by ox_inventory selection)",
        ['item_def_tech_name_hint_money'] = "e.g. 'money' (used for ESX addMoney)",
        ['item_def_tech_name_hint_black_money'] = "e.g. 'black_money' (for ESX addAccountMoney)",
        ['item_def_tech_name_hint_license'] = "e.g. 'weapon', 'drive' (ESX License Name)",
        ['item_def_tech_name_hint_vehicle'] = "e.g. 'adder', 'sultan' (Vehicle Spawncode)",
        ['item_def_default_value_label'] = "Default Amount/Quantity (for this item):",
        ['item_def_default_value_hint'] = "This value will be used as default for the amount/quantity when starting a giveaway, but can be overridden there.",
        ['item_def_license_vehicle_info'] = "Licenses and vehicles are always given 1x. The quantity is ignored.",
        ['btn_save_item_changes'] = "Save Changes",
        ['btn_save_item_definition'] = "Save Item Definition",
        ['btn_cancel'] = "Cancel",
        ['defined_items_title'] = "Defined Items:",
        ['btn_edit'] = "Edit",
        ['btn_delete'] = "Delete",
        ['no_items_defined_yet'] = "No items defined for giveaways yet.",
        ['btn_close_admin_panel'] = "Close Admin Panel",
        ['error_fill_all_fields'] = "Please fill all fields correctly.",
        ['error_item_definition_fields'] = "Please fill all required fields for the item definition.",
        ['error_saving_item_def'] = "Error saving the item definition.",
        ['error_unknown_giveaway_start'] = "Unknown error when starting the giveaway.",
        ['error_nui_communication'] = "Error communicating with the server.",
        ['invalid_duration_or_winners'] = "Invalid input for duration or number of winners.",
        ['duration_too_short'] = "Duration must be at least %s minute(s).",
        ['duration_too_long'] = "Duration may not exceed %s minute(s).",
        ['winners_too_few'] = "There must be at least 1 winner.",
        ['winners_too_many'] = "The maximum number of winners is %s.",
        ['tab_giveaway_history'] = "History",
        ['giveaway_history_title'] = "Past Giveaways",
        ['history_date_time'] = "Date/Time",
        ['history_prize'] = "Prize",
        ['history_winners'] = "Winners",
        ['history_no_entries'] = "No past giveaways found.",
        ['history_item_details'] = "%sx %s", -- e.g. 10x Bread
        ['history_money_details'] = "$%s", -- e.g. $10000
        ['history_black_money_details'] = "$%s (Black Money)", -- e.g. $5000 (Black Money)
        ['history_license_details'] = "License: %s", -- e.g. License: Weapon License
        ['history_vehicle_details'] = "Vehicle: %s", -- e.g. Vehicle: Adder
        ['vehicle_spawncode_empty'] = "Vehicle spawn code cannot be empty.",
        ['vehicle_validation_error'] = "Error in vehicle validation (model conflict).",
        ['item_definition_not_found'] = "Item definition not found.",
        ['giveaway_already_running'] = "A giveaway is already running.",
        ['selected_item_not_found'] = "Selected item not found.",
        ['giveaway_started_successfully'] = "Giveaway started successfully!",
        ['vehicle_pending'] = "Vehicle",
        ['black_money_suffix'] = "Black Money",
        ['inventory_system_unavailable'] = "Error: Inventory system not available.",
        ['no_winners_offline'] = "Nobody (possibly offline)",
        ['plate_handover_model_conflict'] = "Error: Plate handover (model conflict).",
        ['plate_generation_failed'] = "Error: License plate not generated.",
        ['vehicle_save_failed'] = "Error: Vehicle could not be saved in your garage.",
        ['giveaway_cancelled_successfully'] = "Giveaway cancelled successfully.",
    }
}

-- Translation function
function Translate(key, ...)
    local primaryLang = Config.Language or 'en'
    local fallbackLang = Config.FallbackLanguage or 'de'
    
    
    if Locales[primaryLang] and Locales[primaryLang][key] then
        return string.format(Locales[primaryLang][key], ...)
    end
    
    
    if Config.UseFallbackLanguage and fallbackLang ~= primaryLang and Locales[fallbackLang] and Locales[fallbackLang][key] then
        return string.format(Locales[fallbackLang][key], ...)
    end
    
    
    if primaryLang ~= 'en' and fallbackLang ~= 'en' and Locales['en'] and Locales['en'][key] then
        return string.format(Locales['en'][key], ...)
    end
    
    
    if primaryLang ~= 'de' and fallbackLang ~= 'de' and Locales['de'] and Locales['de'][key] then
        return string.format(Locales['de'][key], ...)
    end
    
    
    print(('[^1ERROR^7] Locale key "%s" not found for language "%s" or any fallback language'):format(key, primaryLang))
    return "Error: Locale not found - " .. key
end


function GetCurrentLanguage()
    return Config.Language or 'en'
end


function GetAvailableLanguages()
    local langs = {}
    for lang, _ in pairs(Locales) do
        table.insert(langs, lang)
    end
    return langs
end
