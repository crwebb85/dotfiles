local busted = require('myconfig.test_harness.busted')

local describe = busted.describe
local it = busted.it
local before_each = busted.before_each
local after_each = busted.after_each
local assert = busted.assert

local test_buffer_lines = {
    'local function fizz_buzz(i)',
    '    if i % 15 == 0 then',
    "        print('FizzBuzz')",
    '    elseif i % 3 == 0 then',
    "        print('Fizz')",
    '    elseif i % 5 == 0 then',
    "        print('Buzz')",
    '    else',
    '        print(i)',
    '    end',
    'end',
    '',
    'for i = 1, 100 do',
    '    fizz_buzz(i)',
    'end',
}

-- local function assert_buf_keymap_exists(bufnr, mode, lhs)
--     local maps = vim.api.nvim_buf_get_keymap(bufnr, mode)
--     local found = false
--     for _, map in ipairs(maps) do
--         if map.lhs == lhs then
--             found = true
--             break
--         end
--     end
--     assert.is_true(found)
-- end

local function assert_keymap_exists(mode, lhs)
    local maps = vim.api.nvim_get_keymap(mode)
    local found = false
    for _, map in ipairs(maps) do
        if map.lhs == lhs then
            found = true
            break
        end
    end
    assert.is_true(found)
end
local function feedkeys(keys)
    local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.api.nvim_feedkeys(termcodes, 'x', false)
end

describe('normal mode gcc keymap', function()
    local bufnr

    before_each(function()
        -- Create a new scratch buffer
        -- require('myconfig.comment.comment').setup_keymaps()
        bufnr = vim.api.nvim_create_buf(false, true)
        vim.bo[bufnr].filetype = 'lua'
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, test_buffer_lines)
        vim.api.nvim_win_set_buf(0, bufnr)
    end)

    after_each(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end)

    it('is registered', function() assert_keymap_exists('n', 'gcc') end)

    it('comments/uncomments the line when triggered', function()
        local lines_before_keymap =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        -- Make sure test buffer starts with expected text
        local expected_starting_lines = test_buffer_lines
        assert.same(expected_starting_lines, lines_before_keymap)

        -- Move cursor to line 1
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        local pos = vim.api.nvim_win_get_cursor(0)
        assert.same({ 1, 0 }, pos)

        -- Simulate pressing the keymap using normal mode feedkeys
        feedkeys('gcc')

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        local expected_commented_lines = {
            '-- local function fizz_buzz(i)',
            '    if i % 15 == 0 then',
            "        print('FizzBuzz')",
            '    elseif i % 3 == 0 then',
            "        print('Fizz')",
            '    elseif i % 5 == 0 then',
            "        print('Buzz')",
            '    else',
            '        print(i)',
            '    end',
            'end',
            '',
            'for i = 1, 100 do',
            '    fizz_buzz(i)',
            'end',
        }
        assert.same(expected_commented_lines, lines)

        -- Trigger again to uncomment
        feedkeys('gcc')

        local lines_after_uncomment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local expected_uncommented_lines = test_buffer_lines
        assert.same(expected_uncommented_lines, lines_after_uncomment)
    end)

    it('comments/uncomments the line with count triggered', function()
        local lines_before_keymap =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        -- Make sure test buffer starts with expected text
        local expected_starting_lines = test_buffer_lines
        assert.same(expected_starting_lines, lines_before_keymap)

        -- Move cursor to line 1
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        local pos = vim.api.nvim_win_get_cursor(0)
        assert.same({ 1, 0 }, pos)

        -- Simulate pressing the keymap using normal mode feedkeys
        feedkeys('4gcc')

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        local expected_commented_lines = {
            '-- local function fizz_buzz(i)',
            '--     if i % 15 == 0 then',
            "--         print('FizzBuzz')",
            '--     elseif i % 3 == 0 then',
            "        print('Fizz')",
            '    elseif i % 5 == 0 then',
            "        print('Buzz')",
            '    else',
            '        print(i)',
            '    end',
            'end',
            '',
            'for i = 1, 100 do',
            '    fizz_buzz(i)',
            'end',
        }
        assert.same(expected_commented_lines, lines)

        -- Trigger again to uncomment
        feedkeys('4gcc')

        local lines_after_uncomment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local expected_uncommented_lines = test_buffer_lines
        assert.same(expected_uncommented_lines, lines_after_uncomment)
    end)

    it('comments/uncomments the line with count and dot repeat', function()
        local lines_before_keymap =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        -- Make sure test buffer starts with expected text
        local expected_starting_lines = test_buffer_lines
        assert.same(expected_starting_lines, lines_before_keymap)

        -- Move cursor to line 1
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        local pos = vim.api.nvim_win_get_cursor(0)
        assert.same({ 1, 0 }, pos)

        -- Simulate pressing the keymap using normal mode feedkeys
        feedkeys('4gcc')

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        local expected_commented_lines = {
            '-- local function fizz_buzz(i)',
            '--     if i % 15 == 0 then',
            "--         print('FizzBuzz')",
            '--     elseif i % 3 == 0 then',
            "        print('Fizz')",
            '    elseif i % 5 == 0 then',
            "        print('Buzz')",
            '    else',
            '        print(i)',
            '    end',
            'end',
            '',
            'for i = 1, 100 do',
            '    fizz_buzz(i)',
            'end',
        }
        assert.same(expected_commented_lines, lines)

        -- Trigger again to uncomment
        feedkeys('.')

        local lines_after_uncomment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local expected_uncommented_lines = test_buffer_lines
        assert.same(expected_uncommented_lines, lines_after_uncomment)

        -- Trigger again to comment
        feedkeys('.')

        local lines_after_second_comment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        assert.same(expected_commented_lines, lines_after_second_comment)
    end)
