vim.api.nvim_create_user_command(
    'ViewOpen',
    function(opts) require('config.utils').openView(tonumber(opts.args)) end,
    { nargs = '?' }
)
vim.api.nvim_create_user_command(
    'ViewPrintPath',
    function(opts) require('config.utils').printViewPath(tonumber(opts.args)) end,
    { nargs = '?' }
)
vim.api.nvim_create_user_command(
    'ViewReset',
    function(opts) require('config.utils').resetView(tonumber(opts.args)) end,
    { nargs = '?' }
)
vim.api.nvim_create_user_command(
    'ViewDelete',
    function(opts) require('config.utils').deleteView(tonumber(opts.args)) end,
    { nargs = '?' }
)

-- Diff Clipboard https://www.naseraleisa.com/posts/diff#file-1
-- TODO cleanup these user commands to not us vim.cmd
-- Create a new scratch buffer
vim.api.nvim_create_user_command(
    'Ns',
    require('config.utils').openNewScratchBuffer,
    { nargs = 0 }
)

-- Compare clipboard to current buffer
vim.api.nvim_create_user_command(
    'CompareClipboard',
    require('config.utils').compareClipboardToBuffer,
    { nargs = 0 }
)

vim.api.nvim_create_user_command(
    'CompareClipboardSelection',
    require('config.utils').compareClipboardToSelection,
    {
        nargs = 0,
        range = true,
    }
)

vim.api.nvim_create_user_command('FormatDisable', function(args)
    -- FormatDisable! will disable formatting just for this buffer
    vim.b.disable_autoformat = true
    if not args.bang then vim.g.disable_autoformat = true end

    vim.api.nvim_exec_autocmds('User', { pattern = 'DisabledFormatter' })
end, {
    desc = 'Disable autoformat-on-save',
    bang = true,
})

vim.api.nvim_create_user_command('FormatEnable', function(args)
    -- FormatDisable! will enable formatting just for this buffer
    vim.b.disable_autoformat = false
    if not args.bang then vim.g.disable_autoformat = false end

    vim.api.nvim_exec_autocmds('User', { pattern = 'EnabledFormatter' })
end, {
    desc = 'Re-enable autoformat-on-save',
    bang = true,
})
