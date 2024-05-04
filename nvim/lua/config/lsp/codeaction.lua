-- based on https://github.com/neovim/neovim/blob/v0.8.0/runtime/lua/vim/lsp/buf.lua#L153-L178
---@private
---@param bufnr integer
---@param mode "v"|"V"
---@return table {start={row, col}, end={row, col}} using (1, 0) indexing
local function range_from_selection(bufnr, mode)
    -- [bufnum, lnum, col, off]; both row and column 1-indexed
    local start = vim.fn.getpos('v')
    local end_ = vim.fn.getpos('.')
    local start_row = start[2]
    local start_col = start[3]
    local end_row = end_[2]
    local end_col = end_[3]

    -- A user can start visual selection at the end and move backwards
    -- Normalize the range to start < end
    if start_row == end_row and end_col < start_col then
        end_col, start_col = start_col, end_col
    elseif end_row < start_row then
        start_row, end_row = end_row, start_row
        start_col, end_col = end_col, start_col
    end

    if mode == 'V' then
        start_col = 1
        local lines =
            vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, true)
        end_col = #lines[1]
    end

    return {
        ['start'] = { start_row, start_col - 1 },
        ['end'] = { end_row, end_col - 1 },
    }
end

local code_action_marks = {}

vim.api.nvim_create_user_command('MCAMark', function(args)
    local mark_name = args.args

    local params

    local bufnr = vim.api.nvim_get_current_buf()
    local mode = vim.api.nvim_get_mode().mode

    -- if args.range == 2 then vim.print(args) end
    if mode == 'v' or mode == 'V' then
        local range = range_from_selection(0, mode)
        params = vim.lsp.util.make_given_range_params(range.start, range['end'])
    else
        params = vim.lsp.util.make_range_params()
    end
    params.context = {
        triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
        diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr),
    }
    vim.lsp.buf_request_all(
        bufnr,
        'textDocument/codeAction',
        params,
        function(results)
            local actions = {}
            local action_selection_list = { '\nSelect a code action:' }
            local index = 1
            for client_id, result in pairs(results) do
                for _, lsp_action in pairs(result.result or {}) do
                    local action = {
                        client_id = client_id,
                        kind = lsp_action.kind,
                        title = lsp_action.title,
                    }
                    table.insert(actions, action)
                    local action_selection_text = index
                        .. '. '
                        .. lsp_action.title
                    table.insert(action_selection_list, action_selection_text)

                    index = index + 1
                end
            end
            if #actions == 0 then
                vim.notify('\nNo code actions available', vim.log.levels.INFO)
                return
            end
            --TODO see if i can make inputlist silent so it isn't in the way of messages
            --TODO replace with vim.ui.select(actions, select_opts, on_user_choice)
            local selection = vim.fn.inputlist(action_selection_list)
            local selection_index = tonumber(selection)
            local selected_action = actions[selection_index]
            if selected_action == nil then
                vim.notify('\nNot a valid selection', vim.log.levels.INFO)
                return
            end
            -- vim.print(selected_action)

            -- vim.print(selection)
            if mark_name == nil or mark_name:gsub('%s+', '') == '' then
                mark_name =
                    vim.fn.input({ prompt = '\nMark name:', default = '0' })
                -- vim.print('mark_name:', mark_name)
                --TODO think through default value and validating input
            end
            if mark_name ~= nil then
                code_action_marks[mark_name] = selected_action
            end
        end
    )
end, {
    desc = 'Marks a Code Action item',
    nargs = '?', --0 or 1 param
    range = true,
})

---@param action lsp.Command|lsp.CodeAction
---@param client vim.lsp.Client
---@param ctx lsp.HandlerContext
local function apply_action(action, client, ctx)
    vim.print(action)
    vim.print(ctx)
    if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end
    local a_cmd = action.command
    if a_cmd then
        local command = type(a_cmd) == 'table' and a_cmd or action
        client:_exec_cmd(command, ctx)
    end
end

