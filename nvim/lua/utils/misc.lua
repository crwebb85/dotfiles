local M = {}

---Hack to fix processes that get confused on windows when paths use a forward slash
---This must as close to the line of code that is having issues as possible and for some
---reason must be reran each time.
---
---I am using this primarily for debuggers on windows as they seem to have issues
---finding the pdb files
function M.shellslash_hack()
    if vim.fn.has('win32') == 1 then vim.cmd([[set noshellslash]]) end
end

---Get the get default git branch name
---@return string
function M.get_default_branch_name()
    local res = vim.system(
        { 'git', 'rev-parse', '--verify', 'main' },
        { capture_output = true }
    ):wait()
    return res.code == 0 and 'main' or 'master'
end

---Delete the buffer by buffer number
---@param bufnr uinteger
function M.delete_buf(bufnr)
    if bufnr ~= nil then vim.api.nvim_buf_delete(bufnr, { force = true }) end
end

---Open buffer in split
---@param bufnr uinteger
---@param vertical_split string?
function M.split(bufnr, vertical_split)
    local cmd = vertical_split and 'vsplit' or 'split'

    vim.cmd(cmd)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, bufnr)
end

---Resize split
---@param amount integer
---@param split_vertical string?
function M.resize(amount, split_vertical)
    local cmd = split_vertical and 'vertical resize ' or 'resize'
    cmd = cmd .. amount

    vim.cmd(cmd)
end

---Schedule an error notification
---@param err any
function M.scheduled_error(err)
    vim.schedule(function() vim.notify(err, vim.log.levels.ERROR) end)
end

return M
