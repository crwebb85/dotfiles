--Begin setup.lua
if vim.g.loaded_lsp_zero == 1 then return { ok = false } end

vim.g.loaded_lsp_zero = 1

local Setup = {}
Setup.ok = true
Setup.done = false

---
-- Commands
---
local function setup_server(input)
    local opts = {}
    if input.bang then
        opts.root_dir = function() return vim.fn.get_cwd() end
    end

    M.use(input.fargs, opts)
end

vim.api.nvim_create_user_command('LspZeroSetupServers', setup_server, {
    bang = true,
    nargs = '*',
})

vim.api.nvim_create_user_command(
    'LspZeroWorkspaceAdd',
    'lua vim.lsp.buf.add_workspace_folder()',
    {}
)

vim.api.nvim_create_user_command(
    'LspZeroWorkspaceList',
    'lua vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()))',
    {}
)

local function inspect_config_source(input)
    local server = input.args
    local mod = 'lua/lspconfig/server_configurations/%s.lua'
    local path = vim.api.nvim_get_runtime_file(mod:format(server), 0)

    if path[1] == nil then
        local msg = "[lsp-zero] Could not find configuration for '%s'"
        vim.notify(msg:format(server), vim.log.levels.WARN)
        return
    end

    vim.cmd.sview({
        args = { path[1] },
        mods = { vertical = true },
    })
end

