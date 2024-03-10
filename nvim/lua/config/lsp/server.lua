local M = {
    -- default_config = false,
    -- setup_done = false,
}

local state = {
    exclude = {},
    capabilities = nil,
}

function M.get_capabilities() return state.capabilities end

local function set_capabilities(current)
    if state.capabilities == nil then
        local base_capabilities =
            require('lspconfig.util').default_config.capabilities
        -- if I ever stop using lspconfig the alternative is
        -- local base_capabilities = vim.lsp.protocol.make_client_capabilities()

        local cmp_default_capabilities =
            require('cmp_nvim_lsp').default_capabilities()

        state.capabilities = vim.tbl_deep_extend(
            'force',
            base_capabilities,
            cmp_default_capabilities,
            current or {}
        )

        return state.capabilities
    end

    if current == nil then return state.capabilities end

    return vim.tbl_deep_extend('force', state.capabilities, current)
end

function M.setup(name, opts)
    if type(name) ~= 'string' or state.exclude[name] then return false end

    if type(opts) ~= 'table' then opts = {} end

    --ensure lsp won't be setup twice by adding to the exclude list
    if type(name) == 'string' then state.exclude[name] = true end

    if state.capabilities == nil then
        set_capabilities({
            textDocument = {
                documentLink = {
                    dynamicRegistration = true,
                },
            },
        })
    end

    -- vim.print(state.capabilities)
    local lsp = require('lspconfig')[name]

    if lsp.manager then return false end --TODO maybe should throw an error

    opts.capabilities = state.capabilities

    -- vim.print('setting up', name)
    -- vim.print(opts)
    local ok = pcall(lsp.setup, opts)

    if not ok then
        local msg = '[lsp] Failed to setup %s.\n'
            .. 'Configure this server using lspconfig to get the full error message.'

        vim.notify(msg:format(name), vim.log.levels.WARN)
        return false
    end

    return true
end

return M
