--This file was heavily based on d7c8fd9a482a98e44442071d1d02342ebb256be4 commit of
--snacks.nvim terminal and win modules

---@class TerminalWindowManager
---@field id number this id is primarily used to create unique augroup that doesn't change when winid changes
---@field private buffer_manager TerminalBufferManager
---@field tabid uinteger of the tab to the window manager is locked to
---@field winid? uinteger the winid of the window. Will be nil when window is hidden.
---@field augroup number the augroup of the window manager's autocmds.
---@field position "float"|"bottom"|"top"|"left"|"right" the position the window is in if open or was last in if closed
---@field auto_close boolean close the terminal buffer when the process exits
---@field start_insert boolean start insert mode when entering newly opened terminal window
local TerminalWindowManager = setmetatable({}, {})
TerminalWindowManager.__index = TerminalWindowManager

---@class TerminalWindowManagerOpts
---@field auto_close? boolean close the terminal buffer when the process exits (default:true)
---@field start_insert? boolean start insert mode when starting the terminal (default:true)
---@field position? "float"|"bottom"|"top"|"left"|"right" (default: bottom)

---@class TerminalWindowManagerShowOpts
---@field position? "float"|"bottom"|"top"|"left"|"right" a position to explicitly set the window to if it wasn't already that position
---@field enter? boolean Enter the window after opening (default: true)

local M = {}

---The id of the previously created window manager.
---This is needed for generating unique augroups
---Note: I cannot use winid because it can change each time I open and close
---the window manager
local id = 0

---Creates a new window_manager
---@param buffer_manager TerminalBufferManager
---@param tabid? uinteger of the tab to create the window for
---@return TerminalWindowManager
function M.create_window_manager(buffer_manager, tabid)
    tabid = (tabid ~= 0 and tabid) or vim.api.nvim_get_current_tabpage()

    id = id + 1

    local opts = buffer_manager:get_window_default_options()

    ---@type TerminalWindowManager
    local window_manager_fields = {
        id = id,
        tabid = tabid,
        buffer_manager = buffer_manager,
        position = opts.position or 'bottom',
        auto_close = opts.auto_close or opts.auto_close == nil,
        start_insert = opts.start_insert or opts.start_insert == nil,
    }
    local window_manager =
        setmetatable(window_manager_fields, TerminalWindowManager)

    return window_manager
end

---@type integer? a buffer used as a last resort for switching to when creating new windows
local scratch_bufnr = nil

---Tries to close the window and if it fails because it is the last window
---open a new window with oil open to cwd
---retrying closing the window
---@param winid uinteger
---@param opts TerminalWindowManagerCloseOpts
local function safe_close_win(winid, opts)
    -- vim.notify('Close called by ' .. opts.debug_source, vim.log.levels.DEBUG)
    local ok_close, err_close = pcall(vim.api.nvim_win_close, winid, true)
    ---E444 is the error that happens when you try to close the last window
    if not ok_close and (err_close and err_close:find('E444')) then
        if opts.prevent_exit then
            -- vim.notify(
            --     'Preventing exit. Close was called by ' .. opts.debug_source,
            --     vim.log.levels.DEBUG
            -- )

            if
                scratch_bufnr == nil
                or not vim.api.nvim_buf_is_valid(scratch_bufnr)
            then
                scratch_bufnr = vim.api.nvim_create_buf(true, true)
            end

            local ok_winopen, winid_or_err_winopen =
                pcall(vim.api.nvim_open_win, scratch_bufnr, false, {
                    split = 'above',
                    win = -1,
                })
            local new_winid = type(winid_or_err_winopen) == 'number'
                    and winid_or_err_winopen
                or nil

            --E1159 is the error that happens when you try to split the window
            --during a BufWipeout event when the window currently displays the buffer
            --being wiped out
            if
                not ok_winopen
                and (
                    winid_or_err_winopen
                    and type(winid_or_err_winopen) == 'string'
                    and winid_or_err_winopen:find('E1159')
                )
            then
                vim.api.nvim_set_current_buf(scratch_bufnr)
                new_winid = vim.api.nvim_open_win(scratch_bufnr, false, {
                    split = 'above',
                    win = -1,
                })
            elseif not ok_winopen and winid_or_err_winopen ~= nil then
                error(winid_or_err_winopen)
            end

            if new_winid == nil then error('wth are you nil') end
            vim.api.nvim_win_call(
                new_winid,
                function() require('oil').open() end
            )
            vim.api.nvim_win_close(winid, true)
        end
    elseif not ok_close and err_close then
        error(err_close)
    end
