local config = require('myconfig.config')
local maputils = require('myconfig.utils.mapping')
local feedkeys = maputils.feedkeys

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

-------------------------------------------------------------------------------
---LSP keymaps
require('myconfig.lsp.keymaps').setup_lsp_keymaps()

local function do_open(uri, open_func)
    local cmd, err = open_func(uri)
    local rv = cmd and cmd:wait(1000) or nil
    if cmd and rv and rv.code ~= 0 then
        err = ('vim.ui.open: command %s (%d): %s'):format(
            (rv.code == 124 and 'timeout' or 'failed'),
            rv.code,
            vim.inspect(cmd.cmd)
        )
    end
    return err
end

vim.keymap.set({ 'n' }, 'gx', function()
    local link_uri = require('myconfig.lsp.lsplinks').get_link_at_cursor()
    if link_uri ~= nil then
        local err = do_open(link_uri, require('myconfig.lsp.lsplinks').open)
        if err then vim.notify(err, vim.log.levels.ERROR) end
    end
    for _, url in ipairs(require('vim.ui')._get_urls()) do
        local err = do_open(url, vim.ui.open)
        if err then vim.notify(err, vim.log.levels.ERROR) end
    end
end, {
    desc = 'Custom Remap: Open lsp links if exists. Otherwise, fallback to default neovim functionality for open link',
})

-------------------------------------------------------------------------------
---Completion

local function pumvisible() return tonumber(vim.fn.pumvisible()) ~= 0 end

local function is_completion_menu_visible()
    if require('myconfig.config').use_native_completion then
        return pumvisible()
    else
        return require('cmp').visible()
    end
end

local function is_entry_active()
    if require('myconfig.config').use_native_completion then
        return pumvisible()
            and vim.fn.complete_info({ 'selected' }).selected >= 0
    else
        local cmp = require('cmp')
        return cmp.visible() and cmp.get_active_entry()
    end
end

local function confirm_entry(replace)
    if require('myconfig.config').use_native_completion then
        --TODO replicate cmps replace functionality when replace is true
        feedkeys('<C-y>')
    else
        local cmp = require('cmp')
        local behavior = replace and cmp.ConfirmBehavior.Replace
            or cmp.ConfirmBehavior.Insert
        cmp.confirm({
            behavior = behavior,
            select = false,
        })
    end
end

local function is_docs_visible()
    if require('myconfig.config').use_native_completion then
        --TODO: Not the most robust since it doesn't actually check if the documentation is visible
        return not require('myconfig.lsp.completion.documentation').is_documentation_disabled()
    else
        return require('cmp').visible_docs()
    end
end

-- Keymap notes from :help ins-completion
-- |i_CTRL-X_CTRL-D|	CTRL-X CTRL-D	complete defined identifiers
-- |i_CTRL-X_CTRL-E|	CTRL-X CTRL-E	scroll up
-- |i_CTRL-X_CTRL-F|	CTRL-X CTRL-F	complete file names
-- |i_CTRL-X_CTRL-I|	CTRL-X CTRL-I	complete identifiers
-- |i_CTRL-X_CTRL-K|	CTRL-X CTRL-K	complete identifiers from dictionary
-- |i_CTRL-X_CTRL-L|	CTRL-X CTRL-L	complete whole lines
-- |i_CTRL-X_CTRL-N|	CTRL-X CTRL-N	next completion
-- |i_CTRL-X_CTRL-O|	CTRL-X CTRL-O	omni completion
-- |i_CTRL-X_CTRL-P|	CTRL-X CTRL-P	previous completion
-- |i_CTRL-X_CTRL-R|	CTRL-X CTRL-R	complete contents from registers
-- |i_CTRL-X_CTRL-S|	CTRL-X CTRL-S	spelling suggestions
-- |i_CTRL-X_CTRL-T|	CTRL-X CTRL-T	complete identifiers from thesaurus
-- |i_CTRL-X_CTRL-Y|	CTRL-X CTRL-Y	scroll down
-- |i_CTRL-X_CTRL-U|	CTRL-X CTRL-U	complete with 'completefunc'
-- |i_CTRL-X_CTRL-V|	CTRL-X CTRL-V	complete like in : command line
-- |i_CTRL-X_CTRL-Z|	CTRL-X CTRL-Z	stop completion, keeping the text as-is
-- |i_CTRL-X_CTRL-]|	CTRL-X CTRL-]	complete tags
-- |i_CTRL-X_s|		CTRL-X s	spelling suggestions
--
-- commands in completion mode (see |popupmenu-keys|)
--
-- |complete_CTRL-E| CTRL-E	stop completion and go back to original text
-- |complete_CTRL-Y| CTRL-Y	accept selected match and stop completion
--         CTRL-L		insert one character from the current match
--         <CR>		insert currently selected match
--         <BS>		delete one character and redo search
--         CTRL-H		same as <BS>
--         <Up>		select the previous match
--         <Down>		select the next match
--         <PageUp>	select a match several entries back
--         <PageDown>	select a match several entries forward
--         other		stop completion and insert the typed character
--

