local lsp_server = require('config.lsp.server')

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
    require('config.lsp.inlayhints').toggle_inlay_hints,
    { desc = 'LSP: Toggle Inlay Hints' }
)

vim.api.nvim_create_user_command(
    'LspToggleCodeLens',
    require('config.lsp.codelens').toggle_codelens,
    { desc = 'LSP: Toggle Codelens' }
)

---
-- Autocommands
---

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

    --Enable lsp progress display
    require('config.lsp.progress').enable()

    --Disable lsp for large files. The buffer variable is_big_file
    --is set by a BufReadPre autocommand in y autocmd.lua file
    if vim.b[event.buf].is_big_file == true then
        vim.schedule(
            function()
                vim.lsp.buf_detach_client(event.buf, event.data.client_id)
            end
        )
        return
    end

    if
        client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens)
    then
        require('config.lsp.codelens').enable()
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
                callback = require('config.lsp.lsplinks').refresh,
            }
        )
    end

    if
        client:supports_method(vim.lsp.protocol.Methods.textDocument_completion)
    then
        -- Enable lightbulb
        require('config.lsp.lightbulb').enable()

        -- Enable native completion.
        if require('config.config').use_native_completion then
            vim.lsp.completion.enable(true, client.id, event.buf, {
                autotrigger = true,
            })

            -- require('config.lsp.completion.omnifunc')
            -- vim.bo[event.buf].omnifunc = 'v:lua.MyOmnifunc'

            require('config.lsp.completion.documentation').show_complete_documentation(
                event.buf
            )
        end
    end

    require('config.lsp.keymaps').setup_lsp_keymaps(event.buf, client)
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

if require('config.config').use_native_completion then
    vim.api.nvim_create_autocmd('FileType', {
        pattern = '*',
        callback = function(_)
            require('config.lsp.completion.cmp').start_cmp_lsp()
        end,
    })
end

-------------------------------------------------------------------------------
---Server Setup functions (sets the lsp-config opts)
---https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

function M.default_lsp_server_setup(name) lsp_server.setup(name, {}) end

function M.setup_lua_ls(name)
    lsp_server.setup(name, {
        -- on_init = function(client)
        --     local path = client.workspace_folders[1].name
        --     -- if
        --     --     vim.loop.fs_stat(path .. '/.luarc.json')
        --     --     or vim.loop.fs_stat(path .. '/.luarc.jsonc')
        --     -- then
        --     --     return
        --     -- end
        --     vim.print('extend')
        --     vim.print(client.config.settings)
        --     client.config.settings.Lua =
        --         vim.tbl_deep_extend('force', client.config.settings.Lua, {
        --             runtime = {
        --                 -- Tell the language server which version of Lua you're using
        --                 -- (most likely LuaJIT in the case of Neovim)
        --                 version = 'LuaJIT',
        --             },
        --             -- Make the server aware of Neovim runtime files
        --             workspace = {
        --                 checkThirdParty = false,
        --                 -- library = {
        --                 --     vim.env.VIMRUNTIME,
        --                 --     -- Depending on the usage, you might want to add additional paths here.
        --                 --     -- "${3rd}/luv/library"
        --                 --     -- "${3rd}/busted/library",
        --                 -- },
        --                 -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
        --                 library = vim.api.nvim_get_runtime_file('', true),
        --             },
        --             diagnostics = {
        --                 -- Get the language server to recognize the `vim` global
        --                 globals = { 'vim' },
        --             },
        --         })
        --     vim.print(client.config.settings)
        -- end,
        settings = {
            Lua = {
                runtime = { version = 'LuaJIT' },
                hint = { enable = true },
                -- workspace = {
                --     checkThirdParty = false,
                --     library = {
                --         vim.env.VIMRUNTIME .. '/lua',
                --         --     -- Depending on the usage, you might want to add additional paths here.
                --         --     -- "${3rd}/luv/library"
                --         --     -- "${3rd}/busted/library",
                --     },
                --     -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
                --     -- library = vim.api.nvim_get_runtime_file('', true),
                -- },
                -- diagnostics = {
                --     -- Get the language server to recognize the `vim` global
                --     globals = { 'vim' },
                -- },
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

--Mark down lsp comparison
--
-- Completion
-- - markdown_oxide - keeps periods in note references and also completes headers (better completion)
-- - marksman - removes periods by default (can be configured to keep periods) in note references and does not complete headers
--
-- Hover
-- - markdown_oxide - hover always preview the current note (can be disabled in .moxide.toml)
-- - marksman - hover over note references previews the note
--
-- Go To Definition
-- - markdown_oxide - not supported
-- - marksman - goes to note reference
--
-- Code References
-- - marksman
--   - create table of contents
--   - create note for note reference that does not exist
--
-- Diagnostics
-- - marksman - errors for non existent document links
--
-- Rename
-- - markdown_oxide
--   header rename - did not update links containing the header

function M.setup_marksman(name)
    lsp_server.setup(name, {
        -- Note: create a .marksman.toml file in note folder to get full
        -- capabilities https://github.com/artempyanykh/marksman/blob/main/docs/configuration.md
        --

        --TODO add handlers to determine which lsp to prioritize for different capabilities
    })
end

function M.setup_markdown_oxide(name)
    lsp_server.setup(name, {
        -- Note: create a .moxide.toml file in note folder to get full
        -- capabilities https://oxide.md/v0/References/v0+Configuration+Reference

        --TODO add handlers to determine which lsp to prioritize for different capabilities
        --TODO add commands for creating notes
    })
end

return M
