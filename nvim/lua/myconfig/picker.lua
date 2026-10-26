local M = {}

-- local keymaps_picker = function(bufnr)
--     if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
--     local Pick = require('mini.pick')
--     -- Gather keymaps from all modes or filter for normal/visual as needed
--     local modes = { 'n', 'i', 'v', 'x', 's', 'o', 'c', 't' }
--     local items = {}
--     local seen = {}
--
--     for _, mode in ipairs(modes) do
--         for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
--             if map.lhs ~= '' then
--                 local desc = map.desc or map.rhs or ''
--                 local formatted_lhs = map.lhs
--                     :gsub(string.char(9), '<TAB>')
--                     :gsub('', '<C-F>')
--                     :gsub(' ', '<Space>')
--                 local label = string.format(
--                     '[%s] %-15s : %s',
--                     mode,
--                     formatted_lhs,
--                     desc
--                 )
--                 if not seen[label] then
--                     seen[label] = true
--                     table.insert(items, {
--                         text = label,
--                         mode = mode,
--                         lhs = map.lhs,
--                         rhs = map.rhs,
--                         callback = map.callback,
--                         desc = map.desc,
--                     })
--                 end
--             end
--         end
--         for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
--             if map.lhs ~= '' then
--                 local desc = map.desc or map.rhs or ''
--                 local formatted_lhs = map.lhs
--                     :gsub(string.char(9), '<TAB>')
--                     :gsub('', '<C-F>')
--                     :gsub(' ', '<Space>')
--                 local label = string.format(
--                     '[%s] %-15s : %s',
--                     mode,
--                     formatted_lhs,
--                     desc
--                 )
--                 if not seen[label] then
--                     seen[label] = true
--                     table.insert(items, {
--                         text = label,
--                         mode = mode,
--                         lhs = map.lhs,
--                         rhs = map.rhs,
--                         callback = map.callback,
--                         desc = map.desc,
--                     })
--                 end
--             end
--         end
--     end
--
--     Pick.start({
--         source = {
--             name = 'Keymaps',
--             items = items,
--             choose = function(item)
--                 if item.rhs and item.rhs ~= '' then
--                     -- Feed keys or execute the rhs command
--                     vim.api.nvim_feedkeys(
--                         vim.api.nvim_replace_termcodes(
--                             item.rhs,
--                             true,
--                             false,
--                             true
--                         ),
--                         'm',
--                         false
--                     )
--                 elseif item.callback then
--                     item.callback()
--                 end
--             end,
--         },
--     })
-- end

local default_rg_ignore_globs =
    { '!.git', '!venv', '!.venv', '!node_modules', '!bin/', '!obj/' }

local function get_default_rg_ignore_globs(cwd)
    cwd = cwd or vim.fn.getcwd()

    -- copy array
    local rg_ignore_globs = vim.list_extend({}, default_rg_ignore_globs)

    if string.find(cwd, '.gitworktrees') == nil then
        vim.list_extend(rg_ignore_globs, {
            '!.gitworktrees',
        })
    end
    return rg_ignore_globs
end

-------------------------------------------------------------------------------
---Custom files picker that allows me to add custom globs to the command
---when the command tool is rg
---Copied and modified from https://github.com/nvim-mini/mini.pick/blob/9368112b7cafb61d837bed55fc6f40e55df53fa0/lua/mini/pick.lua

local H = {}

H.is_executable = function(tool)
    if tool == 'fallback' then return true end
    return vim.fn.executable(tool) == 1
end

---@alias MyFindToolEnum "rg"|'fd'|'git'|'fallback'

---Determines the default file search tool
---@return MyFindToolEnum
H.files_get_tool = function()
    if H.is_executable('rg') then return 'rg' end
    if H.is_executable('fd') then return 'fd' end
    if H.is_executable('git') then return 'git' end
    return 'fallback'
end
H.show_with_icons = function(buf_id, items, query)
    require('mini.pick').default_show(
        buf_id,
        items,
        query,
        { show_icons = true }
    )
end

H.full_path = function(path)
    return (vim.fn.fnamemodify(path, ':p'):gsub('(.)/$', '%1'))
