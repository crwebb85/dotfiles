local M = {}

M.run = function() vim.lsp.codelens.run() end

local codelens_enabled = true
M.toggle_codelens = function()
    codelens_enabled = not codelens_enabled
    M.refresh_codelens()
end

M.refresh_codelens = function(bufnr)
    if codelens_enabled == true then
        vim.lsp.codelens.refresh()
    else
        vim.lsp.codelens.clear(nil, bufnr)
    end
end

return M
