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
        return default_open(path, opt)
    end
end

-------------------------------------------------------------------------------
---Filepath overrides

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

function M.override_lspconfig_root_pattern()
    local default_root_pattern = require('lspconfig.util').root_pattern

    ---@diagnostic disable-next-line: duplicate-set-field
    require('lspconfig.util').root_pattern = function(...)
        local pattern_func = default_root_pattern(...)
        return function(start_path)
            local path
            if
                require('myconfig.utils.misc').string_starts_with(
                    start_path,
                    'diffview:'
                )
            then
                -- vim.print('starts with diffview')
                path = assert(vim.uv.cwd())
            else
                path = pattern_func(start_path)
            end
            if path == '.' or path == './' or path == '/.' then
                path = assert(vim.uv.cwd())
            end

            local normalized_root_path = vim.fs.normalize(path)
            if
                require('myconfig.utils.path').is_directory(
                    normalized_root_path
                )
            then
                return vim.fs.abspath(normalized_root_path)
            end
            return path
        end
    end
end

local sysname = vim.uv.os_uname().sysname:lower()
local iswin = not not (sysname:find('windows') or sysname:find('mingw'))
local os_sep = iswin and '\\' or '/'

---@param path string
---@return string
local function normalized_path_seperators(path)
    local leading_slashes, rem = path:match('^([\\/]*)(.*)$')
    ---@type string
    local normalized_rem = rem:gsub('[\\/]+', os_sep)
    local normalized_leading = ''
    if #leading_slashes >= 2 then
        normalized_leading = os_sep .. os_sep
    elseif #leading_slashes == 1 then
        normalized_leading = os_sep
    end
    return string.format('%s%s', normalized_leading, normalized_rem)
end

function M.joinpath(...)
    local path = table.concat({ ... }, '/')
    path = normalized_path_seperators(path)
    return (path:gsub('\\', '/'))
end

local old_bufadd = vim.fn.bufadd

--- @param name string
--- @return integer
function M.bufadd(name)
    if name == '' or not vim.uv.fs_stat(name) then return old_bufadd(name) end
    return old_bufadd(vim.fs.abspath(vim.fs.normalize(name)))
end

-------------------------------------------------------------------------------
---Override functions

-- Issue https://github.com/neovim/neovim/issues/36293 was supposed to fix
-- opening windows explorer for folders but the merged fix seems to close the open
-- explorer the second try open it and then prevents you from opening the folder again
-- TODO create a new ticket
if vim.fn.has('win32') == 1 then vim.ui.open = M.open end

-- vim.fs.joinpath = M.joinpath
-- vim.fs.root = M.fs_root
-- vim.fn.bufadd = M.bufadd

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