end
if H.is_windows then
    H.full_path = function(path)
        return (vim.fn.fnamemodify(path, ':p'):gsub('(.)[\\/]$', '%1'))
    end
end

H.is_array_of = function(x, ref_type)
    if not vim.islist(x) then return false end
    for i = 1, #x do
        if type(x[i]) ~= ref_type then return false end
    end
    return true
end

H.poke_picker_throttle = function(querytick_ref)
    -- Allow calling this even if no picker is active
    if not require('mini.pick').is_picker_active() then
        return function() return true end
    end

    local latest_time, dont_check_querytick =
        vim.uv.hrtime(), querytick_ref == nil
    local threshold = 1000000 * H.pickers.active.opts.delay.async
    local hrtime = vim.uv.hrtime
    local poke_is_picker_active = require('mini.pick').poke_is_picker_active
    return function()
        local now = hrtime()
        if (now - latest_time) < threshold then return true end
        latest_time = now
        -- Return positive if picker is active and no query updates (if asked)
        return poke_is_picker_active()
            and (dont_check_querytick or querytick_ref == H.querytick)
    end
end
H.files_fallback_items = function(cwd)
    local poke_picker = H.poke_picker_throttle()
    local f = function()
        local items = {}
        for path, path_type in vim.fs.dir(cwd, { depth = math.huge }) do
            if not poke_picker() then return end
            if
                path_type == 'file'
                and H.is_file_text(string.format('%s/%s', cwd, path))
            then
                table.insert(items, path)
            end
        end
        require('mini.pick').set_picker_items(items)
    end

    vim.schedule(coroutine.wrap(f))
end

---Gets the command for the tool
---@param tool MyFindToolEnum
---@param rg_tool_opts EvaluatedRgToolOpts
---@return string[]
H.files_get_command = function(tool, rg_tool_opts)
    if tool == 'rg' then
        local command = { 'rg', '--files', '--color=never' }
        if rg_tool_opts.show_hidden then table.insert(command, '--hidden') end

        if rg_tool_opts.ignore_vcs then
            table.insert(command, '--ignore-vcs')
        end
        for _, g in ipairs(rg_tool_opts.globs) do
            table.insert(command, '--glob')
            -- NOTE: no `*` as default is important to not "override" ignoring files
            table.insert(command, g)
        end
        return command
    end
    if tool == 'fd' then return { 'fd', '--type=f', '--color=never' } end
    if tool == 'git' then
        return {
            'git',
            '-c',
            'core.quotepath=false',
            'ls-files',
            '--cached',
            '--others',
            '--exclude-standard',
        }
    end
    error([[Wrong 'tool' for `files` builtin.]])
end

---@class EvaluatedRgToolOpts
---@field globs string[]
---@field show_hidden boolean will show hidden files
---@field ignore_vcs boolean won't use gitignore for determining file globs

---@class RgToolOpts
---@field globs? string[]|fun(local_opts, opts:__pick_builtin_opts):string[]
---@field show_hidden? boolean (default: false) will show hidden files
---@field ignore_vcs? boolean (default: false) won't use gitignore for determining file globs

---@class MyFindFilesLocalOpts
---@field tool? MyFindToolEnum
---@field rg_tool_opts? RgToolOpts -- used to build rg command. Only used if tool is rg.