vim.keymap.set({ 'i' }, '<UP>', function()
    if require('myconfig.config').use_native_completion then
        feedkeys('<UP>')
    else
        local select_prev = require('cmp').mapping.select_prev_item({
            behavior = 'select',
        })
        select_prev(function() end)
    end
end, {
    desc = 'Custom Remap: Select previous completion item',
})

vim.keymap.set('i', '<DOWN>', function()
    if require('myconfig.config').use_native_completion then
        feedkeys('<DOWN>')
    else
        local select_next = require('cmp').mapping.select_next_item({
            behavior = 'select',
        })
        select_next(function() end)
    end
end, {
    desc = 'Custom Remap: Select next completion item',
})

--TODO the following keymaps don't work in `ic` mode because <C-p> and <C-n> are hardcoded
--in the vim C code and cannot be remapped until issue https://github.com/vim/vim/issues/16880
--is resolved as a result I can't have my snippet logic work as `ic` mode 90% of the
--time this keymap will be ran when using native completion
vim.keymap.set({ 'i', 's' }, '<C-p>', function()
    -- local luasnip = require('luasnip')
    -- if is_entry_active() then
    --     feedkeys('<C-p>')
    -- elseif luasnip.jumpable(-1) then
    --     luasnip.jump(-1)
    -- elseif vim.snippet.active({ direction = -1 }) then
    --     vim.snippet.jump(-1)
    -- elseif require('myconfig.config').use_native_completion then
    --     feedkeys('<C-p>')
    -- else
    --     local select_prev = require('cmp').mapping.select_prev_item({
    --         behavior = 'select',
    --     })
    --     select_prev(function() end)
    -- end

    if require('myconfig.config').use_native_completion then
        feedkeys('<C-p>')
    else
        local select_prev = require('cmp').mapping.select_prev_item({
            behavior = 'select',
        })
        select_prev(function() end)
    end
end, {
    -- desc = 'Custom Remap: Jump to previous snippet location or fallback to previous completion item',
    desc = 'Custom Remap: Jump to previous completion item',
})

--TODO the following keymaps don't work in `ic` mode because <C-p> and <C-n> are hardcoded
--in the vim C code and cannot be remapped until issue https://github.com/vim/vim/issues/16880
--is resolved as a result I can't have my snippet logic work as `ic` mode 90% of the
--time this keymap will be ran when using native completion
vim.keymap.set({ 'i', 's' }, '<C-n>', function()
    -- local luasnip = require('luasnip')
    -- if is_entry_active() then
    --     feedkeys('<C-n>')
    -- elseif luasnip.expand_or_jumpable() then
    --     luasnip.expand_or_jump()
    -- elseif vim.snippet.active({ direction = 1 }) then
    --     vim.snippet.jump(1)
    -- elseif require('myconfig.config').use_native_completion then
    --     feedkeys('<C-n>')
    -- else
    --     local select_next = require('cmp').mapping.select_next_item({
    --         behavior = 'select',
    --     })
    --     select_next(function() end)
    -- end
    if require('myconfig.config').use_native_completion then
        feedkeys('<C-n>')
    else
        local select_next = require('cmp').mapping.select_next_item({
            behavior = 'select',
        })
        select_next(function() end)
    end
end, {
    -- desc = 'Custom Remap: Jump to next snippet location or fallback to next completion item',
    desc = 'Custom Remap: Jump to next completion item',
})

