local M = {}

--- Toggle Inlay hints
local isInlayHintsEnabled = false
function M.toggle_inlay_hints()
    isInlayHintsEnabled = not isInlayHintsEnabled

    vim.lsp.inlay_hint.enable(isInlayHintsEnabled, { bufnr = 0 })

    vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
        group = vim.api.nvim_create_augroup('inlay_hints', { clear = true }),
        pattern = '?*',
        callback = function()
            vim.lsp.inlay_hint.enable(isInlayHintsEnabled, { bufnr = 0 })
        end,
    })
end

return M