end

---@class TerminalWindowManagerCloseOpts
---@field prevent_exit boolean prevents exiting neovim when last window by opening a new window
---@field debug_source string a string used when debugging to determine which autocmd/function called close

---Closes the window manager
---Note: Since you can't close a window we actually just destroy the window and
---do needed cleanup so it's easy to just create a new window when we try to
---reopen it
---@param opts TerminalWindowManagerCloseOpts
function TerminalWindowManager:close(opts)
    local winid = self.winid
    if winid and vim.api.nvim_win_is_valid(winid) then
        local ok_close, err_close = pcall(safe_close_win, winid, opts)
        if not ok_close then
            vim.notify(
                'Failed to close window: ' .. vim.inspect(err_close),
                vim.log.levels.ERROR
            )
        end
    end

    --Try to delete the augroup. If it errors not because augroup was already deleted
    --then log the error
    local ok_del_augroup, err_del_augroup =
        pcall(vim.api.nvim_del_augroup_by_id, self.augroup)
    if
        not ok_del_augroup
        and (err_del_augroup and not err_del_augroup:find('E367'))
    then
        vim.notify(
            'Failed to cleanup terminal window autocmds: '
                .. vim.inspect(err_del_augroup),
            vim.log.levels.ERROR
        )
    end
end

---Hides the terminal window and equalizes positions of remaining
---terminal windows
---@return TerminalWindowManager
function TerminalWindowManager:hide()
    self:close({ prevent_exit = true, debug_source = 'hide' })
    vim.schedule(function() self:equalize() end)
    return self
end

---Toggles the terminal window
---@param opts? TerminalWindowManagerShowOpts
---@return TerminalWindowManager
function TerminalWindowManager:toggle(opts)
    opts = opts or {}
    opts.position = opts.position or self.position

    if opts.position ~= self.position then
        --If we are changing the position we won't hide the terminal
        --and instead just move it to the new position
        self:show(opts)
    elseif self:is_valid() then
        self:hide()
    else
        self:show(opts)
    end
    return self
end

