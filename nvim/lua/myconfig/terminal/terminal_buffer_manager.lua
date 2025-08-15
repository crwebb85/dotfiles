---@class TerminalBufferManager
---@field bufnr uinteger
local TerminalBufferManager = setmetatable({}, {})
TerminalBufferManager.__index = TerminalBufferManager

---@class TerminalBufferManagerOptions
---@field key TerminalKey
---@field auto_insert? boolean start insert mode when entering the terminal buffer (default:true)
---@field defaut_window_manager_opts TerminalWindowManagerOpts

---Check if the terminal buffer is valid
---@return boolean
function TerminalBufferManager:buf_valid()
    return self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) or false
end

---Gets the default window options when creating a new terminal window for
---this buffer. The values are stored in a buffer local variable to make
---loading from a session possible.
---@return TerminalWindowManagerOpts
function TerminalBufferManager:get_window_default_options()
    local my_terminal_settings = vim.b[self.bufnr].my_terminal
    ---@type TerminalWindowManagerOpts
    local opts = my_terminal_settings
            and my_terminal_settings.defaut_window_manager_opts
        or {}

    ---@type TerminalWindowManagerOpts
    local win_opts = {
        start_insert = true,
        auto_close = true,
        tui_mode = false,
        position = 'bottom',
    }

    if type(opts.start_insert) == 'boolean' then
        win_opts.start_insert = opts.start_insert
    end

    if type(opts.auto_close) == 'boolean' then
        win_opts.auto_close = opts.auto_close
    end

    if type(opts.tui_mode) == 'boolean' then
        win_opts.tui_mode = opts.tui_mode
    end

    local valid_position = { 'float', 'bottom', 'top', 'left', 'right' }
    if vim.tbl_contains(valid_position, opts.position) then
        --TODO Im not sure how I feel about the if I first open a terminal in a position
        --that stays it's default. I guess I will just wait and see if that gets annoying
        win_opts.position = opts.position
    end

    return win_opts
end

local M = {}

--- Parses a shell command into a table of arguments.
--- - spaces inside quotes (only double quotes are supported) are preserved
--- - backslash
--- This is copied verbatum from snack.nvim plugin
---@private
---@param cmd string|string[]
---@return string[]
local function parse_shell_option_to_cmd(cmd)
    if type(cmd) == 'table' then return cmd end
    local args = {}
    local in_quotes, escape_next, current = false, false, ''
    local function add()
        if #current > 0 then
            table.insert(args, current)
            current = ''
        end
    end

    for i = 1, #cmd do
        local char = cmd:sub(i, i)
        if escape_next then
            current = current
                .. ((char == '"' or char == '\\') and '' or '\\')
                .. char
            escape_next = false
        elseif char == '\\' and in_quotes then
            escape_next = true
        elseif char == '"' then
            in_quotes = not in_quotes
        elseif char:find('[ \t]') and not in_quotes then
            add()
        else
            current = current .. char
        end
    end
    add()
    return args
end

---Creates a new buffer manager
---@param opts TerminalBufferManagerOptions
function M.create_terminal_buffer_manager(opts)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].filetype = 'my_terminal'
    vim.b[bufnr].my_terminal = {
        key = opts.key,
        defaut_window_manager_opts = opts.defaut_window_manager_opts,
    }

    local auto_insert = opts.auto_insert or opts.auto_insert == nil

    if auto_insert then
        vim.api.nvim_create_autocmd('BufEnter', {
            callback = function() vim.cmd.startinsert() end,
            buffer = bufnr,
        })
    end

    ---@type TerminalBufferManager
    local buffer_manager_fields = {
        bufnr = bufnr,
    }
    local buffer_manager =
        setmetatable(buffer_manager_fields, TerminalBufferManager)

    vim.api.nvim_buf_call(
        buffer_manager.bufnr,
        function()
            vim.fn.jobstart(
                opts.key.cmd or parse_shell_option_to_cmd(vim.o.shell),
                {
                    cwd = opts.key.cwd,
                    env = opts.key.env,
                    term = true,
                }
            )
        end
    )

    return buffer_manager
end

return M
