local C = require('myconfig.comment.constants')
local ft = require('myconfig.comment.ft')

local M = {}

---Params for checking if a line is commented
---with the given comment string parts
---@class MyIsLineCommentParams
---@field line string line
---@field lcs string LHS of commentstring
---@field rcs string RHS of commentstring
---@field padding_pattern string the lua regex pattern for the padding

---Params for checking if the given lines are all
---line comments with the given comment string parts
---@class MyIsLinewiseCommentParams
---@field lines string[] lines
---@field lcs string LHS of commentstring
---@field rcs string RHS of commentstring
---@field padding_pattern string the lua regex pattern for the padding

---The params for determining if the line selection is a block
---comment
---@class MyIsBlockwiseCommentParams
---@field lines string[] List of lines
---@field lcs string LHS of commentstring
---@field rcs string RHS of commentstring
---@field padding_pattern string the lua regex pattern for the padding
---@field start_col? integer Starting column (0 indexed)
---@field end_col? integer Ending column (0 indexed)

---The params for the megalith "is comment" function
---that has all the wierd edgecases so that
---it can be used by the comment toggling function
---@class MyIsCommentParams
---@field lines string[] List of lines
---@field lcs string LHS of commentstring
---@field rcs string RHS of commentstring
---@field padding_pattern string the lua regex pattern for the padding
---@field start_col? integer Starting column (0 indexed)
---@field end_col? integer Ending column (0 indexed)
---@field ctype integer ctype linewise or blockwise

---Params for commenting a selection
---@class MyCommentParams
---@field lines string[] List of lines
---@field lcs string LHS of commentstring
---@field rcs string RHS of commentstring
---@field is_block boolean will only comment edges if true
---@field start_col? integer Starting column (0 indexed)
---@field end_col? integer Ending column (0 indexed)
---@field add_padding? boolean | fun(context:table):boolean (default: false) TODO workout context

---Params for uncommenting a selection
---@class MyUncommentParams
---@field lines string[] List of lines
---@field lcs string LHS of commentstring
---@field rcs string RHS of commentstring
---@field is_block boolean will only uncomment edges if true
---@field start_col? integer Starting column (0 indexed)
---@field end_col? integer Ending column (0 indexed)
---@field add_padding? boolean | fun(context:table):boolean (default: false) TODO workout context

---Toggle Comment Params
---@class MyToggleCommentParams
---@field lines string[] List of lines
---@field lcs string LHS of commentstring
---@field rcs string RHS of commentstring
---@field start_col? integer Starting column (0 indexed)
---@field end_col? integer Ending column (0 indexed)
---@field partial? boolean Comment the partial region (visual mode)
---@field ctype integer ctype linewise or blockwise

---Params for commenting a selection in a buffer
---@class MyCommentBufParams : MyCommentParams
---@field bufnr uinteger buffer to operate on
---@field start_row integer Starting row (1 indexed)
---@field end_row integer Ending row (1 indexed)

---Params for uncommenting a selection in a buffer
---@class MyUncommentBufParams : MyUncommentParams
---@field bufnr uinteger buffer to operate on
---@field start_row integer Starting row (1 indexed)
---@field end_row integer Ending row (1 indexed)

---Params for toggling a comment in a buffer
---@class MyToggleCommentBufParams : MyToggleCommentParams
---@field bufnr uinteger buffer to operate on
---@field start_row integer Starting row (1 indexed)
---@field end_row integer Ending row (1 indexed)

---Toggle Comment Params
---@class MyFlipFlopCommentBufParams
---@field bufnr uinteger buffer to operate on
---@field lines string[] List of lines
---@field lcs string LHS of commentstring
---@field rcs string RHS of commentstring
---@field range My01IndexedBufferRange

---@class MyInsertCommentOnLineBufParams
---@field bufnr uinteger buffer to operate on
---@field lcs string LHS of commentstring
---@field rcs string RHS of commentstring
---@field start_row integer Starting row (1 indexed)
---@field add_padding? boolean | fun(context:table):boolean (default: false) TODO workout context

