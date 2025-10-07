local qf_properties = require('myconfig.quickfix').properties
local qf_preview = require('myconfig.quickfix').preview

local qf_bufnr = vim.api.nvim_get_current_buf()
local qf_win_id = vim.fn.win_getid()
local qf_is_loc = vim.fn.getwininfo(qf_win_id)[1].loclist == 1

vim.wo.spell = false

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
        qf_preview.preview_quickfix_list()
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
        if qf_properties.is_qf_preview_mode() then
            qf_preview.preview_quickfix_list()
        end
    end,
    buffer = qf_bufnr,
})
