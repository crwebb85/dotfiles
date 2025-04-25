local platform = require('utils.platform')

local M = {}

local function get_plugin_dir()
    local str = debug.getinfo(2, 'S').source:sub(2)
    return vim.fn.fnamemodify(str, ':h')
end

local __dirname = get_plugin_dir()

local EDITOR_CLI_DIR = vim.fs.joinpath(__dirname, 'EditorToolsCLI')

local EDITOR_CLI_FILE_PATH =
    vim.fs.joinpath(__dirname, 'EditorToolsCLI', 'src', '__main__.py')

local VENV_DIR = vim.fs.joinpath(__dirname, 'EditorToolsCLI', 'venv')

---@param executable string
local function find_venv_executable(executable)
    local candidates = {
        vim.fn.has('unix') == 1
            and vim.fs.joinpath(VENV_DIR, 'bin', executable),
        -- MSYS2
        vim.fn.has('win32') == 1
            and vim.fs.joinpath(VENV_DIR, 'bin', ('%s.exe'):format(executable)),
        -- Stock Windows
        vim.fn.has('win32') == 1
            and vim.fs.joinpath(
                VENV_DIR,
                'Scripts',
                ('%s.exe'):format(executable)
            ),
    }

    for _, candidate in ipairs(candidates) do
        if
            candidate ~= nil and vim.fn.executable(vim.fs.normalize(candidate))
        then
            return candidate
        end
    end
    return nil
end

---@return string[]
local function get_python_executables_priority_sorted()
    ---@type string[]
    local executables = {}

    local host_executable = vim.g.python3_host_prog
        and vim.fn.expand(vim.g.python3_host_prog)

    if host_executable ~= nil then
        table.insert(executables, host_executable)
    end

    if vim.fn.has('win32') == 1 then
        table.insert(executables, 'python')
        table.insert(executables, 'python3')
    else
        table.insert(executables, 'python3')
        table.insert(executables, 'python')
    end
    return executables
end

local function create_venv()
    local on_exit = function(obj)
        vim.print('code:', obj.code)
        vim.print('signal:', obj.signal)
        vim.print('stdout:', obj.stdout)
        vim.print('stderr:', obj.stderr)
        if obj.stder ~= nil then
            vim.print('Failed to create virtual environment\n')
        end
        vim.print('Finished Creating virtual environment\n')

        vim.print('Setting up virtual environment…\n')

        local python_venv_executable_path = find_venv_executable('python')
        vim.system(
            { python_venv_executable_path, '-m', 'venv', VENV_DIR },
            {},
            function(setup_venv_response)
                vim.print('code:', setup_venv_response.code)
                vim.print('signal:', setup_venv_response.signal)
                vim.print('stdout:', setup_venv_response.stdout)
                vim.print('stderr:', setup_venv_response.stderr)
                vim.print('Finished setting up virtual environment\n')
            end
        )
    end
    local py_executables = get_python_executables_priority_sorted()
    for _, py_executable in ipairs(py_executables) do
        -- the following pcall will return false if the base command doesn't exist
        -- so we can try the next command
        if
            pcall(
                function()
                    vim.system(
                        { py_executable, '-m', 'venv', VENV_DIR },
                        {},
                        on_exit
                    )
                end
            )
        then
            return -- if py_executable exists we can stop trying different commands
        end
    end
end

function M.init_venv()
    vim.print('VENV_DIR:' .. VENV_DIR)
    vim.print('EDITOR_CLI_DIR:' .. EDITOR_CLI_DIR)
    vim.print('Creating virtual environment…\n')
    create_venv()
end

function M.hello_world()
    local python_executable_path = find_venv_executable('python')

    vim.print(python_executable_path)
    local output = vim.fn.system({
        python_executable_path,
        EDITOR_CLI_FILE_PATH,
        'hello',
    })
    if output then print(output) end
end

function M.sort_json_file()
    local python_executable_path = find_venv_executable('python')

    local file_path = vim.fn.expand('%p')
    if file_path == nil then
        error('Buffer needs to be a file on system')
    elseif type(file_path) == 'table' then
        error("Multiple files returned by expand (this shouldn't happen)")
    end
    vim.print(python_executable_path)
    local output = vim.fn.system({
        python_executable_path,
        EDITOR_CLI_FILE_PATH,
        'sortjsonfile',
        file_path,
    })
    if output then print(output) end

    -- reload current file
    vim.cmd([[:e]])
end

M.setup = function()
    vim.api.nvim_create_user_command('EditorToolsInit', M.init_venv, {})
    vim.api.nvim_create_user_command('Hello', M.hello_world, {})
    vim.api.nvim_create_user_command('SortJsonFile', M.sort_json_file, {})
end

return M
