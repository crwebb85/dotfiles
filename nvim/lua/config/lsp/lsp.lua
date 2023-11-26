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

vim.api.nvim_create_user_command('LspSetupServers', setup_server, {
    bang = true,
    nargs = '*',
})

vim.api.nvim_create_user_command(
    'LspWorkspaceAdd',
    'lua vim.lsp.buf.add_workspace_folder()',
    {}
)

vim.api.nvim_create_user_command(
    'LspWorkspaceList',
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

local function default_keymaps(bufnr)
    vim.keymap.set(
        'n',
        'K',
        function() vim.lsp.buf.hover() end,
        { buffer = bufnr }
    )
    vim.keymap.set(
        'n',
        'gd',
        function() vim.lsp.buf.definition() end,
        { buffer = bufnr }
    )
    vim.keymap.set(
        'n',
        'gD',
        function() vim.lsp.buf.declaration() end,
        { buffer = bufnr }
    )
    vim.keymap.set(
        'n',
        'gi',
        function() vim.lsp.buf.implementation() end,
        { buffer = bufnr }
    )
    vim.keymap.set(
        'n',
        'go',
        function() vim.lsp.buf.type_definition() end,
        { buffer = bufnr }
    )
    vim.keymap.set(
        'n',
        'gr',
        function() vim.lsp.buf.references() end,
        { buffer = bufnr }
    )
    vim.keymap.set(
        'n',
        'gs',
        function() vim.lsp.buf.signature_help() end,
        { buffer = bufnr }
    )
    vim.keymap.set(
        'n',
        '<F2>',
        function() vim.lsp.buf.rename() end,
        { buffer = bufnr }
    )
    vim.keymap.set(
        'n',
        '<F3>',
        function() vim.lsp.buf.format({ async = true }) end,
        { buffer = bufnr }
    )
    vim.keymap.set(
        'x',
        '<F3>',
        function() vim.lsp.buf.format({ async = true }) end,
        { buffer = bufnr }
    )
    vim.keymap.set(
        'n',
        '<F4>',
        function() vim.lsp.buf.code_action() end,
        { buffer = bufnr }
    )

    if vim.lsp.buf.range_code_action then
        vim.keymap.set(
            'x',
            '<F4>',
            function() vim.lsp.buf.range_code_action() end,
            { buffer = bufnr }
        )
    else
        vim.keymap.set(
            'x',
            '<F4>',
            function() vim.lsp.buf.code_action() end,
            { buffer = bufnr }
        )
    end

    vim.keymap.set(
        'n',
        'gl',
        function() vim.diagnostic.open_float() end,
        { buffer = bufnr }
    )
    vim.keymap.set(
        'n',
        '[d',
        require('config.utils').dot_repeat(
            function() vim.diagnostic.goto_prev() end
        ),
        { buffer = bufnr, expr = true }
    )
    vim.keymap.set(
        'n',
        ']d',
        require('config.utils').dot_repeat(
            function() vim.diagnostic.goto_next() end
        ),
        { buffer = bufnr, expr = true }
    )
    vim.keymap.set(
        'n',
        '<leader>vca',
        function() vim.lsp.buf.code_action() end,
        {
            buffer = bufnr,
            remap = false,
            desc = 'LSP: Open Code Action menu',
        }
    )
    vim.keymap.set(
        'n',
        '<leader>vrr',
        function() vim.lsp.buf.references() end,
        {
            buffer = bufnr,
            remap = false,
            desc = 'LSP: Find references',
        }
    )
    vim.keymap.set('n', '<leader>vrn', function() vim.lsp.buf.rename() end, {
        buffer = bufnr,
        remap = false,
        desc = 'LSP: Rename symbol',
    })
end

local function lsp_attach(event)
    vim.api.nvim_buf_create_user_command(
        event.buf,
        'LspWorkspaceRemove',
        'lua vim.lsp.buf.remove_workspace_folder()',
        {}
    )

    default_keymaps(event.buf)
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

            local err_msg = '[lsp] Could not configure lspconfig\n'
                .. 'during initial setup. Some features may fail.'
                .. '\n\nDetails on how to solve this problem are in the help page.\n'

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
        local err_msg = '[lsp] Some language servers have been configured before\n'
            .. 'lsp could finish its initial setup. Some features may fail.'
            .. '\n\nDetails on how to solve this problem are in the help page.\n'

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
local border_style = 'rounded'

vim.lsp.handlers['textDocument/hover'] =
    vim.lsp.with(vim.lsp.handlers.hover, { border = border_style })

vim.lsp.handlers['textDocument/signatureHelp'] =
    vim.lsp.with(vim.lsp.handlers.signature_help, { border = border_style })

vim.diagnostic.config({
    float = { border = border_style },
})

if vim.o.signcolumn == 'auto' then vim.o.signcolumn = 'yes' end

local M = {}
local s = {
    lsp_project_configs = {},
}

local function store_config(name, opts)
    if type(opts) == 'table' then s.lsp_project_configs[name] = opts end
end

function M.configure(name, opts)
    local Server = require('config.lsp.server')

    store_config(name, opts)
    Server.setup(name, opts)
end

function M.default_setup(name) require('config.lsp.server').setup(name, {}) end

return M
