--This file was heavily based on d7c8fd9a482a98e44442071d1d02342ebb256be4 commit of
--snacks.nvim terminal module. I wanted a toggle term that could have the same
--terminal buffer open in more than one tab and toggled on a tab level.

---@class TerminalKey
---@field cmd? string | string[]
---@field namespace? string
---@field count integer
---@field env? table<string, string>
---@field cwd? string

---@class TerminalManager
---@field window_managers table<integer, TerminalWindowManager> lookup of which window manager is attached to which tab
---@field buffer_manager TerminalBufferManager
---@field key TerminalKey
---@field private augroup integer for terminal autocmds that need to be cleaned up on terminal destruction
---@field private esc_timer? uv_timer_t
local TerminalManager = setmetatable({}, {})
TerminalManager.__index = TerminalManager

local M = {}

---@class TerminalManagerOpts
---@field count? uinteger terminal count (defaults to vim.v.count1)
---@field cmd? string | string[] the command to run when creating the terminal
---@field cwd? string
---@field namespace? string an optional namespace to seperate groups of terminals that way I can seperate floating and non-floating terminals
---@field env? table<string, string>
---@field start_insert? boolean start insert mode when entering newly opened terminal window (default:true)
---@field auto_insert? boolean start insert mode when entering the terminal buffer (default:true)
---@field auto_close? boolean close the terminal buffer when the process exits (default:true)
---@field position? "float"|"bottom"|"top"|"left"|"right"
---@field tui_mode? boolean disables signcolumn and line numbers (default: false)

---Getter for the terminal id (the string representation of the terminal key)
---@return string terminal id
function TerminalManager:get_id() return M.convert_terminal_key_to_id(self.key) end

---Gets the window manager for the tab (defaults to current tab)
---@param tabid? uinteger id of the tab
---@return TerminalWindowManager?
function TerminalManager:get_window_manager(tabid)
    if tabid == nil or tabid == 0 then
        tabid = vim.api.nvim_get_current_tabpage()
    end
    local window_manager = self.window_managers[tabid]

    if window_manager == nil or not window_manager:buf_valid() then
        self.window_managers[tabid] = nil
        return nil
    end
    return self.window_managers[tabid]
end

---Get the window managers where the table key is the tabid the window manager is
---attatched to
---@return table<integer, TerminalWindowManager>
function TerminalManager:get_window_managers()
    return TerminalManager.window_managers
end

---Check if the terminal buffer is valid
---@return boolean
function TerminalManager:buf_valid()
    return self.buffer_manager and self.buffer_manager:buf_valid() or false
end

---Get the terminal buffer number
---@return integer
function TerminalManager:get_bufnr() return self.buffer_manager.bufnr end

---Cleans up memory for the terminal when destroying the terminal
function TerminalManager:destroy()
    for _, window_manager in pairs(self.window_managers) do
        window_manager:close({
            prevent_exit = true,
            debug_source = 'Destroy Terminal',
        })
    end
    pcall(vim.api.nvim_del_augroup_by_id, self.augroup)
end

---@class TerminalManagerOpenOpts
---@field tabid? uinteger of the tab to create the window for
---@field position? "float"|"bottom"|"top"|"left"|"right" a position to explicitly set the window to if it wasn't already that position
---@field enter? boolean Enter the window after opening (default: true)
---@field tui_mode? boolean disables signcolumn and line numbers (default: false)

---Creates a new WindowManager for the tab if it doesn't exist.
---@param opts? TerminalManagerOpenOpts
---@return TerminalWindowManager
function TerminalManager:open(opts)
    opts = opts or {}

    local tabid = (opts.tabid ~= 0 and opts.tabid)
        or vim.api.nvim_get_current_tabpage()
    local enter = opts.enter or opts.enter == nil
    local position = opts.position
    local tui_mode = opts.tui_mode == true

    if self.window_managers[tabid] ~= nil then
        local window_manager = self.window_managers[tabid]
        window_manager:show({
            position = position,
            enter = enter,
            tui_mode = tui_mode,
        })
        return window_manager
    end

    local window_manager =
        require('myconfig.terminal.terminal_window_manager').create_window_manager(
            self.buffer_manager,
            tabid
        )
    self.window_managers[tabid] = window_manager

    window_manager:show({ position = position, enter = enter, tui_mode })

    return window_manager
end

---Hides the terminal in the current tab
function TerminalManager:hide()
    local window_manager = self:get_window_manager()
    if window_manager ~= nil then window_manager:hide() end
end

---Intended to be used in a keymap to make double pressing escape trigger changing
---the mode to terminal normal mode
---@return string?
function TerminalManager:escape_key_triggered()
    self.esc_timer = self.esc_timer or vim.uv.new_timer()
    if self.esc_timer:is_active() then
        self.esc_timer:stop()
        vim.cmd('stopinsert')
    else
        self.esc_timer:start(200, 0, function() end)
        return '<esc>'
    end
end

---@type table<string, TerminalManager>
local terminals = {}

