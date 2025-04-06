fx_version 'cerulean'
game 'gta5'

author 'SicilianoStudio'
description 'Sistema avanzato per il ban temporaneo delle armi'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'es_extended',
    'mysql-async'
}