---Trys to make terminal windows consistent sizes
---@private
function TerminalWindowManager:equalize()
    if self:is_floating() or not vim.api.nvim_tabpage_is_valid(self.tabid) then
        return
    end

    ---@type {[integer]: vim.fn.getwininfo.ret.item[]}
    local window_info_by_wincol = {}
    ---@type {[integer]: vim.fn.getwininfo.ret.item[]}
    local window_info_by_winrow = {}

    ---@type integer[]
    local bottom_terminal_winrows = {}
    ---@type integer[]
    local top_terminal_winrows = {}
    ---@type integer[]
    local left_terminal_wincols = {}
    ---@type integer[]
    local right_terminal_wincols = {}

    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(self.tabid)) do
        local win_info = vim.fn.getwininfo(winid)[1] --getwinfo returns one item in the list when you specify the winid

        window_info_by_wincol[win_info.wincol] = window_info_by_wincol[win_info.wincol]
            or {}
        table.insert(window_info_by_wincol[win_info.wincol], win_info)

        window_info_by_winrow[win_info.winrow] = window_info_by_winrow[win_info.winrow]
            or {}
        table.insert(window_info_by_winrow[win_info.winrow], win_info)

        local position = vim.w[winid].my_terminal_window
            and vim.w[winid].my_terminal_window.position
        if position == 'bottom' then
            table.insert(bottom_terminal_winrows, win_info.winrow)
        elseif position == 'top' then
            table.insert(top_terminal_winrows, win_info.winrow)
        elseif position == 'left' then
            table.insert(left_terminal_wincols, win_info.wincol)
        elseif position == 'right' then
            table.insert(right_terminal_wincols, win_info.wincol)
        end
    end

    for _, winrow in ipairs(bottom_terminal_winrows) do
        local row_width = 0
        local row_win_count = 0
        for _, win_info in ipairs(window_info_by_winrow[winrow]) do
            row_width = row_width + win_info.width
            row_win_count = row_win_count + 1
        end

        local size = math.floor(row_width / row_win_count)

        for _, win_info in ipairs(window_info_by_winrow[winrow]) do
            vim.api.nvim_win_call(
                win_info.winid,
                function() vim.cmd(('vertical resize %s'):format(size)) end
            )
        end
    end

    for _, winrow in ipairs(top_terminal_winrows) do
        local row_width = 0
        local row_win_count = 0
        for _, win_info in ipairs(window_info_by_winrow[winrow]) do
            row_width = row_width + win_info.width
            row_win_count = row_win_count + 1
        end

        local size = math.floor(row_width / row_win_count)

        for _, win_info in ipairs(window_info_by_winrow[winrow]) do
            vim.api.nvim_win_call(
                win_info.winid,
                function() vim.cmd(('vertical resize %s'):format(size)) end
            )
        end
    end

    for _, wincol in ipairs(left_terminal_wincols) do
        local col_height = 0
        local col_win_count = 0
        for _, win_info in ipairs(window_info_by_wincol[wincol]) do
            col_height = col_height + win_info.height
            col_win_count = col_win_count + 1
        end

        local size = math.floor(col_height / col_win_count)

        for _, win_info in ipairs(window_info_by_wincol[wincol]) do
            vim.api.nvim_win_call(
                win_info.winid,
                function() vim.cmd(('horizontal resize %s'):format(size)) end
            )
        end
    end

    for _, wincol in ipairs(right_terminal_wincols) do
        local col_height = 0
        local col_win_count = 0
        for _, win_info in ipairs(window_info_by_wincol[wincol]) do
            col_height = col_height + win_info.height
            col_win_count = col_win_count + 1
        end

        local size = math.floor(col_height / col_win_count)

        for _, win_info in ipairs(window_info_by_wincol[wincol]) do
            vim.api.nvim_win_call(
                win_info.winid,
                function() vim.cmd(('horizontal resize %s'):format(size)) end
            )
        end
    end
end

---Changes the window position to a different valid position
---@param position "float"|"bottom"|"top"|"left"|"right"
---@return boolean true if position changed from old position
---@private
function TerminalWindowManager:set_position(position)
    local old_position = self.position

    self.position = position
    if self:is_valid() then
        vim.w[self.winid].my_terminal_window = {
            id = self.id,
            position = self.position,
        }
    end

    local is_position_changed = old_position ~= position
    return is_position_changed
end

