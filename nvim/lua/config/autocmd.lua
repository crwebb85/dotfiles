local config = require('config.config')

-------------------------------------------------------------------------------
--- Temporarily highlight text selection that was yanked
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('yank_group', { clear = true }),
    callback = function() vim.highlight.on_yank() end,
})

-------------------------------------------------------------------------------
--- Terminal Autocmds
vim.api.nvim_create_autocmd('TermOpen', {
    group = vim.api.nvim_create_augroup('my.terminal', {}),
    desc = 'My Default settings for :terminal buffers',
    callback = function(args)
        --Set keymaps
        vim.keymap.set('t', '<leader><esc>', [[<C-\><C-n>]], {
            buffer = args.buf,
            desc = 'Terminal: Esc to terminal normal mode',
        })
        vim.keymap.set(
            't',
            '<leader>',
            [[<leader>]],
            --Note I only need this keymap so that typing space by itself still works and doesn't
            --permanently prompt me for the <esc> key because of the above keymap <leader><esc>
            { buffer = args.buf, desc = 'Terminal: enter leader key' }
        )
        vim.keymap.set(
            't',
            '<C-h>',
            [[<Cmd>wincmd h<CR>]],
            { buffer = args.buf, desc = 'Terminal: Move to left window' }
        )
        vim.keymap.set(
            't',
            '<C-j>',
            [[<Cmd>wincmd j<CR>]],
            { buffer = args.buf, desc = 'Terminal: Move to lower window' }
        )
        vim.keymap.set(
            't',
            '<C-k>',
            [[<Cmd>wincmd k<CR>]],
            { buffer = args.buf, desc = 'Terminal: Move to upper window' }
        )
        vim.keymap.set(
            't',
            '<C-l>',
            [[<Cmd>wincmd l<CR>]],
            { buffer = args.buf, desc = 'Terminal: Move to right window' }
        )
        vim.keymap.set(
            't',
            '<C-w>',
            [[<C-\><C-n><C-w>]],
            { buffer = args.buf, desc = 'Terminal: Trigger Window keymaps' }
        )

        ---Overrides defaults from _defaults.lua
        vim.wo[0][0].number = true
        vim.wo[0][0].relativenumber = true
        vim.wo[0][0].signcolumn = 'yes'
        vim.wo[0][0].spell = false

        ---Setup keymaps and window settings for my terminal managers
        if vim.b[args.buf].my_terminal ~= nil then
            vim.wo[0][0].sidescrolloff = 0
            vim.wo[0][0].scrolloff = 0
            vim.wo[0][0].cursorcolumn = false
            vim.wo[0][0].cursorline = false
            vim.wo[0][0].cursorlineopt = 'both'
            vim.wo[0][0].colorcolumn = ''
            vim.wo[0][0].fillchars = 'eob: ,lastline:…'
            vim.wo[0][0].listchars = 'extends:…,tab:  '
            vim.keymap.set('n', 'gf', function()
                local terminal_manager =
                    require('config.terminal.terminal').get_terminal_manager_by_bufnr(
                        args.buf
                    )
                if terminal_manager == nil then return end

                local cfile = vim.fn.expand('<cfile>')
                local path = vim.fn.findfile(cfile, '**')
                if path == '' then path = vim.fn.finddir(cfile, '**') end

                if path == '' then
                    vim.notify(
                        'No file/directory under cursor',
                        vim.log.levels.WARN
                    )
                else
                    local window_manager = terminal_manager:get_window_manager()
                    if
                        window_manager
                        and window_manager.position == 'float'
                    then
                        terminal_manager:hide()
                    end
                    vim.schedule(function() require('oil').open(path) end)
                end
            end, {
                buffer = args.buf,
                desc = 'Custom Remap: Go to file under cursor (terminal edition)',
            })
            vim.keymap.set('t', '<esc>', function()
                local terminal_manager =
                    require('config.terminal.terminal').get_terminal_manager_by_bufnr(
                        args.buf
                    )
                if terminal_manager == nil then return end
                return terminal_manager:escape_key_triggered()
            end, {
                expr = true,
                buffer = args.buf,
                desc = 'Custom Terminal: Double escape to normal mode',
            })
            vim.keymap.set({ 'n', 't' }, '<C-q>', function()
                local terminal_manager =
                    require('config.terminal.terminal').get_terminal_manager_by_bufnr(
                        args.buf
                    )
                if terminal_manager == nil then return end

                terminal_manager:hide()
            end, {
                buffer = args.buf,
                desc = 'Custom Terminal: Hide terminal',
            })
        end
    end,
})