--- Creates a new terminal manager.
---@param opts? TerminalManagerOpts
---@return TerminalManager
function M.create(opts)
    opts = opts or {}

    local count = opts.count or vim.v.count1

    ---@type TerminalKey
    local terminal_key = vim.deepcopy({
        cmd = opts.cmd,
        namespace = opts.namespace,
        cwd = opts.cwd,
        env = opts.env,
        count = count,
    })

    local buffer_manager =
        require('myconfig.terminal.terminal_buffer_manager').create_terminal_buffer_manager({
            key = terminal_key,
            auto_insert = opts.auto_insert,
            ---@type TerminalWindowManagerOpts
            defaut_window_manager_opts = {
                start_insert = opts.start_insert or opts.start_insert == nil,
                auto_close = opts.auto_close or opts.auto_close == nil,
                position = opts.position or 'bottom',
                tui_mode = opts.tui_mode == true,
            },
        })

    local term_augroup_name = 'my_terminal_'
        .. M.convert_terminal_key_to_id(terminal_key)

    local term_augroup =
        vim.api.nvim_create_augroup(term_augroup_name, { clear = true })

    ---@type TerminalManager
    local terminal_fields = {
        window_managers = {},
        buffer_manager = buffer_manager,
        key = terminal_key,
    }
    local terminal = setmetatable(terminal_fields, TerminalManager)

    terminal:open()

    vim.api.nvim_create_autocmd('BufWipeout', {
        group = term_augroup,
        callback = function()
            terminal:destroy()
            terminals[terminal:get_id()] = nil
        end,
        buffer = terminal.buffer_manager.bufnr,
    })

    vim.api.nvim_create_autocmd('TabClosed', {
        group = term_augroup,
        callback = function()
            --Scheduling since there is know way to get the tabid of closed
            --tab until after this autocmd finishes because it nvim_tabpage_is_valid
            --doesn't return false until after TabClosed autocmds finish
            vim.schedule(function()
                for tabid, window_manager in pairs(terminal.window_managers) do
                    if not vim.api.nvim_tabpage_is_valid(tabid) then
                        window_manager:close({
                            prevent_exit = false,
                            debug_source = 'TabClosed',
                        })
                        terminal.window_managers[tabid] = nil
                    end
                end
            end)
        end,
    })

    vim.cmd('noh')

    return terminal
end

--- Get a terminal manager by the options used to create it.
---@param opts? TerminalManagerOpts
---@return TerminalManager? terminal
function M.get_terminal_manager_by_options(opts)
    opts = opts or {}

    ---@type TerminalKey
    local terminal_key = {
        cmd = opts.cmd,
        namespace = opts.namespace,
        cwd = opts.cwd,
        env = opts.env,
        count = opts.count or vim.v.count1,
    }
    local id = M.convert_terminal_key_to_id(terminal_key)
    return terminals[id]
end

---Gets the terminal manager for the buffer
---@param bufnr integer? the buffer number (default: 0)
---@return TerminalManager? terminal
function M.get_terminal_manager_by_bufnr(bufnr)
    if bufnr == nil then bufnr = vim.api.nvim_get_current_buf() end
    local key = vim.b[bufnr].my_terminal and vim.b[bufnr].my_terminal.key
    return key and terminals[M.convert_terminal_key_to_id(key)]
end

---Gets the terminal manager for the buffer
---@param key TerminalKey the terminal key
---@return TerminalManager? terminal
function M.get_terminal_manager_by_key(key)
    return key and terminals[M.convert_terminal_key_to_id(key)]
end

---Converts the terminal key object to a terminal id
---@param key TerminalKey
---@return string
function M.convert_terminal_key_to_id(key) return vim.inspect(key) end

---@param filter? fun(t: TerminalManager): boolean
---@return TerminalManager[]
function M.list(filter)
    if filter == nil then
        ---@type fun(t: TerminalManager): boolean
        filter = function(t) return t.buffer_manager:buf_valid() end
    end
    return vim.tbl_filter(filter, terminals)
end

--- Toggle a terminal window in the current tab.
---@param opts? TerminalManagerOpts
function M.toggle(opts)
    opts = opts or {}
    local terminal = M.get_terminal_manager_by_options(opts)
    if terminal ~= nil and not terminal.buffer_manager:buf_valid() then
        vim.notify(
            'Could not create new terminal manager. Terminal already existed but was not properly cleaned up after terminal exited',
            vim.log.levels.WARN
        )
        return nil
    end

    if terminal == nil then
        terminal = M.create(opts)
        terminals[terminal:get_id()] = terminal
        return terminal:get_window_manager()
    end
    local window_manager = terminal:get_window_manager()
    if window_manager == nil then
        window_manager = terminal:open({
            position = opts.position,
            tui_mode = opts.tui_mode,
        })
        return window_manager
    end
    return window_manager:toggle({
        position = opts.position,
        tui_mode = opts.tui_mode,
    })
end

return M