vim.api.nvim_create_user_command('MCARun', function(args)
    local mark_name = args.args
    local bufnr = vim.api.nvim_get_current_buf()

    local params
    local mode = vim.api.nvim_get_mode().mode
    if mode == 'v' or mode == 'V' then
        local range = range_from_selection(0, mode)
        params = vim.lsp.util.make_given_range_params(range.start, range['end'])
    else
        params = vim.lsp.util.make_range_params()
    end
    params.context = {
        triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
        diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr),
    }

    local action_mark = code_action_marks[mark_name]
    if action_mark == nil then
        vim.notify('Invalid action mark', vim.log.levels.INFO)
        return
    end

    local clients = vim.lsp.get_clients({
        bufnr = bufnr,
        method = 'textDocument/codeAction',
    })
    local remaining = #clients
    if remaining == 0 then return end

    vim.lsp.buf_request_all(
        bufnr,
        'textDocument/codeAction',
        params,
        function(results)
            for client_id, result in pairs(results) do
                for _, lsp_action in pairs(result.result or {}) do
                    if
                        lsp_action.kind == action_mark.kind
                        and lsp_action.title == action_mark.title
                    then
                        vim.print('action:', lsp_action)
                        local client = vim.lsp.get_client_by_id(client_id)
                        if client == nil then
                            return --TODO maybe alert
                        end
                        ---attempt 2
                        local ctx = {
                            method = 'textDocument/codeAction',
                            client_id = client_id,
                            bufnr = bufnr,
                            params = params,
                        }
                        local reg = client.dynamic_capabilities:get(
                            'textDocument/codeAction',
                            { bufnr = bufnr }
                        )

                        local supports_resolve = vim.tbl_get(
                            reg or {},
                            'registerOptions',
                            'resolveProvider'
                        ) or client.supports_method(
                            'codeAction/resolve'
                        )

                        if
                            not lsp_action.edit
                            and client
                            and supports_resolve
                        then
                            client.request(
                                'codeAction/resolve',
                                lsp_action,
                                function(err, resolved_action)
                                    if err then
                                        if lsp_action.command then
                                            apply_action(
                                                lsp_action,
                                                client,
                                                ctx
                                            )
                                        else
                                            vim.notify(
                                                err.code .. ': ' .. err.message,
                                                vim.log.levels.ERROR
                                            )
                                        end
                                    else
                                        apply_action(
                                            resolved_action,
                                            client,
                                            ctx
                                        )
                                    end
                                end,
                                bufnr
                            )
                        else
                            apply_action(lsp_action, client, ctx)
                        end
                        return
                    end
                end
            end
            -- vim.notify('Code actions could not be found', vim.log.levels.INFO)
        end
    )
end, {
    desc = 'Runs a Code Action Mark',
    nargs = 1, --0 or 1 param
    complete = function()
        local marks = {}
        for mark, _ in pairs(code_action_marks) do
            table.insert(marks, mark)
        end
        return marks
    end,
    range = true,
})
------------------------
---

local function build_client_request_future(client)
    local async_lib = require('plenary.async_lib.async')
    return async_lib.wrap(function(bufnr, method, params, callback)
        local proxied_callback = function(err, result, context, config)
            result = {
                err = err,
                result = result,
                context = context,
                config = config,
            }
            callback(result)
        end
        client.request(method, params, proxied_callback, bufnr)
    end, 4)
end

local function is_lsp_request_supported(method, client, bufnr)
    local reg = client.dynamic_capabilities:get(method, { bufnr = bufnr })

    return vim.tbl_get(reg or {}, 'registerOptions', 'resolveProvider')
        or client.supports_method(method)
end
vim.api.nvim_create_user_command('TestLSP', function(args)
    local client_id = tonumber(vim.split(args.args, ':')[1])
    if client_id == nil then error('Selected lsp client does not exist') end
    local client = vim.lsp.get_client_by_id(client_id)
    local bufnr = vim.api.nvim_get_current_buf()
    local params = require('vim.lsp.util').make_position_params()

    local async_lib = require('plenary.async_lib.async')
    local ms = require('vim.lsp.protocol').Methods

    local client_request = build_client_request_future(client)

    local request_order = {}
    local requests = {}

    local methods = {
        ms.textDocument_definition,
        ms.textDocument_declaration,
        ms.textDocument_implementation,
        ms.textDocument_typeDefinition,
    }
    for _, method in ipairs(methods) do
        if is_lsp_request_supported(method, client, bufnr) then
            table.insert(requests, client_request(bufnr, method, params))
            table.insert(request_order, method)
        end
    end

    local method = ms.textDocument_references
    if is_lsp_request_supported(method, client, bufnr) then
        local reference_params = vim.tbl_deep_extend('force', params, {
            context = {
                includeDeclaration = true,
            },
        })
        table.insert(requests, client_request(bufnr, method, reference_params))
        table.insert(request_order, method)
    end

    local all_requests = async_lib.join(requests)
    async_lib.run(all_requests, function(result)
        local code_info = {}
        code_info[ms.textDocument_definition] = nil
        code_info[ms.textDocument_references] = nil
        code_info[ms.textDocument_declaration] = nil
        code_info[ms.textDocument_implementation] = nil
        code_info[ms.textDocument_typeDefinition] = nil

        for i, method_name in ipairs(request_order) do
            code_info[method_name] = result[i][1].result
        end
        vim.print(code_info)
    end)
end, {
    desc = 'Testing async lsp calls',
    nargs = 1,
    complete = function()
        local clients = vim.lsp.get_clients({
            bufnr = 0,
        })
        local client_selection = {}
        for _, client in ipairs(clients) do
            table.insert(client_selection, client.id .. ':' .. client.name)
        end
        return client_selection
    end,
})
