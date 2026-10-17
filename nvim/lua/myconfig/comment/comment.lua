local M = {}

local ft = require('myconfig.comment.ft')
local C = require('myconfig.comment.constants')

---Range of the selection that needs to be commented
---@class MyCommentRange
---@field start_row integer Starting row
---@field start_col integer Starting column
---@field end_row integer Ending row
---@field end_col integer Ending column

---Operator-mode function parameters
---@class ToggleCommentParams
---@field lines string[] List of lines
---@field rcs string RHS of commentstring
---@field lcs string LHS of commentstring
---@field range MyCommentRange

local position_before_operation
function M.save_position()
    position_before_operation = vim.api.nvim_win_get_cursor(0)
end

function M.restore_position()
    if position_before_operation ~= nil then
        vim.api.nvim_win_set_cursor(0, position_before_operation)
        position_before_operation = nil
    end
end
function M.setup_keymaps()
    vim.keymap.del({ 'o', 'n', 'x' }, 'gc')

    vim.keymap.set('n', 'gc', function()
        M.save_position()
        vim.go.operatorfunc = function(motion)
            M.comment_toggle_motion_linewise(motion)
        end
        return 'g@' -- operator pending
    end, { expr = true, desc = 'Comment toggle linewise' })

    vim.keymap.set('n', 'gb', function()
        M.save_position()
        vim.go.operatorfunc = function(motion)
            M.comment_toggle_motion_blockwise(motion)
            M.restore_position()
        end
        return 'g@' -- operator pending
    end, { expr = true, desc = 'Comment toggle blockwise' })

    vim.keymap.set('n', 'gcc', function()
        M.save_position()
        local count = vim.api.nvim_get_vvar('count')
        vim.go.operatorfunc = function(_)
            if count == 0 then
                M.comment_toggle_motion_linewise('line')
                M.restore_position()
            else
                M.toggle_with_count(count, C.ctype.linewise)
            end
        end
        return 'g@l'
    end, { expr = true, desc = 'Comment: toggle comment the line' })

    vim.keymap.set(
        'n',
        'gbc',
        function()
            -- Note: convention would dictate that this keymap would be 'gbB'
            -- but since B is a useful motion we will use c instead making
            -- the keymap gbB so that gbB still works for commenting on the B motion
            M.save_position()
            local count = vim.api.nvim_get_vvar('count')
            vim.go.operatorfunc = function(_)
                if count == 0 then
                    M.comment_toggle_motion_blockwise('line')
                    M.restore_position()
                else
                    M.toggle_with_count(count, C.ctype.blockwise)
                end
            end
            -- use the $ motion to make text from the cursor to the end of the line a comment
            return 'g@$'
        end,
        { expr = true, desc = 'Comment: toggle comment to the end of the line' }
    )

    vim.keymap.set(
        { 'o' },
        'gc',
        function() M.comment_lines_textobject() end,
        { desc = 'Comment: textobject identical to gc operator' }
        --Note: vgc does not select the commented lines. It really does a block
        --comment around the character (which in my opinion pretty useless so I might
        --try to fix that) this is because it isn't using the textobject gc it is using
        --the gc visual mapping
    )

    vim.keymap.set('x', 'gc', function()
        M.save_position()
        M.comment_visualmode_linewise(vim.api.nvim_get_mode().mode)
        --Old Comment.nvim did not restore position because it ran the `gc` and `gb`
        --keymaps as dot repeatable functions and needed the cursor at the top since it
        --was used to toggle the selected comment without having to reselect the visual
        --selection. It just was very sensitive to the cursor position. We don't need
        --worry about that now that the keymap isn't dot repeatable so we will restore
        --postion so this behaves more how I like it.
        M.restore_position()
    end, {
        desc = 'Comment: toggle linewise (visual)',
    })

    vim.keymap.set('x', 'gb', function()
        M.save_position()
        M.comment_visualmode_blockwise(vim.api.nvim_get_mode().mode)
        --Old Comment.nvim did not restore position because it ran the `gc` and `gb`
        --keymaps as dot repeatable functions and needed the cursor at the top since it
        --was used to toggle the selected comment without having to reselect the visual
        --selection. It just was very sensitive to the cursor position. We don't need
        --worry about that now that the keymap isn't dot repeatable so we will restore
        --postion so this behaves more how I like it.
        M.restore_position()
    end, {
        desc = 'Comment: toggle blockwise (visual)',
    })

    vim.keymap.set({ 'n' }, 'gC', function()
        M.save_position()
        local count = vim.api.nvim_get_vvar('count')
        vim.go.operatorfunc = function(motion)
            if count == 0 then
                M.flip_flop_comment(motion)
                M.restore_position()
            else
                -- TODO create to count version of flip_flop_comment similar to
                -- M.toggle_with_count(count, ctype)
                vim.notify(
                    'Flip flop with counts has not yet been implemented',
                    vim.log.levels.WARN
                )
                M.flip_flop_comment(motion)
                M.restore_position() --TODO remove when flip_flop with count is implemented
            end
        end
        return 'g@'
    end, {
        desc = 'Comment: Invert line comments on operator (dot repeatable)',
        expr = true,
    })

    vim.keymap.set({ 'x' }, 'gC', function()
        M.save_position()
        M.flip_flop_comment_visualmode(vim.api.nvim_get_mode().mode)
        M.restore_position()
    end, {
        desc = 'Comment: Invert line comments in visual selection',
    })

    vim.keymap.set(
        'n',
        'gco',
        function() M.insert_below(C.ctype.linewise) end,
        { desc = 'Comment: insert below' }
    )

    vim.keymap.set(
        'n',
        'gcO',
        function() M.insert_above(C.ctype.linewise) end,
        { desc = 'Comment: insert above' }
    )

    vim.keymap.set(
        'n',
        'gcA',
        function() M.insert_eol(C.ctype.linewise) end,
        { desc = 'Comment: insert end of line' }
    )

    vim.keymap.set(
        { 'o', 'x' },
        --ugh so I would love all these comment textobjects to have the same
        --namespaces but I also like being able to do vagcgc to uncomment a group
        --of comments
        'agc',
        function() M.around_comment_lines_textobject() end,
        { desc = 'Comment textobject with treesitter fallback' }
    )

    vim.keymap.set({ 'x', 'o' }, 'avgc', function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            -- I plan to replace this with a smarter version of the keymap
            '@comment.outer',
            'textobjects'
        )
    end, {
        desc = 'Select outer part of a comment',
    })

    vim.keymap.set({ 'x', 'o' }, 'ivgc', function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            -- I plan to replace this with a smarter version of the keymap
            '@comment.inner',
            'textobjects'
        )
    end, {
        desc = 'Select inner part of a comment',
    })
