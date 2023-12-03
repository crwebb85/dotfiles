-- Navigation --

-- Pull up netrw file explorer
vim.keymap.set(
    'n',
    '<leader>fv',
    vim.cmd.Ex,
    { desc = 'Pull up netrw file explorer (view file explorer)' }
)

-- Clipboard --
-- Now the '+' register will copy to system clipboard using OSC52
vim.keymap.set('n', '<leader>c', '"+y', { desc = 'copy to system clipboard' })
vim.keymap.set('n', '<leader>cc', '"+yy', { desc = 'copy to system clipboard' })
vim.keymap.set('v', '<leader>c', '"+y', { desc = 'copy to system clipboard' })

-- Nearly the same keymaps
-- TODO determine which I like better
vim.keymap.set(
    { 'n', 'v' },
    '<leader>y',
    [["+y]],
    { desc = 'copy to system clipboard' }
)
vim.keymap.set('n', '<leader>Y', [["+Y]], { desc = 'copy to system clipboard' })

-- don't override paste buffer with the replaced text
-- when pasting over text
vim.keymap.set(
    'x',
    '<leader>p',
    [["_dP]],
    { desc = 'Paste without overriding paste buffer' }
)

-- Delete to the void register
vim.keymap.set(
    { 'n', 'v' },
    '<leader>d',
    [["_d]],
    { desc = 'Delete to the void register' }
)

-- Other --
-- Select the last changed text or the text that was just pasted (does not work for multilined spaces)
vim.keymap.set('n', 'gp', '`[v`]', {
    desc = 'Select  last changed or pasted text (limited to a single paragraph)',
})

-- Remap key to enter visual block mode so it doesn't interfere with pasting shortcut
vim.keymap.set('n', '<A-v>', '<C-V>', { desc = 'Enter visual block mode' })

-- Move highlighted lines up and down
vim.keymap.set(
    'v',
    'J',
    ":m '>+1<CR>gv=gv",
    { desc = 'Move highlighted lines up' }
)
vim.keymap.set(
    'v',
    'K',
    ":m '<-2<CR>gv=gv",
    { desc = 'Move highlighted lines down' }
)

-- Move next line to the end of the current line
-- but without moving the cursor to the end of the line
vim.keymap.set(
    'n',
    'J',
    'mzJ`z',
    { desc = 'Move next line to end of current line without moving cursor' }
)

-- Page down or up but keep cursor in the middle of the page
vim.keymap.set(
    'n',
    '<C-d>',
    '<C-d>zz',
    { desc = 'Page down and move cursor to the middle of the page' }
)
vim.keymap.set(
    'n',
    '<C-u>',
    '<C-u>zz',
    { desc = 'Page up and move cursor to the middle of the page' }
)

-- Go to next/previous search term
-- but keep cursor in the middle of page
vim.keymap.set(
    'n',
    'n',
    'nzzzv',
    { desc = 'Go to next search term and move cursor to middle of the page' }
)
vim.keymap.set('n', 'N', 'Nzzzv', {
    desc = 'Go to previous search term and move cursor to middle of the page',
})

-- Disable the "execute last macro" shortcut
--TODO detemine if I want this
vim.keymap.set(
    'n',
    'Q',
    '<nop>',
    { desc = 'remapped to <nop> to disable this keybinging' }
)

-- Format buffer
vim.keymap.set(
    'n',
    '<leader>f',
    function() require('conform').format({ lsp_fallback = true }) end,
    { desc = 'Format buffer' }
)

-- Quick fix navigation
vim.keymap.set(
    'n',
    '<C-k>',
    '<cmd>cnext<CR>zz',
    { desc = 'cnext quick fix navigation' }
)
vim.keymap.set(
    'n',
    '<C-j>',
    '<cmd>cprev<CR>zz',
    { desc = 'cprev quick fix navigation' }
)
vim.keymap.set(
    'n',
    '<leader>k',
    '<cmd>lnext<CR>zz',
    { desc = 'lnext quick fix navigation' }
)
vim.keymap.set(
    'n',
    '<leader>j',
    '<cmd>lprev<CR>zz',
    { desc = 'lprev quick fix navigation' }
)

-- LSP signature info
vim.keymap.set({ 'n', 'i' }, '<C-m>', vim.lsp.buf.signature_help)

-- Find and replace word cursor is on
vim.keymap.set(
    'n',
    '<leader>s',
    [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    { desc = 'Find and replace the word the cursor is on' }
)

-- Make file executeable
vim.keymap.set(
    'n',
    '<leader>x',
    '<cmd>!chmod +x %<CR>',
    { silent = true, desc = 'Make file executeable' }
)

-- Diffing https://www.naseraleisa.com/posts/diff#file-1
-- Compare buffer to clipboard
vim.keymap.set(
    'n',
    '<leader>vc',
    '<cmd>CompareClipboard<cr>',
    { desc = 'Compare Clipboard', silent = true }
)

-- Compare Clipboard to selected text
vim.keymap.set(
    'v',
    '<leader>vc',
    '<esc><cmd>CompareClipboardSelection<cr>',
    { desc = 'Compare Clipboard Selection' }
)

-- Reverse letters https://vim.fandom.com/wiki/Reverse_letters
vim.keymap.set(
    'v',
    '<leader>ir',
    [[c<C-O>:set ri<CR><C-R>"<Esc>:set nori<CR>]],
    { desc = 'Reverse text selection' }
)