vim.keymap.set({ 'i', 's' }, '<C-h>', function()
    local luasnip = require('luasnip')
    if luasnip.jumpable(-1) then
        luasnip.jump(-1)
    elseif vim.snippet.active({ direction = -1 }) then
        vim.snippet.jump(-1)
    end
end, {
    desc = 'Custom: Jump to previous snippet location',
})

vim.keymap.set({ 'i', 's' }, '<C-l>', function()
    local luasnip = require('luasnip')
    if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
    elseif vim.snippet.active({ direction = 1 }) then
        vim.snippet.jump(1)
    end
end, {
    desc = 'Custom: Jump to next snippet location',
})

vim.keymap.set('i', '<CR>', function()
    if is_entry_active() then
        ---setting the undolevels creates a new undo break
        ---so by setting it to itself I can create an undo break
        ---without side effects just before a comfirming a completion.
        -- Use <c-u> in insert mode to undo the completion
        vim.cmd([[let &g:undolevels = &g:undolevels]])
        confirm_entry()
    else
        feedkeys('<CR>') --Fallback to default keymap (aka insert a newline)
        -- 						*i_CTRL-M* *i_<CR>*
        -- <CR> or CTRL-M	Begin new line.
    end
end, {
    desc = 'Custom Remap: Select active completion item or fallback',
})

vim.keymap.set('i', '<C-y>', function()
    if is_entry_active() then
        ---setting the undolevels creates a new undo break
        ---so by setting it to itself I can create an undo break
        ---without side effects just before a comfirming a completion.
        -- Use <c-u> in insert mode to undo the completion
        vim.cmd([[let &g:undolevels = &g:undolevels]])
        --I verified that feedkeys in my <CR> mapping does not call this remapping
        --so I don't have to worry about this recursively getting called
        confirm_entry(true)
    else
        feedkeys('<C-y') -- Fallback to default keymap
        -- 						*i_CTRL-Y*
        -- CTRL-Y		Insert the character which is above the cursor.
        -- 		Note that for CTRL-E and CTRL-Y 'textwidth' is not used, to be
        -- 		able to copy characters from a long line.
    end
end, {
    desc = 'Custom Remap: Select active completion item or fallback',
})

--TODO fix for cmp
vim.keymap.set('i', '<C-e>', function()
    --TODO may want to also toggle my autocmd that automatically opens
    --the completion menu on each character typed
    if is_completion_menu_visible() then
        --Close completion menu
        require('myconfig.lsp.completion.completion_state').completion_auto_trigger_enabled =
            false
        if pumvisible() then
            feedkeys('<C-e>') --Close completion menu
        elseif not require('myconfig.config').use_native_completion then
            require('cmp').abort()
        else
            feedkeys('<C-e>') --Close completion menu
        end
    else
        require('myconfig.lsp.completion.completion_state').completion_auto_trigger_enabled =
            true

        if not require('myconfig.config').use_native_completion then
            require('cmp').complete()
            --TODO One difference that may be desirable is that cmp automatically
            --reenables showing documentation window while my native completion doesn't
            --currently do so
        elseif vim.bo.omnifunc == '' then
            feedkeys('<C-x><C-n>') --Triggers buffer completion
        else
            -- vim.lsp.completion.get()
            feedkeys('<C-x><C-o>') --Triggers vim.bo.omnifunc which is normally lsp completion
        end
    end
end, { desc = 'Custom Remap: Toggle completion window' })

