local config = require('myconfig.config')
local maputils = require('myconfig.utils.mapping')

vim.g.mapleader = ' '

vim.keymap.del({ 'n' }, '[d')
vim.keymap.del({ 'n' }, ']d')

vim.keymap.del({ 'n' }, '[D')
vim.keymap.del({ 'n' }, ']D')

-- Disable the "execute last macro" shortcut
vim.keymap.set(
    'n',
    'Q',
    '<nop>',
    { desc = 'Customized Remap: Remapped to <nop> to disable this keybinging' }
)

vim.keymap.set(
    -- { 'n', 'v', 'i' }, --commented because I don't like the delay on insert mode
    { 'n', 'v' },
    -- '<C-;>', -- Doesn't work on wezterm
    '<leader><leader>;',
    '<ESC><ESC>:',
    { desc = 'Custom Keymap: Go into command mode' }
)

---Finds the start and end index of a substring in another string for a given
---known index that is known to be within the matched string.
---If a match is not found around the known index then (nil, nil) will be returned
---@param s string
---@param search string
---@param known_index integer
---@return integer? start_index
---@return integer? end_index
local function string_find_for_inner_index(s, search, known_index)
    ---@type integer?
    local first = 0
    ---@type integer?
    local last = nil
    -- local first, last = 0
    while first ~= nil and first <= #s do
        first, last = s:find(search, first + 1, true)
        if
            first ~= nil
            and last ~= nil
            and first <= known_index
            and known_index <= last
        then
            return first, last
        end
    end
    return nil, nil
end

local function get_cfile()
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col('.')
    assert(col > 0)

    local cfile = vim.fn.expand('<cfile>')
    if string.sub(line, col, col) == ':' then
        col = col + 1 -- handles a bug where file names with the prefix 'C:\' will only return characters after the colon
    end
    local start_index, end_index = string_find_for_inner_index(line, cfile, col)
    -- There is a wierd bug for <cfile> where files with windows drive letters
    -- may be incorrect if the colon is followed by a single backslash if the
    -- cursor is after the colon
    -- For example:
    --C:\Users\crweb\Documents\.config\nvim\test.md --cursor after colon-> \Users\crweb\Documents\.config\nvim\test.md
    --
    if start_index == nil then return cfile, start_index, end_index end

    if
        string.len(cfile) > 0
        and string.sub(cfile, 1, 1) == '\\'
        and start_index > 2
    then
        local drive_prefix = string.sub(line, start_index - 2, start_index - 1)
        cfile = table.concat({ drive_prefix, cfile })
        start_index = start_index - 2
    end
    assert(cfile == string.sub(line, start_index, end_index))
    return cfile, start_index, end_index
end

-- local filename, filename_start_index, filename_end_index = get_cfile()
-- print(filename, filename_start_index, filename_end_index)

---@type integer?
local scratch_bufnr = nil

local function get_gf_location()
    --determine gF position
    -- 1. get current cursor and bufnr
    -- 2. do gF
    -- 3. if error is not E447 then throw
    -- 3.a if error is E447 and there are lines following current line then do "%join!
    -- 4. get current line number and filename
    -- 5. move cursor up, or down based on where there are available lines (note gF does not change the column)
    -- 6. go back cursor and bufnr in step 1
    -- 7. do gF
    -- 8. get current line number and filename
    -- 9. if filename changed between step 4 and step 8 throw an error
    -- 10: if line number from step 4 and step 8 are the same then we know gF sets the line number
    -- 11:   try to determine column number
    -- 11.a: run get_cfile
    -- 11.b if cfile is not the same as filename from step 4 then return {cfile, linenumber, nil}
    -- 11.c use vim.fn.getqflist to get column

    -- 1. get current cursor and bufnr
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)

    local lnum = vim.fn.line('.')
    local col = vim.fn.col('.')

    local trailing_count = 2
    local lines = vim.api.nvim_buf_get_lines(
        bufnr,
        lnum - 1,
        lnum + trailing_count,
        false
    )

    if scratch_bufnr == nil or not vim.api.nvim_buf_is_valid(scratch_bufnr) then
        scratch_bufnr = vim.api.nvim_create_buf(false, true)
    end

    local gf_bufnr, gf_filename, gf_line, gf_col = vim._with(
        { buf = scratch_bufnr },
        function()
            -- 2. do gF
            vim.api.nvim_buf_set_lines(scratch_bufnr, 0, 0, false, { lines[1] })
            vim.api.nvim_win_set_cursor(0, { 1, cursor[2] })
            local cfile_filename, cfile_start_index, cfile_end_index =
                get_cfile()

            local ok, err = pcall(vim.cmd.normal, { 'gF', bang = true })
            if not ok and err and err:find('E447') then
                -- 3.a if error is E447 and there are lines following current line then do "%join!
                local joined_lines = table.concat(lines, '')
                vim.api.nvim_buf_set_lines(
                    scratch_bufnr,
                    0,
                    0,
                    false,
                    { joined_lines }
                )
                vim.api.nvim_win_set_cursor(0, { 1, cursor[2] })
                cfile_filename, cfile_start_index, cfile_end_index = get_cfile()

                local ok2, err2 = pcall(vim.cmd.normal, { 'gF', bang = true })
                if not ok2 and err2 ~= nil then error(err2) end
            elseif not ok then
                -- 3. if error is not E447 then throw
                error(err or 'something went wrong')
            end

            -- We should now be at the new location if it didn't error but we will assert that just in case
            local new_bufnr = vim.api.nvim_get_current_buf()
            assert(scratch_bufnr ~= new_bufnr)
            -- 4. get current line number and filename
            local new_lnum_on_first_gf = vim.fn.line('.')
            local new_filename_on_first_gf =
                vim.api.nvim_buf_get_name(new_bufnr)

            local new_cursor_on_first_gf = vim.api.nvim_win_get_cursor(0)
            assert(new_cursor_on_first_gf[1] > 0)

            -- 5. move cursor up, or down based on where there are available lines (note gF does not change the column)
            local new_bufnr_lines =
                vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
            if new_cursor_on_first_gf[1] == 1 and #new_bufnr_lines == 2 then
                vim.api.nvim_win_set_cursor(
                    0,
                    { new_cursor_on_first_gf[1] + 1, new_cursor_on_first_gf[2] }
                )
            elseif new_cursor_on_first_gf[1] ~= 1 then
                vim.api.nvim_win_set_cursor(
                    0,
                    { new_cursor_on_first_gf[1] - 1, new_cursor_on_first_gf[2] }
                )
            end

            -- 6. go back cursor and bufnr in step 1
            vim.api.nvim_set_current_buf(bufnr)
            vim.api.nvim_win_set_cursor(0, cursor)

            -- 7. do gF
            vim.cmd.normal({ 'gF', bang = true })

            -- 8. get current line number and filename
            local new_lnum_on_second_gf = vim.fn.line('.')
            local new_filename_on_second_gf =
                vim.api.nvim_buf_get_name(new_bufnr)
            local new_cursor_on_second_gf = vim.api.nvim_win_get_cursor(0)

            -- 9. if filename changed between step 4 and step 8 throw an error
            assert(new_filename_on_first_gf == new_filename_on_second_gf)

            -- 10: if line number from step 4 and step 8 are the same then we know gF sets the line number
            local ret_lnum = new_lnum_on_first_gf
            if new_lnum_on_second_gf ~= new_lnum_on_first_gf then
                ret_lnum = nil
                -- return new_bufnr, new_filename_on_first_gf, nil, nil
            end

            -- 11.a: run get_cfile
            -- local cfile_filename, cfile_start_index, cfile_end_index =
            --     get_cfile()

            -- 11.b if cfile is not the same as filename from step 4 then return {cfile, linenumber, nil}
            if
                vim.fs.normalize(cfile_filename)
                ~= vim.fs.normalize(new_filename_on_first_gf)
            then
                return new_bufnr,
                    new_filename_on_first_gf,
                    new_lnum_on_first_gf,
                    nil
            end

            -- 11.c use vim.fn.getqflist to get column
            local lines_to_find_column_for =
                vim.api.nvim_buf_get_lines(scratch_bufnr, 0, 1, false)
            local items = vim.fn.getqflist({
                lines = lines_to_find_column_for,
            }).items
            local ret_col = nil
            local ret_bufnr = new_bufnr
            if #items > 0 then
                -- {
                --   bufnr = 24,
                --   col = 0,
                --   end_col = 0,
                --   end_lnum = 0,
                --   lnum = 34,
                --   module = "",
                --   nr = -1,
                --   pattern = "",
                --   text = "",
                --   type = "",
                --   valid = 1,
                --   vcol = 0
                -- }
                -- Note: errorformat might incorrectly extract the filename
                -- so we won't use the bufnr returned by getqflist since it is often
                -- garbage in stack traces

                -- ret_bufnr = items[1].bufnr
                ret_lnum = items[1].lnum
                ret_col = items[1].col
            end

            return ret_bufnr, new_filename_on_first_gf, ret_lnum, ret_col
        end
    )

    return gf_bufnr, gf_filename, gf_line, gf_col
end

