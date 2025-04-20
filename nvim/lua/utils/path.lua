local M = {}

---Creates the given file if it doesn't exist
---from https://github.com/backdround/global-note.nvim/blob/1e0d4bba425d971ed3ce40d182c574a25507115c/lua/global-note/utils.lua#L5C1-L24C4
---@param filepath string
M.ensure_file_exists = function(filepath)
    vim.validate({ file_path = { filepath, 'string' } })

    local stat = vim.loop.fs_stat(filepath)
    if stat and stat.type == 'file' then return end

    if stat and stat.type ~= 'file' then
        local template = "Path %s already exists and it's not a file!"
        error(template:format(filepath))
    end

    local file, err = io.open(filepath, 'w')
    if not file then error(err) end

    file:close()
end

---Creates the given directory if it doesn't exist
---from https://github.com/backdround/global-note.nvim/blob/1e0d4bba425d971ed3ce40d182c574a25507115c/lua/global-note/utils.lua#L28C1-L46C4
---@param path string
M.ensure_directory_exists = function(path)
    vim.validate({ directory_path = { path, 'string' } })

    local stat = vim.loop.fs_stat(path)
    if stat and stat.type == 'directory' then return end

    if stat and stat.type ~= 'directory' then
        local template = "Path %s already exists and it's not a directory!"
        error(template:format(path))
    end

    local status, err = vim.loop.fs_mkdir(path, 493)

    if not status then error('Unable to create a directory: ' .. err) end
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

    local predicted_executable_path =
        vim.fs.joinpath(data_path, 'mason', 'bin', mason_tool_name)

    local executable_path = vim.fn.exepath(predicted_executable_path)
    if executable_path == '' then
        vim.print(
            'Cannot find mason tool called '
                .. mason_tool_name
                .. '. Things may not work correctly if it is not installed by the time it needs to be used.'
        )

        if require('utils.platform').is.win then
            executable_path = predicted_executable_path .. '.cmd'
        else
            executable_path = predicted_executable_path
        end
    end
    return executable_path
end

return M