-------------------------------------------------------------------------------
--- Dockerfile autocmds

-- Dockerfile filetype
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    desc = 'Set file type for Dockerfile*',
    pattern = { 'Dockerfile*', '*.Dockerfile', '*.dockerfile' },
    command = [[set ft=dockerfile]],
})

-------------------------------------------------------------------------------
--- Add keybindings/settings to specific buffer types

-- Close some filetypes with <q>
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('close_with_q', { clear = true }),
    pattern = {
        'PlenaryTestPopup',
        'help',
        'lspinfo',
        'man',
        'notify',
        'startuptime',
        'tsplayground',
        'checkhealth',
        'neotest-output',
        'neotest-summary',
        'neotest-output-panel',
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set(
            'n',
            'q',
            '<cmd>close<CR>',
            { buffer = event.buf, silent = true, desc = 'Custom: Close window' }
        )
        vim.wo[0][0].colorcolumn = '0' --removes the column I normal have at 80 characters
        vim.cmd.stopinsert()
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
-- Highlight cursor line briefly when neovim regains focus.  This helps to
-- reorient the user and tell them where they are in the buffer.
-- Stolen from https://www.reddit.com/r/neovim/comments/1cytkbq/comment/l5gg32x/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
-- which was stolen from https://developer.ibm.com/tutorials/l-vim-script-5
vim.api.nvim_create_autocmd('FocusGained', {
    pattern = '*',
    callback = function(_)
        -- vim.print('highlight')
        vim.wo.cursorline = true
        vim.cmd('redraw')
        vim.defer_fn(function() vim.wo.cursorline = false end, 600)
    end,
    group = vim.api.nvim_create_augroup(
        'draw_temp_cursor_line',
        { clear = true }
    ),
})

-------------------------------------------------------------------------------
-- Change line numbers based on the mode
--

local change_relative_line_number_group =
    vim.api.nvim_create_augroup('change_relative_line_number', { clear = true })
vim.api.nvim_create_autocmd('ModeChanged', {
    callback = function(args)
        local modes = vim.split(args.match, ':')
        -- vim.print(modes)
        local prev_mode = modes[1]
        local new_mode = modes[2]
        if new_mode == 'c' and vim.wo.number == true then
            vim.wo.relativenumber = false
            vim.wo.cursorline = true
            -- TODO temporarily removing this redraw because redraws now clear the selection messages
            -- so it was preventing me seeing which code actions I could pick
            --vim.cmd('redraw')
        elseif prev_mode == 'c' and vim.wo.number == true then
            vim.wo.relativenumber = true
            vim.wo.cursorline = false
            -- TODO temporarily removing this redraw because redraws now clear the selection messages
            -- so it was preventing me seeing which code actions I could pick
            --vim.cmd('redraw')
        end
    end,
    group = change_relative_line_number_group,
})

vim.api.nvim_create_autocmd({ 'WinEnter' }, {
    callback = function(_)
        if vim.wo.number == true then vim.wo.relativenumber = true end
    end,
    group = change_relative_line_number_group,
})
vim.api.nvim_create_autocmd({ 'WinLeave' }, {
    callback = function(_)
        if vim.wo.number == true then vim.wo.relativenumber = false end
    end,
    group = change_relative_line_number_group,
})

-------------------------------------------------------------------------------
---Make library files readonly

local READONLY_LIBRARY_DIR_PATTERN =
    vim.glob.to_lpeg('**/{venv,node_modules}/**')

local LAZY_PLUGIN_FILEPATH_PATTERN = (function()
    local data_path = vim.fn.stdpath('data')
    if type(data_path) == 'string' then
        local lazy_plugin_path =
            string.lower(vim.fs.normalize(vim.fs.joinpath(data_path, 'lazy')))
        return vim.glob.to_lpeg(lazy_plugin_path .. '/**')
    end
    return nil
end)()

local NVIM_RUNTIME_FILEPATH_PATTERN = (function()
    local nvim_runtime_filepath = string.lower(vim.fs.normalize('$VIMRUNTIME'))
    return vim.glob.to_lpeg(nvim_runtime_filepath .. '/**')
end)()

vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
    callback = function(args)
        local name =
            string.lower(vim.fs.normalize(vim.api.nvim_buf_get_name(args.buf)))

        if
            READONLY_LIBRARY_DIR_PATTERN:match(name) ~= nil
            or (LAZY_PLUGIN_FILEPATH_PATTERN ~= nil and LAZY_PLUGIN_FILEPATH_PATTERN:match(
                name
            ) ~= nil)
            or NVIM_RUNTIME_FILEPATH_PATTERN:match(name) ~= nil
        then
            vim.bo[args.buf].readonly = true
            vim.bo[args.buf].modifiable = false
        end
    end,
})