local function smart_open_buf(dest_bufnr, callback)
    local current_bufnr = vim.api.nvim_get_current_buf()
    local current_winid = vim.api.nvim_get_current_win()
    local current_tabid = vim.api.nvim_get_current_tabpage()
    -- We don't need to do anything if we swap to the same buffer
    if dest_bufnr == current_bufnr then
        callback()
        return
    end

    -- Find another window to swap to
    local dest_winid ---@type number?
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(current_tabid)) do
        local win_bufnr = vim.api.nvim_win_get_buf(winid)
        local is_float = vim.api.nvim_win_get_config(winid).zindex ~= nil
        if win_bufnr == dest_bufnr and winid ~= current_winid then
            dest_winid = winid
            break
        elseif
            dest_winid == nil
            and winid ~= current_winid
            and vim.api.nvim_win_is_valid(winid)
            and not is_float
            and vim.bo[win_bufnr].buftype == ''
        then
            dest_winid = winid
        end
    end

    if dest_winid == nil and vim.bo[current_bufnr].buftype == '' then
        dest_winid = current_winid
    end
    if dest_winid ~= nil then
        vim.api.nvim_win_set_buf(current_winid, current_bufnr)
        vim.api.nvim_win_set_buf(dest_winid, dest_bufnr)
        vim.api.nvim_set_current_win(dest_winid)
        vim.cmd.stopinsert()
    else
        vim.api.nvim_win_call(current_winid, function()
            vim.cmd.stopinsert()

            local win_config = {
                split = 'above',
                win = -1,
            }

            local position = 'bottom'

            local terminal_manager =
                require('myconfig.terminal.terminal').get_terminal_manager_by_bufnr(
                    current_bufnr
                )

            if terminal_manager ~= nil then
                local window_manager = terminal_manager:get_window_manager()
                if window_manager and window_manager.position == 'float' then
                    position = window_manager.position
                end
            end

            if position == 'top' then
                win_config.split = 'below'
            elseif position == 'right' then
                win_config.split = 'left'
            elseif position == 'bottom' then
                win_config.split = 'above'
            elseif position == 'left' then
                win_config.split = 'right'
            end

            vim.api.nvim_open_win(dest_bufnr, true, win_config)

            vim.api.nvim_win_set_buf(current_winid, current_bufnr)
        end)
    end
    callback()
end

if config.use_experimental_gf then
    vim.keymap.set('n', 'gf', function()
        local bufnr, filename, lnum, col = get_gf_location()
        print(bufnr, filename, lnum, col)
        smart_open_buf(bufnr, function()
            vim.api.nvim_win_set_buf(0, bufnr)
            local cursor = vim.api.nvim_win_get_cursor(0)
            if lnum ~= nil then cursor[1] = lnum end
            if col ~= nil then cursor[2] = col end
            vim.api.nvim_win_set_cursor(0, cursor)

            local terminal_manager =
                require('myconfig.terminal.terminal').get_terminal_manager_by_bufnr(
                    bufnr
                )

            if terminal_manager ~= nil then
                local window_manager = terminal_manager:get_window_manager()
                if window_manager and window_manager.position == 'float' then
                    terminal_manager:hide()
                end
            end
        end)
    end, {
        desc = 'Custom Remap: Go to file or open telescope picker at parent folder',
    })

    --
    -- vim.keymap.set('n', 'gf', function()
    --     local previous_winfixbuf = vim.wo.winfixbuf
    --     if vim.bo.buftype == 'terminal' then vim.wo.winfixbuf = true end
    --
    --     local ok, err = pcall(vim.cmd.normal, { 'gf', bang = true })
    --
    --     if vim.bo.buftype == 'terminal' then
    --         vim.wo.winfixbuf = previous_winfixbuf
    --     end
    --
    --     if ok then
    --         local terminal_manager =
    --             require('myconfig.terminal.terminal').get_terminal_manager_by_bufnr(
    --                 vim.api.nvim_get_current_buf()
    --             )
    --
    --         if terminal_manager ~= nil then
    --             local window_manager = terminal_manager:get_window_manager()
    --             if window_manager and window_manager.position == 'float' then
    --                 terminal_manager:hide()
    --             end
    --         end
    --     elseif err and err:find('E447') then
    --         vim.notify(err)
    --     else
    --         error(err, 1)
    --     end
    --
    --     -- if terminal_manager == nil then return end
    -- end, {
    --     desc = 'Custom Remap: Go to file or open telescope picker at parent folder',
    -- })
    -- local function get_item_at_cursor()
    --     local bufnr = vim.api.nvim_get_current_buf()
    --     local lnum = vim.fn.line('.')
    --     local col = vim.fn.col('.')
    --
    --     -- retrict this to just 8 lines above and below the cursor
    --     local leading_count = 2
    --     local trailing_count = 2
    --     local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum, true)
    --     local leading_lines = vim.api.nvim_buf_get_lines(
    --         bufnr,
    --         lnum - leading_count + 1,
    --         lnum - 1,
    --         true
    --     )
    --     local trailing_lines = vim.api.nvim_buf_get_lines(
    --         bufnr,
    --         lnum + 1,
    --         lnum + trailing_count + 1,
    --         true
    --     )
    --
    --     local line = vim.api.nvim_get_current_line()
    --     -- local modified_lines = {}
    --     -- local cursor_column_offset_per_modified_line = {}
    --
    --     -- { {
    --     --     bufnr = 199,
    --     --     col = 0,
    --     --     end_col = 0,
    --     --     end_lnum = 0,
    --     --     lnum = 34,
    --     --     module = "",
    --     --     nr = -1,
    --     --     pattern = "",
    --     --     text = "",
    --     --     type = "",
    --     --     valid = 1,
    --     --     vcol = 0
    --     --   } }
    --     -- local items = vim.fn.getqflist({
    --     --     lines = {
    --     --         [[C:\Users\crweb\Documents\poc\hello-world-dotnet-console\HelloWorldTestNunit\UnitTest1.cs:line 34]],
    --     --     },
    --     -- }).items
    --     --
    --
    --     -- local items = vim.fn.getqflist({ lines = { [[C:\Users\crweb\Documents\poc\hello-world-dotnet-console\HelloWorldTestNunit\UnitTest1.cs:line 32 C:\Users\crweb\Documents\poc\hello-world-dotnet-console\HelloWorldTestNunit\UnitTest1.cs:line 34]], }, }).items
    --
    --     -- since errorformat finds first match on a line we need to find start of cfile
    --     -- then search towards left for first whitespace or qoute and strip the text
    --
    --     local items = vim.fn.getqflist({ lines = { line } }).items
    --     lnum = 1
    --     for i, item in ipairs(items) do
    --         local lnum_matches = (item.lnum == lnum and item.end_lnum == nil)
    --             or (item.lnum <= lnum and lnum <= item.end_lnum)
    --         local col_matches = (
    --             (item.col == col and item.end_col == nil)
    --             or (item.col <= col and col <= item.end_col)
    --         )
    --         if lnum_matches and col_matches then return items[i] end
    --     end
    --
    --     --TODO if the item is not found we will concat lines with and without trimming whitespace till we get a match
    --     for i, item in ipairs(items) do
    --         local lnum_matches = (item.lnum == lnum and item.end_lnum == nil)
    --             or (item.lnum <= lnum and lnum <= item.end_lnum)
    --         local col_matches = (
    --             (item.col == col and item.end_col == nil)
    --             or (item.col <= col and col <= item.end_col)
    --         )
    --         if lnum_matches and col_matches then return items[i] end
    --     end
    --     return nil
    -- end
    --
    -- vim.keymap.set('n', 'gF', function()
    --     local prev_bufnr = vim.api.nvim_get_current_buf()
    --     local prev_win = vim.api.nvim_get_current_win()
    --     local item = get_item_at_cursor()
    --
    --     -- local ok, err = pcall(vim.cmd.normal, { 'gF', bang = true })
    --
    --     local new_bufnr = vim.api.nvim_get_current_buf()
    --     if prev_bufnr ~= new_bufnr and vim.bo[prev_bufnr].buftype == 'terminal' then
    --         vim.api.nvim_win_set_buf(prev_win, prev_bufnr)
    --     end
    --
    --     if ok then
    --         local terminal_manager =
    --             require('myconfig.terminal.terminal').get_terminal_manager_by_bufnr(
    --                 vim.api.nvim_get_current_buf()
    --             )
    --
    --         if terminal_manager ~= nil then
    --             local window_manager = terminal_manager:get_window_manager()
    --             if window_manager and window_manager.position == 'float' then
    --                 terminal_manager:hide()
    --             end
    --         end
    --     elseif err and err:find('E447') then
    --         vim.notify(err)
    --     else
    --         error(err, 1)
    --     end
    --
    --     -- if terminal_manager == nil then return end
    -- end, {
    --     desc = 'Custom Remap: Go to file or open telescope picker at parent folder',
    -- })
end

-------------------------------------------------------------------------------
---LSP keymaps
require('myconfig.lsp.keymaps').setup_lsp_keymaps()

local function do_open(uri, open_func)
    local cmd, err = open_func(uri)
    local rv = cmd and cmd:wait(1000) or nil
    if cmd and rv and rv.code ~= 0 then
        err = ('vim.ui.open: command %s (%d): %s'):format(
            (rv.code == 124 and 'timeout' or 'failed'),
            rv.code,
            vim.inspect(cmd.cmd)
        )
    end
    return err
end

