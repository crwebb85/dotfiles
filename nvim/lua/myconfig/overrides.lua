local default_select = vim.ui.select
local default_open = vim.ui.open
local default_fs_root = vim.fs.root

local M = {}

--- Opens `path` with the system default handler (macOS `open`, Windows `explorer.exe`, Linux
--- `xdg-open`, …), or returns (but does not show) an error message on failure.
---
--- Can also be invoked with `:Open`. [:Open]()
---
--- Expands "~/" and environment variables in filesystem paths.
---
--- Examples:
---
--- ```lua
--- -- Asynchronous.
--- vim.ui.open("https://neovim.io/")
--- vim.ui.open("~/path/to/file")
--- -- Use the "osurl" command to handle the path or URL.
--- vim.ui.open("gh#neovim/neovim!29490", { cmd = { 'osurl' } })
--- -- Synchronous (wait until the process exits).
--- local cmd, err = vim.ui.open("$VIMRUNTIME")
--- if cmd then
---   cmd:wait()
--- end
--- ```
---
---@param path string Path or URL to open
---@param opt? vim.ui.open.Opts Options
---
---@return vim.SystemObj|nil # Command object, or nil if not found.
---@return nil|string # Error message on failure, or nil on success.
---
---@see |vim.system()|
function M.open(path, opt)
    local is_dir = require('myconfig.utils.path').is_directory(path)
    if vim.fn.executable('explorer') == 1 and is_dir then
        vim.cmd([[!explorer ]] .. path)
        --TODO for some reason vim.system({'explore.exe', path}) does not work when
        --path is a directory as a result default_open also doesn't work when path
        --is a directory. However the command works just fine in powershell to open the
        --directory.
    else
        default_open(path, opt)
    end
end

--From https://github.com/nvim-telescope/telescope-ui-select.nvim/blob/6e51d7da30bd139a6950adf2a47fda6df9fa06d2/lua/telescope/_extensions/ui-select.lua
local function make_codeaction_indexed(items)
    local indexed_items = {}
    local widths = {
        idx = 0,
        command_title = 0,
        client_name = 0,
    }
    for idx, item in ipairs(items) do
        local client_id, title
        client_id = item.ctx.client_id
        title = item.action.title

        local client = vim.lsp.get_client_by_id(client_id)

        local entry = {
            idx = idx,
            ['add'] = {
                command_title = title:gsub('\r\n', '\\r\\n'):gsub('\n', '\\n'),
                client_name = client and client.name or '',
            },
            text = item,
        }
        table.insert(indexed_items, entry)
        widths.idx = math.max(
            widths.idx,
            require('plenary.strings').strdisplaywidth(entry.idx)
        )
        widths.command_title = math.max(
            widths.command_title,
            require('plenary.strings').strdisplaywidth(entry.add.command_title)
        )
        widths.client_name = math.max(
            widths.client_name,
            require('plenary.strings').strdisplaywidth(entry.add.client_name)
        )
    end
    return indexed_items, widths
end

--From https://github.com/nvim-telescope/telescope-ui-select.nvim/blob/6e51d7da30bd139a6950adf2a47fda6df9fa06d2/lua/telescope/_extensions/ui-select.lua
local function make_codeaction_displayer(widths)
    return require('telescope.pickers.entry_display').create({
        separator = ' ',
        items = {
            { width = widths.idx + 1 }, -- +1 for ":" suffix
            { width = widths.command_title },
            { width = widths.client_name },
        },
    })
end

--From https://github.com/nvim-telescope/telescope-ui-select.nvim/blob/6e51d7da30bd139a6950adf2a47fda6df9fa06d2/lua/telescope/_extensions/ui-select.lua
local function make_codeaction_display(displayer)
    return function(e)
        return displayer({
            { e.value.idx .. ':', 'TelescopePromptPrefix' },
            { e.value.add.command_title },
            {
                e.value.add.client_name,
                'TelescopeResultsComment',
            },
        })
    end
end

--From https://github.com/nvim-telescope/telescope-ui-select.nvim/blob/6e51d7da30bd139a6950adf2a47fda6df9fa06d2/lua/telescope/_extensions/ui-select.lua
local function make_codeaction_ordinal(e) return e.idx .. e.add['command_title'] end

