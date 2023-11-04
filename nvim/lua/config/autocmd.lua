local init_group = 'init'

vim.api.nvim_create_augroup(init_group, { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', { group = init_group, callback = function() vim.highlight.on_yank() end })

vim.api.nvim_create_autocmd("VimEnter", {
    desc = "Auto select virtualenv Nvim open",
    pattern = "*",
    callback = function()
        local venv = vim.fn.findfile("requirements.txt", vim.fn.getcwd() .. ";")
        --local venv = vim.fn.findfile("pyproject.toml", vim.fn.getcwd() .. ";")
        if venv ~= "" then
            require("venv-selector").retrieve_from_cache()
        end
    end,
    once = true,
})

local remember_folds_group = 'remember_folds'

vim.api.nvim_create_augroup(remember_folds_group, { clear = true })
-- bufleave but not bufwinleave captures closing 2nd tab
-- BufHidden for compatibility with `set hidden`
vim.api.nvim_create_autocmd({ 'BufWinLeave', 'BufLeave', 'BufWritePost', 'BufHidden', 'QuitPre' },
    {
        desc = "Saves view file (saves information like open/closed folds)",
        group = remember_folds_group,
        pattern = "?*",
        -- nested is needed by bufwrite* (if triggered via other autocmd)
        nested = true,
        callback = SaveView,
    }
)


--TODO debug loading betwen format and writing
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufWritePost' },
    {
        desc = "Loads the view file for the buffer (reloads open/closed folds)",
        group = remember_folds_group,
        pattern = "?*",
        callback = function()
            if vim.api.nvim_get_option_value("diff", {}) and vim.api.nvim_get_option_value('foldexpr', {}) == "v:lua.vim.treesitter.foldexpr()" then
                -- Reset Folding back to using tresitter after no longer using diff mode
                vim.api.nvim_set_option_value("foldmethod", "expr", {})
                vim.api.nvim_set_option_value("foldexpr ", "v:lua.vim.treesitter.foldexpr()", {})
            end
            LoadView()
        end,
    }
)


local format_on_save_group = 'format_on_save_group'
vim.api.nvim_create_augroup(format_on_save_group, { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    group = format_on_save_group,
    callback = function(args)
        require("conform").format({ bufnr = args.buf, lsp_fallback = true })
    end,
})
