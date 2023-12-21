local M = {}

M.run = function() vim.lsp.codelens.run() end

local virtlines_enabled = true
M.toggle_virtlines = function()
    virtlines_enabled = not virtlines_enabled
    M.refresh_virtlines()
end

M.refresh_virtlines = function() vim.lsp.codelens.refresh() end

return M