--- Pick from files
---
--- Lists all files recursively in all subdirectories. Tries to use one of the
--- CLI tools to create items (see |MiniPick-cli-tools|): `rg`, `fd`, `git`.
--- If none is present, uses fallback which utilizes |vim.fs.dir()|.
---
--- To customize CLI tool search, either use tool's global configuration approach
--- or directly |MiniPick.builtin.cli()| with specific command.
---
---@param local_opts? MyFindFilesLocalOpts
---   Possible fields:
---   - <tool> `(string)` - which tool to use. One of "rg", "fd", "git", "fallback".
---     Default: whichever tool is present, trying in that same order.
---@param opts? __pick_builtin_opts
M.files_with_glob = function(local_opts, opts)
    ---@type MyFindFilesLocalOpts
    local_opts = vim.tbl_deep_extend('force', { tool = nil }, local_opts or {})
    local tool = local_opts.tool or H.files_get_tool()
    local config = vim.tbl_deep_extend(
        'force',
        require('mini.pick').config,
        vim.b.minipick_config or {}
    )
    local show = config.source.show or H.show_with_icons
    local default_opts =
        { source = { name = string.format('Files (%s)', tool), show = show } }
    opts = vim.tbl_deep_extend('force', default_opts, opts or {})

    local rg_tool_opts = local_opts.rg_tool_opts or {}

    ---@type string[]
    local globs = {}
    local unevaluated_globs = rg_tool_opts.globs or {}
    if type(unevaluated_globs) == 'function' then
        globs = unevaluated_globs(local_opts, opts)
    elseif
        type(unevaluated_globs) == 'table'
        and H.is_array_of(unevaluated_globs, 'string')
    then
        globs = unevaluated_globs
    end

    ---@type EvaluatedRgToolOpts
    local evaluated_rg_tool_opts = {
        globs = globs,
        show_hidden = vim.nonnil(rg_tool_opts.show_hidden, false) or false,
        ignore_vcs = vim.nonnil(rg_tool_opts.ignore_vcs, false) or false,
    }

    if tool == 'fallback' then
        local cwd = H.full_path(opts.source.cwd or vim.fn.getcwd())
        opts.source.items = function() H.files_fallback_items(cwd) end
        return require('mini.pick').start(opts)
    end

    return require('mini.pick').builtin.cli({
        command = H.files_get_command(tool, evaluated_rg_tool_opts),
        postprocess = function(items)
            if opts.source.default_items ~= nil then
                vim.list_extend(items, opts.source.default_items)
            end
            return items
        end,
    }, opts)
end

-------------------------------------------------------------------------------
--- Pick harpoon items

function M.harpoon_picker()
    local harpoon = require('myconfig.harpoon')
    local file_paths = {}
    for _, item in ipairs(harpoon:list().items) do
        -- Decode dynamic harpoon items based on current date
        local list_item_value, _ = string.gsub(
            item.value,
            '^%${(.*)}$',
            function(n) return os.date(n) end
        )
        table.insert(file_paths, list_item_value)
    end

    require('mini.pick').start({
        source = {
            name = 'Harpoon',
            items = file_paths,
        },
    })
end

-------------------------------------------------------------------------------
--- Pick project folders
function M.projects_picker()
    -- Fetch the project paths array using your existing utility function
    local project_paths = require('myconfig.utils.path').get_project_paths()

    require('mini.pick').start({
        source = {
            name = 'My Projects',
            items = project_paths,
        },

        -- mappings = {
        --     --TODO add a mapping to switch to a find files for the project at the cursor
        --     find_files = { char = '<C-tbd>', func = tbd },
        --     --TODO add a mapping to switch to live grep on the project at the cursor
        --     live_grep = { char = '<C-tbd>', func = tbd },
        -- },
    })
end

-------------------------------------------------------------------------------
--- Pick pocs folders
function M.pocs_picker()
    require('mini.pick').start({
        source = {
            name = 'My Projects',
            items = require('myconfig.utils.path').get_poc_paths(),
        },
        -- mappings = {
        --     --TODO add a mapping to switch to a find files for the poc at the cursor
        --     find_files = { char = '<C-tbd>', func = tbd },
        --     --TODO add a mapping to switch to live grep on the poc at the cursor
        --     live_grep = { char = '<C-tbd>', func = tbd },
        -- },
    })
end

-------------------------------------------------------------------------------
--- Pick notes

function M.notes_files_picker()
    local cwd = require('myconfig.utils.path').get_my_notes_dir()
    M.files_with_glob(
        {
            rg_tool_opts = {
                globs = get_default_rg_ignore_globs(cwd),
            },
        }, -- tool options
        {
            source = {
                name = 'Find Files (Notes)',
                -- Overrides the current working directory to just your notes directory
                cwd = cwd,
            },
        }
    )
end

