local async = require('vim._async')

---@type vim.Log
local logger = vim.log.new({
    name = 'myconfig.treesitter',
    current_level = vim.log.levels.ERROR,
    format_func = function(current_level, level, ...)
        local level_names = {
            [0] = 'TRACE',
            [1] = 'DEBUG',
            [2] = 'INFO',
            [3] = 'WARN',
            [4] = 'ERROR',
            [5] = 'OFF',
        }
        local log_date_format = '%F %H:%M:%S'

        if level < current_level then return nil end

        -- Stack shape:
        --   default_format_func <- create_writer closure <- user callsite
        local info = debug.getinfo(3, 'Sl')
        local header = string.format(
            '[%s][%s] %s:%s',
            level_names[level],
            os.date(log_date_format),
            info.short_src,
            info.currentline
        )
        local parts = { header }
        local argc = select('#', ...)
        for i = 1, argc do
            local arg = select(i, ...)
            if arg == nil then
                table.insert(parts, 'nil')
            elseif type(arg) == 'string' then
                local formatted_arg, _ = string.gsub(arg, '\n', '\n     ')
                table.insert(parts, formatted_arg)
            else
                table.insert(
                    parts,
                    -- vim.inspect(arg, { newline = '\n', indent = '' })
                    vim.inspect(arg, { newline = ' ', indent = '' })
                )
            end
        end
        local mess = table.concat(parts, '\t') .. '\n'
        return mess
    end,
})

local M = {}
-- The parsers I installed/require
--
-- angular
-- apex
-- awk
-- bash
-- c
-- c_sharp
-- cmake
-- comment
-- cpp
-- css
-- csv
-- diff
-- dockerfile
-- dtd
-- ecma
-- editorconfig
-- git_config
-- git_rebase
-- gitattributes
-- gitcommit
-- gitignore
-- go
-- graphql
-- hcl
-- html
-- html_tags
-- http
-- hurl
-- ini
-- java
-- javadoc
-- javascript
-- jinja
-- jinja_inline
-- jsdoc
-- json
-- json5
-- jsx
-- lua
-- luadoc
-- make
-- markdown
-- markdown_inline
-- mermaid
-- powershell
-- psv
-- python
-- query
-- razor
-- regex
-- requirements
-- rust
-- sflog
-- soql
-- sosl
-- sql
-- ssh_config
-- strace
-- terraform
-- toml
-- tsv
-- tsx
-- typescript
-- vim
-- vimdoc
-- vue
-- xml
-- yaml
-- zig

-- The old parsers I was using:
-- apex
-- c
-- c_sharp
-- css
-- diff
-- dtd
-- ecma
-- git_config
-- git_rebase
-- gitattributes
-- gitcommit
-- gitignore
-- html
-- html_tags
-- hurl
-- javascript
-- json
-- jsx
-- kulala_http
-- lua
-- markdown
-- markdown_inline
-- powershell
-- python
-- query
-- razor
-- regex
-- rust
-- strace
-- toml
-- tsx
-- typescript
-- vim
-- vimdoc
-- xml
-- yaml

-- old queries lived (sym linked to nvim-treesitter):
-- nvim-data\site\queries
--
--
--contained revision information for the built parser
--nvim-data\site\parser-info
--nvim-data\site\parser-info\c_sharp.revision
--
--contains the compiled parser
--nvim-data\site\parser\
--nvim-data\site\parser\c_sharp.so
--

---@class MyTreesitterParserSpec
---
---List of other languages to install (e.g., if queries inherit from them)
---@field requires? string[]
---
---@field filetypes? string[] additional filetypes to register the parser for
---
---HEAD means the parser version goes by commit hash while SEMVER means the version follows semver tags
---@field versioning_type 'HEAD'|'SEMVER'
---
---Explanatory footnote text to add in SUPPORTED_LANGUAGES.md
---@field readme_note? string
---
---Path to the parser source code
---@field path string
---
---Repo does not contain a `parser.c`; must be generated from grammar first
---@field generate? boolean
---
---Generate parser from `grammar.json` instead of `grammar.js` (default true)
---@field generate_from_json? boolean
---
---Name of the parser
---@field name string
---
--- Version to use for install and updates. Can be:
--- - `nil` (no value, default) to use repository's default branch (usually `main` or `master`).
--- - String to use specific branch, tag, or commit hash.
--- - Output of |vim.version.range()| to install the greatest/last semver tag
---   inside the version constraint.
--- @field version? string|vim.VersionRange
---
--- @field err string? any errors during setting up the parser

