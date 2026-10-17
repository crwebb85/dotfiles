---Run with `:BustedFile %`
---or `BustedDirectory nvim\tests\ {}`

local C = require('myconfig.comment.constants')
local busted = require('myconfig.test_harness.busted')

local describe = busted.describe
local it = busted.it
-- local pending = busted.pending
-- local before_each = busted.before_each
-- local after_each = busted.after_each
-- local clear = busted.clear
local assert = busted.assert

-- assert.is_not_nil(list)
-- assert.are.same(expected, list)

describe('Comment', function()
    it('linewise inner parentheses', function()
        ---@type MyCommentParams
        local params = {
            add_padding = true,
            is_block = false,
            lcs = '--',
            rcs = '',
            lines = {
                "        'Error during safe execution: ' .. err .. init_trace,",
                '        vim.log.levels.WARN',
            },
        }

        local expected = {
            "        -- 'Error during safe execution: ' .. err .. init_trace,",
            '        -- vim.log.levels.WARN',
        }
        local commented_lines = require('myconfig.comment.api').comment(params)
        assert.are.same(expected, commented_lines)
    end)

    it('linewise on line', function()
        ---@type MyCommentParams
        local params = {
            add_padding = true,
            is_block = false,
            lcs = '--',
            rcs = '',
            lines = {
                "        'Error during safe execution: ' .. err .. init_trace,",
            },
        }

        local expected = {
            "        -- 'Error during safe execution: ' .. err .. init_trace,",
        }
        local commented_lines = require('myconfig.comment.api').comment(params)
        assert.are.same(expected, commented_lines)
    end)

    it('blockwise (gbiW)', function()
        ---@type MyCommentParams
        local params = {
            add_padding = false,
            is_block = true,
            lcs = '--[[',
            rcs = ']]',
            lines = {
                "        'Error during safe execution: ' .. err .. init_trace,",
            },
            start_col = 43,
            end_col = 45,
        }

        local expected = {
            "        'Error during safe execution: ' .. --[[err]] .. init_trace,",
        }
        local commented_lines = require('myconfig.comment.api').comment(params)
        assert.are.same(expected, commented_lines)
    end)

    it('blockwise with counts (4gbc)', function()
        ---@type MyCommentParams
        local params = {
            add_padding = true,
            is_block = false,
            lcs = '--[[',
            rcs = ']]',
            lines = {
                "        'Error during safe execution: ' .. err .. init_trace,",
                '        vim.log.levels.WARN',
                '    )',
                '    return false',
            },
        }

        local expected = {
            "    --[[     'Error during safe execution: ' .. err .. init_trace, ]]",
            '    --[[     vim.log.levels.WARN ]]',
            '    --[[ ) ]]',
            '    --[[ return false ]]',
        }
        local commented_lines = require('myconfig.comment.api').comment(params)
        assert.are.same(expected, commented_lines)
    end)

    it('line comment to end of line (gc$)', function()
        ---@type MyCommentParams
        local params = {
            add_padding = false,
            is_block = true,
            lcs = '--',
            rcs = '',
            lines = {
                "        'Error during safe execution: ' .. err .. init_trace,",
            },
            start_col = 47,
            end_col = 60,
        }

        local expected = {
            "        'Error during safe execution: ' .. err --.. init_trace,",
        }
        local commented_lines = require('myconfig.comment.api').comment(params)
        assert.are.same(expected, commented_lines)
    end)
end)

