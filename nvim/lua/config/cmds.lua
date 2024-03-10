local Set = require('utils.datastructure').Set
local format_properties = require('config.formatter').properties

-------------------------------------------------------------------------------
-- Scratch

vim.api.nvim_create_user_command(
    'ScratchTab',
    function()
        vim.cmd([[
		    " open new tab, set options to prevent save prompt when closing
		    execute 'tabnew' 
            setlocal buftype=nofile 
            setlocal bufhidden=hide 
            setlocal noswapfile
	    ]])
    end,
    { nargs = 0, desc = 'Creates a scratch buffer in a new tab' }
)

-- Create a new scratch buffer to the right
vim.api.nvim_create_user_command('Scratch', function()
    local old_splitright_value = vim.go.splitright
    vim.opt.splitright = true
    vim.cmd([[
            execute 'vsplit | enew'
            setlocal buftype=nofile
            setlocal bufhidden=hide
            setlocal noswapfile
        ]])
    vim.opt.splitright = old_splitright_value
end, { nargs = 0, desc = 'Creates a scratch buffer to the right' })

-------------------------------------------------------------------------------
-- Messages

vim.api.nvim_create_user_command('MessagesTab', function()
    vim.cmd([[
		    " open new tab, set options to prevent save prompt when closing
		    execute 'tabnew' 
            setlocal buftype=nofile 
			setlocal bufhidden=delete
            setlocal noswapfile 
            execute ":put =execute(':messages')"
	    ]])

    vim.print('Refresh message buffer with "<leader>R"')
    vim.keymap.set(
        'n',
        '<leader>R',
        function() vim.cmd([[execute ":%delete_ | :put =execute(':messages')"]]) end,
        {
            buffer = 0,
            desc = [[Messages: Refreshes messages buffer with latest messages]],
        }
    )
end, {
    nargs = 0,
    desc = 'Open vim messages in a temporary scratch buffer in new tab',
})

vim.api.nvim_create_user_command('Messages', function()
    local old_splitright_value = vim.go.splitright
    vim.opt.splitright = true
    vim.cmd([[
		    " open new tab, set options to prevent save prompt when closing
            execute 'vsplit | enew'
            setlocal buftype=nofile 
			setlocal bufhidden=delete
            setlocal noswapfile 
            execute ":put =execute(':messages')"
	    ]])
    vim.opt.splitright = old_splitright_value

    vim.print('Refresh message buffer with "<leader>R"')
    vim.keymap.set(
        'n',
        '<leader>R',
        function() vim.cmd([[execute ":%delete_ | :put =execute(':messages')"]]) end,
        {
            buffer = 0,
            desc = [[Messages: Refreshes messages buffer with latest messages]],
        }
    )
end, { nargs = 0, desc = 'Open vim messages in a temporary scratch buffer' })

-------------------------------------------------------------------------------
-- Diff Clipboard https://www.naseraleisa.com/posts/diff#file-1

-- Compare clipboard to current buffer
vim.api.nvim_create_user_command('CompareClipboard', function()
    local ftype = vim.api.nvim_eval('&filetype') -- original filetype
    vim.cmd([[
		tabnew %
	    
        "create scratch buffer that will contain contents of buffer
        execute 'vsplit | enew'
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        " paste clipboard into scratch buffer
		normal! P
		windo diffthis
	]])
    vim.cmd('set filetype=' .. ftype)
end, { nargs = 0, desc = 'Compares buffer file with clipboard contents' })

---Get the text in the visual selection
---@param bufnr number of the buffer with text selected
---@return string[]
local function get_visual_selection(bufnr)
    local start_pos = vim.api.nvim_buf_get_mark(0, '<')
    local start_row = start_pos[1]
    local start_col = start_pos[2]

    local end_pos = vim.api.nvim_buf_get_mark(0, '>')
    local end_row = end_pos[1]
    local end_col = end_pos[2]
    -- vim.print(start_pos)
    -- vim.print(end_pos)

    ---@type string[]
    local text = {}

    if end_col == 2147483647 then
        text = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, true)
    else
        text = vim.api.nvim_buf_get_text(
            bufnr,
            start_row - 1,
            start_col,
            end_row - 1,
            end_col + 1,
            {}
        )
    end
    return text
