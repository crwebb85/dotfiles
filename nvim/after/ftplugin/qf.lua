local qf_properties = require('config/quickfix').properties

vim.print('qf after plugin')
local qf_bufnr = vim.api.nvim_get_current_buf()
local qf_win_id = vim.fn.win_getid()
local qf_is_loc = vim.fn.getwininfo(qf_win_id)[1].loclist == 1

vim.opt_local.spell = false

-- local quickfix_preview_namespace = 0
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

local function preview_quickfix_list()
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local item_id = row
    -- vim.print(item_id)
    local items = {}
    if qf_is_loc then
        items = vim.fn.getloclist(0, {
            id = 0,
            idx = item_id,
            all = 0, --gets all the fields
        }).items
    else
        items = vim.fn.getqflist({
            id = 0,
            idx = item_id,
            all = 0, --gets all the fields
        }).items
        -- vim.print(items)
    end

    -- vim.print(items)
    local item = items[1]
    --https://vi.stackexchange.com/a/27166
    if item.lnum ~= nil then
        local cmd = [[pedit +setl\ nofoldenable|]]
            .. item.lnum
            .. ' '
            .. vim.fn.bufname(item.bufnr)
        -- .. vim.uri_to_fname(item.user_data.uri)
        -- vim.print(cmd)
        vim.cmd(cmd)
    else
        vim.cmd(
            [[pedit +setl\ nofoldenable|]]
                .. 0
                .. ' '
                .. vim.fn.bufname(item.bufnr)
            -- .. vim.uri_to_fname(item.user_data.uri)
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
        -- vim.print('preview_bufnr:', preview_bufnr)
        -- vim.print(item.user_data.range)
        -- vim.print(item)
        clear_hl(preview_bufnr)
        local preview_window_id = vim.fn.win_getid(preview_window_number)
        -- vim.print('preview_window_id:', preview_window_id)
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
        vim.print('Could not find the preview window')
    end
end

vim.keymap.set('n', '<CR>', function()
    if qf_properties.is_qf_preview_mode() then vim.cmd('pclose') end

    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local item_id = row
    if qf_is_loc then
        vim.cmd([[:ll ]] .. item_id)
    else
        vim.cmd([[:cc ]] .. item_id)
    end
    vim.cmd([[:norm zR ]]) --Open folds
end, {
    buffer = qf_bufnr,
    silent = true,
    desc = 'Custom - Quick Fix List: Go to quickfix item under cursor',
})
--https://github.com/romainl/vim-qf
--https://github.com/ten3roberts/qf.nvim
vim.keymap.set('n', '<C-p>', function(_)
    if qf_properties.is_qf_preview_mode() then
        qf_properties.set_qf_preview_mode(false)
        vim.cmd('pclose')
    else
        preview_quickfix_list()
        qf_properties.set_qf_preview_mode(true)
    end
end, {
    buffer = qf_bufnr,
    desc = 'Custom - Quick Fix List: Toggle preview mode',
})

vim.api.nvim_create_autocmd('BufLeave', {
    callback = function(_)
        if qf_properties.is_qf_preview_mode() then vim.cmd('pclose') end
    end,
    buffer = qf_bufnr,
})

vim.api.nvim_create_autocmd('CursorHold', {
    callback = function(_)
        if qf_properties.is_qf_preview_mode() then preview_quickfix_list() end
    end,
    buffer = qf_bufnr,
})
