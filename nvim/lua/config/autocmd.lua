-------------------------------------------------------------------------------
--- Temporarily highlight text selection that was yanked
local yank_group = 'yank_group'
vim.api.nvim_create_augroup(yank_group, { clear = true })
vim.api.nvim_create_autocmd(
    'TextYankPost',
    { group = yank_group, callback = function() vim.highlight.on_yank() end }
)

-------------------------------------------------------------------------------
--- Add keybindings/settings to specific buffer types

-- Add keybindings to terminal buffers
vim.api.nvim_create_autocmd({ 'TermOpen' }, {
    -- if you only want these mappings for toggle term use term://*toggleterm#* instead
    pattern = 'term://*',
    callback = function()
        vim.keymap.set(
            't',
            '<leader><esc>',
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

--Fix specifix buffers to certain buffers so that I don't accidently leave
--them
-- TOOD figure out how to handle if all the remaining windows are fixed
-- vim.api.nvim_create_autocmd('FileType', {
--     group = vim.api.nvim_create_augroup('sticky_buffers', { clear = true }),
--     pattern = {
--         'lspinfo',
--         'git',
--         'spectre_panel',
--         'checkhealth',
--         'neotest-output',
--         'neotest-summary',
--         'neotest-output-panel',
--         'qf',
--         'terminal',
--         'toggleterm',
--         'dapui_watches',
--         'dapui_stacks',
--         'dapui_breakpoints',
--         'dapui_scopes',
--         'dapui_console',
--     },
--     callback = function(_) vim.cmd([[setlocal winfixbuf]]) end,
-- })

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

-------------------------------------------------------------------------------
--- Autosave
-- vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost', 'VimLeavePre' }, {
--     pattern = '*',
--     group = vim.api.nvim_create_augroup('autosave', { clear = true }),
--     callback = function(event)
--         if event.buftype or event.file == '' then return end
--         vim.api.nvim_buf_call(event.buf, function()
--             vim.schedule(function() vim.cmd('silent! write') end)
--         end)
--     end,
-- })
