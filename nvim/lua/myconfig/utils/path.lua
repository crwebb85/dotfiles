local M = {}

---@param filepath string
---@return boolean
M.is_existing_file = function(filepath)
    vim.validate('filepath', filepath, 'string')

    local stat = vim.uv.fs_stat(filepath)
    if stat and stat.type == 'file' then
        return true
    else
        return false
    end
end

---@param path string
---@return boolean
function M.is_directory(path)
    vim.validate('path', path, 'string')
    local stat, _, _ = vim.uv.fs_stat(path)
    return stat and stat.type == 'directory' or false
end

---@param path string
---@return boolean
function M.is_file(path)
    vim.validate('path', path, 'string')
    local stat, _, _ = vim.uv.fs_stat(path)
    return stat and stat.type == 'file' or false
end

local function validate_is_possible_environment_variable_name(s)
    return #s >= 1 and string.sub(s, 1, 1) == '$'
end

---@param env_name string
---@return string[] paths
function M.get_paths_from_environment_variable(env_name)
    vim.validate('env_name', env_name, 'string')
    vim.validate(
        'env_name',
        env_name,
        validate_is_possible_environment_variable_name,
        'expected env_name to contain a `$` as the first character'
    )

    --TODO should I use os.getenv
    local path = vim.fs.normalize(env_name)
    if path == env_name then return {} end
    local paths = vim.split(path, ';', { trimempty = true })
    return paths
end

---@param env_name string
---@return string? path
function M.get_single_path_from_environment_variable(env_name)
    local paths = M.get_paths_from_environment_variable(env_name)
    if #paths <= 0 then return nil end
    if #paths > 1 then
        vim.notify(
            string.format(
                'Expected environment variable %s to contain one path but it contained %s',
                env_name,
                #paths
            ),
            vim.log.levels.WARN
        )
    end
    return paths[1]
end

---Creates the given file if it doesn't exist
---from https://github.com/backdround/global-note.nvim/blob/1e0d4bba425d971ed3ce40d182c574a25507115c/lua/global-note/utils.lua#L5C1-L24C4
---@param filepath string
M.ensure_file_exists = function(filepath)
    vim.validate('file_path', filepath, 'string')

    local stat = vim.uv.fs_stat(filepath)
    if stat and stat.type == 'file' then return end

    if stat and stat.type ~= 'file' then
        local template = "Path %s already exists and it's not a file!"
        error(template:format(filepath))
    end

    local file, err = io.open(filepath, 'w')
    if not file then error(err) end

    file:close()
end

M.is_file_empty = function(filepath)
    local file, err = io.open(filepath, 'r')
    if not file then error(err) end

    -- Try reading zero characters, which tests for EOF
    local content = file:read(0)
    file:close()

    -- If content is nil, the file is empty or already at EOF
    return content == nil
end

---Creates the given directory if it doesn't exist
---from https://github.com/backdround/global-note.nvim/blob/1e0d4bba425d971ed3ce40d182c574a25507115c/lua/global-note/utils.lua#L28C1-L46C4
---@param path string
M.ensure_directory_exists = function(path)
    vim.validate('directory_path', path, 'string')

    local stat = vim.uv.fs_stat(path)
    if stat and stat.type == 'directory' then return end

    if stat and stat.type ~= 'directory' then
        local template = "Path %s already exists and it's not a directory!"
        error(template:format(path))
    end

    local status, err = vim.uv.fs_mkdir(path, 493)

    if not status then error('Unable to create a directory: ' .. err) end
end

---Gets the file extension based on the last period in the filename
---(Does not handle multipart extensions like `.ansible.yaml`)
function M.get_file_extension(filename)
    local extension = filename:match('%.([^.]+)$')
    return extension
end

-------------------------------------------------------------------------------
---Get specific paths

---@return string data_path
function M.get_nvim_data_dir()
    local data_path = vim.fn.stdpath('data')
    if data_path == nil then
        error('data path was nil but a string was expected')
    elseif type(data_path) == 'table' then
        error('data path was an array but a string was expected')
    end

    data_path = vim.fs.normalize(data_path)

    local stat, err, error_name = vim.uv.fs_stat(data_path)
    if not stat or err or error_name then
        local template = 'Error checking path stat for `%s`:\n %s: %s'
        error(template:format(data_path, error_name or '', err or ''))
    end

    if stat and stat.type ~= 'directory' then
        local template = "Path %s already exists and it's not a directory!"
        error(template:format(data_path))
    end

    return data_path
