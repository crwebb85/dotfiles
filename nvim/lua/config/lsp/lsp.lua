local lsp_codelens = require('config.lsp.codelens')
local lsp_links = require('config.lsp.lsplinks')
local lsp_lightbulb = require('config.lsp.lightbulb')
local lsp_commands = require('config.lsp.commands')
local lsp_progress = require('config.lsp.progress')
local lsp_server = require('config.lsp.server')
local lsp_inlayhints = require('config.lsp.inlayhints')
require('config.lsp.codeaction')
local M = {}

---
-- Commands
---

vim.api.nvim_create_user_command(
    'LspWorkspaceAdd',
    function() vim.lsp.buf.add_workspace_folder() end,
    { desc = 'LSP: Add folder from workspace' }
)

vim.api.nvim_create_user_command(
    'LspWorkspaceRemove',
    function() vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
    { desc = 'LSP: Remove folder from workspace' }
)

vim.api.nvim_create_user_command(
    'LspWorkspaceList',
    function() vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
    { desc = 'LSP: List workspace folders' }
)

vim.api.nvim_create_user_command(
    'LspToggleInlayHints',
    lsp_inlayhints.toggle_inlay_hints,
    { desc = 'LSP: Toggle Inlay Hints' }
)

vim.api.nvim_create_user_command(
    'LspToggleCodeLens',
    lsp_codelens.toggle_codelens,
    { desc = 'LSP: Toggle Codelens' }
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

---Sets keymaps for the lsp buffer
---@param bufnr any
---@param client any
local function default_keymaps(bufnr, client)
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
        'gR',
        function() require('trouble').toggle('lsp_references') end,
        {
            buffer = bufnr,
            desc = 'LSP: Lists all the references to the symbol under the cursor in the the trouble quickfix window.',
        }
    )
    vim.keymap.set(
        'n',
        '<leader>vrr',
        function() vim.lsp.buf.references() end,
        {
            buffer = bufnr,
            -- remap = false,
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
        -- remap = false,
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
            -- remap = false,
            desc = 'LSP: Selects a code action available at the current cursor position.',
        }
    )

    vim.keymap.set(
        { 'v', 'n' },
        '<F3>',
        require('actions-preview').code_actions,
        {
            buffer = bufnr,
            desc = 'LSP - Actions Preview: Code action preview menu',
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

    vim.keymap.set(
        'n',
        '<leader>lr',
        function() lsp_codelens.run() end,
        { desc = 'LSP: Run Codelens', buffer = bufnr }
    )

    if client.server_capabilities.documentLinkProvider ~= nil then
        vim.keymap.set('n', 'gx', require('config.lsp.lsplinks').gx, {
            desc = 'LSP Remap: Open lsp links if exists. Otherwise, fallback to default neovim functionality for open link',
            buffer = bufnr,
        })
    end
end

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

    -- vim.print(client.server_capabilities)

    if
        client.server_capabilities.codeLensProvider ~= nil
        and client.server_capabilities.codeLensProvider.resolveProvider
    then
        local augroup_codelens =
            vim.api.nvim_create_augroup('lsp_codelens', { clear = true })
        vim.api.nvim_clear_autocmds({
            group = augroup_codelens,
            buffer = event.buf,
        })
        vim.api.nvim_create_autocmd(
            { 'BufEnter', 'BufWritePost', 'CursorHold' },
            {
                group = augroup_codelens,
                callback = function() lsp_codelens.refresh_codelens(event.buf) end,
                buffer = event.buf,
            }
        )
    end

    if client.server_capabilities.codeActionProvider ~= nil then
        local augroup_lsp_lightbulb =
            vim.api.nvim_create_augroup('lsp_lightbulb', { clear = true })

        -- Show a lightbulb when code actions are available at the cursor position
        vim.api.nvim_create_autocmd(
            { 'BufEnter', 'CursorHold', 'CursorHoldI', 'WinScrolled' },
            {
                group = augroup_lsp_lightbulb,
                callback = lsp_lightbulb.show_lightbulb,
                buffer = event.buf,
            }
        )

        vim.api.nvim_create_autocmd({ 'BufLeave' }, {
            group = augroup_lsp_lightbulb,
            callback = lsp_lightbulb.remove_lightbulb,
            buffer = event.buf,
        })
    end

    if client.server_capabilities.documentLinkProvider ~= nil then
        -- vim.print('lsp has documentLinkProvider')
        vim.api.nvim_create_autocmd(
            { 'InsertLeave', 'BufEnter', 'CursorHold', 'LspAttach' },
            {
                group = vim.api.nvim_create_augroup(
                    'lsplinks',
                    { clear = true }
                ),
                callback = lsp_links.refresh,
            }
        )
    end
    default_keymaps(event.buf, client)
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
    callback = lsp_commands.setup,
    once = true,
})