vim.keymap.set({ 'n' }, 'gx', function()
    local link_uri = require('myconfig.lsp.lsplinks').get_link_at_cursor()
    if link_uri ~= nil then
        local err = do_open(link_uri, require('myconfig.lsp.lsplinks').open)
        if err then vim.notify(err, vim.log.levels.ERROR) end
    end
    for _, url in ipairs(require('vim.ui')._get_urls()) do
        local err = do_open(url, vim.ui.open)
        if err then vim.notify(err, vim.log.levels.ERROR) end
    end
end, {
    desc = 'Custom Remap: Open lsp links if exists. Otherwise, fallback to default neovim functionality for open link',
})

-------------------------------------------------------------------------------
---Completion

local function pumvisible() return tonumber(vim.fn.pumvisible()) ~= 0 end

local function is_completion_menu_visible() return pumvisible() end

local function is_entry_active()
    return pumvisible() and vim.fn.complete_info({ 'selected' }).selected >= 0
end

local function confirm_entry(replace)
    --TODO replicate cmps replace functionality when replace is true
    return '<C-y>'
end

-- Keymap notes from :help ins-completion
-- |i_CTRL-X_CTRL-D|	CTRL-X CTRL-D	complete defined identifiers
-- |i_CTRL-X_CTRL-E|	CTRL-X CTRL-E	scroll up
-- |i_CTRL-X_CTRL-F|	CTRL-X CTRL-F	complete file names
-- |i_CTRL-X_CTRL-I|	CTRL-X CTRL-I	complete identifiers
-- |i_CTRL-X_CTRL-K|	CTRL-X CTRL-K	complete identifiers from dictionary
-- |i_CTRL-X_CTRL-L|	CTRL-X CTRL-L	complete whole lines
-- |i_CTRL-X_CTRL-N|	CTRL-X CTRL-N	next completion
-- |i_CTRL-X_CTRL-O|	CTRL-X CTRL-O	omni completion
-- |i_CTRL-X_CTRL-P|	CTRL-X CTRL-P	previous completion
-- |i_CTRL-X_CTRL-R|	CTRL-X CTRL-R	complete contents from registers
-- |i_CTRL-X_CTRL-S|	CTRL-X CTRL-S	spelling suggestions
-- |i_CTRL-X_CTRL-T|	CTRL-X CTRL-T	complete identifiers from thesaurus
-- |i_CTRL-X_CTRL-Y|	CTRL-X CTRL-Y	scroll down
-- |i_CTRL-X_CTRL-U|	CTRL-X CTRL-U	complete with 'completefunc'
-- |i_CTRL-X_CTRL-V|	CTRL-X CTRL-V	complete like in : command line
-- |i_CTRL-X_CTRL-Z|	CTRL-X CTRL-Z	stop completion, keeping the text as-is
-- |i_CTRL-X_CTRL-]|	CTRL-X CTRL-]	complete tags
-- |i_CTRL-X_s|		CTRL-X s	spelling suggestions
--
-- commands in completion mode (see |popupmenu-keys|)
--
-- |complete_CTRL-E| CTRL-E	stop completion and go back to original text
-- |complete_CTRL-Y| CTRL-Y	accept selected match and stop completion
--         CTRL-L		insert one character from the current match
--         <CR>		insert currently selected match
--         <BS>		delete one character and redo search
--         CTRL-H		same as <BS>
--         <Up>		select the previous match
--         <Down>		select the next match
--         <PageUp>	select a match several entries back
--         <PageDown>	select a match several entries forward
--         other		stop completion and insert the typed character
--

vim.keymap.set({ 'i' }, '<UP>', function()
    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    --where I could record a macro just fine but replaying it would skip the
    --keymap that feedkeys was supposed to call
    --If i find I need to change back to using feedkeys refer to
    --https://www.reddit.com/r/neovim/comments/1o1hx82/comment/nigq6jm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
    --for information about which mode to use

    --TODO evaluated if this keymap should have macro specific logic
    return '<UP>'
end, {
    desc = 'Custom Remap: Select previous completion item',
    expr = true,
})

vim.keymap.set('i', '<DOWN>', function()
    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    --where I could record a macro just fine but replaying it would skip the
    --keymap that feedkeys was supposed to call
    --If i find I need to change back to using feedkeys refer to
    --https://www.reddit.com/r/neovim/comments/1o1hx82/comment/nigq6jm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
    --for information about which mode to use

    --TODO evaluated if this keymap should have macro specific logic

    return '<DOWN>'
end, {
    desc = 'Custom Remap: Select next completion item',
    expr = true,
})

vim.keymap.set({ 'i', 's' }, '<C-p>', function()
    --TODO the following commented version of this keymap keymap doesn't work
    --in `ic` mode because <C-p> and <C-n> are hardcoded
    --in the vim C code and cannot be remapped until issue https://github.com/vim/vim/issues/16880
    --is resolved as a result I can't have my snippet logic work since 90% of the
    --the completion mode is `ic` which won't call this keymap
    --
    -- local luasnip = require('luasnip')
    -- if is_entry_active() then
    --     vim.api.nvim_feedkeys(
    --         vim.api.nvim_replace_termcodes('<C-p>', true, false, true),
    --         'n', --Note probably not the best mode
    --         true
    --     )
    -- elseif luasnip.jumpable(-1) then
    --     luasnip.jump(-1)
    -- elseif vim.snippet.active({ direction = -1 }) then
    --     vim.snippet.jump(-1)
    -- elseif require('myconfig.config').use_native_completion then
    --     vim.api.nvim_feedkeys(
    --         vim.api.nvim_replace_termcodes('<C-p>', true, false, true),
    --         'n', --Note probably not the best mode
    --         true
    --     )
    -- else
    --     local select_prev = require('cmp').mapping.select_prev_item({
    --         behavior = 'select',
    --     })
    --     select_prev(function() end)
    -- end

    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    --where I could record a macro just fine but replaying it would skip the
    --keymap that feedkeys was supposed to call
    --If i find I need to change back to using feedkeys refer to
    --https://www.reddit.com/r/neovim/comments/1o1hx82/comment/nigq6jm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
    --for information about which mode to use

    --TODO evaluated if this keymap should have macro specific logic

    return '<C-p>'
end, {
    -- desc = 'Custom Remap: Jump to previous snippet location or fallback to previous completion item',
    desc = 'Custom Remap: Jump to previous completion item',
    expr = true,
})

vim.keymap.set({ 'i', 's' }, '<C-n>', function()
    --TODO the following commented version of this keymap keymap doesn't work
    --in `ic` mode because <C-p> and <C-n> are hardcoded
    --in the vim C code and cannot be remapped until issue https://github.com/vim/vim/issues/16880
    --is resolved as a result I can't have my snippet logic work since 90% of the
    --the completion mode is `ic` which won't call this keymap
    --
    -- local luasnip = require('luasnip')
    -- if is_entry_active() then
    --     vim.api.nvim_feedkeys(
    --         vim.api.nvim_replace_termcodes('<C-n>', true, false, true),
    --         'n', --Note probably not the best mode
    --         true
    --     )
    -- elseif luasnip.expand_or_jumpable() then
    --     luasnip.expand_or_jump()
    -- elseif vim.snippet.active({ direction = 1 }) then
    --     vim.snippet.jump(1)
    -- elseif require('myconfig.config').use_native_completion then
    --     vim.api.nvim_feedkeys(
    --         vim.api.nvim_replace_termcodes('<C-n>', true, false, true),
    --         'n', --Note probably not the best mode
    --         true
    --     )
    -- else
    --     local select_next = require('cmp').mapping.select_next_item({
    --         behavior = 'select',
    --     })
    --     select_next(function() end)
    -- end

    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    --where I could record a macro just fine but replaying it would skip the
    --keymap that feedkeys was supposed to call
    --If i find I need to change back to using feedkeys refer to
    --https://www.reddit.com/r/neovim/comments/1o1hx82/comment/nigq6jm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
    --for information about which mode to use

    --TODO evaluated if this keymap should have macro specific logic

    return '<C-n>'
end, {
    -- desc = 'Custom Remap: Jump to next snippet location or fallback to next completion item',
    desc = 'Custom Remap: Jump to next completion item',
    expr = true,
})

vim.keymap.set({ 'i', 's' }, '<C-h>', function()
    local luasnip = require('luasnip')
    if luasnip.jumpable(-1) then
        luasnip.jump(-1)
    elseif vim.snippet.active({ direction = -1 }) then
        vim.snippet.jump(-1)
    end
end, {
    desc = 'Custom: Jump to previous snippet location',
})

vim.keymap.set({ 'i', 's' }, '<C-l>', function()
    local luasnip = require('luasnip')
    if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
    elseif vim.snippet.active({ direction = 1 }) then
        vim.snippet.jump(1)
    end
end, {
    desc = 'Custom: Jump to next snippet location',
})

