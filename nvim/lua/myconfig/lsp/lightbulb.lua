--originally based on https://github.com/rockyzhang24/dotfiles/blob/master/.config/nvim/lua/rockyz/lsp/lightbulb.lua
--but this code no longer resembles it.
local M = {}

local LIGHTBULB_NS = vim.api.nvim_create_namespace('my-lightbulb')

---@type integer?
local lightbulb_bufnr = nil
---@type integer?
local lightbulb_extmark_id = nil

local function remove_lightbulb()
    if
        lightbulb_bufnr ~= nil
        and vim.api.nvim_buf_is_valid(lightbulb_bufnr)
        and lightbulb_extmark_id ~= nil
    then
        vim.api.nvim_buf_del_extmark(
            lightbulb_bufnr,
            LIGHTBULB_NS,
            lightbulb_extmark_id
        )
    end
end

---draws the lightbulb at the position
---@param position [integer, integer] # (row, col) tuple
---@param bufnr integer the current buffer
local function draw_lightbulb(position, bufnr)
    if
        bufnr ~= lightbulb_bufnr
        and bufnr ~= nil
        and vim.api.nvim_buf_is_valid(bufnr)
    then
        remove_lightbulb()
        lightbulb_bufnr = bufnr
    end
    if bufnr == nil or not vim.api.nvim_buf_is_valid(bufnr) then return end

    ---@type vim.api.keyset.set_extmark
    local extmark_opts = {
        id = lightbulb_extmark_id,
        priority = 10,
        strict = false, -- prevent errors if empty buffer
        sign_text = '',
        sign_hl_group = 'LightBulbSign',
        number_hl_group = 'LightBulbNumber',
    }
    local line, col = unpack(position)
    lightbulb_extmark_id = vim.api.nvim_buf_set_extmark(
        bufnr,
        LIGHTBULB_NS,
        line - 1,
        col + 1,
        extmark_opts
    )
end

---Copied from rom runtime/lua/vim/lsp/buf.lua
---@param bufnr integer
---@param mode "v"|"V"
---@return table {start={row,col}, end={row,col}} using (1, 0) indexing
local function range_from_selection(bufnr, mode)
    -- TODO: Use `vim.fn.getregionpos()` instead.

    -- [bufnum, lnum, col, off]; both row and column 1-indexed
    local start = vim.fn.getpos('v')
    local end_ = vim.fn.getpos('.')
    local start_row = start[2]
    local start_col = start[3]
    local end_row = end_[2]
    local end_col = end_[3]

    -- A user can start visual selection at the end and move backwards
    -- Normalize the range to start < end
    if start_row == end_row and end_col < start_col then
        end_col, start_col = start_col, end_col --- @type integer, integer
    elseif end_row < start_row then
        start_row, end_row = end_row, start_row --- @type integer, integer
        start_col, end_col = end_col, start_col --- @type integer, integer
    end
    if mode == 'V' then
        start_col = 1
        local lines =
            vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, true)
        end_col = #lines[1]
    end
    return {
        ['start'] = { start_row, start_col - 1 },
        ['end'] = { end_row, end_col - 1 },
    }
end

local function refresh_lightbulb()
    -- Check if the method textDocument/codeAction is supported
    local cur_bufnr = vim.api.nvim_get_current_buf()

    local position = vim.api.nvim_win_get_cursor(0) -- line is 1-based indexing

    local clients = vim.lsp.get_clients({
        bufnr = cur_bufnr,
        method = vim.lsp.protocol.Methods.textDocument_codeAction,
    })
    if #clients <= 0 then
        remove_lightbulb()
        return
    end

    vim.lsp.buf_request_all(
        cur_bufnr,
        vim.lsp.protocol.Methods.textDocument_codeAction,
        function(client, _)
            --Used same logic for creating paramaters as vim.lsp.buf.code_action
            --in runtime/lua/vim/lsp/buf.lua
            local mode = vim.api.nvim_get_mode().mode
            local win = vim.api.nvim_get_current_win()
            local bufnr = vim.api.nvim_get_current_buf()

            local params

            if mode == 'v' or mode == 'V' then
                local range = range_from_selection(bufnr, mode)
                params = vim.lsp.util.make_given_range_params(
                    range.start,
                    range['end'],
                    bufnr,
                    client.offset_encoding
                )
            else
                params =
                    vim.lsp.util.make_range_params(win, client.offset_encoding)
            end

            local ns_push = vim.lsp.diagnostic.get_namespace(client.id, false)
            local ns_pull = vim.lsp.diagnostic.get_namespace(client.id, true)
            local diagnostics = {}
            local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
            vim.list_extend(
                diagnostics,
                vim.diagnostic.get(bufnr, { namespace = ns_pull, lnum = lnum })
            )
            vim.list_extend(
                diagnostics,
                vim.diagnostic.get(bufnr, { namespace = ns_push, lnum = lnum })
            )

            ---@diagnostic disable-next-line: inject-field
            params.context = {
                ---@diagnostic disable-next-line: no-unknown
                diagnostics = vim.tbl_map(
                    function(d) return d.user_data.lsp end,
                    diagnostics
                ),
            }

            return params
        end,
        function(results)
            local has_actions = false
            for _, result in pairs(results) do
                for _, action in pairs(result.result or {}) do
                    if action then
                        has_actions = true
                        break
                    end
                end
            end
            if has_actions then
                draw_lightbulb(position, cur_bufnr)
            else
                remove_lightbulb()
            end
        end
    )
end

-- If I ever modify the code to enable/disable I will probably also
-- need to close the timer or I may have a memory leak.
local refresh_timer

local throttled_refresh_lightbulb
local is_autocmds_setup = false
function M.enable()
    if is_autocmds_setup then return end
    is_autocmds_setup = true

    if throttled_refresh_lightbulb == nil then
        local throttle = require('myconfig.utils.timers').throttle
        throttled_refresh_lightbulb, refresh_timer =
            throttle(refresh_lightbulb, 30)
    end

    local augroup_lsp_lightbulb =
        vim.api.nvim_create_augroup('lsp_lightbulb', { clear = true })

    -- Show a lightbulb when code actions are available at the cursor position
    vim.api.nvim_create_autocmd({
        'BufEnter',
        'CursorHold',
        'CursorHoldI',
        'LspAttach',
        'LspDetach',
    }, {
        group = augroup_lsp_lightbulb,
        callback = throttled_refresh_lightbulb,
    })

    vim.api.nvim_create_autocmd({ 'BufLeave' }, {
        group = augroup_lsp_lightbulb,
        callback = remove_lightbulb,
    })
end

return M