vim.api.nvim_create_autocmd({ 'LspProgress' }, {
    pattern = '*',
    group = vim.api.nvim_create_augroup('lsp_progress', { clear = true }),
    callback = lsp_progress.update_lsp_progress_display,
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

-------------------------------------------------------------------------------
---Server Setup functions (sets the lsp-config opts)
---https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

function M.default_lsp_server_setup(name) lsp_server.setup(name, {}) end

function M.setup_lua_ls(name)
    lsp_server.setup(name, {
        settings = {
            Lua = {
                runtime = { version = 'LuaJIT' },
                hint = { enable = true },
            },
        },
    })
end
function M.setup_pyright(name)
    lsp_server.setup(name, {
        settings = {
            python = {
                -- Note autoImportCompletions only shows imports that have been used in other files that have already been opened
                -- See https://github.com/hrsh7th/nvim-cmp/issues/426#issuecomment-1185144017
                -- TODO see if there is a way to get it to at least suggest imports without having to open all workspace files
                autoImportCompletions = true,
            },
        },
    })
end

function M.setup_tsserver(name)
    lsp_server.setup(name, {
        settings = {
            typescript = {
                inlayHints = {
                    -- taken from https://github.com/typescript-language-server/typescript-language-server#workspacedidchangeconfiguration
                    includeInlayEnumMemberValueHints = true,
                    includeInlayFunctionLikeReturnTypeHints = true,
                    includeInlayFunctionParameterTypeHints = true,
                    includeInlayParameterNameHints = 'all',
                    includeInlayParameterNameHintsWhenArgumentMatchesName = true,
                    includeInlayPropertyDeclarationTypeHints = true,
                    includeInlayVariableTypeHints = true,
                    includeInlayVariableTypeHintsWhenTypeMatchesName = true,
                },
            },
            javascript = {
                inlayHints = {
                    includeInlayEnumMemberValueHints = true,
                    includeInlayFunctionLikeReturnTypeHints = true,
                    includeInlayFunctionParameterTypeHints = true,
                    includeInlayParameterNameHints = 'all',
                    includeInlayParameterNameHintsWhenArgumentMatchesName = true,
                    includeInlayPropertyDeclarationTypeHints = true,
                    includeInlayVariableTypeHints = true,
                    includeInlayVariableTypeHintsWhenTypeMatchesName = true,
                },
            },
        },
    })
end

function M.setup_yamlls(name)
    -- yamlls config is based on article https://www.arthurkoziel.com/json-schemas-in-neovim/
    local yamlls_cfg = require('yaml-companion').setup({
        -- detect k8s schemas based on file content
        builtin_matchers = {
            kubernetes = { enabled = true },
        },

        -- schemas available in Telescope picker
        -- :Telescope yaml_schema
        -- Catalog of general schemas: https://www.schemastore.org/api/json/catalog.json
        -- Catalog of kubernetes schemas: https://github.com/datreeio/CRDs-catalog/tree/main
        schemas = {
            {
                name = 'Argo CD Application',
                uri = 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/argoproj.io/application_v1alpha1.json',
            },
            {
                name = 'SealedSecret',
                uri = 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/bitnami.com/sealedsecret_v1alpha1.json',
            },
            {
                name = 'Kustomization',
                uri = 'https://json.schemastore.org/kustomization.json',
            },
            {
                name = 'GitHub Workflow',
                uri = 'https://json.schemastore.org/github-workflow.json',
            },
            {
                name = 'Ansible Execution Environment',
                uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/execution-environment.json',
            },
            {
                name = 'Ansible Meta',
                url = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/meta.json',
            },
            {
                name = 'Ansible Meta Runtime',
                uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/meta-runtime.json',
            },
            {
                name = 'Ansible Argument Specs',
                uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/role-arg-spec.json',
            },
            {
                name = 'Ansible Requirements',
                uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/requirements.json',
            },
            {
                name = 'Ansible Vars File',
                uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/vars.json',
            },
            {
                name = 'Ansible Tasks File',
                uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/tasks',
            },
            {
                name = 'Ansible Playbook',
                uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/playbook',
            },
            {
                name = 'Ansible Rulebook',
                uri = 'https://raw.githubusercontent.com/ansible/ansible-rulebook/main/ansible_rulebook/schema/ruleset_schema.json',
            },
            {
                name = 'Ansible Inventory',
                uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/inventory.json',
            },
            {
                name = 'Ansible Collection Galaxy',
                uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/galaxy.json',
            },
            {
                name = 'Ansible-lint Configuration',
                uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible-lint-config.json',
            },
            {
                name = 'Ansible Navigator Configuration',
                uri = 'https://raw.githubusercontent.com/ansible/ansible-navigator/main/src/ansible_navigator/data/ansible-navigator.json',
            },
            {
                name = 'OpenAPI 3.0',
                uri = 'https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.0/schema.json',
            },
            {
                name = 'OpenAPI 3.1',
                uri = 'https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json',
            },
            {
                name = 'Swagger API 2.0',
                uri = 'https://json.schemastore.org/swagger-2.0.json',
            },
        },

        lspconfig = {
            settings = {
                yaml = {
                    validate = true,
                    schemaStore = {
                        enable = false,
                        url = '',
                    },

                    -- schemas from store, matched by filename
                    -- loaded automatically
                    -- Catalog of general schemas: https://www.schemastore.org/api/json/catalog.json
                    schemas = require('schemastore').yaml.schemas({
                        select = {
                            'kustomization.yaml',
                            'GitHub Workflow',
                            'Ansible Execution Environment',
                            'Ansible Meta',
                            'Ansible Meta Runtime',
                            'Ansible Argument Specs',
                            'Ansible Requirements',
                            'Ansible Vars File',
                            'Ansible Tasks File',
                            'Ansible Playbook',
                            'Ansible Rulebook',
                            'Ansible Inventory',
                            'Ansible Collection Galaxy',
                            'Ansible-lint Configuration',
                            'Ansible Navigator Configuration',
                            'openapi.json',
                            'Swagger API 2.0',
                        },
                    }),
                },
            },
        },
    })

    lsp_server.setup(name, yamlls_cfg)
end

function M.setup_jsonls(name)
    -- jsonls config is based on article https://www.arthurkoziel.com/json-schemas-in-neovim/
    -- Config type is defined in https://github.com/microsoft/vscode/blob/30b777312745e84972956d4361465d4d38aa0f78/extensions/json-language-features/server/src/jsonServer.ts#L202C2-L218C3
    local json_schemas = require('schemastore').json.schemas({
        select = {
            'Renovate',
            'GitHub Workflow Template Properties',
        },
        -- extra = {
        --     {
        --         description = 'Schema for luals lsp configuration file',
        --         name = 'LuaLS Settings',
        --         url = 'https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json',
        --         fileMatch = { '.luarc.json', '.luarc.jsonc' },
        --     },
        -- },
    })
    -- Adding the schemas to the extra tab doesn't seem to be working
    table.insert(json_schemas, {
        description = 'Schema for luals lsp configuration file',
        name = 'LuaLS Settings',
        url = 'https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json',
        fileMatch = { '.luarc.json', '.luarc.jsonc' },
    })
    local jsonls_cfg = {
        settings = {
            json = {
                schemas = json_schemas,
                validate = { enable = true },
            },
        },
    }

    lsp_server.setup(name, jsonls_cfg)
end

function M.setup_tablo(name)
    -- taplo config is based on article https://www.arthurkoziel.com/json-schemas-in-neovim/
    -- tablo loads all toml schemas from https://www.schemastore.org/api/json/catalog.json with little customization
    lsp_server.setup(name, {
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
    })
end

function M.setup_omnisharp(name)
    local pid = vim.fn.getpid()
    lsp_server.setup(name, {
        cmd = {
            require('utils.path').get_mason_tool_path('omnisharp'),
            '--languageserver',
            '--hostPID',
            tostring(pid),
        },
    })
end
function M.setup_powershell_es(name)
    lsp_server.setup(name, {
        filetypes = { 'ps1', 'psm1', 'psd1' },
        settings = { powershell = { codeFormatting = { Preset = 'OTBS' } } },
        init_options = {
            enableProfileLoading = false,
        },
    })
end

return M
