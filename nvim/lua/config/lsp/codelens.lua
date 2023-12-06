local M = {}

M.run = function()
    vim.lsp.codelens.run()
    -- if vim.o.modified then vim.cmd([[w]]) end
    --
    -- local bufnr = vim.api.nvim_get_current_buf()
    -- local line = vim.api.nvim_win_get_cursor(0)[1]
    --
    -- local lenses = vim.deepcopy(vim.lsp.codelens.get(bufnr))
    -- vim.print(lenses)
    -- lenses = vim.tbl_filter(
    --     function(v) return v.range.start.line < line end,
    --     lenses
    -- )
    --
    -- table.sort(
    --     lenses,
    --     function(a, b) return a.range.start.line < b.range.start.line end
    -- )
    --
    -- local _, lens = next(lenses)
    --
    -- local client_id = next(vim.lsp.get_clients({ bufnr = bufnr }))
    -- local client = vim.lsp.get_client_by_id(client_id)
    -- if client == nil then return {} end
    -- client.request('workspace/executeCommand', lens.command, function(...)
    --     local result = vim.lsp.handlers['workspace/executeCommand'](...)
    --     vim.lsp.codelens.refresh()
    --     return result
    -- end, bufnr)
end

local virtlines_enabled = true
M.toggle_virtlines = function()
    virtlines_enabled = not virtlines_enabled
    M.refresh_virtlines()
end

-- local colors = require('tokyonight.colors').setup()
-- vim.api.nvim_set_hl(0, 'VirtNonText', { fg = colors.dark3, italic = true })

M.refresh_virtlines = function()
    vim.lsp.codelens.refresh()

    -- local bufnr = vim.api.nvim_get_current_buf()
    -- local params = { textDocument = vim.lsp.util.make_text_document_params() }
    -- vim.lsp.buf_request(
    --     bufnr,
    --     'textDocument/codeLens',
    --     params,
    --     function(err, result, _, _)
    --         if err or result == nil then return end
    --
    --         local ns = vim.api.nvim_create_namespace('custom-lsp-codelens')
    --         vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    --
    --         if not virtlines_enabled then return end
    --
    --         for _, lens in ipairs(result) do
    --             local title = lens.command.title
    --             local range = lens.range
    --             local prefix = string.rep(' ', lens.range.start.character)
    --             local text = prefix .. title
    --
    --             local lines = { { { text, 'VirtNonText' } } }
    --             if string.len(text) > 100 then
    --                 vim.g.something = true
    --                 lines = {}
    --
    --                 local split_text = vim.split(text, '->')
    --
    --                 for i, line in ipairs(split_text) do
    --                     if i ~= #split_text then line = line .. ' ->' end
    --
    --                     table.insert(lines, { { line, 'VirtNonText' } })
    --                 end
    --             end
    --
    --             vim.api.nvim_buf_set_extmark(bufnr, ns, range.start.line, 0, {
    --                 virt_lines_above = true,
    --                 virt_lines = lines,
    --             })
    --         end
    --     end
    -- )
end

return M
