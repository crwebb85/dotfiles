local M = {}

--TODO handle preview option
function M.is_hidden()
    local options = vim.opt.completeopt:get('popup')
    for _, option in ipairs(options) do
        if option == 'popup' then return false end
    end
    return true
end

function M.hide_docs(is_hidden)
    local complete_info = vim.fn.complete_info({
        'selected', -- TODO BUG: without fetching selected preview_winid and preview_bufnr will always be null
        'preview_winid',
        'preview_bufnr',
    })
    if is_hidden then
        vim.opt.completeopt:remove('popup')
        -- -- vim.print(complete_info)
        -- -- vim.print(vim.bo[complete_info.preview_bufnr].bufhidden)
        if complete_info.preview_winid ~= nil then
            vim.api.nvim_win_hide(complete_info.preview_winid)
        end
    else
        vim.opt.completeopt:append('popup')
        local items = vim.fn.complete_info({ 'items' }).items
        -- vim.print(complete_info)
        if 0 <= complete_info.selected then
            local completion_item = items[complete_info.selected + 1]
            -- vim.print(completion_item)
            M.set_documentation(completion_item)
        end
    end
end

function M.scroll_docs(delta)
    local complete_info = vim.fn.complete_info({
        'selected', -- TODO BUG: without fetching selected preview_winid and preview_bufnr will always be null
        'preview_winid',
        'preview_bufnr',
    })
    -- vim.print(complete_info)
    local winid = complete_info.preview_winid
    local bufnr = complete_info.preview_bufnr

    if
        winid == nil
        or not vim.api.nvim_win_is_valid(winid)
        or bufnr == nil
        or not vim.api.nvim_buf_is_valid(bufnr)
    then
        return false
    end

    if not M.is_hidden() then
        vim.defer_fn(function()
            vim.api.nvim_buf_call(bufnr, function()
                local info = vim.fn.getwininfo(winid)[1] or {}
                local top = info.topline or 1
                top = top + delta
                top = math.max(top, 1)
                local content_height = vim.fn.line('$')
                top = math.min(top, content_height - info.height + 1)
                vim.api.nvim_command('normal! ' .. top .. 'zt')
            end)
        end, 0)
        return true
    else
        return false
    end
end

---@param documentation string|lsp.MarkupContent|nil
local function is_lsp_completion_documention_empty(documentation)
    -- vim.print(documentation)
    return documentation == nil
        or documentation == ''
        or (type(documentation) == table and documentation.value == '')
        or (type(documentation) == table and documentation.value == nil)
end

---@param lsp_documentation string|lsp.MarkupContent
---@param selected integer index of selected completion item 0-indexed
local function display_documentation(lsp_documentation, selected)
    local kind = lsp_documentation and lsp_documentation.kind
    local filetype = kind == 'markdown' and 'markdown' or ''
    local documentation_value = type(lsp_documentation) == 'string'
            and lsp_documentation
        or lsp_documentation.value
    -- vim.print('selected ' .. selected)
    local preview_info = vim.api.nvim__complete_set(selected, {
        info = documentation_value,
    })
    if preview_info.bufnr ~= nil then
        -- vim.print(
        --     'set filetype (' .. filetype .. ') in resolve'
        -- )
        vim.bo[preview_info.bufnr].filetype = filetype
    end
end

---@param lsp_documentation string|lsp.MarkupContent
local function refresh_documentation(lsp_documentation)
    local complete_info = vim.fn.complete_info({
        'selected',
        'preview_winid',
        'preview_bufnr',
    })
    --we do this check here so that we don't close the completion window
    --if we are not going to replace it.
    if is_lsp_completion_documention_empty(lsp_documentation) then
        return
    elseif complete_info.preview_bufnr == nil then
        --If the preview buffer is already close we can just create a new one without
        --needing to schedule it
        display_documentation(lsp_documentation, complete_info.selected)
    else
        --Note: scheduling for the nvim_win_hide hack so we can close the window
        vim.schedule(function()
            local current_complete_info = vim.fn.complete_info({
                'selected',
                'preview_winid',
                'preview_bufnr',
            })
            if current_complete_info.preview_winid ~= nil then
                --HACK: nvim_win_hide will cause a whole new
                --buffer and window to be generated when I call nvim__complete_set
                --Since it is a new buffer, it will recalculate
                --the the treessiter highlights correctly. Without this
                --the treessiter highlights don't refresh
                vim.api.nvim_win_hide(current_complete_info.preview_winid)
            end
            display_documentation(
                lsp_documentation,
                current_complete_info.selected
            )
        end)
    end
end

function M.set_documentation(completion_item)
    if completion_item == nil then return end

    local lsp_completion_item = vim.tbl_get(
        completion_item,
        'user_data',
        'nvim',
        'lsp',
        'completion_item'
    )
    local complete_info = vim.fn.complete_info({
        'selected',
        'preview_winid',
        'preview_bufnr',
    })

    local preview_bufnr = complete_info.preview_bufnr
    if lsp_completion_item == nil then
        --Handle non-lsp completion items
        if
            preview_bufnr ~= nil
            and completion_item.word ~= nil
            and completion_item.word ~= ''
        then
            vim.bo[preview_bufnr].filetype = ''
        end
        return
    end

    ---@type string|lsp.MarkupContent
    local lsp_documentation = lsp_completion_item.documentation
    if lsp_documentation ~= nil then
        --Handle lsp completion items with documentation already supplied
        refresh_documentation(lsp_documentation)
        return
    end

    --Handle lsp completion items that need documentation resolved
    local client_id =
        vim.tbl_get(completion_item, 'user_data', 'nvim', 'lsp', 'client_id')
    local client = vim.lsp.get_client_by_id(client_id)
    if client == nil then return end

    local is_resolve_support = true --TODO actually check for resolve support
    if not is_resolve_support then return end
    client.request(
        vim.lsp.protocol.Methods.completionItem_resolve,
        lsp_completion_item,
        function(err, result, _)
            if err ~= nil then
                vim.print(err)
                return
            end
            local documentation = result and result.documentation
            refresh_documentation(documentation)
        end
    )
end

-- - Note if the selected completion item has a non-empty info field
--   the popup buffer will have its contents set to the info field before this autocmd triggers
-- - this auto command will not directly triggerd with vim.api.nvim__complete_set
-- - Updating info field via vim.api.nvim__complete_set does not directly modify the completion item
-- - After a lsp completionItem_resolve the lsp may update the completion_item
--   with pass by reference if implemented in lua or update its documentation cache and include the field
--   on the next textDocument_completion request
M.show_complete_documentation = function(bufnr)
    vim.api.nvim_create_autocmd('CompleteChanged', {
        group = vim.api.nvim_create_augroup(
            'completion.documentation' .. bufnr,
            { clear = true }
        ),
        buffer = bufnr,
        callback = function(_)
            if tonumber(vim.fn.pumvisible()) == 0 or M.is_hidden() then
                return
            end
            local event = vim.v.event --need to grab from vim.v.event for some reason to get the data I need
            M.set_documentation(event.completed_item)
        end,
    })
end

return M
