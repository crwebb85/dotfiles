vim.g.mapleader = ' '

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
    ---------------------------------------------------------------------------
    -- Git integration
    {
        'tpope/vim-fugitive',
        version = '*',
        lazy = true,
        event = 'VeryLazy',
    },
    -- Adds git diffview
    {
        'sindrets/diffview.nvim',
        lazy = true,
        config = function()
            local actions = require('diffview.actions')
            local diffview_keymaps = {
                {
                    'n',
                    '<leader>ggo',
                    actions.goto_file_tab,
                    {
                        desc = 'Diffview: Open the file in a new tabpage',
                    },
                },
                {
                    'n',
                    'q',
                    '<cmd>DiffviewClose<CR>',
                    { silent = true },
                },
                {
                    'n',
                    'cc',
                    ':tab Git commit | startinsert <CR>',
                    {
                        desc = 'Diffview: Open commit message with Vim Fugitive',
                    },
                },
            }

            require('diffview').setup({
                keymaps = {
                    view = diffview_keymaps,
                    file_panel = diffview_keymaps,
                    file_history_panel = diffview_keymaps,
                },
            })
        end,
        keys = {
            {
                '<leader>gd',
                function()
                    if next(require('diffview.lib').views) == nil then
                        require('diffview').open({})
                    else
                        require('diffview').close()
                    end
                end,
                desc = 'Diffview: Toggle',
            },
            {
                '<leader>gh',
                '<cmd>DiffviewFileHistory<cr>',
                desc = 'Diffview: Open Git Repo history',
            },

            {
                '<leader>ghf',
                '<cmd>DiffviewFileHistory --follow %<cr>',
                desc = 'Diffview: Open Git File history',
            },

            {
                '<leader>ghl',
                "<Esc><Cmd>'<,'>DiffviewFileHistory --follow<CR>",
                mode = 'v',
                desc = 'Diffview: Open Git File history over selected text',
            },

            {
                '<leader>ghl',
                '<Cmd>.DiffviewFileHistory --follow<CR>',
                desc = 'Diffview: Open Git history for the line',
            },

            -- Diff against local master branch
            {
                '<leader>ghm',
                function()
                    vim.cmd(
                        'DiffviewOpen '
                            .. require('config.utils').get_default_branch_name()
                    )
                end,
                desc = 'Diffview: Diff against master',
            },

            -- Diff against remote master branch
            {
                '<leader>ghM',
                function()
                    vim.cmd(
                        'DiffviewOpen HEAD..origin/'
                            .. require('config.utils').get_default_branch_name()
                    )
                end,
                desc = 'Diffview: Diff against origin/master',
            },
        },
    },
    -- Adds an api wrapper arround git which I use in my heirline setup
    -- Adds Gitblame
    -- Adds sidbar showing lines changed
    {
        'lewis6991/gitsigns.nvim',
        lazy = true,
        event = 'VeryLazy',
        config = true,
        keys = {

            -- Highlight changed words.
            {
                '<leader>gvw',
                function() require('gitsigns').toggle_word_diff() end,
                desc = 'Gitsigns: Toggle word diff',
            },

            -- Highlight added lines.
            {
                '<leader>gvl',
                function() require('gitsigns').toggle_linehl() end,
                desc = 'Gitsigns: Toggle line highlight',
            },

            -- Highlight removed lines.
            {
                '<leader>gvd',
                function() require('gitsigns').toggle_deleted() end,
                desc = 'Gitsigns: Toggle deleted (all)',
            },
            {
                '<leader>gvh',
                function() require('gitsigns').preview_hunk() end,
                desc = 'Gitsigns: Preview hunk',
            },
            {
                ']h',
                require('config.utils').dot_repeat(function()
                    if vim.wo.diff then return ']h' end
                    vim.schedule(function() require('gitsigns').next_hunk() end)
                    return '<Ignore>'
                end),
                desc = 'Gitsigns: Go to next hunk (dot repeatable)',
                expr = true,
            },
            {
                '[h',
                require('config.utils').dot_repeat(function()
                    if vim.wo.diff then return '[h' end
                    vim.schedule(function() require('gitsigns').prev_hunk() end)
                    return '<Ignore>'
                end),
                desc = 'Gitsigns: Go to previous hunk (dot repeatable)',
                expr = true,
            },
        },
    },

    ---------------------------------------------------------------------------
    -- Navigation

    -- Fuzzy finder (for many things not just file finder)
    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim', -- telescope uses plenary to create the UI
            {
                'crwebb85/telescope-media-files.nvim',
                -- dev = true,
            },
        },
        lazy = true,
        cmd = { 'Telescope' },
        keys = {

            {
                '<leader>ff',
                function() require('telescope.builtin').find_files() end,
                desc = 'Telescope: find files',
            },
            {
                '<leader>fs',
                function() require('telescope.builtin').grep_string() end,
                desc = 'Telescope: grep at cursor/selection',
                mode = { 'n', 'v' },
            },
            {
                '<leader>fg',
                function() require('telescope.builtin').live_grep() end,
                desc = 'Telescope: live_grep',
            },
            {
                '<leader>fb',
                function() require('telescope.builtin').buffers() end,
                desc = 'Telescope: open buffers',
            },
            {
                '<leader>fh',
                function() require('telescope.builtin').help_tags() end,
                desc = 'Telescope: help tags',
                mode = { 'n' },
            },
            {
                '<leader>fh',
                function()
                    -- based on https://github.com/nvim-telescope/telescope.nvim/issues/1923#issuecomment-1122642431
                    local function getVisualSelection()
                        vim.cmd('noau normal! "vy"')
                        local text = vim.fn.getreg('v')
                        vim.fn.setreg('v', {})

                        if type(text) ~= 'string' then return '' end

                        text = string.gsub(text, '\n', '')
                        if #text > 0 then
                            return text
                        else
                            return ''
                        end
                    end

                    local text = getVisualSelection()
                    require('telescope.builtin').help_tags({
                        default_text = text,
                    })
                end,
                desc = 'Telescope: help tags',
                mode = { 'v' },
            },
            {
                '<leader>fk',
                function() require('telescope.builtin').keymaps() end,
                desc = 'Telescope: keymaps',
            },
            {
                '<leader>fd',
                function() require('telescope.builtin').spell_suggest() end,
                desc = 'Telescope: suggest spelling (search dictionary)',
            },
        },
        opts = {
            defaults = {
                -- setting initial mode to 'normal'
                -- will allow me to have the telescope prompt in normal mode
                -- which is sometimes useful but not something I want normally enabled

                -- initial_mode = 'normal',

                dynamic_preview_title = true,
                mappings = {
                    i = {

                        ['<CR>'] = function(...)
                            require('telescope.actions').select_default(...)

                            local escape_key = vim.api.nvim_replace_termcodes(
                                '<ESC>',
                                true,
                                false,
                                true
                            )
                            vim.api.nvim_feedkeys(escape_key, 'm', false) -- Set mode to normal mode
                        end,
                        ['<C-b>'] = function(args)
                            require('telescope.actions').delete_buffer(args)
                        end,
                    },
                    n = {
                        ['<C-b>'] = function(args)
                            require('telescope.actions').delete_buffer(args)
                        end,
                    },
                },
            },
            pickers = {
                find_files = {
                    find_command = {
                        'rg',
                        '--files',
                        '--hidden',
                        '--glob',
                        '!.git',
                        '--glob',
                        '!node_modules',
                        '--glob',
                        '!venv',
                        '--glob',
                        '!.venv',
                    },
                },
            },
            extensions = {
                media_files = {
                    -- filetypes whitelist
                    -- defaults to {"png", "jpg", "mp4", "webm", "pdf"}
                    filetypes = { 'png', 'webp', 'jpg', 'jpeg' },
                    -- find command (defaults to `fd`)
                    find_cmd = 'rg',
                },
            },
        },
        config = function(_, opts)
            require('telescope').setup(opts)
            require('telescope').load_extension('media_files')
        end,
    },

    -- Harpoon (fast file navigation between pinned files)
    {
        'theprimeagen/harpoon',
        lazy = true,
        config = true,
        keys = {
            {
                '<leader>a',
                function() require('harpoon.mark').add_file() end,
                desc = 'Harpoon: Add file',
            },
            {
                '<C-e>',
                function() require('harpoon.ui').toggle_quick_menu() end,
                desc = 'Harpoon: Toggle quick menu',
            },
            -- Protip: To reorder the entries in harpoon quick menu use `Vd` to cut the line and `P` to paste where you want it

            -- Harpoon quick navigation
            {
                '<leader>1',
                function() require('harpoon.ui').nav_file(1) end,
                desc = 'Harpoon: Go to file 1',
            },
            {
                '<leader>2',
                function() require('harpoon.ui').nav_file(2) end,
                desc = 'Harpoon: Go to file 2',
            },
            {
                '<leader>3',
                function() require('harpoon.ui').nav_file(3) end,
                desc = 'Harpoon: Go to file 3',
            },
            {
                '<leader>4',
                function() require('harpoon.ui').nav_file(4) end,
                desc = 'Harpoon: Go to file 4',
            },
            {
                '<leader>5',
                function() require('harpoon.ui').nav_file(5) end,
                desc = 'Harpoon: Go to file 5',
            },
            {
                '<leader>6',
                function() require('harpoon.ui').nav_file(6) end,
                desc = 'Harpoon: Go to file 6',
            },
            {
                '<leader>7',
                function() require('harpoon.ui').nav_file(7) end,
                desc = 'Harpoon: Go to file 7',
            },
            {
                '<leader>8',
                function() require('harpoon.ui').nav_file(8) end,
                desc = 'Harpoon: Go to file 8',
            },
            {
                '<leader>9',
                function() require('harpoon.ui').nav_file(9) end,
                desc = 'Harpoon: Go to file 9',
            },
            {
                '<leader>0',
                function() require('harpoon.ui').nav_file(0) end,
                desc = 'Harpoon: Go to file 0',
            },
        },
    },

    {
        'stevearc/oil.nvim',
        lazy = true,
        keys = {
            {
                '<leader>ol',
                '<CMD>Oil<CR>',
                desc = 'Oil: Open parent directory',
            },
        },
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        opts = {
            keymaps = {
                ['<leader>gf'] = {
                    callback = function()
                        local oil = require('oil')
                        local entry = oil.get_cursor_entry()

                        if entry == nil then return end
                        if entry['type'] == 'file' then
                            local dir = oil.get_current_dir()
                            local fileName = entry['name']
                            local fullName = dir .. fileName
                            require('utils.image_preview').preview_image(
                                vim.fs.normalize(fullName)
                            )
                        end
                    end,
                    desc = 'Open image preview',
                    mode = 'n',
                },
            },
        },
        config = function(_, opts) require('oil').setup(opts) end,
    },

    ---------------------------------------------------------------------------
    -- Utils

    --Big file/Macro speed increases
    {
        'pteroctopus/faster.nvim',
        lazy = true,
        event = 'VeryLazy',
        config = true,
    },

    -- A util library
    {
        'nvim-lua/plenary.nvim',
        lazy = true,
    },

    -- Comment toggling
    {
        'numToStr/Comment.nvim',
        lazy = true,
        event = 'VeryLazy',
        opts = {},
        config = true,
    },
    -- Keymap suggestions
    {
        'folke/which-key.nvim',
        lazy = true,
        event = 'VeryLazy',
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
        end,
        config = true,
    },
    -- Adds motions to wrap text in qoutes/brackets/tags/etc
    -- using the same motions I use to yank text
    {
        'kylechui/nvim-surround',
        lazy = true,
        event = 'VeryLazy',
        config = true,
    },
    -- File search and replace
    {
        'nvim-pack/nvim-spectre',
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        lazy = true,
        event = 'VeryLazy',
        opts = {},
        config = true,
        keys = {
            {
                '<leader>st',
                function() require('spectre').toggle() end,
                mode = { 'n' },
                desc = 'Spectre: Toggle Spectre',
            },
            {
                '<leader>sw',
                function()
                    require('spectre').open_visual({ select_word = true })
                end,
                mode = { 'n' },
                desc = 'Spectre: Search current word',
            },
            {
                '<leader>sw',
                function() require('spectre').open_visual() end,
                mode = { 'v' },
                desc = 'Spectre: Search current word',
            },
            {
                '<leader>sp',
                function()
                    require('spectre').open_file_search({ select_word = true })
                end,
                mode = { 'n' },
                desc = 'Spectre: Search on current file',
            },
        },
    },
    -- Adds markdown preview (opens in browser)
    {
        'iamcco/markdown-preview.nvim',
        cmd = {
            'MarkdownPreviewToggle',
            'MarkdownPreview',
            'MarkdownPreviewStop',
        },
        ft = { 'markdown' },
        build = function() vim.fn['mkdp#util#install']() end,
        lazy = true,
    },
    -- Adds refactor commands
    {
        'ThePrimeagen/refactoring.nvim',
        lazy = true,
        config = true,
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
        },
        cmd = { 'Refactor' },
        keys = {
            {
                '<leader>re',
                function() require('refactoring').refactor('Extract Function') end,
                mode = { 'x' },
                desc = 'Refactor: Extract Function',
            },
            {
                '<leader>rf',
                function()
                    require('refactoring').refactor('Extract Function To File')
                end,
                mode = { 'x' },
                desc = 'Refactor: Extract Function To File',
            }, -- Extract variable supports only visual mode
            {
                '<leader>rv',
                function() require('refactoring').refactor('Extract Variable') end,
                mode = { 'x' },
                desc = 'Refactor: Extract Variable',
            }, -- Inline func supports only normal
            {
                '<leader>rI',
                function() require('refactoring').refactor('Inline Function') end,
                mode = { 'n' },
                desc = 'Refactor: Inline Function',
            }, -- Inline var supports both normal and visual mode
            {
                '<leader>ri',
                function() require('refactoring').refactor('Inline Variable') end,
                mode = { 'n', 'x' },
                desc = 'Refactor: Inline Variable',
            }, -- Extract block supports only normal mode
            {
                '<leader>rb',
                function() require('refactoring').refactor('Extract Block') end,
                mode = { 'n' },
                desc = 'Refactor: Extract Block',
            }, -- Extract block supports only normal mode
            {
                '<leader>rbf',
                function()
                    require('refactoring').refactor('Extract Block To File')
                end,
                mode = { 'n' },
                desc = 'Refactor: Extract Block To File',
            },
            {
                '<leader>rr',
                function() require('refactoring').select_refactor({}) end,
                mode = { 'n', 'x' },
                desc = 'Refactor: Prompt for a refactor',
            },
            {
                '<leader>rp',
                function()
                    require('refactoring').debug.printf({ below = false })
                end,
                mode = { 'n' },
                desc = 'Refactor: Printf',
            },
            {
                '<leader>rv',
                function() require('refactoring').debug.print_var({}) end,
                mode = { 'n', 'x' },
                desc = 'Refactor: Print var',
            },
            {
                '<leader>rc',
                function() require('refactoring').debug.cleanup({}) end,
                mode = { 'n' },
                desc = 'Refactor: Cleanup debugging print statements',
            },
        },
    },
    -- Open terminal within neovim
    {
        'akinsho/toggleterm.nvim',
        lazy = true,
        config = function(_, opts)
            if require('utils.platform').is.win then
                local powershell_options = {
                    shell = vim.fn.executable('pwsh') == 1 and 'pwsh'
                        or 'powershell',
                    shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::Default;',
                    shellredir = '-RedirectStandardOutput %s -NoNewWindow -Wait',
                    shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode',
                    shellquote = '',
                    shellxquote = '',
                }

                for option, value in pairs(powershell_options) do
                    vim.opt[option] = value
                end
            end
            require('toggleterm').setup(opts)
        end,
        cmd = { 'ToggleTerm' },
        keys = {
            {
                '<leader>tt',
                '<cmd>exe v:count1 . "ToggleTerm"<CR>',
                desc = 'Toggleterm: Toggle',
            },
            {

                [[<C-\>]],
                '<cmd>exe v:count1 . "ToggleTerm"<CR>',
                desc = 'ToggleTerm: Toggle',
                mode = { 'n', 'i' },
            },
        },
    },
    -- Diagnostic info
    {
        'folke/trouble.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        lazy = true,
        config = true,
        cmd = { 'Trouble', 'TroubleToggle' },
        keys = {
            {
                '<leader>xx',
                function() require('trouble').toggle() end,
                desc = 'Trouble: Toggle UI',
            },
            {
                '<leader>xw',
                function() require('trouble').toggle('workspace_diagnostics') end,
                desc = 'Trouble: Toggle workspace diagnostics',
            },
            {
                '<leader>xd',
                function() require('trouble').toggle('document_diagnostics') end,
                desc = 'Trouble: Toggle document diagnostics',
            },
            {
                '<leader>xq',
                function() require('trouble').toggle('quickfix') end,
                desc = 'Trouble: Toggle quickfix list (Using Troubles UI)',
            },
            {
                '<leader>xl',
                function() require('trouble').toggle('loclist') end,
                desc = 'Trouble: Toggle loclist',
            },
            {
                '<leader>xr',
                function() require('trouble').toggle('lsp_references') end,
                desc = 'Trouble: Toggle lsp references',
            },
            {
                '<leader>xn',
                function()
                    require('trouble').next({ skip_groups = true, jump = true })
                end,
                desc = 'Trouble: jump to the next item, skipping the groups',
            },
            {
                '<leader>xp',
                function()
                    require('trouble').previous({
                        skip_groups = true,
                        jump = true,
                    })
                end,
                desc = 'Trouble: jump to the previous item, skipping the groups',
            },
            {
                '<leader>xf',
                function()
                    require('trouble').first({ skip_groups = true, jump = true })
                end,
                desc = 'Trouble: jump to the first item, skipping the groups',
            },
            {
                '<leader>xl',
                function()
                    require('trouble').last({ skip_groups = true, jump = true })
                end,
                desc = 'Trouble: jump to the last item, skipping the groups',
            },
        },
    },
    -- Query ollama
    {
        'nomnivore/ollama.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        lazy = true,
        config = true,
        -- All the user commands added by the plugin
        cmd = { 'Ollama', 'OllamaModel', 'OllamaServe', 'OllamaServeStop' },

        -- Sample keybind for prompting. Note that the <c-u> is important for selections to work properly.
        keys = {
            {
                '<leader>oo',
                ":<c-u>lua require('ollama').prompt()<cr>",
                desc = 'Ollama: Open prompt',
                mode = { 'n', 'v' },
            },
        },
    },
    -- {
    --     'stevearc/stickybuf.nvim',
    --     lazy = true,
    --     event = 'VeryLazy',
    --     config = function()
    --         require('stickybuf').setup({
    --             -- This function is run on BufEnter to determine pinning should be activated
    --             get_auto_pin = function(bufnr)
    --                 --[[
    --                 TODO play around with either this libray or create my own autocmds
    --                 to handle auto closing popup windows figure out how to handle diffview
    --                 --]]
    --                 -- local buftype = vim.bo[bufnr].buftype
    --                 -- local filetype = vim.bo[bufnr].filetype
    --                 -- local bufname = vim.api.nvim_buf_get_name(bufnr)
    --                 -- if vim.startswith(bufname, 'diffview:') then
    --                 --     return bufnr
    --                 -- end
    --                 -- if buftype == 'nofile' then
    --                 --     local filetypes_of_buffers_to_close_set =
    --                 --         require('config.utils').set({
    --                 --             'lazy',
    --                 --             'mason',
    --                 --             'lspinfo',
    --                 --         })
    --                 --     if
    --                 --         filetypes_of_buffers_to_close_set[filetype] ~= nil
    --                 --     then
    --                 --         return filetype
    --                 --     end
    --                 -- end
    --                 -- You can return "bufnr", "buftype", "filetype", or a custom function to set how the window will be pinned.
    --                 -- You can instead return an table that will be passed in as "opts" to `stickybuf.pin`.
    --                 -- The function below encompasses the default logic. Inspect the source to see what it does.
    --                 return require('stickybuf').should_auto_pin(bufnr)
    --             end,
    --         })
    --     end,
    -- },

    ---------------------------------------------------------------------------
    -- Clipboard support (copy from vim to the outside world)
    {
        'ojroques/nvim-osc52',
    },

    {
        'folke/tokyonight.nvim',
        lazy = false,
        priority = 1000,
        config = function()
            require('tokyonight.colors').setup()
            local color = 'tokyonight'
            vim.cmd.colorscheme(color)
        end,
    },

    ---------------------------------------------------------------------------
    -- Undotree the solution to screwups
    {
        'mbbill/undotree',
        lazy = true,
        cmd = { 'UndotreeToggle', 'UndotreeShow' },
        keys = {
            {
                '<leader>u',
                vim.cmd.UndotreeToggle,
                desc = 'Undotree: Toggle Undotree',
            },
        },
        config = function(_, _)
            if require('utils.platform').is.win then
                vim.g.undotree_DiffCommand = 'FC'
            end
        end,
    },

    ---------------------------------------------------------------------------
    -- Parser for syntax highlighting
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = true,
        event = 'VeryLazy',
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter.configs').setup({
                modules = {},
                -- A list of parser names, or "all"
                ensure_installed = {
                    'diff',
                    'javascript',
                    'typescript',
                    'tsx',
                    'css',
                    'json',
                    'jsonc',
                    'html',
                    'xml',
                    'yaml',
                    'c',
                    'lua',
                    'rust',
                    'vim',
                    'vimdoc',
                    'query',
                    'markdown',
                    'markdown_inline',
                    'python',
                    'toml',
                    'regex',
                },

                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,

                -- Automatically install missing parsers when entering buffer
                -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
                auto_install = true,

                -- List of parsers to ignore installing (or "all")
                ignore_install = {},

                ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
                -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

                highlight = {
                    enable = true,

                    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
                    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
                    -- Using this option may slow down your editor, and you may see some duplicate highlights.
                    -- Instead of true it can also be a list of languages
                    additional_vim_regex_highlighting = false,
                },
            })
        end,
    },

    -----------------------------------------------------------------------------
    -- PYTHON REPL
    -- A basic REPL that opens up as a horizontal split
    -- - use `<leader>i` to toggle the REPL
    -- - use `<leader>I` to restart the REPL
    -- - `+` serves as the "send to REPL" operator. That means we can use `++`
    -- to send the current line to the REPL, and `+j` to send the current and the
    -- following line to the REPL, like we would do with other vim operators.
    {
        'Vigemus/iron.nvim',
        keys = {
            { '<leader>i', vim.cmd.IronRepl, desc = 'Iron: Toggle REPL' },
            { '<leader>I', vim.cmd.IronRestart, desc = 'Iron: Restart REPL' },

            -- these keymaps need no right-hand-side, since that is defined by the
            -- plugin config further below
            { '+', mode = { 'n', 'x' }, desc = 'Iron: Send-to-REPL Operator' },
            { '++', desc = 'Iron: Send Line to REPL' },
        },

        -- since irons's setup call is `require("iron.core").setup`, instead of
        -- `require("iron").setup` like other plugins would do, we need to tell
        -- lazy.nvim which module to via the `main` key
        main = 'iron.core',

        opts = {
            keymaps = {
                send_line = '++',
                visual_send = '+',
                send_motion = '+',
            },
            config = {
                -- this defined how the repl is opened. Here we set the REPL window
                -- to open in a horizontal split to a bottom, with a height of 10
                -- cells.
                repl_open_cmd = 'horizontal bot 10 split',

                -- This defines which binary to use for the REPL. If `ipython` is
                -- available, it will use `ipython`, otherwise it will use `python3`.
                -- since the python repl does not play well with indents, it's
                -- preferable to use `ipython` or `bypython` here.
                -- (see: https://github.com/Vigemus/iron.nvim/issues/348)
                repl_definition = {
                    python = {
                        command = function()
                            local ipythonAvailable = vim.fn.executable(
                                'ipython'
                            ) == 1
                            local binary = ipythonAvailable and 'ipython'
                                or 'python3'
                            return { binary }
                        end,
                    },
                },
            },
        },
    },

    ---------------------------------------------------------------------------
    -- Testing

    {
        'nvim-neotest/neotest',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'antoinemadec/FixCursorHold.nvim',
            'nvim-treesitter/nvim-treesitter',
            --adapters
            'rouge8/neotest-rust',
            'nvim-neotest/neotest-python',
            'Issafalcon/neotest-dotnet',
        },
        lazy = true,
        event = 'VeryLazy',
        keys = {
            {
                '<leader>tr',
                function() require('neotest').run.run() end,
                desc = 'Neotest: Run the nearest test',
            },
            {
                '<leader>tc',
                function() require('neotest').run.run(vim.fn.expand('%')) end,
                desc = 'Neotest: Run the current file',
            },
            {
                '<leader>td',
                function() require('neotest').run.run({ strategy = 'dap' }) end,
                desc = 'Neotest: Debug the nearest test',
            },
            {
                '<leader>ts',
                function() require('neotest').run.stop() end,
                desc = 'Neotest: Stop the nearest test',
            },
            {
                '<leader>ta',
                function() require('neotest').run.attach() end,
                desc = 'Neotest: Attach to the nearest test',
            },
        },
        config = function(_, _)
            require('neotest').setup({
                adapters = {
                    require('neotest-python')({
                        dap = { justMyCode = false },
                    }),
                    require('neotest-rust')({
                        -- args = { '--no-capture' },
                        -- dap_adapter = 'lldb',
                    }),
                    require('neotest-dotnet')({
                        dap = {
                            -- Extra arguments for nvim-dap configuration
                            -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
                            args = { justMyCode = false },
                            -- Enter the name of your dap adapter, the default value is netcoredbg
                            adapter_name = 'netcoredbg',
                        },
                        -- Let the test-discovery know about your custom attributes (otherwise tests will not be picked up)
                        -- Note: Only custom attributes for non-parameterized tests should be added here. See the support note about parameterized tests
                        -- custom_attributes = {
                        --     xunit = { 'MyCustomFactAttribute' },
                        --     nunit = { 'MyCustomTestAttribute' },
                        --     mstest = { 'MyCustomTestMethodAttribute' },
                        -- },
                        -- Provide any additional "dotnet test" CLI commands here. These will be applied to ALL test runs performed via neotest. These need to be a table of strings, ideally with one key-value pair per item.
                        -- dotnet_additional_args = {
                        --     '--verbosity detailed',
                        -- },
                        -- Tell neotest-dotnet to use either solution (requires .sln file) or project (requires .csproj or .fsproj file) as project root
                        -- Note: If neovim is opened from the solution root, using the 'project' setting may sometimes find all nested projects, however,
                        --       to locate all test projects in the solution more reliably (if a .sln file is present) then 'solution' is better.
                        -- discovery_root = 'project', -- Default
                    }),
                },
            })
        end,
    },

    ---------------------------------------------------------------------------
    -- DEBUGGING

    -- DAP Client for nvim
    {
        'mfussenegger/nvim-dap',
        lazy = true,
        config = function(_, _)
            local dap = require('dap')
            dap.adapters.codelldb = {
                type = 'server',
                port = '${port}',
                executable = {
                    command = require('utils.path').get_mason_tool_path(
                        'codelldb'
                    ),
                    -- command = vim.fn.stdpath('data') .. '/mason/bin/codelldb',
                    args = { '--port', '${port}' },

                    -- On windows you may have to uncomment this:
                    -- detached = false,
                },
            }
            dap.adapters.executable = {
                type = 'executable',
                command = require('utils.path').get_mason_tool_path('codelldb'),
                -- command = vim.fn.stdpath('data') .. '/mason/bin/codelldb',
                name = 'lldb1',
                host = '127.0.0.1',
                port = 13000,
            }
            dap.configurations.rust = {
                {
                    name = 'Launch file',
                    type = 'codelldb',
                    request = 'launch',
                    program = function()
                        return vim.fn.input(
                            'Path to executable: ',
                            vim.fn.getcwd() .. '/',
                            'file'
                        )
                    end,
                    cwd = '${workspaceFolder}',
                    stopOnEntry = false,
                },
            }
        end,
        keys = {
            {
                '<leader>dc',
                function() require('dap').continue() end,
                desc = 'Debug: Start/Continue Debugger',
            },
            {
                '<leader>db',
                function() require('dap').toggle_breakpoint() end,
                desc = 'Debug: Add Breakpoint',
            },
            {
                '<leader>dt',
                function() require('dap').terminate() end,
                desc = 'Debug: Terminate Debugger',
            },
            {
                '<leader>dC',
                function() require('dap').run_to_cursor() end,
                desc = 'Debug: Run to Cursor',
            },
            {
                '<leader>dg',
                function() require('dap').goto_() end,
                desc = 'Debug: Go to line (no execute)',
            },
            {
                '<leader>di',
                function() require('dap').step_into() end,
                desc = 'Debug: Step Into',
            },
            {
                '<leader>dj',
                function() require('dap').down() end,
                desc = 'Debug: Down',
            },
            {
                '<leader>dk',
                function() require('dap').up() end,
                desc = 'Debug: Up',
            },
            {
                '<leader>dl',
                function() require('dap').run_last() end,
                desc = 'Debug: Run Last',
            },
            {
                '<leader>do',
                function() require('dap').step_out() end,
                desc = 'Debug: Step Out',
            },
            {
                '<leader>dO',
                function() require('dap').step_over() end,
                desc = 'Debug: Step Over',
            },
            {
                '<leader>dp',
                function() require('dap').pause() end,
                desc = 'Debug: Pause',
            },
            {
                '<leader>dr',
                function() require('dap').repl.toggle() end,
                desc = 'Debug: Toggle REPL',
            },
            {
                '<leader>ds',
                function() require('dap').session() end,
                desc = 'Debug: Session',
            },
            {
                '<leader>dw',
                function() require('dap.ui.widgets').hover() end,
                desc = 'Debug: Widgets',
            },
        },
    },

    -- UI for the debugger
    -- - the debugger UI is also automatically opened when starting/stopping the debugger
    -- - toggle debugger UI manually with `<leader>du`
    {
        'rcarriga/nvim-dap-ui',
        lazy = true,
        dependencies = 'mfussenegger/nvim-dap',
        keys = {
            {
                '<leader>du',
                function() require('dapui').toggle() end,
                desc = 'Debug: Toggle debugger UI',
            },
        },
        -- automatically open/close the DAP UI when starting/stopping the debugger
        config = function()
            require('dapui').setup()
            local listener = require('dap').listeners
            listener.after.event_initialized['dapui_config'] = function()
                require('dapui').open()
            end
            listener.before.event_terminated['dapui_config'] = function()
                require('dapui').close()
            end
            listener.before.event_exited['dapui_config'] = function()
                require('dapui').close()
            end
        end,
    },

    -- Configuration for the python debugger
    {
        'mfussenegger/nvim-dap-python',
        lazy = true,
        ft = 'python',
        dependencies = 'mfussenegger/nvim-dap',
        config = function()
            -- configures debugpy
            -- uses the debugypy installation by mason
            local debugpyPythonPath = require('mason-registry')
                .get_package('debugpy')
                :get_install_path() .. '/venv/bin/python3'
            require('dap-python').setup(debugpyPythonPath, {})
        end,
    },

    ---------------------------------------------------------------------------
    --- LSP's and more

    -- -- Adds workspace configuration file support
    -- {
    --     'folke/neoconf.nvim',
    --     lazy = false,
    --     config = true,
    -- },

    -- Configure Lua LSP to know about neovim plugins when in neovim config
    {
        'folke/neodev.nvim',
        lazy = true, -- Will lazy load before lspconfig since I marked it as a dependency
        config = function()
            require('neodev').setup({
                setup_jsonls = false, -- I will do this manually in my lspconfig setup
                -- -- Workaround to get correctly configure lua_ls for neovim config
                -- -- https://github.com/folke/neodev.nvim/issues/158#issuecomment-1672421325
                -- override = function(_, library)
                --     library.enabled = true
                --     library.plugins = true
                -- end,
            })
        end,
    },

    -- Helps configure which json and yaml schemas to use for the corresponding lsp
    -- Catalog of general schemas: https://www.schemastore.org/api/json/catalog.json
    -- Catalog of kubernetes schemas: https://github.com/datreeio/CRDs-catalog/tree/main
    -- Note: The setup for this plugin is in the lspconfig plugin's setup function
    {
        'b0o/schemastore.nvim',
        lazy = true, -- my setup for lspconfig will lazy load this plugin
    },

    -- A frontend for yaml schemas to use
    -- Adds a telescope picker via `Telescope yaml_schema`
    -- Adds a hook to determine which shema is selected (useful for statusline)
    -- Enhances auto-completion descriptions
    -- Adds detection mechanism for kubernetes files as they are context dependent rather the file name dependent
    -- Note: Most of the setup for this is in the lspconfig plugin's setup function
    {
        'someone-stole-my-name/yaml-companion.nvim',
        lazy = true, -- my setup for lspconfig will lazy load this plugin
        dependencies = {
            { 'neovim/nvim-lspconfig' },
            { 'nvim-lua/plenary.nvim' },
            { 'nvim-telescope/telescope.nvim' },
        },
        config = function() require('telescope').load_extension('yaml_schema') end,
    },

    -- Manager for external tools (LSPs, linters, debuggers, formatters)
    -- auto-install of those external tools
    {
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        lazy = true,
        event = 'VeryLazy',
        dependencies = {
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },
        },
        config = function(_, _)
            require('mason-tool-installer').setup({
                ensure_installed = {
                    -- LSPs
                    'pyright', -- LSP for python
                    'ruff-lsp', -- linter for python (includes flake8, pep8, etc.)
                    'marksman',
                    'lua-language-server', -- (lua_ls) LSP for lua files
                    'typescript-language-server', -- tsserver LSP (keywords: typescript, javascript)
                    'eslint-lsp', -- eslint Linter (implemented as a standalone lsp to improve speed)(keywords: javascript, typescript)
                    'ansible-language-server',
                    'omnisharp',
                    -- 'ansible-lint',
                    'rust-analyzer',
                    'yamlls', -- (yaml-language-server)
                    'jsonls', -- (json-lsp)
                    'taplo', -- LSP for toml (for pyproject.toml files)

                    -- Formatters
                    'black', -- python formatter
                    'isort', -- python organize imports
                    'stylua', -- Formatter for lua files
                    'prettier', -- Formatter typescript (keywords: angular, css, flow, graphql, html, json, jsx, javascript, less, markdown, scss, typescript, vue, yaml
                    'prettierd', --Uses a daemon for faster formatting (keywords: angular, css, flow, graphql, html, json, jsx, javascript, less, markdown, scss, typescript, vue, yaml)
                    'xmlformatter',
                    'jq', --json formatter
                    -- 'fixjson', -- json fixer, fixes invalid json like trailing commas

                    -- Debuggers
                    'codelldb',
                    'debugpy', -- python debugger
                    'netcoredbg',
                },
            })
            require('mason-tool-installer').run_on_start() -- Fix Issue: https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim/issues/37
        end,
    },

    {
        'williamboman/mason.nvim',
        lazy = true,
        config = true,
    },
    {
        'williamboman/mason-lspconfig.nvim',
        lazy = true,
        config = function()
            require('mason-lspconfig').setup({
                handlers = {
                    --my handler requires neovim/lspconfig and hrsh7th/cmp-nvim-lsp
                    --so those dependencies will get lazily loaded when the lsp attaches
                    --if they haven't already been loaded
                    require('config.lsp.lsp').default_setup,
                },
            })
        end,
    },

    {
        'neovim/nvim-lspconfig',
        lazy = true,
        dependencies = {
            {
                -- neodev must load before lspconfig to load in the lua_ls LSP settings
                'folke/neodev.nvim',
                -- cmp-nvim-lsp provides a list of lsp capibilities to that cmp adds to neovim
                -- I must have cmp-nvim-lsp load before nvim-lspconfig for
                -- lua snips to show up in cmp
                'hrsh7th/cmp-nvim-lsp',
            },
        },
        config = function()
            local lspconfig = require('lspconfig')
            --https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
            lspconfig.lua_ls.setup({
                settings = {
                    Lua = {
                        runtime = { version = 'LuaJIT' },
                        hint = { enable = true },
                    },
                },
            })
            lspconfig.pyright.setup({
                settings = {
                    python = {
                        -- Note autoImportCompletions only shows imports that have been used in other files that have already been opened
                        -- See https://github.com/hrsh7th/nvim-cmp/issues/426#issuecomment-1185144017
                        -- TODO see if there is a way to get it to at least suggest imports without having to open all workspace files
                        autoImportCompletions = true,
                    },
                },
            })
            lspconfig.tsserver.setup({
                settings = {
                    typescript = {
                        inlayHints = {
                            -- taken from https://github.com/typescript-language-server/typescript-language-server#workspacedidchangeconfiguration
                            includeInlayEnumMemberValueHints = true,
                            includeInlayFunctionLikeReturnTypeHints = true,
                            includeInlayFunctionParameterTypeHints = true,
                            includeInlayParameterNameHints = 'all',
                            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
                            includeInlayPropertyDeclarationTypeHints = true,
                            includeInlayVariableTypeHints = true,
                            includeInlayVariableTypeHintsWhenTypeMatchesName = true,
                        },
                    },
                    javascript = {
                        inlayHints = {
                            includeInlayEnumMemberValueHints = true,
                            includeInlayFunctionLikeReturnTypeHints = true,
                            includeInlayFunctionParameterTypeHints = true,
                            includeInlayParameterNameHints = 'all',
                            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
                            includeInlayPropertyDeclarationTypeHints = true,
                            includeInlayVariableTypeHints = true,
                            includeInlayVariableTypeHintsWhenTypeMatchesName = true,
                        },
                    },
                },
            })

            -- yamlls config is based on article https://www.arthurkoziel.com/json-schemas-in-neovim/
            local yamlls_cfg = require('yaml-companion').setup({
                -- detect k8s schemas based on file content
                builtin_matchers = {
                    kubernetes = { enabled = true },
                },

                -- schemas available in Telescope picker
                -- Catalog of general schemas: https://www.schemastore.org/api/json/catalog.json
                -- Catalog of kubernetes schemas: https://github.com/datreeio/CRDs-catalog/tree/main
                schemas = {
                    -- not loaded automatically, manually select with
                    -- :Telescope yaml_schema
                    {
                        name = 'Argo CD Application',
                        uri = 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/argoproj.io/application_v1alpha1.json',
                    },
                    {
                        name = 'SealedSecret',
                        uri = 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/bitnami.com/sealedsecret_v1alpha1.json',
                    },
                    -- schemas below are automatically loaded, but added
                    -- them here so that they show up in the statusline
                    {
                        name = 'Kustomization',
                        uri = 'https://json.schemastore.org/kustomization.json',
                    },
                    {
                        name = 'GitHub Workflow',
                        uri = 'https://json.schemastore.org/github-workflow.json',
                    },
                    {
                        name = 'Ansible Execution Environment',
                        uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/execution-environment.json',
                    },
                    {
                        name = 'Ansible Meta',
                        url = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/meta.json',
                    },
                    {
                        name = 'Ansible Meta Runtime',
                        uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/meta-runtime.json',
                    },
                    {
                        name = 'Ansible Argument Specs',
                        uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/role-arg-spec.json',
                    },
                    {
                        name = 'Ansible Requirements',
                        uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/requirements.json',
                    },
                    {
                        name = 'Ansible Vars File',
                        uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/vars.json',
                    },
                    {
                        name = 'Ansible Tasks File',
                        uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/tasks',
                    },
                    {
                        name = 'Ansible Playbook',
                        uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/playbook',
                    },
                    {
                        name = 'Ansible Rulebook',
                        uri = 'https://raw.githubusercontent.com/ansible/ansible-rulebook/main/ansible_rulebook/schema/ruleset_schema.json',
                    },
                    {
                        name = 'Ansible Inventory',
                        uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/inventory.json',
                    },
                    {
                        name = 'Ansible Collection Galaxy',
                        uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/galaxy.json',
                    },
                    {
                        name = 'Ansible-lint Configuration',
                        uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible-lint-config.json',
                    },
                    {
                        name = 'Ansible Navigator Configuration',
                        uri = 'https://raw.githubusercontent.com/ansible/ansible-navigator/main/src/ansible_navigator/data/ansible-navigator.json',
                    },
                },

                lspconfig = {
                    settings = {
                        yaml = {
                            validate = true,
                            schemaStore = {
                                enable = false,
                                url = '',
                            },

                            -- schemas from store, matched by filename
                            -- loaded automatically
                            -- Catalog of general schemas: https://www.schemastore.org/api/json/catalog.json
                            schemas = require('schemastore').yaml.schemas({
                                select = {
                                    'kustomization.yaml',
                                    'GitHub Workflow',
                                    'Ansible Execution Environment',
                                    'Ansible Meta',
                                    'Ansible Meta Runtime',
                                    'Ansible Argument Specs',
                                    'Ansible Requirements',
                                    'Ansible Vars File',
                                    'Ansible Tasks File',
                                    'Ansible Playbook',
                                    'Ansible Rulebook',
                                    'Ansible Inventory',
                                    'Ansible Collection Galaxy',
                                    'Ansible-lint Configuration',
                                    'Ansible Navigator Configuration',
                                },
                            }),
                        },
                    },
                },
            })
            lspconfig.yamlls.setup(yamlls_cfg)

            -- jsonls config is based on article https://www.arthurkoziel.com/json-schemas-in-neovim/
            -- Config type is defined in https://github.com/microsoft/vscode/blob/30b777312745e84972956d4361465d4d38aa0f78/extensions/json-language-features/server/src/jsonServer.ts#L202C2-L218C3
            local json_schemas = require('schemastore').json.schemas({
                select = {
                    'Renovate',
                    'GitHub Workflow Template Properties',
                },
                -- extra = {
                --     {
                --         description = 'Schema for luals lsp configuration file',
                --         name = 'LuaLS Settings',
                --         url = 'https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json',
                --         fileMatch = { '.luarc.json', '.luarc.jsonc' },
                --     },
                -- },
            })
            -- Adding the schemas to the extra tab doesn't seem to be working
            table.insert(json_schemas, {
                description = 'Schema for luals lsp configuration file',
                name = 'LuaLS Settings',
                url = 'https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json',
                fileMatch = { '.luarc.json', '.luarc.jsonc' },
            })
            local jsonls_cfg = {
                settings = {
                    json = {
                        schemas = json_schemas,
                        validate = { enable = true },
                    },
                },
            }
            -- vim.print(jsonls_cfg)
            lspconfig.jsonls.setup(jsonls_cfg)

            -- taplo config is based on article https://www.arthurkoziel.com/json-schemas-in-neovim/
            -- tablo loads all toml schemas from https://www.schemastore.org/api/json/catalog.json with little customization
            lspconfig.taplo.setup({
                settings = {
                    evenBetterToml = {
                        schema = {
                            -- add additional schemas
                            -- associations = {
                            --     ['example\\.toml$'] = 'https://json.schemastore.org/example.json',
                            -- },
                        },
                    },
                },
            })

            local pid = vim.fn.getpid()

            lspconfig.omnisharp.setup({
                cmd = {
                    require('utils.path').get_mason_tool_path('omnisharp'),
                    '--languageserver',
                    '--hostPID',
                    tostring(pid),
                },
            })
        end,
    },

    -- Autocompletion
    {
        'hrsh7th/nvim-cmp',
        lazy = true,
        event = { 'InsertEnter', 'CmdlineEnter' },
        dependencies = {
            { 'L3MON4D3/LuaSnip' },
            { 'saadparwaiz1/cmp_luasnip' }, -- Completion for snippets
            { 'hrsh7th/cmp-buffer' }, -- Completion for words in buffer
            { 'hrsh7th/cmp-path' }, -- Completion for file paths
            { 'hrsh7th/cmp-cmdline' },
            {
                'hrsh7th/cmp-nvim-lua', -- Completion for lua api
                lazy = true,
                ft = 'lua',
            },
            { 'hrsh7th/cmp-nvim-lsp' }, -- Provides a list of lsp capibilities to that cmp adds to neovim
            { 'hrsh7th/cmp-nvim-lsp-signature-help' }, -- Provides signature info while typing function paramaters
            { 'onsails/lspkind.nvim' }, -- Helps format the cmp selection items
            {
                'petertriho/cmp-git', -- Provides info about git repo
                lazy = true,
                ft = 'gitcommit',
                dependencies = { 'nvim-lua/plenary.nvim' },
            },
        },
        config = function()
            local cmp = require('cmp')
            cmp.setup({
                performance = {
                    max_view_entries = 15,
                },
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'nvim_lsp_signature_help' },
                    { name = 'nvim_lua' },
                    { name = 'luasnip' },
                    { name = 'buffer', keyword_length = 5 },
                    { name = 'path' },
                }),
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end,
                },
                formatting = {
                    format = require('lspkind').cmp_format({
                        with_text = true,
                        menu = {
                            buffer = '[buf]',
                            nvim_lsp = '[LSP]',
                            nvim_lua = '[API]',
                            path = '[path]',
                            luasnip = '[snip]',
                            git = '[git]',
                            cmdline = '[cmd]',
                            nvim_lsp_signature_help = '[info]',
                        },
                    }),
                },
                mapping = {
                    ['<Down>'] = {
                        i = cmp.mapping.select_next_item({
                            behavior = 'select',
                        }),
                    },
                    ['<Up>'] = {
                        i = cmp.mapping.select_prev_item({
                            behavior = 'select',
                        }),
                    },
                    ['<C-y>'] = {
                        i = cmp.mapping.confirm({ select = false }),
                    },
                    ['<C-e>'] = {
                        i = cmp.mapping.abort(),
                    },
                    -- `Enter` key to confirm completion
                    ['<CR>'] = cmp.mapping({
                        i = function(fallback)
                            if cmp.visible() and cmp.get_active_entry() then
                                cmp.confirm({
                                    behavior = cmp.ConfirmBehavior.Insert,
                                    select = false,
                                })
                            else
                                fallback()
                            end
                        end,
                    }),
                    ['<S-CR>'] = cmp.mapping({
                        i = function(fallback)
                            -- when using specific terminals you may need to update
                            -- the settings so that they pass the correct key-codes
                            -- for shift+enter https://stackoverflow.com/a/42461580
                            if cmp.visible() and cmp.get_active_entry() then
                                cmp.confirm({
                                    behavior = cmp.ConfirmBehavior.Replace,
                                    select = false,
                                })
                            else
                                fallback()
                            end
                        end,
                    }),

                    -- Ctrl+Enter to trigger completion menu
                    ['<C-CR>'] = cmp.mapping(cmp.mapping.complete(), { 'i' }),
                    -- Complete common string
                    ['<S-Space>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            return cmp.complete_common_string()
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                    ['<C-t>'] = cmp.mapping(function()
                        if cmp.visible_docs() then
                            cmp.close_docs()
                        else
                            cmp.open_docs()
                        end
                    end, { 'i', 's' }),
                    -- Scroll up and down in the completion documentation
                    ['<C-u>'] = cmp.mapping(function(falback)
                        if cmp.visible() then
                            cmp.mapping.scroll_docs(-4)
                        else
                            falback()
                        end
                    end, { 'i', 's' }),
                    ['<C-d>'] = cmp.mapping(function(falback)
                        if cmp.visible() then
                            cmp.mapping.scroll_docs(4)
                        else
                            falback()
                        end
                    end, { 'i', 's' }),
                    -- Navigate between snippet placeholder
                    -- ['<Tab>'] = cmp.mapping(function(fallback)
                    --     local luasnip = require('luasnip')
                    --
                    --     if cmp.visible() and cmp.get_active_entry() ~= nil then
                    --         cmp.select_next_item()
                    --     elseif luasnip.expand_or_jumpable() then
                    --         luasnip.expand_or_jump()
                    --     else
                    --         fallback()
                    --     end
                    -- end, { 'i', 's' }),
                    --
                    -- ['<S-Tab>'] = cmp.mapping(function(fallback)
                    --     local luasnip = require('luasnip')
                    --
                    --     if cmp.visible() and cmp.get_active_entry() ~= nil then
                    --         cmp.select_prev_item()
                    --     elseif luasnip.jumpable(-1) then
                    --         luasnip.jump(-1)
                    --     else
                    --         fallback()
                    --     end
                    -- end, { 'i', 's' }),
                    ['<C-n>'] = cmp.mapping(function(fallback)
                        local luasnip = require('luasnip')
                        if luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),

                    ['<C-p>'] = cmp.mapping(function(fallback)
                        local luasnip = require('luasnip')

                        if luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                },
            })

            cmp.setup.filetype('gitcommit', {
                sources = cmp.config.sources({
                    { name = 'git' },
                    { name = 'luasnip' },
                    { name = 'buffer', keyword_length = 5 },
                }),
            })

            -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline({ '/', '?' }, {
                mapping = {
                    ['<C-z>'] = {
                        c = function()
                            if cmp.visible() then
                                cmp.select_next_item()
                            else
                                cmp.complete()
                            end
                        end,
                    },
                    ['<Tab>'] = {
                        c = function()
                            if cmp.visible() then
                                cmp.select_next_item()
                            else
                                cmp.complete()
                            end
                        end,
                    },
                    ['<S-Tab>'] = {
                        c = function()
                            if cmp.visible() then
                                cmp.select_prev_item()
                            else
                                cmp.complete()
                            end
                        end,
                    },
                    ['<C-n>'] = {
                        c = function(fallback)
                            if cmp.visible() then
                                cmp.select_next_item()
                            else
                                fallback()
                            end
                        end,
                    },
                    ['<C-p>'] = {
                        c = function(fallback)
                            if cmp.visible() then
                                cmp.select_prev_item()
                            else
                                fallback()
                            end
                        end,
                    },
                    ['<C-e>'] = {
                        c = cmp.mapping.abort(),
                    },
                    ['<C-y>'] = {
                        c = cmp.mapping.confirm({ select = false }),
                    },
                },
                sources = {
                    { name = 'buffer', keyword_length = 3 },
                },
            })

            -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline(':', {
                mapping = {

                    ['<C-z>'] = {
                        c = function()
                            if cmp.visible() then
                                cmp.select_next_item()
                            else
                                cmp.complete()
                            end
                        end,
                    },
                    ['<Tab>'] = {
                        c = function(_)
                            if cmp.visible() then
                                if #cmp.get_entries() == 1 then
                                    cmp.confirm({ select = true })
                                else
                                    cmp.select_next_item()
                                end
                            else
                                cmp.complete()
                                if #cmp.get_entries() == 1 then
                                    cmp.confirm({ select = true })
                                end
                            end
                        end,
                    },
                    ['<S-Tab>'] = {
                        c = function()
                            if cmp.visible() then
                                cmp.select_prev_item()
                            else
                                cmp.complete()
                            end
                        end,
                    },
                    ['<C-n>'] = {
                        c = function(fallback)
                            if cmp.visible() then
                                cmp.select_next_item()
                            else
                                fallback()
                            end
                        end,
                    },
                    ['<C-p>'] = {
                        c = function(fallback)
                            if cmp.visible() then
                                cmp.select_prev_item()
                            else
                                fallback()
                            end
                        end,
                    },
                    ['<C-e>'] = {
                        c = cmp.mapping.abort(),
                    },
                    ['<C-y>'] = {
                        c = cmp.mapping.confirm({ select = false }),
                    },
                },
                sources = cmp.config.sources({
                    { name = 'path' },
                    { name = 'cmdline' },
                }),
            })
        end,
    },

    -- Snippets
    {
        'L3MON4D3/LuaSnip',
        lazy = true,
        dependencies = {
            'rafamadriz/friendly-snippets',
            {
                'benfowler/telescope-luasnip.nvim',
                dependencies = {
                    'nvim-telescope/telescope.nvim',
                },
                config = function()
                    require('telescope').load_extension('luasnip')
                end,
            },
        },
        config = function(_, opts)
            if opts then require('luasnip').config.setup(opts) end
            vim.tbl_map(
                function(type)
                    require('luasnip.loaders.from_' .. type).lazy_load()
                end,
                { 'vscode', 'snipmate', 'lua' }
            )
            local config_path = vim.fn.stdpath('config')
            if config_path ~= nil and type(config_path) == 'string' then
                local luasnip_path = require('utils.path').concat({
                    config_path,
                    'LuaSnip/',
                })
                require('luasnip.loaders.from_lua').load({
                    paths = {
                        luasnip_path,
                    },
                })
            end
            -- friendly-snippets - enable standardized comments snippets
            require('luasnip').filetype_extend('typescript', { 'tsdoc' })
            require('luasnip').filetype_extend('javascript', { 'jsdoc' })
            require('luasnip').filetype_extend('lua', { 'luadoc' })
            require('luasnip').filetype_extend('python', { 'pydoc' })
            require('luasnip').filetype_extend('rust', { 'rustdoc' })
            require('luasnip').filetype_extend('cs', { 'csharpdoc' })
            require('luasnip').filetype_extend('java', { 'javadoc' })
            require('luasnip').filetype_extend('c', { 'cdoc' })
            require('luasnip').filetype_extend('cpp', { 'cppdoc' })
            require('luasnip').filetype_extend('php', { 'phpdoc' })
            require('luasnip').filetype_extend('kotlin', { 'kdoc' })
            require('luasnip').filetype_extend('ruby', { 'rdoc' })
            require('luasnip').filetype_extend('sh', { 'shelldoc' })
        end,
    },

    -- Virtual Environments
    -- select virtual environments
    -- - makes pyright and debugpy aware of the selected virtual environment
    -- - Select a virtual environment with `:VenvSelect`
    {
        'linux-cultist/venv-selector.nvim',
        lazy = true,
        ft = 'python',
        dependencies = {
            'neovim/nvim-lspconfig',
            'nvim-telescope/telescope.nvim',
            'mfussenegger/nvim-dap-python',
        },
        config = function(_, _)
            require('venv-selector').setup({
                dap_enabled = true, -- makes the debugger work with venv
                name = { 'venv', '.venv' },
            })
            require('venv-selector').retrieve_from_cache()
        end,
    },

    -- Formatting client: conform.nvim
    -- - configured to use black & isort in python
    -- - use the taplo-LSP for formatting in toml
    -- - Formatting is triggered via `<leader>f`, but also automatically on save
    {
        'stevearc/conform.nvim',
        event = 'BufWritePre', -- load the plugin before saving
        keys = {
            {
                '<leader>f',
                function()
                    local params =
                        require('config.formatter').construct_conform_formatting_params()
                    require('conform').format(params)
                end,
                desc = 'Conform: Format buffer',
            },
        },
        config = function(_, _)
            require('conform').setup({
                formatters_by_ft = {
                    lua = { 'stylua' },
                    -- first use isort and then black
                    python = { 'isort', 'black' },
                    typescript = { { 'prettierd', 'prettier' } },
                    javascript = { { 'prettierd', 'prettier' } },
                    yaml = { { 'prettierd', 'prettier' } },
                    json = { { 'prettierd', 'prettier' } },
                    jsonc = { { 'prettierd', 'prettier' } },
                    json5 = { { 'prettierd', 'prettier' } },
                    ansible = { { 'prettierd', 'prettier' } },
                    --use `:set ft=yaml.ansible` to get treesitter highlights for yaml,
                    -- ansible lsp, and prettier formatting TODO set up autocmd to detect ansible
                    ['yaml.ansible'] = { { 'prettierd', 'prettier' } },
                    -- "inject" is a "special" formatter from conform.nvim, which
                    -- formats treesitter-injected code. In effect, hits will make
                    -- conform.nvim format any python codeblocks inside a markdown file.
                    markdown = { { 'prettierd', 'prettier' }, 'injected' },
                    xml = { 'xmlformat' },
                },
                formatters = {
                    xmlformat = {
                        command = 'xmlformat',
                        args = { '--selfclose', '-' },
                    },
                },
                -- enable format-on-save
                format_on_save = require('config.formatter').construct_conform_autoformat_params,
            })
            -- -- Set this value to true to silence errors when formatting a block fails
            -- require('conform.formatters.injected').options.ignore_errors = false
        end,
    },

    -- Code Action preview
    {
        'aznhe21/actions-preview.nvim',
        lazy = true,
        config = true,
    },

    ---------------------------------------------------------------------------
    -- Import plugins defined in the plugins folder
    { import = 'plugins' },
})