-------------------------------------------------------------------------------
---Big File feature disabling
---based on https://github.com/LunarVim/bigfile.nvim/blob/33eb067e3d7029ac77e081cfe7c45361887a311a/lua/bigfile/init.lua

local big_file_augroup = vim.api.nvim_create_augroup('bigfile', {})

---@param bufnr number
---@return integer|nil size in MiB if buffer is valid, nil otherwise
local function get_buf_size(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local ok, stats = pcall(
        function() return vim.uv.fs_stat(vim.api.nvim_buf_get_name(bufnr)) end
    )
    if not (ok and stats) then return end
    return math.floor(0.5 + (stats.size / (1024 * 1024)))
end

---@param bufnr number
local function pre_bufread_callback(bufnr)
    if vim.b[bufnr].is_big_file == true then return end

    local filesize = get_buf_size(bufnr)
    local bigfile_detected = (
        filesize ~= nil and filesize >= config.bigfile_filesize
    )

    vim.b[bufnr].is_big_file = bigfile_detected
    if not bigfile_detected then return end

    ----------
    --   lsp
    --   Note: I moved the code that disables the lsp for large file to my
    --   lsp configuration
    -- vim.api.nvim_create_autocmd({ 'LspAttach' }, {
    --     buffer = bufnr,
    --     callback = function(args)
    --         vim.schedule(
    --             function() vim.lsp.buf_detach_client(bufnr, args.data.client_id) end
    --         )
    --     end,
    -- })

    ----------
    --   treesitter
    --   I don't think I can can simplify this without by doing this in the treesitter
    --   config since I think other plugins can add modules
    local is_ts_configured = false
    local function configure_treesitter()
        local status_ok, ts_config = pcall(require, 'nvim-treesitter.configs')
        if not status_ok then return end

        local disable_cb = function(_, buf)
            local detected = vim.b[buf].is_big_file_treesitter_disabled == true
            return detected
        end

        for _, mod_name in ipairs(ts_config.available_modules()) do
            local module_config = ts_config.get_module(mod_name) or {}
            local old_disabled = module_config.disable
            module_config.disable = function(lang, buf)
                return disable_cb(lang, buf)
                    or (type(old_disabled) == 'table' and vim.tbl_contains(
                        old_disabled,
                        lang
                    ))
                    or (
                        type(old_disabled) == 'function'
                        and old_disabled(lang, buf)
                    )
            end
        end

        is_ts_configured = true
    end
    if not is_ts_configured then configure_treesitter() end

    vim.b[bufnr].is_big_file_treesitter_disabled = true

    ----------
    --   matchparen
    --   if the cursor is on a parenthesis, bracket, or square bracket the matchparen plugin
    --   highlights the matching one.
    --
    --   The below autocmds make the compromise that matchparen will be disabled while
    --   a bigfile is the active(the buffer displayed) buffer in any window. Once there is no active bigfile buffer
    --   in any window matchparen will be reenabled.
    --
    -- Note BufWinLeave does not trigger if two windows have the same buffer open
    -- open and one of the windows changes buffers

    if vim.fn.exists(':DoMatchParen') == 2 then
        vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
            callback = function() vim.cmd('NoMatchParen') end,
            buffer = bufnr,
        })
        vim.api.nvim_create_autocmd({ 'BufWinLeave' }, {
            callback = function()
                --TODO actually check if there isn't a third window that is a large file before
                --renabling matchparen (I might use a global variable to track which windows have a big file open in it)
                vim.cmd('DoMatchParen')
            end,
            buffer = bufnr,
        })
    end

    ----------
    --   syntax and filetype
    vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
        callback = function()
            vim.cmd('syntax clear')
            vim.bo.syntax = 'OFF'
            vim.bo.filetype = ''
        end,
        buffer = bufnr,
    })

    ----------
    --   buffer options
    vim.bo.swapfile = false
    vim.bo.undolevels = -1

    ----------
    --   global options

    -- I don't really get what undoreload does. It was set to zero by bigfile.nvim plugin
    -- but since I don't understand what it does and it is a global property so if it changes
    -- I won't know how that effects my config which could cause unexpected behavior.
    -- For that reason, I will comment it out unless I still have preformance issues.
    -- vim.go.undoreload = 0

    ----------
    --   window options

    --The below explains the observations I found of what happens if you set a local window
    --setting with this context hopefully you will be able to understand why I did the weird autocmds
    --farther down for reseting window settings back to the default value
    --
    -- 1. opening buffer 1 and running `:lua vim.wo.spell = false` disables spell
    --    for the buffer while in that window
    -- 2. now switching to a new (never opened before) buffer in the same window
    --    will also have spelling disabled as well
    -- 3. switching to an existing buffer (one that has been opened before
    --    disabling spelling) will have the spelling enabled
    --This behavior happens for all window options.

    --Okay I think this works for reseting the window settings back after leaving
    --the big file buffer. Trying to restrict these autocmds to set the correct settings
    --for that specific window without a bunch of memory leaks was a pain
    --This is used to set:
    -- vim.wo.foldmethod = 'manual'
    -- vim.wo.list = false
    -- vim.wo.spell = false
    -- but change them back when leaving the big file buffer
    -- vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        callback = function()
            local old_foldmethod = vim.wo.foldmethod
            local old_list = vim.wo.list
            local old_spell = vim.wo.spell
            local win_id = vim.api.nvim_get_current_win()
            vim.wo.foldmethod = 'manual'
            vim.wo.list = false
            vim.wo.spell = false

            --using a dynamic augroup name. I want only one of the following
            --BufWinLeave autocmd to exist per window that the buffer is open in
            --By using the window id I can make sure that window settings are reset
            --for only the window that the bigfile buffer is leaving from
            local bigfile_reset_window_settings_augroup =
                vim.api.nvim_create_augroup(
                    'bigfile_reset_window_settings_' .. win_id,
                    {}
                )
            vim.api.nvim_create_autocmd({ 'BufLeave' }, {
                group = bigfile_reset_window_settings_augroup,
                callback = function(_)
                    if win_id == vim.api.nvim_get_current_win() then
                        vim.wo.foldmethod = old_foldmethod
                        vim.wo.list = old_list
                        vim.wo.spell = old_spell

                        --cleanup this augroup
                        vim.api.nvim_del_augroup_by_id(
                            bigfile_reset_window_settings_augroup
                        )
                    end
                end,
                buffer = bufnr,
            })
        end,
        buffer = bufnr,
    })