vim.keymap.set('i', '<CR>', function()
    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    --where I could record a macro just fine but replaying it would skip the
    --keymap that feedkeys was supposed to call
    --If i find I need to change back to using feedkeys refer to
    --https://www.reddit.com/r/neovim/comments/1o1hx82/comment/nigq6jm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
    --for information about which mode to use
    if is_entry_active() then
        ---setting the undolevels creates a new undo break
        ---so by setting it to itself I can create an undo break
        ---without side effects just before a comfirming a completion.
        -- Use <c-u> in insert mode to undo the completion
        vim.cmd([[let &g:undolevels = &g:undolevels]])
        return confirm_entry()
    else
        return '<CR>'
        -- 						*i_CTRL-M* *i_<CR>*
        -- <CR> or CTRL-M	Begin new line.
    end
end, {
    desc = 'Custom Remap: Select active completion item or fallback',
    expr = true,
})

vim.keymap.set('i', '<C-y>', function()
    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    if is_entry_active() then
        ---setting the undolevels creates a new undo break
        ---so by setting it to itself I can create an undo break
        ---without side effects just before a comfirming a completion.
        -- Use <c-u> in insert mode to undo the completion
        vim.cmd([[let &g:undolevels = &g:undolevels]])
        return confirm_entry(true)
    else
        return '<C-y>' -- Fallback to default keymap
        -- 						*i_CTRL-Y*
        -- CTRL-Y		Insert the character which is above the cursor.
        -- 		Note that for CTRL-E and CTRL-Y 'textwidth' is not used, to be
        -- 		able to copy characters from a long line.
    end
end, {
    desc = 'Custom Remap: Select active completion item or fallback',
    expr = true,
})

vim.keymap.set('i', '<C-e>', function()
    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    --where I could record a macro just fine but replaying it would skip the
    --keymap that feedkeys was supposed to call
    --If i find I need to change back to using feedkeys refer to
    --https://www.reddit.com/r/neovim/comments/1o1hx82/comment/nigq6jm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
    --for information about which mode to use

    --TODO evaluated if this keymap should have macro specific logic

    if is_completion_menu_visible() then
        --Close completion menu
        require('myconfig.lsp.completion.completion_state').completion_auto_trigger_enabled =
            false
        if pumvisible() then
            return '<C-e>' --Close completion menu
        else
            return '<C-e>' --Close completion menu
        end
    else
        require('myconfig.lsp.completion.completion_state').completion_auto_trigger_enabled =
            true

        if vim.bo.omnifunc == '' then
            return '<C-x><C-n>' --Triggers buffer completion
        else
            -- vim.lsp.completion.get()
            return '<C-x><C-o>' --Triggers vim.bo.omnifunc which is normally lsp completion
        end
    end
end, {
    desc = 'Custom Remap: Toggle completion window',
    expr = true,
})

vim.keymap.set({ 'i', 's' }, '<C-u>', function()
    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    --where I could record a macro just fine but replaying it would skip the
    --keymap that feedkeys was supposed to call
    --If i find I need to change back to using feedkeys refer to
    --https://www.reddit.com/r/neovim/comments/1o1hx82/comment/nigq6jm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
    --for information about which mode to use

    --TODO evaluated if this keymap should have macro specific logic
    local docs = require('myconfig.lsp.completion.documentation')
    if docs.is_docs_visible() then
        docs.scroll_docs(-4)
        return ''
    else
        return '<C-u>' -- Fallback to default keymap that deletes text to the left
        -- 						*i_CTRL-U*
        -- CTRL-U		Delete all entered characters before the cursor in the current
        -- 		line.  If there are no newly entered characters and
        -- 		'backspace' is not empty, delete all characters before the
        -- 		cursor in the current line.
        -- 		If C-indenting is enabled the indent will be adjusted if the
        -- 		line becomes blank.
        -- 		See |i_backspacing| about joining lines.
        -- 						*i_CTRL-U-default*
        -- 		By default, sets a new undo point before deleting.
        -- 		|default-mappings|
    end
end, {
    desc = 'Custom Remap: Scroll up documentation window or fallback',
    expr = true,
})

vim.keymap.set({ 'i', 's' }, '<C-d>', function()
    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    --where I could record a macro just fine but replaying it would skip the
    --keymap that feedkeys was supposed to call
    --If i find I need to change back to using feedkeys refer to
    --https://www.reddit.com/r/neovim/comments/1o1hx82/comment/nigq6jm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
    --for information about which mode to use

    --TODO evaluated if this keymap should have macro specific logic

    local docs = require('myconfig.lsp.completion.documentation')
    if docs.is_docs_visible() then
        docs.scroll_docs(4)
        return ''
    else
        return '<C-d>' -- Default to default keymap of deleting text to the right
        -- 						*i_CTRL-D*
        -- CTRL-D		Delete one shiftwidth of indent at the start of the current
        -- 		line.  The indent is always rounded to a 'shiftwidth'.
    end
end, {
    desc = 'Custom Remap: Scroll down documentation window when visiblie or fallback',
    expr = true,
})

vim.keymap.set({ 'i', 's' }, '<C-t>', function()
    local is_hidden =
        require('myconfig.lsp.completion.documentation').is_documentation_disabled()
    require('myconfig.lsp.completion.documentation').hide_docs(not is_hidden)
end, {
    desc = 'Custom Remap: Toggle the completion docs',
    --This replaces the keymap that adds one indent to the beginning of the line
})

-------------------------------------------------------------------------------
--- Command completion

vim.keymap.set('c', '<Tab>', '<C-n>', {
    desc = 'Custom Ex completion: Select next item',
})

vim.keymap.set('c', '<Left>', function()
    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    --where I could record a macro just fine but replaying it would skip the
    --keymap that feedkeys was supposed to call
    --If i find I need to change back to using feedkeys refer to
    --https://www.reddit.com/r/neovim/comments/1o1hx82/comment/nigq6jm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
    --for information about which mode to use

    --TODO evaluated if this keymap should have macro specific logic

    -- wild trigger seems to work but if it doesn't the reddit post
    -- https://www.reddit.com/r/neovim/comments/1nh3dnx/commandline_completion_as_you_type/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
    -- explains the work around of using nvim_feedkeys on <C-Z> to open it. I found
    -- that calling nvim_feedkeys on <C-Z> causes issues for typing user command arguments
    -- when the usercommand doesn't define a completion function
    vim.schedule(function()
        vim.fn.wildtrigger() -- open the wildmenu
    end)
    return '<Space><BS><Left>'
end, {
    desc = 'Custom remap Ex completion: Move cursor left',
    expr = true,
})

vim.keymap.set('c', '<Right>', function()
    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    --where I could record a macro just fine but replaying it would skip the
    --keymap that feedkeys was supposed to call
    --If i find I need to change back to using feedkeys refer to
    --https://www.reddit.com/r/neovim/comments/1o1hx82/comment/nigq6jm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
    --for information about which mode to use

    --TODO evaluated if this keymap should have macro specific logic

    -- Also wild trigger seems to work but if it doesn't the reddit post
    -- https://www.reddit.com/r/neovim/comments/1nh3dnx/commandline_completion_as_you_type/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
    -- explains the work around of using nvim_feedkeys on <C-Z> to open it. I found
    -- that calling nvim_feedkeys on <C-Z> causes issues for typing user command arguments
    -- when the usercommand doesn't define a completion function
    vim.schedule(function()
        vim.fn.wildtrigger() -- open the wildmenu
    end)
    return '<Space><BS><Right>'
end, {
    desc = 'Custom remap Ex completion: Move cursor right',
    expr = true,
})

vim.keymap.set('c', '<BS>', function()
    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    --where I could record a macro just fine but replaying it would skip the
    --keymap that feedkeys was supposed to call
    --If i find I need to change back to using feedkeys refer to
    --https://www.reddit.com/r/neovim/comments/1o1hx82/comment/nigq6jm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
    --for information about which mode to use

    --TODO evaluated if this keymap should have macro specific logic

    -- Also wild trigger seems to work but if it doesn't the reddit post
    -- https://www.reddit.com/r/neovim/comments/1nh3dnx/commandline_completion_as_you_type/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
    -- explains the work around of using feedkeys on <C-Z> to open it. I found
    -- that calling feedkeys on <C-Z> causes issues for typing user command arguments
    -- when the usercommand doesn't define a completion function
    vim.schedule(function()
        vim.fn.wildtrigger() -- open the wildmenu
    end)
    return '<BS>'
end, {
    desc = 'Custom remap Ex completion: Backspace but also keep completion menu open',
    expr = true,
})

vim.keymap.set('c', '<Space>', function()
    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    --where I could record a macro just fine but replaying it would skip the
    --keymap that feedkeys was supposed to call
    --If i find I need to change back to using feedkeys refer to
    --https://www.reddit.com/r/neovim/comments/1o1hx82/comment/nigq6jm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
    --for information about which mode to use

    --TODO evaluated if this keymap should have macro specific logic

    vim.schedule(function()
        vim.fn.wildtrigger() -- open the wildmenu
    end)
    return '<Space>'
end, {
    desc = 'Custom remap Ex completion: Space but also keep completion menu open',
    expr = true,
})

