local M = {}

---@class My.cmp.DocumentationInfoPartial
---@field bufnr? uinteger
---@field winid? uinteger
local cached_documentation_info = {}

---@class My.cmp.DocumentationInfo
---@field bufnr uinteger
---@field winid uinteger

---@type boolean
local is_hidden = false

function M.is_hidden() return is_hidden end

function M.hide_docs(value)
    is_hidden = value
    if is_hidden then
        local info = M.get_documentation_window_info()
        if info ~= nil then vim.api.nvim_win_hide(info.winid) end
    end
    --TODO add logic to reopen the doc window when it is unhidden
end

---Get the documentation info of the open documentation preview.
---@return My.cmp.DocumentationInfo|nil
function M.get_documentation_window_info()
    local bufnr = cached_documentation_info.bufnr
    local winid = cached_documentation_info.winid
    if bufnr == nil or not vim.api.nvim_buf_is_valid(bufnr) then return nil end
    if winid == nil or not vim.api.nvim_win_is_valid(winid) then return nil end
    if bufnr ~= vim.api.nvim_win_get_buf(winid) then return nil end

    return {
        bufnr = cached_documentation_info.bufnr,
        winid = cached_documentation_info.winid,
    }
end

function M.scroll_docs(delta)
    local documentation_info = M.get_documentation_window_info()
    if documentation_info == nil then return false end
    if not is_hidden then
        vim.defer_fn(function()
            vim.api.nvim_buf_call(documentation_info.bufnr, function()
                local info = vim.fn.getwininfo(documentation_info.winid)[1]
                    or {}
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

---displays the lsp documentation
---@param documentation string|lsp.MarkupContent
local function display_documentation(documentation)
    local width = 0

    local documentation_value = ''
    local syntax = 'text'
    if type(documentation) == 'string' then
        documentation_value = documentation
    else
        documentation_value = documentation.value
        if documentation.kind == 'markdown' then syntax = 'markdown' end
    end

    local lines = vim.split(documentation_value, '\n')
    for _, line in ipairs(lines) do
        width = math.max(width, #line)
    end

    if width == 0 then return end
    local pumpos = vim.fn.pum_getpos()
    local max_width = math.max(
        vim.api.nvim_win_get_width(0) - pumpos.width - pumpos.col - 5,
        0
    )

    --TODO determine logic to put the documentation to the left if there is more space
    local opts = {
        border = 'single',
        height = #lines,
        width = width,
        max_width = max_width,
        offset_x = pumpos.width,
        close_events = {
            'CompleteChanged',
            'CompleteDone',
            'InsertLeave',
        },
    }

    -- Update buffer content if needed.
    vim.schedule(function()
        local preview_bufnr, preview_winid =
            vim.lsp.util.open_floating_preview(lines, syntax, opts)
        cached_documentation_info.bufnr = preview_bufnr
        cached_documentation_info.winid = preview_winid
        vim.wo[preview_winid].conceallevel = 2
        vim.wo[preview_winid].concealcursor = 'n'
        vim.wo[preview_winid].foldenable = false
        vim.wo[preview_winid].linebreak = true
        vim.wo[preview_winid].scrolloff = 0
        vim.wo[preview_winid].showbreak = 'NONE'
        --TODO add transparency based on vim.o.pumblend
    end)
end

M.show_complete_documentation = function(bufnr)
    vim.api.nvim_create_autocmd('CompleteChanged', {
        group = vim.api.nvim_create_augroup(
            'completion.documentation' .. bufnr,
            { clear = true }
        ),
        buffer = bufnr,
        callback = function(_)
            if tonumber(vim.fn.pumvisible()) == 0 or is_hidden then return end
            local event = vim.v.event --need to grab from vim.v.event for some reason to get the data I need

            local documentation = vim.tbl_get(
                event,
                'completed_item',
                'user_data',
                'nvim',
                'lsp',
                'completion_item',
                'documentation'
            )

            if documentation ~= nil and documentation ~= '' then
                display_documentation(documentation)
                return
            end

            local lsp_info =
                vim.tbl_get(event, 'completed_item', 'user_data', 'nvim', 'lsp')
            if lsp_info == nil then return end

            local completion_item = lsp_info.completion_item
            if completion_item == nil then return end

            local client_id = vim.tbl_get(lsp_info, 'client_id')
            if client_id == nil then return end

            local client = vim.lsp.get_client_by_id(client_id)
            if client == nil then return end

            client.request(
                vim.lsp.protocol.Methods.completionItem_resolve,
                completion_item,
                function(err, result, _, _)
                    if err ~= nil then
                        vim.print(err)
                        return
                    elseif
                        result == nil
                        or result.documentation == nil
                        or result.documentation == ''
                    then
                        return
                    end
                    display_documentation(result.documentation)
                end,
                bufnr
            )
        end,
    })
end

return M