end

---Get region for line movement or visual selection
---NOTE: Returns the current line region, if `opmode` is not given.
---@param opmode? OpMotionMode
---@return MyCommentRange
function M.get_region(opmode)
    if not opmode then
        local row = unpack(vim.api.nvim_win_get_cursor(0))
        ---@type MyCommentRange
        return { start_row = row, start_col = 0, end_row = row, end_col = 0 }
    end

    local sln, eln =
        vim.api.nvim_buf_get_mark(0, '['), vim.api.nvim_buf_get_mark(0, ']')

    ---@type MyCommentRange
    return {
        start_row = sln[1],
        start_col = sln[2],
        end_row = eln[1],
        end_col = eln[2],
    }
end

---Get region for line movement or visual selection
---NOTE: Returns the current line region, if `visual_mode` is not given or an
---unknown value.
---@param visual_mode? VisualMode
---@return MyCommentRange
function M.get_region_from_visual_selection(visual_mode)
    --Note: \22 is the termcode for <C-v> key. Which is what vim.fn.visualmode()
    --returns when in visual block mode
    if not visual_mode or not string.match(visual_mode, '[vV\22]') then
        vim.notify(
            string.format(
                'Unknown visual mode of `%s`. Will fallback to commenting/uncommenting the current line.',
                visual_mode
            )
        )

        local row = unpack(vim.api.nvim_win_get_cursor(0))
        ---@type MyCommentRange
        return { start_row = row, start_col = 0, end_row = row, end_col = 0 }
    end

    -- when used in a keymap dot repeatable function we need to us the marks < and >
    -- to get the position and vim.fn.visualmode() to get the mode.
    -- I mention this because the old Comment.nvim plugin
    -- had the visual gc and gb keymaps run as dot repeatable functions.
    -- I made them no longer dot repeatable because I thought the repeat behavior
    -- weird when the cursor moved
    --
    -- Old marks used:
    -- ```
    -- local sln, eln =
    --     vim.api.nvim_buf_get_mark(0, '<'), vim.api.nvim_buf_get_mark(0, '>')
    --```

    local start_pos = vim.fn.getpos('v')
    local end_pos = vim.fn.getpos('.')

    local start_line = start_pos[2]
    local start_col = start_pos[3]
    local end_line = end_pos[2]
    local end_col = end_pos[3]

    -- If the user selected backwards, swap the coordinates
    if
        start_line > end_line
        or (start_line == end_line and start_col > end_col)
    then
        start_line, end_line = end_line, start_line
        start_col, end_col = end_col, start_col
    end

    if visual_mode == 'V' then
        start_col = 0
        end_col = math.huge
    end

    ---@type MyCommentRange
    return {
        start_row = start_line,
        start_col = start_col,
        end_row = end_line,
        end_col = end_col,
    }
end

---@private
---Helper to get padding pattern
---@param flag boolean
---@return string string
function M.get_padpat(flag) return flag and '%s?' or '' end

---@private
---Helper to get padding character
---@param flag boolean
---@return string string
function M.get_pad(flag) return flag and ' ' or '' end

