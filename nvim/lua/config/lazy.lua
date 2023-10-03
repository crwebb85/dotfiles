local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)


require("lazy").setup({
    ---------------------------------------------------------------------------
    -- Git integration
    "tpope/vim-fugitive",

    "sindrets/diffview.nvim",

    ---------------------------------------------------------------------------
    -- Navigation

    -- Fuzzy finder (for many things not just file finder)
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.2',
        dependencies = {
            'nvim-lua/plenary.nvim', -- telescope uses plenary to create the UI
        }
    },

    -- Harpoon (fast file navigation between pinned files)
    'theprimeagen/harpoon',

    ---------------------------------------------------------------------------
    -- Clipboard support (copy from vim to the outside world)
    "ojroques/nvim-osc52",

    -- Color theme
    {
        'rose-pine/neovim',
        name = 'rose-pine',
        lazy = false,
        config = function()
            require("rose-pine").setup({
                disable_background = true
            })
        end
    },

    ---------------------------------------------------------------------------
    -- Undotree the solution to screwups
    'mbbill/undotree',

    ---------------------------------------------------------------------------
    -- Parser for syntax highlighting
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        config = function()
            require 'nvim-treesitter.configs'.setup {
                -- A list of parser names, or "all"
                ensure_installed = {
                    "javascript",
                    "typescript",
                    "tsx",
                    "css",
                    "json",
                    "html",
                    "xml",
                    "yaml",
                    "c",
                    "lua",
                    "rust",
                    "vim",
                    "vimdoc",
                    "query",
                    "markdown",
                    "markdown_inline",
                    "python",
                    "toml",
                },

                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,

                -- Automatically install missing parsers when entering buffer
                -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
                auto_install = true,

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
            }
        end
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
        "Vigemus/iron.nvim",
        keys = {
            { "<leader>i", vim.cmd.IronRepl, desc = "󱠤 Toggle REPL" },
            { "<leader>I", vim.cmd.IronRestart, desc = "󱠤 Restart REPL" },

            -- these keymaps need no right-hand-side, since that is defined by the
            -- plugin config further below
            { "+", mode = { "n", "x" }, desc = "󱠤 Send-to-REPL Operator" },
            { "++", desc = "󱠤 Send Line to REPL" },
        },

        -- since irons's setup call is `require("iron.core").setup`, instead of
        -- `require("iron").setup` like other plugins would do, we need to tell
        -- lazy.nvim which module to via the `main` key
        main = "iron.core",

        opts = {
            keymaps = {
                send_line = "++",
                visual_send = "+",
                send_motion = "+",
            },
            config = {
                -- this defined how the repl is opened. Here we set the REPL window
                -- to open in a horizontal split to a bottom, with a height of 10
                -- cells.
                repl_open_cmd = "horizontal bot 10 split",

                -- This defines which binary to use for the REPL. If `ipython` is
                -- available, it will use `ipython`, otherwise it will use `python3`.
                -- since the python repl does not play well with indents, it's
                -- preferable to use `ipython` or `bypython` here.
                -- (see: https://github.com/Vigemus/iron.nvim/issues/348)
                repl_definition = {
                    python = {
                        command = function()
                            local ipythonAvailable = vim.fn.executable("ipython") == 1
                            local binary = ipythonAvailable and "ipython" or "python3"
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
        "mfussenegger/nvim-dap",
        keys = {
            {
                "<leader>dc",
                function() require("dap").continue() end,
                desc = "Start/Continue Debugger",
            },
            {
                "<leader>db",
                function() require("dap").toggle_breakpoint() end,
                desc = "Add Breakpoint",
            },
            {
                "<leader>dt",
                function() require("dap").terminate() end,
                desc = "Terminate Debugger",
            },
        },
    },

    -- UI for the debugger
    -- - the debugger UI is also automatically opened when starting/stopping the debugger
    -- - toggle debugger UI manually with `<leader>du`
    {
        "rcarriga/nvim-dap-ui",
        dependencies = "mfussenegger/nvim-dap",
        keys = {
            {
                "<leader>du",
                function() require("dapui").toggle() end,
                desc = "Toggle Debugger UI",
            },
        },
        -- automatically open/close the DAP UI when starting/stopping the debugger
        config = function()
            local listener = require("dap").listeners
            listener.after.event_initialized["dapui_config"] = function() require("dapui").open() end
            listener.before.event_terminated["dapui_config"] = function() require("dapui").close() end
            listener.before.event_exited["dapui_config"] = function() require("dapui").close() end
        end,
    },

    -- Configuration for the python debugger
    {
        "mfussenegger/nvim-dap-python",
        dependencies = "mfussenegger/nvim-dap",
    },

    ---------------------------------------------------------------------------
    --- LSP's and more

    -- Manager for external tools (LSPs, linters, debuggers, formatters)
    -- auto-install of those external tools
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = {
            { "williamboman/mason.nvim",           opts = true },
            { "williamboman/mason-lspconfig.nvim", opts = true },
        },
        opts = {
            ensure_installed = {
                "pyright",             -- LSP for python
                "ruff-lsp",            -- linter for python (includes flake8, pep8, etc.)
                "debugpy",             -- python debugger
                "black",               -- python formatter
                "isort",               -- python organize imports
                "taplo",               -- LSP for toml (for pyproject.toml files)
                "lua-language-server", -- LSP for lua files
                "stylua",              -- Formatter for lua files
            },
        },
    },

    -- LSP Support
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        lazy = true,
        config = false,
    },
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            { 'hrsh7th/cmp-nvim-lsp' },
        }
    },
    -- Autocompletion
    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            { 'L3MON4D3/LuaSnip' }
        },
    },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },
    { 'saadparwaiz1/cmp_luasnip' },
    { 'hrsh7th/cmp-nvim-lsp' },

    -- Snippets
    { 'L3MON4D3/LuaSnip' },
    { 'rafamadriz/friendly-snippets' },

    -- Virtual Environments
    -- select virtual environments
    -- - makes pyright and debugpy aware of the selected virtual environment
    -- - Select a virtual environment with `:VenvSelect`
    {
        "linux-cultist/venv-selector.nvim",
        dependencies = {
            "neovim/nvim-lspconfig",
            "nvim-telescope/telescope.nvim",
            "mfussenegger/nvim-dap-python",
        },
        opts = {
            dap_enabled = true, -- makes the debugger work with venv
            name = { "venv", ".venv" },
        },
    },

    -- Formatting client: conform.nvim
    -- - configured to use black & isort in python
    -- - use the taplo-LSP for formatting in toml
    -- - Formatting is triggered via `<leader>f`, but also automatically on save
    {
        "stevearc/conform.nvim",
        event = "BufWritePre", -- load the plugin before saving
        opts = {
            formatters_by_ft = {
                -- first use isort and then black
                python = { "isort", "black" },
                -- "inject" is a "special" formatter from conform.nvim, which
                -- formats treesitter-injected code. In effect, hits will make
                -- conform.nvim format any python codeblocks inside a markdown file.
                markdown = { "inject" },
            },
            -- enable format-on-save
            format_on_save = {
                -- when no formatter is setup for a filetype, fallback to formatting
                -- via the LSP. This is relevant e.g. for taplo (toml LSP), where the
                -- LSP can handle the formatting for us
                lsp_fallback = true,
            },
        },
    },
})


local lsp_zero = require('lsp-zero')

lsp_zero.preset("recommended")

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

        -- Navigate between snippet placeholder
        ['<C-f>'] = cmp_action.luasnip_jump_forward(),
        ['<C-b>'] = cmp_action.luasnip_jump_backward(),

        -- Scroll up and down in the completion documentation
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-d>'] = cmp.mapping.scroll_docs(4),
    })
})


lsp_zero.on_attach(function(client, bufnr)
    -- see :help lsp-zero-keybindings
    -- to learn the available actions
    lsp_zero.default_keymaps({ buffer = bufnr })

    local opts = { buffer = bufnr, remap = false }

    vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
    vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
    vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
end)

lsp_zero.setup()

require('mason').setup({})
require('mason-lspconfig').setup({
    handlers = {
        lsp_zero.default_setup,
    },
})

-- configures debugpy
-- uses the debugypy installation by mason
local debugpyPythonPath = require("mason-registry").get_package("debugpy"):get_install_path()
    .. "/.venv/bin/python3" -- TODO figure out if I need dynamically determine path
require("dap-python").setup(debugpyPythonPath, {})

--TODO add statusline functionality https://github.com/linux-cultist/venv-selector.nvim#tips-and-tricks
