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
