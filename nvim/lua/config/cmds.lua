local Set = require('utils.datastructure').Set
local format_properties = require('config.formatter').properties

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

--Formatting

local function get_buffer_formatter_names()
    local buffer_formatters =
        require('config.formatter').get_buffer_formatter_details(0)
    local formatter_names = {}
    for _, formatter_info in pairs(buffer_formatters) do
        table.insert(formatter_names, formatter_info.name)
    end
    return formatter_names
end

vim.api.nvim_create_user_command('FormatterToggleBufferAutoFormat', function()
    format_properties.set_buffer_autoformat_disabled(
        not format_properties.is_buffer_autoformat_disabled()
    )
    if format_properties.is_buffer_autoformat_disabled() then
        vim.api.nvim_exec_autocmds('User', { pattern = 'DisabledFormatter' })
    else
        vim.api.nvim_exec_autocmds('User', { pattern = 'EnabledFormatter' })
    end
end, {
    desc = 'Toggle autoformat-on-save.',
})

vim.api.nvim_create_user_command(
    'FormatterDisableBufferFormatters',
    function(args)
        local formatters_to_disable = args.fargs

        if #formatters_to_disable == 0 then
            vim.print('No formatters listed to disable')
            return
        end

        local disabled_formatters_set =
            Set:new(format_properties.get_buffer_disabled_formatters())
        local formatters_to_disable_set = Set:new(formatters_to_disable)
        local valid_formatters_set = Set:new(get_buffer_formatter_names())
        local new_disabled_formatters_set = disabled_formatters_set:union(
            (valid_formatters_set:intersection(formatters_to_disable_set))
        )
        local new_disabled_formatters = new_disabled_formatters_set:to_array()
        vim.print('Disabled buffer formatters:', new_disabled_formatters)
        format_properties.set_buffer_disabled_formatters(
            new_disabled_formatters
        )

        vim.api.nvim_exec_autocmds('User', {
            pattern = 'DisabledFormatter',
        })
    end,
    {
        complete = get_buffer_formatter_names,
        nargs = '+', --Any number of arguments greater than zero
        desc = 'Disables formatters for the buffer.',
    }
)

vim.api.nvim_create_user_command(
    'FormatterEnableBufferFormatters',
    function(args)
        local formatters_to_enable = args.fargs
        if #formatters_to_enable == 0 then
            vim.print('No formatters listed to enable')
            return
        end

        local formatters_to_enable_set = Set:new(formatters_to_enable)
        local disabled_formatters_set =
            Set:new(format_properties.get_buffer_disabled_formatters())
        local new_disabled_formatters = disabled_formatters_set
            :difference(formatters_to_enable_set)
            :to_array()
        vim.print('Buffer formatters still disabled:', new_disabled_formatters)
        format_properties.set_buffer_disabled_formatters(
            new_disabled_formatters
        )

        vim.api.nvim_exec_autocmds('User', { pattern = 'EnabledFormatter' })
    end,
    {
        complete = function()
            return format_properties.get_buffer_disabled_formatters()
        end,
        nargs = '+', -- any number of arguments greater than zero
        desc = 'Enable formatters for the buffer.',
    }
)

vim.api.nvim_create_user_command('FormatterToggleProjectAutoFormat', function()
    format_properties.set_project_autoformat_disabled(
        not format_properties.is_project_autoformat_disabled()
    )
    if format_properties.is_project_autoformat_disabled() then
        vim.api.nvim_exec_autocmds('User', { pattern = 'DisabledFormatter' })
    else
        vim.api.nvim_exec_autocmds('User', { pattern = 'EnabledFormatter' })
    end
end, {
    desc = 'Toggle autoformat on save project wide.',
})