describe('Uncomment', function()
    it('linewise inner parentheses', function()
        ---@type MyUncommentParams
        local params = {
            add_padding = true,
            is_block = false,
            lcs = '--',
            rcs = '',
            lines = {
                "        -- 'Error during safe execution: ' .. err .. init_trace,",
                '        -- vim.log.levels.WARN',
            },
        }

        local expected = {
            "        'Error during safe execution: ' .. err .. init_trace,",
            '        vim.log.levels.WARN',
        }
        local commented_lines =
            require('myconfig.comment.api').uncomment(params)
        assert.are.same(expected, commented_lines)
    end)

    it('linewise line', function()
        ---@type MyUncommentParams
        local params = {
            add_padding = true,
            is_block = false,
            lcs = '--',
            rcs = '',
            lines = {
                "        -- 'Error during safe execution: ' .. err .. init_trace,",
            },
        }

        local expected =
            { "        'Error during safe execution: ' .. err .. init_trace," }
        local commented_lines =
            require('myconfig.comment.api').uncomment(params)
        assert.are.same(expected, commented_lines)
    end)

    it('blockwise (gbiW)', function()
        ---@type MyUncommentParams
        local params = {
            add_padding = false,
            is_block = true,
            lcs = '--[[',
            rcs = ']]',
            lines = {
                "        'Error during safe execution: ' .. --[[err]] .. init_trace,",
            },
            start_col = 43,
            end_col = 51,
        }

        local expected = {
            "        'Error during safe execution: ' .. err .. init_trace,",
        }
        local commented_lines =
            require('myconfig.comment.api').uncomment(params)
        assert.are.same(expected, commented_lines)
    end)

    it('blockwise (4gbc)', function()
        ---@type MyUncommentParams
        local params = {
            add_padding = true,
            is_block = false,
            lcs = '--[[',
            rcs = ']]',
            lines = {
                "    --[[     'Error during safe execution: ' .. err .. init_trace, ]]",
                '    --[[     vim.log.levels.WARN ]]',
                '    --[[ ) ]]',
                '    --[[ return false ]]',
            },
        }

        local expected = {
            "        'Error during safe execution: ' .. err .. init_trace,",
            '        vim.log.levels.WARN',
            '    )',
            '    return false',
        }
        local commented_lines =
            require('myconfig.comment.api').uncomment(params)
        assert.are.same(expected, commented_lines)
    end)

    it('uncomment end of line comment (gc$)', function()
        ---@type MyUncommentParams
        local params = {
            add_padding = false,
            is_block = true,
            lcs = '--',
            rcs = '',
            lines = {
                "        'Error during safe execution: ' .. err --.. init_trace,",
            },
            start_col = 47,
            end_col = 62,
        }

        local expected =
            { "        'Error during safe execution: ' .. err .. init_trace," }
        local commented_lines =
            require('myconfig.comment.api').uncomment(params)
        assert.are.same(expected, commented_lines)
    end)
end)

