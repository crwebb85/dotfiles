local M = {}

---
-- Commands
---
---
local function setup_user_commands()
    vim.api.nvim_create_user_command(
        'LspWorkspaceAdd',
        function() vim.lsp.buf.add_workspace_folder() end,
        { desc = 'LSP: Add folder from workspace' }
    )

    vim.api.nvim_create_user_command(
        'LspWorkspaceRemove',
        function() vim.lsp.buf.add_workspace_folder() end,
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
end

---
-- Autocommands
---

function M.enable()
    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup(
            'my_lsp_attach_onetime_setup',
            { clear = true }
        ),
        desc = 'lsp on_attach',
        callback = function()
            setup_user_commands()

            --Enable lsp progress display
            require('config.lsp.progress').enable()
            --Setup commands
            require('config.lsp.command_handlers').setup_command_handlers()
        end,
        once = true,
    })

    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('my_lsp_attach', { clear = true }),
        desc = 'lsp on_attach',
        callback = function(event)
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            if client == nil then return end

            --Setup keymap
            require('config.lsp.keymaps').setup_lsp_keymaps(event.buf, client)

            --Disable lsp for large files. The buffer variable is_big_file
            --is set by a BufReadPre autocommand in y autocmd.lua file
            if vim.b[event.buf].is_big_file == true then
                vim.schedule(
                    function()
                        vim.lsp.buf_detach_client(
                            event.buf,
                            event.data.client_id
                        )
                    end
                )
                return
            end

            if
                client:supports_method(
                    vim.lsp.protocol.Methods.textDocument_codeLens
                )
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
                client:supports_method(
                    vim.lsp.protocol.Methods.textDocument_completion
                )
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
        end,
    })

    if require('config.config').use_native_completion then
        vim.api.nvim_create_autocmd('FileType', {
            pattern = '*',
            callback = function(_)
                require('config.lsp.completion.cmp').start_cmp_lsp()
            end,
        })
    else
        vim.api.nvim_create_autocmd('InsertEnter', {
            group = vim.api.nvim_create_augroup(
                'cmp_nvim_lsp',
                { clear = true }
            ),
            pattern = '*',
            callback = function()
                require('config.lsp.completion.cmp_nvim_lsp').enable_cmp_completion()
            end,
        })
    end
end

function M.get_additional_default_capabilities()
    local cmp_default_capabilities = {
        textDocument = {
            completion = {
                completionItem = {
                    commitCharactersSupport = true,
                    deprecatedSupport = true,
                    insertReplaceSupport = true,
                    insertTextModeSupport = {
                        valueSet = { 1, 2 },
                    },
                    labelDetailsSupport = true,
                    preselectSupport = true,
                    resolveSupport = {
                        properties = {
                            'documentation',
                            'additionalTextEdits',
                            'insertTextFormat',
                            'insertTextMode',
                            'command',
                        },
                    },
                    snippetSupport = true,
                    tagSupport = {
                        valueSet = { 1 },
                    },
                },
                completionList = {
                    itemDefaults = {
                        'commitCharacters',
                        'editRange',
                        'insertTextFormat',
                        'insertTextMode',
                        'data',
                    },
                },
                contextSupport = true,
                dynamicRegistration = false,
                insertTextMode = 1,
            },
        },
    }

    local document_link_capabilities = {
        textDocument = {
            documentLink = {
                dynamicRegistration = true,
            },
        },
    }
    local capabilities = vim.tbl_deep_extend(
        'force',
        require('config.config').use_native_completion and {}
            or cmp_default_capabilities,
        document_link_capabilities
    )
    return capabilities
end

return M
