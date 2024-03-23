local M = {}
---TODO replace with :h getregion which is in newer versions of neovim
---Get the text in the visual selection
---@param bufnr number of the buffer with text selected
---@return string[]
function M.get_visual_selection(bufnr)
    local start_pos = vim.api.nvim_buf_get_mark(0, '<')
    local start_row = start_pos[1]
    local start_col = start_pos[2]

    local end_pos = vim.api.nvim_buf_get_mark(0, '>')
    local end_row = end_pos[1]
    local end_col = end_pos[2]
    -- vim.print(start_pos)
    -- vim.print(end_pos)

    ---@type string[]
    local text = {}

    if end_col == 2147483647 then
        text = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, true)
    else
        text = vim.api.nvim_buf_get_text(
            bufnr,
            start_row - 1,
            start_col,
            end_row - 1,
            end_col + 1,
            {}
        )
    end
    return text
end

---Hack to fix processes that get confused on windows when paths use a forward slash
---This must as close to the line of code that is having issues as possible and for some
---reason must be reran each time.
---
---I am using this primarily for debuggers on windows as they seem to have issues
---finding the pdb files
function M.shellslash_hack()
    if require('utils.platform').is.win then vim.cmd([[set noshellslash]]) end
end

return M