---@class MyInsertCommentAtEofBufParams
---@field bufnr uinteger buffer to operate on
---@field lcs string LHS of commentstring
---@field rcs string RHS of commentstring
---@field start_row integer Starting row (1 indexed)
---@field add_padding? boolean | fun(context:table):boolean (default: false) TODO workout context

---Check if the given string is commented or not
---with the given comment string parts
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/opfunc.lua?plain=1#L135
---@param params MyIsLineCommentParams
---@return boolean
function M.is_line_commented(params)
    local ll = #params.lcs == 0 and params.lcs
        or '^%s*' .. vim.pesc(params.lcs) .. params.padding_pattern
    local rr = #params.rcs == 0 and params.rcs
        or params.padding_pattern .. vim.pesc(params.rcs) .. '$'
    local pattern = ll .. '.-' .. rr

    return string.find(params.line, pattern) ~= nil
end

---Checks if all the selected lines are commented as linewise comment
---using the given comment string parts
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/opfunc.lua?plain=1#L148
---@param params MyIsLinewiseCommentParams
function M.is_linewise_comment(params)
    for _, line in ipairs(params.lines) do
        -- While commenting a region, there could be a mix lines commented and non-commented.
        -- If any line is uncommented, then we should comment the whole block or vise-versa
        if
            not M.is_line_commented({
                line = line,
                lcs = params.lcs,
                rcs = params.rcs,
                padding_pattern = params.padding_pattern,
            })
        then
            return false
        end
    end
    return true
end