end

---@return string config_path
function M.get_nvim_config_dir()
    local config_path = vim.fn.stdpath('config')
    if config_path == nil then
        error('config path was nil but a string was expected')
    elseif type(config_path) == 'table' then
        error('config path was an array but a string was expected')
    end

    config_path = vim.fs.normalize(config_path)

    local stat, err, error_name = vim.uv.fs_stat(config_path)
    if not stat or err or error_name then
        local template = 'Error checking path stat for `%s`:\n %s: %s'
        error(template:format(config_path, error_name or '', err or ''))
    end

    if stat and stat.type ~= 'directory' then
        local template = "Path %s already exists and it's not a directory!"
        error(template:format(config_path))
    end

    return config_path
end

---@return string plugins_path
function M.get_nvim_plugins_dir()
    local data_path = M.get_nvim_data_dir()
    local plugins_dir =
        vim.fs.joinpath(data_path, 'site', 'pack', 'core', 'opt')

    plugins_dir = vim.fs.normalize(plugins_dir)

    local stat, err, error_name = vim.uv.fs_stat(plugins_dir)
    if not stat or err or error_name then
        local template = 'Error checking path stat for `%s`:\n %s: %s'
        error(template:format(plugins_dir, error_name or '', err or ''))
    end

    if stat and stat.type ~= 'directory' then
        local template = "Path %s already exists and it's not a directory!"
        error(template:format(plugins_dir))
    end

    return plugins_dir
end

---@return string[] plugin_dirs
function M.list_nvim_plugin_dirs()
    local plugins_dir = M.get_nvim_plugins_dir()

    local plugin_dirs = {}
    for name, type in vim.fs.dir(plugins_dir, { depth = 1 }) do
        if type == 'directory' then
            local plugin_path = vim.fs.joinpath(plugins_dir, name)
            table.insert(plugin_dirs, plugin_path)
        end
    end

    return plugin_dirs
end

---@return string runtime_path
function M.get_vimruntime_dir()
    local runtime_path =
        M.get_single_path_from_environment_variable('$VIMRUNTIME')

    if runtime_path == nil then
        error('Could not find $VIMRUNTIME environment variable')
    end

    if not M.is_directory(runtime_path) then
        local template = "Path %s already exists and it's not a directory!"
        error(template:format(runtime_path))
    end

    return runtime_path
end

---@return string note_path
function M.get_my_notes_dir()
    local note_path = M.get_single_path_from_environment_variable('$MY_NOTES')

    if note_path == nil then
        error('Could not find $MY_NOTES environment variable')
    end

    if not M.is_directory(note_path) then
        local template = "Path %s already exists and it's not a directory!"
        error(template:format(note_path))
    end

    return note_path
end

---@return string skeleton_dir
function M.get_skeleton_dir()
    local config_dir = M.get_nvim_config_dir()

    local skeleton_dir = vim.fs.joinpath(config_dir, 'skeletons')
    return skeleton_dir
end

---TODO decide if I need something like this where I build the parsers
---and in one folder and then copy them to the parser folders after it finishes
---This could be useful if the parser is currently in use when the build starts.
---@return string path
function M.get_treesitter_temp_build_path()
    local data_path = M.get_nvim_data_dir()
    local path = vim.fs.joinpath(data_path, 'mytreesitter', 'cache')
    M.ensure_directory_exists(path)
    return path
end

---Fetches the treesitter parsers directory path and creates it if it doesn't exist
---@return string path
function M.get_treesitter_parsers_dir()
    local data_path = M.get_nvim_data_dir()
    local mytreesitter_dir = vim.fs.joinpath(data_path, 'mytreesitter')
    M.ensure_directory_exists(mytreesitter_dir)
    local path = vim.fs.joinpath(mytreesitter_dir, 'parsers')
    M.ensure_directory_exists(path)
    return path
end