--- @class MyTreesitterParserInfo
--- @field err string The latest error when working on plugin. If non-empty,
---   all further actions should not be done (including triggering events).
--- @field installed? boolean Whether plugin was successfully installed.
--- @field outdated? boolean Whether the plugin is outdated
--- @field path? string path to built parser
--- @field sha_head? string Git hash of HEAD.
--- @field sha_target? string Git hash of `version_ref`.
--- @field version_str? string `spec.version` with resolved version range.
--- @field version_ref? string Resolved version as Git reference (if different from `version_str`).
--- @field is_dirty? boolean true if parser was built on a dirty repository

---@class MyTreesitterParser
---@field spec MyTreesitterParserSpec
---@field info MyTreesitterParserInfo

---@type table<string, MyTreesitterParser>
local downloaded_parsers = {}

---@async
---@param cmd string[]
---@param opts? vim.SystemOpts
---@return vim.SystemCompleted
local function system(cmd, opts)
    local cwd = opts and opts.cwd or vim.uv.cwd()
    logger.trace('running job: (cwd=%s) %s', cwd, table.concat(cmd, ' '))

    ---vim.system throws an error when uv.spawn fails, in particular if cmd or cwd
    ---does not exist. This kills the coroutine, so the async'ed call simply hangs.
    ---Instead, we pass a wrapper that catches errors and propagates them as a proper
    ---`SystemObj`.
    ---remove when https://github.com/neovim/neovim/issues/38257 is resolved.
    ---@param _cmd string[]
    ---@param _opts vim.SystemOpts
    ---@param on_exit fun(result: vim.SystemCompleted)
    ---@return vim.SystemObj?
    local function system_wrap(_cmd, _opts, on_exit)
        local ok, ret = pcall(vim.system, _cmd, _opts, on_exit)
        if not ok then
            on_exit({
                code = 125,
                signal = 0,
                stdout = '',
                stderr = ret --[[@as string]],
            })
            return nil
        end
        return ret --[[@as vim.SystemObj]]
    end

    local r = async.await(3, system_wrap, cmd, opts) --[[@as vim.SystemCompleted]]
    async.await(1, vim.schedule)
    if r.stdout and r.stdout ~= '' then
        logger.trace('stdout -> %s', r.stdout)
    end
    if r.stderr and r.stderr ~= '' then
        logger.trace('stderr -> %s', r.stderr)
    end

    return r
end

---@async
---@param parser MyTreesitterParser
---@return string? err
local function do_compile(parser)
    logger.info(string.format('Compiling parser'))
    -- local uuid = require('myconfig.utils.misc').uuid()
    local out_path = vim.fs.joinpath(
        require('myconfig.utils.path').get_treesitter_parsers_dir(),
        parser.spec.name .. '.so'
    )
    -- local out_path = 'parser.so'

    local r = system({
        'tree-sitter',
        'build',
        '-o',
        out_path,
        -- vim.fs.join(compile_location, 'parser.so'),
    }, { cwd = parser.spec.path })
    if r.code > 0 then
        logger.error('Error during "tree-sitter build": %s', r.stderr)
        return string.format('Error during "tree-sitter build": %s', r.stderr)
    end
    parser.info.installed = true
    parser.info.path = out_path
end

---Adds the parser to the list of downloaded parsers
---@param spec MyTreesitterParserSpec
function M.add_parser(spec)
    local parser_path =
        require('myconfig.utils.path').get_treesitter_parser_path(spec.name)
    local info = {
        err = '',
    }
    if require('myconfig.utils.path').is_existing_file(parser_path) then
        info.path = parser_path
        info.installed = true
    end
    downloaded_parsers[spec.name] = {
        --TODO normalize spec
        spec = vim.deepcopy(spec),
        info = info,
    }
end

--- @param action string
--- @return fun(kind: 'begin'|'report'|'end', percent: integer, fmt: string, ...:any): nil
local function new_progress_report(action)
    local progress = {
        kind = 'progress',
        source = 'myconfig.treesitter',
        title = 'myconfig.treesitter',
    }
    local headless = #vim.api.nvim_list_uis() == 0

    return vim.schedule_wrap(function(kind, percent, fmt, ...)
        progress.status = kind == 'end' and 'success' or 'running'
        progress.percent = percent
        local msg = ('%s %s'):format(action, fmt:format(...))
        progress.id = vim.api.nvim_echo({ { msg } }, kind ~= 'report', progress)
        -- Force redraw to show installation progress during startup
        -- TODO: redraw! not needed with ui2.
        if not headless then vim.cmd.redraw({ bang = true }) end
    end)
end

local copcall = package.loaded.jit and pcall or require('coxpcall').pcall