vim.keymap.set({ 'i', 's' }, '<C-u>', function()
    if is_docs_visible() then
        if require('myconfig.config').use_native_completion then
            require('myconfig.lsp.completion.documentation').scroll_docs(-4)
        else
            require('cmp').mapping.scroll_docs(-4)
        end
    else
        feedkeys('<C-u>') -- Fallback to default keymap that deletes text to the left
        -- 						*i_CTRL-U*
        -- CTRL-U		Delete all entered characters before the cursor in the current
        -- 		line.  If there are no newly entered characters and
        -- 		'backspace' is not empty, delete all characters before the
        -- 		cursor in the current line.
        -- 		If C-indenting is enabled the indent will be adjusted if the
        -- 		line becomes blank.
        -- 		See |i_backspacing| about joining lines.
        -- 						*i_CTRL-U-default*
        -- 		By default, sets a new undo point before deleting.
        -- 		|default-mappings|
    end
end, {
    desc = 'Custom Remap: Scroll up documentation window or fallback',
})

vim.keymap.set({ 'i', 's' }, '<C-d>', function()
    if is_docs_visible() then
        if require('myconfig.config').use_native_completion then
            require('myconfig.lsp.completion.documentation').scroll_docs(4)
        else
            require('cmp').mapping.scroll_docs(4)
        end
    else
        feedkeys('<C-d>') -- Default to default keymap of deleting text to the right
        -- 						*i_CTRL-D*
        -- CTRL-D		Delete one shiftwidth of indent at the start of the current
        -- 		line.  The indent is always rounded to a 'shiftwidth'.
    end
end, {
    desc = 'Custom Remap: Scroll down documentation window when visiblie or fallback',
})

vim.keymap.set({ 'i', 's' }, '<C-t>', function()
    if require('myconfig.config').use_native_completion then
        local is_hidden =
            require('myconfig.lsp.completion.documentation').is_documentation_disabled()
        require('myconfig.lsp.completion.documentation').hide_docs(
            not is_hidden
        )
    else
        local cmp = require('cmp')
        if cmp.visible_docs() then
            cmp.close_docs()
        else
            cmp.open_docs()
        end
    end
end, {
    desc = 'Custom Remap: Toggle the completion docs',
    --This replaces the keymap that adds one indent to the beginning of the line
})

-------------------------------------------------------------------------------
---Terminal keymaps
---

vim.keymap.set('n', '<leader>tt', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        start_insert = true,
        auto_insert = false,
        auto_close = false,
        namespace = 'normal_group',
    })
end, { desc = 'Custom: Toggle Terminal' })

vim.keymap.set('n', '<leader>tjh', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        start_insert = true,
        auto_insert = false,
        auto_close = false,
        namespace = 'normal_group',
        position = 'left',
    })
end, { desc = 'Custom: Toggle Terminal Left' })

vim.keymap.set('n', '<leader>tjj', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        start_insert = true,
        auto_insert = false,
        auto_close = false,
        namespace = 'normal_group',
        position = 'bottom',
    })
end, { desc = 'Custom: Toggle Terminal Bottom' })

vim.keymap.set('n', '<leader>tjk', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        start_insert = true,
        auto_insert = false,
        auto_close = false,
        namespace = 'normal_group',
        position = 'top',
    })
end, { desc = 'Custom: Toggle Terminal Top' })

vim.keymap.set('n', '<leader>tjl', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        start_insert = true,
        auto_insert = false,
        auto_close = false,
        namespace = 'normal_group',
        position = 'right',
    })
end, { desc = 'Custom: Toggle Terminal Right' })

vim.keymap.set('n', '<leader>tjf', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        start_insert = true,
        auto_close = false,
        interactive = true,
        namespace = 'normal_group',
        position = 'float',
    })
end, { desc = 'Custom: Toggle Floating Terminal' })

vim.keymap.set('n', '<leader>gs', function()
    local terminal = require('myconfig.terminal.terminal')
    terminal.toggle({
        cmd = 'lazygit',
        start_insert = true,
        auto_insert = false,
        auto_close = false,
        position = 'float',
        tui_mode = true,
    })
end, { desc = 'Custom: Toggle LazyGit' })

