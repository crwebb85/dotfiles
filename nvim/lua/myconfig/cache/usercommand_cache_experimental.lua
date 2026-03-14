local M = {}

local user_command_cache = require('myconfig.cache.cache').create_ttl_cache()

---Finds the makefiles in the cwd
---@param cwd any
---@return string[]
local function find_makefiles(cwd)
    if cwd == nil then cwd = vim.fn.getcwd() end

    local cmd = {
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
        '*.makefile',
        '--glob',
        'Makefile',
        '--glob',
        'Makefile',
        '--glob',
        '*.Makefile',
    }

    local proc = vim.system(cmd, { cwd = cwd, text = true }):wait()
    if proc.code == 0 then
        local text = proc.stdout:gsub('\n$', '') -- strip trailing newline
        return vim.split(text, '\n')
    else
        vim.notify(proc.stderr, vim.log.levels.ERROR)
        return {}
    end
end

---Either finds the makefiles in the cwd or returns that cached list
---@param cwd string? the current directory to search (default: actual cwd)
---@return string[]
function M.get_makefiles(cwd)
    if cwd == nil then cwd = vim.fn.getcwd() end
    local key = string.format('makefiles_in_path:%s', cwd)
    return user_command_cache:get_or_create(
        key,
        function() return find_makefiles(cwd) end,
        {
            sliding_expiration_timespan = 60,
            absolute_expiration_timespan = 300, --5 min * 60s/min = 300s
        }
    )
end

local function list_commands_from_makefile(makefile_path)
    ---@type string[]
    local commands = {}

    -- Open the Makefile for reading
    local file, err = io.open(makefile_path, 'r')

    if file == nil then error(err) end
    local in_target = false

    -- Iterate through each line in the Makefile
    for line in file:lines() do
        -- Check for lines starting with a target rule (e.g., "target: dependencies")
        local target = line:match('^(.-):')
        if target then
            in_target = true
            table.insert(commands, target)
        elseif in_target then
            -- If we're inside a target block, stop adding commands
            in_target = false
        end
    end

    -- Close the Makefile
    file:close()

    return commands
end

---@class MyProjectMakefilesInfo
---@field commands_by_makefile_path table<string, string[]>
---@field makefile_paths_by_command table<string, string[]>
---@field all_commands string[]
---@field all_makefile_paths string[]

---Determines the makefile info for the cwd
---@param cwd string? the current directory
---@return MyProjectMakefilesInfo
local function determine_project_makefiles_info(cwd)
    -- vim.print('hi')
    if cwd == nil then cwd = vim.fn.getcwd() end

    local Set = require('myconfig.utils.datastructure').Set

    local commands_by_makefile_path = {}
    local makefile_paths = M.get_makefiles(cwd)
    -- vim.print(makefile_paths)
    local makefile_paths_by_command = {}
    for _, makefile_path in ipairs(makefile_paths) do
        local status, commands_or_err =
            pcall(list_commands_from_makefile, makefile_path)

        if status then
            local commands = Set:new(commands_or_err):to_array()
            commands_by_makefile_path[makefile_path] = commands
            for _, command in ipairs(commands) do
                if makefile_paths_by_command[command] == nil then
                    makefile_paths_by_command[command] = {}
                end
                table.insert(makefile_paths_by_command[command], makefile_path)
            end
        elseif type(commands_or_err) == 'string' then
            ---@type string
            local err = commands_or_err
            vim.notify(err, vim.log.levels.ERROR, {
                title = 'Make',
            })
        end
    end
    local all_commands = {}
    for command, _ in pairs(makefile_paths_by_command) do
        table.insert(all_commands, command)
    end
    local all_makefile_paths = {}
    for make_file_path, _ in pairs(commands_by_makefile_path) do
        table.insert(all_makefile_paths, make_file_path)
    end

    ---@type MyProjectMakefilesInfo
    return {
        commands_by_makefile_path = commands_by_makefile_path,
        makefile_paths_by_command = makefile_paths_by_command,
        all_commands = all_commands,
        all_makefile_paths = all_makefile_paths,
    }
end

---Determines the makefile info for the cwd or fetches it from the cache
---@param cwd string? the current directory
---@return MyProjectMakefilesInfo
function M.get_project_makefiles_info(cwd)
    if cwd == nil then cwd = vim.fn.getcwd() end
    local key = string.format('makefile_options:%s', cwd)
    ---@type MyProjectMakefilesInfo
    return user_command_cache:get_or_create(
        key,
        function() return determine_project_makefiles_info(cwd) end,
        {
            sliding_expiration_timespan = 60,
            absolute_expiration_timespan = 300, --5 min * 60s/min = 300s
        }
    )
end

---@param CmdLine string
---@param CursorPos number
---@return vim.api.keyset.cmd cmd
---@return integer cmd_start_pos
---@return integer cmd_end_pos
local function get_parsed_command_at_cursor(CmdLine, CursorPos)
    -- we can use cmd.nextcmd to find out if the end pos of the command by
    -- doing cmd_line_length - #cmd.nextcmd
    -- TODO figure out if I have any off by one errors
    local cmd_line_length = #CmdLine
    local cmd_start_pos = 0
    local parsed_cmd = vim.api.nvim_parse_cmd(CmdLine, {})
    local cmd_end_pos = cmd_line_length - #parsed_cmd.nextcmd
    while CursorPos < cmd_start_pos or CursorPos > cmd_end_pos do
        cmd_start_pos = cmd_end_pos
        parsed_cmd = vim.api.nvim_parse_cmd(parsed_cmd.nextcmd, {})
        cmd_end_pos = cmd_line_length - #parsed_cmd.nextcmd
    end
    return parsed_cmd, cmd_start_pos, cmd_end_pos
end

