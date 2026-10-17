local M = {}

local ft = require('myconfig.comment.ft')
local C = require('myconfig.comment.constants')
local function is_only_whitespace_after(line, col)
    -- convert 0 indexed col to 1-indexed in Lua
    local col_one_indexed = col + 1

    local next_char_col = col_one_indexed + 1

    local sub_str = line:sub(next_char_col)
    -- Match if the remainder consists of zero or more whitespace characters only
    return sub_str:match('^%s*$') ~= nil
end

function M.setup_comment_keymaps()
    vim.keymap.del({ 'o', 'n', 'x' }, 'gc')

    vim.keymap.set('n', 'gc', function()
        ---Toggle (comment/uncomment) the comment for the text selection by a motion
        ---with a linewise comment (will do a block comment in some situations)
        ---
        ---based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/init.lua#L100

        vim.go.operatorfunc = function(motion)
            local bufnr = vim.api.nvim_get_current_buf()
            local position = vim.api.nvim_win_get_cursor(0)

            local range = require('myconfig.utils.misc').get_region(motion)

            local lines = vim.api.nvim_buf_get_lines(
                bufnr,
                range.start_row - 1,
                range.end_row,
                false
            )

            if #lines == 0 then return end

            -- If we are doing char or visual motion on the same line
            -- then we would probably want block comment instead of line comment
            local is_partial = motion == 'char'
            local is_ending_line_comment = is_partial
                and range.start_row == range.end_row
                and is_only_whitespace_after(lines[1], range.end_col)
            local is_blockx = is_partial
                and range.start_row == range.end_row
                and not is_ending_line_comment

            local comment_string_type = is_blockx and 'block' or 'line'
            local lcs, rcs = ft.parse_cstr(range, comment_string_type)

            --TODO refactor
            if is_blockx then
                require('myconfig.comment.api').toggle_comment_buf({
                    bufnr = bufnr,
                    lines = lines,
                    lcs = lcs,
                    rcs = rcs,
                    start_row = range.start_row,
                    end_row = range.end_row,
                    start_col = range.start_col,
                    end_col = range.end_col,
                    partial = is_partial,
                    ctype = C.ctype.blockwise,
                })
            elseif is_ending_line_comment then
                -- TODO refactor to add padding to end of line comments
                require('myconfig.comment.api').toggle_comment_buf({
                    bufnr = bufnr,
                    lines = lines,
                    lcs = lcs,
                    rcs = rcs,
                    start_row = range.start_row,
                    end_row = range.end_row,
                    start_col = range.start_col,
                    end_col = range.end_col,
                    partial = false,
                    ctype = C.ctype.blockwise,
                })
            else
                require('myconfig.comment.api').toggle_comment_buf({
                    bufnr = bufnr,
                    lines = lines,
                    lcs = lcs,
                    rcs = rcs,
                    start_row = range.start_row,
                    end_row = range.end_row,
                    start_col = range.start_col,
                    end_col = range.end_col,
                    partial = false,
                    ctype = C.ctype.linewise,
                })
            end

            vim.api.nvim_win_set_cursor(0, position)
        end
        return 'g@' -- operator pending
    end, {
        expr = true,
        desc = 'Comment toggle linewise (or blockwise in some contexts)',
    })

    vim.keymap.set('n', 'gb', function()
        -- Toggles the block comment
        -- based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/init.lua#L101
        vim.go.operatorfunc = function(motion)
            local bufnr = vim.api.nvim_get_current_buf()
            local position = vim.api.nvim_win_get_cursor(0)

            local range = require('myconfig.utils.misc').get_region(motion)

            local lines = vim.api.nvim_buf_get_lines(
                bufnr,
                range.start_row - 1,
                range.end_row,
                false
            )

            if #lines == 0 then return end

            local is_partial = motion == 'char'
            local lcs, rcs = ft.parse_cstr(range, 'block')

            require('myconfig.comment.api').toggle_comment_buf({
                bufnr = bufnr,
                lines = lines,
                lcs = lcs,
                rcs = rcs,
                start_row = range.start_row,
                end_row = range.end_row,
                start_col = range.start_col,
                end_col = range.end_col,
                partial = is_partial,
                ctype = C.ctype.blockwise,
            })

            vim.api.nvim_win_set_cursor(0, position)
        end
        return 'g@' -- operator pending
    end, { expr = true, desc = 'Comment toggle blockwise' })

    vim.keymap.set('n', 'gcc', function()
        --toggles the linewise comment on the line (or lines if count)
        --based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/init.lua#L103

        --TODO counts often don't work if keymap isn't typed fast enough because
        --of issue https://github.com/folke/which-key.nvim/issues/824
        --There is a fix for it https://github.com/folke/which-key.nvim/pull/1073
        local count = vim.v.count1

        vim.go.operatorfunc = function(_)
            local bufnr = vim.api.nvim_get_current_buf()
            local position = vim.api.nvim_win_get_cursor(0)

            local start_row, _ = unpack(position)
            local end_row = (start_row + count) - 1
            ---@type My01IndexedBufferRange
            local range = {
                start_row = start_row,
                start_col = 0,
                end_row = end_row,
                end_col = 0,
            }

            local lines = vim.api.nvim_buf_get_lines(
                bufnr,
                range.start_row - 1,
                range.end_row,
                false
            )

            if #lines == 0 then return end

            local lcs, rcs = ft.parse_cstr(range, 'line')

            require('myconfig.comment.api').toggle_comment_buf({
                bufnr = bufnr,
                lines = lines,
                lcs = lcs,
                rcs = rcs,
                start_row = range.start_row,
                end_row = range.end_row,
                start_col = range.start_col,
                end_col = range.end_col,
                partial = false,
                ctype = C.ctype.linewise,
            })

            vim.api.nvim_win_set_cursor(0, position)
        end
        return 'g@l'
    end, {
        expr = true,
        desc = 'Comment: toggle comment the line (or lines if count)',
    })

    vim.keymap.set('n', 'gbc', function()
        --toggles the blockwise comment on the line (or lines if count)
        --based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/init.lua#L107

        -- Note: convention would dictate that this keymap would be 'gbb'
        -- but since b is a useful motion we will use c instead making
        -- the keymap gbb so that gbb still works for commenting on the b motion

        --TODO counts often don't work if keymap isn't typed fast enough because
        --of issue https://github.com/folke/which-key.nvim/issues/824
        --There is a fix for it https://github.com/folke/which-key.nvim/pull/1073
        local count = vim.v.count1

        vim.go.operatorfunc = function(_)
            local bufnr = vim.api.nvim_get_current_buf()
            local position = vim.api.nvim_win_get_cursor(0)

            local start_row, _ = unpack(vim.api.nvim_win_get_cursor(0))
            local end_row = (start_row + count) - 1
            ---@type My01IndexedBufferRange
            local range = {
                start_row = start_row,
                start_col = 0,
                end_row = end_row,
                end_col = 0,
            }

            local lines = vim.api.nvim_buf_get_lines(
                bufnr,
                range.start_row - 1,
                range.end_row,
                false
            )

            if #lines == 0 then return end

            local lcs, rcs = ft.parse_cstr(range, 'block')

            require('myconfig.comment.api').toggle_comment_buf({
                bufnr = bufnr,
                lines = lines,
                lcs = lcs,
                rcs = rcs,
                start_row = range.start_row,
                end_row = range.end_row,
                start_col = range.start_col,
                end_col = range.end_col,
                partial = false,
                -- Important: We linewise the event though we use block comments
                ctype = C.ctype.linewise,
            })

            vim.api.nvim_win_set_cursor(0, position)
        end
        return 'g@l'
    end, {
        expr = true,
        desc = 'Comment: toggle comment using block comments but commented linewise over count',
    })

    vim.keymap.set(
        { 'o' },
        'gc',
        function()
            require('myconfig.comment.api').select_comment_lines_textobject()
        end,
        { desc = 'Comment: textobject identical to gc operator' }
        --Note: vgc does not select the commented lines. It really does a block
        --comment around the character (which in my opinion pretty useless so I might
        --try to fix that) this is because it isn't using the textobject gc it is using
        --the gc visual mapping
    )

    vim.keymap.set('x', 'gc', function()
        ---Comment/Uncomment visual selection with line comments
        ---
        ---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/init.lua#L116
        ---
        ---Note: this differs from old Comment.nvim in that visual selections
        ---on a single line are no longer treated as block comments. I didn't like
        ---the inconsistency.

        local bufnr = vim.api.nvim_get_current_buf()
        local position = vim.api.nvim_win_get_cursor(0)

        local visual_mode = vim.api.nvim_get_mode().mode
        local range =
            require('myconfig.utils.misc').get_region_from_visual_selection(
                visual_mode
            )

        local lines = vim.api.nvim_buf_get_lines(
            bufnr,
            range.start_row - 1,
            range.end_row,
            false
        )

        if #lines == 0 then return end

        local lcs, rcs = ft.parse_cstr(range, 'line')

        require('myconfig.comment.api').toggle_comment_buf({
            bufnr = bufnr,
            lines = lines,
            lcs = lcs,
            rcs = rcs,
            start_row = range.start_row,
            end_row = range.end_row,
            start_col = range.start_col,
            end_col = range.end_col,
            partial = false,
            ctype = C.ctype.linewise,
        })
        --Old Comment.nvim did not restore position because it ran the `gc` and `gb`
        --keymaps as dot repeatable functions and needed the cursor at the top since it
        --was used to toggle the selected comment without having to reselect the visual
        --selection. It just was very sensitive to the cursor position. We don't need
        --worry about that now that the keymap isn't dot repeatable so we will restore
        --postion so this behaves more how I like it.
        vim.api.nvim_win_set_cursor(0, position)
    end, {
        desc = 'Comment: toggle linewise (visual)',
    })

    vim.keymap.set('x', 'gb', function()
        ---Comment/Uncomment visual selection with a block comment
        ---
        ---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/init.lua#L122

        local bufnr = vim.api.nvim_get_current_buf()
        local position = vim.api.nvim_win_get_cursor(0)

        local visual_mode = vim.api.nvim_get_mode().mode
        local range =
            require('myconfig.utils.misc').get_region_from_visual_selection(
                visual_mode
            )

        local lines = vim.api.nvim_buf_get_lines(
            bufnr,
            range.start_row - 1,
            range.end_row,
            false
        )

        if #lines == 0 then return end

        local is_partial = visual_mode == 'v'
        local lcs, rcs = ft.parse_cstr(range, 'block')

        require('myconfig.comment.api').toggle_comment_buf({
            bufnr = bufnr,
            lines = lines,
            lcs = lcs,
            rcs = rcs,
            start_row = range.start_row,
            end_row = range.end_row,
            start_col = range.start_col,
            end_col = range.end_col,
            partial = is_partial,
            ctype = C.ctype.blockwise,
        })
        --Old Comment.nvim did not restore position because it ran the `gc` and `gb`
        --keymaps as dot repeatable functions and needed the cursor at the top since it
        --was used to toggle the selected comment without having to reselect the visual
        --selection. It just was very sensitive to the cursor position. We don't need
        --worry about that now that the keymap isn't dot repeatable so we will restore
        --postion so this behaves more how I like it.
        vim.api.nvim_win_set_cursor(0, position)
    end, {
        desc = 'Comment: toggle blockwise (visual)',
    })

    vim.keymap.set({ 'n' }, 'gC', function()
        vim.go.operatorfunc = function(motion)
            local position = vim.api.nvim_win_get_cursor(0)

            local range = require('myconfig.utils.misc').get_region(motion)

            local lines = vim.api.nvim_buf_get_lines(
                0,
                range.start_row - 1,
                range.end_row,
                false
            )

            if #lines == 0 then return end

            local lcs, rcs = ft.parse_cstr(range, 'line')

            require('myconfig.comment.api').flip_flop_comment_buf({
                bufnr = vim.api.nvim_get_current_buf(),
                lines = lines,
                lcs = lcs,
                rcs = rcs,
                range = range,
            })

            vim.api.nvim_win_set_cursor(0, position)
        end
        return 'g@'
    end, {
        desc = 'Comment: Flip Flop line comments on operator (dot repeatable)',
        expr = true,
    })

    vim.keymap.set({ 'n' }, 'gCc', function()
        --TODO counts often don't work if keymap isn't typed fast enough because
        --of issue https://github.com/folke/which-key.nvim/issues/824
        --There is a fix for it https://github.com/folke/which-key.nvim/pull/1073
        local count = vim.v.count1
        vim.go.operatorfunc = function(_)
            local position = vim.api.nvim_win_get_cursor(0)

            local start_row, _ = unpack(position)
            local end_row = (start_row + count) - 1
            ---@type My01IndexedBufferRange
            local range = {
                start_row = start_row,
                start_col = 0,
                end_row = end_row,
                end_col = 0,
            }

            local lines = vim.api.nvim_buf_get_lines(
                0,
                range.start_row - 1,
                range.end_row,
                false
            )

            if #lines == 0 then return end

            local lcs, rcs = ft.parse_cstr(range, 'line')

            require('myconfig.comment.api').flip_flop_comment_buf({
                bufnr = vim.api.nvim_get_current_buf(),
                lines = lines,
                lcs = lcs,
                rcs = rcs,
                range = range,
            })

            vim.api.nvim_win_set_cursor(0, position)
        end
        return 'g@l'
    end, {
        desc = 'Comment: Flip Flop line comments with counts (dot repeatable)',
        expr = true,
    })

    vim.keymap.set({ 'x' }, 'gC', function()
        local position = vim.api.nvim_win_get_cursor(0)

        local visual_mode = vim.api.nvim_get_mode().mode

        local range =
            require('myconfig.utils.misc').get_region_from_visual_selection(
                visual_mode
            )

        local lines = vim.api.nvim_buf_get_lines(
            0,
            range.start_row - 1,
            range.end_row,
            false
        )

        if #lines == 0 then return end

        local lcs, rcs = ft.parse_cstr(range, 'line')

        require('myconfig.comment.api').flip_flop_comment_buf({
            bufnr = vim.api.nvim_get_current_buf(),
            lines = lines,
            lcs = lcs,
            rcs = rcs,
            range = range,
        })

        vim.api.nvim_win_set_cursor(0, position)
    end, {
        desc = 'Comment: Flip Flop line comments in visual selection',
    })

    vim.keymap.set('n', 'gco', function()
        ---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/init.lua#L129

        local row, col = unpack(vim.api.nvim_win_get_cursor(0))

        local lcs, rcs = ft.parse_cstr(
            { start_row = row, start_col = col, end_row = row, end_col = col },
            'line'
        )

        local insert_pos =
            require('myconfig.comment.api').insert_comment_on_line_buf({
                bufnr = vim.api.nvim_get_current_buf(),
                lcs = lcs,
                rcs = rcs,
                start_row = row,
                add_padding = true,
            })

        vim.api.nvim_win_set_cursor(0, insert_pos)
        --insert using `a` key so that it puts the in the correct spot when the insert_pos
        --is the last character
        vim.api.nvim_feedkeys('a', 'ni', true)
    end, { desc = 'Comment: insert below' })

    vim.keymap.set('n', 'gcO', function()
        ---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/init.lua#L130

        local row, col = unpack(vim.api.nvim_win_get_cursor(0))

        local lcs, rcs = ft.parse_cstr(
            { start_row = row, start_col = col, end_row = row, end_col = col },
            'line'
        )

        local insert_pos =
            require('myconfig.comment.api').insert_comment_on_line_buf({
                bufnr = vim.api.nvim_get_current_buf(),
                lcs = lcs,
                rcs = rcs,
                start_row = row - 1,
                add_padding = true,
            })
        vim.api.nvim_win_set_cursor(0, insert_pos)
        --insert using `a` key so that it puts the in the correct spot when the insert_pos
        --is the last character
        vim.api.nvim_feedkeys('a', 'ni', true)
    end, { desc = 'Comment: insert above' })

    vim.keymap.set('n', 'gcA', function()
        ---Based on https://github.com/numToStr/Comment.nvim/blob/e30b7f2008e52442154b66f7c519bfd2f1e32acb/lua/Comment/init.lua#L131

        local row, col = unpack(vim.api.nvim_win_get_cursor(0))

        local lcs, rcs = ft.parse_cstr(
            { start_row = row, start_col = col, end_row = row, end_col = col },
            'line'
        )

        local insert_pos =
            require('myconfig.comment.api').insert_comment_at_eol_buf({
                bufnr = vim.api.nvim_get_current_buf(),
                lcs = lcs,
                rcs = rcs,
                start_row = row,
                add_padding = true,
            })
        vim.api.nvim_win_set_cursor(0, insert_pos)
        --insert using `a` key so that it puts the in the correct spot when the insert_pos
        --is the last character
        vim.api.nvim_feedkeys('a', 'ni', true)
    end, { desc = 'Comment: insert end of line' })

    vim.keymap.set(
        { 'o', 'x' },
        --ugh so I would love all these comment textobjects to have the same
        --namespaces but I also like being able to do vagcgc to uncomment a group
        --of comments
        'agc',
        function()
            require('myconfig.comment.api').select_around_comment_lines_textobject()
        end,
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

return M