vim.keymap.set('c', '<C-e>', function()
    --I switched from vim.api.nvim_feedkeys to an expr keymap to fix issues with macros
    --where I could record a macro just fine but replaying it would skip the
    --keymap that feedkeys was supposed to call
    --If i find I need to change back to using feedkeys refer to
    --https://www.reddit.com/r/neovim/comments/1o1hx82/comment/nigq6jm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
    --for information about which mode to use

    --TODO evaluated if this keymap should have macro specific logic

    local is_wild_menu_open = vim.fn.wildmenumode() == 1
    -- '<C-e>' clears completionion text (basically an undo)
    -- Note: I can't use vim.fn.wildtrigger() after <C-e> it just doesn't open
    -- the completion menu I'm not sure if it's a bug but we just have to live
    -- using the <C-Z> instead and all its quirks
    if is_wild_menu_open then
        --Clear selected completion item with <C-e> and then reopen the wild menu
        --with <C-Z>. We only reopen if it was already open since <C-Z> will
        --enter ^Z into the commandline if there
        --is no completion items
        return '<C-e><C-Z>'
    else
        return '<C-e>'
    end
end, {
    desc = 'Custom remap Ex completion: Clears completion selection',
    expr = true,
})

-------------------------------------------------------------------------------
---Terminal keymaps
---

vim.keymap.set('n', '<leader>tt', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        start_insert = true,
        auto_insert = false,
        auto_close = false,
        namespace = 'normal_group',
    })
end, { desc = 'Custom: Toggle Terminal' })

vim.keymap.set('n', '<leader>tjh', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        start_insert = true,
        auto_insert = false,
        auto_close = false,
        namespace = 'normal_group',
        position = 'left',
    })
end, { desc = 'Custom: Toggle Terminal Left' })

vim.keymap.set('n', '<leader>tjj', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        start_insert = true,
        auto_insert = false,
        auto_close = false,
        namespace = 'normal_group',
        position = 'bottom',
    })
end, { desc = 'Custom: Toggle Terminal Bottom' })

vim.keymap.set('n', '<leader>tjk', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        start_insert = true,
        auto_insert = false,
        auto_close = false,
        namespace = 'normal_group',
        position = 'top',
    })
end, { desc = 'Custom: Toggle Terminal Top' })

vim.keymap.set('n', '<leader>tjl', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        start_insert = true,
        auto_insert = false,
        auto_close = false,
        namespace = 'normal_group',
        position = 'right',
    })
end, { desc = 'Custom: Toggle Terminal Right' })

vim.keymap.set('n', '<leader>tjf', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        start_insert = true,
        auto_close = false,
        interactive = true,
        namespace = 'normal_group',
        position = 'float',
    })
end, { desc = 'Custom: Toggle Floating Terminal' })

vim.keymap.set('n', '<leader>gs', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        cmd = 'lazygit',
        start_insert = true,
        auto_insert = false,
        auto_close = false,
        position = 'float',
        tui_mode = true,
    })
end, { desc = 'Custom: Toggle LazyGit' })

-------------------------------------------------------------------------------

--Granular undo while in insert mode
vim.keymap.set(
    'i',
    ',',
    ',<C-g>U',
    { desc = 'Creates an undo point when the character is typed' }
)
vim.keymap.set(
    'i',
    '.',
    '.<C-g>U',
    { desc = 'Creates an undo point when the character is typed' }
)
vim.keymap.set(
    'i',
    '!',
    '!<C-g>U',
    { desc = 'Creates an undo point when the character is typed' }
)
vim.keymap.set(
    'i',
    '?',
    '?<C-g>U',
    { desc = 'Creates an undo point when the character is typed' }
)

