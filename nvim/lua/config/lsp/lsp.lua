local M = {}

--- Toggle Inlay hints
local isInlayHintsEnabled = false
function M.toggleInlayHintsAutocmd()
    if not vim.lsp.inlay_hint then
        print("This version of neovim doesn't support inlay hints")
    end

    isInlayHintsEnabled = not isInlayHintsEnabled

    vim.lsp.inlay_hint.enable(0, isInlayHintsEnabled)

    vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
        group = vim.api.nvim_create_augroup('inlay_hints', { clear = true }),
        pattern = '?*',
        callback = function() vim.lsp.inlay_hint.enable(0, isInlayHintsEnabled) end,
    })
end

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
    'LspToggleInlayHints',
    M.toggleInlayHintsAutocmd,
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
    local path = vim.api.nvim_get_runtime_file(mod:format(server), false)

    if path[1] == nil then
        local msg = "[lsp] Could not find configuration for '%s'"
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
    local path = vim.api.nvim_get_runtime_file(mod, false)[1]
    local pattern = '%s/*.lua'

    local list = vim.split(vim.fn.glob(pattern:format(path)), '\n')
    local res = {}

    for _, i in ipairs(list) do
        local name = vim.fn.fnamemodify(i, ':t:r')
        if name ~= nil and vim.startswith(name, user_input) then
            res[#res + 1] = name
        end
    end

    return res
end

vim.api.nvim_create_user_command('LspViewConfigSource', inspect_config_source, {
    nargs = 1,
    complete = config_source_complete,
})

---
-- Autocommands
---

local function default_keymaps(bufnr)
    vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, {
        buffer = bufnr,
        desc = [[LSP: Displays hover information about the symbol under the cursor in a floating window. Calling the function twice will jump into the floating window.]],
    })
    vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, {
        buffer = bufnr,
        desc = 'LSP: Jumps to the definition of the symbol under the cursor.',
    })
    vim.keymap.set('n', 'gD', function() vim.lsp.buf.declaration() end, {
        buffer = bufnr,
        desc = 'LSP: Jumps to the declaration of the symbol under the cursor.',
    })
    vim.keymap.set('n', 'gi', function() vim.lsp.buf.implementation() end, {
        buffer = bufnr,
        desc = 'Lists all the implementations for the symbol under the cursor in the quickfix window.',
    })
    vim.keymap.set('n', 'go', function() vim.lsp.buf.type_definition() end, {
        buffer = bufnr,
        desc = 'LSP: Jumps to the definition of the type of the symbol under the cursor.',
    })
    vim.keymap.set('n', 'gr', function() vim.lsp.buf.references() end, {
        buffer = bufnr,
        desc = 'LSP: Lists all the references to the symbol under the cursor in the quickfix window.',
    })
    vim.keymap.set(
        'n',
        '<leader>vrr',
        function() vim.lsp.buf.references() end,
        {
            buffer = bufnr,
            remap = false,
            desc = 'LSP: Lists all the references to the symbol under the cursor in the quickfix window.',
        }
    )
    vim.keymap.set('n', 'gs', function() vim.lsp.buf.signature_help() end, {
        buffer = bufnr,
        desc = 'LSP: Displays signature information about the symbol under the cursor in a floating window.',
    })
    vim.keymap.set('n', '<F2>', function() vim.lsp.buf.rename() end, {
        buffer = bufnr,
        desc = 'LSP: Renames all references to the symbol under the cursor.',
    })
    vim.keymap.set('n', '<leader>vrn', function() vim.lsp.buf.rename() end, {
        buffer = bufnr,
        remap = false,
        desc = 'LSP: Rename symbol',
    })
    vim.keymap.set('n', '<F4>', function() vim.lsp.buf.code_action() end, {
        buffer = bufnr,
        desc = 'LSP: Selects a code action available at the current cursor position.',
    })

    if vim.lsp.buf.range_code_action then
        vim.keymap.set(
            'x',
            '<F4>',
            function() vim.lsp.buf.range_code_action() end,
            {
                buffer = bufnr,
                desc = 'LSP: Selects a code action available for the current range selection.',
            }
        )
    else
        vim.keymap.set('x', '<F4>', function() vim.lsp.buf.code_action() end, {
            buffer = bufnr,
            desc = 'LSP: Selects a code action available at the current cursor position.',
        })
    end

    vim.keymap.set(
        'n',
        '<leader>vca',
        function() vim.lsp.buf.code_action() end,
        {
            buffer = bufnr,
            remap = false,
            desc = 'LSP: Selects a code action available at the current cursor position.',
        }
    )

    if vim.lsp.buf.range_code_action then
        vim.keymap.set(
            'x',
            '<leader>vca',
            function() vim.lsp.buf.range_code_action() end,
            {
                buffer = bufnr,
                desc = 'LSP: Selects a code action available for the current range selection.',
            }
        )
    else
        vim.keymap.set(
            'x',
            '<leader>vca',
            function() vim.lsp.buf.code_action() end,
            {
                buffer = bufnr,
                desc = 'LSP: Selects a code action available at the current cursor position.',
            }
        )
    end

    vim.keymap.set(
        { 'v', 'n' },
        'gf',
        require('actions-preview').code_actions,
        { desc = 'LSP - Actions Preview: Code action preview menu' }
    )

    vim.keymap.set('n', 'gl', function() vim.diagnostic.open_float() end, {
        buffer = bufnr,
        desc = 'LSP Diagnostic: Show diagnostics in a floating window.',
    })
    vim.keymap.set(
        'n',
        '[d',
        require('config.utils').dot_repeat(
            function() vim.diagnostic.goto_prev() end
        ),
        {
            buffer = bufnr,
            expr = true,
            desc = 'LSP Diagnostic: Move to the previous diagnostic in the current buffer. (Dot repeatable)',
        }
    )
    vim.keymap.set(
        'n',
        ']d',
        require('config.utils').dot_repeat(
            function() vim.diagnostic.goto_next() end
        ),
        {
            buffer = bufnr,
            expr = true,
            desc = 'LSP Diagnostic: Move to the next diagnostic. (Dot repeatable)',
        }
    )
    -- Toggle Inlay Hints
    vim.keymap.set(
        'n',
        '<leader>vth',
        function() M.toggleInlayHintsAutocmd() end,
        { desc = 'LSP: Toggle Inlay Hints', buffer = bufnr }
    )

    -- Toggle Codelens
    vim.keymap.set(
        'n',
        '<leader>vtc',
        function() require('config.lsp.codelens').toggle_virtlines() end,
        { desc = 'LSP: Toggle Codelens', buffer = bufnr }
    )

    -- Toggle Codelens
    vim.keymap.set(
        'n',
        '<leader>lr',
        function() require('config.lsp.codelens').run() end,
        { desc = 'LSP: Run Codelens', buffer = bufnr }
    )
