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

-- Create a new scratch buffer to the left that will push my working window
-- closer to the center so that I am not hurting my neck
-- https://github.com/smithbm2316/centerpad.nvim/
vim.api.nvim_create_user_command('CenterWindow', function()
    --TODO maybe add a toggle
    local old_splitright_value = vim.go.splitright
    vim.opt.splitright = false
    local leftpad_size = 36
    local main_win = vim.api.nvim_get_current_win()
    local leftpad_buf_name = 'leftpad'
    local leftpad_bufnr = vim.fn.bufnr(leftpad_buf_name)
    if leftpad_bufnr < 0 then -- reopen the same scratch buffer if it already exists
        vim.cmd(string.format('%svnew', leftpad_size))
        leftpad_bufnr = vim.api.nvim_get_current_buf()
    else
        vim.cmd(string.format('%svsplit', leftpad_size))
        vim.api.nvim_set_current_buf(leftpad_bufnr)
    end
    vim.api.nvim_buf_set_name(leftpad_bufnr, leftpad_buf_name)
    vim.bo[leftpad_bufnr].buftype = 'nofile'
    vim.bo[leftpad_bufnr].bufhidden = 'hide'
    vim.bo[leftpad_bufnr].swapfile = false
    vim.api.nvim_set_current_win(main_win)

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

vim.api.nvim_create_user_command('CompareClipboardSelection', function()
    local file_type = vim.opt_local.filetype
    local selection_text = require('utils.misc').get_visual_selection(0)
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
    function(_) vim.fn['RemoveDuplicateQFListFiles']() end,
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

---Add items to the quickfix list based on the treesitter query defined inside
---the opened treesitter query editor window. (Use :QueryEdit to open the query
---edit window and :InspectTree to see what the treesitter tree looks like).
---If no parameters supplied then all capture groups will be added to the QF list.
---Otherwise you can restrict QF list to only include capture groups you need by
---supplying the list of capture groups as command paramters
vim.api.nvim_create_user_command('QFRunTSQuery', function(params)
    local capture_names_set = Set:new(params.fargs)
    local query_bufnr = nil
    local tabnr = vim.api.nvim_tabpage_get_number(0)
    for _, winnr in ipairs(vim.api.nvim_tabpage_list_wins(tabnr)) do
        query_bufnr = vim.api.nvim_win_get_buf(winnr)
        local buf_name = vim.api.nvim_buf_get_name(query_bufnr)
        if string.match(buf_name, '.*[\\/]query_editor%.scm') ~= nil then
            break
        end
    end

    if query_bufnr == nil then error('No query editor open in tab') end

    local base_bufnr = vim.api.nvim_win_get_buf(0)
    local base_buf_name = vim.api.nvim_buf_get_name(base_bufnr)

    local lang = vim.treesitter.language.get_lang(vim.bo[base_bufnr].filetype)
    local parser = vim.treesitter.get_parser(base_bufnr, lang)
    local query_content = table.concat(
        vim.api.nvim_buf_get_lines(query_bufnr, 0, -1, false),
        '\n'
    )

    local ok_query, query =
        pcall(vim.treesitter.query.parse, lang, query_content)
    if not ok_query then return end

    local items = {}
    for id, node in query:iter_captures(parser:trees()[1]:root(), base_bufnr) do
        local capture_name = query.captures[id]

        if
            capture_names_set.size == 0 or capture_names_set:has(capture_name)
        then
            local lnum, col, end_lnum, end_col = node:range()
            local item = {
                filename = base_buf_name,
                lnum = lnum + 1,
                end_lnum = end_lnum + 1,
                col = col + 1,
                end_col = end_col + 1,
                text = capture_name,
            }
            table.insert(items, item)
        end
    end
    vim.fn.setqflist({}, ' ', { items = items })
end, {
    nargs = '*',
})
--[[
(class_declaration 
  ; name: (identifier) @classname
  ; (.eq? @classname "Program")
  body: (declaration_list
            (method_declaration
                ; (modifier) @modifier
                ; (.eq? @modifier "public")

                name: (identifier) @name
                ; parameters: (parameter_list) @parameters
                ; body: (block) @body
              )
          ) 
)
]]

vim.api.nvim_create_user_command('QFRemoveInvalid', function(_)
    local items = vim.fn.getqflist()
    items = vim.tbl_filter(function(item) return item.valid == 1 end, items)
    vim.fn.setqflist({}, ' ', { items = items })
    vim.cmd('open')
end, {
    desc = 'Remove invalid quickfix items',
})
-------------------------------------------------------------------------------
---Task runner commands

vim.api.nvim_create_user_command('Make', function(params)
    -- Insert args at the '$*' in the makeprg
    local cmd, num_subs = vim.o.makeprg:gsub('%$%*', params.args)
    if num_subs == 0 then cmd = cmd .. ' ' .. params.args end
    local task = require('overseer').new_task({
        cmd = vim.fn.expandcmd(cmd),
        components = {
            { 'on_output_quickfix', open = not params.bang, open_height = 8 },
            'default',
        },
    })
    task:start()
end, {
    desc = 'Run your makeprg as an Overseer task',
    nargs = '*',
    bang = true,
})

--- Given a path, open the file, extract all the Makefile keys,
--  and return them as a list.
---@param path string
---@return table options A telescope options list like
--{ { text: "1 - all", value="all" }, { text: "2 - hello", value="hello" } ...}
local function get_makefile_options(path)
    local options = {}

    -- Open the Makefile for reading
    local file = io.open(path, 'r')

    if file then
        local in_target = false
        local count = 0

        -- Iterate through each line in the Makefile
        for line in file:lines() do
            -- Check for lines starting with a target rule (e.g., "target: dependencies")
            local target = line:match('^(.-):')
            if target then
                in_target = true
                count = count + 1
                -- Exclude the ":" and add the option to the list with text and value fields
                table.insert(
                    options,
                    { text = count .. ' - ' .. target, value = target }
                )
            elseif in_target then
                -- If we're inside a target block, stop adding options
                in_target = false
            end
        end

        -- Close the Makefile
        file:close()
    else
        vim.notify(
            'Unable to open a Makefile in the current working dir.',
            vim.log.levels.ERROR,
            {
                title = 'Makeit.nvim',
            }
        )
    end

    return options
end

vim.api.nvim_create_user_command('Makeit', function(_)
    -- dependencies
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local state = require('telescope.actions.state')
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local options = get_makefile_options(
        require('utils.path').concat({ vim.fn.getcwd(), 'Makefile' })
    )

    --- On option selected → Run action depending of the language
    local function on_option_selected(prompt_bufnr)
        actions.close(prompt_bufnr) -- Close Telescope on selection
        local selection = state.get_selected_entry()
        _G.makeit_redo = selection.value -- Save redo
        if selection then
            vim.cmd([[Make ]] .. selection.value) --TODO replace with a local function
        end
    end

    --- Show telescope
    local function open_telescope()
        pickers
            .new({}, {
                prompt_title = 'Makeit',
                results_title = 'Options',
                finder = finders.new_table({
                    results = options,
                    entry_maker = function(entry)
                        return {
                            display = entry.text,
                            value = entry.value,
                            ordinal = entry.text,
                        }
                    end,
                }),
                sorter = conf.generic_sorter(),
                attach_mappings = function(_, map)
                    map(
                        'i',
                        '<CR>',
                        function(prompt_bufnr) on_option_selected(prompt_bufnr) end
                    )
                    map(
                        'n',
                        '<CR>',
                        function(prompt_bufnr) on_option_selected(prompt_bufnr) end
                    )
                    return true
                end,
            })
            :find()
    end
    open_telescope() -- Entry point
end, {
    desc = 'Opens telescope picker to pick the Make task to run',
})

vim.api.nvim_create_user_command('OverseerRestartLast', function()
    local overseer = require('overseer')
    local tasks = overseer.list_tasks({ recent_first = true })
    if vim.tbl_isempty(tasks) then
        vim.notify('No tasks found', vim.log.levels.WARN)
    else
        overseer.run_action(tasks[1], 'restart')
    end
end, {})

vim.api.nvim_create_user_command('Grep', function(params)
    local overseer = require('overseer')
    -- Insert args at the '$*' in the grepprg
    local cmd, num_subs = vim.o.grepprg:gsub('%$%*', params.args)
    if num_subs == 0 then cmd = cmd .. ' ' .. params.args end
    local task = overseer.new_task({
        cmd = vim.fn.expandcmd(cmd),
        components = {
            {
                'on_output_quickfix',
                errorformat = vim.o.grepformat,
                open = not params.bang,
                open_height = 8,
                items_only = true,
            },
            -- We don't care to keep this around as long as most tasks
            { 'on_complete_dispose', timeout = 30 },
            'default',
        },
    })
    task:start()
end, { nargs = '*', bang = true, complete = 'file' })

vim.api.nvim_create_user_command(
    'OverseerDebugParser',
    function() require('overseer').debug_parser() end,
    {}
)

--https://github.com/stevearc/dotfiles/blob/master/.config/nvim/plugin/stacktrace.lua
vim.api.nvim_create_user_command('Stacktrace', function(params)
    local selection_text = {}

    if params.range == 2 then
        selection_text = require('utils.misc').get_visual_selection(0)
    end

    local bufnr = vim.api.nvim_create_buf(false, true)

    vim.bo[bufnr].bufhidden = 'wipe'
    local winid = vim.api.nvim_open_win(bufnr, true, {
        relative = 'editor',
        width = vim.o.columns,
        height = vim.o.lines,
        row = 1,
        col = 1,
        border = 'rounded',
        style = 'minimal',
        title = 'Stacktrace',
        title_pos = 'center',
    })

    vim.api.nvim_buf_set_lines(bufnr, 0, 1, true, selection_text)

    local colors = require('tokyonight.colors').setup()
    vim.api.nvim_set_hl(0, 'stacktrace_quickfix_item_hl_group', {
        fg = colors.dark3,
        italic = true,
    })
    vim.fn.matchadd(
        'stacktrace_quickfix_item_hl_group',
        '[^%s].\\+:\\d\\+:\\(\\d\\+:\\)\\= .\\+'
        --matches text like the following lines
        --[[ 
            .\hello-world.go:6: undefined: mt
            adfas .\hello-world.go:3:8: "fmt" imported and not used
            .\hello-world.go:6:2: undefined: mt
        ]]
        --
    )
    local cancel
    local confirm
    cancel = function()
        cancel = function() end
        confirm = function() end
        vim.api.nvim_win_close(winid, true)
    end
    confirm = function()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
        cancel()
        local items = vim.fn.getqflist({
            lines = lines,
        }).items
        -- Use :Stacktrace! to not filter out invalid lines
        if not params.bang then
            items = vim.tbl_filter(
                function(item) return item.valid == 1 end,
                items
            )
        end
        vim.fn.setqflist({}, ' ', {
            title = 'Stacktrace',
            items = items,
        })
        vim.cmd('copen')
    end
    vim.keymap.set('n', 'q', cancel, { buffer = bufnr })
    vim.keymap.set({ 'n', 'i' }, '<C-c>', cancel, { buffer = bufnr })
    vim.keymap.set('n', '<CR>', confirm, { buffer = bufnr })
    vim.keymap.set({ 'n', 'i' }, '<C-s>', confirm, { buffer = bufnr })
end, {
    desc = 'Parse a stacktrace using errorformat and add to quickfix',
    bang = true,
    range = true,
})

-------------------------------------------------------------------------------

vim.api.nvim_create_user_command('ConvertLineEndings', function(params)
    vim.print(params)
    local line_ending = params.args
    if line_ending == 'lf' then
        vim.cmd([[
                :update
                :e ++ff=dos
                :setlocal ff=unix
                :w
            ]])
    elseif line_ending == 'crlf' then
        vim.cmd([[
                :update
                :e ++ff=dos
                :w
            ]])
    else
        vim.print('Invalid line_ending name of:' .. line_ending)
    end
end, {
    nargs = 1,
    bang = true,
    complete = function() return { 'lf', 'crlf' } end,
})