function M.notes_grep_picker()
    local cwd = require('myconfig.utils.path').get_my_notes_dir()
    require('mini.pick').builtin.grep_live(
        {
            globs = get_default_rg_ignore_globs(cwd),
        }, -- tool options
        {
            source = {
                name = 'Live Grep (Notes)',
                -- Scopes the live grep search to your notes directory
                cwd = cwd,
            },
        }
    )
end

-------------------------------------------------------------------------------
--- Pick my dotfiles config

function M.neovim_config_find_files_picker()
    local cwd = require('myconfig.utils.path').get_nvim_config_dir()
    M.files_with_glob({
        rg_tool_opts = {
            globs = get_default_rg_ignore_globs(cwd),
        },
    }, {
        source = {
            name = 'Find Files (neovim config)',
            cwd = cwd,
        },
    })
end

function M.neovim_config_grep_files_picker()
    local cwd = require('myconfig.utils.path').get_nvim_config_dir()
    require('mini.pick').builtin.grep_live({
        globs = get_default_rg_ignore_globs(cwd),
    }, {
        source = {
            name = 'Live Grep (neovim config)',
            cwd = cwd,
        },
    })
end

-------------------------------------------------------------------------------
--- Pick my skeletons

function M.skeleton_find_files_picker()
    local cwd = require('myconfig.utils.path').get_skeleton_dir()
    M.files_with_glob({
        rg_tool_opts = {
            globs = get_default_rg_ignore_globs(cwd),
        },
    }, {
        source = {
            name = 'Find Files (skeletons)',
            cwd = cwd,
        },
    })
end

function M.skeleton_grep_files_picker()
    local cwd = require('myconfig.utils.path').get_skeleton_dir()
    require('mini.pick').builtin.grep_live({
        globs = get_default_rg_ignore_globs(cwd),
    }, {
        source = {
            name = 'Live Grep (skeletons)',
            cwd = cwd,
        },
    })
end

-------------------------------------------------------------------------------
--- Pick neovim data folder

function M.neovim_data_find_files()
    local cwd = require('myconfig.utils.path').get_nvim_data_dir()
    M.files_with_glob({
        rg_tool_opts = {
            globs = get_default_rg_ignore_globs(cwd),
        },
    }, {
        source = {
            name = 'Find Files (neovim data)',
            cwd = cwd,
        },
    })
end

function M.neovim_data_live_grep()
    local cwd = require('myconfig.utils.path').get_nvim_data_dir()
    require('mini.pick').builtin.grep_live({
        globs = get_default_rg_ignore_globs(cwd),
    }, {
        source = {
            name = 'Live Grep (neovim data)',
            cwd = cwd,
        },
    })
end

-------------------------------------------------------------------------------
--- Pick neovim plugins

function M.neovim_plugin_find_files()
    local cwd = require('myconfig.utils.path').get_nvim_plugins_dir()
    M.files_with_glob({
        rg_tool_opts = {
            globs = get_default_rg_ignore_globs(cwd),
        },
    }, {
        source = {
            name = 'Find Files (neovim plugin)',
            cwd = cwd,
        },
    })
end

function M.neovim_plugin_find_dir()
    require('mini.pick').start({
        source = {
            name = 'Plugin Directories',
            items = require('myconfig.utils.path').list_nvim_plugin_dirs(),
        },
        -- mappings = {
        --     --TODO add a mapping to switch to a find files for the poc at the cursor
        --     find_files = { char = '<C-tbd>', func = tbd },
        --     --TODO add a mapping to switch to live grep on the poc at the cursor
        --     live_grep = { char = '<C-tbd>', func = tbd },
        -- },
    })
end
function M.neovim_plugin_live_grep()
    local cwd = require('myconfig.utils.path').get_nvim_plugins_dir()
    require('mini.pick').builtin.grep_live({
        globs = get_default_rg_ignore_globs(cwd),
    }, {
        source = {
            name = 'Live Grep (neovim plugin)',
            cwd = cwd,
        },
    })
end

-------------------------------------------------------------------------------
--- Pick neovim runtime files

