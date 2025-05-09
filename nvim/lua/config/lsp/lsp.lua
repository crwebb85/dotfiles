local M = {}

--TODO debounce refreshing the cache
local configured_lsp_names_cache = nil

local function get_configured_lsp_names()
    if configured_lsp_names_cache ~= nil then
        return configured_lsp_names_cache
    end
    local configured_lsp_names = {}
    local seen_lsp_names = {}
    for _, runtime_path in
        ipairs(vim.api.nvim_get_runtime_file('lsp/*.lua', true))
    do
        local name, _ = vim.fs.basename(runtime_path):gsub('%.lua', '')
        if not seen_lsp_names[name] then
            table.insert(configured_lsp_names, name)
            seen_lsp_names[name] = true
        end
    end
    configured_lsp_names_cache = configured_lsp_names
    return configured_lsp_names_cache
end

---This function was copied from nvim\runtime\lua\vim\lsp.lua
local function validate_cmd(v)
    if type(v) == 'table' then
        if vim.fn.executable(v[1]) == 0 then
            return false, v[1] .. ' is not executable'
        end
        return true
    end
    return type(v) == 'function'
end

---This function was copied from nvim\runtime\lua\vim\lsp.lua
--- @param config vim.lsp.Config
local function validate_config(config)
    vim.validate(
        'cmd',
        config.cmd,
        validate_cmd,
        'expected function or table with executable command'
    )
    vim.validate('reuse_client', config.reuse_client, 'function', true)
    vim.validate('filetypes', config.filetypes, 'table', true)
end

---This function was copied from nvim\runtime\lua\vim\lsp.lua
--- @param bufnr integer
--- @param name string
--- @param config vim.lsp.Config
local function can_start(bufnr, name, config)
    local config_ok, err = pcall(validate_config, config)
    if not config_ok then
        vim.lsp.log.error(
            ('cannot start %s due to config error: %s'):format(name, err)
        )
        return false
    end

    if
        config.filetypes
        and not vim.tbl_contains(config.filetypes, vim.bo[bufnr].filetype)
    then
        return false
    end

    return true
end

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

    vim.api.nvim_create_user_command('LspStart', function(args)
        local lsp_name = args.fargs[1]
        local config = vim.lsp.config[lsp_name]
        if config == nil then
            vim.notify(
                string.format('No lsp with name %s is configured.', lsp_name),
                vim.log.levels.WARN
            )
        end
        vim.lsp.enable(lsp_name)
        for _, buf_info in ipairs(vim.fn.getbufinfo()) do
            local bufnr = buf_info.bufnr
            --below code snippet was from the default implementation of autocommand created by vim.lsp.enable
            if config and can_start(bufnr, lsp_name, config) then
                -- Deepcopy config so changes done in the client
                -- do not propagate back to the enabled configs.
                config = vim.deepcopy(config)

                if type(config.root_dir) == 'function' then
                    ---@param root_dir string
                    config.root_dir(bufnr, function(root_dir)
                        config.root_dir = root_dir
                        vim.schedule(
                            function()
                                vim.lsp.start(config, {
                                    bufnr = bufnr,
                                    reuse_client = config.reuse_client,
                                    _root_markers = config.root_markers,
                                })
                            end
                        )
                    end)
                else
                    vim.lsp.start(config, {
                        bufnr = bufnr,
                        reuse_client = config.reuse_client,
                        _root_markers = config.root_markers,
                    })
                end
            end
        end
    end, {
        complete = get_configured_lsp_names,
        nargs = 1,
        desc = 'LSP: Enables the LSP',
    })

    vim.api.nvim_create_user_command('LspRestart', function(args)
        local arg = args.fargs[1]
        local hi, lo = string.find(arg, '^%s*%d+')
        if hi == nil then
            vim.notify('No client id specified', vim.log.levels.WARN)
            return
        end
        local client_id_string = string.sub(arg, hi, lo)
        local client_id = tonumber(client_id_string)

        if client_id == nil then
            vim.notify('Client id not valid', vim.log.levels.WARN)
            return
        end

        local client = vim.lsp.get_client_by_id(client_id)
        if client == nil then
            vim.notify(
                string.format(
                    'Could not find client for client id %s',
                    client_id
                ),
                vim.log.levels.WARN
            )
            return
        end
        local attached_bufnrs = {}
        for bufnr, is_attached in pairs(client.attached_buffers) do
            if is_attached and vim.api.nvim_buf_is_valid(bufnr) then
                table.insert(attached_bufnrs, bufnr)
            end
        end
        local client_config = vim.deepcopy(client.config)

        client:stop()

        vim.notify(
            string.format('Attaching buffers to restarted LSP %s.', client.name),
            vim.log.levels.INFO
        )
        local new_client_id = nil
        for _, bufnr in pairs(attached_bufnrs) do
            if vim.api.nvim_buf_is_valid(bufnr) then
                new_client_id = vim.lsp.start(client_config, { bufnr = bufnr })
            end
        end
        vim.notify(
            string.format(
                'Restarted LSP %s. Old client id was %s. New client id is %s',
                client.name,
                client_id,
                new_client_id
            ),
            vim.log.levels.INFO
        )
    end, {
        complete = function()
            local completion_items = {}
            for _, client in ipairs(vim.lsp.get_clients()) do
                local completion_item =
                    string.format('%s %s', client.id, client.name)
                table.insert(completion_items, completion_item)
            end
            return completion_items
        end,
        nargs = 1,
        desc = 'LSP: Restarts the LSP',
    })

    vim.api.nvim_create_user_command('LspStop', function(args)
        local arg = args.fargs[1]
        local hi, lo = string.find(arg, '^%s*%d+')
        if hi == nil then
            vim.notify('No client id specified', vim.log.levels.WARN)
            return
        end
        local client_id_string = string.sub(arg, hi, lo)
        local client_id = tonumber(client_id_string)

        if client_id == nil then
            vim.notify('Client id not valid', vim.log.levels.WARN)
            return
        end

        local client = vim.lsp.get_client_by_id(client_id)

        if client == nil then
            vim.notify(
                string.format(
                    'Could not find client for client id %s',
                    client_id
                ),
                vim.log.levels.WARN
            )
            return
        end

        vim.lsp.enable(client.name, false)
        client:stop()
    end, {
        complete = function()
            local completion_items = {}
            for _, client in ipairs(vim.lsp.get_clients()) do
                local completion_item =
                    string.format('%s %s', client.id, client.name)
                table.insert(completion_items, completion_item)
            end
            return completion_items
        end,
        nargs = 1,
        desc = 'Stops the LSP',
    })
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

            if client:supports_method('textDocument/documentColor') then
                vim.lsp.document_color.enable(true, event.buf)
            end
        end,
    })

    if require('config.config').use_native_completion then
        vim.api.nvim_create_autocmd('FileType', {
            group = vim.api.nvim_create_augroup(
                'native_completion',
                { clear = true }
            ),
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
