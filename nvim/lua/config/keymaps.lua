local config = require('config.config')
local maputils = require('utils.mapping')

vim.g.mapleader = ' '

vim.keymap.del({ 'n' }, '[d')
vim.keymap.del({ 'n' }, ']d')

vim.keymap.del({ 'n' }, '[D')
vim.keymap.del({ 'n' }, ']D')

-- Disable the "execute last macro" shortcut
vim.keymap.set(
    'n',
    'Q',
    '<nop>',
    { desc = 'Customized Remap: Remapped to <nop> to disable this keybinging' }
)

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
    --I think this is a case where I want 'v' and not 'x' mode
    { 'v', 'n' },
    '<leader>y',
    [["+y]],
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
    --I think this is a case where I want 'v' and not 'x' mode
    { 'v', 'n' },
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
    { 'n', 'v' },
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
vim.keymap.set(
    'n',
    'J',
    function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.cmd('join' .. vim.v.count1)
        vim.api.nvim_win_set_cursor(0, cursor)
    end,
    -- 'mzJ`z',
    {
        desc = 'Customized Remap: Move next line to end of current line without moving cursor',
    }
)

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

-- Quick fix navigation
vim.keymap.set(
    'n',
    '<C-j>',
    function() require('utils.mapping').smart_nav('cnext') end,
    { desc = 'Custom - Quick Fix List: cnext quick fix navigation' }
)
vim.keymap.set(
    'n',
    '<C-k>',
    function() require('utils.mapping').smart_nav('cprev') end,
    { desc = 'Custom - Quick Fix List: cprev quick fix navigation' }
)

vim.keymap.set('n', '<leader>qt', function()
    local qf_exists = false
    for _, win in pairs(vim.fn.getwininfo()) do
        if win['quickfix'] == 1 then qf_exists = true end
    end
    if qf_exists == true then
        vim.cmd('cclose')
        return
    end
    if not vim.tbl_isempty(vim.fn.getqflist()) then vim.cmd('copen') end
end, { desc = 'Custom - Quick Fix List: toggle' })

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
        default = {
            key = 's',
            mode = { 'n', 'x' },
            backward = function() vim.cmd('norm!' .. vim.v.count1 .. '[s') end,
            forward = function() vim.cmd('norm!' .. vim.v.count1 .. ']s') end,
            desc = 'Custom Remap: jump to "{prev|next}" spelling error',
            opts = {},
        },
        extreme = {
            key = 'S',
            mode = { 'n', 'x' },
            backward = function() vim.cmd('norm!' .. vim.v.count1 .. '[S') end,
            forward = function() vim.cmd('norm!' .. vim.v.count1 .. ']S') end,
            desc = 'Custom Remap: jump to "{prev|next}" spelling error excluding rare words',
            opts = {},
        },
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
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'hh',
            mode = { 'n', 'x' },
            backward = function()
                local target = 'all'
                if vim.wo.diff == true then target = 'unstaged' end
                require('gitsigns.actions').nav_hunk(
                    'prev',
                    { target = target, count = vim.v.count1 }
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
            key = 'HH',
            mode = { 'n', 'x' },
            backward = function()
                local target = 'all'
                if vim.wo.diff == true then target = 'unstaged' end
                require('gitsigns.actions').nav_hunk(
                    'first',
                    { target = target, count = math.huge }
                )
            end,
            forward = function()
                local target = 'all'
                if vim.wo.diff == true then target = 'unstaged' end
                require('gitsigns.actions').nav_hunk(
                    'last',
                    { target = target, count = math.huge }
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
                    { target = 'unstaged', count = vim.v.count1 }
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
                    { target = 'unstaged', count = math.huge }
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
                    { target = 'staged', count = vim.v.count1 }
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
                    { target = 'staged', count = math.huge }
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
                    { target = 'all', count = vim.v.count1 }
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
                    { target = 'all', count = math.huge }
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
            key = 'dd',
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
            desc = 'Custom: Jump to the {previous|next} diagnostic',
            opts = {},
        },
        extreme = {
            key = 'DD',
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
            desc = 'Custom: Jump to the {first|last} diagnostic',
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
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'm',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_start(
                    '@function.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_start(
                    '@function.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom Remap: jump to the {previous|next} method start',
            opts = {},
        },
        extreme = {
            key = 'M',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_end(
                    '@function.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_end(
                    '@function.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom Remap: jump to the {previous|next} method end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'f',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_start(
                    '@call.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_start(
                    '@call.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom Remap: jump to the {previous|next} function call start',
            opts = {},
        },
        extreme = {
            key = 'F',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_end(
                    '@call.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_end(
                    '@call.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom Remap: jump to the {previous|next} function call end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'c',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_start(
                    '@class.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_start(
                    '@class.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} class start',
            opts = {},
        },
        extreme = {
            key = 'C',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_end(
                    '@class.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_end(
                    '@class.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} class end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'i',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_start(
                    '@conditional.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_start(
                    '@conditional.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} conditional start',
            opts = {},
        },
        extreme = {
            key = 'I',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_end(
                    '@conditional.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_end(
                    '@conditional.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} conditional end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'o',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_start(
                    '@loop.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_start(
                    '@loop.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} loop start',
            opts = {},
        },
        extreme = {
            key = 'O',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_end(
                    '@loop.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_end(
                    '@loop.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} loop end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'va',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_start(
                    '@parameter.inner',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_start(
                    '@parameter.inner',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} parameter inner start',
            opts = {},
        },
        extreme = {
            key = 'vA',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_end(
                    '@parameter.inner',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_end(
                    '@parameter.inner',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} parameter inner end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'gci',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_start(
                    '@comment.inner',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_start(
                    '@comment.inner',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} comment inner start',
            opts = {},
        },
        extreme = {
            key = 'gcI',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_end(
                    '@comment.inner',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_end(
                    '@comment.inner',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} comment inner end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'gca',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_start(
                    '@comment.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_start(
                    '@comment.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} comment outer start',
            opts = {},
        },
        extreme = {
            key = 'gcA',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_end(
                    '@comment.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_end(
                    '@comment.outer',
                    'textobjects'
                )
            end,
            desc = 'Custom: jump to the {previous|next} comment outer end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'gt',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_start(
                    '@cast.outer',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_start(
                    '@cast.outer',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            desc = 'Custom: jump to the {previous|next} type cast start',
            opts = {},
        },
        extreme = {
            key = 'gT',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter.textobjects.move').goto_previous_end(
                    '@cast.outer',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            forward = function()
                require('nvim-treesitter.textobjects.move').goto_next_end(
                    '@cast.outer',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            desc = 'Custom: jump to the {previous|next} type cast end',
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

vim.keymap.del({ 'o', 'n', 'x' }, 'gc')

vim.keymap.set(
    { 'o' },
    'gc',
    function() require('utils.mapping').comment_lines_textobject() end,
    { desc = 'Comment textobject identical to gc operator' }
    --note: vgc does not select the commented lines. It really does a block
    --comment arround the character (which in my opinion pretty useless so I might
    --try to fix that) this is because it isn't using the textobject gc it is using
    --the gc visual mapping defined in numToStr/Comment.nvim
)

vim.keymap.set(
    { 'o', 'x' },
    'agc',
    function() require('utils.mapping').around_comment_lines_textobject() end,
    { desc = 'Comment textobject with treesitter fallback' }
)

vim.keymap.set(
    { 'o', 'x' },
    'igi',
    ":<c-u>lua require('utils.mapping').select_indent()<cr>",
    { desc = 'Select inner indent textobject', silent = true }
)

vim.keymap.set(
    { 'o', 'x' },
    'agi',
    ":<c-u>lua require('utils.mapping').select_indent(true)<cr>",
    { desc = 'Select around indent textobject', silent = true }
)
