local M = {}

function M.run() vim.lsp.codelens.run() end

local codelens_enabled = true
function M.toggle_codelens()
    codelens_enabled = not codelens_enabled
    M.refresh_codelens({ bufnr = nil })
end

function M.refresh_codelens(bufnr)
    if codelens_enabled == true then
        vim.lsp.codelens.refresh({ bufnr = bufnr })
    else
        vim.lsp.codelens.clear(nil, bufnr)
    end
end

local is_autocmds_setup = false
function M.enable()
    if is_autocmds_setup then return end
    is_autocmds_setup = true
    -- vim.notify('Codelens enabled', vim.log.levels.INFO)

    local augroup_codelens =
        vim.api.nvim_create_augroup('lsp_codelens', { clear = true })

    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'CursorHold' }, {
        group = augroup_codelens,
        callback = function(event) M.refresh_codelens(event.buf) end,
    })
end

return M