---Shows the window
---@param opts TerminalWindowManagerShowOpts
---@return TerminalWindowManager
function TerminalWindowManager:show(opts)
    opts = opts or {}

    local position = opts.position or self.position
    local enter = opts.enter or opts.enter == nil

    if self:set_position(position) then
        --temporarily close the window so that it can be re-positioned
        --There is a stupid edge case where if I try to reposition but the terminal
        --window is the last window in the tab. This will end up creating a new
        --window. I think thats an ok way to handle it
        self:close({
            prevent_exit = true,
            debug_source = 'repositioning with show',
        })
    end

    if self:is_valid() then return self end

    self.augroup = vim.api.nvim_create_augroup(
        'my_terminal_window_' .. self.id,
        { clear = true }
    )

    local win_config = self:create_win_config_for_position(self.position)

    self.winid =
        vim.api.nvim_open_win(self.buffer_manager.bufnr, enter, win_config)

    if enter then vim.api.nvim_set_current_win(self.winid) end

    if
        self.start_insert
        and vim.api.nvim_get_current_buf() == self.buffer_manager.bufnr
    then
        vim.cmd.startinsert()
    end

    if self.position == 'left' or self.position == 'right' then
        vim.wo[self.winid].winfixheight = true
        vim.wo[self.winid].winfixwidth = false
    elseif self.position == 'bottom' or self.position == 'top' then
        vim.wo[self.winid].winfixheight = false
        vim.wo[self.winid].winfixwidth = true
    end

    vim.schedule(function() self:equalize() end)

    vim.w[self.winid].my_terminal_window = {
        id = self.id,
        position = self.position,
    }

    if self.auto_close then
        vim.api.nvim_create_autocmd('TermClose', {
            group = self.augroup,
            callback = function()
                if type(vim.v.event) == 'table' and vim.v.event.status ~= 0 then
                    vim.notify(
                        'Terminal exited with code '
                            .. vim.v.event.status
                            .. '.\nCheck for any errors.',
                        vim.log.levels.ERROR
                    )
                    return
                end
                self:close({ prevent_exit = true, debug_source = 'TermClose' })
            end,
            buffer = self.buffer_manager.bufnr,
        })
    end

    vim.api.nvim_create_autocmd('BufWipeout', {
        group = self.augroup,
        callback = function()
            vim.schedule(
                --Scheduled since this is more of a last resort in case the terminals managers
                --BufWipeout autocmd failed to close the window.
                function()
                    self:close({
                        prevent_exit = true,
                        debug_source = 'BufWipeout',
                    })
                end
            )
        end,
        buffer = self.buffer_manager.bufnr,
    })

    vim.api.nvim_create_autocmd('VimLeavePre', {
        group = self.augroup,
        callback = function()
            self:close({ prevent_exit = false, debug_source = 'VimLeavePre' })
        end,
    })

    vim.api.nvim_create_autocmd('WinClosed', {
        group = self.augroup,
        callback = function()
            if vim.api.nvim_get_current_win() == self.winid then
                pcall(vim.cmd.wincmd, 'p')
            end
        end,
        pattern = self.winid .. '',
    })

    -- swap buffers when opening a new buffer in the same window
    vim.api.nvim_create_autocmd('BufWinEnter', {
        group = self.augroup,
        nested = true,
        callback = function()
            --We schedule this so that the code that triggers the buf change
            --doesn't error because we change the current buffer out from under it
            --Unfortunately, scheduling can cause flickering since the non-terminal
            --buffer finishes the redraw on the terminal window before switching
            --back to the terminal buffer
            return vim.schedule(function() self:fixbuf() end)
        end,
    })

    return self
end

---Picks a window to redirect buffer changes to
---@private
function TerminalWindowManager:fixbuf()
    if not self:is_open() then return end

    local dest_bufnr = vim.api.nvim_win_get_buf(self.winid)

    -- We don't need to do anything if we swap to the same buffer
    if dest_bufnr == self.buffer_manager.bufnr then return end

    -- Find another window to swap to
    local dest_winid ---@type number?
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(self.tabid)) do
        local win_bufnr = vim.api.nvim_win_get_buf(winid)
        local is_float = vim.api.nvim_win_get_config(winid).zindex ~= nil
        if win_bufnr == dest_bufnr and winid ~= self.winid then
            dest_winid = winid
            break
        elseif
            dest_winid == nil
            and winid ~= self.winid
            and vim.api.nvim_win_is_valid(winid)
            and not is_float
            and vim.bo[win_bufnr].buftype == ''
        then
            dest_winid = winid
        end
    end

    if dest_winid ~= nil then
        vim.api.nvim_win_set_buf(self.winid, self.buffer_manager.bufnr)
        vim.api.nvim_win_set_buf(dest_winid, dest_bufnr)
        vim.api.nvim_set_current_win(dest_winid)
        vim.cmd.stopinsert()
    else
        vim.api.nvim_win_call(self.winid, function()
            vim.cmd.stopinsert()

            local win_config = {
                split = 'above',
                win = -1,
            }
            if self.position == 'top' then
                win_config.split = 'below'
            elseif self.position == 'right' then
                win_config.split = 'left'
            elseif self.position == 'bottom' then
                win_config.split = 'above'
            elseif self.position == 'left' then
                win_config.split = 'right'
            end

            vim.api.nvim_open_win(dest_bufnr, true, win_config)

            vim.api.nvim_win_set_buf(self.winid, self.buffer_manager.bufnr)
        end)
    end