---Gets the treesitter parser filepath by parser_name
---Note: the path may not exist
---TODO: possibly support other parser filetypes
---@param parser_name string
---@return string
function M.get_treesitter_parser_path(parser_name)
    local base_path = M.get_treesitter_parsers_dir()
    return vim.fs.joinpath(base_path, parser_name .. '.so')
end

---@param mason_tool_name string
---@return string
function M.get_mason_tool_path(mason_tool_name)
    local data_path = M.get_nvim_data_dir()

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

---@return string basepath of mason data
function M.get_mason_base_path()
    local data_path = M.get_nvim_data_dir()
    return vim.fs.joinpath(data_path, 'mason')
end

---list of project paths
---@return string[] project_paths
function M.get_project_paths()
    ---@type string[]
    local project_search_paths = {} -- The folders called projects not the actual project folders
    if vim.fn.has('win32') == 1 then
        local user_profile_paths =
            M.get_paths_from_environment_variable('$USERPROFILE')
        for _, user_profile_path in ipairs(user_profile_paths) do
            if M.is_directory(user_profile_path) then
                --Get projects folder in OneDrive dir
                local my_documents_onedrive_projects_path = vim.fs.joinpath(
                    user_profile_path,
                    'OneDrive',
                    'documents',
                    'projects'
                )
                my_documents_onedrive_projects_path = vim.fs.abspath(
                    vim.fs.normalize(my_documents_onedrive_projects_path)
                )
                table.insert(
                    project_search_paths,
                    my_documents_onedrive_projects_path
                )

                --Get projects folder in regular documents dir
                local my_documents_project_path =
                    vim.fs.joinpath(user_profile_path, 'documents', 'projects')
                my_documents_project_path =
                    vim.fs.abspath(vim.fs.normalize(my_documents_project_path))
                table.insert(project_search_paths, my_documents_project_path)
            end
        end
    else
        vim.notify(
            "TODO: Implement get_projects_paths for other OS's",
            vim.log.levels.WARN
        )
    end

    --Note: MYWORKSPACE is a custom environment variable I will add
    --if I need to store my projects/poc's on a different drive and not in my
    --documents folder
    local workspace_paths =
        M.get_paths_from_environment_variable('$MYWORKSPACE')
    for _, workspace_path in ipairs(workspace_paths) do
        if M.is_directory(workspace_path) then
            local myworkspace_projects_path =
                vim.fs.joinpath(workspace_path, 'projects')
            myworkspace_projects_path =
                vim.fs.abspath(vim.fs.normalize(myworkspace_projects_path))
            table.insert(project_search_paths, myworkspace_projects_path)
        end
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

    -- Add my dotfiles to the searchable list (for quick selection)
    local config_paths =
        M.get_paths_from_environment_variable('$XDG_CONFIG_HOME')
    for _, config_path in ipairs(config_paths) do
        if M.is_directory(config_path) then
            table.insert(project_paths, config_path)
        end
    end

    -- Add the project parent directories to the searchable list (to make creating new projects easier)
    vim.list_extend(project_paths, project_search_paths)

    return project_paths
end

