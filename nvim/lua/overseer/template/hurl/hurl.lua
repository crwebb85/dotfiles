local function getUUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    math.randomseed(os.time())
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

M = {}

---@class HurlBuilderOptions
---@field hurl_path string | fun(): string
---@field env_path? string | fun(): string?

---@class ResolvedHurlBuilderOptions
---@field hurl_path string
---@field env_path string?

---Resolves the  hurl options
---@param opts HurlBuilderOptions
---@return ResolvedHurlBuilderOptions
local function resolve_hurl_options(opts)
    ---resolve hurl_path
    local hurl_path = ''
    local unresolved_hurl_path = opts.hurl_path
    if unresolved_hurl_path == nil then
        error('Hurl path is required')
    elseif type(unresolved_hurl_path) == 'string' then
        hurl_path = unresolved_hurl_path
    elseif type(unresolved_hurl_path) == 'function' then
        hurl_path = unresolved_hurl_path()
    else
        local template = 'Invalid hurl_path of type %s'
        error(template:format(type(hurl_path)))
    end

    if hurl_path == nil or hurl_path:match('%s') ~= nil then
        error('Hurl path is required')
    end

    hurl_path = vim.fs.normalize(hurl_path)
    hurl_path = vim.fs.abspath(hurl_path)
    if not require('utils.path').is_existing_file(hurl_path) then
        local template = 'Hurl path does not exist: %s'
        error(template:format(hurl_path))
    end

    ---resolve env_path
    local env_path = nil
    local unresolved_env_path = opts.env_path
    if unresolved_env_path == nil then
        env_path = nil
    elseif type(unresolved_env_path) == 'string' then
        --using a temp variable so that LSP type narrowing works correctly
        env_path = unresolved_env_path
    elseif type(unresolved_env_path) == 'function' then
        env_path = unresolved_env_path()
    else
        local template = 'Invalid env_path of type %s'
        error(template:format(type(env_path)))
    end

    if env_path ~= nil and env_path:match('%s') ~= nil then env_path = nil end

    if env_path ~= nil then
        env_path = vim.fs.normalize(env_path)
        env_path = vim.fs.abspath(env_path)
    end

    if
        env_path ~= nil and not require('utils.path').is_existing_file(env_path)
    then
        local template = 'Env path does not exist: %s'
        error(template:format(env_path))
    end

    ---resolve values
    return {
        hurl_path = hurl_path,
        env_path = env_path,
    }
end

---Builds the hurl builder (its builder inception)
---@param opts HurlBuilderOptions
---@return function
function M.hurl_builder_builder(opts)
    if opts == nil then error('opts cannot be nil') end
    local builder = function()
        -- Full path to current file (see :help expand())
        local resolved_opts = resolve_hurl_options(opts)
        local report_id = getUUID()

        local data_path = vim.fn.stdpath('data')
        if type(data_path) ~= 'string' then
            error('data path is not a string')
        end

        local report_path = vim.fs.joinpath(data_path, 'hurl-report', report_id)

        local args = {
            resolved_opts.hurl_path,
            '--no-output',
            '--report-json',
            report_path,
        }
        if resolved_opts.env_path ~= nil then
            table.insert(args, '--variables-file')
            table.insert(args, resolved_opts.env_path)
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