function M.neovim_runtime_find_files()
    local cwd = require('myconfig.utils.path').get_vimruntime_dir()
    M.files_with_glob({
        rg_tool_opts = {
            globs = get_default_rg_ignore_globs(cwd),
        },
    }, {
        source = {
            name = 'Find Files (neovim runtime)',
            cwd = cwd,
        },
    })
end

function M.neovim_runtime_live_grep()
    local cwd = require('myconfig.utils.path').get_vimruntime_dir()
    require('mini.pick').builtin.grep_live({
        globs = get_default_rg_ignore_globs(cwd),
    }, {
        source = {
            name = 'Live Grep (neovim runtime)',
            cwd = cwd,
        },
    })
end

-------------------------------------------------------------------------------
---Yaml schema picker
---This is based on https://github.com/someone-stole-my-name/yaml-companion.nvim/blob/131b0d67bd2e0f1a02e0daf2f3460482221ce3c0/lua/telescope/_extensions/yaml_schema_builtin.lua
---which got archived and then converted to mini.pick

--- gets or sets the schema in its context and lsp
---@param bufnr number
---@param new_schema MyYamlSchema | nil
local function set_schema(bufnr, new_schema)
    --Note: for this to work you also need to run the `yaml/supportSchemaSelection`
    --lsp notification to tell yamlls that we may select a schema. I do this in my
    --lsp attach autocmd.
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    if new_schema and new_schema.uri and new_schema.name then
        vim.b[bufnr].yaml_schema = new_schema

        local bufuri = vim.uri_from_bufnr(bufnr)

        local clients = vim.lsp.get_clients({
            bufnr = bufnr,
            name = 'yamlls',
        })
        if #clients < 1 then return end
        local client = clients[1]
        local settings = client.settings

        -- we don't want more than 1 schema per file
        -- Note: this is wierd and I think it may have issues
        -- when using more than one yaml file
        ---@diagnostic disable-next-line: undefined-field
        for key, _ in pairs(settings.yaml.schemas) do
            ---@diagnostic disable-next-line: undefined-field
            if settings.yaml.schemas[key] == bufuri then
                ---@diagnostic disable-next-line: undefined-field
                settings.yaml.schemas[key] = nil
            end
        end

        local override = {}
        override[new_schema.uri] = bufuri

        vim.notify(
            string.format(
                'file=%s schema=%s set new override',
                bufuri,
                new_schema.uri
            ),
            vim.log.levels.INFO
        )

        settings = vim.tbl_deep_extend(
            'force',
            settings,
            { yaml = { schemas = override } }
        )
        client.settings = vim.tbl_deep_extend(
            'force',
            settings,
            { yaml = { schemas = override } }
        )

        client:notify(
            vim.lsp.protocol.Methods.workspace_didChangeConfiguration,
            {
                settings = client.settings,
            }
        )
    end
end

---@return MyYamlSchema[]
local function get_schemas()
    local r = {}
    --schemastore strangely usees the .json.schemas() function to return the master
    --list of schemas which includes the schema name. Strangely .yaml.schemas()
    --does not have the schema name
    for _, schema in ipairs(require('schemastore').json.schemas()) do
        table.insert(r, {
            name = schema.name,
            uri = schema.url,
            -- The label used for the item
            text = string.format('%s: %s', schema.name, schema.url),
        })
    end
    return r
end
function M.yaml_schema()
    local bufnr = vim.api.nvim_get_current_buf()
    require('mini.pick').start({
        source = {
            name = 'Schema',
            items = get_schemas(),
            -- Replaces Telescope's attach_mappings selection behavior
            choose = function(entry)
                local schema = {
                    name = entry.name,
                    uri = entry.uri,
                }
                set_schema(bufnr, schema)
            end,
        },
    })
end

-------------------------------------------------------------------------------
---luasnip picker for picking snippets
--- Logic based on https://github.com/benfowler/telescope-luasnip.nvim/blob/07a2a2936a7557404c782dba021ac0a03165b343/lua/telescope/_extensions/luasnip.lua
--- where I converted the Telescope to a mini.pick picker