-------------------------------------------------------------------------------

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
    function() require('myconfig.utils.mapping').smart_nav('cnext') end,
    { desc = 'Custom - Quick Fix List: cnext quick fix navigation' }
)
vim.keymap.set(
    'n',
    '<C-k>',
    function() require('myconfig.utils.mapping').smart_nav('cprev') end,
    { desc = 'Custom - Quick Fix List: cprev quick fix navigation' }
)

vim.keymap.set('n', '<leader>qt', function()
    local qf_exists = false
    local tabid = vim.api.nvim_get_current_tabpage()
    local tabnr = vim.api.nvim_tabpage_get_number(tabid)
    for _, win in pairs(vim.fn.getwininfo()) do
        if win.quickfix == 1 and win.loclist == 0 and win.tabnr == tabnr then
            qf_exists = true
        end
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
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@function.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
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
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@function.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
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
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@call.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
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
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@call.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
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
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@class.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
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
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@class.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
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
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@conditional.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
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
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@conditional.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
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
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@loop.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
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
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@loop.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
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
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@parameter.inner',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
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
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@parameter.inner',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
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
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@comment.inner',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
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
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@comment.inner',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
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
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@comment.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
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
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@comment.outer',
                    'textobjects'
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
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
            key = 'gmn',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@function_declaration_name.inner',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
                    '@function_declaration_name.inner',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            desc = 'Custom: jump to the {previous|next} function name start',
            opts = {},
        },
        extreme = {
            key = 'gmN',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@function_declaration_name.inner',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
                    '@function_declaration_name.inner',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            desc = 'Custom: jump to the {previous|next} function name end',
            opts = {},
        },
    })
    :navigator({
        --visual mode: stays within buffer so visual mode would be useful
        default = {
            key = 'gt',
            mode = { 'n', 'x' },
            backward = function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@cast.outer',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
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
                require('nvim-treesitter-textobjects.move').goto_previous_end(
                    '@cast.outer',
                    config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
                )
            end,
            forward = function()
                require('nvim-treesitter-textobjects.move').goto_next_end(
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
        mode = { 'n', 'x' }, --Add some check so that non-visual visual mode keymaps don't get repeated
    })
    :navigator({
        default = {
            key = '',
            backward = function()
                if myoperations.isLastCallbackExtreme then
                    myoperations.repeat_extreme_backward_callback()
                else
                    myoperations.repeat_backward_callback()
                end
            end,
            forward = function()
                if myoperations.isLastCallbackExtreme then
                    myoperations.repeat_extreme_forward_callback()
                else
                    myoperations.repeat_forward_callback()
                end
            end,
            desc = 'Custom: Repeat my last {backward|forward} keymap for navigating lists (if extreme was used, will repeat extreme)',
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
                if myoperations.isLastCallbackExtreme then
                    myoperations.repeat_backward_callback()
                else
                    myoperations.repeat_extreme_backward_callback()
                end
            end,
            forward = function()
                if myoperations.isLastCallbackExtreme then
                    myoperations.repeat_forward_callback()
                else
                    myoperations.repeat_extreme_forward_callback()
                end
            end,
            desc = 'Custom: Repeat the extreme of my last "{backward|forward}" command navigating lists (if the last movement was extreme then the none extreme will be repeated)',
            opts = {},
        },
    })

-------------------------------------------------------------------------------
--- treesitter

vim.keymap.set(
    { 'x', 'o' },
    'a=',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@assignment.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of an assignment',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'i=',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@assignment.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of an assignment',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'il=',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@assignment.lhs',
            'textobjects'
        )
    end,
    {
        desc = 'Select left hand side of an assignment',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ir=',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@assignment.rhs',
            'textobjects'
        )
    end,
    {
        desc = 'Select right hand side of an assignment',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'aa',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@parameter.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of a parameter/argument',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ia',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@parameter.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of a parameter/argument',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ai',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@conditional.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of a conditional',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ii',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@conditional.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of a conditional',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ao',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@loop.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of a loop',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'io',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@loop.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of a loop',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'af',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@call.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of a function call',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'if',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@call.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of a function call',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'am',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@function.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of a method/function definition',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'im',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@function.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of a method/function definition',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ac',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@class.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Select outer part of a class',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ic',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@class.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Select inner part of a class',
    }
)

vim.keymap.set({ 'x', 'o' }, 'a<leader>c', function()
    require('nvim-treesitter-textobjects.select').select_textobject(
        -- I plan to replace this with a smarter version of the keymap
        '@comment.outer',
        'textobjects'
    )
end, {
    desc = 'Select outer part of a comment',
})

vim.keymap.set({ 'x', 'o' }, 'i<leader>c', function()
    require('nvim-treesitter-textobjects.select').select_textobject(
        -- I plan to replace this with a smarter version of the keymap
        '@comment.inner',
        'textobjects'
    )
end, {
    desc = 'Select inner part of a comment',
})

vim.keymap.set(
    { 'x', 'o' },
    'agt',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@cast.outer',
            config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
        )
    end,
    {

        desc = 'Select outer part of a type cast',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'igt',
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@cast.inner',
            config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP
        )
    end,
    {
        desc = 'Select inner part of a type cast',
    }
)
-------------------------------------------------------------------------------
---treesitter swap nodes
vim.keymap.set(
    'n',
    '<leader>vna',
    function()
        require('nvim-treesitter-textobjects.swap').swap_next(
            '@parameter.inner'
        )
    end,
    {
        desc = 'TS: swap next parameter',
    }
)