vim.api.nvim_create_user_command(
    'FormatterDisableProjectFormatters',
    function(args)
        local formatters_to_disable = args.fargs
        if #formatters_to_disable == 0 then
            vim.print('No formatters listed to disable')
            return
        end

        local disabled_formatters_set =
            Set:new(format_properties.get_project_disabled_formatters())
        local formatters_to_disable_set = Set:new(formatters_to_disable)
        local valid_formatters_set = Set:new(get_buffer_formatter_names())
        local new_disabled_formatters_set = disabled_formatters_set:union(
            (valid_formatters_set:intersection(formatters_to_disable_set))
        )
        local new_disabled_formatters = new_disabled_formatters_set:to_array()
        vim.print('Project disabled formatters:', new_disabled_formatters)
        format_properties.set_project_disabled_formatters(
            new_disabled_formatters
        )

        vim.api.nvim_exec_autocmds('User', { pattern = 'DisabledFormatter' })
    end,
    {
        complete = get_buffer_formatter_names,
        nargs = '+', --Any number of arguments greater than zero
        desc = 'Disabled formatters by name project wide.',
    }
)

vim.api.nvim_create_user_command(
    'FormatterEnableProjectFormatters',
    function(args)
        local formatters_to_enable = args.fargs
        if #formatters_to_enable == 0 then
            vim.print('No formatters listed to enable')
            return
        end
        local formatters_to_enable_set = Set:new(formatters_to_enable)
        local disabled_formatters_set =
            Set:new(format_properties.get_project_disabled_formatters())
        local new_disabled_formatters = disabled_formatters_set
            :difference(formatters_to_enable_set)
            :to_array()
        vim.print(
            'Remaining project disabled formatters:',
            new_disabled_formatters
        )
        format_properties.set_project_disabled_formatters(
            new_disabled_formatters
        )

        vim.api.nvim_exec_autocmds('User', { pattern = 'EnabledFormatter' })
    end,
    {
        complete = function()
            return format_properties.get_project_disabled_formatters()
        end,
        nargs = '+', --Any number of arguments greater than zero
        desc = 'Enable formatters project wide',
    }
)

vim.api.nvim_create_user_command('FormatterSetTimeout', function(args)
    local timeout = tonumber(args.fargs[1])
    if timeout == nil then error('Invalid timeout') end
    if timeout < 500 then
        error('Format timeout should be greater than 500 milliseconds')
    end
    if timeout > 180000 then -- three minutes
        error(
            'Format timeout should be less then 180000 milliseconds (3 minutes)'
        )
    end
    format_properties.set_formatting_timeout(timeout)
end, {
    complete = function() return { '500', '1000', '2000', '3000', '5000' } end,
    nargs = 1,
    desc = 'Sets the formatter timeout in milliseconds',
})

vim.api.nvim_create_user_command(
    'FormatterGetDetails',
    function() vim.print(format_properties.get_buffer_formatting_details()) end,
    { desc = 'Prints the formatting details for the buffer' }
)

vim.api.nvim_create_user_command(
    'FormatterSetBufferLspFormatStrategy',
    function(args)
        local strategy_name = args.fargs[1]
        -- vim.print(strategy_name)
        local strategy = format_properties.LspFormatStrategyEnums[strategy_name]
        if strategy == nil then error('Invalid LSP format strategy') end
        format_properties.set_buffer_lsp_format_strategy(strategy)
    end,
    {
        complete = function()
            local strategies = {}
            for strategy_name, _ in
            pairs(format_properties.LspFormatStrategyEnums)
            do
                table.insert(strategies, strategy_name)
            end
            return strategies
        end,
        nargs = 1,
        desc = 'Sets the formatter timeout in milliseconds',
    }
)

vim.api.nvim_create_user_command(
    'FormatterSetFileTypeLspFormatStrategy',
    function(args)
        local strategy_name = args.fargs[1]
        local strategy = format_properties.LspFormatStrategyEnums[strategy_name]
        if strategy == nil then error('Invalid LSP format strategy') end
        local filetype = vim.bo.filetype
        if filetype == nil then error('The buffer has no file type') end
        format_properties.set_filetype_lsp_format_strategy(filetype, strategy)
    end,
    {
        complete = function()
            local strategies = {}
            for strategy_name, _ in
            pairs(format_properties.LspFormatStrategyEnums)
            do
                table.insert(strategies, strategy_name)
            end
            return strategies
        end,
        nargs = 1,
        desc = 'Sets the formatter timeout in milliseconds',
    }
)
