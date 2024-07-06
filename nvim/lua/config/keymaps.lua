local maputils = require('utils.mapping')

--Granular undo while in insert mode
vim.keymap.set(
    'i',
    ',',
    ',<C-g>U',
    { desc = 'Creates an undo point when the character is typed' }
)
vim.keymap.set(
    'i',
    '.',
    '.<C-g>U',
    { desc = 'Creates an undo point when the character is typed' }
)
vim.keymap.set(
    'i',
    '!',
    '!<C-g>U',
    { desc = 'Creates an undo point when the character is typed' }
)
vim.keymap.set(
    'i',
    '?',
    '?<C-g>U',
    { desc = 'Creates an undo point when the character is typed' }
)

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
-- vim.keymap.set(
--     'n',
--     '<C-l>',
--     '<cmd>lnext<CR>zz',
--     { desc = 'Custom - Location List: lnext location list navigation' }
-- )
-- vim.keymap.set(
--     'n',
--     '<C-h>',
--     '<cmd>lprev<CR>zz',
--     { desc = 'Custom - Location List: lprev location list navigation' }
-- )

-- Find and replace word cursor is on
vim.keymap.set(
    'n',
    '<leader>s',
    [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    { desc = 'Custom: Find and replace the word the cursor is on' }
)

-- -- Make file executeable
-- vim.keymap.set(
--     'n',
--     '<leader>x',
--     '<cmd>!chmod +x %<CR>',
--     { silent = true, desc = 'Custom: Make file executeable' }
-- )
--
-- -- Diffing https://www.naseraleisa.com/posts/diff#file-1
-- -- Compare buffer to clipboard
-- vim.keymap.set(
--     'n',
--     '<leader>vcc',
--     '<cmd>CompareClipboard<cr>',
--     { desc = 'Custom: Compare Clipboard', silent = true }
-- )
--
-- -- Compare Clipboard to selected text
-- vim.keymap.set(
--     'v',
--     '<leader>vcc',
--     '<esc><cmd>CompareClipboardSelection<cr>',
--     { desc = 'Custom: Compare Clipboard Selection' }
-- )

-- Reverse letters https://vim.fandom.com/wiki/Reverse_letters
vim.keymap.set(
    'v',
    '<leader>ir',
    [[c<C-O>:set ri<CR><C-R>"<Esc>:set nori<CR>]],
    { desc = 'Custom: Reverse characters in text selection' }
)

vim.keymap.set(
    'n',
    '<leader>;',
    function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.cmd([[norm A;]])
        vim.api.nvim_win_set_cursor(0, cursor)
    end,
    -- [[A;<Esc>]],
    -- [[mmA;<Esc>`m]],
    {
        desc = 'Custom: Add semicolon to end of line without moving cursor',
    }
)

vim.keymap.set('v', '<leader>;', ':s/\\([^;]\\)$/\\1;/<CR>', {
    desc = 'Custom: Add a semicolon to end of each line in visual selection excluding lines that already have semicolons',
})

vim.keymap.set(
    'n',
    '<leader>,',
    function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.cmd([[norm A,]])
        vim.api.nvim_win_set_cursor(0, cursor)
    end,
    -- [[A,<Esc>]],
    -- [[mmA,<Esc>`m]],
    {
        desc = 'Custom: Add comma to end of line without moving cursor',
    }
)

vim.keymap.set('v', '<leader>,', ':s/\\([^,]\\)$/\\1,/<CR>', {
    desc = 'Custom: Add a comma to end of each line in visual selection excluding lines that already have commas',
})

vim.keymap.set('n', '<A-,>', '<c-w>5<', {
    desc = 'Custom: Decrease window width',
})
vim.keymap.set('n', '<A-;>', '<c-w>5>', {
    desc = 'Custom: Increase window width',
})
vim.keymap.set('n', '<A-t>', '<c-w>5+', {
    desc = 'Custom: Increase window height',
})
vim.keymap.set('n', '<A-s>', '<c-w>5-', {
    desc = 'Custom: Decrease window height',
})

local function add_lines(direction)
    local line_number = vim.api.nvim_win_get_cursor(0)[1]
    if direction == 'below' then line_number = line_number - 1 end
    local lines = vim.fn['repeat']({ '' }, vim.v.count1)
    vim.api.nvim_buf_set_lines(0, line_number, line_number, true, lines)
end

vim.keymap.set('n', '<leader>voj', function() add_lines('below') end, {
    desc = 'Custom: add blank line(s) below the current line',
})
vim.keymap.set('n', '<leader>vok', function() add_lines('above') end, {
    desc = 'Custom: add blank line(s) above the current line',
})

local myoperations = maputils
    .operations({

        backward_key = '[',
        forward_key = ']',
        mode = { 'n' },
    })
    :navigator({
        --visual mode: can navigate to a new buffer but visual mode is probably otherwise useful
        default = {
            key = 'q',
            mode = { 'n', 'x' },
            backward = 'cprevious',
            forward = 'cnext',
            desc = 'Custom: Run the "{cprevious|cnext}" command',
            opts = {},
        },
        extreme = {
            key = 'Q',
            mode = { 'n', 'x' },
            backward = 'cfirst',
            forward = 'clast',
            desc = 'Custom: Run the "{cfirst|clast}" command',
            opts = {},
        },
    })
    :navigator({
        default = {
            key = '<C-q>',
            backward = 'cpfile',
            forward = 'cnfile',
            desc = 'Custom: Run the "{cpfile|cnfile}" command',
            opts = {},
        },
        extreme = {
            key = '<leader><C-q>',
            backward = 'cfirst',
            forward = 'clast',
            desc = 'Custom: Run the "{cfirst|clast}" command',
            opts = {},
        },
    })
    :navigator({
        --visual mode: can navigate to a new buffer but visual mode is probably otherwise useful
        default = {
            key = 'l',
            mode = { 'n', 'x' },
            backward = 'lprevious',
            forward = 'lnext',
            desc = 'Custom: Run the "{lprevious|lnext}" command',
            opts = {},
        },
        extreme = {
            key = 'L',
            mode = { 'n', 'x' },
            backward = 'lfirst',
            forward = 'llast',
            desc = 'Custom: Run the "{lfirst|llast}" command',
            opts = {},
        },
    })
    :navigator({
        -- no visual mode: map will navigate to a new buffer so visual mode is not useful
        default = {
            key = '<C-l>',
            backward = 'lpfile',
            forward = 'lnfile',
            desc = 'Custom: Run the "{lpfile|lnfile}" command',
            opts = {},
        },
        extreme = {
            key = '<leader><C-l>',
            backward = 'lfirst',
            forward = 'llast',
            desc = 'Custom: Run the "{lfirst|llast}" command',
            opts = {},
        },
    })
    :navigator({
        -- no visual mode: map will navigate to a new buffer so visual mode is not useful
        default = {
            key = 'b',
            backward = 'bprevious',
            forward = 'bnext',
            desc = 'Custom: Run the "{bprevious|bnext}" command',
            opts = {},
        },
        extreme = {
            key = 'B',
            backward = 'bfirst',
            forward = 'blast',
            desc = 'Custom: Run the "{bfirst|blast}" command',
            opts = {},
        },
    })
    :navigator({
        -- no visual mode: map will navigate to a new buffer so visual mode is not useful
        default = {
            key = 'a',
            backward = 'previous',
            forward = 'next',
            desc = 'Custom: Run the "{previous|next}" command',
            opts = {},
        },
        extreme = {
            key = 'A',
            backward = 'first',
            forward = 'last',
            desc = 'Custom: Run the "{first|last}" command',
            opts = {},
        },
    })
    :navigator({
        --no visual mode: I believe this can navigate to other buffers so visual mode would not be useful
        default = {
            key = 't',
            backward = 'tprevious',
            forward = 'tnext',
            desc = 'Custom: Run the "{tprevious|tnext}" command',
            opts = {},
        },
        extreme = {
            key = 'T',
            backward = 'tfirst',
            forward = 'tlast',
            desc = 'Custom: Run the "{tfirst|tlast}" command',
            opts = {},
        },
    })
    :navigator({
        --no visual mode: I believe this can navigate to other buffers so visual mode would not be useful
        default = {
            key = '<C-t>',
            backward = 'ptprevious',
            forward = 'ptnext',
            desc = 'Custom: Run the "{ptprevious|ptnext}" command',
            opts = {},
        },
        extreme = {
            key = '<leader><C-t>',
            backward = 'ptfirst',
            forward = 'ptlast',
            desc = 'Custom: Run the "{ptfirst|ptlast}" command',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'h',
            mode = { 'n', 'x' },
            backward = function()
                local target = 'all'
                if vim.wo.diff == true then target = 'unstaged' end
                require('gitsigns.actions').nav_hunk(
                    'prev',
                    { target = target, count = -vim.v.count1 }
                )
            end,
            forward = function()
                local target = 'all'
                if vim.wo.diff == true then target = 'unstaged' end
                require('gitsigns.actions').nav_hunk(
                    'next',
                    { target = target, count = vim.v.count1 }
                )
            end,
            desc = 'Gitsigns: smart jump to the {previous|next} git hunk (based on if in diff mode)',
            opts = {},
        },
        extreme = {
            key = 'H',
            mode = { 'n', 'x' },
            backward = function()
                require('gitsigns.actions').nav_hunk(
                    'first',
                    { target = 'unstaged', count = -math.huge }
                )
            end,
            forward = function()
                require('gitsigns.actions').nav_hunk(
                    'last',
                    { target = 'unstaged', count = math.huge }
                )
            end,
            desc = 'Gitsigns: smart jump to the {first|last} git hunk (based on if in diff mode)',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'hu',
            mode = { 'n', 'x' },
            backward = function()
                require('gitsigns.actions').nav_hunk(
                    'prev',
                    { target = 'unstaged', count = -vim.v.count1 }
                )
            end,
            forward = function()
                require('gitsigns.actions').nav_hunk(
                    'next',
                    { target = 'unstaged', count = vim.v.count1 }
                )
            end,
            desc = 'Gitsigns: jump to the {previous|next} unstaged git hunk',
            opts = {},
        },
        extreme = {
            key = 'Hu',
            mode = { 'n', 'x' },
            backward = function()
                require('gitsigns.actions').nav_hunk(
                    'first',
                    { target = 'unstaged', count = -math.huge }
                )
            end,
            forward = function()
                require('gitsigns.actions').nav_hunk(
                    'last',
                    { target = 'unstaged', count = math.huge }
                )
            end,
            desc = 'Gitsigns: jump to the {first|last} unstaged git hunk',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'hs',
            mode = { 'n', 'x' },
            backward = function()
                require('gitsigns.actions').nav_hunk(
                    'prev',
                    { target = 'staged', count = -vim.v.count1 }
                )
            end,
            forward = function()
                require('gitsigns.actions').nav_hunk(
                    'next',
                    { target = 'staged', count = vim.v.count1 }
                )
            end,
            desc = 'Gitsigns: jump to the {previous|next} staged git hunk',
            opts = {},
        },
        extreme = {
            key = 'Hs',
            mode = { 'n', 'x' },
            backward = function()
                require('gitsigns.actions').nav_hunk(
                    'first',
                    { target = 'staged', count = -math.huge }
                )
            end,
            forward = function()
                require('gitsigns.actions').nav_hunk(
                    'last',
                    { target = 'staged', count = math.huge }
                )
            end,
            desc = 'Gitsigns: jump to the {first|last} staged git hunk',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'ha',
            mode = { 'n', 'x' },
            backward = function()
                require('gitsigns.actions').nav_hunk(
                    'prev',
                    { target = 'all', count = -vim.v.count1 }
                )
            end,
            forward = function()
                require('gitsigns.actions').nav_hunk(
                    'next',
                    { target = 'all', count = vim.v.count1 }
                )
            end,
            desc = 'Gitsigns: jump to the {previous|next} git hunk (staged or unstaged)',
            opts = {},
        },
        extreme = {
            key = 'Ha',
            mode = { 'n', 'x' },
            backward = function()
                require('gitsigns.actions').nav_hunk(
                    'first',
                    { target = 'all', count = -math.huge }
                )
            end,
            forward = function()
                require('gitsigns.actions').nav_hunk(
                    'last',
                    { target = 'all', count = math.huge }
                )
            end,
            desc = 'Gitsigns: jump to the {first|last} git hunk (staged or unstaged)',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'd',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -vim.v.count1,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = vim.v.count1,
                    float = true,
                })
            end,
            desc = 'Custom Remap: jump to the {previous|next} diagnostic',
            opts = {},
        },
        extreme = {
            key = 'D',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -math.huge,
                    wrap = false,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = math.huge,
                    wrap = false,
                    float = true,
                })
            end,
            desc = 'Custom Remap: jump to the {first|last} diagnostic',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'dh',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -vim.v.count1,
                    severity = vim.diagnostic.severity.HINT,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = vim.v.count1,
                    severity = vim.diagnostic.severity.HINT,
                    float = true,
                })
            end,
            desc = 'Custom: jump to the {previous|next} diagnostic hint',
            opts = {},
        },
        extreme = {
            key = 'Dh',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -math.huge,
                    severity = vim.diagnostic.severity.HINT,
                    wrap = false,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = math.huge,
                    severity = vim.diagnostic.severity.HINT,
                    wrap = false,
                    float = true,
                })
            end,
            desc = 'Custom Remap: jump to the {first|last} diagnostic hint',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'de',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -vim.v.count1,
                    severity = vim.diagnostic.severity.ERROR,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = vim.v.count1,
                    severity = vim.diagnostic.severity.ERROR,
                    float = true,
                })
            end,
            desc = 'Custom: jump to the {previous|next} diagnostic error',
            opts = {},
        },
        extreme = {
            key = 'De',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -math.huge,
                    severity = vim.diagnostic.severity.ERROR,
                    wrap = false,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = math.huge,
                    severity = vim.diagnostic.severity.ERROR,
                    wrap = false,
                    float = true,
                })
            end,
            desc = 'Custom Remap: jump to the {first|last} diagnostic error',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'di',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -vim.v.count1,
                    severity = vim.diagnostic.severity.INFO,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = vim.v.count1,
                    severity = vim.diagnostic.severity.INFO,
                    float = true,
                })
            end,
            desc = 'Custom: jump to the {previous|next} diagnostic info',
            opts = {},
        },
        extreme = {
            key = 'Di',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -math.huge,
                    severity = vim.diagnostic.severity.INFO,
                    wrap = false,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = math.huge,
                    severity = vim.diagnostic.severity.INFO,
                    wrap = false,
                    float = true,
                })
            end,
            desc = 'Custom Remap: jump to the {first|last} diagnostic info',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'dw',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -vim.v.count1,
                    severity = vim.diagnostic.severity.WARN,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = vim.v.count1,
                    severity = vim.diagnostic.severity.WARN,
                    float = true,
                })
            end,
            desc = 'Custom: jump to the {previous|next} diagnostic warn',
            opts = {},
        },
        extreme = {
            key = 'Dw',
            mode = { 'n', 'x' },
            backward = function()
                vim.diagnostic.jump({
                    count = -math.huge,
                    severity = vim.diagnostic.severity.WARN,
                    wrap = false,
                    float = true,
                })
            end,
            forward = function()
                vim.diagnostic.jump({
                    count = math.huge,
                    severity = vim.diagnostic.severity.WARN,
                    wrap = false,
                    float = true,
                })
            end,
            desc = 'Custom Remap: jump to the {first|last} diagnostic warning',
            opts = {},
        },
    })

maputils
    .operations({
        backward_key = '<C-h>',
        forward_key = '<C-l>',
        mode = { 'n' },
    })
    :navigator({
        default = {
            key = '',
            backward = function() myoperations.repeat_backward_callback() end,
            forward = function() myoperations.repeat_forward_callback() end,
            desc = 'Custom: Repeat my last {backward|forward} keymap for navigating lists',
            opts = {},
        },
    })

maputils
    .operations({
        backward_key = '<leader><C-h>',
        forward_key = '<leader><C-l>',
        mode = { 'n' },
    })
    :navigator({
        default = {
            key = '',
            backward = function()
                myoperations.repeat_extreme_backward_callback()
            end,
            forward = function() myoperations.repeat_extreme_forward_callback() end,
            desc = 'Custom: Run the extreme "{backward|forward}" command',
            opts = {},
        },
    })