---Check if the given string is commented or not
---
---If given {string[]} to the closure, it will check the first and last line
---with LHS and RHS of commentstring respectively else it will check the given
---line with LHS and RHS (if given) of the commenstring
---@param line_or_lines string|string[]
---@param left string Left side of the commentstring
---@param right string Right side of the commentstring
---@param padding boolean Is padding enabled?
---@param start_col? integer Starting column
---@param end_col? integer Ending column
---@return boolean
function M.is_commented(line_or_lines, left, right, padding, start_col, end_col)
    local pp = M.get_padpat(padding)
    local ll = #left == 0 and left or '^%s*' .. vim.pesc(left) .. pp
    local rr = #right == 0 and right or pp .. vim.pesc(right) .. '$'
    local pattern = ll .. '.-' .. rr
    local is_full = start_col == nil or end_col == nil

    -------------------
    -- for blockwise --
    -------------------
    if type(line_or_lines) == 'table' then
        local first, last = line_or_lines[1], line_or_lines[#line_or_lines]
        if is_full then
            return (string.find(first, ll) and string.find(last, rr)) ~= nil
        end
        return (
            string.find(string.sub(first, start_col + 1, -1), ll)
            and string.find(string.sub(last, 0, end_col + 1), rr)
        ) ~= nil
    end

    ------------------
    -- for linewise --
    ------------------
    if is_full then return string.find(line_or_lines, pattern) ~= nil end

    --------------------------------
    -- for current-line blockwise --
    --------------------------------
    -- SOURCE: https://github.com/numToStr/Comment.nvim/issues/224
    return string.find(
        string.sub(
            line_or_lines,
            start_col + 1,
            (end_col > #line_or_lines and #line_or_lines or end_col + 1)
        ),
        pattern
    ) ~= nil
end

-- FIXME This prints `a` in i_CTRL-o
---Moves the cursor and enters INSERT mode
---@param row integer Starting row
---@param col integer Ending column
local function move_n_insert(row, col)
    vim.api.nvim_win_set_cursor(0, { row, col })
    vim.api.nvim_feedkeys('a', 'ni', true)
end

---@param lnum integer Line index
---@param ctype integer
local function ins_on_line(lnum, ctype)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    ---@type MyCommentRange
    local range =
        { start_row = row, start_col = col, end_row = row, end_col = col }
    local start_row = row + lnum
    local lcs, rcs = ft.parse_cstr(range, ctype)
    local padding = M.get_pad(false) -- TODO could add ' ' conditionally at some point

    -- We need RHS of cstr, if we are doing block comments or if RHS exists
    -- because even in line comment RHS do exists for some filetypes like jsx_element, ocaml
    local if_rcs = #rcs == 0 and rcs or padding .. rcs

    vim.api.nvim_buf_set_lines(
        0,
        start_row,
        start_row,
        false,
        { lcs .. padding .. if_rcs }
    )
    vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
    vim.api.nvim_command('normal! ==')
    move_n_insert(start_row + 1, #vim.api.nvim_get_current_line() - #if_rcs - 1)
end

---Add a comment below the current line and goes to INSERT mode
---@param ctype integer See |comment.utils.ctype|
function M.insert_below(ctype) ins_on_line(0, ctype) end

---Add a comment above the current line and goes to INSERT mode
---@param ctype integer See |comment.utils.ctype|
function M.insert_above(ctype) ins_on_line(-1, ctype) end

function M.insert_eol(ctype)
    local start_row, start_col = unpack(vim.api.nvim_win_get_cursor(0))
    ---@type MyCommentRange
    local range = {
        start_row = start_row,
        start_col = start_col,
        end_row = start_row,
        end_col = start_col,
    }

    local lcs, rcs = ft.parse_cstr(range, ctype)

    local line = vim.api.nvim_get_current_line()
    local padding = M.get_pad(false) -- TODO could add ' ' conditionally at some point

    -- We need RHS of cstr, if we are doing block comments or if RHS exists
    -- because even in line comment RHS do exists for some filetypes like jsx_element, ocaml
    local if_rcs = #rcs == 0 and rcs or padding .. rcs

    local ecol
    if #line == 0 then
        -- If line is empty, start comment at the correct indentation level
        vim.api.nvim_set_current_line(lcs .. padding .. if_rcs)
        vim.api.nvim_command('normal! ==')
        ecol = #vim.api.nvim_get_current_line() - #if_rcs - 1
    else
        -- NOTE:
        -- 1. Python is the only language that recommends 2 spaces between the statement and the comment
        -- 2. Other than that, I am assuming that the users wants a space b/w the end of line and start of the comment
        local space = vim.bo.filetype == 'python' and '  ' or ' '
        local ll = line .. space .. lcs .. padding
        vim.api.nvim_set_current_line(ll .. if_rcs)
        ecol = #ll - 1
    end

    move_n_insert(start_row, ecol)
end

---Returns the array of commented lines
---
---@param lines string[]
---@param left string Left side of the commentstring
---@param right string Right side of the commentstring
---@param padding boolean Is padding enabled?
---@param start_col? integer Starting column
---@param end_col? integer Ending column
---@return string[]
function M.comment_lines(lines, left, right, padding, start_col, end_col)
    local pad = M.get_pad(padding)
    local ll = #left == 0 and left or (left .. pad)
    local rr = #right == 0 and right or (pad .. right)

    -------------------
    -- for blockwise --
    -------------------
    local first, last = lines[1], lines[#lines]
    -- If both columns are given then we can assume it's a partial block
    if start_col and end_col then
        local sfirst = string.sub(first, 0, start_col)
        local slast = string.sub(first, start_col + 1, -1)
        local efirst = string.sub(last, 0, end_col + 1)
        local elast = string.sub(last, end_col + 2, -1)
        lines[1] = sfirst .. ll .. slast
        lines[#lines] = efirst .. rr .. elast
    else
        lines[1] = #first == 0 and left
            or string.gsub(first, '^(%s*)', '%1' .. vim.pesc(ll))
        lines[#lines] = #last == 0 and right or (last .. rr)
    end
    return lines
end

---Returns the array of uncommented lines
---
---@param lines string[]
---@param left string Left side of the commentstring
---@param right string Right side of the commentstring
---@param padding boolean Is padding enabled?
---@param start_col? integer Starting column
---@param end_col? integer Ending column
---@return string[]
function M.uncomment_lines(lines, left, right, padding, start_col, end_col)
    local pp, plen = M.get_padpat(padding), padding and 1 or 0
    local left_len, right_len = #left + plen, #right + plen
    local ll = #left == 0 and left or vim.pesc(left) .. pp
    local rr = #right == 0 and right or pp .. vim.pesc(right)

    -------------------
    -- for blockwise --
    -------------------
    local first, last = lines[1], lines[#lines]
    -- If both columns are given then we can assume it's a partial block
    if start_col and end_col then
        local sfirst = string.sub(first, 0, start_col)
        local slast = string.sub(first, start_col + left_len + 1, -1)
        local efirst = string.sub(last, 0, end_col - right_len + 1)
        local elast = string.sub(last, end_col + 2, -1)
        lines[1] = sfirst .. slast
        lines[#lines] = efirst .. elast
    else
        lines[1] = string.gsub(first, '^(%s*)' .. ll, '%1')
        lines[#lines] = string.gsub(last, rr .. '$', '')
    end
    return lines
end

--- Uncomment the line
---@param line string the line to uncomment
---@param left string Left side of the commentstring
---@param right string Right side of the commentstring
---@param padding boolean Is padding enabled?
---@param start_col? integer Starting column
---@param end_col? integer Ending column
---@return string
function M.uncomment_line2(line, left, right, padding, start_col, end_col)
    local pp, plen = M.get_padpat(padding), padding and 1 or 0
    local left_len, right_len = #left + plen, #right + plen
    local ll = #left == 0 and left or vim.pesc(left) .. pp
    local rr = #right == 0 and right or pp .. vim.pesc(right)
    local is_lw = not (start_col and start_col)
    local pattern = is_lw and '^(%s*)' .. ll .. '(.-)' .. rr .. '$' or ''

    ------------------
    -- for linewise --
    ------------------
    if is_lw then
        local a, b, c = string.match(line, pattern)
        assert(a and b, { msg = 'Nothing to uncomment!' })
        -- If there is nothing after LHS then just return ''
        -- bcz the line previously (before comment) was empty
        return #b == 0 and b or a .. b .. (c or '')
    end

    --------------------------------
    -- for current-line blockwise --
    --------------------------------
    -- SOURCE: https://github.com/numToStr/Comment.nvim/issues/224
    if end_col > #line then
        return string.sub(line, start_col + left_len + 1, #line - right_len)
    end
    local first = string.sub(line, 0, start_col)
    local mid =
        string.sub(line, start_col + left_len + 1, end_col - right_len + 1)
    local last = string.sub(line, end_col + 2, -1)
    return first .. mid .. last
end

--- Comment the line
---@param line string the line to uncomment
---@param left string Left side of the commentstring
---@param right string Right side of the commentstring
---@param padding boolean Is padding enabled?
---@param start_col? integer Starting column
---@param end_col? integer Ending column
---@param tabbed? boolean Using tab indentation
---@return string
function M.comment_line2(line, left, right, padding, start_col, end_col, tabbed)
    local pad = M.get_pad(padding)
    local ll = #left == 0 and left or (left .. pad)
    local rr = #right == 0 and right or (pad .. right)
    local empty = string.rep(tabbed and '\t' or ' ', start_col or 0)
        .. left
        .. right
    local is_lw = start_col and not end_col

    ------------------
    -- for linewise --
    ------------------
    if is_lw then
        if #line == 0 then return empty end
        -- line == 0 -> start from 0 col
        if start_col == 0 then return (ll .. line .. rr) end
        local first = string.sub(line, 0, start_col)
        local last = string.sub(line, start_col + 1, -1)
        return first .. ll .. last .. rr
    end

    --------------------------------
    -- for current-line blockwise --
    --------------------------------
    -- SOURCE: https://github.com/numToStr/Comment.nvim/issues/224
    if end_col > #line then return ll .. line .. rr end
    local first = string.sub(line, 0, start_col)
    local mid = string.sub(line, start_col + 1, end_col + 1)
    local last = string.sub(line, end_col + 2, -1)
    return first .. ll .. mid .. rr .. last
end

---Returns a closure which is used to uncomment a line
---
---If given {string[]} to the closure then it will block uncomment
---else linewise uncomment will be done with the given {string}
---@param line string the line to uncomment
---@param left string Left side of the commentstring
---@param right string Right side of the commentstring
---@param padding boolean Is padding enabled?
---@return string uncommented_line
function M.uncomment_line(line, left, right, padding)
    local pp = M.get_padpat(padding)
    local ll = #left == 0 and left or vim.pesc(left) .. pp
    local rr = #right == 0 and right or pp .. vim.pesc(right)
    local pattern = '^(%s*)' .. ll .. '(.-)' .. rr .. '$'

    local a, b, c = string.match(line, pattern)

    assert(a and b, { msg = 'Nothing to uncomment!' })
    -- If there is nothing after LHS then just return ''
    -- because the line previously (before comment) was empty
    return #b == 0 and b or a .. b .. (c or '')
end

---Returns a closure which is used to do comments
---
---If given {string[]} to the closure then it will do blockwise comment
---else linewise comment will be done with the given {string}
---@param line string
---@param left string Left side of the commentstring
---@param right string Right side of the commentstring
---@param padding boolean Is padding enabled?
---@param start_col? integer Starting column
---@param tabbed? boolean Using tab indentation
---@return string commented_line
function M.comment_line(line, left, right, padding, start_col, tabbed)
    local pad = M.get_pad(padding)
    local ll = #left == 0 and left or (left .. pad)
    local rr = #right == 0 and right or (pad .. right)
    local empty = string.rep(tabbed and '\t' or ' ', start_col or 0)
        .. left
        .. right

    ------------------
    -- for linewise --
    ------------------
    if #line == 0 then return empty end
    -- line == 0 -> start from 0 col
    if start_col == 0 then return (ll .. line .. rr) end
    local first = string.sub(line, 0, start_col)
    local last = string.sub(line, start_col + 1, -1)
    return first .. ll .. last .. rr
end

---Full/Partial/Current-Line Block commenting
---@param param ToggleCommentParams
---@param partial? boolean Comment the partial region (visual mode)
---@return integer _ Returns a calculated comment mode
function M.toggle_blockwise(param, partial)
    local is_x = #param.lines == 1 -- current-line blockwise

    local padding = false

    local is_cmt
    if is_x then
        local line = param.lines[1]
        local start_col, end_col = param.range.start_col, param.range.end_col
        is_cmt = M.is_commented(
            line,
            param.lcs,
            param.rcs,
            padding,
            start_col,
            end_col
        )
        local modified_line = line
        if is_cmt then
            modified_line = M.uncomment_line2(
                line,
                param.lcs,
                param.rcs,
                padding,
                start_col,
                end_col
            )
        else
            modified_line = M.comment_line2(
                line,
                param.lcs,
                param.rcs,
                padding,
                start_col,
                end_col
            )
        end

        vim.api.nvim_set_current_line(modified_line)
    else
        local lines = param.lines

        local start_col, end_col = nil, nil
        if partial then
            start_col, end_col = param.range.start_col, param.range.end_col
        end
        is_cmt = M.is_commented(
            lines,
            param.lcs,
            param.rcs,
            padding,
            start_col,
            end_col
        )
        if is_cmt then
            lines = M.uncomment_lines(
                lines,
                param.lcs,
                param.rcs,
                padding,
                start_col,
                end_col
            )
        else
            lines = M.comment_lines(
                lines,
                param.lcs,
                param.rcs,
                padding,
                start_col,
                end_col
            )
        end

        vim.api.nvim_buf_set_lines(
            0,
            param.range.start_row - 1,
            param.range.end_row,
            false,
            lines
        )
    end

    return is_cmt and C.cmode.uncomment or C.cmode.comment
end

---Line commenting
---@param param ToggleCommentParams
---@return integer _ Returns a calculated comment mode
function M.toggle_linewise(param)
    local padding = true

    local min_indent = -1
    local tabbed = false
    local cmode = C.cmode.uncomment

    -- Compute the cmode and min_indent:
    ---When commenting multiple line, it is to be expected that indentation should be preserved
    ---So, When looping over multiple lines we need to store the indentation of the minimum length (except empty line)
    ---Which will be used to semantically comment rest of the lines
    for _, line in ipairs(param.lines) do
        -- While commenting a region, there could be lines being both commented and non-commented
        -- So, if any line is uncommented then we should comment the whole block or vise-versa
        if
            cmode == C.cmode.uncomment
            and (not M.is_commented(line, param.lcs, param.rcs, padding))
        then
            cmode = C.cmode.comment
        end

        if #line > 0 then
            local _, len = string.find(line, '^%s*')
            if len ~= nil and (min_indent == -1 or min_indent > len) then
                min_indent = len
                tabbed = string.find(line, '^\t') ~= nil
            end
        end
    end

    if cmode == C.cmode.uncomment then
        for i, line in ipairs(param.lines) do
            param.lines[i] =
                M.uncomment_line(line, param.lcs, param.rcs, padding)
        end
    else
        for i, line in ipairs(param.lines) do
            param.lines[i] = M.comment_line(
                line,
                param.lcs,
                param.rcs,
                padding,
                min_indent,
                tabbed
            )
        end
    end

    vim.api.nvim_buf_set_lines(
        0,
        param.range.start_row - 1,
        param.range.end_row,
        false,
        param.lines
    )

    return cmode
end

---Line commenting with count
---@param count integer Value of |v:count|
---@param ctype integer See |comment.utils.ctype|
function M.toggle_with_count(count, ctype)
    local start_row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local end_row = (start_row + count) - 1
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)

    ---@type MyCommentRange
    local range =
        { start_row = start_row, start_col = 0, end_row = end_row, end_col = 0 }

    local lcs, rcs = ft.parse_cstr(range, ctype)

    ---@type ToggleCommentParams
    local params = {
        lines = lines,
        range = range,
        lcs = lcs,
        rcs = rcs,
    }

    if ctype == C.ctype.blockwise then
        M.toggle_blockwise(params)
    else
        M.toggle_linewise(params)
    end
end

---Vim visual mode enum. Read |visualmode()|
---@alias VisualMode
---| '"v"'
---| '"V"'
---| '\22' -- The termcode for <CTRL-V>
---| '' --Default when visual mode has yet been used

---Toggle (comment/uncomment) the comment for the text selection by a motion
---with a block comment
---@param motion OpMotionMode
function M.comment_toggle_motion_blockwise(motion)
    local range = M.get_region(motion)

    local lines =
        vim.api.nvim_buf_get_lines(0, range.start_row - 1, range.end_row, false)

    if #lines == 0 then return end

    local is_partial = motion == 'char'
    local ctype = C.ctype.blockwise
    local lcs, rcs = ft.parse_cstr(range, ctype)

    ---@type ToggleCommentParams
    local params = {
        lines = lines,
        range = range,
        lcs = lcs,
        rcs = rcs,
    }

    M.toggle_blockwise(params, is_partial)
end

function M.is_only_whitespace_after(line, col)
    -- convert 0 indexed col to 1-indexed in Lua
    local col_one_indexed = col + 1

    local next_char_col = col_one_indexed + 1

    local sub_str = line:sub(next_char_col)
    -- Match if the remainder consists of zero or more whitespace characters only
    return sub_str:match('^%s*$') ~= nil
end

---Toggle (comment/uncomment) the comment for the text selection by a motion
---with a linewise comment (will do a block comment in some situations)
---@param motion OpMotionMode
function M.comment_toggle_motion_linewise(motion)
    local range = M.get_region(motion)

    local lines =
        vim.api.nvim_buf_get_lines(0, range.start_row - 1, range.end_row, false)

    if #lines == 0 then return end

    -- If we are doing char or visual motion on the same line
    -- then we would probably want block comment instead of line comment
    local is_partial = motion == 'char'
    local is_ending_line_comment = range.start_row == range.end_row
        and M.is_only_whitespace_after(lines[1], range.end_col)
    local is_blockx = is_partial
        and range.start_row == range.end_row
        and not is_ending_line_comment
    local ctype = is_blockx and C.ctype.blockwise or C.ctype.linewise
    local lcs, rcs = ft.parse_cstr(range, ctype)

    ---@type ToggleCommentParams
    local params = {
        lines = lines,
        range = range,
        lcs = lcs,
        rcs = rcs,
    }

    if ctype == C.ctype.blockwise then
        M.toggle_blockwise(params, is_partial)
    elseif is_ending_line_comment then
        M.toggle_blockwise(params)
    else
        M.toggle_linewise(params)
    end
end

---Comment/Uncomment visual selection with line comments
---
---Note: this differs from old Comment.nvim in that visual selections
---on a single line are no longer treated as block comments. I didn't like
---the inconsistency.
---@param visual_mode VisualMode
function M.comment_visualmode_linewise(visual_mode)
    local range = M.get_region_from_visual_selection(visual_mode)

    local lines =
        vim.api.nvim_buf_get_lines(0, range.start_row - 1, range.end_row, false)

    if #lines == 0 then return end

    local lcs, rcs = ft.parse_cstr(range, C.ctype.linewise)

    ---@type ToggleCommentParams
    local params = {
        lines = lines,
        range = range,
        lcs = lcs,
        rcs = rcs,
    }

    M.toggle_linewise(params)
end

---Comment/Uncomment visual selection with a block comment
---@param visual_mode VisualMode
function M.comment_visualmode_blockwise(visual_mode)
    local range = M.get_region_from_visual_selection(visual_mode)

    local lines =
        vim.api.nvim_buf_get_lines(0, range.start_row - 1, range.end_row, false)

    if #lines == 0 then return end

    local is_partial = visual_mode == 'v'
    local lcs, rcs = ft.parse_cstr(range, C.ctype.blockwise)

    ---@type ToggleCommentParams
    local params = {
        lines = lines,
        range = range,
        lcs = lcs,
        rcs = rcs,
    }

    M.toggle_blockwise(params, is_partial)
end

---@param motion OpMotionMode
function M.flip_flop_comment(motion)
    --From https://github.com/numToStr/Comment.nvim/issues/17#issuecomment-1268650042

    local range = M.get_region(motion)

    local ll, rr = ft.parse_cstr(range, C.ctype.linewise)
    local padding = true

    local rcom = {} -- ranges of commented lines
    local cl = range.start_row -- current line
    local rs, re = nil, nil -- range start and end
    local lines =
        vim.api.nvim_buf_get_lines(0, range.start_row - 1, range.end_row, false)
    for _, line in ipairs(lines) do
        if #line == 0 or not M.is_commented(line, ll, rr, padding) then -- empty or uncommented line
            if rs ~= nil then
                table.insert(rcom, { rs, re })
                rs, re = nil, nil
            end
        else
            rs = rs or cl -- set range start if not set
            re = cl -- update range end
        end
        cl = cl + 1
    end
    if rs ~= nil then table.insert(rcom, { rs, re }) end

    ---Toggle comments on a range of lines
    ---@param sl integer: starting line
    ---@param el integer: ending line
    local toggle_lines = function(sl, el)
        local sub_range =
            { start_row = sl, start_col = 0, end_row = el, end_col = 0 }

        local sub_range_lines = vim.api.nvim_buf_get_lines(
            0,
            sub_range.start_row - 1,
            sub_range.end_row,
            false
        )

        if #sub_range_lines == 0 then return end

        local lcs, rcs = ft.parse_cstr(sub_range, C.ctype.linewise)

        ---@type ToggleCommentParams
        local params = {
            lines = sub_range_lines,
            range = sub_range,
            lcs = lcs,
            rcs = rcs,
        }

        M.toggle_linewise(params)
    end

    toggle_lines(range.start_row, range.end_row)
    for _, r in ipairs(rcom) do
        toggle_lines(r[1], r[2]) -- uncomment lines twice to remove previous comment
        toggle_lines(r[1], r[2])
    end
end

---@param visual_mode VisualMode
function M.flip_flop_comment_visualmode(visual_mode)
    --From https://github.com/numToStr/Comment.nvim/issues/17#issuecomment-1268650042
    local range = M.get_region_from_visual_selection(visual_mode)
    local ll, rr = ft.parse_cstr(range, C.ctype.linewise)
    local padding = true

    local rcom = {} -- ranges of commented lines
    local cl = range.start_row -- current line
    local rs, re = nil, nil -- range start and end
    local lines =
        vim.api.nvim_buf_get_lines(0, range.start_row - 1, range.end_row, false)
    for _, line in ipairs(lines) do
        if #line == 0 or not M.is_commented(line, ll, rr, padding) then -- empty or uncommented line
            if rs ~= nil then
                table.insert(rcom, { rs, re })
                rs, re = nil, nil
            end
        else
            rs = rs or cl -- set range start if not set
            re = cl -- update range end
        end
        cl = cl + 1
    end
    if rs ~= nil then table.insert(rcom, { rs, re }) end

    ---Toggle comments on a range of lines
    ---@param sl integer: starting line
    ---@param el integer: ending line
    local toggle_lines = function(sl, el)
        local sub_range =
            { start_row = sl, start_col = 0, end_row = el, end_col = 0 }

        local sub_range_lines = vim.api.nvim_buf_get_lines(
            0,
            sub_range.start_row - 1,
            sub_range.end_row,
            false
        )

        if #sub_range_lines == 0 then return end

        local lcs, rcs = ft.parse_cstr(sub_range, C.ctype.linewise)

        ---@type ToggleCommentParams
        local params = {
            lines = sub_range_lines,
            range = sub_range,
            lcs = lcs,
            rcs = rcs,
        }

        M.toggle_linewise(params)
    end

    toggle_lines(range.start_row, range.end_row)
    for _, r in ipairs(rcom) do
        toggle_lines(r[1], r[2]) -- uncomment lines twice to remove previous comment
        toggle_lines(r[1], r[2])
    end
end

---Select the comment lines that would have been created by the gc operator
---Equivalent to the default gc text object but uses numToStr/Comment.nvim
function M.comment_lines_textobject()
    local lnum_cur = vim.fn.line('.')
    local cnum_cur = vim.fn.col('.')

    ---@type MyCommentRange
    local range = {
        start_row = lnum_cur,
        start_col = cnum_cur,
        end_row = lnum_cur,
        end_col = cnum_cur,
    }
    local ll, rr = ft.parse_cstr(range, C.ctype.linewise)
    local padding = true

    local is_plugin_linewise_comment =
        M.is_commented(vim.fn.getline(lnum_cur), ll, rr, padding)

    if not is_plugin_linewise_comment then return end

    -- Compute commented range
    local lnum_from = lnum_cur
    while
        (lnum_from >= 2)
        and M.is_commented(vim.fn.getline(lnum_from - 1), ll, rr, padding)
    do
        lnum_from = lnum_from - 1
    end

    local lnum_to = lnum_cur
    local n_lines = vim.api.nvim_buf_line_count(0)
    while
        (lnum_to <= n_lines - 1)
        and M.is_commented(vim.fn.getline(lnum_to + 1), ll, rr, padding)
    do
        lnum_to = lnum_to + 1
    end

    vim.cmd([[normal! ]] .. lnum_from .. [[G^v]] .. lnum_to .. [[Gg_]])
end

local function get_treesitter_comment_node_at_cursor()
    local node = vim.treesitter.get_node({ ignore_injections = false })

    if node == nil then return nil end

    if node:type():lower() == 'comment' then return node end

    local parent_node = node:parent()
    if parent_node ~= nil and parent_node:type():lower() == 'comment' then
        return parent_node
    end

    return nil
end

--- Select contiguous commented lines at cursor
--- based on https://github.com/neovim/neovim/blob/3c53e8f78511d6db9a6c804e5a479ba38c33102d/runtime/lua/vim/_comment.lua#L233-L256
---  https://thevaluable.dev/vim-create-text-objects/
---  https://neovim.discourse.group/t/lua-function-to-perform-visual-line-selection/4425
---  https://vi.stackexchange.com/a/43692
---  https://www.reddit.com/r/neovim/comments/18w9rwv/comment/kfwknp3/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
function M.around_comment_lines_textobject()
    local lnum_cur = vim.fn.line('.')
    local cnum_cur = vim.fn.col('.')

    ---@type MyCommentRange
    local range = {
        start_row = lnum_cur,
        start_col = cnum_cur,
        end_row = lnum_cur,
        end_col = cnum_cur,
    }
    local ll, rr = ft.parse_cstr(range, C.ctype.linewise)

    local padding = true

    local is_linewise_comment =
        M.is_commented(vim.fn.getline(lnum_cur), ll, rr, padding)
    local comment_node = get_treesitter_comment_node_at_cursor()

    if not is_linewise_comment and comment_node ~= nil then
        -- I am unsure if the "<count>|" keymap goes to the byte or column. I am assuming column for now
        -- but if I am wrong I will need to change the parameters to the treesitter range method to get
        -- back the byte number
        local lnum_from, cnum_from, lnum_to, cnum_to = comment_node:range()
        lnum_from = lnum_from + 1 -- change from 0 base indexing to 1 based indexing
        lnum_to = lnum_to + 1 -- change from 0 base indexing to 1 based indexing
        cnum_from = cnum_from + 1

        vim.cmd([[normal! :noh]]) -- enter normal mode (no idea why this makes it work)
        vim.cmd(
            [[normal ]]
                .. lnum_from
                .. [[G]]
                .. cnum_from
                .. [[|v]]
                .. lnum_to
                .. [[G]]
                .. cnum_to
                .. [[|]]
        )
        return
    elseif not is_linewise_comment and comment_node == nil then
        return
    end

    -- Compute commented range
    local lnum_from = lnum_cur
    while
        (lnum_from >= 2)
        and M.is_commented(vim.fn.getline(lnum_from - 1), ll, rr, padding)
    do
        lnum_from = lnum_from - 1
    end

    local lnum_to = lnum_cur
    local n_lines = vim.api.nvim_buf_line_count(0)
    while
        (lnum_to <= n_lines - 1)
        and M.is_commented(vim.fn.getline(lnum_to + 1), ll, rr, padding)
    do
        lnum_to = lnum_to + 1
    end

    vim.cmd([[normal! :noh]]) -- enter normal mode (no idea why this makes it work)
    vim.cmd([[normal ]] .. lnum_from .. [[G^v]] .. lnum_to .. [[Gg_]])
end

return M
