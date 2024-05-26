local M = {
    -- default_config = false,
    -- setup_done = false,
}

local state = {
    exclude = {},
    capabilities = nil,
}

--From https://github.com/hrsh7th/cmp-nvim-lsp/blob/39e2eda76828d88b773cc27a3f61d2ad782c922d/lua/cmp_nvim_lsp/init.lua#L37
local cmp_default_capabilities = {
    textDocument = {
        completion = {
            dynamicRegistration = false,
            completionItem = {
                snippetSupport = true,
                commitCharactersSupport = true,
                deprecatedSupport = true,
                preselectSupport = true,
                tagSupport = {
                    valueSet = {
                        1, -- Deprecated
                    },
                },
                insertReplaceSupport = true,
                resolveSupport = {
                    properties = {
                        'documentation',
                        'detail',
                        'additionalTextEdits',
                        'sortText',
                        'filterText',
                        'insertText',
                        'textEdit',
                        'insertTextFormat',
                        'insertTextMode',
                    },
                },
                insertTextModeSupport = {
                    valueSet = {
                        1, -- asIs
                        2, -- adjustIndentation
                    },
                },
                labelDetailsSupport = true,
            },
            contextSupport = true,
            insertTextMode = 1,
            completionList = {
                itemDefaults = {
                    'commitCharacters',
                    'editRange',
                    'insertTextFormat',
                    'insertTextMode',
                    'data',
                },
            },
        },
    },
}

function M.get_capabilities() return state.capabilities end

local function set_capabilities(current)
    if state.capabilities == nil then
        local base_capabilities =
            require('lspconfig.util').default_config.capabilities
        -- if I ever stop using lspconfig the alternative is
        -- local base_capabilities = vim.lsp.protocol.make_client_capabilities()

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
                    -- this might not be needed because document links to the golang
                    -- documentation from a go import statment seems to work without this line
                    -- I am leaving this here in case there is an LSP that needs it explicitly set
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
