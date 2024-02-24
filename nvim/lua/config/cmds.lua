-- Scratch

vim.api.nvim_create_user_command(
    'ScratchTab',
    function()
        vim.cmd([[
		    " open new tab, set options to prevent save prompt when closing
		    execute 'tabnew | setlocal buftype=nofile bufhidden=hide noswapfile'
	    ]])
    end,
    { nargs = 0 }
)

-- Messages
vim.api.nvim_create_user_command('MessagesTab', function()
    vim.cmd([[
		    " open new tab, set options to prevent save prompt when closing
		    execute "tabnew | setlocal buftype=nofile bufhidden=hide noswapfile | :put =execute(':messages')"
	    ]])
    --TODO add a autocmd to auto refresh the buffer contents with new messages
end, { nargs = 0 })

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

vim.api.nvim_create_user_command('FormatDisableBuffer', function(_)
    vim.print('Format on save disabled for buffer')
    vim.b.disable_autoformat = true

    vim.api.nvim_exec_autocmds('User', { pattern = 'DisabledFormatter' })
end, {
    desc = 'Disable autoformat-on-save for the buffer',
})

vim.api.nvim_create_user_command('FormatDisableProject', function(_)
    vim.print('Format on save disabled project wide')
    vim.g.disable_autoformat = true

    vim.api.nvim_exec_autocmds('User', { pattern = 'DisabledFormatter' })
end, {
    desc = 'Disable autoformat-on-save project wide',
})

vim.api.nvim_create_user_command('FormatEnableBuffer', function(_)
    if vim.g.disable_autoformat == true then
        vim.print(
            "Enabled format on save for buffer but this won't go into effect because formating is disabled project wide"
        )
        vim.b.disable_autoformat = false
    elseif vim.b.disable_autoformat == false then
        vim.print('Format on save already enabled for buffer')
    else
        vim.print('Enabled format on save for buffer')
        vim.b.disable_autoformat = false
    end
    vim.api.nvim_exec_autocmds('User', { pattern = 'EnabledFormatter' })
end, {
    desc = 'Re-enable autoformat-on-save for buffer.',
})

vim.api.nvim_create_user_command('FormatEnableProject', function(_)
    if vim.g.disable_autoformat == false then
        vim.print('Format on save already enabled project wide')
    else
        vim.g.disable_autoformat = false
        vim.print(
            'Enabled format on save project wide. Note: Did not change buffer specific settings'
        )
    end

    vim.api.nvim_exec_autocmds('User', { pattern = 'EnabledFormatter' })
end, {
    desc = 'Re-enable autoformat-on-save project wide',
})
