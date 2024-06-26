fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'TheStoicBear'
description 'Stoic-VehicleSystem'
version '1.0.0'
shared_scripts {
    "@ND_Core/init.lua",
    '@ox_lib/init.lua',
    'cl.lua',
    'turbokit.lua',
    'coilovers.lua',
    'engstages.lua',
    'transstages.lua',
}
client_scripts {
    'cl.lua',
    'target.lua',
    'turbokit.lua',
    'coilovers.lua',
    'engstages.lua',
    'transstages.lua',
}
server_scripts {
   '@oxmysql/lib/MySQL.lua',
   'sv.lua'
} 
files {
    'ui/index.html',
    'ui/style.css',
    'ui/app.js'
}

ui_page 'ui/index.html'