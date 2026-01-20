--source: https://github.com/rockyzhang24/dotfiles/blob/master/.config/nvim/lua/rockyz/lsp/progress.lua
--
local M = {}

-- Buffer number and window id for the floating window
---@type integer?
local winid
local spinner = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' }
local idx = 0
-- Progress is done or not
local isDone = true

---@type integer
local progress_bufnr

local function get_progress_bufnr()
    if
        progress_bufnr == nil or not vim.api.nvim_buf_is_valid(progress_bufnr)
    then
        progress_bufnr = vim.api.nvim_create_buf(false, true)
    end
    return progress_bufnr
end

-- Get the progress message for all clients. The format is
-- "65%: [lua_ls] Loading Workspace: 123/1500 | [client2] xxx | [client3] xxx"
local function get_lsp_progress_msg()
    -- Most code is grabbed from the source of vim.lsp.status()
    -- Ref: https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp.lua
    local percentage = nil
    local all_messages = {}
    isDone = true
    for _, client in ipairs(vim.lsp.get_clients()) do
        local messages = {}
        for progress in client.progress do
            local value = progress.value
            if type(value) == 'table' and value.kind then
                if value.kind ~= 'end' then isDone = false end
                local message = value.message
                        and (value.title .. ': ' .. value.message)
                    or value.title
                messages[#messages + 1] = message
                if value.percentage then
                    percentage = math.max(percentage or 0, value.percentage)
                end
            end
        end
        if next(messages) ~= nil then
            table.insert(
                all_messages,
                '[' .. client.name .. '] ' .. table.concat(messages, ', ')
            )
        end
    end
    local message = table.concat(all_messages, ' | ')
    -- Show percentage
    if percentage then
        message = string.format('%3d%%: %s', percentage, message)
    end
    -- Show spinner
    idx = idx == #spinner * 4 and 1 or idx + 1
    message = spinner[math.ceil(idx / 4)] .. message
    return message
end

local function log_progress_display_vars()
    ---@type integer | string
    local display_winid
    if winid == nil then
        display_winid = 'nil'
    else
        display_winid = winid
    end
    local progress_tabpage = nil
    if winid ~= nil and vim.api.nvim_win_is_valid(winid) then
        progress_tabpage = vim.api.nvim_win_get_tabpage(winid)
    end
    local status = {
        progress_bufnr = progress_bufnr,
        progress_winid = display_winid,
        progress_tabpage = progress_tabpage,
        current_tabpage = vim.api.nvim_get_current_tabpage(),
        spinner = spinner,
        idx = idx,
        isDone = isDone,
        progress_message = get_lsp_progress_msg(),
    }
    vim.notify(vim.inspect(status), vim.log.levels.INFO)
end

local function cleanup_old_progress_bar()
    if winid and vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_win_close(winid, true)
    end
    vim.api.nvim_buf_set_lines(get_progress_bufnr(), 0, 1, false, { '' })
    winid = nil
    idx = 0
end

local function create_progress_bar_window_and_buffer(message, win_row)
    winid = vim.api.nvim_open_win(get_progress_bufnr(), false, {
        relative = 'editor',
        width = #message,
        height = 1,
        row = win_row,
        col = vim.o.columns - #message,
        style = 'minimal',
        noautocmd = true,
    })
end

local function update_lsp_progress_display()
    -- The row position of the floating window. Just right above the status line.
    local win_row = vim.o.lines - vim.o.cmdheight - 4
    local message = get_lsp_progress_msg()
    if winid == nil or not vim.api.nvim_win_is_valid(winid) then
        create_progress_bar_window_and_buffer(message, win_row)
    elseif
        vim.api.nvim_win_get_tabpage(winid)
        ~= vim.api.nvim_get_current_tabpage()
    then
        cleanup_old_progress_bar()
        create_progress_bar_window_and_buffer(message, win_row)
    else
        vim.api.nvim_win_set_config(winid, {
            relative = 'editor',
            width = #message,
            row = win_row,
            col = vim.o.columns - #message,
        })
    end
    if winid and vim.api.nvim_win_is_valid(winid) then
        vim.wo[winid].winhl = 'Normal:Normal'
    end
    vim.api.nvim_buf_set_lines(get_progress_bufnr(), 0, 1, false, { message })
    if isDone then cleanup_old_progress_bar() end
end

local is_autocmds_setup = false
function M.enable()
    if is_autocmds_setup then return end
    is_autocmds_setup = true

    vim.api.nvim_create_autocmd({ 'LspProgress' }, {
        pattern = '*',
        group = vim.api.nvim_create_augroup('lsp_progress', { clear = true }),
        callback = update_lsp_progress_display,
    })

    --For debugging
    vim.api.nvim_create_user_command(
        'LspLogProgressDisplayVars',
        log_progress_display_vars,
        { nargs = 0 }
    )
end

return M