end)

describe('normal mode gbc keymap', function()
    local bufnr

    before_each(function()
        -- Create a new scratch buffer
        require('myconfig.comment.keymaps').setup_comment_keymaps()
        bufnr = vim.api.nvim_create_buf(false, true)
        vim.bo[bufnr].filetype = 'lua'
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, test_buffer_lines)
        vim.api.nvim_win_set_buf(0, bufnr)
    end)

    after_each(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end)

    it('is registered', function() assert_keymap_exists('n', 'gbc') end)

    it('comments/uncomments the line when triggered', function()
        local lines_before_keymap =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        -- Make sure test buffer starts with expected text
        local expected_starting_lines = test_buffer_lines
        assert.same(expected_starting_lines, lines_before_keymap)

        -- Move cursor to line 1
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        local pos = vim.api.nvim_win_get_cursor(0)
        assert.same({ 1, 0 }, pos)

        -- Simulate pressing the keymap using normal mode feedkeys
        feedkeys('gbc')

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        local expected_commented_lines = {
            '--[[ local function fizz_buzz(i) ]]',
            '    if i % 15 == 0 then',
            "        print('FizzBuzz')",
            '    elseif i % 3 == 0 then',
            "        print('Fizz')",
            '    elseif i % 5 == 0 then',
            "        print('Buzz')",
            '    else',
            '        print(i)',
            '    end',
            'end',
            '',
            'for i = 1, 100 do',
            '    fizz_buzz(i)',
            'end',
        }
        assert.same(expected_commented_lines, lines)

        -- Trigger again to uncomment
        feedkeys('gbc')

        local lines_after_uncomment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local expected_uncommented_lines = test_buffer_lines
        assert.same(expected_uncommented_lines, lines_after_uncomment)
    end)

    it('comments/uncomments the line with count triggered', function()
        local lines_before_keymap =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        -- Make sure test buffer starts with expected text
        local expected_starting_lines = test_buffer_lines
        assert.same(expected_starting_lines, lines_before_keymap)

        -- Move cursor to line 1
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        local pos = vim.api.nvim_win_get_cursor(0)
        assert.same({ 1, 0 }, pos)

        -- Simulate pressing the keymap using normal mode feedkeys
        feedkeys('4gbc')

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        local expected_commented_lines = {
            '--[[ local function fizz_buzz(i) ]]',
            '--[[     if i % 15 == 0 then ]]',
            "--[[         print('FizzBuzz') ]]",
            '--[[     elseif i % 3 == 0 then ]]',
            "        print('Fizz')",
            '    elseif i % 5 == 0 then',
            "        print('Buzz')",
            '    else',
            '        print(i)',
            '    end',
            'end',
            '',
            'for i = 1, 100 do',
            '    fizz_buzz(i)',
            'end',
        }
        assert.same(expected_commented_lines, lines)

        -- Trigger again to uncomment
        feedkeys('4gbc')

        local lines_after_uncomment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local expected_uncommented_lines = test_buffer_lines
        assert.same(expected_uncommented_lines, lines_after_uncomment)
    end)

    it('comments/uncomments the line with count and dot repeat', function()
        local lines_before_keymap =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        -- Make sure test buffer starts with expected text
        local expected_starting_lines = test_buffer_lines
        assert.same(expected_starting_lines, lines_before_keymap)

        -- Move cursor to line 1
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        local pos = vim.api.nvim_win_get_cursor(0)
        assert.same({ 1, 0 }, pos)

        -- Simulate pressing the keymap using normal mode feedkeys
        feedkeys('4gbc')

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        local expected_commented_lines = {
            '--[[ local function fizz_buzz(i) ]]',
            '--[[     if i % 15 == 0 then ]]',
            "--[[         print('FizzBuzz') ]]",
            '--[[     elseif i % 3 == 0 then ]]',
            "        print('Fizz')",
            '    elseif i % 5 == 0 then',
            "        print('Buzz')",
            '    else',
            '        print(i)',
            '    end',
            'end',
            '',
            'for i = 1, 100 do',
            '    fizz_buzz(i)',
            'end',
        }
        assert.same(expected_commented_lines, lines)

        -- Trigger again to uncomment
        feedkeys('.')

        local lines_after_uncomment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local expected_uncommented_lines = test_buffer_lines
        assert.same(expected_uncommented_lines, lines_after_uncomment)

        -- Trigger again to comment
        feedkeys('.')

        local lines_after_second_comment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        assert.same(expected_commented_lines, lines_after_second_comment)
    end)
