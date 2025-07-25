local Set = require('utils.datastructure').Set
local format_properties = require('config.formatter').properties
local Path = require('utils.path')
local config = require('config.config')
local M = {}

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
    vim.go.splitright = true
    vim.cmd([[
            execute 'vsplit | enew'
            setlocal buftype=nofile
            setlocal bufhidden=hide
            setlocal noswapfile
        ]])
    vim.go.splitright = old_splitright_value
end, { nargs = 0, desc = 'Creates a scratch buffer to the right' })

vim.api.nvim_create_user_command('GlobalNote', function()
    local data_dir = vim.fn.stdpath('data')
    if type(data_dir) ~= 'string' then error('Invalid data directory') end
    local directory = vim.fs.joinpath(data_dir, 'global-note')
    local filepath = vim.fs.joinpath(directory, 'global.md')
    Path.ensure_directory_exists(directory)
    Path.ensure_file_exists(filepath)

    local buffer_id = vim.fn.bufadd(filepath)
    if buffer_id == nil then
        error(
            "Unreachable: The file should exist, but it doesn't: " .. filepath
        )
    end

    vim.api.nvim_open_win(buffer_id, true, {
        split = 'right',
    })
end, { nargs = 0, desc = 'Creates the global note in split to the right' })

vim.api.nvim_create_user_command('GlobalNoteTab', function()
    local data_dir = vim.fn.stdpath('data')
    if type(data_dir) ~= 'string' then error('Invalid data directory') end
    local directory = vim.fs.joinpath(data_dir, 'global-note')
    local filepath = vim.fs.joinpath(directory, 'global.md')
    Path.ensure_directory_exists(directory)
    Path.ensure_file_exists(filepath)

    local buffer_id = vim.fn.bufadd(filepath)
    if buffer_id == nil then
        error(
            "Unreachable: The file should exist, but it doesn't: " .. filepath
        )
    end

    vim.cmd([[
		execute 'tabnew'
	]])
    vim.api.nvim_set_current_buf(buffer_id)
end, { nargs = 0, desc = 'Creates the global note in a new tab' })