---@class MyUserCmdParsed
---@field cursor_cmd vim.api.keyset.cmd the parsed command at the cursor (used when chaining commands with pipe and the cursor is not at the first command)
---@field cursor_cmd_start_pos integer
---@field cursor_cmd_end_pos integer
---@field cursor_arg_index integer?
---@field cursor_prev_arg_index integer?
---@field cursor_next_arg_index integer?
---@field cursor_arg string?
---@field cursor_prev_arg string?
---@field cursor_next_arg string?

---@param CmdLine string
---@param CursorPos number
---@return MyUserCmdParsed
local function parse_command(CmdLine, CursorPos)
    local cursor_cmd, cursor_cmd_start_pos, cursor_cmd_end_pos =
        get_parsed_command_at_cursor(CmdLine, CursorPos)
    local _, cmd_name_end_pos = string.find(
        CmdLine,
        vim.fn.fnameescape(cursor_cmd.cmd),
        cursor_cmd_start_pos
    )
    if cmd_name_end_pos == nil then
        vim.notify(
            'wth how could I not find the cmd_name_end_pos. Will fall back to length of the cmd string plus cursor_cmd_start_pos',
            vim.log.levels.WARN
        )
        cmd_name_end_pos = cursor_cmd_start_pos + #cursor_cmd.cmd
    end

    local arg_search_pos = cmd_name_end_pos
    local current_arg_index = nil

    local args = cursor_cmd.args or {}
    local cursor_prev_arg
    local cursor_prev_arg_index
    local cursor_next_arg
    local cursor_next_arg_index
    for i, arg in ipairs(args) do
        -- if current_arg_index == nil then
        local next_arg_start_pos, next_arg_end_pos =
            string.find(CmdLine, vim.fn.fnameescape(arg), arg_search_pos)
        if next_arg_end_pos > CursorPos then
            -- we the cursor is in between two arguments rather than on on
            if i - 1 > 0 then
                cursor_prev_arg_index = i - 1
                cursor_prev_arg = args[i - 1]
            end

            cursor_next_arg_index = i
            cursor_next_arg = arg
            break
        elseif
            CursorPos >= next_arg_start_pos
            and CursorPos <= next_arg_end_pos
        then
            --i is the index of the current arg
            -- vim.print(string.format('found_arg at %s: `%s`', i, arg))
            current_arg_index = i

            if i - 1 > 0 then
                cursor_prev_arg_index = i - 1
                cursor_prev_arg = args[i - 1]
            end

            if i + 1 < #args then
                cursor_next_arg_index = i + 1
                cursor_next_arg = args[cursor_next_arg_index]
            end
        end
        if next_arg_end_pos ~= nil then
            arg_search_pos = next_arg_end_pos
        else
            --Fallback to the length of the arg plus arg_search_pos
            arg_search_pos = arg_search_pos + #arg
        end
        -- elseif cursor_next_arg == nil then
        --     cursor_next_arg = arg
        --     cursor_next_arg_index = i
        --     break
        -- end
    end

    return {
        cursor_cmd = cursor_cmd,
        cursor_cmd_start_pos = cursor_cmd_start_pos,
        cursor_cmd_end_pos = cursor_cmd_end_pos,
        cursor_prev_arg_index = cursor_prev_arg_index,
        cursor_arg_index = current_arg_index,
        cursor_next_arg_index = cursor_next_arg_index,
        cursor_prev_arg = cursor_prev_arg,
        cursor_arg = current_arg_index ~= nil and args[current_arg_index]
            or nil,
        cursor_next_arg = cursor_next_arg,
    }
end

---This is an experimental version of the Make command completion items
---but I haven't finished ironing out the logic because I wanted it to be
---aware of which arguments are already added to determine what items should be
---in the completion menu
---@param ArgLead string
---@param CmdLine string
---@param CursorPos number
---@return string[] completiontion_items
function M.complete_make_command_experimental(ArgLead, CmdLine, CursorPos)
    local my_parsed_cmd = parse_command(CmdLine, CursorPos)
    vim.print(my_parsed_cmd)
    local info = M.get_project_makefiles_info(vim.fn.getcwd())
    -- vim.print(info)

    local Set = require('myconfig.utils.datastructure').Set
    local complete_set = Set:new({})
    -- commands_by_makefile_path table<string, string[]>
    -- makefile_paths_by_command table<string, string[]>
    local args = my_parsed_cmd.cursor_cmd.args ~= nil
            and my_parsed_cmd.cursor_cmd.args
        or {}
    local index_of_dash_f_arg = nil
    local args_that_may_be_make_commands = Set:new({})
    for i, arg in ipairs(args) do
        if info.makefile_paths_by_command[arg] ~= nil then -- TODO may need to normalize
            args_that_may_be_make_commands:insert(arg)
        end
        if arg == '-f' then index_of_dash_f_arg = i end
    end

    if
        my_parsed_cmd.cursor_arg_index ~= nil
        and my_parsed_cmd.cursor_cmd.args[my_parsed_cmd.cursor_arg_index - 1]
            == '-f'
    then
        if args_that_may_be_make_commands.size == 0 then
            --then add all paths
            for _, path in ipairs(info.all_makefile_paths) do
                complete_set:insert(vim.fn.fnameescape(path))
            end
        else
            args_that_may_be_make_commands:each(function(make_command)
                local potential_make_file_paths =
                    info.makefile_paths_by_command[make_command]
                for _, path in ipairs(potential_make_file_paths) do
                    complete_set:insert(vim.fn.fnameescape(path))
                end
            end)
        end
    else
        for _, command in ipairs(info.all_commands) do
            complete_set:insert(command)
        end
    end
    if index_of_dash_f_arg == nil then complete_set:insert('-f') end

    return complete_set:to_array()
end

return M
