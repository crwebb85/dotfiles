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
            require("rose-pine").setup({})
        end     
    },

    -- LSP (Language Server Protocol
    {'nvim-treesitter/nvim-treesitter'},
})
