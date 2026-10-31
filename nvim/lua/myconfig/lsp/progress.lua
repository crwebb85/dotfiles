--originally based on source: https://github.com/rockyzhang24/dotfiles/blob/master/.config/nvim/lua/rockyz/lsp/progress.lua
--but since refactored to us ui2 for progress indicator based on https://www.reddit.com/r/neovim/s/oVynbgmxSM

local M = {}

local spinner = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' }
local idx = 0
local message_id = nil

local function display_progress(percent, title, is_running)
    local status = 'success'
    if is_running then status = 'running' end

    idx = idx == #spinner * 4 and 1 or idx + 1
    local i_frame = math.ceil(idx / 4)

    message_id = vim.api.nvim_echo({ { title } }, false, {
        id = message_id,
        percent = percent,
        source = 'lsp-progress',
        status = status,
        title = spinner[i_frame] .. ' LSP',
        kind = 'progress',
    })
end

--- Get the progress information for all clients.
---
---@return integer progress percentage 0 to 100 (uses the max for all clients)
---@return string message for all clients in form `[lua_ls] Loading Workspace: 123/1500 | [client2] xxx | [client3] xxx"`
---@return boolean is_running true if any lsp is has unfinished progress
local function get_lsp_progress_info()
    -- Based on `vim.lsp.status()`
    -- https://github.com/neovim/neovim/blob/cc917b90adf3f32c76dc7338396435d0416bd200/runtime/lua/vim/lsp.lua#L806
    -- but the return type is changed to reflect what my progress indicator requires
    -- and switched to using min of all percentages instead of max
    local percentage = 100
    local all_messages = {}
    local is_done = true
    for _, client in ipairs(vim.lsp.get_clients()) do
        local messages = {}
        for progress in client.progress do
            local value = progress.value
            if type(value) == 'table' and value.kind then
                if value.kind ~= 'end' then is_done = false end
                local message = value.message
                        and (value.title .. ': ' .. value.message)
                    or value.title
                messages[#messages + 1] = message
                if value.percentage ~= nil and value.percentage > 0 then
                    percentage = math.min(percentage, value.percentage)
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
    local is_running = not is_done
    if is_running and percentage >= 100 then percentage = 0 end
    return percentage, message, is_running
end

local function update_lsp_progress_display(_)
    local percentage, message, is_running = get_lsp_progress_info()

    -- I'm not using the autocmd args to build the progress message
    -- since I want to construct the progress from all LSPs. However, this
    -- commented snippet is how you get the values from the autocmd args.
    --
    -- local value = args.data.params.value
    -- if value == nil then return end
    -- local title = value.title
    -- local percent = value.percentage or 0

    display_progress(percentage, message, is_running)
end

local is_autocmds_setup = false
function M.enable()
    if not require('myconfig.config').use_ui2 then
        vim.notify(
            'LSP progress is build on ui2 and cannot be used when ui2 is disabled',
            vim.log.levels.WARN
        )
    end
    if is_autocmds_setup then return end
    is_autocmds_setup = true

    vim.api.nvim_create_autocmd({ 'LspProgress' }, {
        pattern = '*',
        group = vim.api.nvim_create_augroup('lsp_progress', { clear = true }),
        callback = update_lsp_progress_display,
    })
end

return M