local function config_source_complete(user_input)
    local mod = 'lua/lspconfig/server_configurations'
    local path = vim.api.nvim_get_runtime_file(mod, 0)[1]
    local pattern = '%s/*.lua'

    local list = vim.split(vim.fn.glob(pattern:format(path)), '\n')
    local res = {}

    for _, i in ipairs(list) do
        local name = vim.fn.fnamemodify(i, ':t:r')
        if vim.startswith(name, user_input) then res[#res + 1] = name end
    end

    return res
end

vim.api.nvim_create_user_command(
    'LspZeroViewConfigSource',
    inspect_config_source,
    {
        nargs = 1,
        complete = config_source_complete,
    }
)

---
-- Autocommands
---
local lsp_cmds =
    vim.api.nvim_create_augroup('lsp_zero_attach', { clear = true })

local function lsp_attach(event)
    local Server = require('config.lsp.server')
    local bufnr = event.buf

    Server.set_buf_commands(bufnr)

    if Server.common_attach then
        local id = vim.tbl_get(event, 'data', 'client_id')
        local client = {}

        if id then client = vim.lsp.get_client_by_id(id) end

        Server.common_attach(client, bufnr)
    end
end

vim.api.nvim_create_autocmd('LspAttach', {
    group = lsp_cmds,
    desc = 'lsp-zero on_attach',
    callback = lsp_attach,
})

local function setup_lspconfig()
    local extend = vim.g.lsp_zero_extend_lspconfig

    if extend == false or extend == 0 then return end

    local ok = (
        vim.g.lspconfig == 1
        or #vim.api.nvim_get_runtime_file('doc/lspconfig.txt', 0) > 0
    )

    if not ok then
        local show_msg = function()
            if vim.g.lspconfig ~= 1 then return end

            local Server = require('config.lsp.server')
            if Server.setup_done then return end

            local err_msg = '[lsp-zero] Could not configure lspconfig\n'
                .. 'during initial setup. Some features may fail.'
                .. '\n\nDetails on how to solve this problem are in the help page.\n'
                .. 'Execute the following command\n\n:help lsp-zero-guide:fix-extend-lspconfig'

            vim.notify(err_msg, vim.log.levels.WARN)
        end

        vim.api.nvim_create_autocmd(
            'LspAttach',
            { once = true, callback = show_msg }
        )
        return
    end

    local Server = require('config.lsp.server')

    if Server.has_configs() then
        local err_msg = '[lsp-zero] Some language servers have been configured before\n'
            .. 'lsp-zero could finish its initial setup. Some features may fail.'
            .. '\n\nDetails on how to solve this problem are in the help page.\n'
            .. 'Execute the following command\n\n:help lsp-zero-guide:fix-extend-lspconfig'

        vim.notify(err_msg, vim.log.levels.WARN)
        return
    end

    Server.has_lspconfig = true
    Server.extend_lspconfig()
end

local function setup_cmp()
    local extend_cmp = vim.g.lsp_zero_extend_cmp
    if extend_cmp == 0 or extend_cmp == false then return end

    local loaded_cmp = vim.g.loaded_cmp
    if loaded_cmp == true then
        require('config.lsp.cmp').apply_base()
        return
    end

    if loaded_cmp == 0 or loaded_cmp == false then return end

    vim.api.nvim_create_autocmd('User', {
        pattern = 'CmpReady',
        once = true,
        callback = function() require('config.lsp.cmp').apply_base() end,
    })
end

function Setup.extend_plugins()
    if Setup.done then return false end

    Setup.done = true
    setup_lspconfig()
    setup_cmp()

    return true
end

---
-- UI settings
---
local border_style = vim.g.lsp_zero_ui_float_border
if border_style == nil then border_style = 'rounded' end

if type(border_style) == 'string' then
    vim.lsp.handlers['textDocument/hover'] =
        vim.lsp.with(vim.lsp.handlers.hover, { border = border_style })

    vim.lsp.handlers['textDocument/signatureHelp'] =
        vim.lsp.with(vim.lsp.handlers.signature_help, { border = border_style })

    vim.diagnostic.config({
        float = { border = border_style },
    })
end

local signs = vim.g.lsp_zero_ui_signcolumn
if
    (signs == nil and vim.o.signcolumn == 'auto')
    or signs == 1
    or signs == true
then
    vim.o.signcolumn = 'yes'
end

local M = {}
local s = {
    lsp_project_configs = {},
}

function M.cmp_format()
    return {
        fields = { 'abbr', 'menu', 'kind' },
        format = function(entry, item)
            local n = entry.source.name
            if n == 'nvim_lsp' then
                item.menu = '[LSP]'
            elseif n == 'nvim_lua' then
                item.menu = '[nvim]'
            else
                item.menu = string.format('[%s]', n)
            end
            return item
        end,
    }
end

function M.extend_cmp(opts) require('config.lsp.cmp').extend(opts) end

function M.extend_lspconfig()
    local Server = require('config.lsp.server')

    if Server.setup_done then return end

    if Server.has_configs() then
        local msg = '[lsp-zero] Some language servers have been configured before\n'
            .. 'you called the function .extend_lspconfig().\n\n'
            .. 'Solution: Go to the place where you use lspconfig for the first time.\n'
            .. 'Call the .extend_lspconfig() function before you setup the language server'

        vim.notify(msg, vim.log.levels.WARN)
        return
    end

    Server.has_lspconfig = true
    Server.extend_lspconfig()
end

function M.setup_servers(list, opts)
    if type(list) ~= 'table' then return end

    opts = opts or {}

    local Server = require('config.lsp.server')
    local exclude = opts.exclude or {}

    for _, name in ipairs(list) do
        if not vim.tbl_contains(exclude, name) then Server.setup(name, {}) end
    end
end

function M.configure(name, opts)
    local Server = require('config.lsp.server')

    M.store_config(name, opts)
    Server.setup(name, opts)
end

function M.default_setup(name) require('config.lsp.server').setup(name, {}) end

function M.on_attach(fn)
    local Server = require('config.lsp.server')

    if type(fn) == 'function' then Server.common_attach = fn end
end

function M.set_server_config(opts)
    if type(opts) == 'table' then
        local Server = require('config.lsp.server')
        Server.default_config = opts
    end
end

function M.store_config(name, opts)
    if type(opts) == 'table' then s.lsp_project_configs[name] = opts end
end

function M.use(servers, opts)
    if type(servers) == 'string' then servers = { servers } end

    -- local bufnr = vim.api.nvim_get_current_buf()
    local has_filetype = not (vim.bo.filetype == '')
    local buffer = vim.api.nvim_get_current_buf()
    local lspconfig = require('lspconfig')
    local user_opts = opts or {}

    for _, name in ipairs(servers) do
        local config = vim.tbl_deep_extend(
            'force',
            s.lsp_project_configs[name] or {},
            user_opts
        )

        local lsp = lspconfig[name]
        lsp.setup(config)

        if lsp.manager and has_filetype then
            pcall(function() lsp.manager:try_add_wrapper(buffer) end)
        end
    end
end

function M.nvim_lua_ls(opts)
    return require('config.lsp.server').nvim_workspace(opts)
end

function M.set_sign_icons(opts)
    require('config.lsp.server').set_sign_icons(opts)
end

function M.default_keymaps(opts)
    opts = opts or { buffer = 0 }
    require('config.lsp.server').default_keymaps(opts)
end

function M.get_capabilities()
    return require('config.lsp.server').client_capabilities()
end

function M.new_client(opts)
    if type(opts) ~= 'table' then return end

    local name = opts.name or ''

    local Server = require('config.lsp.server')

    Server.skip_setup(name)

    local defaults1 = {
        capabilities = Server.client_capabilities(),
        on_attach = function() end,
    }

    local config = vim.tbl_deep_extend(
        'force',
        defaults1,
        Server.default_config or {},
        opts or {}
    )

    if config.filetypes == nil then return end

    local setup_id
    local desc = 'Attach LSP server'
    local defaults = {
        capabilities = vim.lsp.protocol.make_client_capabilities(),
        on_exit = vim.schedule_wrap(function()
            if setup_id then pcall(vim.api.nvim_del_autocmd, setup_id) end
        end),
    }

    local config2 = vim.tbl_deep_extend('force', defaults, config)

    local get_root = config.root_dir
    if type(get_root) == 'function' then config2.root_dir = nil end

    if config.on_exit then
        local cb = config.on_exit
        local cleanup = defaults.on_exit
        config2.on_exit = function(...)
            cleanup()
            cb(...)
        end
    end

    if config2.name then
        desc = string.format('Attach LSP: %s', config2.name)
    end

    local start_client = function()
        if get_root then config2.root_dir = get_root() end

        if config2.root_dir then vim.lsp.start(config2) end
    end

    setup_id = vim.api.nvim_create_autocmd('FileType', {
        group = lsp_cmds,
        pattern = config2.filetypes,
        desc = desc,
        callback = start_client,
    })
end

function M.format_on_save(opts)
    return require('config.lsp.format').format_on_save(opts)
end

function M.format_mapping(...)
    return require('config.lsp.format').format_mapping(...)
end

function M.buffer_autoformat(...)
    return require('config.lsp.format').buffer_autoformat(...)
end

function M.async_autoformat(...)
    return require('config.lsp.format').async_autoformat(...)
end

M.dir = {}

function M.dir.find_all(list) return require('config.lsp.dir').find_all(list) end

function M.dir.find_first(list)
    return require('config.lsp.dir').find_first(list)
end

M.omnifunc = {}

function M.omnifunc.setup(opts) require('config.lsp.omnifunc').setup(opts) end

if Setup.ok then Setup.extend_plugins() end

M.defaults = {}

function M.defaults.cmp_config(opts)
    local defaults = require('config.lsp.cmp').base_config()

    return vim.tbl_deep_extend('force', defaults, opts or {})
end

function M.defaults.cmp_mappings(opts)
    local defaults = require('config.lsp.cmp').basic_mappings()
    return vim.tbl_deep_extend('force', defaults, opts or {})
end

return M
