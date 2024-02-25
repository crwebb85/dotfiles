local Set = require('utils.datastructure').Set

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

local function get_buffer_formatter_names()
    local buffer_formatters =
        require('config.utils').get_buffer_formatter_details(0)
    local formatter_names = {}
    for _, formatter_info in pairs(buffer_formatters) do
        table.insert(formatter_names, formatter_info.name)
    end
    -- vim.print(args)
    return formatter_names
end
vim.api.nvim_create_user_command('FormatDisableBuffer', function(args)
    -- vim.print(args)
    local formatters_to_disable = args.fargs
    if #formatters_to_disable == 0 then
        vim.print('Format on save disabled for buffer')
        vim.b.disable_autoformat = true
    else
        if vim.b.disabled_formatters == nil then
            vim.b.disabled_formatters = {}
        end
        local disabled_formatters_set = Set:new(vim.b.disabled_formatters)
        local formatters_to_disable_set = Set:new(formatters_to_disable)
        local valid_formatters_set = Set:new(get_buffer_formatter_names())
        local new_disabled_formatters_set = disabled_formatters_set:union(
            (valid_formatters_set:intersection(formatters_to_disable_set))
        )
        new_disabled_formatters_set:print()
        vim.b.disabled_formatters = new_disabled_formatters_set:to_array()
    end

    vim.api.nvim_exec_autocmds('User', {
        pattern = 'DisabledFormatter',
    })
end, {
    complete = get_buffer_formatter_names,
    nargs = '*', --Any number of arguments
    desc = 'Disable autoformat-on-save for the buffer. If formatter names are specified as arguments only those formatters will be disabled.',
})

vim.api.nvim_create_user_command('FormatDisableProject', function(args)
    local formatters_to_disable = args.fargs
    if #formatters_to_disable == 0 then
        vim.print('Format on save disabled project wide')
        vim.g.disable_autoformat = true
    else
        if vim.g.disabled_formatters == nil then
            vim.g.disabled_formatters = {}
        end

        local disabled_formatters_set = Set:new(vim.g.disabled_formatters)
        local formatters_to_disable_set = Set:new(formatters_to_disable)
        local valid_formatters_set = Set:new(get_buffer_formatter_names())
        local new_disabled_formatters_set = disabled_formatters_set:union(
            (valid_formatters_set:intersection(formatters_to_disable_set))
        )
        new_disabled_formatters_set:print()
        vim.g.disabled_formatters = new_disabled_formatters_set:to_array()
    end

    vim.api.nvim_exec_autocmds('User', { pattern = 'DisabledFormatter' })
end, {
    complete = get_buffer_formatter_names,
    nargs = '*', --Any number of arguments
    desc = 'Disable autoformat-on-save project wide. If formatter names are specified as arguments only those formatters will be disabled.',
})

vim.api.nvim_create_user_command('FormatEnableBuffer', function(args)
    local formatters_to_enable = args.fargs
    if #formatters_to_enable == 0 then
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
    else
        if vim.b.disabled_formatters == nil then
            vim.b.disabled_formatters = {}
        end
        local formatters_to_enable_set = Set:new(formatters_to_enable)
        local disabled_formatters_set = Set:new(vim.b.disabled_formatters)
        vim.b.disabled_formatters = disabled_formatters_set
            :difference(formatters_to_enable_set)
            :to_array()
        vim.print(vim.b.disabled_formatters)
    end

    vim.api.nvim_exec_autocmds('User', { pattern = 'EnabledFormatter' })
end, {
    complete = function() return vim.b.disabled_formatters end,
    nargs = '*',
    desc = 'Re-enable autoformat-on-save for buffer.',
})

vim.api.nvim_create_user_command('FormatEnableProject', function(args)
    local formatters_to_enable = args.fargs
    if #formatters_to_enable == 0 then
        if vim.g.disable_autoformat == false then
            vim.print('Format on save already enabled project wide')
        else
            vim.g.disable_autoformat = false
            vim.print(
                'Enabled format on save project wide. Note: Did not change buffer specific settings'
            )
        end
    else
        if vim.g.disabled_formatters == nil then
            vim.g.disabled_formatters = {}
        end
        local formatters_to_enable_set = Set:new(formatters_to_enable)
        local disabled_formatters_set = Set:new(vim.g.disabled_formatters)
        vim.g.disabled_formatters = disabled_formatters_set
            :difference(formatters_to_enable_set)
            :to_array()
        vim.print(vim.g.disabled_formatters)
    end

    vim.api.nvim_exec_autocmds('User', { pattern = 'EnabledFormatter' })
end, {
    complete = function() return vim.g.disabled_formatters end,
    nargs = '*',
    desc = 'Re-enable autoformat-on-save project wide',
})
