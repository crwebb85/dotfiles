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

return M