local filter_description = function(name, description)
    local result = ''
    if description and #description > 1 then
        for _, line in ipairs(description) do
            result = result .. line .. ' '
        end
    elseif name and description and description[1] ~= name then
        result = description[1]
    end

    return result
end
local filter_null = function(str, default)
    return str and str or (default and default or '')
end
local default_search_text = function(entry)
    local context = entry.context
    return filter_null(context.trigger)
        .. ' '
        .. filter_null(context.name)
        .. ' '
        .. entry.ft
        .. ' '
        .. filter_description(context.name, context.description)
end

local get_docstring = function(ft, context)
    local docstring = {}
    if context then
        local snips_for_ft = require('luasnip').get_snippets(ft)
        if snips_for_ft then
            for _, snippet in pairs(snips_for_ft) do
                if
                    context.name == snippet.name
                    and context.trigger == snippet.trigger
                then
                    local raw_docstring = snippet:get_docstring()
                    if type(raw_docstring) == 'string' then
                        for chunk in
                            string.gmatch(snippet:get_docstring(), '[^\n]+')
                        do
                            docstring[#docstring + 1] = chunk
                        end
                    else
                        docstring = raw_docstring
                    end
                end
            end
        end
    end
    return docstring
end

function M.luasnip_picker()
    local opts = {
        preview = {
            check_mime_type = true,
        },
    }
    local items = {}

    local available = require('luasnip').available()
    for filename, file in pairs(available) do
        for _, snippet in ipairs(file) do
            if snippet ~= nil then
                local ft = filename == '' and '-' or filename
                local item = {
                    ft = ft,
                    context = snippet,
                    -- The item label
                    text = string.format(
                        '%-12s │ %-24s │ %-16s │ %s',
                        ft,
                        snippet.name,
                        snippet.trigger,
                        filter_description(snippet.name, snippet.description)
                    ),
                }
                table.insert(items, item)
            end
        end
    end

    table.sort(items, function(a, b)
        if a.ft ~= b.ft then
            return a.ft > b.ft
        elseif a.context.name ~= b.context.name then
            return a.context.name > b.context.name
        else
            return a.context.trigger > b.context.trigger
        end
    end)

    require('mini.pick').start({
        source = {
            name = 'LuaSnip',
            items = items,
            -- Mimics default_search_text for filtering matches
            match = function(items_to_match, _, query)
                local prompt_pattern = vim.pesc(table.concat(query))
                local matches_indexes = {}
                for i, _ in ipairs(items_to_match) do
                    local item = items[i]
                    local text_to_search = default_search_text(item)
                    if
                        string.find(
                            string.lower(text_to_search),
                            string.lower(prompt_pattern),
                            1,
                            true
                        )
                    then
                        table.insert(matches_indexes, i)
                    end
                end
                return matches_indexes
            end,
            -- Custom dynamic previewer callback
            preview = function(bufnr, item)
                local snippet_lines = get_docstring(item.ft, item.context)
                if opts.preview.check_mime_type then
                    vim.bo[bufnr].filetype = item.ft
                end
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, snippet_lines)
            end,
            -- Expansion action on confirmation
            choose = function(item)
                vim.schedule(function()
                    local snippetsToExpand = {}
                    require('luasnip').available(function(snippet)
                        if snippet.trigger == item.context.trigger then
                            table.insert(snippetsToExpand, snippet)
                        end
                        return nil
                    end)

                    if #snippetsToExpand > 0 then
                        vim.cmd(':startinsert!')
                        vim.defer_fn(
                            function()
                                require('luasnip').snip_expand(
                                    snippetsToExpand[1]
                                )
                            end,
                            50
                        )
                    else
                        error(
                            "mini.pick luasnip: snippet '"
                                .. item.context.name
                                .. "' was selected, but there are no snippets to expand!"
                        )
                    end
                end)
            end,
        },
    })
end

-------------------------------------------------------------------------------
---Media files picker
---Based on https://github.com/nvim-telescope/telescope-media-files.nvim
---converted to mini.pick