end

vim.api.nvim_create_autocmd('BufReadPre', {
    pattern = '*',
    group = big_file_augroup,
    callback = function(args) pre_bufread_callback(args.buf) end,
    desc = string.format(
        'Performance rule for handling files over %sMiB',
        config.bigfile_filesize
    ),
})

-------------------------------------------------------------------------------
---Fix macros so that keymap timeout is turned off when recording macros. I was
---having issues where when I record a macro I would hit the keymaps too slowly
---and they would timeout

local macro_keymap_augroup =
    vim.api.nvim_create_augroup('brain_slows_down_during_macro_recording', {})
vim.api.nvim_create_autocmd('RecordingEnter', {
    pattern = '*',
    group = macro_keymap_augroup,
    callback = function() vim.go.timeout = false end,
    desc = 'Disable keymap timeout during macro recording since I type a lot slower when recording macros',
    --Note this is also useful since keymaps that only activate after a timeout can't be used during macros
    --since the macro doesn't wait a timeout (there might be a way to make it sleep for the timeout but I don't
    --care since I will never use that and just won't try to support that functionality)
})

vim.api.nvim_create_autocmd('RecordingLeave', {
    pattern = '*',
    group = macro_keymap_augroup,
    callback = function() vim.go.timeout = true end,
    desc = 'Re-enable keymap timeout after macro recording is over',
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