describe('Toggle Comment', function()
    it('linewise inner parentheses to comment', function()
        ---@type MyToggleCommentParams
        local params = {
            ctype = 1,
            lcs = '--',
            rcs = '',
            lines = {
                "        'Error during safe execution: ' .. err .. init_trace,",
                '        vim.log.levels.WARN',
            },
            partial = false,
            start_col = 0,
            end_col = 0,
        }

        local expected = {
            "        -- 'Error during safe execution: ' .. err .. init_trace,",
            '        -- vim.log.levels.WARN',
        }
        local toggled_lines, cmode =
            require('myconfig.comment.api').toggle_comment(params)
        assert.are.same(expected, toggled_lines)
        assert.are.same(C.cmode.comment, cmode)
    end)

    it('linewise inner parentheses to uncomment', function()
        ---@type MyToggleCommentParams
        local params = {
            ctype = 1,
            lcs = '--',
            rcs = '',
            lines = {
                "        -- 'Error during safe execution: ' .. err .. init_trace,",
                '        -- vim.log.levels.WARN',
            },
            partial = false,
            start_col = 0,
            end_col = 0,
        }

        local expected = {
            "        'Error during safe execution: ' .. err .. init_trace,",
            '        vim.log.levels.WARN',
        }
        local toggled_lines, cmode =
            require('myconfig.comment.api').toggle_comment(params)
        assert.are.same(expected, toggled_lines)
        assert.are.same(C.cmode.uncomment, cmode)
    end)

    it('linewise on line to comment', function()
        ---@type MyToggleCommentParams
        local params = {
            ctype = 1,
            lcs = '--',
            rcs = '',
            lines = {
                "        'Error during safe execution: ' .. err .. init_trace,",
            },
            partial = false,
            start_col = 0,
            end_col = 0,
        }

        local expected = {
            "        -- 'Error during safe execution: ' .. err .. init_trace,",
        }
        local toggled_lines, cmode =
            require('myconfig.comment.api').toggle_comment(params)
        assert.are.same(expected, toggled_lines)
        assert.are.same(C.cmode.comment, cmode)
    end)

    it('linewise on line to uncomment', function()
        ---@type MyToggleCommentParams
        local params = {
            ctype = 1,
            lcs = '--',
            rcs = '',
            lines = {
                "        -- 'Error during safe execution: ' .. err .. init_trace,",
            },
            partial = false,
            start_col = 0,
            end_col = 0,
        }

        local expected =
            { "        'Error during safe execution: ' .. err .. init_trace," }
        local toggled_lines, cmode =
            require('myconfig.comment.api').toggle_comment(params)
        assert.are.same(expected, toggled_lines)
        assert.are.same(C.cmode.uncomment, cmode)
    end)

    it('blockwise (gbiW) to comment', function()
        ---@type MyToggleCommentParams
        local params = {
            ctype = 2,
            lcs = '--[[',
            rcs = ']]',
            lines = {
                "        'Error during safe execution: ' .. err .. init_trace,",
            },
            partial = true,
            start_col = 43,
            end_col = 45,
        }

        local expected = {
            "        'Error during safe execution: ' .. --[[err]] .. init_trace,",
        }
        local toggled_lines, cmode =
            require('myconfig.comment.api').toggle_comment(params)
        assert.are.same(expected, toggled_lines)
        assert.are.same(C.cmode.comment, cmode)
    end)

    it('blockwise (gbiW) to uncomment', function()
        ---@type MyToggleCommentParams
        local params = {
            ctype = 2,
            lcs = '--[[',
            rcs = ']]',
            lines = {
                "        'Error during safe execution: ' .. --[[err]] .. init_trace,",
            },
            partial = true,
            start_col = 43,
            end_col = 51,
        }

        local expected = {
            "        'Error during safe execution: ' .. err .. init_trace,",
        }
        local toggled_lines, cmode =
            require('myconfig.comment.api').toggle_comment(params)
        assert.are.same(expected, toggled_lines)
        assert.are.same(C.cmode.uncomment, cmode)
    end)

    it('blockwise (4gbc) to comment', function()
        ---@type MyToggleCommentParams
        local params = {
            ctype = 1,
            lcs = '--[[',
            rcs = ']]',
            lines = {
                "        'Error during safe execution: ' .. err .. init_trace,",
                '        vim.log.levels.WARN',
                '    )',
                '    return false',
            },
            partial = false,
            start_col = 0,
            end_col = 0,
        }

        local expected = {
            "    --[[     'Error during safe execution: ' .. err .. init_trace, ]]",
            '    --[[     vim.log.levels.WARN ]]',
            '    --[[ ) ]]',
            '    --[[ return false ]]',
        }
        local toggled_lines, cmode =
            require('myconfig.comment.api').toggle_comment(params)
        assert.are.same(expected, toggled_lines)
        assert.are.same(C.cmode.comment, cmode)
    end)

    it('blockwise (4gbc) to uncomment', function()
        ---@type MyToggleCommentParams
        local params = {
            ctype = 1,
            lcs = '--[[',
            rcs = ']]',
            lines = {
                "    --[[     'Error during safe execution: ' .. err .. init_trace, ]]",
                '    --[[     vim.log.levels.WARN ]]',
                '    --[[ ) ]]',
                '    --[[ return false ]]',
            },
            partial = false,
            start_col = 0,
            end_col = 0,
        }

        local expected = {
            "        'Error during safe execution: ' .. err .. init_trace,",
            '        vim.log.levels.WARN',
            '    )',
            '    return false',
        }
        local toggled_lines, cmode =
            require('myconfig.comment.api').toggle_comment(params)
        assert.are.same(expected, toggled_lines)
        assert.are.same(C.cmode.uncomment, cmode)
    end)

    it('linewise (gc$) to comment', function()
        ---@type MyToggleCommentParams
        local params = {
            ctype = 2,
            lcs = '--',
            rcs = '',
            lines = {
                "        'Error during safe execution: ' .. err .. init_trace,",
            },
            partial = false,
            start_col = 47,
            end_col = 60,
        }

        local expected = {
            "        'Error during safe execution: ' .. err --.. init_trace,",
        }
        local toggled_lines, cmode =
            require('myconfig.comment.api').toggle_comment(params)
        assert.are.same(expected, toggled_lines)
        assert.are.same(C.cmode.comment, cmode)
    end)

    it('linewise (gc$) to uncomment', function()
        ---@type MyToggleCommentParams
        local params = {
            ctype = 2,
            lcs = '--',
            rcs = '',
            lines = {
                "        'Error during safe execution: ' .. err --.. init_trace,",
            },
            partial = false,
            start_col = 47,
            end_col = 62,
        }

        local expected =
            { "        'Error during safe execution: ' .. err .. init_trace," }
        local toggled_lines, cmode =
            require('myconfig.comment.api').toggle_comment(params)
        assert.are.same(expected, toggled_lines)
        assert.are.same(C.cmode.uncomment, cmode)
    end)
end)

