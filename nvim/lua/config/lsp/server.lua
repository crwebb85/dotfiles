local M = {
    default_config = false,
    has_lspconfig = false,
    cmp_capabilities = false,
    setup_done = false,
}

local s = {}

local state = {
    exclude = {},
    capabilities = nil,
}
function M.extend_lspconfig()
    if M.setup_done then return end

    local util = require('lspconfig.util')

    util.default_config.capabilities = s.set_capabilities()

    util.on_setup = util.add_hook_after(
        util.on_setup,
        function(config, user_config)
            -- looks like some lsp servers can override the capabilities option
            -- during "config definition". so, now we have to do this.
            s.ensure_capabilities(config, user_config)

            if type(M.default_config) == 'table' then
                s.apply_global_config(config, user_config, M.default_config)
            end
        end
    )

    M.has_lspconfig = true
    M.setup_done = true
end

function M.setup(name, opts)
    if type(name) ~= 'string' or state.exclude[name] then return false end

    if type(opts) ~= 'table' then opts = {} end

    M.skip_setup(name)

    local lsp = require('lspconfig')[name]

    if lsp.manager then return false end

    local ok = pcall(lsp.setup, opts)

    if not ok then
        local msg = '[lsp] Failed to setup %s.\n'
            .. 'Configure this server using lspconfig to get the full error message.'

        vim.notify(msg:format(name), vim.log.levels.WARN)
        return false
    end

    return true
end

--TODO use this to configure lua_ls
function M.nvim_workspace(opts)
    local runtime_path = vim.split(package.path, ';')
    table.insert(runtime_path, 'lua/?.lua')
    table.insert(runtime_path, 'lua/?/init.lua')

    local config = {
        settings = {
            Lua = {
                -- Disable telemetry
                telemetry = { enable = false },
                runtime = {
                    -- Tell the language server which version of Lua you're using
                    -- (most likely LuaJIT in the case of Neovim)
                    version = 'LuaJIT',
                    path = runtime_path,
                },
                diagnostics = {
                    -- Get the language server to recognize the `vim` global
                    globals = { 'vim' },
                },
                workspace = {
                    checkThirdParty = false,
                    library = {
                        -- Make the server aware of Neovim runtime files
                        vim.fn.expand('$VIMRUNTIME/lua'),
                        vim.fn.stdpath('config') .. '/lua',
                    },
                },
            },
        },
    }

    return vim.tbl_deep_extend('force', config, opts or {})
end

function M.skip_setup(name)
    if type(name) == 'string' then state.exclude[name] = true end
end

function M.has_configs()
    local configs = require('lspconfig.configs')

    for _, c in pairs(configs) do
        if c.manager then return true end
    end

    return false
end

function s.set_capabilities(current)
    if state.capabilities == nil then
        local cmp_default_capabilities = {}
        local base = {}

        if M.has_lspconfig then
            base = require('lspconfig.util').default_config.capabilities
        else
            base = vim.lsp.protocol.make_client_capabilities()
        end

        local ok, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
        if ok then
            M.cmp_capabilities = true
            cmp_default_capabilities = cmp_lsp.default_capabilities()
        end

        state.capabilities = vim.tbl_deep_extend(
            'force',
            base,
            cmp_default_capabilities,
            current or {}
        )

        return state.capabilities
    end

    if current == nil then return state.capabilities end

    return vim.tbl_deep_extend('force', state.capabilities, current)
end

function s.ensure_capabilities(server_config, user_config)
    local config_def = require('lspconfig.configs')[server_config.name]

    if type(config_def) ~= 'table' then return end

    local get_completion = function(val)
        return vim.tbl_get(val, 'capabilities', 'textDocument', 'completion')
    end

    local defaults =
        vim.tbl_get(config_def, 'document_config', 'default_config')
    local default_opts = get_completion(defaults or {})

    if defaults == nil or default_opts == nil then return end

    local user_opts = get_completion(user_config) or {}
    local plugin_opts = s.set_capabilities().textDocument.completion

    local completion_opts =
        vim.tbl_deep_extend('force', default_opts, plugin_opts, user_opts)

    server_config.capabilities.textDocument.completion = completion_opts
end

function s.apply_global_config(config, user_config, defaults)
    local new_config = vim.deepcopy(defaults)
    s.tbl_merge(new_config, user_config)

    for key, val in pairs(new_config) do
        if s.is_keyval(val) and s.is_keyval(config[key]) then
            s.tbl_merge(config[key], val)
        elseif
            key == 'on_new_config'
            and config[key]
            and config[key] ~= new_config[key]
        then
            local cb = config[key]
            config[key] = s.compose_fn(cb, new_config[key])
        else
            config[key] = val
        end
    end
end

function s.compose_fn(config_callback, user_callback)
    return function(...)
        config_callback(...)
        user_callback(...)
    end
end

function s.is_keyval(v) return type(v) == 'table' and not vim.tbl_islist(v) end

function s.tbl_merge(old_val, new_val)
    for k, v in pairs(new_val) do
        if s.is_keyval(old_val[k]) and s.is_keyval(v) then
            s.tbl_merge(old_val[k], v)
        else
            old_val[k] = v
        end
    end
end

return M