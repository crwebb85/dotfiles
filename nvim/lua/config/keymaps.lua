-- Clipboard --
-- Now the '+' register will copy to system clipboard using OSC52
vim.keymap.set(
    { 'n', 'v' },
    '<leader>y',
    [["+y]],
    { desc = 'Custom Clipboard: Copy to system clipboard' }
)
vim.keymap.set(
    'n',
    '<leader>Y',
    [["+Y]],
    { desc = 'Custom Clipboard: Copy to system clipboard' }
)

-- don't override paste buffer with the replaced text
-- when pasting over text
vim.keymap.set(
    'x',
    '<leader>p',
    [["_dP]],
    { desc = 'Custom Clipboard: Paste without overriding paste buffer' }
)

-- Delete to the void register
vim.keymap.set(
    { 'n', 'v' },
    '<leader>d',
    [["_d]],
    { desc = 'Custom Clipboard: Delete to the void register' }
)

-- Other --
-- Select the last changed text or the text that was just pasted (does not work for multilined spaces)
vim.keymap.set('n', 'gp', '`[v`]', {
    desc = 'Custom Clipboard: Select  last changed or pasted text (limited to a single paragraph)',
})

-- Remap key to enter visual block mode so it doesn't interfere with pasting shortcut
vim.keymap.set(
    'n',
    '<A-v>',
    '<C-V>',
    { desc = 'Custom: Enter visual block mode' }
)

-- Move highlighted lines up and down
vim.keymap.set(
    'v',
    'J',
    ":m '>+1<CR>gv=gv",
    { desc = 'Custom: Move highlighted lines up' }
)
vim.keymap.set(
    'v',
    'K',
    ":m '<-2<CR>gv=gv",
    { desc = 'Custom: Move highlighted lines down' }
)

-- Move next line to the end of the current line
-- but without moving the cursor to the end of the line
vim.keymap.set('n', 'J', 'mzJ`z', {
    desc = 'Customized Remap: Move next line to end of current line without moving cursor',
})

-- Page down or up but keep cursor in the middle of the page
vim.keymap.set('n', '<C-d>', '<C-d>zz', {
    desc = 'Customized Remap: Page down and move cursor to the middle of the page',
})
vim.keymap.set('n', '<C-u>', '<C-u>zz', {
    desc = 'Customized Remap: Page up and move cursor to the middle of the page',
})

-- Go to next/previous search term
-- but keep cursor in the middle of page
vim.keymap.set('n', 'n', 'nzzzv', {
    desc = 'Customized Remap: Go to next search term and move cursor to middle of the page',
})
vim.keymap.set('n', 'N', 'Nzzzv', {
    desc = 'Customized Remap: Go to previous search term and move cursor to middle of the page',
})

-- Disable the "execute last macro" shortcut
vim.keymap.set(
    'n',
    'Q',
    '<nop>',
    { desc = 'Customized Remap: Remapped to <nop> to disable this keybinging' }
)

-- Quick fix navigation
vim.keymap.set(
    'n',
    '<C-j>',
    '<cmd>cnext<CR>zz',
    { desc = 'Custom - Quick Fix List: cnext quick fix navigation' }
)
vim.keymap.set(
    'n',
    '<C-k>',
    '<cmd>cprev<CR>zz',
    { desc = 'Custom - Quick Fix List: cprev quick fix navigation' }
)
vim.keymap.set(
    'n',
    '<leader>j',
    '<cmd>lnext<CR>zz',
    { desc = 'Custom - Location List: lnext location list navigation' }
)
vim.keymap.set(
    'n',
    '<leader>k',
    '<cmd>lprev<CR>zz',
    { desc = 'Custom - Location List: lprev location list navigation' }
)

-- Find and replace word cursor is on
vim.keymap.set(
    'n',
    '<leader>s',
    [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    { desc = 'Custom: Find and replace the word the cursor is on' }
)

-- Make file executeable
vim.keymap.set(
    'n',
    '<leader>x',
    '<cmd>!chmod +x %<CR>',
    { silent = true, desc = 'Custom: Make file executeable' }
)

-- Diffing https://www.naseraleisa.com/posts/diff#file-1
-- Compare buffer to clipboard
vim.keymap.set(
    'n',
    '<leader>vcc',
    '<cmd>CompareClipboard<cr>',
    { desc = 'Custom: Compare Clipboard', silent = true }
)

-- Compare Clipboard to selected text
vim.keymap.set(
    'v',
    '<leader>vcc',
    '<esc><cmd>CompareClipboardSelection<cr>',
    { desc = 'Custom: Compare Clipboard Selection' }
)

-- Reverse letters https://vim.fandom.com/wiki/Reverse_letters
vim.keymap.set(
    'v',
    '<leader>ir',
    [[c<C-O>:set ri<CR><C-R>"<Esc>:set nori<CR>]],
    { desc = 'Custom: Reverse characters in text selection' }
)

vim.keymap.set(
    { 'i', 'n' },
    '<A-r>',
    function()
        if
            not vim.api.nvim_get_option_value('number', {})
            and not vim.api.nvim_get_option_value('relativenumber', {})
        then
            vim.cmd([[
                setlocal number!
                echo "nu:1/rnu:0"
            ]])
        elseif
            vim.api.nvim_get_option_value('number', {})
            and not vim.api.nvim_get_option_value('relativenumber', {})
        then
            vim.cmd([[
                setlocal relativenumber!
                echo "nu:1/rnu:1"
            ]])
        elseif
            vim.api.nvim_get_option_value('number', {})
            and vim.api.nvim_get_option_value('relativenumber', {})
        then
            vim.cmd([[
                setlocal number!
                echo "nu:0/rnu:1"
            ]])
        else
            vim.cmd([[
                setlocal relativenumber!
                echo "nu:0/rnu:0"
            ]])
        end
    end,
    { desc = 'Custom: Cycle line numbers/relative line numbers for the buffer' }
)

vim.keymap.set(
    'n',
    '<leader>;',
    [[A;<Esc>]],
    { desc = 'Custom: Add semicolon to end of line' }
)

vim.keymap.set('v', '<leader>;', ':s/\\([^;]\\)$/\\1;/<CR>', {
    desc = 'Custom: Add a semicolon to end of each line in visual selection excluding lines that already have semicolons',
})

vim.keymap.set(
    'n',
    '<leader>,',
    [[A,<Esc>]],
    { desc = 'Custom: Add comma to end of line' }
)

vim.keymap.set('v', '<leader>,', ':s/\\([^,]\\)$/\\1,/<CR>', {
    desc = 'Custom: Add a comma to end of each line in visual selection excluding lines that already have commas',
})