---Get file extension from path
---@param url string file path or url
---@return string
local function get_file_extension(url)
    local extension_match = url:match('^.+(%..+)$')
    if type(extension_match) == 'string' then
        local extension, _ = string.gsub(extension_match, '%.', '')
        return extension
    else
        return ''
    end
end

---@class PreviewDrawerOptions
---@field path string
---@field preview_width number
---@field preview_height number

---Creates the image preview command
---@param opts PreviewDrawerOptions
---@return string[] | nil command and arguments or nil if error
---@return string? error
local function image_preview(opts)
    local chafa_cmd_name = 'chafa'
    if vim.fn.executable(chafa_cmd_name) == 0 then
        return nil,
            'Warning: Image preview requires chafa. Install it first to view preview.'
    end
    return {
        chafa_cmd_name,
        vim.fs.abspath(vim.fs.normalize(opts.path)),
        '--format=symbols',
        '--clear',
        '--size',
        string.format('%sx%s', opts.preview_width, opts.preview_height),
    },
        nil
end

---@param opts PreviewDrawerOptions
---@return string[] | nil command and arguments or nil if error
---@return string? error
local function gif_preview(opts)
    local chafa_cmd_name = 'chafa'
    if vim.fn.executable(chafa_cmd_name) == 0 then
        return nil,
            'Warning: Image preview requires chafa. Install it first to view preview.'
    end
    return {
        chafa_cmd_name,
        vim.fs.abspath(vim.fs.normalize(opts.path)),
        '--format=symbols',
        '--clear',
        '--size',
        string.format('%sx%s', opts.preview_width, opts.preview_height),
    },
        nil
end

---@param _opts PreviewDrawerOptions
---@return string[] | nil command and arguments or nil if error
---@return string? error
---@diagnostic disable-next-line: unused-local
local function video_preview(_opts)
    -- TODO
    return nil, 'unimplemented video preview'
    -- if ! command -v viu &> /dev/null; then
    --   echo "ffmpegthumbnailer could not be found in your path,\nplease install it to display video previews"
    --   exit
    -- fi
    -- path="${2##*/}"
    -- echo -e "Loading preview..\nFile: $path"
    -- ffmpegthumbnailer -i "$2" -o "${TMP_FOLDER}/${path}.png" -s 0 -q 10
    -- clear
    -- render_at_size "${5}" "${6}" "${TMP_FOLDER}/${path}.png" "${7}"

    -- return get_render_at_size_command(opts.path, opts.preview_width, opts.preview_height)
end

---@param _opts PreviewDrawerOptions
---@return string[] | nil command and arguments or nil if error
---@return string? error
---@diagnostic disable-next-line: unused-local
local function pdf_preview(_opts)
    return nil, 'unimplemented pdf preview'
    -- path="${2##*/}"
    --   echo -e "Loading preview..\nFile: $path"
    --   [[ ! -f "${TMP_FOLDER}/${path}.png" ]] && pdftoppm -png -singlefile "$2" "${TMP_FOLDER}/${path}.png"
    --   clear
    --   render_at_size "${5}" "${6}" "${TMP_FOLDER}/${path}.png" "${7}"

    -- return get_render_at_size_command(opts.path, opts.preview_width, opts.preview_height)
end

local draw_matcher = {
    ['jpg'] = image_preview,
    ['png'] = image_preview,
    ['jpeg'] = image_preview,
    ['webp'] = image_preview,
    ['svg'] = image_preview,
    ['gif'] = gif_preview,
    ['avi'] = video_preview,
    ['mp4'] = video_preview,
    ['wmv'] = video_preview,
    ['dat'] = video_preview,
    ['3gp'] = video_preview,
    ['ogv'] = video_preview,
    ['mkv'] = video_preview,
    ['mpg'] = video_preview,
    ['mpeg'] = video_preview,
    ['vob'] = video_preview,
    ['m2v'] = video_preview,
    ['mov'] = video_preview,
    ['webm'] = video_preview,
    ['mts'] = video_preview,
    ['m4v'] = video_preview,
    ['rm'] = video_preview,
    ['qt'] = video_preview,
    ['divx'] = video_preview,
    ['pdf'] = pdf_preview,
    ['epub'] = pdf_preview,
}
local function get_media_preview_command(preview_winid, media_file_path)
    local preview_width = vim.api.nvim_win_get_width(preview_winid)
    local preview_height = vim.api.nvim_win_get_height(preview_winid)

    local extension = get_file_extension(media_file_path)

    local preview_drawer = draw_matcher[extension]
    if preview_drawer then
        return preview_drawer({
            path = media_file_path,
            preview_width = preview_width,
            preview_height = preview_height,
        })
    else
        return nil, 'Invalid file type'
    end