--From https://github.com/nvim-telescope/telescope-ui-select.nvim/blob/6e51d7da30bd139a6950adf2a47fda6df9fa06d2/lua/telescope/_extensions/ui-select.lua
--Im mostly using this when I'm having the issue with the bug that causes vim.cmd('redraw')
--to clear the default vim.ui.select from the selection menu
function M.telescope_ui_select(items, opts, on_choice)
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local utils = require('telescope.utils')

    opts = opts or {}
    local prompt = opts.prompt or 'Select one of'

    opts.format_item = vim.F.if_nil(
        opts.format_item,
        function(e) return tostring(e) end
    )

    -- schedule_wrap because closing the windows is deferred
    -- See https://github.com/nvim-telescope/telescope.nvim/pull/2336
    -- And we only want to dispatch the callback when we're back in the original win
    on_choice = vim.schedule_wrap(on_choice)

    local sopts = {}
    if opts.kind == 'codeaction' then
        sopts = {
            make_indexed = make_codeaction_indexed,
            make_displayer = make_codeaction_displayer,
            make_display = make_codeaction_display,
            make_ordinal = make_codeaction_ordinal,
        }
    end

    local indexed_items, widths = vim.F.if_nil(
        sopts.make_indexed,
        function(items_)
            local updated_indexed_items = {}
            for idx, item in ipairs(items_) do
                table.insert(updated_indexed_items, { idx = idx, text = item })
            end
            return updated_indexed_items
        end
    )(items)
    local displayer = vim.F.if_nil(sopts.make_displayer, function() end)(widths)
    local make_display = vim.F.if_nil(sopts.make_display, function(_)
        return function(e)
            local x, _ = opts.format_item(e.value.text)
            return x
        end
    end)(displayer)
    local make_ordinal = vim.F.if_nil(
        sopts.make_ordinal,
        function(e) return opts.format_item(e.text) end
    )
    pickers
        .new({}, {
            prompt_title = string.gsub(prompt, '\n', ' '),
            finder = finders.new_table({
                results = indexed_items,
                entry_maker = function(e)
                    return {
                        value = e,
                        display = make_display,
                        ordinal = make_ordinal(e),
                    }
                end,
            }),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    local selection = action_state.get_selected_entry()
                    local cb = on_choice
                    on_choice = function(_, _) end
                    actions.close(prompt_bufnr)
                    if selection == nil then
                        utils.__warn_no_selection('ui-select')
                        cb(nil, nil)
                        return
                    end
                    cb(selection.value.text, selection.value.idx)
                end)
                actions.close:enhance({
                    post = function() on_choice(nil, nil) end,
                })
                return true
            end,
            sorter = conf.generic_sorter({}),
        })
        :find()
end

function M.get_select_function()
    if require('myconfig.config').use_telescope_for_vim_ui_select then
        return M.telescope_ui_select
    else
        return default_select
    end
end

function M.fs_root(source, marker)
    local root_path = default_fs_root(source, marker)
    if root_path == nil then return nil end
    --I have an issue where diffview creates a buffer with root path of '.'
    if root_path == '.' or root_path == './' or root_path == '/.' then
        -- vim.print('override root path')
        root_path = assert(vim.uv.cwd())
    end

    -- vim.print('unnormalized: ' .. root_path)
    local normalized_root_path = vim.fs.normalize(root_path)
    -- vim.print('normalized: ' .. normalized_root_path)
    if require('myconfig.utils.path').is_directory(normalized_root_path) then
        return vim.fs.abspath(normalized_root_path)
    end

    vim.notify(string.format('fs_root non-file root_path %s', root_path))
    return root_path
end

-------------------------------------------------------------------------------
---Override functions
vim.ui.select = M.get_select_function()
-- vim.ui.open = M.open
--
-- vim.fs.root = M.fs_root

-------------------------------------------------------------------------------
---Override autocmds

-- Fix error that occurs when the completion documentation window is closed
-- Error in "msg_showmode" UI event handler (ns=nvim._ext_ui):
-- Lua: ...vim-win64\share\nvim\runtime/lua/vim/_extui/messages.lua:162: E565: Not allowed to change text or change window
-- stack traceback:
-- 	[C]: in function 'nvim_buf_set_text'
-- 	...vim-win64\share\nvim\runtime/lua/vim/_extui/messages.lua:162: in function 'set_virttext'
-- 	...vim-win64\share\nvim\runtime/lua/vim/_extui/messages.lua:424: in function 'handler'
-- 	C:\nvim-win64\share\nvim\runtime/lua/vim/_extui.lua:44: in function 'ui_callback'
-- 	C:\nvim-win64\share\nvim\runtime/lua/vim/_extui.lua:92: in function <C:\nvim-win64\share\nvim\runtime/lua/vim/_extui.lua:85>
-- 	[C]: in function 'nvim__redraw'
-- 	C:\nvim-win64\share\nvim\runtime/lua/vim/diagnostic.lua:2932: in function <C:\nvim-win64\share\nvim\runtime/lua/vim/diagnostic.lua:2930>
-- 	[C]: in function 'nvim_exec_autocmds'
-- 	C:\nvim-win64\share\nvim\runtime/lua/vim/diagnostic.lua:2615: in function 'reset'
-- 	C:/nvim-win64/share/nvim/runtime/lua/vim/lsp/client.lua:1277: in function '_on_detach'
-- 	C:\nvim-win64\sha
--
-- 	The fix was to just schedule the redraw
vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group = vim.api.nvim_create_augroup('nvim.diagnostic.status', {}),
    callback = function(ev)
        vim.schedule(function()
            if vim.api.nvim_buf_is_loaded(ev.buf) then
                vim.api.nvim__redraw({ buf = ev.buf, statusline = true })
            end
        end)
    end,
    desc = 'diagnostics component for the statusline',
})

return M