-- Clipboard --
-- Now the '+' register will copy to system clipboard using OSC52
vim.keymap.set(
    --I think this is a case where I want 'v' and not 'x' mode
    { 'v', 'n' },
    '<leader>y',
    [["+y]],
    { desc = 'Custom Clipboard: Copy to system clipboard' }
)

-- don't override paste buffer with the replaced text
-- when pasting over text
vim.keymap.set(
    'x',
    '<leader>p',
    [["_dP]],
    { desc = 'Custom Clipboard: Paste without overriding paste buffer' }
)

-- Delete to the void register
vim.keymap.set(
    --I think this is a case where I want 'v' and not 'x' mode
    { 'v', 'n' },
    '<leader>d',
    [["_d]],
    { desc = 'Custom Clipboard: Delete to the void register' }
)

-- Other --
-- Select the last changed text or the text that was just pasted (does not work for multilined spaces)
vim.keymap.set('n', 'gp', '`[v`]', {
    desc = 'Custom Clipboard: Select  last changed or pasted text (limited to a single paragraph)',
})

-- Remap key to enter visual block mode so it doesn't interfere with pasting shortcut
vim.keymap.set(
    { 'n', 'v' },
    '<A-v>',
    '<C-V>',
    { desc = 'Custom: Enter visual block mode' }
)

-- Move highlighted lines up and down
vim.keymap.set(
    'v',
    'J',
    ":m '>+1<CR>gv=gv",
    { desc = 'Custom: Move highlighted lines up' }
)
vim.keymap.set(
    'v',
    'K',
    ":m '<-2<CR>gv=gv",
    { desc = 'Custom: Move highlighted lines down' }
)

-- Move next line to the end of the current line
-- but without moving the cursor to the end of the line
vim.keymap.set(
    'n',
    'J',
    function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.cmd('join' .. vim.v.count1)
        vim.api.nvim_win_set_cursor(0, cursor)
    end,
    -- 'mzJ`z',
    {
        desc = 'Customized Remap: Move next line to end of current line without moving cursor',
    }
)

-- Page down or up but keep cursor in the middle of the page
vim.keymap.set('n', '<C-d>', '<C-d>zz', {
    desc = 'Customized Remap: Page down and move cursor to the middle of the page',
})
vim.keymap.set('n', '<C-u>', '<C-u>zz', {
    desc = 'Customized Remap: Page up and move cursor to the middle of the page',
})

-- Go to next/previous search term
-- but keep cursor in the middle of page
vim.keymap.set('n', 'n', 'nzzzv', {
    desc = 'Customized Remap: Go to next search term and move cursor to middle of the page',
})
vim.keymap.set('n', 'N', 'Nzzzv', {
    desc = 'Customized Remap: Go to previous search term and move cursor to middle of the page',
})

-- Quick fix navigation
vim.keymap.set(
    'n',
    '<C-j>',
    function() require('myconfig.utils.mapping').smart_nav('cnext') end,
    { desc = 'Custom - Quick Fix List: cnext quick fix navigation' }
)
vim.keymap.set(
    'n',
    '<C-k>',
    function() require('myconfig.utils.mapping').smart_nav('cprev') end,
    { desc = 'Custom - Quick Fix List: cprev quick fix navigation' }
)

vim.keymap.set('n', '<leader>qt', function()
    local qf_exists = false
    local tabid = vim.api.nvim_get_current_tabpage()
    local tabnr = vim.api.nvim_tabpage_get_number(tabid)
    for _, win in pairs(vim.fn.getwininfo()) do
        if win.quickfix == 1 and win.loclist == 0 and win.tabnr == tabnr then
            qf_exists = true
        end
    end
    if qf_exists == true then
        vim.cmd('cclose')
        return
    end
    if not vim.tbl_isempty(vim.fn.getqflist()) then vim.cmd('copen') end
end, { desc = 'Custom - Quick Fix List: toggle' })

-- Find and replace word cursor is on
vim.keymap.set(
    'n',
    '<leader>s',
    [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    { desc = 'Custom: Find and replace the word the cursor is on' }
)

-- -- Make file executeable
-- vim.keymap.set(
--     'n',
--     '<leader>x',
--     '<cmd>!chmod +x %<CR>',
--     { silent = true, desc = 'Custom: Make file executeable' }
-- )
--
-- -- Diffing https://www.naseraleisa.com/posts/diff#file-1
-- -- Compare buffer to clipboard
-- vim.keymap.set(
--     'n',
--     '<leader>vcc',
--     '<cmd>CompareClipboard<cr>',
--     { desc = 'Custom: Compare Clipboard', silent = true }
-- )
--
-- -- Compare Clipboard to selected text
-- vim.keymap.set(
--     'v',
--     '<leader>vcc',
--     '<esc><cmd>CompareClipboardSelection<cr>',
--     { desc = 'Custom: Compare Clipboard Selection' }
-- )

-- Reverse letters https://vim.fandom.com/wiki/Reverse_letters
vim.keymap.set(
    'v',
    '<leader>ir',
    [[c<C-O>:set ri<CR><C-R>"<Esc>:set nori<CR>]],
    { desc = 'Custom: Reverse characters in text selection' }
)

vim.keymap.set(
    'n',
    '<leader>;',
    function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.cmd([[norm A;]])
        vim.api.nvim_win_set_cursor(0, cursor)
    end,
    -- [[A;<Esc>]],
    -- [[mmA;<Esc>`m]],
    {
        desc = 'Custom: Add semicolon to end of line without moving cursor',
    }
)

vim.keymap.set('v', '<leader>;', ':s/\\([^;]\\)$/\\1;/<CR>', {
    desc = 'Custom: Add a semicolon to end of each line in visual selection excluding lines that already have semicolons',
})

vim.keymap.set(
    'n',
    '<leader>,',
    function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.cmd([[norm A,]])
        vim.api.nvim_win_set_cursor(0, cursor)
    end,
    -- [[A,<Esc>]],
    -- [[mmA,<Esc>`m]],
    {
        desc = 'Custom: Add comma to end of line without moving cursor',
    }
)

vim.keymap.set('v', '<leader>,', ':s/\\([^,]\\)$/\\1,/<CR>', {
    desc = 'Custom: Add a comma to end of each line in visual selection excluding lines that already have commas',
})

vim.keymap.set('n', '<A-,>', '<c-w>5<', {
    desc = 'Custom: Decrease window width',
})
vim.keymap.set('n', '<A-;>', '<c-w>5>', {
    desc = 'Custom: Increase window width',
})
vim.keymap.set('n', '<A-t>', '<c-w>5+', {
    desc = 'Custom: Increase window height',
})
vim.keymap.set('n', '<A-s>', '<c-w>5-', {
    desc = 'Custom: Decrease window height',
})

local function add_lines(direction)
    local line_number = vim.api.nvim_win_get_cursor(0)[1]
    if direction == 'below' then line_number = line_number - 1 end
    local lines = vim.fn['repeat']({ '' }, vim.v.count1)
    vim.api.nvim_buf_set_lines(0, line_number, line_number, true, lines)
end

vim.keymap.set('n', '<leader>voj', function() add_lines('below') end, {
    desc = 'Custom: add blank line(s) below the current line',
})
vim.keymap.set('n', '<leader>vok', function() add_lines('above') end, {
    desc = 'Custom: add blank line(s) above the current line',
})

local my_lsp_location_navigator =
    require('myconfig.lsp.locations').create_lsp_locations_navigator({
        namespace = 'my_default_lsp_location_navigator',
    })

local myoperations = maputils
    .operations({

        backward_key = '[',
        forward_key = ']',
        mode = { 'n' },
    })
    :navigator({
        default = {
            key = 's',
            mode = { 'n', 'x' },
            backward = function() vim.cmd('norm!' .. vim.v.count1 .. '[s') end,
            forward = function() vim.cmd('norm!' .. vim.v.count1 .. ']s') end,
            desc = 'Custom Remap: jump to "{prev|next}" spelling error',
            opts = {},
        },
        extreme = {
            key = 'S',
            mode = { 'n', 'x' },
            backward = function() vim.cmd('norm!' .. vim.v.count1 .. '[S') end,
            forward = function() vim.cmd('norm!' .. vim.v.count1 .. ']S') end,
            desc = 'Custom Remap: jump to "{prev|next}" spelling error excluding rare words',
            opts = {},
        },
    })
    :navigator({
        --visual mode: can navigate to a new buffer but visual mode is probably otherwise useful
        default = {
            key = 'q',
            mode = { 'n', 'x' },
            backward = 'cprevious',
            forward = 'cnext',
            desc = 'Custom: Run the "{cprevious|cnext}" command',
            opts = {},
        },
        extreme = {
            key = 'Q',
            mode = { 'n', 'x' },
            backward = 'cfirst',
            forward = 'clast',
            desc = 'Custom: Run the "{cfirst|clast}" command',
            opts = {},
        },
    })
    :navigator({
        default = {
            key = '<C-q>',
            backward = 'cpfile',
            forward = 'cnfile',
            desc = 'Custom: Run the "{cpfile|cnfile}" command',
            opts = {},
        },
        extreme = {
            key = '<leader><C-q>',
            backward = 'cfirst',
            forward = 'clast',
            desc = 'Custom: Run the "{cfirst|clast}" command',
            opts = {},
        },
    })
    :navigator({
        --visual mode: can navigate to a new buffer but visual mode is probably otherwise useful
        default = {
            key = 'l',
            mode = { 'n', 'x' },
            backward = 'lprevious',
            forward = 'lnext',
            desc = 'Custom: Run the "{lprevious|lnext}" command',
            opts = {},
        },
        extreme = {
            key = 'L',
            mode = { 'n', 'x' },
            backward = 'lfirst',
            forward = 'llast',
            desc = 'Custom: Run the "{lfirst|llast}" command',
            opts = {},
        },
    })
    :navigator({
        -- no visual mode: map will navigate to a new buffer so visual mode is not useful
        default = {
            key = '<C-l>',
            backward = 'lpfile',
            forward = 'lnfile',
            desc = 'Custom: Run the "{lpfile|lnfile}" command',
            opts = {},
        },
        extreme = {
            key = '<leader><C-l>',
            backward = 'lfirst',
            forward = 'llast',
            desc = 'Custom: Run the "{lfirst|llast}" command',
            opts = {},
        },
    })
    :navigator({
        -- no visual mode: map will navigate to a new buffer so visual mode is not useful
        default = {
            key = 'b',
            backward = 'bprevious',
            forward = 'bnext',
            desc = 'Custom: Run the "{bprevious|bnext}" command',
            opts = {},
        },
        extreme = {
            key = 'B',
            backward = 'bfirst',
            forward = 'blast',
            desc = 'Custom: Run the "{bfirst|blast}" command',
            opts = {},
        },
    })
    :navigator({
        -- no visual mode: map will navigate to a new buffer so visual mode is not useful
        default = {
            key = 'a',
            backward = 'previous',
            forward = 'next',
            desc = 'Custom: Run the "{previous|next}" command',
            opts = {},
        },
        extreme = {
            key = 'A',
            backward = 'first',
            forward = 'last',
            desc = 'Custom: Run the "{first|last}" command',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'hh',
            mode = { 'n', 'x' },
            backward = function()
                local target = 'all'
                if vim.wo.diff == true then target = 'unstaged' end
                require('gitsigns.actions').nav_hunk(
                    'prev',
                    { target = target, count = vim.v.count1 }
                )
            end,
            forward = function()
                local target = 'all'
                if vim.wo.diff == true then target = 'unstaged' end
                require('gitsigns.actions').nav_hunk(
                    'next',
                    { target = target, count = vim.v.count1 }
                )
            end,
            desc = 'Gitsigns: smart jump to the {previous|next} git hunk (based on if in diff mode)',
            opts = {},
        },
        extreme = {
            key = 'HH',
            mode = { 'n', 'x' },
            backward = function()
                local target = 'all'
                if vim.wo.diff == true then target = 'unstaged' end
                require('gitsigns.actions').nav_hunk(
                    'first',
                    { target = target, count = math.huge }
                )
            end,
            forward = function()
                local target = 'all'
                if vim.wo.diff == true then target = 'unstaged' end
                require('gitsigns.actions').nav_hunk(
                    'last',
                    { target = target, count = math.huge }
                )
            end,
            desc = 'Gitsigns: smart jump to the {first|last} git hunk (based on if in diff mode)',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'hu',
            mode = { 'n', 'x' },
            backward = function()
                require('gitsigns.actions').nav_hunk(
                    'prev',
                    { target = 'unstaged', count = vim.v.count1 }
                )
            end,
            forward = function()
                require('gitsigns.actions').nav_hunk(
                    'next',
                    { target = 'unstaged', count = vim.v.count1 }
                )
            end,
            desc = 'Gitsigns: jump to the {previous|next} unstaged git hunk',
            opts = {},
        },
        extreme = {
            key = 'Hu',
            mode = { 'n', 'x' },
            backward = function()
                require('gitsigns.actions').nav_hunk(
                    'first',
                    { target = 'unstaged', count = math.huge }
                )
            end,
            forward = function()
                require('gitsigns.actions').nav_hunk(
                    'last',
                    { target = 'unstaged', count = math.huge }
                )
            end,
            desc = 'Gitsigns: jump to the {first|last} unstaged git hunk',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'hs',
            mode = { 'n', 'x' },
            backward = function()
                require('gitsigns.actions').nav_hunk(
                    'prev',
                    { target = 'staged', count = vim.v.count1 }
                )
            end,
            forward = function()
                require('gitsigns.actions').nav_hunk(
                    'next',
                    { target = 'staged', count = vim.v.count1 }
                )
            end,
            desc = 'Gitsigns: jump to the {previous|next} staged git hunk',
            opts = {},
        },
        extreme = {
            key = 'Hs',
            mode = { 'n', 'x' },
            backward = function()
                require('gitsigns.actions').nav_hunk(
                    'first',
                    { target = 'staged', count = math.huge }
                )
            end,
            forward = function()
                require('gitsigns.actions').nav_hunk(
                    'last',
                    { target = 'staged', count = math.huge }
                )
            end,
            desc = 'Gitsigns: jump to the {first|last} staged git hunk',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'ha',
            mode = { 'n', 'x' },
            backward = function()
                require('gitsigns.actions').nav_hunk(
                    'prev',
                    { target = 'all', count = vim.v.count1 }
                )
            end,
            forward = function()
                require('gitsigns.actions').nav_hunk(
                    'next',
                    { target = 'all', count = vim.v.count1 }
                )
            end,
            desc = 'Gitsigns: jump to the {previous|next} git hunk (staged or unstaged)',
            opts = {},
        },
        extreme = {
            key = 'Ha',
            mode = { 'n', 'x' },
            backward = function()
                require('gitsigns.actions').nav_hunk(
                    'first',
                    { target = 'all', count = math.huge }
                )
            end,
            forward = function()
                require('gitsigns.actions').nav_hunk(
                    'last',
                    { target = 'all', count = math.huge }
                )
            end,
            desc = 'Gitsigns: jump to the {first|last} git hunk (staged or unstaged)',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'dd',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -vim.v.count1,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = vim.v.count1,
                    float = true,
                })
            end,
            desc = 'Custom: Jump to the {previous|next} diagnostic',
            opts = {},
        },
        extreme = {
            key = 'DD',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -math.huge,
                    wrap = false,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = math.huge,
                    wrap = false,
                    float = true,
                })
            end,
            desc = 'Custom: Jump to the {first|last} diagnostic',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'dh',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -vim.v.count1,
                    severity = vim.diagnostic.severity.HINT,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = vim.v.count1,
                    severity = vim.diagnostic.severity.HINT,
                    float = true,
                })
            end,
            desc = 'Custom: jump to the {previous|next} diagnostic hint',
            opts = {},
        },
        extreme = {
            key = 'Dh',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -math.huge,
                    severity = vim.diagnostic.severity.HINT,
                    wrap = false,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = math.huge,
                    severity = vim.diagnostic.severity.HINT,
                    wrap = false,
                    float = true,
                })
            end,
            desc = 'Custom Remap: jump to the {first|last} diagnostic hint',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'de',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -vim.v.count1,
                    severity = vim.diagnostic.severity.ERROR,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = vim.v.count1,
                    severity = vim.diagnostic.severity.ERROR,
                    float = true,
                })
            end,
            desc = 'Custom: jump to the {previous|next} diagnostic error',
            opts = {},
        },
        extreme = {
            key = 'De',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -math.huge,
                    severity = vim.diagnostic.severity.ERROR,
                    wrap = false,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = math.huge,
                    severity = vim.diagnostic.severity.ERROR,
                    wrap = false,
                    float = true,
                })
            end,
            desc = 'Custom Remap: jump to the {first|last} diagnostic error',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'di',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -vim.v.count1,
                    severity = vim.diagnostic.severity.INFO,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = vim.v.count1,
                    severity = vim.diagnostic.severity.INFO,
                    float = true,
                })
            end,
            desc = 'Custom: jump to the {previous|next} diagnostic info',
            opts = {},
        },
        extreme = {
            key = 'Di',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -math.huge,
                    severity = vim.diagnostic.severity.INFO,
                    wrap = false,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = math.huge,
                    severity = vim.diagnostic.severity.INFO,
                    wrap = false,
                    float = true,
                })
            end,
            desc = 'Custom Remap: jump to the {first|last} diagnostic info',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'dw',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -vim.v.count1,
                    severity = vim.diagnostic.severity.WARN,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = vim.v.count1,
                    severity = vim.diagnostic.severity.WARN,
                    float = true,
                })
            end,
            desc = 'Custom: jump to the {previous|next} diagnostic warn',
            opts = {},
        },
        extreme = {
            key = 'Dw',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -math.huge,
                    severity = vim.diagnostic.severity.WARN,
                    wrap = false,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = math.huge,
                    severity = vim.diagnostic.severity.WARN,
                    wrap = false,
                    float = true,
                })
            end,
            desc = 'Custom Remap: jump to the {first|last} diagnostic warning',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'm',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@function.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
                    '@function.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom Remap: jump to the {previous|next} method start',
            opts = {},
        },
        extreme = {
            key = 'M',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@function.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
                    '@function.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom Remap: jump to the {previous|next} method end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'f',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@call.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
                    '@call.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom Remap: jump to the {previous|next} function call start',
            opts = {},
        },
        extreme = {
            key = 'F',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@call.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
                    '@call.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom Remap: jump to the {previous|next} function call end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'c',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@class.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
                    '@class.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} class start',
            opts = {},
        },
        extreme = {
            key = 'C',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@class.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
                    '@class.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} class end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'i',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@conditional.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
                    '@conditional.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} conditional start',
            opts = {},
        },
        extreme = {
            key = 'I',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@conditional.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
                    '@conditional.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} conditional end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'o',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@loop.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
                    '@loop.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} loop start',
            opts = {},
        },
        extreme = {
            key = 'O',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@loop.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
                    '@loop.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} loop end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'va',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@parameter.inner',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
                    '@parameter.inner',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} parameter inner start',
            opts = {},
        },
        extreme = {
            key = 'vA',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@parameter.inner',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
                    '@parameter.inner',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} parameter inner end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'gci',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@comment.inner',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
                    '@comment.inner',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} comment inner start',
            opts = {},
        },
        extreme = {
            key = 'gcI',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@comment.inner',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
                    '@comment.inner',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} comment inner end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'gca',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@comment.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
                    '@comment.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} comment outer start',
            opts = {},
        },
        extreme = {
            key = 'gcA',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@comment.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
                    '@comment.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} comment outer end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'gmn',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@function_declaration_name.inner',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
                    '@function_declaration_name.inner',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            desc = 'Custom: jump to the {previous|next} function name start',
            opts = {},
        },
        extreme = {
            key = 'gmN',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@function_declaration_name.inner',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
                    '@function_declaration_name.inner',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            desc = 'Custom: jump to the {previous|next} function name end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'gt',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@cast.outer',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
                    '@cast.outer',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            desc = 'Custom: jump to the {previous|next} type cast start',
            opts = {},
        },
        extreme = {
            key = 'gT',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@cast.outer',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
                    '@cast.outer',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            desc = 'Custom: jump to the {previous|next} type cast end',
            opts = {},
        },
    })
    :navigator({
        default = {
            key = 'grr',
            mode = { 'n' },
            backward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').references
                )
                my_lsp_location_navigator:jump('prev')
            end,
            forward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').references
                )
                my_lsp_location_navigator:jump('next')
            end,
            backward_repeat = function() my_lsp_location_navigator:jump('prev') end,
            forward_repeat = function() my_lsp_location_navigator:jump('next') end,
            desc = 'Custom: jump to {previous|next} LSP reference',
            construct_callbacks = true,
            opts = {},
        },
        extreme = {
            key = 'Grr',
            mode = { 'n' },
            backward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').references
                )
                my_lsp_location_navigator:jump('first')
            end,
            forward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').references
                )
                my_lsp_location_navigator:jump('last')
            end,
            backward_repeat = function()
                my_lsp_location_navigator:jump('first')
            end,
            forward_repeat = function() my_lsp_location_navigator:jump('last') end,
            desc = 'Custom: jump to {first|last} LSP reference',
            opts = {},
        },
    })
    :navigator({
        default = {
            key = 'gd',
            mode = { 'n' },
            backward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').definition
                )
                my_lsp_location_navigator:jump('prev')
            end,
            forward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').definition
                )
                my_lsp_location_navigator:jump('next')
            end,
            backward_repeat = function() my_lsp_location_navigator:jump('prev') end,
            forward_repeat = function() my_lsp_location_navigator:jump('next') end,
            desc = 'Custom: jump to {previous|next} LSP definition',
            construct_callbacks = true,
            opts = {},
        },
        extreme = {
            key = 'Gd',
            mode = { 'n' },
            backward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').definition
                )
                my_lsp_location_navigator:jump('first')
            end,
            forward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').definition
                )
                my_lsp_location_navigator:jump('last')
            end,
            backward_repeat = function()
                my_lsp_location_navigator:jump('first')
            end,
            forward_repeat = function() my_lsp_location_navigator:jump('last') end,
            desc = 'Custom: jump to {first|last} LSP definition',
            opts = {},
        },
    })
    :navigator({
        default = {
            key = 'gD',
            mode = { 'n' },
            backward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').declaration
                )
                my_lsp_location_navigator:jump('prev')
            end,
            forward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').declaration
                )
                my_lsp_location_navigator:jump('next')
            end,
            backward_repeat = function() my_lsp_location_navigator:jump('prev') end,
            forward_repeat = function() my_lsp_location_navigator:jump('next') end,
            desc = 'Custom: jump to {previous|next} LSP declaration',
            construct_callbacks = true,
            opts = {},
        },
        extreme = {
            key = 'GD',
            mode = { 'n' },
            backward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').declaration
                )
                my_lsp_location_navigator:jump('first')
            end,
            forward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').declaration
                )
                my_lsp_location_navigator:jump('last')
            end,
            backward_repeat = function()
                my_lsp_location_navigator:jump('first')
            end,
            forward_repeat = function() my_lsp_location_navigator:jump('last') end,
            desc = 'Custom: jump to {first|last} LSP declaration',
            opts = {},
        },
    })
    :navigator({
        default = {
            key = 'gi',
            mode = { 'n' },
            backward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').implementation
                )
                my_lsp_location_navigator:jump('prev')
            end,
            forward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').implementation
                )
                my_lsp_location_navigator:jump('next')
            end,
            backward_repeat = function() my_lsp_location_navigator:jump('prev') end,
            forward_repeat = function() my_lsp_location_navigator:jump('next') end,
            desc = 'Custom: jump to {previous|next} LSP implementation',
            construct_callbacks = true,
            opts = {},
        },
        extreme = {
            key = 'Gi',
            mode = { 'n' },
            backward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').implementation
                )
                my_lsp_location_navigator:jump('first')
            end,
            forward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').implementation
                )
                my_lsp_location_navigator:jump('last')
            end,
            backward_repeat = function()
                my_lsp_location_navigator:jump('first')
            end,
            forward_repeat = function() my_lsp_location_navigator:jump('last') end,
            desc = 'Custom: jump to {first|last} LSP implementation',
            opts = {},
        },
    })
    :navigator({
        default = {
            key = 'gd',
            mode = { 'n' },
            backward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').type_definition
                )
                my_lsp_location_navigator:jump('prev')
            end,
            forward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').type_definition
                )
                my_lsp_location_navigator:jump('next')
            end,
            backward_repeat = function() my_lsp_location_navigator:jump('prev') end,
            forward_repeat = function() my_lsp_location_navigator:jump('next') end,
            desc = 'Custom: jump to {previous|next} LSP type definition',
            construct_callbacks = true,
            opts = {},
        },
        extreme = {
            key = 'Gd',
            mode = { 'n' },
            backward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').type_definition
                )
                my_lsp_location_navigator:jump('first')
            end,
            forward = function()
                my_lsp_location_navigator:init(
                    require('myconfig.lsp.locations').type_definition
                )
                my_lsp_location_navigator:jump('last')
            end,
            backward_repeat = function()
                my_lsp_location_navigator:jump('first')
            end,
            forward_repeat = function() my_lsp_location_navigator:jump('last') end,
            desc = 'Custom: jump to {first|last} LSP type definition',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            --TODO implement my own jump consumer that automatically opens the output window
            --TODO implement my own output consumer which has an a position argument (so I can do first and last)
            key = 'vtt',
            mode = { 'n', 'v' },
            backward = function() require('neotest').jump.prev() end,
            forward = function()
                require('neotest').jump.next()

                -- require('neotest').output.open()
            end,
            desc = 'Custom: jump to {previous|next} test case',
            construct_callbacks = true,
            opts = {},
        },
        extreme = {
            key = 'vtT',
            mode = { 'n' },
            backward = function() error('unimplemented') end,
            forward = function() error('unimplemented') end,
            desc = 'Custom: jump to {first|last} test case',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'vtf',
            mode = { 'n', 'v' },
            backward = function()
                require('neotest').jump.prev({ status = 'failed' })
            end,
            forward = function()
                require('neotest').jump.next({ status = 'failed' })
            end,
            desc = 'Custom: jump to {previous|next} test case',
            construct_callbacks = true,
            opts = {},
        },
        extreme = {
            key = 'vtF',
            mode = { 'n' },
            backward = function() error('unimplemented') end,
            forward = function() error('unimplemented') end,
            desc = 'Custom: jump to {first|last} failed test case',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'vtp',
            mode = { 'n', 'v' },
            backward = function()
                require('neotest').jump.prev({ status = 'passed' })
            end,
            forward = function()
                require('neotest').jump.next({ status = 'passed' })
            end,
            desc = 'Custom: jump to {previous|next} passed test case',
            construct_callbacks = true,
            opts = {},
        },
        extreme = {
            key = 'vtP',
            mode = { 'n' },
            backward = function() error('unimplemented') end,
            forward = function() error('unimplemented') end,
            desc = 'Custom: jump to {first|last} passed test case',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'vts',
            mode = { 'n', 'v' },
            backward = function()
                require('neotest').jump.prev({ status = 'skipped' })
            end,
            forward = function()
                require('neotest').jump.next({ status = 'skipped' })
            end,
            desc = 'Custom: jump to {previous|next} skipped test case',
            construct_callbacks = true,
            opts = {},
        },
        extreme = {
            key = 'vtS',
            mode = { 'n' },
            backward = function() error('unimplemented') end,
            forward = function() error('unimplemented') end,
            desc = 'Custom: jump to {first|last} skipped test case',
            opts = {},
        },
    })

