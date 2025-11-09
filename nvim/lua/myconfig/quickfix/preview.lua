local api = require('myconfig.quickfix.api')

local M = {}

local quickfix_preview_namespace =
    vim.api.nvim_create_namespace('quickfix_preview_namespace')

vim.api.nvim_set_hl(
    quickfix_preview_namespace,
    'quickfix_preview_highlight_group',
    {
        standout = true,
    }
)

local function clear_hl(bufnr)
    if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_clear_namespace(
            bufnr,
            quickfix_preview_namespace,
            0,
            -1
        )
    end
end

---Gets the window number of the preview window
-- based on https://github.com/ronakg/quickr-preview.vim/blob/72727c6c266c7062820e8385153e0d1486020aa8/after/ftplugin/qf.vim#L41
---@return integer? winnr of the preview window for the tab or nil if not open
local function get_preview_window_id()
    for winnr = 1, vim.fn.winnr('$') do
        if vim.fn.getwinvar(winnr, '&previewwindow') then
            return winnr + 1 -- I'm not sure why I have to add one but using this number in other functions isn't working without it
        end
        return nil
    end
end

--TODO previewing buffers with unsaved changes cause an error

---Previews the quickfix entry at the cursor (assumes the cursor is in the quickfix window)
---
---@param winnr? integer the window number or the |window-ID|. When {win} is zero the current window's location list is used. When nil the quickfix list is used.
function M.preview_quickfix_list(winnr)
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local item_id = row

    local items = api.get_list_entries({
        filewin = winnr,
        id = 0,
        idx = item_id,
    })

    if items == nil then
        return -- no list exists to preview
    end

    if #items <= 0 then
        return -- no item to preview
    end
    local item = items[1] -- the first item should be the item specified by idx

    --https://vi.stackexchange.com/a/27166
    if item.lnum ~= nil then
        local cmd = [[pedit +setl\ nofoldenable|]]
            .. item.lnum
            .. ' '
            .. vim.fn.bufname(item.bufnr)
        vim.cmd(cmd)
    else
        vim.cmd(
            [[pedit +setl\ nofoldenable|]]
                .. 0
                .. ' '
                .. vim.fn.bufname(item.bufnr)
        )
    end

    -- range = {
    --           ["end"] = {
    --             character = 21,
    --             line = 1304
    --           },
    --           start = {
    --             character = 18,
    --             line = 1304
    --           }
    --         }
    local preview_window_number = get_preview_window_id()
    if preview_window_number ~= nil then
        local preview_bufnr = vim.fn.winbufnr(preview_window_number)
        clear_hl(preview_bufnr)
        local preview_window_id = vim.fn.win_getid(preview_window_number)
        vim.api.nvim_win_set_hl_ns(
            preview_window_id,
            quickfix_preview_namespace
        )
        local start_line = 0
        local start_col = 0
        local end_line = 0
        local end_col = 2147483647
        if
            item.user_data ~= nil
            and item.user_data.range ~= nil
            and item.user_data.range.start ~= nil
        then
            local start = item.user_data.range.start
            if start.line ~= nil then start_line = start.line end
            if start.character ~= nil then start_col = start.character end
        end
        if
            item.user_data ~= nil
            and item.user_data.range ~= nil
            and item.user_data.range['end'] ~= nil
        then
            local end_pos = item.user_data.range['end']
            if end_pos.line ~= nil then end_line = end_pos.line end
            if end_pos.character ~= nil then end_col = end_pos.character end
        end
        vim.highlight.range(
            preview_bufnr,
            quickfix_preview_namespace,
            'quickfix_preview_highlight_group',
            {
                start_line,
                start_col,
            },
            {
                end_line,
                end_col,
            },
            {}
        )
    else
        vim.notify('Could not find the preview window', vim.log.levels.WARN)
    end
end

return M
