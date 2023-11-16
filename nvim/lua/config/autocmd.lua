local init_group = 'init'

vim.api.nvim_create_augroup(init_group, { clear = true })
vim.api.nvim_create_autocmd(
    'TextYankPost',
    { group = init_group, callback = function() vim.highlight.on_yank() end }
)

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

local remember_folds_group = 'remember_folds'

vim.api.nvim_create_augroup(remember_folds_group, { clear = true })
-- bufleave but not bufwinleave captures closing 2nd tab
-- BufHidden for compatibility with `set hidden`
vim.api.nvim_create_autocmd(
    { 'BufWinLeave', 'BufLeave', 'BufWritePost', 'BufHidden', 'QuitPre' },
    {
        desc = 'Saves view file (saves information like open/closed folds)',
        group = remember_folds_group,
        pattern = '?*',
        -- nested is needed by bufwrite* (if triggered via other autocmd)
        nested = true,
        callback = SaveView,
    }
)

--TODO debug loading betwen format and writing
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
        LoadView()
    end,
})

local format_on_save_group = 'format_on_save_group'
vim.api.nvim_create_augroup(format_on_save_group, { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*',
    group = format_on_save_group,
    callback = function(args)
        require('conform').format({ bufnr = args.buf, lsp_fallback = true })
    end,
})

local isInlayHintsEnabled = false
function ToggleInlayHintsAutocmd()
    if not vim.lsp.inlay_hint then
        print("This version of neovim doesn't support inlay hints")
    end

    vim.api.nvim_create_augroup('inlay_hints', { clear = true })
    isInlayHintsEnabled = not isInlayHintsEnabled

    vim.lsp.inlay_hint(0, isInlayHintsEnabled)

    vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
        pattern = '?*',
        callback = function() vim.lsp.inlay_hint(0, isInlayHintsEnabled) end,
    })
end

function _G.set_terminal_keymaps()
    local opts = { buffer = 0 }
    vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
    vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
    vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
    vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
    vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
    vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

--Add lightbulb above code that has code actions
local lightbulb = require('config.lightbulb')
-- Show a lightbulb when code actions are available at the cursor position
vim.api.nvim_create_augroup('code_action', { clear = true })
vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI', 'WinScrolled' }, {
    group = 'code_action',
    pattern = '*',
    callback = lightbulb.show_lightbulb,
})
vim.api.nvim_create_autocmd({ 'TermEnter' }, {
    group = 'code_action',
    pattern = '*',
    callback = lightbulb.remove_bulb,
})
