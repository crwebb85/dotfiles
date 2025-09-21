---Based on https://github.com/nvim-neotest/neotest/blob/2cf3544fb55cdd428a9a1b7154aea9c9823426e8/lua/neotest/consumers/output.lua
--- Modified to to
--- 1. No longer have the winbar on the floating window

require('neotest') -- Make sure neotest is setup before using this consumer
local nio = require('nio')
local lib = require('neotest.lib')
local config = require('neotest.config')

local win, short_opened

local function open_output(result, opts)
    local output = opts.short and result.short
        or (result.output and lib.files.read(result.output))
    if not output then
        if not opts.quiet then
            lib.notify('Output not found for position', 'warn')
        end
        return
    end
    local buf = nio.api.nvim_create_buf(false, true)

    short_opened = opts.short

    local normalized_output = output:gsub('\r\n', '\n'):gsub('\r', '\n')
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(
        buf,
        0,
        -1,
        false,
        vim.split(normalized_output, '\n')
    )
    vim.bo[buf].modifiable = false

    local lines = nio.api.nvim_buf_get_lines(buf, 0, -1, false)
    local width, height = 80, #lines
    for i, line in ipairs(lines) do
        if i > 500 then
            break -- Don't want to parse very long output
        end
        local line_length = vim.str_utfindex(line, 'utf-8')
        if line_length > width then width = line_length end
    end

    opts.open_win = opts.open_win
        or function(win_opts)
            local float = lib.ui.float.open({
                width = win_opts.width,
                height = win_opts.height,
                buffer = buf,
                auto_close = opts.auto_close,
            })
            return float.win_id
        end

    local cur_win = vim.api.nvim_get_current_win()

    win = opts.open_win({ width = width, height = height })
        or vim.api.nvim_get_current_win()

    vim.api.nvim_win_set_buf(win, buf)

    if opts.enter then
        vim.api.nvim_set_current_win(win)
    elseif cur_win ~= vim.api.nvim_get_current_win() then
        vim.api.nvim_set_current_win(cur_win)
    end

    vim.bo[buf].filetype = 'neotest-output'
    vim.wo[win].winbar = nil
end

local neotest = {}

---@class neotest.consumers.myoutput
---@field open fun(opts?: neotest.consumers.output.OpenArgs)

--- A consumer that displays the output of test results.
-- ---@type neotest.consumers.myoutput
neotest.myoutput = {}

---@private
---@type neotest.Client
local client

local init = function()
    if config.output.open_on_run then
        client.listeners.results = function(_, results)
            if win then return end
            local cur_pos = nio.fn.getpos('.')
            local line = cur_pos[2] - 1
            local buf_path = vim.fn.expand('%:p')
            local positions = client:get_position(buf_path, {})
            if not positions then return end
            for _, node in positions:iter_nodes() do
                local pos = node:data()
                local range = node:closest_value_for('range')
                if
                    pos.type == 'test'
                    and results[pos.id]
                    and results[pos.id].status == 'failed'
                    and range[1] <= line
                    and range[3] >= line
                then
                    open_output(results[pos.id], {
                        short = config.output.open_on_run == 'short',
                        enter = false,
                        quiet = true,
                    })
                end
            end
        end
    end
end

-- -@class neotest.consumers.output.OpenArgs
-- -@field open_win function? Function that takes a table with width and height keys
-- - and opens a window for the output. If a window ID is not returned, the current
-- - window will be used
-- -@field short boolean? Show shortened output
-- -@field enter boolean? Enter output window
-- -@field quiet boolean? Suppress warnings of no output
-- -@field last_run boolean? Open output for last test run
-- -@field position_id string? Open output for position with this ID, opens nearest
-- - position if not given
-- -@field adapter string? Adapter ID, defaults to first found with matching position
-- -@field auto_close boolean? Close output window when leaving it, or when cursor moves outside of window

--- Open the output of a test result
--- ```vim
---   lua require("neotest").myoutput.open({ enter = true })
--- ```
---@param opts? neotest.consumers.output.OpenArgs
function neotest.myoutput.open(opts)
    opts = opts or {}
    if win then
        if opts.short ~= short_opened then
            pcall(vim.api.nvim_win_close, win, true)
        else
            if pcall(vim.api.nvim_set_current_win, win) then return end
            opts.enter = true
        end
    end
    local adapter_id = nil
    local tree
    if opts.last_run then
        local position_id, last_args = require('neotest').run.get_last_run()
        if position_id and last_args then
            tree, adapter_id = client:get_position(
                position_id,
                { adapter = last_args.adapter }
            )
        end
        if not tree then
            lib.notify('Last test run no longer exists')
            return
        end
    elseif not opts.position_id then
        local file_path = vim.fn.expand('%:p')
        local row = vim.fn.getbufinfo(file_path)[1].lnum - 1
        tree, adapter_id =
            client:get_nearest(file_path, row, { adapter = opts.adapter })
    else
        tree, adapter_id =
            client:get_position(opts.position_id, { adapter = opts.adapter })
    end
    if not tree then
        lib.notify('No tests found in file', 'warn')
        return
    end
    if adapter_id == nil then
        lib.notify('Adapter id is nil', 'warn')
        return
    end
    local result = client:get_results(adapter_id)[tree:data().id]
    if not result then
        lib.notify('No output for ' .. tree:data().name)
        return
    end
    open_output(result, opts)
end

neotest.myoutput.open = nio.create(neotest.myoutput.open, 1)

neotest.myoutput = setmetatable(neotest.myoutput, {
    __call = function(_, client_)
        client = client_
        init()
        return neotest.myoutput
    end,
})

return neotest.myoutput
