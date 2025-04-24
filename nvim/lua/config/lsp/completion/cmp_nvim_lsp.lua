local M = {}

local client_source_map = {}

function M.enable_cmp_completion()
    --From https://github.com/hrsh7th/cmp-nvim-lsp/blob/a8912b88ce488f411177fc8aed358b04dc246d7b/lua/cmp_nvim_lsp/init.lua
    local source = require('config.lsp.completion.cmp_nvim_lsp_source')
    local cmp = require('cmp')

    local allowed_clients = {}

    -- register all active clients.
    for _, client in ipairs(vim.lsp.get_clients()) do
        allowed_clients[client.id] = client
        if not client_source_map[client.id] then
            local s = source.new(client)
            if s:is_available() then
                client_source_map[client.id] =
                    cmp.register_source('nvim_lsp', s)
            end
        end
    end

    -- register all buffer clients (early register before activation)
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
        allowed_clients[client.id] = client
        if not client_source_map[client.id] then
            local s = source.new(client)
            if s:is_available() then
                client_source_map[client.id] =
                    cmp.register_source('nvim_lsp', s)
            end
        end
    end

    -- unregister stopped/detached clients.
    for client_id, source_id in pairs(client_source_map) do
        if
            not allowed_clients[client_id]
            or allowed_clients[client_id]:is_stopped()
        then
            cmp.unregister_source(source_id)
            client_source_map[client_id] = nil
        end
    end
end
return M