end

local augroup_codelens =
    vim.api.nvim_create_augroup('custom-lsp-codelens', { clear = true })

--- @class lsp_attach_event_data
--- @field client_id? integer

--- @class lsp_attach_event
--- @field buf? integer
--- @field data? lsp_attach_event_data
--- @field event? string
--- @field match? string
--- @field id? integer
--- @field group? integer
--- @field file? string

-- Example of what event fields are present
-- {
--   buf = 4,
--   data = {
--     client_id = 1
--   },
--   event = "LspAttach",
--   file = "/home/chris/.config/nvim/lua/config/lazy.lua",
--   group = 42,
--   id = 52,
--   match = "/home/chris/.config/nvim/lua/config/lazy.lua"
-- }
--- @param event lsp_attach_event
local function lsp_attach(event)
    -- vim.print(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client == nil then return end

    vim.api.nvim_buf_create_user_command(
        event.buf,
        'LspWorkspaceRemove',
        'lua vim.lsp.buf.remove_workspace_folder()',
        {}
    )

    -- vim.print(client.server_capabilities)

    if
        client.server_capabilities.codeLensProvider ~= nil
        and client.server_capabilities.codeLensProvider.resolveProvider
    then
        vim.api.nvim_clear_autocmds({
            group = augroup_codelens,
            buffer = event.buf,
        })
        vim.api.nvim_create_autocmd(
            { 'BufEnter', 'BufWritePost', 'CursorHold' },
            {
                group = augroup_codelens,
                callback = require('config.lsp.codelens').refresh_virtlines,
                buffer = event.buf,
            }
        )
    end

    if client.server_capabilities.codeActionProvider ~= nil then
        vim.api.nvim_create_augroup('code_action', { clear = true })

        -- Show a lightbulb when code actions are available at the cursor position
        vim.api.nvim_create_autocmd(
            { 'BufEnter', 'CursorHold', 'CursorHoldI', 'WinScrolled' },
            {
                group = 'code_action',
                callback = require('config.lsp.lightbulb').show_lightbulb,
                buffer = event.buf,
            }
        )

        vim.api.nvim_create_autocmd({ 'BufLeave' }, {
            group = 'code_action',
            callback = require('config.lsp.lightbulb').remove_bulb,
            buffer = event.buf,
        })
    end

    vim.api.nvim_create_autocmd({ 'LspProgress' }, {
        pattern = '*',
        group = vim.api.nvim_create_augroup('lsp_progress', { clear = true }),
        callback = require('config.lsp.progress').update_lsp_progress_display,
    })

    default_keymaps(event.buf)
    -- vim.print(client.name)
end

vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp_attach', { clear = true }),
    desc = 'lsp on_attach',
    callback = lsp_attach,
})

vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('init_commands', { clear = true }),
    desc = 'lsp on_attach',
    callback = require('config.lsp.commands').setup,
    once = true,
})

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

function M.default_setup(name) require('config.lsp.server').setup(name, {}) end

return M