end

---Check if the window is currently floating
---@return boolean
function TerminalWindowManager:is_floating()
    return self:is_valid()
        and vim.api.nvim_win_get_config(self.winid).zindex ~= nil
end

---@private
---@param position "float"|"bottom"|"top"|"left"|"right" a position the window will be created at
---@return vim.api.keyset.win_config
function TerminalWindowManager:create_win_config_for_position(position)
    local height = position == 'float' and 0.9 or 0.4
    height = math.floor(vim.o.lines * height)
    height = math.max(height, 1)
    height = math.min(height, vim.o.lines)
    height = math.max(height, 1)

    local width = position == 'float' and 0.9 or 0.4
    width = math.floor(width * vim.o.columns)
    width = math.max(width, 1)
    width = math.min(width, vim.o.columns)
    width = math.max(width, 1)

    if position == 'float' then
        ---@type vim.api.keyset.win_config
        return {
            zindex = 50,
            relative = 'editor',
            height = height,
            width = width,
            row = math.floor((vim.o.lines - height) / 2),
            col = math.floor((vim.o.columns - width) / 2),
        }
    end

    local parent_winid = 0
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(self.tabid)) do
        if
            vim.w[winid].my_terminal_window
            and vim.w[winid].my_terminal_window.position == self.position
        then
            parent_winid = winid
            break
        end
    end

    if
        parent_winid ~= 0
        and (self.position == 'left' or self.position == 'right')
    then
        ---@type vim.api.keyset.win_config
        return {
            height = height,
            split = 'below',
            win = parent_winid,
        }
    elseif parent_winid ~= 0 then
        return {
            width = width,
            split = 'right',
            win = parent_winid,
        }
    elseif self.position == 'top' then
        return {
            height = height,
            split = 'above',
            win = -1,
        }
    elseif self.position == 'right' then
        return {
            width = width,
            split = 'right',
            win = -1,
        }
    elseif self.position == 'bottom' then
        return {
            height = height,
            split = 'below',
            win = -1,
        }
    elseif self.position == 'left' then
        return {
            width = width,
            split = 'left',
            win = -1,
        }
    else
        vim.notify(
            'Invalid teriminal window position. This should not happen',
            vim.log.levels.ERROR
        )
        return {
            height = height,
            split = 'below',
            win = -1,
        }
    end
end

---Checks if the buffer is valid
---@return boolean
function TerminalWindowManager:buf_valid()
    return self.buffer_manager.bufnr
            and vim.api.nvim_buf_is_valid(self.buffer_manager.bufnr)
        or false
end

---Checks if the window is open
---@return boolean
function TerminalWindowManager:is_open()
    return self.winid and vim.api.nvim_win_is_valid(self.winid) or false
end

---Checks if the window manager is still valid
---@return boolean
function TerminalWindowManager:is_valid()
    return vim.api.nvim_tabpage_is_valid(self.tabid)
        and self:is_open()
        and self:buf_valid()
        and vim.api.nvim_win_get_buf(self.winid)
            == self.buffer_manager.bufnr
end

return M