vim.keymap.set(
    'n',
    '<leader>vpa',
    function()
        require('nvim-treesitter-textobjects.swap').swap_previous(
            '@parameter.inner'
        )
    end,
    {
        desc = 'TS: swap previous parameter',
    }
)

vim.keymap.set('n', '<leader>vn:', function()
    require('nvim-treesitter-textobjects.swap').swap_next('@property.outer') -- swap object property with next
end, {
    desc = 'TS: swap object property with next',
})

vim.keymap.set('n', '<leader>vp:', function()
    require('nvim-treesitter-textobjects.swap').swap_previous('@property.outer') -- swap object property with next
end, {
    desc = 'TS: swap object property with previous',
})

vim.keymap.set('n', '<leader>vnm', function()
    require('nvim-treesitter-textobjects.swap').swap_next('@function.outer') -- swap function with next
end, {
    desc = 'TS: swap function with next',
})

vim.keymap.set('n', '<leader>vpm', function()
    require('nvim-treesitter-textobjects.swap').swap_previous('@function.outer') -- swap function with previous
end, {
    desc = 'TS: swap function with previous',
})

-------------------------------------------------------------------------------
vim.keymap.del({ 'o', 'n', 'x' }, 'gc')

vim.keymap.set(
    { 'o' },
    'gc',
    function() require('myconfig.utils.mapping').comment_lines_textobject() end,
    { desc = 'Comment textobject identical to gc operator' }
    --note: vgc does not select the commented lines. It really does a block
    --comment arround the character (which in my opinion pretty useless so I might
    --try to fix that) this is because it isn't using the textobject gc it is using
    --the gc visual mapping defined in numToStr/Comment.nvim
)

vim.keymap.set(
    { 'o', 'x' },
    'agc',
    function()
        require('myconfig.utils.mapping').around_comment_lines_textobject()
    end,
    { desc = 'Comment textobject with treesitter fallback' }
)

vim.keymap.set(
    { 'o', 'x' },
    'igi',
    ":<c-u>lua require('myconfig.utils.mapping').select_indent()<cr>",
    { desc = 'Select inner indent textobject', silent = true }
)

vim.keymap.set(
    { 'o', 'x' },
    'agi',
    ":<c-u>lua require('myconfig.utils.mapping').select_indent(true)<cr>",
    { desc = 'Select around indent textobject', silent = true }
)