-- Create a new scratch buffer to the left that will push my working window
-- closer to the center so that I am not hurting my neck
-- https://github.com/smithbm2316/centerpad.nvim/
vim.api.nvim_create_user_command('CenterWindow', function()
    --TODO maybe add a toggle
    local old_splitright_value = vim.go.splitright
    vim.go.splitright = false
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

    vim.go.splitright = old_splitright_value
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
    vim.go.splitright = true
    vim.cmd([[
		    " open new tab, set options to prevent save prompt when closing
            execute 'vsplit | enew'
            setlocal buftype=nofile
			setlocal bufhidden=delete
            setlocal noswapfile
            execute ":put =execute(':messages')"
	    ]])
    vim.go.splitright = old_splitright_value

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
    local file_type = vim.bo.filetype
    local selection_text = require('utils.misc').get_visual_selection(0)
    vim.cmd([[
		" open new tab, set options to prevent save prompt when closing
		execute 'tabnew'
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
    ]])
    vim.bo.filetype = file_type -- setfile type of first buffer
    vim.api.nvim_buf_set_lines(0, 0, 1, true, selection_text)

    vim.cmd([[
        " create comparison buffer
        execute 'vsplit | enew'
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile

	]])

    vim.bo.filetype = file_type -- set filetype of second buffer

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

vim.api.nvim_create_user_command('FormatterAutoFormatProjectToggle', function()
    local old_value = format_properties.is_project_autoformat_disabled()
    format_properties.set_project_autoformat_disabled(not old_value)
end, {
    desc = 'Toggle autoformat on save project wide.',
})

vim.api.nvim_create_user_command(
    'FormatterAutoFormatBufferToggle',
    function()
        format_properties.set_buffer_autoformat_disabled(
            not format_properties.is_buffer_autoformat_disabled()
        )
    end,
    {
        desc = 'Toggle autoformat-on-save.',
    }
)

vim.api.nvim_create_user_command('FormatterTimeout', function(args)
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

vim.api.nvim_create_user_command('FormatterAfterSaveToggle', function()
    local filetype = vim.bo[0].filetype
    local is_format_after_save_enabled =
        format_properties.is_format_after_save_enabled(filetype)
    format_properties.set_format_after_save(
        filetype,
        not is_format_after_save_enabled
    )
end, {
    desc = 'Toggles whether the formatter runs on save or after save',
})

vim.api.nvim_create_user_command(
    'FormatterDetails',
    function()
        vim.print(require('config.formatter').get_buffer_formatting_details())
    end,
    { desc = 'Prints the formatting details for the buffer' }
)
-------------------------------------------------------------------------------
---Formatter disable/enables

local function get_project_formatter_names()
    local filetype = vim.bo.filetype
    return format_properties.get_project_formatters(filetype)
end

vim.api.nvim_create_user_command('FormatterProjectToggle', function(args)
    ---@type string[]
    local formatters_to_toggle = args.fargs
    if #formatters_to_toggle == 0 then
        vim.print('No formatters listed to toggle')
        return
    end
    --remove duplicates
    local formatters_to_toggle_set = Set:new(formatters_to_toggle)
    local valid_formatters_set = Set:new(get_project_formatter_names())
    local invalid_formatters_set =
        formatters_to_toggle_set:difference(valid_formatters_set)
    if invalid_formatters_set.size >= 0 then
        vim.print(
            'Ignoring invalid formatters: '
                .. invalid_formatters_set:to_string()
        )
    end

    local sanitized_formatters_to_toggle_set =
        formatters_to_toggle_set:intersection(valid_formatters_set)

    local disabled_formatters =
        format_properties.get_project_disabled_formatters_set()

    sanitized_formatters_to_toggle_set:each(function(formatter)
        if disabled_formatters[formatter] then
            disabled_formatters[formatter] = nil
        else
            disabled_formatters[formatter] = true
        end
    end)

    ---@type string[]
    local new_disabled_formatters_list = {}
    for formatter, disabled in pairs(disabled_formatters) do
        if disabled then
            table.insert(new_disabled_formatters_list, formatter)
        end
    end

    vim.print('Project disabled formatters:', new_disabled_formatters_list)
    format_properties.set_project_disabled_formatters(
        new_disabled_formatters_list
    )
end, {
    complete = get_project_formatter_names,
    nargs = '+', --Any number of arguments greater than zero
    desc = 'Disabled formatters by name project wide.',
})

vim.api.nvim_create_user_command('FormatterBufferToggle', function(args)
    local bufnr = vim.api.nvim_get_current_buf()
    ---@type string[]
    local formatters_to_toggle = args.fargs
    if #formatters_to_toggle == 0 then
        vim.print('No formatters listed to toggle')
        return
    end
    --remove duplicates
    local formatters_to_toggle_set = Set:new(formatters_to_toggle)
    local valid_formatters_set = Set:new(get_project_formatter_names())
    local invalid_formatters_set =
        formatters_to_toggle_set:difference(valid_formatters_set)
    if invalid_formatters_set.size >= 0 then
        vim.print(
            'Ignoring invalid formatters: '
                .. invalid_formatters_set:to_string()
        )
    end

    local sanitized_formatters_to_toggle_set =
        formatters_to_toggle_set:intersection(valid_formatters_set)

    local disabled_formatters =
        format_properties.get_buffer_disabled_formatters_set(bufnr)

    sanitized_formatters_to_toggle_set:each(function(formatter)
        if disabled_formatters[formatter] then
            disabled_formatters[formatter] = nil
        else
            disabled_formatters[formatter] = true
        end
    end)

    ---@type string[]
    local new_disabled_formatters_list = {}
    for formatter, disabled in pairs(disabled_formatters) do
        if disabled then
            table.insert(new_disabled_formatters_list, formatter)
        end
    end

    vim.print('Buffer disabled formatters:', new_disabled_formatters_list)
    format_properties.set_buffer_disabled_formatters(
        new_disabled_formatters_list,
        bufnr
    )
end, {
    complete = get_project_formatter_names,
    nargs = '+', --Any number of arguments greater than zero
    desc = 'Disabled formatters by name project wide.',
})

vim.api.nvim_create_user_command(
    'FormatterBufferLspFormatStrategy',
    function(args)
        local strategy_name = args.fargs[1]
        local bufnr = vim.api.nvim_get_current_buf()
        local strategy = format_properties.LspFormatStrategyEnums[strategy_name]
        if strategy == nil then error('Invalid LSP format strategy') end
        format_properties.set_buffer_lsp_format_strategy(strategy, bufnr)
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
        desc = 'Sets the lsp format strategy for the buffer',
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
        desc = 'Sets the formatter filetype lsp format strategy',
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
    'QFToLoc',
    function(_)
        vim.cmd(
            [[call setloclist(0, [], ' ', {'items': get(getqflist({'items': 1}), 'items')})]]
        )
    end,
    {
        desc = 'Copies QF list to Loc list',
    }
)

vim.api.nvim_create_user_command('QFToLocAdd', function(_)
    local items = vim.fn.getqflist()
    local action = 'a' -- add to existing list
    vim.fn.setloclist(0, {}, action, { items = items })
end, {
    desc = 'Appends items from QF list to end of Loc list',
})

vim.api.nvim_create_user_command(
    'LocToQF',
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
vim.api.nvim_create_user_command('QFRunTSQueryFromQueryEditor', function(params)
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
    if parser == nil then error('No treesitter parser') end
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

            local text = vim.api.nvim_buf_get_text(
                base_bufnr,
                lnum,
                col,
                end_lnum,
                end_col,
                {}
            )

            local line_text = vim.trim(vim.fn.getline(lnum + 1))

            local item = {
                filename = base_buf_name,
                lnum = lnum + 1,
                end_lnum = end_lnum + 1,
                col = col + 1,
                end_col = end_col + 1,
                text = string.format(
                    'Query:%s  Node:%s  Line:%s',
                    capture_name,
                    vim.trim(text[1]),
                    line_text
                ),
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

vim.api.nvim_create_user_command('QFRunTSQuery', function(params)
    if #params.fargs < 2 then
        vim.notify(
            'Must supply at least 2 arguments. The first must be the treesitter group. Followed a capture name or list of capture names to match on.'
        )
        return
    end
    local query_group = params.fargs[1]

    local capture_names_set = Set:new({})
    for i, capture_name in ipairs(params.fargs) do
        if i ~= 1 then
            --we skip the first argument because it is the treesitter group not a capture name
            capture_names_set:insert(capture_name)
        end
    end

    local base_bufnr = vim.api.nvim_win_get_buf(0)
    local base_buf_name = vim.api.nvim_buf_get_name(base_bufnr)

    local lang = vim.treesitter.language.get_lang(vim.bo[base_bufnr].filetype)
    local parser = vim.treesitter.get_parser(base_bufnr, lang)
    if parser == nil then error('No treesitter parser') end

    local ok_query, query = pcall(vim.treesitter.query.get, lang, query_group)
    if not ok_query or query == nil then return end

    local items = {}

    for capture, captured_node, _, _ in
        query:iter_captures(parser:trees()[1]:root(), base_bufnr)
    do
        local capture_name = query.captures[capture]
        if
            capture_names_set.size ~= 0 and capture_names_set:has(capture_name)
        then
            local lnum, col, end_lnum, end_col = captured_node:range()

            local text = vim.api.nvim_buf_get_text(
                base_bufnr,
                lnum,
                col,
                end_lnum,
                end_col,
                {}
            )
            local line_text = vim.trim(vim.fn.getline(lnum + 1))

            local item = {
                filename = base_buf_name,
                lnum = lnum + 1,
                end_lnum = end_lnum + 1,
                col = col + 1,
                end_col = end_col,
                text = string.format(
                    'Query:%s  Node:%s  Line:%s',
                    capture_name,
                    vim.trim(text[1]),
                    line_text
                ),
                valid = 1,
            }
            table.insert(items, item)
            -- TODO remove duplicates
        end
    end
    vim.fn.setqflist({}, ' ', { items = items, title = query_group })
end, {
    nargs = '+',
    complete = function(_, text, _)
        --first argument is the text of the command arg the cursor is on but only includes the text up to the cursor
        --second argumet is the text up to the cursor
        --third argument is the index of the cursor
        local words = vim.split(text, '%s+')
        -- vim.print(words)
        if #words > 2 then
            local base_bufnr = vim.api.nvim_win_get_buf(0)

            local lang =
                vim.treesitter.language.get_lang(vim.bo[base_bufnr].filetype)
            local query_group = words[2]
            local ok_query, query =
                pcall(vim.treesitter.query.get, lang, query_group)
            if not ok_query or query == nil then return end
            return query.captures
        end

        return {
            config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP,
            'textobjects',
            'folds',
            'highlights',
            'injections',
            'locals',
        }
    end,
})

vim.api.nvim_create_user_command('QFRemoveInvalid', function(_)
    local items = vim.fn.getqflist()
    items = vim.tbl_filter(function(item) return item.valid == 1 end, items)
    vim.fn.setqflist({}, ' ', { items = items })
    vim.cmd('copen')
end, {
    desc = 'Remove invalid quickfix items',
})

-------------------------------------------------------------------------------
---Treesitter

--Technically nvim-treesitter.textobjects already has commands like these but they
--don't work for treesitter queries defined outside of the plugin

--TODO
-- 1. I would like to add marks to the beginning and end so that I can have a command to move toggle between the two
-- 2. fight the urge to create a repeat command. I can just use a macro for that
-- 3. it would be nice if I had a flag to include comments when swapping

vim.api.nvim_create_user_command('TSGotoNext', function(params)
    if #params.fargs ~= 2 then
        vim.notify(
            'Must supply 2 arguments. The first must be the treesitter group. Followed a capture name to match on.'
        )
        return
    end
    local query_group = params.fargs[1]
    local capture_name = '@' .. params.fargs[2] --we prepend `@` to the beginning of the capture_name since 'nvim-treesitter.textobjects' requires it

    if params.bang then
        require('nvim-treesitter-textobjects.move').goto_next_end(
            capture_name,
            query_group
        )
    else
        require('nvim-treesitter-textobjects.move').goto_next_start(
            capture_name,
            query_group
        )
    end
end, {
    bang = true,
    nargs = '+',
    complete = function(_, text, _)
        --first argument is the text of the command arg the cursor is on but only includes the text up to the cursor
        --second argumet is the text up to the cursor
        --third argument is the index of the cursor
        local words = vim.split(text, '%s+')
        -- vim.print(words)
        if #words <= 2 then
            return {
                config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP,
                'textobjects',
                'folds',
                'highlights',
                'injections',
                'locals',
            }
        elseif #words <= 3 then
            local base_bufnr = vim.api.nvim_win_get_buf(0)

            local lang =
                vim.treesitter.language.get_lang(vim.bo[base_bufnr].filetype)
            local query_group = words[2]
            local ok_query, query =
                pcall(vim.treesitter.query.get, lang, query_group)
            if not ok_query or query == nil then return end
            return query.captures
        end
        return {}
    end,
    desc = 'Go to the treesitter capture group. The first param is the query group and the second param is the capture name. Bang puts the cursor at the end of the capture group.',
})

vim.api.nvim_create_user_command('TSGotoPrevious', function(params)
    if #params.fargs ~= 2 then
        vim.notify(
            'Must supply 2 arguments. The first must be the treesitter group. Followed a capture name to match on.'
        )
        return
    end
    local query_group = params.fargs[1]
    local capture_name = '@' .. params.fargs[2] --we prepend `@` to the beginning of the capture_name since 'nvim-treesitter-textobjects' requires it

    if params.bang then
        require('nvim-treesitter-textobjects.move').goto_previous_end(
            capture_name,
            query_group
        )
    else
        require('nvim-treesitter-textobjects.move').goto_previous_start(
            capture_name,
            query_group
        )
    end
end, {
    bang = true,
    nargs = '+',
    complete = function(_, text, _)
        --first argument is the text of the command arg the cursor is on but only includes the text up to the cursor
        --second argumet is the text up to the cursor
        --third argument is the index of the cursor
        local words = vim.split(text, '%s+')
        -- vim.print(words)
        if #words <= 2 then
            return {
                config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP,
                'textobjects',
                'folds',
                'highlights',
                'injections',
                'locals',
            }
        elseif #words <= 3 then
            local base_bufnr = vim.api.nvim_win_get_buf(0)

            local lang =
                vim.treesitter.language.get_lang(vim.bo[base_bufnr].filetype)
            local query_group = words[2]
            local ok_query, query =
                pcall(vim.treesitter.query.get, lang, query_group)
            if not ok_query or query == nil then return end
            return query.captures
        end
        return {}
    end,
    desc = 'Go to the previous treesitter capture group. The first param is the query group and the second param is the capture name. Bang puts the cursor at the end of the capture group.',
})

vim.api.nvim_create_user_command('TSSwapNext', function(params)
    if #params.fargs ~= 2 then
        vim.notify(
            'Must supply 2 arguments. The first must be the treesitter group. Followed a capture name to match on.'
        )
        return
    end
    local query_group = params.fargs[1]
    local capture_name = '@' .. params.fargs[2] --we prepend `@` to the beginning of the capture_name since 'nvim-treesitter-textobjects' requires it

    require('nvim-treesitter-textobjects.swap').swap_next(
        capture_name,
        query_group
    )
end, {
    nargs = '+',
    complete = function(_, text, _)
        --first argument is the text of the command arg the cursor is on but only includes the text up to the cursor
        --second argumet is the text up to the cursor
        --third argument is the index of the cursor
        local words = vim.split(text, '%s+')
        -- vim.print(words)
        if #words <= 2 then
            return {
                config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP,
                'textobjects',
                'folds',
                'highlights',
                'injections',
                'locals',
            }
        elseif #words <= 3 then
            local base_bufnr = vim.api.nvim_win_get_buf(0)

            local lang =
                vim.treesitter.language.get_lang(vim.bo[base_bufnr].filetype)
            local query_group = words[2]
            local ok_query, query =
                pcall(vim.treesitter.query.get, lang, query_group)
            if not ok_query or query == nil then return end
            return query.captures
        end
        return {}
    end,
    desc = 'Swap the next treesitter capture group. The first param is the query group and the second param is the capture name.',
})

vim.api.nvim_create_user_command('TSSwapPrevious', function(params)
    if #params.fargs ~= 2 then
        vim.notify(
            'Must supply 2 arguments. The first must be the treesitter group. Followed a capture name to match on.'
        )
        return
    end
    local query_group = params.fargs[1]
    local capture_name = '@' .. params.fargs[2] --we prepend `@` to the beginning of the capture_name since 'nvim-treesitter-textobjects' requires it

    require('nvim-treesitter-textobjects.swap').swap_previous(
        capture_name,
        query_group
    )
end, {
    nargs = '+',
    complete = function(_, text, _)
        --first argument is the text of the command arg the cursor is on but only includes the text up to the cursor
        --second argumet is the text up to the cursor
        --third argument is the index of the cursor
        local words = vim.split(text, '%s+')
        -- vim.print(words)
        if #words <= 2 then
            return {
                config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP,
                'textobjects',
                'folds',
                'highlights',
                'injections',
                'locals',
            }
        elseif #words <= 3 then
            local base_bufnr = vim.api.nvim_win_get_buf(0)

            local lang =
                vim.treesitter.language.get_lang(vim.bo[base_bufnr].filetype)
            local query_group = words[2]
            local ok_query, query =
                pcall(vim.treesitter.query.get, lang, query_group)
            if not ok_query or query == nil then return end
            return query.captures
        end
        return {}
    end,
    desc = 'Swap the previous treesitter capture group. The first param is the query group and the second param is the capture name.',
})

vim.api.nvim_create_user_command('TSSelect', function(params)
    if #params.fargs ~= 2 then
        vim.notify(
            'Must supply 2 arguments. The first must be the treesitter group. Followed a capture name to match on.'
        )
        return
    end
    local query_group = params.fargs[1]
    local capture_name = '@' .. params.fargs[2] --we prepend `@` to the beginning of the capture_name since 'nvim-treesitter-textobjects' requires it

    require('nvim-treesitter-textobjects.select').select_textobject(
        capture_name,
        query_group
    )
end, {
    nargs = '+',
    complete = function(_, text, _)
        --first argument is the text of the command arg the cursor is on but only includes the text up to the cursor
        --second argumet is the text up to the cursor
        --third argument is the index of the cursor
        local words = vim.split(text, '%s+')
        -- vim.print(words)
        if #words <= 2 then
            return {
                config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP,
                'textobjects',
                'folds',
                'highlights',
                'injections',
                'locals',
            }
        elseif #words <= 3 then
            local base_bufnr = vim.api.nvim_win_get_buf(0)

            local lang =
                vim.treesitter.language.get_lang(vim.bo[base_bufnr].filetype)
            local query_group = words[2]
            local ok_query, query =
                pcall(vim.treesitter.query.get, lang, query_group)
            if not ok_query or query == nil then return end
            return query.captures
        end
        return {}
    end,
    desc = 'Select treesitter capture group. The first param is the query group and the second param is the capture name.',
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
    local options =
        get_makefile_options(vim.fs.joinpath(vim.fn.getcwd(), 'Makefile'))

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

vim.api.nvim_create_user_command('WatchRun', function()
    local overseer = require('overseer')
    overseer.run_template({ name = 'run script' }, function(task)
        if task then
            task:add_component({
                'restart_on_save',
                paths = { vim.fn.expand('%:p') },
            })
            local main_win = vim.api.nvim_get_current_win()
            overseer.run_action(task, 'open vsplit')
            vim.api.nvim_set_current_win(main_win)
        else
            vim.notify(
                'WatchRun not supported for filetype ' .. vim.bo.filetype,
                vim.log.levels.ERROR
            )
        end
    end)
end, {})

vim.api.nvim_create_user_command(
    'OverseerDebugParser',
    function() require('overseer').debug_parser() end,
    {}
)

vim.api.nvim_create_user_command('OverseerRestartLast', function()
    local overseer = require('overseer')
    local tasks = overseer.list_tasks({ recent_first = true })
    if vim.tbl_isempty(tasks) then
        vim.notify('No tasks found', vim.log.levels.WARN)
    else
        overseer.run_action(tasks[1], 'restart')
    end
end, {})

--https://github.com/stevearc/dotfiles/blob/master/.config/nvim/plugin/stacktrace.lua
vim.api.nvim_create_user_command('Stacktrace', function(params)
    local selection_text = {}

    if params.range == 2 then
        local start_pos = vim.api.nvim_buf_get_mark(0, '<')
        local start_row = start_pos[1]

        local end_pos = vim.api.nvim_buf_get_mark(0, '>')
        local end_row = end_pos[1]

        if start_row ~= params.line1 or end_row ~= params.line2 then
            --Assume that a range was selected likn 1,3Stacktrace or %Stacktrace command was typed
            --For 1,3Stacktrace the first three lines are selected
            --For %Stacktrace the whole buffer should be selected
            selection_text = vim.api.nvim_buf_get_lines(
                0,
                params.line1 - 1,
                params.line2,
                true
            )
        else
            --TODO handle visual block mode selection
            --TODO there has to be a better way to determine what the range was
            --as marks other then `<` and `>` could have been used to define the range
            selection_text = require('utils.mapping').get_visual_selection(0)
        end
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
    -- Note: I want to be able to record macros inside this buffer so I don't remap q to cancel anymore
    vim.keymap.set({ 'n', 'i' }, '<C-c>', cancel, { buffer = bufnr })
    vim.keymap.set('n', '<CR>', confirm, { buffer = bufnr })
    vim.keymap.set({ 'n', 'i' }, '<C-s>', confirm, { buffer = bufnr }) -- TODO: re-evaluate this keymap since it conflicts with one of my multi-cursor keymaps
end, {
    desc = 'Parse a stacktrace using errorformat and add to quickfix',
    bang = true,
    range = true,
})

-------------------------------------------------------------------------------
--- File search/creation

vim.api.nvim_create_user_command('Grep', function(params)
    local overseer = require('overseer')
    -- insert args at the '$*' in the grepprg
    local cmd, num_subs = vim.o.grepprg:gsub('%$%*', params.args)
    if num_subs == 0 then cmd = cmd .. ' ' .. params.args end
    local task = overseer.new_task({
        cmd = vim.fn.expandcmd(cmd),
        components = {
            {
                'quickfix.my_on_output_quickfix',
                errorformat = vim.o.grepformat,
                open = not params.bang,
                open_height = 8,
                items_only = true,
            },
            -- we don't care to keep this around as long as most tasks
            { 'on_complete_dispose', timeout = 30 },
            'default',
        },
    })
    task:start()
end, { nargs = '*', bang = true, complete = 'file' })

vim.api.nvim_create_user_command('GrepAdd', function(params)
    local overseer = require('overseer')
    -- insert args at the '$*' in the grepprg
    local cmd, num_subs = vim.o.grepprg:gsub('%$%*', params.args)
    if num_subs == 0 then cmd = cmd .. ' ' .. params.args end
    local task = overseer.new_task({
        cmd = vim.fn.expandcmd(cmd),
        components = {
            {
                'quickfix.my_on_output_quickfix',
                errorformat = vim.o.grepformat,
                open = not params.bang,
                open_height = 8,
                items_only = true,
                append = true,
                tail = false, -- must set to false when append equals true because of a bug I have in my TODO list (TODO: remove `tail = false` when bug is fixed)
            },
            -- we don't care to keep this around as long as most tasks
            { 'on_complete_dispose', timeout = 30 },
            'default',
        },
    })
    task:start()
end, { nargs = '*', bang = true, complete = 'file' })

vim.api.nvim_create_user_command('Find', function(args)
    --This command is a little to simple for me to really need
    --but until I remember that I can use :args for this then
    --this is nice to have in my git history.
    local search = args.fargs[1]
    if search == nil or search:match('^%s*$') then
        error('Must provide a search glob')
    end
    local cmd = string.format([[:args %s]], search)
    vim.cmd(cmd)
end, {
    nargs = 1,
    desc = 'Find files by glob',
})

vim.api.nvim_create_user_command('CopyToSamePath', function(args)
    local filename = args.fargs[1]
    if filename == nil or filename:match('^*$') then
        error('Must provide a new filename')
    end

    local src_filepath = vim.fn.expand('%:p')
    local dir = vim.fn.fnamemodify(src_filepath, ':h')

    if dir == nil or dir:match('^%s*$') then
        error('Current buffer seems to not have a directory')
    end

    local stat = vim.loop.fs_stat(dir)
    if not stat or stat.type ~= 'directory' then
        error("Current buffer's directory does not seem to exist")
    end

    local file_path = vim.fs.joinpath(dir, filename)
    vim.cmd.saveas(file_path)
end, {
    nargs = 1,
    desc = 'Copies the file to the same folder of current buffer with then new name specified by the cmd argument',
})

-------------------------------------------------------------------------------
--- File cleanup

vim.api.nvim_create_user_command('ConvertLineEndings', function(params)
    -- vim.print(params)
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

-- based on https://vim.fandom.com/wiki/Remove_unwanted_empty_lines
vim.api.nvim_create_user_command(
    'RemoveTrailingWhitespace',
    function(_) vim.cmd([[:%s/\s\+$//e]]) end,
    {
        nargs = 0,
    }
)

-- based on https://vim.fandom.com/wiki/Remove_unwanted_empty_lines
vim.api.nvim_create_user_command(
    'CollapseDuplicateWhitespace',
    function(_) vim.cmd([[:%s/\n\{3,}/\r\r/e]]) end,
    {
        nargs = 0,
    }
)
-------------------------------------------------------------------------------
-- Define Bdelete and Bwipeout.
vim.api.nvim_create_user_command(
    'Bdelete',
    function(opts) require('config.bufdelete')._buf_kill_cmd(opts, false) end,
    {
        bang = true,
        bar = true,
        count = true,
        addr = 'buffers',
        nargs = '*',
        complete = 'buffer',
    }
)

vim.api.nvim_create_user_command(
    'Bwipeout',
    function(opts) require('config.bufdelete')._buf_kill_cmd(opts, true) end,
    {
        bang = true,
        bar = true,
        count = true,
        addr = 'buffers',
        nargs = '*',
        complete = 'buffer',
    }
)

vim.api.nvim_create_user_command(
    'BCloseAllInactive',
    function(_) require('config.bufdelete').close_inactive_file_buffers() end,
    {
        desc = 'Close all inactive unmodified file buffer',
    }
)

return M
