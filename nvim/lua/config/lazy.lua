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

local function get_default_branch_name()
    local res = vim.system(
        { 'git', 'rev-parse', '--verify', 'main' },
        { capture_output = true }
    ):wait()
    return res.code == 0 and 'main' or 'master'
end

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
        version = '*',
        lazy = true,
        config = true,
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
                desc = 'Toggle Git DiffView',
            },
            {
                '<leader>gh',
                '<cmd>DiffviewFileHistory<cr>',
                { desc = 'Open Git Repo history' },
            },

            {
                '<leader>ghf',
                '<cmd>DiffviewFileHistory --follow %<cr>',
                { desc = 'Open Git File history' },
            },

            {
                '<leader>ghl',
                "<Esc><Cmd>'<,'>DiffviewFileHistory --follow<CR>",
                mode = 'v',
                { desc = 'Open Git File history over selected text' },
            },

            {
                '<leader>ghl',
                '<Cmd>.DiffviewFileHistory --follow<CR>',
                { desc = 'Open Git history for the line' },
            },

            -- Diff against local master branch
            {
                '<leader>ghm',
                function()
                    vim.cmd('DiffviewOpen ' .. get_default_branch_name())
                end,
                { desc = 'Diff against master' },
            },

            -- Diff against remote master branch
            {
                '<leader>ghM',
                function()
                    vim.cmd(
                        'DiffviewOpen HEAD..origin/'
                            .. get_default_branch_name()
                    )
                end,
                { desc = 'Diff against origin/master' },
            },
        },
    },
    -- Adds an api wrapper arround git which I use in my heirline setup
    -- Adds Gitblame
    -- Adds sidbar showing lines changed
    {
        'lewis6991/gitsigns.nvim',
        version = '*',
        lazy = true,
        event = 'VeryLazy',
        config = true,
        keys = {

            -- Highlight changed words.
            {
                '<leader>gvw',
                function() require('gitsigns').toggle_word_diff() end,
                { desc = 'Toggle word diff' },
            },

            -- Highlight added lines.
            {
                '<leader>gvl',
                function() require('gitsigns').toggle_linehl() end,
                { desc = 'Toggle line highlight' },
            },

            -- Highlight removed lines.
            {
                '<leader>gvd',
                function() require('gitsigns').toggle_deleted() end,
                { desc = 'Toggle deleted (all)' },
            },
            {
                '<leader>gvh',
                function() require('gitsigns').preview_hunk() end,
                { desc = 'Preview hunk' },
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
        },
        version = '*',
        lazy = true,
        cmd = { 'Telescope' },
        keys = {

            {
                '<leader>ff',
                function() require('telescope.builtin').find_files() end,
                desc = 'Telescope find files',
            },
            {
                '<leader>fg',
                function() require('telescope.builtin').live_grep() end,
                desc = 'Telescope live_grep',
            },
            {
                '<leader>fb',
                function() require('telescope.builtin').buffers() end,
                desc = 'Telescope open buffers',
            },
            {
                '<leader>fh',
                function() require('telescope.builtin').help_tags() end,
                desc = 'Telescope help tags',
            },
            {
                '<leader>fk',
                function() require('telescope.builtin').keymaps() end,
                desc = 'Telescope keymaps',
            },
            {
                '<leader>fd',
                function() require('telescope.builtin').spell_suggest() end,
                desc = 'Telescope suggest spelling (search dictionary)',
            },
        },
        config = function()
            require('telescope').setup({
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
                        },
                    },
                },
            })
        end,
    },

    -- Harpoon (fast file navigation between pinned files)
    {
        'theprimeagen/harpoon',
        version = '*',
        lazy = true,
        config = true,
        keys = {
            {
                '<leader>a',
                function() require('harpoon.mark').add_file() end,
                desc = 'Add file to harpoon',
            },
            {
                '<C-e>',
                function() require('harpoon.ui').toggle_quick_menu() end,
                desc = 'Toggle harpoon quick menu',
            },
            -- Protip: To reorder the entries in harpoon quick menu use `Vd` to cut the line and `P` to paste where you want it

            -- Harpoon quick navigation
            {
                '<leader>1',
                function() require('harpoon.ui').nav_file(1) end,
                desc = 'Go to harpoon file 1',
            },
            {
                '<leader>2',
                function() require('harpoon.ui').nav_file(2) end,
                desc = 'Go to harpoon file 2',
            },
            {
                '<leader>3',
                function() require('harpoon.ui').nav_file(3) end,
                desc = 'Go to harpoon file 3',
            },
            {
                '<leader>4',
                function() require('harpoon.ui').nav_file(4) end,
                desc = 'Go to harpoon file 4',
            },
            {
                '<leader>5',
                function() require('harpoon.ui').nav_file(5) end,
                desc = 'Go to harpoon file 5',
            },
            {
                '<leader>6',
                function() require('harpoon.ui').nav_file(6) end,
                desc = 'Go to harpoon file 6',
            },
            {
                '<leader>7',
                function() require('harpoon.ui').nav_file(7) end,
                desc = 'Go to harpoon file 7',
            },
            {
                '<leader>8',
                function() require('harpoon.ui').nav_file(8) end,
                desc = 'Go to harpoon file 8',
            },
            {
                '<leader>9',
                function() require('harpoon.ui').nav_file(9) end,
                desc = 'Go to harpoon file 9',
            },
            {
                '<leader>0',
                function() require('harpoon.ui').nav_file(0) end,
                desc = 'Go to harpoon file 10',
            },
        },
    },

    ---------------------------------------------------------------------------
    -- Utils

    -- Autopair brackets and quotes
    {
        'echasnovski/mini.pairs',
        version = '*',
        lazy = true,
        event = 'VeryLazy',
        config = true,
    },
    -- Comment toggling
    {
        'echasnovski/mini.comment',
        version = '*',
        lazy = true,
        event = 'VeryLazy',
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
        version = '*',
        lazy = true,
        event = 'VeryLazy',
        config = true,
    },
    -- Open terminal within neovi
    {
        'akinsho/toggleterm.nvim',
        version = '*',
        lazy = true,
        config = true,
        cmd = { 'ToggleTerm' },
        keys = {
            {
                '<leader>tt',
                '<cmd>exe v:count1 . "ToggleTerm"<CR>',
                desc = 'Toggle ToggleTerm',
            },
            {

                [[<C-\>]],
                '<cmd>exe v:count1 . "ToggleTerm"<CR>',
                desc = 'Toggle ToggleTerm',
                mode = { 'n', 'i' },
            },
        },
    },
    -- Diagnostic info
    {
        'folke/trouble.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        version = '*',
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
        version = '*',
        lazy = true,
        config = true,
        -- All the user commands added by the plugin
        cmd = { 'Ollama', 'OllamaModel', 'OllamaServe', 'OllamaServeStop' },

        -- Sample keybind for prompting. Note that the <c-u> is important for selections to work properly.
        keys = {
            {
                '<leader>oo',
                ":<c-u>lua require('ollama').prompt()<cr>",
                desc = 'ollama prompt',
                mode = { 'n', 'v' },
            },
        },
    },

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
        version = '*',
        lazy = true,
        config = true,
        cmd = { 'UndotreeToggle', 'UndotreeShow' },
        keys = {
            {
                '<leader>u',
                vim.cmd.UndotreeToggle,
                desc = 'Toggle Undotree pluggin',
            },
        },
    },

    ---------------------------------------------------------------------------
    -- Parser for syntax highlighting
    {
        'nvim-treesitter/nvim-treesitter',
        version = '*',
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
            { '<leader>i', vim.cmd.IronRepl, desc = '󱠤 Toggle REPL' },
            { '<leader>I', vim.cmd.IronRestart, desc = '󱠤 Restart REPL' },

            -- these keymaps need no right-hand-side, since that is defined by the
            -- plugin config further below
            { '+', mode = { 'n', 'x' }, desc = '󱠤 Send-to-REPL Operator' },
            { '++', desc = '󱠤 Send Line to REPL' },
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
    -- DEBUGGING

    -- DAP Client for nvim
    -- - start the debugger with `<leader>dc`
    -- - add breakpoints with `<leader>db`
    -- - terminate the debugger `<leader>dt`
    {
        'mfussenegger/nvim-dap',
        version = '*',
        lazy = true,
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
                desc = 'Down',
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
        version = '*',
        lazy = true,
        dependencies = 'mfussenegger/nvim-dap',
        keys = {
            {
                '<leader>du',
                function() require('dapui').toggle() end,
                desc = 'Debug: Toggle Debugger UI',
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
        version = '*',
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

    -- Adds workspace configuration file support
    {
        'folke/neoconf.nvim',
        version = '*',
        lazy = false,
        config = true,
    },

    -- Configure Lua LSP to know about neovim plugins when in neovim config
    {
        'folke/neodev.nvim',
        version = '*',
        lazy = true,
        ft = 'lua',
        config = function()
            require('neodev').setup({
                -- -- Workaround to get correctly configure lua_ls for neovim config
                -- -- https://github.com/folke/neodev.nvim/issues/158#issuecomment-1672421325
                -- override = function(_, library)
                --     library.enabled = true
                --     library.plugins = true
                -- end,
            })
        end,
    },
    -- Manager for external tools (LSPs, linters, debuggers, formatters)
    -- auto-install of those external tools
    {
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        version = '*',
        lazy = true,
        event = 'VeryLazy',
        dependencies = {
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },
        },
        opts = {
            ensure_installed = {
                'pyright', -- LSP for python
                'ruff-lsp', -- linter for python (includes flake8, pep8, etc.)
                'debugpy', -- python debugger
                'black', -- python formatter
                'isort', -- python organize imports
                'taplo', -- LSP for toml (for pyproject.toml files)

                'lua-language-server', -- LSP for lua files
                'stylua', -- Formatter for lua files

                'prettier', -- Formatter typescript (keywords: angular, css, flow, graphql, html, json, jsx, javascript, less, markdown, scss, typescript, vue, yaml
                'typescript-language-server', -- tsserver LSP (keywords: typescript, javascript)
                'eslint-lsp', -- eslint Linter (implemented as a standalone lsp to improve speed)(keywords: javascript, typescript)

                'ansible-language-server',
                'ansible-lint',
            },
        },
    },
    {
        'williamboman/mason.nvim',
        version = '*',
        lazy = true,
        config = true,
    },
    {
        'williamboman/mason-lspconfig.nvim',
        version = '*',
        lazy = true,
        config = function()
            local lsp_zero = require('lsp-zero')

            require('mason-lspconfig').setup({
                handlers = {
                    lsp_zero.default_setup,
                },
            })
        end,
    },

    -- LSP Support
    {
        'VonHeikemen/lsp-zero.nvim',
        lazy = true,
        config = function()
            local lsp_zero = require('lsp-zero')

            lsp_zero.preset('recommended')

            lsp_zero.on_attach(function(_, bufnr)
                -- see :help lsp-zero-keybindings
                -- to learn the available actions
                lsp_zero.default_keymaps({ buffer = bufnr })

                vim.keymap.set(
                    'n',
                    '<leader>vca',
                    function() vim.lsp.buf.code_action() end,
                    {
                        buffer = bufnr,
                        remap = false,
                        desc = 'LSP: Open Code Action menu',
                    }
                )
                vim.keymap.set(
                    'n',
                    '<leader>vrr',
                    function() vim.lsp.buf.references() end,
                    {
                        buffer = bufnr,
                        remap = false,
                        desc = 'LSP: Find references',
                    }
                )
                vim.keymap.set(
                    'n',
                    '<leader>vrn',
                    function() vim.lsp.buf.rename() end,
                    {
                        buffer = bufnr,
                        remap = false,
                        desc = 'LSP: Rename symbol',
                    }
                )
            end)

            lsp_zero.setup()
        end,
    },
    {
        'neovim/nvim-lspconfig',
        version = '*',
        lazy = true,
        dependencies = {
            { 'VonHeikemen/lsp-zero.nvim' }, --need lsp zero configured before nvim-lspconfig
            { 'hrsh7th/cmp-nvim-lsp' },
        },
        config = function()
            local lspconfig = require('lspconfig')
            --https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
            lspconfig.lua_ls.setup({
                settings = {
                    Lua = {
                        runtime = { version = 'LuaJIT' },
                        completion = {
                            callSnippet = 'Replace',
                        },
                        hint = { enable = true },
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
        end,
    },
    -- Autocompletion
    {
        'hrsh7th/nvim-cmp',
        version = '*',
        lazy = true,
        event = 'InsertEnter',
        dependencies = {
            { 'L3MON4D3/LuaSnip' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
        },
        config = function()
            local cmp = require('cmp')
            local cmp_action = require('lsp-zero').cmp_action()
            local cmp_select = { behavior = cmp.SelectBehavior.Select }

            cmp.setup({
                mapping = cmp.mapping.preset.insert({
                    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),

                    -- `Enter` key to confirm completion
                    ['<CR>'] = cmp.mapping.confirm({ select = false }),

                    -- Ctrl+Space to trigger completion menu
                    ['<C-Space>'] = cmp.mapping.complete(),

                    -- Complete common string
                    ['<C-l>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            return cmp.complete_common_string()
                        end
                        fallback()
                    end, { 'i', 'c' }),

                    -- Navigate between snippet placeholder
                    ['<C-f>'] = cmp_action.luasnip_jump_forward(),
                    ['<C-b>'] = cmp_action.luasnip_jump_backward(),
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        local luasnip = require('luasnip')
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),

                    ['<S-Tab>'] = cmp.mapping(function(fallback)
                        local luasnip = require('luasnip')
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                    -- Scroll up and down in the completion documentation
                    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-d>'] = cmp.mapping.scroll_docs(4),
                }),
            })
        end,
    },

    -- Snippets
    {
        'L3MON4D3/LuaSnip',
        version = '*',
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
        version = '*',
        lazy = true,
        ft = 'python',
        dependencies = {
            'neovim/nvim-lspconfig',
            'nvim-telescope/telescope.nvim',
            'mfussenegger/nvim-dap-python',
        },
        opts = {
            dap_enabled = true, -- makes the debugger work with venv
            name = { 'venv', '.venv' },
        },
    },

    -- Formatting client: conform.nvim
    -- - configured to use black & isort in python
    -- - use the taplo-LSP for formatting in toml
    -- - Formatting is triggered via `<leader>f`, but also automatically on save
    {
        'stevearc/conform.nvim',
        event = 'BufWritePre', -- load the plugin before saving
        opts = {
            formatters_by_ft = {
                lua = { 'stylua' },
                -- first use isort and then black
                python = { 'isort', 'black' },
                typescript = { 'prettier' },
                javascript = { 'prettier' },
                yaml = { 'prettier' },
                -- "inject" is a "special" formatter from conform.nvim, which
                -- formats treesitter-injected code. In effect, hits will make
                -- conform.nvim format any python codeblocks inside a markdown file.
                markdown = { 'inject' },
            },
            -- enable format-on-save
            format_on_save = function(bufnr)
                -- Disable with a global or buffer-local variable
                if
                    vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat
                then
                    return
                end
                return { timeout_ms = 500, lsp_fallback = true }
            end,
        },
    },

    ---------------------------------------------------------------------------
    -- Import plugins defined in the plugins folder
    { import = 'plugins' },
})