end)

describe('normal mode gc operator pending keymap', function()
    local bufnr

    before_each(function()
        -- Create a new scratch buffer
        require('myconfig.comment.keymaps').setup_comment_keymaps()
        bufnr = vim.api.nvim_create_buf(false, true)
        vim.bo[bufnr].filetype = 'lua'
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, test_buffer_lines)
        vim.api.nvim_win_set_buf(0, bufnr)
    end)

    after_each(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end)

    it('is registered', function() assert_keymap_exists('n', 'gc') end)

    it('comments/uncomments the paragraph when on inner paragraph', function()
        local lines_before_keymap =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        -- Make sure test buffer starts with expected text
        local expected_starting_lines = test_buffer_lines
        assert.same(expected_starting_lines, lines_before_keymap)

        -- Move cursor to line 1
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        local pos = vim.api.nvim_win_get_cursor(0)
        assert.same({ 1, 0 }, pos)

        -- Simulate pressing the keymap using normal mode feedkeys
        feedkeys('gcip') --comment inner paragraph

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        local expected_commented_lines = {
            '-- local function fizz_buzz(i)',
            '--     if i % 15 == 0 then',
            "--         print('FizzBuzz')",
            '--     elseif i % 3 == 0 then',
            "--         print('Fizz')",
            '--     elseif i % 5 == 0 then',
            "--         print('Buzz')",
            '--     else',
            '--         print(i)',
            '--     end',
            '-- end',
            '',
            'for i = 1, 100 do',
            '    fizz_buzz(i)',
            'end',
        }
        assert.same(expected_commented_lines, lines)

        -- Trigger again to uncomment
        feedkeys('gcip')

        local lines_after_uncomment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local expected_uncommented_lines = test_buffer_lines
        assert.same(expected_uncommented_lines, lines_after_uncomment)
    end)

    it('comment paragraph with counts', function()
        local lines_before_keymap =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        -- Make sure test buffer starts with expected text
        local expected_starting_lines = test_buffer_lines
        assert.same(expected_starting_lines, lines_before_keymap)

        -- Move cursor to line 1
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        local pos = vim.api.nvim_win_get_cursor(0)
        assert.same({ 1, 0 }, pos)

        -- Simulate pressing the keymap using normal mode feedkeys
        feedkeys('3gcip') --comment inner paragraph

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        local expected_commented_lines = {
            '-- local function fizz_buzz(i)',
            '--     if i % 15 == 0 then',
            "--         print('FizzBuzz')",
            '--     elseif i % 3 == 0 then',
            "--         print('Fizz')",
            '--     elseif i % 5 == 0 then',
            "--         print('Buzz')",
            '--     else',
            '--         print(i)',
            '--     end',
            '-- end',
            '--', -- apparently this isn't padded
            '-- for i = 1, 100 do',
            '--     fizz_buzz(i)',
            '-- end',
        }
        assert.same(expected_commented_lines, lines)
    end)

    it(
        'comment/uncomment paragraph with too large counts will be skipped',
        function()
            local lines_before_keymap =
                vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            -- Make sure test buffer starts with expected text
            local expected_starting_lines = test_buffer_lines
            assert.same(expected_starting_lines, lines_before_keymap)

            -- Move cursor to line 1
            vim.api.nvim_win_set_cursor(0, { 1, 0 })

            local pos = vim.api.nvim_win_get_cursor(0)
            assert.same({ 1, 0 }, pos)

            -- Simulate pressing the keymap using normal mode feedkeys
            -- to comment inner four paragraph (blank lines count as a paragraph)
            -- since the text is only 3 paragraphs the selection will fail and nothing
            -- will be commented
            feedkeys('4gcip')

            local lines_after_comment_attempt =
                vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

            local expected_uncommented_lines = test_buffer_lines
            assert.same(expected_uncommented_lines, lines_after_comment_attempt)

            -- Comment all the lines to prepare for uncommenting test
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
                '-- local function fizz_buzz(i)',
                '--     if i % 15 == 0 then',
                "--         print('FizzBuzz')",
                '--     elseif i % 3 == 0 then',
                "--         print('Fizz')",
                '--     elseif i % 5 == 0 then',
                "--         print('Buzz')",
                '--     else',
                '--         print(i)',
                '--     end',
                '-- end',
                '-- ',
                '-- for i = 1, 100 do',
                '--     fizz_buzz(i)',
                '-- end',
            })

            -- Simulate pressing the keymap using normal mode feedkeys
            -- to comment inner four paragraph (blank lines count as a paragraph)
            -- since the text is only 1 paragraph the selection will fail and nothing
            -- will be uncommented
            feedkeys('4gcip')

            local lines_after_uncomment_attempt =
                vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            local expected_commented_lines = {
                '-- local function fizz_buzz(i)',
                '--     if i % 15 == 0 then',
                "--         print('FizzBuzz')",
                '--     elseif i % 3 == 0 then',
                "--         print('Fizz')",
                '--     elseif i % 5 == 0 then',
                "--         print('Buzz')",
                '--     else',
                '--         print(i)',
                '--     end',
                '-- end',
                '-- ',
                '-- for i = 1, 100 do',
                '--     fizz_buzz(i)',
                '-- end',
            }
            assert.same(expected_commented_lines, lines_after_uncomment_attempt)
        end
    )

    it('comments/uncomments the paragraph and is dot repeatable', function()
        local lines_before_keymap =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        -- Make sure test buffer starts with expected text
        local expected_starting_lines = test_buffer_lines
        assert.same(expected_starting_lines, lines_before_keymap)

        -- Move cursor to line 1
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        local pos = vim.api.nvim_win_get_cursor(0)
        assert.same({ 1, 0 }, pos)

        -- Simulate pressing the keymap using normal mode feedkeys
        feedkeys('gcip')

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        local expected_commented_lines = {
            '-- local function fizz_buzz(i)',
            '--     if i % 15 == 0 then',
            "--         print('FizzBuzz')",
            '--     elseif i % 3 == 0 then',
            "--         print('Fizz')",
            '--     elseif i % 5 == 0 then',
            "--         print('Buzz')",
            '--     else',
            '--         print(i)',
            '--     end',
            '-- end',
            '',
            'for i = 1, 100 do',
            '    fizz_buzz(i)',
            'end',
        }
        assert.same(expected_commented_lines, lines)

        -- Trigger again to uncomment
        feedkeys('.')

        local lines_after_uncomment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local expected_uncommented_lines = test_buffer_lines
        assert.same(expected_uncommented_lines, lines_after_uncomment)

        -- Trigger again to comment
        feedkeys('.')

        local lines_after_second_comment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        assert.same(expected_commented_lines, lines_after_second_comment)
    end)

    it('comment/uncomment inner word with dot repeat', function()
        local lines_before_keymap =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        -- Make sure test buffer starts with expected text
        local expected_starting_lines = test_buffer_lines
        assert.same(expected_starting_lines, lines_before_keymap)

        -- Move cursor to line 1
        vim.api.nvim_win_set_cursor(0, { 1, 8 })

        local pos = vim.api.nvim_win_get_cursor(0)
        assert.same({ 1, 8 }, pos)

        -- Simulate pressing the keymap using normal mode feedkeys
        feedkeys('gciW')

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        local expected_commented_lines = {
            'local --[[function]] fizz_buzz(i)',
            '    if i % 15 == 0 then',
            "        print('FizzBuzz')",
            '    elseif i % 3 == 0 then',
            "        print('Fizz')",
            '    elseif i % 5 == 0 then',
            "        print('Buzz')",
            '    else',
            '        print(i)',
            '    end',
            'end',
            '',
            'for i = 1, 100 do',
            '    fizz_buzz(i)',
            'end',
        }
        assert.same(expected_commented_lines, lines)

        -- Simulate pressing the keymap using normal mode feedkeys
        feedkeys('gciW')

        local lines_after_first_uncomment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local expected_uncommented_lines = test_buffer_lines
        assert.same(expected_uncommented_lines, lines_after_first_uncomment)

        -- Trigger again to comment
        feedkeys('.')

        local lines_after_second_comment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        assert.same(expected_commented_lines, lines_after_second_comment)

        -- Trigger again to uncomment
        feedkeys('.')

        local lines_after_second_uncomment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        assert.same(expected_uncommented_lines, lines_after_second_uncomment)
    end)

    it('comment/uncomment to end of line ($) with dot repeat', function()
        local lines_before_keymap =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        -- Make sure test buffer starts with expected text
        local expected_starting_lines = test_buffer_lines
        assert.same(expected_starting_lines, lines_before_keymap)

        -- Move cursor to line 1
        vim.api.nvim_win_set_cursor(0, { 1, 6 })

        local pos = vim.api.nvim_win_get_cursor(0)
        assert.same({ 1, 6 }, pos)

        -- Simulate pressing the keymap using normal mode feedkeys
        feedkeys('gc$')

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        local expected_commented_lines = {
            'local --function fizz_buzz(i)', --TODO refactor to add padding to end of line comments
            '    if i % 15 == 0 then',
            "        print('FizzBuzz')",
            '    elseif i % 3 == 0 then',
            "        print('Fizz')",
            '    elseif i % 5 == 0 then',
            "        print('Buzz')",
            '    else',
            '        print(i)',
            '    end',
            'end',
            '',
            'for i = 1, 100 do',
            '    fizz_buzz(i)',
            'end',
        }
        assert.same(expected_commented_lines, lines)

        -- Simulate pressing the keymap using normal mode feedkeys
        feedkeys('gc$')

        local lines_after_first_uncomment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local expected_uncommented_lines = test_buffer_lines
        assert.same(expected_uncommented_lines, lines_after_first_uncomment)

        -- Trigger again to comment
        feedkeys('.')

        local lines_after_second_comment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        assert.same(expected_commented_lines, lines_after_second_comment)

        -- Trigger again to uncomment
        feedkeys('.')

        local lines_after_second_uncomment =
            vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        assert.same(expected_uncommented_lines, lines_after_second_uncomment)
    end)
end)