---Checks if all the selected lines are commented as linewise comment
---using the given comment string parts
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/utils.lua#L332
---but refactored to behave based on my needs
---@param params MyIsBlockwiseCommentParams
function M.is_blockwise_comment(params)
    local is_full = params.start_col == nil or params.end_col == nil
    local ll = #params.lcs == 0 and params.lcs
        or '^%s*' .. vim.pesc(params.lcs) .. params.padding_pattern
    local rr = #params.rcs == 0 and params.rcs
        or params.padding_pattern .. vim.pesc(params.rcs) .. '$'
    local first_line = params.lines[1]

    if #params.lines == 1 and is_full then
        local pattern = ll .. '.-' .. rr
        return string.find(first_line, pattern) ~= nil
    elseif #params.lines == 1 then
        local pattern = ll .. '.-' .. rr
        --------------------------------
        -- for current-line blockwise --
        --------------------------------
        -- SOURCE: https://github.com/numToStr/Comment.nvim/issues/224
        return string.find(
            string.sub(
                first_line,
                params.start_col + 1,
                (
                    params.end_col > #first_line and #first_line
                    or params.end_col + 1
                )
            ),
            pattern
        ) ~= nil
    end

    local last_line = params.lines[#params.lines]
    if is_full then
        return (string.find(first_line, ll) and string.find(last_line, rr))
            ~= nil
    else
        return (
            string.find(string.sub(first_line, params.start_col + 1, -1), ll)
            and string.find(string.sub(last_line, 0, params.end_col + 1), rr)
        ) ~= nil
    end
end

---Checks if the selection is commented
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/utils.lua#L332
---but refactored to behave based on my needs
---@param params MyIsCommentParams
function M.is_comment(params)
    if params.ctype == C.ctype.linewise then
        return M.is_linewise_comment({
            lines = params.lines,
            lcs = params.lcs,
            rcs = params.rcs,
            padding_pattern = params.padding_pattern,
        })
    elseif params.ctype == C.ctype.blockwise then
        return M.is_blockwise_comment({
            lines = params.lines,
            lcs = params.lcs,
            rcs = params.rcs,
            padding_pattern = params.padding_pattern,
            start_col = params.start_col,
            end_col = params.end_col,
        })
    else
        error('invalid ctype')
    end
end

---Comments the list of lines
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/api.lua?plain=1#L134
---and https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/utils.lua#L198
---but refactored out the metamagic
---@param params MyCommentParams
---@return string[] commented lines
function M.comment(params)
    local lcs = params.lcs
    local rcs = params.rcs
    local add_padding = vim.nonnil(params.add_padding, false)
    assert(add_padding ~= nil, 'asserting for typechecking xD!')
    if type(add_padding) == 'function' then
        add_padding = add_padding({
            -- TODO add context
        })
    end
    local pad = require('myconfig.comment.utils').get_pad(add_padding)
    local ll = #lcs == 0 and lcs or (lcs .. pad)
    local rr = #rcs == 0 and rcs or (pad .. rcs)

    local commented_lines = {}

    if params.is_block then
        assert(
            rcs ~= nil,
            string.format(
                'rcs must not be nil for block comments. CommentParams: %s',
                vim.inspect(params)
            )
        )
        commented_lines = vim.deepcopy(params.lines)

        local first_line = params.lines[1]
        local last_line = params.lines[#params.lines]
        if #params.lines == 1 and params.end_col > #first_line then
            commented_lines[1] = ll .. first_line .. rr
        elseif #params.lines == 1 then
            local first = string.sub(first_line, 0, params.start_col)
            local mid =
                string.sub(first_line, params.start_col + 1, params.end_col + 1)
            local last = string.sub(first_line, params.end_col + 2, -1)
            commented_lines[1] = first .. ll .. mid .. rr .. last
        elseif params.start_col and params.end_col then
            --TODO gb visual is off by plus one on both columns

            -- If both columns are given then we can assume it's a partial block
            local start_col = params.start_col
            local end_col = params.end_col
            local sfirst = string.sub(first_line, 0, start_col)
            local slast = string.sub(first_line, start_col + 1, -1)
            local efirst = string.sub(last_line, 0, end_col + 1)
            local elast = string.sub(last_line, end_col + 2, -1)
            commented_lines[1] = sfirst .. ll .. slast
            commented_lines[#commented_lines] = efirst .. rr .. elast
        else
            commented_lines[1] = #first_line == 0 and lcs
                or string.gsub(first_line, '^(%s*)', '%1' .. vim.pesc(ll))
            commented_lines[#commented_lines] = #last_line == 0 and rcs
                or (last_line .. rr)
        end
    else
        local min_indent = -1
        local tabbed = false

        -- Compute the cmode and min_indent:
        ---When commenting multiple line, it is to be expected that indentation should be preserved
        ---So, When looping over multiple lines we need to store the indentation of the minimum length (except empty line)
        ---Which will be used to semantically comment rest of the lines
        for _, line in ipairs(params.lines) do
            if #line > 0 then
                local _, len = string.find(line, '^%s*')
                if len ~= nil and (min_indent == -1 or min_indent > len) then
                    min_indent = len
                    tabbed = string.find(line, '^\t') ~= nil
                end
            end
        end
        min_indent = math.max(min_indent, 0)

        for i, line in ipairs(params.lines) do
            if #line == 0 then
                local empty = string.rep(tabbed and '\t' or ' ', min_indent)
                    .. lcs
                    .. rcs
                commented_lines[i] = empty
            elseif min_indent == 0 then
                commented_lines[i] = (ll .. line .. rr)
            else
                local first = string.sub(line, 0, min_indent)
                local last = string.sub(line, min_indent + 1, -1)
                commented_lines[i] = first .. ll .. last .. rr
            end
        end
    end

    return commented_lines
end

---Uncomments the list of lines
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/api.lua?plain=1#L158
---and https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/utils.lua#L266
---but refactored out the metamagic
---@param params MyUncommentParams
---@return string[] uncommented lines
function M.uncomment(params)
    local lcs = params.lcs
    local rcs = params.rcs
    local add_padding = vim.nonnil(params.add_padding, false)
    assert(add_padding ~= nil, 'asserting for typechecking xD!')
    if type(add_padding) == 'function' then
        add_padding = add_padding({
            -- TODO add context
        })
    end
    local padding_pattern =
        require('myconfig.comment.utils').get_padpat(add_padding)
    local ll = #lcs == 0 and lcs or vim.pesc(lcs) .. padding_pattern
    local rr = #rcs == 0 and rcs or padding_pattern .. vim.pesc(rcs)

    local uncommented_lines = {}

    if params.is_block then
        assert(
            rcs ~= nil,
            string.format(
                'rcs must not be nil for block comments. UncommentParams: %s',
                vim.inspect(params)
            )
        )
        uncommented_lines = vim.deepcopy(params.lines)
        local pad_len = add_padding and 1 or 0
        local left_len, right_len = #lcs + pad_len, #rcs + pad_len

        local first_line = uncommented_lines[1]
        local last_line = uncommented_lines[#uncommented_lines]
        if #params.lines == 1 and params.end_col > #first_line then
            uncommented_lines[1] = string.sub(
                first_line,
                params.start_col + left_len + 1,
                #first_line - right_len
            )
        elseif #params.lines == 1 then
            local first = string.sub(first_line, 0, params.start_col)
            local mid = string.sub(
                first_line,
                params.start_col + left_len + 1,
                params.end_col - right_len + 1
            )
            local last = string.sub(first_line, params.end_col + 2, -1)
            uncommented_lines[1] = first .. mid .. last
        elseif params.start_col and params.end_col then
            local start_col = params.start_col
            local end_col = params.end_col
            local sfirst = string.sub(first_line, 0, start_col)
            local slast = string.sub(first_line, start_col + left_len + 1, -1)
            local efirst = string.sub(last_line, 0, end_col - right_len + 1)
            local elast = string.sub(last_line, end_col + 2, -1)
            uncommented_lines[1] = sfirst .. slast
            uncommented_lines[#uncommented_lines] = efirst .. elast
        else
            uncommented_lines[1] = string.gsub(first_line, '^(%s*)' .. ll, '%1')
            uncommented_lines[#uncommented_lines] =
                string.gsub(last_line, rr .. '$', '')
        end
    else
        -- TODO previously for single line comments when `not (start_col and start_col)`
        -- the pattern would be set to empty string but not sure why
        local pattern = '^(%s*)' .. ll .. '(.-)' .. rr .. '$'
        for i, line in ipairs(params.lines) do
            local a, b, c = string.match(line, pattern)

            assert(a and b, { msg = 'Nothing to uncomment!' })
            -- If there is nothing after LHS then just return ''
            -- because the line previously (before comment) was empty
            uncommented_lines[i] = #b == 0 and b or a .. b .. (c or '')
        end
    end

    return uncommented_lines
end

---Toggles the comment in the line array (does not modify buffer)
---
---based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/api.lua?plain=1#L110
---but has all the metamagic refactored out and doesn't modify the buffer
---@param params MyToggleCommentParams
---@return string[] lines after toggling comment
---@return integer cmode after toggling comment
function M.toggle_comment(params)
    local padding = params.ctype == C.ctype.linewise
    local padding_pattern =
        require('myconfig.comment.utils').get_padpat(padding)

    local start_col = nil
    local end_col = nil
    if
        params.ctype == C.ctype.blockwise
        and (#params.lines == 1 or params.partial)
    then
        start_col = params.start_col
        end_col = params.end_col
    end

    local is_cmt = M.is_comment({
        ctype = params.ctype,
        lines = params.lines,
        lcs = params.lcs,
        rcs = params.rcs,
        padding_pattern = padding_pattern,
        start_col = start_col,
        end_col = end_col,
    })

    local modified_lines = params.lines
    if is_cmt then
        local is_block = params.ctype == C.ctype.blockwise
            and (#params.lines ~= 1 or start_col ~= nil)
        modified_lines = M.uncomment({
            lines = params.lines,
            lcs = params.lcs,
            rcs = params.rcs,
            is_block = is_block,
            start_col = start_col,
            end_col = end_col,
            add_padding = padding,
        })
    else
        local is_block = params.ctype == C.ctype.blockwise
            and (#params.lines ~= 1 or start_col == nil or end_col ~= nil)
        modified_lines = M.comment({
            lines = params.lines,
            lcs = params.lcs,
            rcs = params.rcs,
            is_block = is_block,
            start_col = start_col,
            end_col = end_col,
            add_padding = padding,
        })
    end
    local new_cmode = is_cmt and C.cmode.uncomment or C.cmode.comment
    return modified_lines, new_cmode
end

---Comments the selection in the buffer
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/api.lua?plain=1#L134
---but refactored out the metamagic
---@param params MyCommentBufParams
function M.comment_buf(params)
    local bufnr = params.bufnr
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    local modified_lines = M.comment({
        lines = params.lines,
        lcs = params.lcs,
        rcs = params.rcs,
        is_block = params.is_block,
        start_col = params.start_col,
        end_col = params.end_col,
        add_padding = params.add_padding,
    })
    vim.api.nvim_buf_set_lines(
        bufnr,
        params.start_row - 1,
        params.end_row,
        false,
        modified_lines
    )
end

---Uncomments the comment in the buffer
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/api.lua?plain=1#L158
---but refactored out the metamagic
---@param params MyUncommentBufParams
function M.uncomment_buf(params)
    local bufnr = params.bufnr
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    local modified_lines = M.uncomment({
        lines = params.lines,
        lcs = params.lcs,
        rcs = params.rcs,
        is_block = params.is_block,
        start_col = params.start_col,
        end_col = params.end_col,
        add_padding = params.add_padding,
    })
    vim.api.nvim_buf_set_lines(
        bufnr,
        params.start_row - 1,
        params.end_row,
        false,
        modified_lines
    )
end

---Toggles the comment in a buffer
---
---based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/api.lua?plain=1#L110
---but has all the metamagic refactored out
---@param params MyToggleCommentBufParams
---@return integer cmode after toggling comment
function M.toggle_comment_buf(params)
    local bufnr = params.bufnr
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    local modified_lines, new_cmode = M.toggle_comment({
        lines = params.lines,
        lcs = params.lcs,
        rcs = params.rcs,
        start_col = params.start_col,
        end_col = params.end_col,
        partial = params.partial,
        ctype = params.ctype,
    })
    vim.api.nvim_buf_set_lines(
        bufnr,
        params.start_row - 1,
        params.end_row,
        false,
        modified_lines
    )

    return new_cmode
end

---Flips blocks of commented and uncommented lines
---so that the commented sections become uncommented
---and the commented sections become commented.
---Operates on the buffer so there is no return value
---
---Modifies the lines in the buffer
---
---Based on https://github.com/numToStr/Comment.nvim/issues/17#issuecomment-1268650042
---@param params MyFlipFlopCommentBufParams
function M.flip_flop_comment_buf(params)
    local bufnr = params.bufnr
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    local commented_regions = {} -- ranges of commented lines
    local range_start_row = params.range.start_row -- current line
    local lcs = params.lcs
    local rcs = params.rcs
    local padding = true
    local padding_pattern =
        require('myconfig.comment.utils').get_padpat(padding)

    local rs, re = nil, nil -- range start and end
    for _, line in ipairs(params.lines) do
        if
            #line == 0
            or not M.is_line_commented({
                line = line,
                lcs = lcs,
                rcs = rcs,
                padding_pattern = padding_pattern,
            })
        then -- empty or uncommented line
            if rs ~= nil then
                table.insert(commented_regions, { rs, re })
                rs, re = nil, nil
            end
        else
            rs = rs or range_start_row -- set range start if not set
            re = range_start_row -- update range end
        end
        range_start_row = range_start_row + 1
    end
    if rs ~= nil then table.insert(commented_regions, { rs, re }) end

    ---Toggle comments on a range of lines
    ---@param start_row integer: starting line
    ---@param end_row integer: ending line
    local toggle_lines = function(start_row, end_row)
        local sub_range_lines =
            vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, false)

        if #sub_range_lines == 0 then return end

        local _ = M.toggle_comment_buf({
            bufnr = bufnr,
            lines = sub_range_lines,
            lcs = lcs,
            rcs = rcs,
            start_row = start_row,
            end_row = end_row,
            start_col = 0,
            end_col = 0,
            partial = false,
            ctype = C.ctype.linewise,
        })
    end

    toggle_lines(params.range.start_row, params.range.end_row)
    for _, r in ipairs(commented_regions) do
        toggle_lines(r[1], r[2]) -- uncomment lines twice to remove previous comment
        toggle_lines(r[1], r[2])
    end
end

---Adds a comment line below the start_row and returns the position you would want
---the cursor to be if you wanted start typing in it
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/extra.lua?plain=1#L23
---modified so that it can run from other windows and so that
---it doesn't change the cursor or mode
---@param params MyInsertCommentOnLineBufParams
---@return [integer, integer] insert_pos # (row, col) tuple (1, 0) indexed
function M.insert_comment_on_line_buf(params)
    local bufnr = params.bufnr
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    local add_padding = vim.nonnil(params.add_padding, false)
    assert(add_padding ~= nil, 'asserting for typechecking xD!')
    if type(add_padding) == 'function' then
        add_padding = add_padding({
            -- TODO add context
        })
    end

    local padding = require('myconfig.comment.utils').get_pad(add_padding)

    local left = params.lcs .. padding
    local right = #params.rcs == 0 and params.rcs or padding .. params.rcs

    vim.api.nvim_buf_set_lines(
        bufnr,
        params.start_row,
        params.start_row,
        false,
        { left .. right }
    )

    ---The position the cursor should be set to if you want to immediately be
    ---able to start typing inside the new comment
    local insert_pos = vim._with({ buf = bufnr }, function()
        vim.api.nvim_win_set_cursor(0, { params.start_row + 1, 0 })
        vim.api.nvim_command('normal! ==') --used to fix indentation
        return {
            params.start_row + 1,
            #vim.api.nvim_get_current_line() - #right - 1,
        }
    end)
    return insert_pos
end

---Adds a comment line below the start_row and returns the position you would want
---the cursor to be if you wanted start typing in it
---
---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/extra.lua?plain=1#L66
---modified so that it can run from other windows and so that
---it doesn't change the cursor or mode
---@param params MyInsertCommentAtEofBufParams
---@return [integer, integer] insert_pos # (row, col) tuple (1, 0) indexed
function M.insert_comment_at_eol_buf(params)
    local bufnr = params.bufnr
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    local add_padding = vim.nonnil(params.add_padding, false)
    assert(add_padding ~= nil, 'asserting for typechecking xD!')
    if type(add_padding) == 'function' then
        add_padding = add_padding({
            -- TODO add context
        })
    end

    local padding = require('myconfig.comment.utils').get_pad(add_padding)

    local lines = vim.api.nvim_buf_get_lines(
        bufnr,
        params.start_row - 1,
        params.start_row,
        false
    )
    local line = lines[1]

    local left = params.lcs .. padding
    local right = #params.rcs == 0 and params.rcs or padding .. params.rcs

    if #line == 0 then
        vim.api.nvim_buf_set_lines(
            bufnr,
            params.start_row - 1,
            params.start_row,
            false,
            { left .. right }
        )
        -- If line is empty, start comment at the correct indentation level
        local insert_pos = vim._with({ buf = bufnr }, function()
            vim.api.nvim_win_set_cursor(0, { params.start_row, 0 })
            vim.api.nvim_command('normal! ==') --used to fix indentation
            return {
                params.start_row,
                #vim.api.nvim_get_current_line() - #right - 1,
            }
        end)
        return insert_pos
    else
        -- NOTE:
        -- old comment.nvim added two spaces between a line with python
        -- code and the eof comment so we will do the same (supposedly that's
        -- what python recommends)
        local space = vim.bo.filetype == 'python' and '  ' or ' '
        local ll = line .. space .. params.lcs .. padding

        vim.api.nvim_buf_set_lines(
            bufnr,
            params.start_row - 1,
            params.start_row,
            false,
            { ll .. right }
        )

        return { params.start_row, #ll - 1 }
    end
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
function M.select_around_comment_lines_textobject()
    local lnum_cur = vim.fn.line('.')
    local cnum_cur = vim.fn.col('.')
    if cnum_cur ~= vim.v.maxcol then
        cnum_cur = cnum_cur - 1 --convert from 1 indexed to 0 indexed
    end

    ---@type My01IndexedBufferRange
    local range = {
        start_row = lnum_cur,
        start_col = cnum_cur,
        end_row = lnum_cur,
        end_col = cnum_cur,
    }
    local lcs, rcs = ft.parse_cstr(range, 'line')

    local padding = true
    local padding_pattern =
        require('myconfig.comment.utils').get_padpat(padding)

    local is_linewise_comment = M.is_line_commented({
        line = vim.fn.getline(lnum_cur),
        lcs = lcs,
        rcs = rcs,
        padding_pattern = padding_pattern,
    })
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
        and M.is_line_commented({
            line = vim.fn.getline(lnum_from - 1),
            lcs = lcs,
            rcs = rcs,
            padding_pattern = padding_pattern,
        })
    do
        lnum_from = lnum_from - 1
    end

    local lnum_to = lnum_cur
    local n_lines = vim.api.nvim_buf_line_count(0)
    while
        (lnum_to <= n_lines - 1)
        and M.is_line_commented({
            line = vim.fn.getline(lnum_to + 1),
            lcs = lcs,
            rcs = rcs,
            padding_pattern = padding_pattern,
        })
    do
        lnum_to = lnum_to + 1
    end

    vim.cmd([[normal! :noh]]) -- enter normal mode (no idea why this makes it work)
    vim.cmd([[normal ]] .. lnum_from .. [[G^v]] .. lnum_to .. [[Gg_]])
end

---Select the comment lines that would have been created by the gc operator
---Equivalent to the default gc text object but uses my comment code
function M.select_comment_lines_textobject()
    local lnum_cur = vim.fn.line('.')
    local cnum_cur = vim.fn.col('.')
    if cnum_cur ~= vim.v.maxcol then
        cnum_cur = cnum_cur - 1 --convert from 1 indexed to 0 indexed
    end

    local lcs, rcs = ft.parse_cstr({
        start_row = lnum_cur,
        start_col = cnum_cur,
        end_row = lnum_cur,
        end_col = cnum_cur,
    }, 'line')

    local padding = true
    local padding_pattern =
        require('myconfig.comment.utils').get_padpat(padding)

    local is_plugin_linewise_comment = M.is_line_commented({
        line = vim.fn.getline(lnum_cur),
        lcs = lcs,
        rcs = rcs,
        padding_pattern = padding_pattern,
    })

    if not is_plugin_linewise_comment then return end

    -- Compute commented range
    local lnum_from = lnum_cur
    while
        (lnum_from >= 2)
        and M.is_line_commented({
            line = vim.fn.getline(lnum_from - 1),
            lcs = lcs,
            rcs = rcs,
            padding_pattern = padding_pattern,
        })
    do
        lnum_from = lnum_from - 1
    end

    local lnum_to = lnum_cur
    local n_lines = vim.api.nvim_buf_line_count(0)
    while
        (lnum_to <= n_lines - 1)
        and M.is_line_commented({
            line = vim.fn.getline(lnum_to + 1),
            lcs = lcs,
            rcs = rcs,
            padding_pattern = padding_pattern,
        })
    do
        lnum_to = lnum_to + 1
    end

    vim.cmd([[normal! ]] .. lnum_from .. [[G^v]] .. lnum_to .. [[Gg_]])
end

return M
