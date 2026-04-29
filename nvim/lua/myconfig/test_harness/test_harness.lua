---based on https://github.com/nvim-lua/plenary.nvim/blob/74b06c6c75e4eeb3108ec01852001636d85a932b/lua/plenary/test_harness.lua
--- changes primarily involved fixing lsp warnings and depreciations
--- also did not include planery's old logger as I intend to use the vim.log.new
--- when it is added to nightly
local Job = require('myconfig.test_harness.job')

local log = vim.log.new({
    name = 'myconfig.test_harness',
})

local test_panel = require('myconfig.test_harness.test_panel')

---checks if the nvim instance is running headless
---@return boolean
local function is_headless() return #vim.api.nvim_list_uis() == 0 end

local test_harness_dir =
    vim.fn.fnamemodify(debug.getinfo(1).source:match('@?(.*[/\\])'), ':p:h:h:h')

local harness = {}

local print_output = vim.schedule_wrap(function(_, ...)
    for _, v in ipairs({ ... }) do
        io.stdout:write(tostring(v))
        io.stdout:write('\n')
    end

    vim.cmd([[mode]])
end)

local get_nvim_output = function(job_id)
    return vim.schedule_wrap(function(bufnr, ...)
        if not vim.api.nvim_buf_is_valid(bufnr) then return end
        for _, v in ipairs({ ... }) do
            vim.api.nvim_chan_send(job_id, v .. '\r\n')
        end
    end)
end

---Run the tests for the paths
---@param paths string[]
---@param opts any
local function test_paths(paths, opts)
    local minimal = not opts
        or not opts.init
        or opts.minimal
        or opts.minimal_init

    opts = vim.tbl_deep_extend('force', {
        nvim_cmd = vim.v.progpath,
        winopts = { winblend = 3 },
        sequential = false,
        keep_going = true,
        timeout = 50000,
    }, opts or {})

    vim.env.BUSTED_TEST_TIMEOUT = opts.timeout

    local res = {}
    if not is_headless() then
        res = test_panel.percentage_range_window(0.95, 0.70, opts.winopts)

        res.job_id = vim.api.nvim_open_term(res.bufnr, {})
        vim.api.nvim_buf_set_keymap(res.bufnr, 'n', 'q', ':q<CR>', {})

        vim.wo[res.win_id].winhl = 'Normal:Normal'
        vim.wo[res.win_id].conceallevel = 3
        vim.wo[res.win_id].concealcursor = 'n'

        if res.border_win_id then
            vim.wo[res.border_win_id].winhl = 'Normal:Normal'
        end

        if res.bufnr then vim.bo[res.bufnr].filetype = 'BustedTestPopup' end
        vim.cmd('mode')
    end

    local outputter = is_headless() and print_output
        or get_nvim_output(res.job_id)

    local path_len = #paths
    local failure = false

    local jobs = vim.tbl_map(function(p)
        local normalized_path = vim.fs.abspath(vim.fs.normalize(p))
        local args = {
            '--headless',
            '-c',
            string.format(
                'set rtp+=.,%s',
                vim.fn.escape(test_harness_dir, ' ')
            ),
        }

        if minimal then
            table.insert(args, '--noplugin')
            if opts.minimal_init then
                table.insert(args, '-u')
                table.insert(args, opts.minimal_init)
            end
        elseif opts.init ~= nil then
            table.insert(args, '-u')
            table.insert(args, opts.init)
        end

        table.insert(args, '-c')
        table.insert(
            args,
            string.format(
                'lua require("myconfig.test_harness.busted").run("%s")',
                normalized_path
            )
        )

        local job = Job:new({
            command = opts.nvim_cmd,
            args = args,

            -- Can be turned on to debug
            on_stdout = function(_, data)
                if path_len == 1 then outputter(res.bufnr, data) end
            end,

            on_stderr = function(_, data)
                if path_len == 1 then outputter(res.bufnr, data) end
            end,

            on_exit = vim.schedule_wrap(function(j_self, _, _)
                if path_len ~= 1 then
                    outputter(res.bufnr, unpack(j_self:stderr_result()))
                    outputter(res.bufnr, unpack(j_self:result()))
                end

                vim.cmd('mode')
            end),
        })
        job.nvim_busted_path = normalized_path
        return job
    end, paths)

    log.debug('Running...')
    for i, j in ipairs(jobs) do
        outputter(res.bufnr, 'Scheduling: ' .. j.nvim_busted_path)
        j:start()
        if opts.sequential then
            log.debug('... Sequential wait for job number', i)
            if not Job.join(j, opts.timeout) then
                log.debug('... Timed out job number', i)
                failure = true
                pcall(function()
                    j.handle:kill(15) -- SIGTERM
                end)
            else
                log.debug('... Completed job number', i, j.code, j.signal)
                failure = failure or j.code ~= 0 or j.signal ~= 0
            end
            if failure and not opts.keep_going then break end
        end
    end

    -- TODO: Probably want to let people know when we've completed everything.
    if not is_headless() then return end

    if not opts.sequential then
        table.insert(jobs, opts.timeout)
        log.debug('... Parallel wait')
        Job.join(unpack(jobs))
        log.debug('... Completed jobs')
        table.remove(jobs, #jobs)
        failure = false
        for _, job in pairs(jobs) do
            if job.code ~= 0 then
                failure = true
                break
            end
        end
    end
    vim.wait(100)

    if is_headless() then
        if failure then return vim.cmd('1cq') end
        vim.cmd('0cq')
        return
    end
end

---Find the test files in the test directory
---@param directory string the directory to search for the test files
---@return string[]
local function find_files_to_run(directory)
    local normalized_dir = vim.fs.abspath(vim.fs.normalize(directory))
    local finder
    if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
        -- On windows use powershell Get-ChildItem instead
        local cmd = vim.fn.executable('pwsh.exe') == 1 and 'pwsh'
            or 'powershell'
        finder = Job:new({
            command = cmd,
            args = {
                '-NoProfile',
                '-Command',
                [[Get-ChildItem -Recurse -n -Filter "*_spec.lua"]],
            },
            cwd = normalized_dir,
        })
    else
        -- everywhere else use find
        finder = Job:new({
            command = 'find',
            args = { normalized_dir, '-type', 'f', '-name', '*_spec.lua' },
        })
    end

    ---@type string[]
    local paths = {}
    for _, path in ipairs(finder:sync(vim.env.BUSTED_TEST_TIMEOUT) or {}) do
        local normalized_path =
            vim.fs.normalize(vim.fs.joinpath(normalized_dir, path))
        table.insert(paths, normalized_path)
    end
    return paths
end

---Run the tests in the test directory
---@param directory string the directory to search for tests to run
---@param opts any
function harness.test_directory(directory, opts)
    local paths = find_files_to_run(directory)

    test_paths(paths, opts)
end

---Run the test file
---@param filepath string path to the test file
function harness.test_file(filepath)
    test_paths({ vim.fs.abspath(vim.fs.normalize(filepath)) })
end

return harness
