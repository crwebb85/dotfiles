-- taplo config is based on article https://www.arthurkoziel.com/json-schemas-in-neovim/
-- taplo loads all toml schemas from https://www.schemastore.org/api/json/catalog.json with little customization
---@type vim.lsp.Config
return {
    settings = {
        evenBetterToml = {
            schema = {
                -- add additional schemas
                -- associations = {
                --     ['example\\.toml$'] = 'https://json.schemastore.org/example.json',
                -- },
            },
        },
    },
}
