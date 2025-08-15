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

function M.fuzzy_pick_process()
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local function make_entry(process_info)
        local text =
            string.format('id=%d name=%s', process_info.pid, process_info.name)
        return {
            value = process_info.pid,
            ordinal = text,
            display = text,
        }
    end

    local processes = require('dap.utils').get_processes({})
    return coroutine.create(function(coro)
        local opts = {}
        pickers
            .new(opts, {
                prompt_title = 'Pick Process',
                finder = finders.new_table({
                    results = processes,
                    entry_maker = make_entry,
                }),
                sorter = conf.generic_sorter(opts),
                attach_mappings = function(buffer_number)
                    actions.select_default:replace(function()
                        actions.close(buffer_number)
                        coroutine.resume(
                            coro,
                            action_state.get_selected_entry().value
                        )
                    end)
                    return true
                end,
            })
            :find()
    end)
end

---This is a telescope replacement for require('dap.utils').pick_process
---@return thread
function M.fuzzy_pick_executable()
    M.shellslash_hack()
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    return coroutine.create(function(coro)
        local opts = {}
        pickers
            .new(opts, {
                prompt_title = 'Path to executable/dll',
                finder = finders.new_oneshot_job({
                    'rg',
                    '--files',
                    '--hidden',
                    '--ignore-vcs', -- So that ripgrep won't ignore gitignore files

                    '--glob',
                    '!node_modules',
                    '--glob',
                    '!venv',
                    '--glob',
                    '!.venv',

                    '--glob',
                    '*.exe',
                    '--glob',
                    '*.dll',
                }, {}),
                sorter = conf.generic_sorter(opts),
                attach_mappings = function(buffer_number)
                    actions.select_default:replace(function()
                        actions.close(buffer_number)
                        coroutine.resume(
                            coro,
                            action_state.get_selected_entry()[1]
                        )
                    end)
                    return true
                end,
            })
            :find()
    end)
end

local dotnet_get_dll_path = function()
    local request = function()
        return vim.fn.input(
            'Path to dll',
            vim.fn.getcwd() .. '/bin/Debug/',
            'file'
        )
    end

    if vim.g['dotnet_last_dll_path'] == nil then
        vim.g['dotnet_last_dll_path'] = request()
    else
        if
            vim.fn.confirm(
                'Do you want to change the path to dll?\n'
                    .. vim.g['dotnet_last_dll_path'],
                '&yes\n&no',
                2
            ) == 1
        then
            vim.g['dotnet_last_dll_path'] = request()
        end
    end

    return vim.g['dotnet_last_dll_path']
end

local dotnet_build_project = function()
    local default_path = vim.fn.getcwd() .. '/'
    if vim.g['dotnet_last_proj_path'] ~= nil then
        default_path = vim.g['dotnet_last_proj_path']
    end
    local path = vim.fn.input('Path to your *proj file', default_path, 'file')
    vim.g['dotnet_last_proj_path'] = path
    local cmd = 'dotnet build -c Debug ' .. path .. ' > /dev/null'
    vim.notify('')
    vim.notify('Cmd to execute: ' .. cmd)
    local f = os.execute(cmd)
    if f == 0 then
        vim.notify('\nBuild: Success ')
    else
        vim.notify('\nBuild: Failure (code: ' .. f .. ')')
    end
end

function M.dotnet_build_and_pick_executable()
    M.shellslash_hack()
    if vim.fn.confirm('Should I recompile first?', '&yes\n&no', 2) == 1 then
        dotnet_build_project()
    end
    return dotnet_get_dll_path()
end

function M.input_executable()
    require('myconfig.dap').shellslash_hack()
    return vim.fn.input('Path to dll', vim.fn.getcwd() .. '/bin/Debug/', 'file')
end

--- I was having problems with using the cmd file mason creates when installing netcoredbg on windows
--- where using the cmd file for debugging wouldn't work. Instead I had to use the exe file directly
---@return string
function M.get_mason_tool_netcoredbg_path()
    local data_path = vim.fn.stdpath('data')
    if data_path == nil then
        error('data path was nil but a string was expected')
    elseif type(data_path) == 'table' then
        error('data path was an array but a string was expected')
    end

    if vim.fn.has('win32') == 1 then
        return vim.fs.joinpath(
            data_path,
            'mason',
            'packages',
            'netcoredbg',
            'netcoredbg',
            'netcoredbg.exe'
        )
    else
        return require('utils.path').get_mason_tool_path('netcoredbg')
    end
end

return M
