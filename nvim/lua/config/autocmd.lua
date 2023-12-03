-------------------------------------------------------------------------------
--- Temporarily highlight text selection that was yanked
local yank_group = 'yank_group'
vim.api.nvim_create_augroup(yank_group, { clear = true })
vim.api.nvim_create_autocmd(
    'TextYankPost',
    { group = yank_group, callback = function() vim.highlight.on_yank() end }
)

-------------------------------------------------------------------------------
--- Select python virtual environment
vim.api.nvim_create_autocmd('VimEnter', {
    desc = 'Auto select virtualenv Nvim open',
    pattern = '*',
    callback = function()
        local venv = vim.fn.findfile('requirements.txt', vim.fn.getcwd() .. ';')
        --local venv = vim.fn.findfile("pyproject.toml", vim.fn.getcwd() .. ";")
        if venv ~= '' then require('venv-selector').retrieve_from_cache() end
    end,
    once = true,
})

-------------------------------------------------------------------------------
--- Code Folding

local remember_folds_group = 'remember_folds'
vim.api.nvim_create_augroup(remember_folds_group, { clear = true })

-- Save fold informatin in view file
vim.api.nvim_create_autocmd(
    -- bufleave but not bufwinleave captures closing 2nd tab
    -- BufHidden for compatibility with `set hidden`
    { 'BufWinLeave', 'BufLeave', 'BufWritePost', 'BufHidden', 'QuitPre' },
    {
        desc = 'Saves view file (saves information like open/closed folds)',
        group = remember_folds_group,
        pattern = '?*',
        -- nested is needed by bufwrite* (if triggered via other autocmd)
        nested = true,
        callback = require('config.utils').saveView,
    }
)

-- Apply folds to folder based on view file
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufWritePost' }, {
    desc = 'Loads the view file for the buffer (reloads open/closed folds)',
    group = remember_folds_group,
    pattern = '?*',
    callback = function()
        if
            not vim.api.nvim_get_option_value('diff', {})
            and vim.api.nvim_get_option_value('foldmethod', {}) == 'diff'
            and vim.api.nvim_get_option_value('foldexpr', {})
                == 'v:lua.vim.treesitter.foldexpr()'
        then
            -- Reset Folding back to using tresitter after no longer using diff mode
            vim.api.nvim_set_option_value('foldmethod', 'expr', {})
            vim.api.nvim_set_option_value(
                'foldexpr',
                'v:lua.vim.treesitter.foldexpr()',
                {}
            )
        end
        require('config.utils').loadView()
    end,
})

-------------------------------------------------------------------------------
--- Add keybindings/settings to specific buffer types

-- Add keybindings to terminal buffers
vim.api.nvim_create_autocmd({ 'TermOpen' }, {
    -- if you only want these mappings for toggle term use term://*toggleterm#* instead
    pattern = 'term://*',
    callback = function()
        vim.keymap.set(
            't',
            '<esc>',
            [[<C-\><C-n>]],
            { buffer = 0, desc = 'Terminal: Esc to terminal normal mode' }
        )
        vim.keymap.set(
            't',
            '<C-h>',
            [[<Cmd>wincmd h<CR>]],
            { buffer = 0, desc = 'Terminal: Move to left window' }
        )
        vim.keymap.set(
            't',
            '<C-j>',
            [[<Cmd>wincmd j<CR>]],
            { buffer = 0, desc = 'Terminal: Move to lower window' }
        )
        vim.keymap.set(
            't',
            '<C-k>',
            [[<Cmd>wincmd k<CR>]],
            { buffer = 0, desc = 'Terminal: Move to upper window' }
        )
        vim.keymap.set(
            't',
            '<C-l>',
            [[<Cmd>wincmd l<CR>]],
            { buffer = 0, desc = 'Terminal: Move to right window' }
        )
        vim.keymap.set(
            't',
            '<C-w>',
            [[<C-\><C-n><C-w>]],
            { buffer = 0, desc = 'Terminal: Trigger Window keymaps' }
        )
    end,
})

-- If opening a terminal start in insert mode and set local parameters
-- Works for both the :terminal command and toggleterm plugin
vim.api.nvim_create_autocmd('TermOpen', {
    group = vim.api.nvim_create_augroup('term_open_insert', { clear = true }),
    pattern = { 'term://*' },
    command = [[
    startinsert
    setlocal nonumber norelativenumber nospell signcolumn=no noruler
  ]],
})

-- When entering terminal start in insert mode. This is useful if I had toggled
-- the terminal closed in normal mode but then try to toggle it back up.
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
    group = vim.api.nvim_create_augroup('term_insert', { clear = true }),
    pattern = { 'term://*' },
    command = [[
    startinsert
  ]],
})

-- Dockerfile filetype
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    desc = 'Set file type for Dockerfile*',
    pattern = { 'Dockerfile*', '*.Dockerfile', '*.dockerfile' },
    command = [[set ft=dockerfile]],
})

-- Close some filetypes with <q>
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('close_with_q', { clear = true }),
    pattern = {
        'PlenaryTestPopup',
        'help',
        'lspinfo',
        'man',
        'notify',
        'qf',
        'git',
        'spectre_panel',
        'startuptime',
        'tsplayground',
        'checkhealth',
        'neotest-output',
        'neotest-summary',
        'neotest-output-panel',
        'guihua',
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set(
            'n',
            'q',
            '<cmd>close<CR>',
            { buffer = event.buf, silent = true, desc = 'Custom: Close window' }
        )
        vim.cmd([[
      setlocal colorcolumn=0
      stopinsert
    ]])
    end,
})

-- Close man pages with <q>
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'man',
    callback = function()
        vim.keymap.set(
            'n',
            'q',
            ':quit<CR>',
            { buffer = 0, silent = true, desc = 'Custom: Close window' }
        )
    end,
})

-- Pressing enter on item in quickfix list will take me to that file and line
-- TODO determine why I need this since I believe this should be a default
-- keymapping but something is overridding it
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'qf',
    callback = function(event)
        vim.keymap.set('n', '<CR>', '<CR>', {
            buffer = event.buf,
            silent = true,
            desc = 'Custom - Quick Fix List: Go to quickfix item under cursor',
        })
    end,
})

-------------------------------------------------------------------------------
--- Lightbulb code action virtual text

local lightbulb = require('config.lightbulb')

-- Show a lightbulb when code actions are available at the cursor position
vim.api.nvim_create_augroup('code_action', { clear = true })
vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI', 'WinScrolled' }, {
    group = 'code_action',
    pattern = '*',
    callback = lightbulb.show_lightbulb,
})
-- Remove lightbulb from terminal buffers
vim.api.nvim_create_autocmd({ 'TermEnter' }, {
    group = 'code_action',
    pattern = '*',
    callback = lightbulb.remove_bulb,
})

-------------------------------------------------------------------------------
--- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
    group = vim.api.nvim_create_augroup('checktime', { clear = true }),
    command = 'checktime',
})

-------------------------------------------------------------------------------
-- Resize splits if window got resized
vim.api.nvim_create_autocmd({ 'VimResized' }, {
    group = vim.api.nvim_create_augroup('resize_splits', { clear = true }),
    callback = function() vim.cmd('tabdo wincmd =') end,
})