local function async_join_run_wait(funs)
    local n_threads = 2 * (vim.uv.available_parallelism() or 1)
    --- @async
    local function joined_f() async.join(n_threads, funs) end
    async.run(joined_f):wait()
end

--- Execute function in parallel for each non-errored plugin in the list
--- @param parsers MyTreesitterParser[]
--- @param f async fun(spec: MyTreesitterParserSpec)
--- @param progress_action string
local function run_list(parsers, f, progress_action)
    local report_progress = new_progress_report(progress_action)

    -- Construct array of functions to execute in parallel
    local n_finished = 0
    local funs = {} --- @type (async fun())[]
    for _, p in ipairs(parsers) do
        --- @async
        funs[#funs + 1] = function()
            local ok, err = copcall(f, p) --[[@as string]]
            if not ok then
                p.info.err = err --- @as string
            end

            -- Show progress
            n_finished = n_finished + 1
            local percent = math.floor(100 * n_finished / #funs)
            report_progress(
                'report',
                percent,
                '(%d/%d) - %s',
                n_finished,
                #funs,
                p.spec.name
            )
        end
    end

    if #funs == 0 then return end

    report_progress('begin', 0, '(0/%d)', #funs)
    async_join_run_wait(funs)
    report_progress('end', 100, '(%d/%d)', #funs, #funs)
end

vim.api.nvim_create_user_command('TSBuild', function(_)
    ---@type MyTreesitterParser[]
    local parsers = {}
    for _, parser in pairs(downloaded_parsers) do
        table.insert(parsers, parser)
    end
    run_list(parsers, do_compile, 'Compiling parsers')
end, {})

vim.api.nvim_create_user_command(
    'PrintTS',
    function(_) vim.print(downloaded_parsers) end,
    {}
)

---@param parser MyTreesitterParser
local function register_parser(parser)
    vim.treesitter.language.add(parser.spec.name, { path = parser.info.path })

    if parser.spec.filetypes ~= nil then
        vim.treesitter.language.register(
            parser.spec.name,
            parser.spec.filetypes
        )
    end
end

---@param parsers MyTreesitterParser[]
--- @return boolean
local function confirm_build(parsers)
    -- Gather pretty aligned list of plugins to install
    local name_width, name_max_width = {}, 0 --- @type integer[], integer
    for i, p in ipairs(parsers) do
        name_width[i] = vim.api.nvim_strwidth(p.spec.name)
        name_max_width = math.max(name_max_width, name_width[i])
    end
    local lines = {} --- @type string[]
    for i, p in ipairs(parsers) do
        local pad = (' '):rep(name_max_width - name_width[i] + 1)
        lines[i] = ('%s%sfrom %s'):format(p.spec.name, pad, p.spec.path)
    end

    local text = table.concat(lines, '\n')
    local confirm_msg = ('These parsers will be built:\n\n%s\n'):format(text)
    local choice =
        vim.fn.confirm(confirm_msg, 'Proceed? &Yes\n&No', 1, 'Question')
    vim.cmd.redraw()
    return choice == 1
end

---@param parsers MyTreesitterParser[]
---@param confirm? boolean Whether to ask user to confirm initial install. Default `true`.
local function build_parsers(parsers, confirm)
    if confirm == nil then confirm = true end
    if confirm and confirm_build(parsers) then
        run_list(parsers, do_compile, 'Compiling parsers')
    end
end

local function report_parser_errors()
    -- Collect any parser build/registration errors
    local errors = {} --- @type string[]
    for _, p in pairs(downloaded_parsers) do
        if p.info.err ~= '' then
            errors[#errors + 1] = ('`%s`:\n%s'):format(p.spec.name, p.info.err)
        end
    end

    if #errors > 0 then
        local error_str = table.concat(errors, '\n\n')
        error(('myconfig.treesitter:\n\n%s'):format(error_str))
    end
end

local function register_all_installed_parsers()
    for _, p in pairs(downloaded_parsers) do
        if p.info.installed then
            local ok, err = pcall(register_parser, p) --[[@as string]]
            if not ok then p.info.err = err end
        end
    end
end

--- @param p MyTreesitterParser
--- @return string
local function compute_feedback_lines_single(p)
    if p.info.err ~= '' then
        return ('## %s\n\n %s'):format(
            p.spec.name,
            p.info.err:gsub('\n', '\n  ')
        )
    end

    local parts = { ('## %s\n'):format(p.spec.name) }
    local version_suffix = p.info.version_str == '' and ''
        or (' (%s)'):format(p.info.version_str)

    if p.info.sha_head == p.info.sha_target then
        parts[#parts + 1] = table.concat({
            'Path:     ' .. p.spec.path,
            -- 'Source:   ' .. p.spec.src,
            -- 'Revision: '
            --     .. p.info.sha_target
            --     .. version_suffix,
        }, '\n')
    else
        parts[#parts + 1] = table.concat({
            'Path:            ' .. p.spec.path,
            -- 'Source:          ' .. p.spec.src,
            -- 'Revision before: ' .. p.info.sha_head,
            -- 'Revision after:  ' .. p.info.sha_target .. version_suffix,
        }, '\n')
    end

    return table.concat(parts, '')
end

--- @param parsers MyTreesitterParser[]
--- @return string[]
local function compute_feedback_lines(parsers, skip_same_sha)
    -- Construct parser line groups for better report
    local report_err, report_unbuilt, report_update, report_same =
        {}, {}, {}, {}
    for _, p in ipairs(parsers) do
        if p.info.err ~= '' then
            report_err[#report_err + 1] = compute_feedback_lines_single(p)
        elseif not p.info.installed then
            report_unbuilt[#report_unbuilt + 1] =
                compute_feedback_lines_single(p)
        elseif p.info.outdated then
            report_update[#report_update + 1] = compute_feedback_lines_single(p)
        else
            report_same[#report_same + 1] = compute_feedback_lines_single(p)
        end
    end

    local lines = {}
    --- @param header string
    --- @param arr string[]
    local function append_report(header, arr)
        if #arr == 0 then return end
        header = header .. ' ' .. string.rep('─', 79 - header:len())
        table.insert(lines, header)
        vim.list_extend(lines, arr)
    end
    append_report('# Error', report_err)
    append_report('# Unbuilt', report_unbuilt)
    append_report('# Update', report_update)
    if not skip_same_sha then append_report('# Same', report_same) end

    return vim.split(table.concat(lines, '\n\n'), '\n')
end

--- @param lines string[]
--- @param on_finish fun(bufnr: integer)
local function show_confirm_buf(lines, on_finish)
    -- Show buffer in a separate tabpage
    local bufnr = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(bufnr, 'mytreesitter://confirm#' .. bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.cmd.sbuffer({ bufnr, mods = { tab = vim.fn.tabpagenr() } })
    local win_id = vim.api.nvim_get_current_win()

    local delete_buffer = vim.schedule_wrap(function()
        pcall(vim.api.nvim_win_close, win_id, true)
        pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
        vim.cmd.redraw()
    end)

    -- Define action on accepting confirm
    local function finish()
        on_finish(bufnr)
        delete_buffer()
    end
    -- - Use `nested` to allow other events (useful for statuslines)
    vim.api.nvim_create_autocmd(
        'BufWriteCmd',
        { buf = bufnr, nested = true, callback = finish }
    )

    -- Define action to cancel confirm
    --- @type integer
    local cancel_au_id
    local function on_cancel(data)
        if vim._tointeger(data.match) ~= win_id then return end
        pcall(vim.api.nvim_del_autocmd, cancel_au_id)
        delete_buffer()
    end
    cancel_au_id = vim.api.nvim_create_autocmd(
        'WinClosed',
        { nested = true, callback = on_cancel }
    )

    -- Set buffer-local options last (so that user autocmmands could override)
    vim.bo[bufnr].modified = false
    vim.bo[bufnr].modifiable = false
    vim.bo[bufnr].buftype = 'acwrite'
    vim.bo[bufnr].filetype = 'mytreesitter'

    -- Attach in-process LSP for more capabilities
    -- vim.lsp.buf_attach_client(bufnr, require('vim.pack._lsp').client_id)
end
function M.setup_treesitter()
    local is_ui_visible = #vim.api.nvim_list_uis() > 0

    if is_ui_visible then
        local can_build = false
        local parsers = {}
        for _, p in pairs(downloaded_parsers) do
            if not p.info.installed or p.info.outdated then
                can_build = true
                table.insert(parsers, p)
            end
        end
        if can_build then
            -- Show report in new buffer in separate tabpage
            local lines = compute_feedback_lines(parsers, false)
            show_confirm_buf(lines, function(bufnr)
                ---@type MyTreesitterParser[]
                local parsers_to_build = get_parsers_to_build(bufnr)
                if #parsers_to_build > 0 then
                    build_parsers(parsers_to_build, nil)
                    register_all_installed_parsers()
                    report_parser_errors()
                    -- vim.treesitter.language.add(
                    --     'jsonc',
                    --     { path = json_parser_file, symbol_name = 'json' }
                    -- )
                else
                    vim.notify('Nothing to build', 'WARN')
                    register_all_installed_parsers()
                    report_parser_errors()
                end
            end)
        else
            register_all_installed_parsers()
            report_parser_errors()
        end
    end
end

return M