end
function M.media_files()
    -- Ensure filetypes table exists or falls back to standard image extensions
    local filetypes = { 'png', 'jpg', 'gif', 'mp4', 'webm', 'pdf' }

    local glob_pattern = string.format('*.{%s}', table.concat(filetypes, ','))

    local command =
        { 'rg', '--files', '--color=never', '--glob', glob_pattern, '.' }

    require('mini.pick').builtin.cli({ command = command }, {
        source = {
            name = 'Media Files',
            -- Replaces the attach_mappings behavior
            choose = function(item)
                if item and item ~= '' then
                    -- Resolve full path name if needed, then copy to target register
                    local filename = vim.fn.fnamemodify(item, ':p')
                    vim.fn.setreg(vim.v.register, filename)
                    vim.notify(
                        string.format(
                            'The image path has been copied! %s',
                            filename
                        ),
                        vim.log.levels.INFO
                    )
                end
            end,
            preview = function(bufnr, item)
                local preview_winid =
                    require('mini.pick').get_picker_state().windows.main
                --Format file as an absolute path with respect to pickers cwd
                local media_file_path = vim.fn.fnamemodify(item, ':p')

                local cmd, err =
                    get_media_preview_command(preview_winid, media_file_path)
                if cmd then
                    vim.api.nvim_buf_call(
                        bufnr,
                        function()
                            vim.fn.jobstart(cmd, {
                                cwd = vim.fn.getcwd(),
                                term = true,
                            })
                        end
                    )
                elseif err ~= nil then
                    vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { err })
                end
            end,
        },
    })
end

-------------------------------------------------------------------------------
---dap pickers

function M.process_picker()
    local processes = require('dap.utils').get_processes()
    local items = {}
    for _, process in ipairs(processes) do
        table.insert(items, {
            pic = process.pid,
            name = process.name,
            --The label for each item
            text = string.format('id=%d name=%s', process.pid, process.name),
        })
    end
    local item = require('mini.pick').start({
        source = {
            name = 'Pick Process',
            items = items,
            choose = function(_) end,
        },
    })
    return item
end

function M.executable_picker()
    require('myconfig.dap').shellslash_hack()
    local command = {
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

        --We only want .exe and .dll files
        '--glob',
        '*.exe',
        '--glob',
        '*.dll',
    }

    return require('mini.pick').builtin.cli({ command = command }, {
        source = {
            name = 'Path to executable/dll',
            -- Replaces the attach_mappings behavior
            choose = function(_) end,
        },
    })
end

-------------------------------------------------------------------------------
---hurl pickers

---@param opts? __pick_builtin_opts
function M.hurl_files_picker(opts)
    opts = vim.tbl_deep_extend(
        'force',
        { source = { name = 'Find Files (Hurl files)' } },
        opts or {}
    )
    local globs = get_default_rg_ignore_globs()
    table.insert(globs, '*.hurl')
    return M.files_with_glob({
        rg_tool_opts = {
            globs = globs,
            show_hidden = true,
            show_ignore_vcs = true,
        },
    }, opts)
end

---@param opts? __pick_builtin_opts
function M.env_files_picker(opts)
    opts = vim.tbl_deep_extend(
        'force',
        { source = { name = 'Find Files (env files)' } },
        opts or {}
    )
    local globs = get_default_rg_ignore_globs()
    table.insert(globs, '*.env')
    return M.files_with_glob({
        rg_tool_opts = {
            globs = globs,
            show_hidden = true,
            show_ignore_vcs = true,
        },
    }, opts)
end

return M
