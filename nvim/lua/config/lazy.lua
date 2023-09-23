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
    -- git integration
    "tpope/vim-fugitive",
    
    "sindrets/diffview.nvim",

    -- fuzzy finder (for many things not just file finder)
    {
        'nvim-telescope/telescope.nvim', 
        tag = '0.1.2',
        dependencies = { 
            'nvim-lua/plenary.nvim', -- telescope uses plenary to create the UI
        } 
    },

    -- clipboard support (copy from vim to the outside world)
    "ojroques/nvim-osc52",

    -- color theme
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

    -- LSP (Language Server Protocol
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        config = function()
            require'nvim-treesitter.configs'.setup {
                -- A list of parser names, or "all"
                ensure_installed = { "javascript", "typescript", "c", "lua", "rust", "vim", "vimdoc", "query" },

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

})
