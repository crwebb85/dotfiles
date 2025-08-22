return {
    desc = 'Opens the hurl results',
    -- Define parameters that can be passed in to the component
    params = {
        report_id = {
            desc = 'The id of the report used to determine path of report and cleanup',
            type = 'string',
            optional = false,
            default = false,
        },
        append = {
            desc = 'When true, append the results to the quickfix list',
            type = 'boolean',
            optional = true,
            default = false,
        },
        cleanup = {
            desc = 'When true, delete the report when this component is restarted or disposed',
            type = 'boolean',
            optional = false,
            default = false,
        },
    },
    -- Optional, default true. Set to false to disallow editing this component in the task editor
    editable = true,
    -- Optional, default true. When false, don't serialize this component when saving a task to disk
    serializable = true,
    -- The params passed in will match the params defined above
    constructor = function(params)
        -- You may optionally define any of the methods below
        return {

            on_init = function(self, _task)
                -- Called when the task is created
                -- This is a good place to initialize resources, if needed

                local data_path = vim.fn.stdpath('data')
                if type(data_path) ~= 'string' then
                    error('data path is not a string')
                end

                self.report_path =
                    vim.fs.joinpath(data_path, 'hurl-report', params.report_id)
                self.report_json_path =
                    vim.fs.joinpath(self.report_path, 'report.json')
            end,

            on_reset = function(self, _task)
                -- Called when the task is reset to run again
                if params.cleanup then vim.fn.delete(self.report_path, 'rf') end
            end,

            on_dispose = function(self, _task)
                -- Called when the task is disposed
                -- Will be called IFF on_init was called, and will be called exactly once.
                -- This is a good place to free resources (e.g. timers, files, etc)

                if params.cleanup then
                    vim.fn.delete(self.report_path, 'rf')
                    vim.fn.delete(self.report_path, 'd')
                end
            end,
            on_complete = function(self, _task, _status, _result)
                local report_json_file =
                    assert(io.open(self.report_json_path, 'r'))
                local report_json = report_json_file:read('*all')
                report_json_file:close()

                ---@type table[]
                local report = vim.json.decode(report_json)

                local items = {}
                local function add_text_item(text)
                    table.insert(items, {
                        text = text,
                        valid = 0,
                    })
                end

                for _, file_report in ipairs(report) do
                    --TODO fields cookies

                    add_text_item(
                        '==============================================================================='
                    )
                    table.insert(items, {
                        filename = file_report.filename,
                        valid = true,
                    })
                    add_text_item(
                        'Success: ' .. vim.inspect(file_report.success)
                    )
                    add_text_item('Time: ' .. file_report.time)
                    add_text_item(
                        '==============================================================================='
                    )

                    local entries = file_report.entries
                    if not vim.isarray(entries) then entries = {} end
                    for entry_index, entry in ipairs(entries) do
                        ---TODO deal with asserts

                        local calls = entry.calls
                        if not vim.isarray(calls) then calls = {} end
                        for _, call in ipairs(calls) do
                            add_text_item('')
                            ---Request
                            local request = call.request
                            add_text_item(request.method .. ' ' .. request.url)
                            add_text_item(
                                'query_string:'
                                    .. vim.inspect(request.query_string)
                            )

                            local request_headers = request.headers
                            if not vim.isarray(request_headers) then
                                request_headers = {}
                            end
                            for _, header in pairs(request_headers) do
                                add_text_item(
                                    header.name .. ':  ' .. header.value
                                )
                            end

                            add_text_item('')

                            ---Response
                            local response = call.response
                            add_text_item('status: ' .. response.status)

                            local response_headers = response.headers
                            if not vim.isarray(response_headers) then
                                response_headers = {}
                            end
                            for _, header in pairs(response_headers) do
                                add_text_item(
                                    header.name .. ':  ' .. header.value
                                )
                            end

                            table.insert(items, {
                                filename = vim.fs.joinpath(
                                    self.report_path,
                                    response.body
                                ),
                                valid = true,
                            })

                            add_text_item('')
                            if entry_index < #entries then
                                add_text_item(
                                    '-------------------------------------------------------------------------------'
                                )
                            end
                        end
                    end
                end

                table.insert(items, {
                    filename = self.report_json_path,
                    valid = true,
                })

                local action = ' '
                if params.append then action = 'a' end

                vim.fn.setqflist(
                    {},
                    action,
                    { items = items, title = 'Hurl Report' }
                )
            end,
            -- ---@param lines string[] The list of lines to render into
            -- ---@param highlights table[] List of highlights to apply after rendering
            -- ---@param detail number The detail level of the task. Ranges from 1 to 3.
            -- render = function(self, task, lines, highlights, detail)
            --     --TODO add summary
            --
            --     -- -- Called from the task list. This can be used to display information there.
            --     -- table.insert(lines, 'Here is a line of output')
            --     -- -- The format is {highlight_group, lnum, col_start, col_end}
            --     -- table.insert(highlights, { 'Title', #lines, 0, -1 })
            -- end,
        }
    end,
}