end

vim.api.nvim_create_user_command('CompareClipboardSelection', function()
    local file_type = vim.opt_local.filetype
    local selection_text = get_visual_selection(0)
    vim.cmd([[
		" open new tab, set options to prevent save prompt when closing
		execute 'tabnew'
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
    ]])
    vim.opt_local.filetype = file_type -- setfile type of first buffer
    vim.api.nvim_buf_set_lines(0, 0, 1, true, selection_text)

    vim.cmd([[
        " create comparison buffer
        execute 'vsplit | enew'
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
         
	]])

    vim.opt_local.filetype = file_type -- set filetype of second buffer

    vim.cmd([[
		normal! VP
		windo diffthis
	]])
end, {
    nargs = 0,
    desc = 'Compare visual selection with clipboard contents',
    range = true,
})

-------------------------------------------------------------------------------
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

        vim.api.nvim_exec_autocmds('User', {
            pattern = 'ChangedLspFormatStrategy',
        })
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
        vim.api.nvim_exec_autocmds('User', {
            pattern = 'ChangedLspFormatStrategy',
        })
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

-------------------------------------------------------------------------------
---Quickfix and Location list

vim.cmd([[
    function! RemoveDuplicateLocListFiles()
        let a = getloclist(0)
        let file = {}
        let result = []
        for entry in a
            if !has_key(file, entry.bufnr)
                call add(result, entry)
                let file[entry.bufnr]=1
            endif
        endfor
        if !empty(result)
            call setloclist(0, result, 'r')
        endif
    endfu
]])

vim.api.nvim_create_user_command(
    'LocRemoveDuplicateFiles',
    function(_) vim.fn['RemoveDuplicateLocListFiles']() end,
    {
        desc = 'Removes duplicate files from Loc List',
    }
)

vim.cmd([[
    function! RemoveDuplicateQFListFiles()
        let a = getqflist()
        let file = {}
        let result = []
        for entry in a
            if !has_key(file, entry.bufnr)
                call add(result, entry)
                let file[entry.bufnr] = 1
            endif
        endfor
        if !empty(result)
            call setqflist(result, 'r')
        endif
    endfu
]])

vim.api.nvim_create_user_command(
    'QFRemoveDuplicateFiles',
    function(_) vim.fn['FilterQFListToUniqueFiles']() end,
    {
        desc = 'Removes duplicate files from Quick Fix List',
    }
)

vim.api.nvim_create_user_command('QFLspDiagnostics', function(args)
    if args.args == 'ERROR' then
        vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.ERROR })
    elseif args.args == 'WARN' then
        vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.WARN })
    elseif args.args == 'HINT' then
        vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.HINT })
    elseif args.args == 'INFO' then
        vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.INFO })
    else
        vim.diagnostic.setqflist({})
    end
end, {
    desc = 'Adds lsp diagnostic to the Quickfix list',
    complete = function() return { 'ERROR', 'WARN', 'HINT', 'INFO' } end,
    nargs = '?',
})

vim.api.nvim_create_user_command('LocLspDiagnostics', function(args)
    if args.args == 'ERROR' then
        vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.ERROR })
    elseif args.args == 'WARN' then
        vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.WARN })
    elseif args.args == 'HINT' then
        vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.HINT })
    elseif args.args == 'INFO' then
        vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.INFO })
    else
        vim.diagnostic.setloclist({})
    end
end, {
    desc = 'Adds lsp diagnostic to the Quickfix list',
    complete = function() return { 'ERROR', 'WARN', 'HINT', 'INFO' } end,
    nargs = '?',
})

vim.api.nvim_create_user_command(
    'QFCopyToLoc',
    function(_)
        vim.cmd(
            [[call setloclist(0, [], ' ', {'items': get(getqflist({'items': 1}), 'items')})]]
        )
    end,
    {
        desc = 'Copies QF list to Loc list',
    }
)

vim.api.nvim_create_user_command(
    'LocCopyToQF',
    function(_)
        vim.cmd(
            [[call setqflist([], ' ', {'items': get(getloclist(0, {'items': 1}), 'items')})]]
        )
    end,
    {
        desc = 'Copies QF list to Loc list',
    }
)
