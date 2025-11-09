---based on https://github.com/nvim-neotest/neotest/blob/2cf3544fb55cdd428a9a1b7154aea9c9823426e8/lua/neotest/consumers/quickfix.lua?plain=1#L1
--- - uses an overseer parser to parse the results
--- - includes files from error message stacktrace as items in QF list below test item
--- - displays the full message below each failed test in QF list
--- - seperates the tests with dashes so the QF list is easier to read

-- TODO: I want a QFWatchNeotest and LocWatchNeotest commands that will keep the keep the quickfix/location list
-- populated with the neotest output. Running the command with bang will disable the watching.
-- TODO: I want a QFNeotest and LocNeotest commands that will populate the quickfix/location lists with the neotest output

local nio = require('nio')
local config = require('neotest.config')

local neotest = {}

---@toc_entry Quickfix Consumer
---@text
--- A consumer that sends results to the quickfix list.
neotest.quickfix = {}

---@private
---@type neotest.Client
local client

---@class MyNeotestQuickfixConfig
---@field open? boolean|function Set to true to open quickfix on neotest results, or a callback to call
---@field parser? table An overseer parser https://github.com/stevearc/overseer.nvim/blob/master/doc/reference.md#parsers
---@field problem_matcher? table An overseer problem matcher
---@field precalculated_vars? table

local init = function()
    ---@param results table<string, neotest.Result>
    client.listeners.results = function(adapter_id, results, partial)
        ---@diagnostic disable-next-line: undefined-field
        local consumer_config = config.custom_consumer_config

        ---@type MyNeotestQuickfixConfig
        local my_neotest_quickfix_config = consumer_config
                and consumer_config.myquickfix
            or {}

        if partial then return end

        local resolved_parser =
            require('myconfig.quickfix.api').resolve_overseer_parser({
                parser = my_neotest_quickfix_config.parser,
                problem_matcher = my_neotest_quickfix_config.problem_matcher,
                precalculated_vars = my_neotest_quickfix_config.precalculated_vars,
            })

        local tree = assert(client:get_position(nil, { adapter = adapter_id }))

        local qf_results = {}
        local buffer_cache = {}

        local failed_test_qf_results = {}

        for pos_id, result in pairs(results) do
            if result.status == 'failed' and tree:get_key(pos_id) then
                local node = assert(tree:get_key(pos_id))
                local pos = node:data()
                if pos.type == 'test' then
                    local bufnr = buffer_cache[pos.path]
                    if not bufnr then
                        ---@diagnostic disable-next-line: param-type-mismatch
                        bufnr = nio.fn.bufnr(pos.path)
                        buffer_cache[pos.path] = bufnr
                    end

                    local range = node:closest_value_for('range')
                    for _, error in ipairs(result.errors or {}) do
                        failed_test_qf_results[#failed_test_qf_results + 1] = {
                            bufnr = bufnr > 0 and bufnr or nil,
                            filename = bufnr <= 0 and pos.path or nil,
                            lnum = (error.line or range[1]) + 1,
                            col = range[2] + 1,
                            text = error.message,
                            type = result.status == 'failed' and 'E' or 'W',
                            user_data = {
                                pos_id = pos_id,
                                test_result = error,
                            },
                        }
                    end
                end
            end
        end

        --Sort the test by file, lnum, and col
        table.sort(failed_test_qf_results, function(a, b)
            if a.filename == b.filename then
                if a.lnum == b.lnum then return a.col < b.col end
                return a.lnum < b.lnum
            end
            if not a.filename then return true end
            if not b.filename then return false end

            return a.filename < b.filename
        end)

        for _, failed_test_qf_result in ipairs(failed_test_qf_results) do
            table.insert(qf_results, failed_test_qf_result)

            local message_lines = failed_test_qf_result.user_data.test_result.message
                or ''

            local append_stacktrace = resolved_parser ~= nil
            local items, sanitized_lines =
                require('myconfig.quickfix.api').parse_list_entries({
                    lines = message_lines,
                    parser = resolved_parser,
                })
            for _, item in ipairs(items) do
                table.insert(qf_results, item)
            end
            if append_stacktrace then
                for _, line in ipairs(sanitized_lines) do
                    table.insert(qf_results, { text = line, valid = 0 })
                end
            end
            table.insert(qf_results, { text = '-------', valid = 0 })
        end

        if #qf_results > 0 then
            nio.fn.setqflist(
                {},
                'u',
                { title = 'Neotest Results', items = qf_results }
            )
            vim.cmd.doautocmd('QuickFixCmdPost')
            if my_neotest_quickfix_config.open then
                if type(my_neotest_quickfix_config.open) == 'function' then
                    my_neotest_quickfix_config.open()
                else
                    nio.api.nvim_command('copen')
                end
            end
        end
    end
end

neotest.quickfix = setmetatable(neotest.quickfix, {
    __call = function(_, client_)
        client = client_
        init()
        return neotest.quickfix
    end,
})

return neotest.quickfix
