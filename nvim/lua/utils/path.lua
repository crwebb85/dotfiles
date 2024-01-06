local sep = (function()
    --:h jit
    --jit is a global variable set by neovim with os info
    if jit then
        local os = string.lower(jit.os)
        if os == 'linux' or os == 'osx' or os == 'bsd' then
            return '/'
        else
            return '\\'
        end
    else
        return string.sub(package.config, 1, 1)
    end
end)()

local M = {}

---@param path_components string[]
---@return string
function M.concat(path_components) return table.concat(path_components, sep) end

---@path root_path string
---@path path string
function M.is_subdirectory(root_path, path)
    return root_path == path or path:sub(1, #root_path + 1) == root_path .. sep
end

---@param mason_tool_name string
---@return string
function M.get_mason_tool_path(mason_tool_name)
    local data_path = vim.fn.stdpath('data')
    if data_path == nil then
        error('data path was nil but a string was expected')
    elseif type(data_path) == 'table' then
        error('data path was an array but a string was expected')
    end
    local executable_path = vim.fn.exepath(M.concat({
        data_path,
        'mason',
        'bin',
        mason_tool_name,
    }))
    if executable_path == '' then
        error('No mason tool called ' .. mason_tool_name)
    end
    return executable_path
end

return M
