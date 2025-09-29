local M = {}

function M.string_starts_with(s, prefix)
    return string.sub(s, 1, string.len(prefix)) == prefix
end

---Get the get default git branch name
---@return string
function M.get_default_branch_name()
    local res = vim.system(
        { 'git', 'rev-parse', '--verify', 'main' },
        { capture_output = true }
    ):wait()
    return res.code == 0 and 'main' or 'master'
end

---Delete the buffer by buffer number
---@param bufnr uinteger
function M.delete_buf(bufnr)
    if bufnr ~= nil then vim.api.nvim_buf_delete(bufnr, { force = true }) end
end

---Open buffer in split
---@param bufnr uinteger
---@param vertical_split string?
function M.split(bufnr, vertical_split)
    local cmd = vertical_split and 'vsplit' or 'split'

    vim.cmd(cmd)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, bufnr)
end

---Resize split
---@param amount integer
---@param split_vertical string?
function M.resize(amount, split_vertical)
    local cmd = split_vertical and 'vertical resize ' or 'resize'
    cmd = cmd .. amount

    vim.cmd(cmd)
end

---Schedule an error notification
---@param err any
function M.scheduled_error(err)
    vim.schedule(function() vim.notify(err, vim.log.levels.ERROR) end)
end

---validates the value is a valid position (intended to be used with vim.validate)
---@param position [integer, integer] (row, col) tuple, (0, 0) if the mark is not set
---@return boolean
---@return string
local function position_validator(position)
    if type(position) ~= 'table' then
        return false, 'position must be a tuple (row, col)'
    end
    if #position ~= 2 then
        return false,
            string.format(
                'position must be a tuple (row, col) but a tuple of size %s was found',
                #position
            )
    end

    if type(position[1]) ~= 'number' then
        return false,
            string.format(
                'position row must be an integer but type %s was found',
                type(position[1])
            )
    end
    if position[1] < 0 then
        return false,
            string.format('position row must be greater than 0', #position)
    end

    if type(position[2]) ~= 'number' then
        return false,
            string.format(
                'position column must be an integer but type %s was found',
                type(position[1])
            )
    end
    if position[2] < 0 then
        return false,
            string.format('position column must be greater than 0', #position)
    end
    return true, ''
end

---sorts the start_pos and end_pos
---@param start_pos [integer, integer] (row, col) tuple, (0, 0) if the mark is not set
---@param end_pos [integer, integer] (row, col) tuple, (0, 0) if the mark is not set
---@return [integer, integer] new_start_pos (row, col) tuple
---@return [integer, integer] new_end_pos (row, col) tuple
function M.sort_start_end_pos(start_pos, end_pos)
    vim.validate(
        'start_pos',
        start_pos,
        position_validator,
        '[integer, integer] (row, col) tuple'
    )
    vim.validate(
        'end_pos',
        start_pos,
        position_validator,
        '[integer, integer] (row, col) tuple'
    )
    local start_row = start_pos[1]
    local start_col = start_pos[2]

    local end_row = end_pos[1]
    local end_col = end_pos[2]
    if start_row == end_row and start_col <= end_col then
        return start_pos, end_pos
    elseif start_row == end_row and start_col > end_col then
        return end_pos, start_pos
    elseif start_row < end_row then
        return start_pos, end_pos
    else
        return end_pos, start_pos
    end
end

---sorts (asc) the start number and end number (used for sorting line/row numbers, character/column numbers,
---@param start_num integer
---@param end_num integer
---@return integer, integer (start_num, end_num) where start_num <= end_num
function M.sort_start_end_number(start_num, end_num)
    if start_num <= end_num then return start_num, end_num end
    return end_num, start_num
end

---@class UserCommandTextSelectionOptions
---@field bufnr? uinteger (default: 0)
---@field user_command_opts vim.api.keyset.create_user_command.command_args the usercommand callback opts

---Gets the visual selection
---(note user commands and keymaps have different quirks when trying to get the range)
---
---@param opts UserCommandTextSelectionOptions
function M.get_text_selection(opts)
    vim.validate('opts', opts, 'table')
    local bufnr = opts.bufnr or 0
    local user_command_opts = opts.user_command_opts
    vim.validate('user_command_opts', opts.user_command_opts, 'table')
    vim.validate(
        'user_command_opts.range',
        opts.user_command_opts.range,
        'number'
    )
    vim.validate(
        'user_command_opts.range',
        opts.user_command_opts.range,
        function(range)
            if range < 0 or range > 2 then
                return false, 'range count must be 0, 1, or 2'
            end
            return true
        end,
        '0, 1 or 2'
    )

    vim.validate(
        'user_command_opts.line1',
        opts.user_command_opts.line1,
        'number'
    )
    vim.validate(
        'user_command_opts.line1',
        opts.user_command_opts.line1,
        function(line1)
            if line1 <= 0 then return false, 'line1 must be greater than 0' end
            return true
        end,
        'number'
    )

    vim.validate(
        'user_command_opts.line2',
        opts.user_command_opts.line2,
        'number'
    )
    vim.validate(
        'user_command_opts.line2',
        opts.user_command_opts.line2,
        function(line2)
            if line2 <= 0 then return false, 'line2 must be greater than 0' end
            return true
        end,
        'number'
    )

    local line1, line2 = M.sort_start_end_number(
        user_command_opts.line1,
        user_command_opts.line2
    )

    if user_command_opts.range == 1 or user_command_opts.range == 0 then
        local start_pos = { bufnr, line1, vim.v.maxcol, 0 }
        local end_pos = { bufnr, line2, vim.v.maxcol, 0 }

        return vim.fn.getregion(start_pos, end_pos, {
            type = 'V',
        })
    end

    --There is no way to get columns from command ranges so we have to get
    --fancy and try to determine it by if the last visual selection line numbers
    --match the command ranges line numbers. We only attempt this when the range
    --count is 2 since it will always be two if the range is a visual selection.
    --This is because visual selections always have two positions a start and end.
    --Note: There is one edgecase where I can't give the correct selection
    --and that is when the last visual selection has the same line numbers
    --as the as the range used in the command for example if I do
    -- :'a,'bCompareClipboardSelection where the mark `a` and mark `b` have
    -- the same line number as the last visual selection then this function will
    -- incorrectly return back the last visual selection using the last visual selection
    -- mode despite the correct ruturn value should just be the full lines

    --Important: using marks '<' and '>' only works correctly when this
    --function is called from a user command. It does not work from keymaps.
    local last_visual_selection_start_pos =
        vim.api.nvim_buf_get_mark(bufnr, '<')
    local last_visual_selection_end_pos = vim.api.nvim_buf_get_mark(bufnr, '>')
    last_visual_selection_start_pos, last_visual_selection_end_pos =
        M.sort_start_end_pos(
            last_visual_selection_start_pos,
            last_visual_selection_end_pos
        )
    local last_visual_selection_start_row = last_visual_selection_start_pos[1]
    local last_visual_selection_end_row = last_visual_selection_end_pos[1]
    local last_visual_selection_start_col = last_visual_selection_start_pos[2]
    local last_visual_selection_end_col = last_visual_selection_end_pos[2]
    local last_visual_selection_mode = vim.fn.visualmode()

    --determine if lines match last visual selection
    if
        line1 == last_visual_selection_start_row
        and line2 == last_visual_selection_end_row
    then
        local start_pos_col = last_visual_selection_start_col
        if start_pos_col < vim.v.maxcol then --TODO not if im handling maxcol correctly
            start_pos_col = start_pos_col + 1 --Convert from 0 index to 1 index
        end

        local start_pos = { bufnr, line1, start_pos_col, 0 }

        local end_pos_col = last_visual_selection_end_col
        if end_pos_col < vim.v.maxcol then --TODO not if im handling maxcol correctly
            end_pos_col = end_pos_col + 1 --Convert from 0 index to 1 index
        end
        local end_pos = { bufnr, line2, end_pos_col, 0 }

        return vim.fn.getregion(start_pos, end_pos, {
            type = last_visual_selection_mode,
        })
    end

    local start_pos = { bufnr, line1, vim.v.maxcol, 0 }
    local end_pos = { bufnr, line2, vim.v.maxcol, 0 }

    return vim.fn.getregion(start_pos, end_pos, {
        type = 'V',
    })
end

---Like vim.fn.matchfuzzy but will return the inputed list back if results are empty
---
--- If {list} is a list of strings, then returns a |List| with all
--- the strings in {list} that fuzzy match {str}. The strings in
--- the returned list are sorted based on the matching score.
---
--- The optional {dict} argument always supports the following
--- items:
---     matchseq  When this item is present return only matches
---     that contain the characters in {str} in the
---     given sequence.
---     limit  Maximum number of matches in {list} to be
---     returned.  Zero means no limit.
---
--- If {list} is a list of dictionaries, then the optional {dict}
--- argument supports the following additional items:
---     key    Key of the item which is fuzzy matched against
---     {str}. The value of this item should be a
---     string.
---     text_cb  |Funcref| that will be called for every item
---     in {list} to get the text for fuzzy matching.
---     This should accept a dictionary item as the
---     argument and return the text for that item to
---     use for fuzzy matching.
---
--- {str} is treated as a literal string and regular expression
--- matching is NOT supported.  The maximum supported {str} length
--- is 256.
---
--- When {str} has multiple words each separated by white space,
--- then the list of strings that have all the words is returned.
---
--- If there are no matching strings or there is an error, then an
--- empty list is returned. If length of {str} is greater than
--- 256, then returns an empty list.
---
--- When {limit} is given, matchfuzzy() will find up to this
--- number of matches in {list} and return them in sorted order.
---
--- Refer to |fuzzy-matching| for more information about fuzzy
--- matching strings.
---
--- Example: >vim
---    echo matchfuzzy(["clay", "crow"], "cay")
--- <results in ["clay"]. >vim
---    echo getbufinfo()->map({_, v -> v.name})->matchfuzzy("ndl")
--- <results in a list of buffer names fuzzy matching "ndl". >vim
---    echo getbufinfo()->matchfuzzy("ndl", {'key' : 'name'})
--- <results in a list of buffer information dicts with buffer
--- names fuzzy matching "ndl". >vim
---    echo getbufinfo()->matchfuzzy("spl",
---         \ {'text_cb' : {v -> v.name}})
--- <results in a list of buffer information dicts with buffer
--- names fuzzy matching "spl". >vim
---    echo v:oldfiles->matchfuzzy("test")
--- <results in a list of file names fuzzy matching "test". >vim
---    let l = readfile("buffer.c")->matchfuzzy("str")
--- <results in a list of lines in "buffer.c" fuzzy matching "str". >vim
---    echo ['one two', 'two one']->matchfuzzy('two one')
--- <results in `['two one', 'one two']` . >vim
---    echo ['one two', 'two one']->matchfuzzy('two one',
---         \ {'matchseq': 1})
--- <results in `['two one']`.
---
--- @param list any[]
--- @param str string
--- @param dict? table
--- @return any
function M.matchfuzzy(list, str, dict)
    local result
    --TODO I can't figure out why this code freaks out if I don't
    --first check the dict value like this
    if dict then
        result = vim.fn.matchfuzzy(list, str, dict)
    else
        result = vim.fn.matchfuzzy(list, str)
    end
    if #result == 0 then return list end
    return result
end

---Used to convert a user command argument completion menu into
---a fuzzy completion menu
---@param func fun(ArgLead: string, CmdLine: string, CursorPos: number): string[] | nil
---@return function
function M.make_fuzzy_completion(func)
    return function(ArgLead, CmdLine, CursorPos)
        local items = func(ArgLead, CmdLine, CursorPos)
        return M.matchfuzzy(items or {}, ArgLead)
    end
end
return M
