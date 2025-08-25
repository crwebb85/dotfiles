-- jsonls config is based on article https://www.arthurkoziel.com/json-schemas-in-neovim/
-- Config type is defined in https://github.com/microsoft/vscode/blob/30b777312745e84972956d4361465d4d38aa0f78/extensions/json-language-features/server/src/jsonServer.ts#L202C2-L218C3
local json_schemas = require('schemastore').json.schemas({
    select = {
        'Renovate',
        'GitHub Workflow Template Properties',
    },
    -- extra = {
    --     {
    --         description = 'Schema for luals lsp configuration file',
    --         name = 'LuaLS Settings',
    --         url = 'https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json',
    --         fileMatch = { '.luarc.json', '.luarc.jsonc' },
    --     },
    -- },
})
-- Adding the schemas to the extra tab doesn't seem to be working
table.insert(json_schemas, {
    description = 'Schema for luals lsp configuration file',
    name = 'LuaLS Settings',
    url = 'https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json',
    fileMatch = { '.luarc.json', '.luarc.jsonc' },
})
local jsonls_cfg = {
    settings = {
        json = {
            schemas = json_schemas,
            validate = { enable = true },
        },
    },
}

return jsonls_cfg