---Lists the paths in my poc directory
---@return string[] poc_paths
function M.get_poc_paths()
    ---@type string[]
    local poc_search_paths = {} -- The folders called pocs not the actual poc folders
    if vim.fn.has('win32') == 1 then
        local user_profile_paths =
            M.get_paths_from_environment_variable('$USERPROFILE')
        for _, user_profile_path in ipairs(user_profile_paths) do
            if M.is_directory(user_profile_path) then
                --Get pocs folder in OneDrive dir
                local my_documents_onedrive_poc_path = vim.fs.joinpath(
                    user_profile_path,
                    'OneDrive',
                    'documents',
                    'poc'
                )
                my_documents_onedrive_poc_path = vim.fs.abspath(
                    vim.fs.normalize(my_documents_onedrive_poc_path)
                )
                table.insert(poc_search_paths, my_documents_onedrive_poc_path)

                --Get pocs folder in regular documents dir
                local my_documents_poc_path =
                    vim.fs.joinpath(user_profile_path, 'documents', 'poc')
                my_documents_poc_path =
                    vim.fs.abspath(vim.fs.normalize(my_documents_poc_path))
                table.insert(poc_search_paths, my_documents_poc_path)
            end
        end
    else
        vim.notify(
            "TODO: Implement get_projects_paths for other OS's",
            vim.log.levels.WARN
        )
    end

    --Note: MYWORKSPACE is a custom environment variable I will add
    --if I need to store my projects/poc's on a different drive and not in my
    --documents folder
    local workspace_paths =
        M.get_paths_from_environment_variable('$MYWORKSPACE')
    for _, workspace_path in ipairs(workspace_paths) do
        if M.is_directory(workspace_path) then
            local myworkspace_poc_path = vim.fs.joinpath(workspace_path, 'poc')
            myworkspace_poc_path =
                vim.fs.abspath(vim.fs.normalize(myworkspace_poc_path))
            table.insert(poc_search_paths, myworkspace_poc_path)
        end
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

    -- Add the poc parent directories to the searchable list (to make creating new poc's easier)
    vim.list_extend(poc_paths, poc_search_paths)

    return poc_paths
end

---Gets the csharp-ls language server's filepath
---@return string path
function M.get_lsp_csharpls_path()
    local csharp_ls_exe = vim.fs.joinpath(
        M.get_mason_base_path(),
        'packages',
        'csharp-language-server',
        'csharp-ls.exe'
    )
    return csharp_ls_exe
end

---Gets the powershell language server's filepath
---@return string path
function M.get_lsp_powershell_editor_services_bundle_path()
    local bundle_path = vim.fs.joinpath(
        M.get_mason_base_path(),
        'packages',
        'powershell-editor-services'
    )
    return bundle_path
end

---Gets the apex language server's filepath
---@return string path
function M.get_lsp_apex_jar_path()
    local apex_jar_path = vim.fs.joinpath(
        M.get_mason_base_path(),
        'share',
        'apex-language-server',
        'apex-jorje-lsp.jar'
    )
    return apex_jar_path
end

--- I was having problems with using the cmd file mason creates when installing netcoredbg on windows
--- where using the cmd file for debugging wouldn't work. Instead I had to use the exe file directly
---@return string
function M.get_mason_tool_netcoredbg_path()
    if vim.fn.has('win32') == 1 then
        return vim.fs.joinpath(
            M.get_mason_base_path(),
            'packages',
            'netcoredbg',
            'netcoredbg',
            'netcoredbg.exe'
        )
    else
        return M.get_mason_tool_path('netcoredbg')
    end
end

---@return string
function M.get_jupytext_venv_dir()
    local config_path =
        M.get_single_path_from_environment_variable('$XDG_CONFIG_HOME')
    local jupytext_venv_directory =
        vim.fs.joinpath(config_path, 'cli-tools', 'jupytext_venv', 'venv')
    return jupytext_venv_directory
end

---Finds the jupytext executable in the python virtual environment
---@param venv_dir string
---@return string? jupytext_executable_path
function M.find_jupytext_executable(venv_dir)
    local candidates = {
        vim.fn.has('unix') == 1
            and vim.fs.joinpath(venv_dir, 'bin', 'jupytext'),
        -- MSYS2
        vim.fn.has('win32') == 1
            and vim.fs.joinpath(venv_dir, 'bin', 'jupytext.exe'),
        -- Stock Windows
        vim.fn.has('win32') == 1
            and vim.fs.joinpath(venv_dir, 'Scripts', 'jupytext.exe'),
    }

    for _, candidate in ipairs(candidates) do
        if
            candidate
            and vim.fn.executable(vim.fs.normalize(candidate)) == 1
        then
            return candidate
        end
    end
    return nil
end

---@param report_id string report uuid
---@return string path
function M.get_hurl_report_path(report_id)
    local data_path = M.get_nvim_data_dir()
    local path = vim.fs.joinpath(data_path, 'hurl-report', report_id)
    return path
end

---The file path of my global notes file
---@return string path
function M.get_global_note_path()
    local data_dir = M.get_nvim_data_dir()
    local directory = vim.fs.joinpath(data_dir, 'global-note')
    local filepath = vim.fs.joinpath(directory, 'global.md')
    M.ensure_directory_exists(directory)
    M.ensure_file_exists(filepath)
    return filepath
end

return M
