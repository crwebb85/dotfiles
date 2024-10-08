local function getUUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    math.randomseed(os.time())
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

---@type overseer.TemplateFileDefinition
local hurl_template = {
    name = 'Run Hurl',
    builder = function()
        -- Full path to current file (see :help expand())
        local file = vim.fn.expand('%:p')
        local report_id = getUUID()

        local data_path = vim.fn.stdpath('data')
        if type(data_path) ~= 'string' then
            error('data path is not a string')
        end

        local report_path = vim.fs.joinpath(data_path, 'hurl-report', report_id)

        return {
            cmd = { 'hurl' },
            args = {
                file,
                '--no-output',
                '--report-json',
                report_path,
            },
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
    end,

    condition = {
        filetype = { 'hurl' },
    },
}

return hurl_template
