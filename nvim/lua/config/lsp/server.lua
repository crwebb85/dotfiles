local M = {
    default_config = false,
    setup_done = false,
}

local state = {
    exclude = {},
    capabilities = nil,
}

local function is_keyval(v) return type(v) == 'table' and not vim.tbl_islist(v) end

local function tbl_merge(old_val, new_val)
    for k, v in pairs(new_val) do
        if is_keyval(old_val[k]) and is_keyval(v) then
            tbl_merge(old_val[k], v)
        else
            old_val[k] = v
        end
    end
end

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

local function ensure_capabilities(server_config, user_config)
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
    local plugin_opts = set_capabilities().textDocument.completion

    local completion_opts =
        vim.tbl_deep_extend('force', default_opts, plugin_opts, user_opts)

    server_config.capabilities.textDocument.completion = completion_opts
end

local function compose_fn(config_callback, user_callback)
    return function(...)
        config_callback(...)
        user_callback(...)
    end
end

local function apply_global_config(config, user_config, defaults)
    local new_config = vim.deepcopy(defaults)
    tbl_merge(new_config, user_config)

    for key, val in pairs(new_config) do
        if is_keyval(val) and is_keyval(config[key]) then
            tbl_merge(config[key], val)
        elseif
            key == 'on_new_config'
            and config[key]
            and config[key] ~= new_config[key]
        then
            local cb = config[key]
            config[key] = compose_fn(cb, new_config[key])
        else
            config[key] = val
        end
    end
end

function M.extend_lspconfig()
    if M.setup_done then return end

    local util = require('lspconfig.util')

    util.default_config.capabilities = set_capabilities()

    util.on_setup = util.add_hook_after(
        util.on_setup,
        function(config, user_config)
            -- looks like some lsp servers can override the capabilities option
            -- during "config definition". so, now we have to do this.
            ensure_capabilities(config, user_config)
            -- TODO figure out why lsp config did this because as of now my config never sets
            -- M.default_config to a table
            if type(M.default_config) == 'table' then
                apply_global_config(config, user_config, M.default_config)
            end
        end
    )

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

return M
