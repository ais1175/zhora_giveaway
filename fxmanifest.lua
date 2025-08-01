fx_version 'cerulean'
game 'gta5'

author 'Zhora/Genesis_NS'
description 'Giveaway Script with NUI from NIGHT-Scene'
version '1.2.0' 

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@es_extended/locale.lua',
    'server/lib/json.lua', 
    'config.lua',
    'server/server.lua'
}


client_scripts {
    '@es_extended/locale.lua',
    'config.lua',
    'client/client.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/assets/*.js',        -- React Build Files
    'html/assets/*.css',       -- Statt einzelne .js/.css
    'giveaway_managed_items.json',
    'giveaway_history.json'
}

dependencies {
    'es_extended',
    'ox_inventory',
    'oxmysql'
}

