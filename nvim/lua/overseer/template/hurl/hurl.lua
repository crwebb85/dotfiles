local function getUUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    math.randomseed(os.time())
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

M = {}

function M.hurl_builder_builder(opts)
    if opts == nil then opts = {} end
    local builder = function()
        -- Full path to current file (see :help expand())
        local file = vim.fn.expand('%:p')
        local report_id = getUUID()

        local data_path = vim.fn.stdpath('data')
        if type(data_path) ~= 'string' then
            error('data path is not a string')
        end

        local report_path = vim.fs.joinpath(data_path, 'hurl-report', report_id)

        local args = {
            file,
            '--no-output',
            '--report-json',
            report_path,
        }

        if
            opts.get_var_file_callback ~= nil
            and type(opts.get_var_file_callback) == 'function'
        then
            local var_file = opts.get_var_file_callback()
            var_file = vim.fs.normalize(var_file)
            if type(var_file) ~= 'string' then error('path is not a string') end
            table.insert(args, '--variables-file')
            table.insert(args, var_file)
        end

        return {
            cmd = { 'hurl' },
            args = args,
            components = {
                {
                    'on_output_quickfix',
                    open = true,
                    errorformat = [[%E%trror:\ %m,%Z\ \ -->\ %f:%l:%c]],
                    --Example error
                    --
                    -- error: Parsing method
                    --   --> C:\Users\crweb\Documents\poc\flask-api\test.hurl:12:1
                    --    |
                    -- 12 | sonpath "$[0].type" == "apple"
                    --    | ^ the HTTP method <sonpath> is not valid. Valid values are GET, HEAD, POST, PUT, DELETE, CONNECT, OPTIONS, TRACE, PATCH
                    --    |
                },
                {
                    'quickfix.trim_quickfix',
                    items_to_append = {
                        '',
                    },
                },
                {
                    'hurl.open_hurl_results',
                    report_id = report_id,
                    append = true,
                    cleanup = true,
                },
                'default',
            },
        }
    end
    return builder
end

return M
