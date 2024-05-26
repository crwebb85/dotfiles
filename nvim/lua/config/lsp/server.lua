local M = {}

local state = {
    exclude = {},
    default_capabilities = nil,
}

function M.get_default_capabilities()
    if state.default_capabilities == nil then
        -- Get neovim default lsp capabilities
        local base_capabilities = vim.lsp.protocol.make_client_capabilities()

        --Get completion capabilities from cmp
        local cmp_default_capabilities =
            require('cmp_nvim_lsp').default_capabilities()

        --Setup document_link_capabilities for my custom implementation
        --of the client capability
        local document_link_capabilities = {
            textDocument = {
                documentLink = {
                    dynamicRegistration = true,
                },
            },
        }

        state.default_capabilities = vim.tbl_deep_extend(
            'force',
            base_capabilities,
            cmp_default_capabilities,
            document_link_capabilities
        )
    end
    return state.default_capabilities
end

function M.setup(name, opts)
    if type(name) ~= 'string' or state.exclude[name] then return false end

    if type(opts) ~= 'table' then opts = {} end

    --ensure lsp won't be setup twice by adding to the exclude list
    if type(name) == 'string' then state.exclude[name] = true end

    local lsp = require('lspconfig')[name]

    if lsp.manager then
        vim.notify('Lsp ' .. name .. ' is not configured by lspconfig')
        return false
    end

    if opts.capabilities == nil then opts.capabilities = {} end

    opts.capabilities = vim.tbl_deep_extend(
        'force',
        M.get_default_capabilities(),
        opts.capabilities
    )

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
