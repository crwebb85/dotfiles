local M = {}

M.is_existing_file = function(filepath)
    vim.validate({ file_path = { filepath, 'string' } })

    local stat = vim.loop.fs_stat(filepath)
    return stat and stat.type == 'file'
end

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
        vim.notify(
            'Cannot find mason tool called '
                .. mason_tool_name
                .. '. Things may not work correctly if it is not installed by the time it needs to be used.',
            vim.log.levels.WARN
        )

        if vim.fn.has('win32') == 1 then
            executable_path = predicted_executable_path .. '.cmd'
        else
            executable_path = predicted_executable_path
        end
    end
    return executable_path
end

function M.get_project_paths()
    ---@type string[]
    local project_search_paths = {} -- The folders called projects not the actual project folders
    if vim.fn.has('win32') == 1 then
        local user_profile_path = vim.fs.normalize('$USERPROFILE')
        if user_profile_path == '$USERPROFILE' then
            error(
                'On Windows you are expected to have a `$USERPROFILE` environment variable'
            )
        end

        --Get projects folder in OneDrive dir
        local search_path = vim.fs.joinpath(
            user_profile_path,
            'OneDrive',
            'documents',
            'projects'
        )
        search_path = vim.fs.abspath(vim.fs.normalize(search_path))
        table.insert(project_search_paths, search_path)

        --Get projects folder in regular documents dir
        search_path =
            vim.fs.joinpath(user_profile_path, 'documents', 'projects')
        search_path = vim.fs.abspath(vim.fs.normalize(search_path))
        table.insert(project_search_paths, search_path)
    else
        error("TODO: Implement get_projects_paths for other  OS's")
    end

    vim.list.unique(project_search_paths)
    local project_paths = {}
    for _, project_search_path in ipairs(project_search_paths) do
        for name, type in vim.fs.dir(project_search_path, { depth = 1 }) do
            if type == 'directory' then
                local project_path = vim.fs.joinpath(project_search_path, name)
                table.insert(project_paths, project_path)
            end
        end
    end
    return project_paths
end

function M.get_poc_paths()
    ---@type string[]
    local poc_search_paths = {} -- The folders called pocs not the actual poc folders
    if vim.fn.has('win32') == 1 then
        local user_profile_path = vim.fs.normalize('$USERPROFILE')
        if user_profile_path == '$USERPROFILE' then
            error(
                'On Windows you are expected to have a `$USERPROFILE` environment variable'
            )
        end

        --Get pocs folder in OneDrive dir
        local search_path =
            vim.fs.joinpath(user_profile_path, 'OneDrive', 'documents', 'poc')
        search_path = vim.fs.abspath(vim.fs.normalize(search_path))
        table.insert(poc_search_paths, search_path)

        --Get pocs folder in regular documents dir
        search_path = vim.fs.joinpath(user_profile_path, 'documents', 'poc')
        search_path = vim.fs.abspath(vim.fs.normalize(search_path))
        table.insert(poc_search_paths, search_path)
    else
        error("TODO: Implement get_pocs_paths for other  OS's")
    end

    vim.list.unique(poc_search_paths)
    local poc_paths = {}
    for _, poc_search_path in ipairs(poc_search_paths) do
        for name, type in vim.fs.dir(poc_search_path, { depth = 1 }) do
            if type == 'directory' then
                local poc_path = vim.fs.joinpath(poc_search_path, name)
                table.insert(poc_paths, poc_path)
            end
        end
    end
    return poc_paths
end

return M