maputils
    .operations({
        backward_key = '<C-h>',
        forward_key = '<C-l>',
        mode = { 'n', 'x' }, --Add some check so that non-visual visual mode keymaps don't get repeated
    })
    :navigator({
        default = {
            key = '',
            backward = function()
                if myoperations.isLastCallbackExtreme then
                    myoperations.repeat_extreme_backward_callback()
                else
                    myoperations.repeat_backward_callback()
                end
            end,
            forward = function()
                if myoperations.isLastCallbackExtreme then
                    myoperations.repeat_extreme_forward_callback()
                else
                    myoperations.repeat_forward_callback()
                end
            end,
            desc = 'Custom: Repeat my last {backward|forward} keymap for navigating lists (if extreme was used, will repeat extreme)',
            opts = {},
        },
    })

maputils
    .operations({
        backward_key = '<leader><C-h>',
        forward_key = '<leader><C-l>',
        mode = { 'n' },
    })
    :navigator({
        default = {
            key = '',
            backward = function()
                if myoperations.isLastCallbackExtreme then
                    myoperations.repeat_backward_callback()
                else
                    myoperations.repeat_extreme_backward_callback()
                end
            end,
            forward = function()
                if myoperations.isLastCallbackExtreme then
                    myoperations.repeat_forward_callback()
                else
                    myoperations.repeat_extreme_forward_callback()
                end
            end,
            desc = 'Custom: Repeat the extreme of my last "{backward|forward}" command navigating lists (if the last movement was extreme then the none extreme will be repeated)',
            opts = {},
        },
    })