describe('is_linewise_comment', function()
    it('for linewise comment', function()
        ---@type MyIsLinewiseCommentParams
        local params = {
            lcs = '--',
            rcs = '',
            lines = {
                "        -- 'Error during safe execution: ' .. err .. init_trace,",
                '        -- vim.log.levels.WARN',
            },
            padding_pattern = require('myconfig.comment.utils').get_padpat(
                true
            ),
        }

        local is_comment =
            require('myconfig.comment.api').is_linewise_comment(params)
        assert.is_true(is_comment)
    end)

    it('for linewise comment missing padding', function()
        ---@type MyIsLinewiseCommentParams
        local params = {
            lcs = '--',
            rcs = '',
            lines = {
                "        -- 'Error during safe execution: ' .. err .. init_trace,",
                '        --vim.log.levels.WARN',
            },
            padding_pattern = require('myconfig.comment.utils').get_padpat(
                true
            ),
        }

        local is_comment =
            require('myconfig.comment.api').is_linewise_comment(params)
        assert.is_true(is_comment)
    end)

    it(
        'for linewise comment missing padding when not using padding pattern',
        function()
            ---@type MyIsLinewiseCommentParams
            local params = {
                lcs = '--',
                rcs = '',
                lines = {
                    "        -- 'Error during safe execution: ' .. err .. init_trace,",
                    '        --vim.log.levels.WARN',
                },
                padding_pattern = require('myconfig.comment.utils').get_padpat(
                    false
                ),
            }

            local is_comment =
                require('myconfig.comment.api').is_linewise_comment(params)
            assert.is_true(is_comment)
        end
    )

    it('for linewise comment with block comment string', function()
        ---@type MyIsLinewiseCommentParams
        local params = {
            lcs = '--[[',
            rcs = ']]',
            lines = {
                "        --[['Error during safe execution: ' .. err .. init_trace,]]",
                '        --[[vim.log.levels.WARN]]',
            },
            padding_pattern = require('myconfig.comment.utils').get_padpat(
                false
            ),
        }

        local is_comment =
            require('myconfig.comment.api').is_linewise_comment(params)
        assert.is_true(is_comment)
    end)

    it('for uncommented selection', function()
        ---@type MyIsLinewiseCommentParams
        local params = {
            lcs = '--',
            rcs = '',
            lines = {
                "        'Error during safe execution: ' .. err .. init_trace,",
                '        vim.log.levels.WARN',
            },
            padding_pattern = require('myconfig.comment.utils').get_padpat(
                true
            ),
        }

        local is_comment =
            require('myconfig.comment.api').is_linewise_comment(params)
        assert.is_false(is_comment)
    end)

    it('for partially commented selection', function()
        ---@type MyIsLinewiseCommentParams
        local params = {
            lcs = '--',
            rcs = '',
            lines = {
                "        'Error during safe execution: ' .. err .. init_trace,",
                '        -- vim.log.levels.WARN',
            },
            padding_pattern = require('myconfig.comment.utils').get_padpat(
                true
            ),
        }

        local is_comment =
            require('myconfig.comment.api').is_linewise_comment(params)
        assert.is_false(is_comment)
    end)
end)
