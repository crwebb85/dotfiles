return {
    desc = 'Runs the debugger (intended to be used with rust-analyzer code lens)',
    -- Define parameters that can be passed in to the component
    params = {
        exec_args = {
            desc = 'The debugger arguments',
            type = 'list',
            subtype = {
                type = 'string',
            },
            optional = false,
            default = false,
        },
        cwd = {
            desc = 'Current directory',
            type = 'string',
            optional = false,
            default = false,
        },
        rust_debug_adapter = {
            desc = 'The name of the rust debug adapter',
            type = 'string',
            optional = true,
            default = 'codelldb',
        },
    },
    -- Optional, default true. Set to false to disallow editing this component in the task editor
    editable = true,
    -- Optional, default true. When false, don't serialize this component when saving a task to disk
    serializable = true,
    -- The params passed in will match the params defined above
    constructor = function(params)
        ---@type string?
        local executable

        return {

            on_init = function(self, _task) require('dap').close() end,

            on_reset = function(self, _task) require('dap').close() end,

            on_dispose = function(self, _task) end,
            on_output_lines = function(self, task, lines)
                for _, value in pairs(lines) do
                    local ok, json = pcall(vim.fn.json_decode, value)
                    if
                        ok
                        and type(json) == 'table'
                        and json.executable ~= vim.NIL
                        and json.executable ~= nil
                    then
                        executable = json.executable
                        break
                    end
                end
            end,
            on_complete = function(self, _task, status, _result)
                vim.print(status)
                vim.print(executable)

                if status == 'SUCCESS' and executable ~= nil then
                    require('dap').run({
                        name = 'Rust debug',
                        type = params.rust_debug_adapter,
                        request = 'launch',
                        program = executable,
                        sourceLanguages = { 'rust' },
                        args = params.exec_args,
                        cwd = params.cwd,
                        stopOnEntry = false,
                    })
                end
            end,
        }
    end,
}