-------------------------------------------------------------------------------
--- treesitter

vim.keymap.set(
    { 'x', 'o' },
    'a=',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@assignment.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of an assignment',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'i=',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@assignment.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of an assignment',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'il=',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@assignment.lhs',
            'textobjects'
        )
    end,
    {
        desc = 'Select left hand side of an assignment',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ir=',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@assignment.rhs',
            'textobjects'
        )
    end,
    {
        desc = 'Select right hand side of an assignment',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'aa',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@parameter.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of a parameter/argument',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ia',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@parameter.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of a parameter/argument',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ai',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@conditional.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of a conditional',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ii',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@conditional.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of a conditional',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ao',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@loop.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of a loop',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'io',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@loop.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of a loop',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'af',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@call.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of a function call',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'if',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@call.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of a function call',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'am',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@function.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of a method/function definition',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'im',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@function.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of a method/function definition',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ac',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@class.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of a class',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ic',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@class.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of a class',
    }
)

vim.keymap.set({ 'x', 'o' }, 'a<leader>c', function()
    require('nvim-treesitter-textobjects.select').select_textobject(
        -- I plan to replace this with a smarter version of the keymap
        '@comment.outer',
        'textobjects'
    )
end, {
    desc = 'Select outer part of a comment',
})

vim.keymap.set({ 'x', 'o' }, 'i<leader>c', function()
    require('nvim-treesitter-textobjects.select').select_textobject(
        -- I plan to replace this with a smarter version of the keymap
        '@comment.inner',
        'textobjects'
    )
end, {
    desc = 'Select inner part of a comment',
})

vim.keymap.set(
    { 'x', 'o' },
    'agt',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@cast.outer',
            config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
        )
    end,
    {

        desc = 'Select outer part of a type cast',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'igt',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@cast.inner',
            config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
        )
    end,
    {
        desc = 'Select inner part of a type cast',
    }
)
-------------------------------------------------------------------------------
---treesitter swap nodes
vim.keymap.set(
    'n',
    '<leader>vna',
    function()
        require('nvim-treesitter-textobjects.swap').swap_next(
            '@parameter.inner'
        )
    end,
    {
        desc = 'TS: swap next parameter',
    }
)

vim.keymap.set(
    'n',
    '<leader>vpa',
    function()
        require('nvim-treesitter-textobjects.swap').swap_previous(
            '@parameter.inner'
        )
    end,
    {
        desc = 'TS: swap previous parameter',
    }
)

vim.keymap.set('n', '<leader>vn:', function()
    require('nvim-treesitter-textobjects.swap').swap_next('@property.outer') -- swap object property with next
end, {
    desc = 'TS: swap object property with next',
})

vim.keymap.set('n', '<leader>vp:', function()
    require('nvim-treesitter-textobjects.swap').swap_previous('@property.outer') -- swap object property with next
end, {
    desc = 'TS: swap object property with previous',
})

vim.keymap.set('n', '<leader>vnm', function()
    require('nvim-treesitter-textobjects.swap').swap_next('@function.outer') -- swap function with next
end, {
    desc = 'TS: swap function with next',
})

vim.keymap.set('n', '<leader>vpm', function()
    require('nvim-treesitter-textobjects.swap').swap_previous('@function.outer') -- swap function with previous
end, {
    desc = 'TS: swap function with previous',
})

-------------------------------------------------------------------------------
vim.keymap.del({ 'o', 'n', 'x' }, 'gc')

vim.keymap.set(
    { 'o' },
    'gc',
    function() require('myconfig.utils.mapping').comment_lines_textobject() end,
    { desc = 'Comment textobject identical to gc operator' }
    --note: vgc does not select the commented lines. It really does a block
    --comment arround the character (which in my opinion pretty useless so I might
    --try to fix that) this is because it isn't using the textobject gc it is using
    --the gc visual mapping defined in numToStr/Comment.nvim
)

vim.keymap.set(
    { 'o', 'x' },
    'agc',
    function()
        require('myconfig.utils.mapping').around_comment_lines_textobject()
    end,
    { desc = 'Comment textobject with treesitter fallback' }
)

vim.keymap.set(
    { 'o', 'x' },
    'igi',
    ":<c-u>lua require('myconfig.utils.mapping').select_indent()<cr>",
    { desc = 'Select inner indent textobject', silent = true }
)

vim.keymap.set(
    { 'o', 'x' },
    'agi',
    ":<c-u>lua require('myconfig.utils.mapping').select_indent(true)<cr>",
    { desc = 'Select around indent textobject', silent = true }
)
