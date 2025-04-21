--source https://github.com/rockyzhang24/dotfiles/blob/master/.config/nvim/lua/rockyz/lsp/lightbulb.lua
local M = {}

local function get_diagnostic_at_cursor()
    local cur_bufnr = vim.api.nvim_get_current_buf()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0)) -- line is 1-based indexing
    -- Get a table of diagnostics at the current line. The structure of the
    -- diagnostic item is defined by nvim (see :h diagnostic-structure) to
    -- describe the information of a diagnostic.
    local diagnostics = vim.diagnostic.get(cur_bufnr, { lnum = line - 1 }) -- lnum is 0-based indexing
    -- Filter out the diagnostics at the cursor position. And then use each to
    -- build a LSP Diagnostic (see
    -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#diagnostic)
    local lsp_diagnostics = {}
    for _, diag in pairs(diagnostics) do
        if diag.col <= col and diag.end_col >= col then
            table.insert(lsp_diagnostics, {
                range = {
                    ['start'] = {
                        line = diag.lnum,
                        character = diag.col,
                    },
                    ['end'] = {
                        line = diag.end_lnum,
                        character = diag.end_col,
                    },
                },
                severity = diag.severity,
                code = diag.code,
                source = diag.source or nil,
                message = diag.message,
            })
        end
    end
    return lsp_diagnostics
end
--
-- Show a lightbulb when code actions are available at the cursor
--
-- It is shown at the beginning (the first column) of the same line, or the
-- previous line if the space is not enough.
--
local prev_lnum = nil
local prev_topline_num = nil
local lightbulb_bufnr = nil
local lightbulb_winid = nil

local function get_lightbulb_bufnr()
    if
        lightbulb_bufnr == nil or not vim.api.nvim_buf_is_valid(lightbulb_bufnr)
    then
        lightbulb_bufnr = vim.api.nvim_create_buf(false, true)
        local icon = ''
        vim.api.nvim_buf_set_lines(lightbulb_bufnr, 0, 1, false, { icon })
    end
    return lightbulb_bufnr
end

local function remove_lightbulb()
    if lightbulb_winid ~= nil then
        vim.api.nvim_win_close(lightbulb_winid, true)
        lightbulb_winid = nil
    end
end

local function draw_lightbulb()
    -- Avoid bulb icon flashing when move the cursor in a line
    --
    -- When code actions are available in different positions within a line,
    -- the bulb will be shown in the same place, so no need to remove the
    -- previous bulb and create a new one.
    -- Check if the first line of the screen is changed in order to update the
    -- bulb when scroll the window (e.g., C-y, C-e, zz, etc)
    local cur_lnum = vim.fn.line('.')
    local cur_topline_num = vim.fn.line('w0')
    if
        cur_lnum == prev_lnum
        and cur_topline_num == prev_topline_num
        and (
            lightbulb_winid ~= nil
            and vim.api.nvim_win_is_valid(lightbulb_winid)
            and vim.api.nvim_win_get_tabpage(lightbulb_winid)
                == vim.api.nvim_get_current_tabpage()
        )
    then
        return
    end
    -- Remove the old bulb in preparation for re-positioning
    remove_lightbulb()
    prev_lnum = cur_lnum
    prev_topline_num = cur_topline_num
    -- Calculate the row position of the lightbulb relative to the cursor
    local row = 0
    local line_number = vim.fn.line('.') or 0
    local cur_indent = vim.fn.indent(line_number)
    if cur_indent <= 2 then
        if vim.fn.line('.') == vim.fn.line('w0') then
            row = 1
        else
            row = -1
        end
    end
    -- Calculate the col position of the lightbulb relative to the cursor
    --
    -- NOTE: We want to get how many columns (characters) before the cursor
    -- that will be the offset for placing the bulb. If the indent is TAB,
    -- each indent level is counted as a single one character no matter how
    -- many spaces the TAB has. We need to convert it to the number of spaces.
    local cursor_col = vim.fn.col('.')
    local col = -cursor_col + 1
    if not vim.api.nvim_get_option_value('expandtab', {}) then
        local tabstop = vim.api.nvim_get_option_value('tabstop', {})
        local tab_cnt = cur_indent / tabstop
        if cursor_col <= tab_cnt then
            col = -(cursor_col - 1) * tabstop
        else
            col = -(cursor_col - tab_cnt + cur_indent) + 1
        end
    end

    local new_lightbulb_winid =
        vim.api.nvim_open_win(get_lightbulb_bufnr(), false, {
            relative = 'cursor',
            width = 1,
            height = 1,
            row = row,
            col = col,
            style = 'minimal',
            noautocmd = true,
            border = 'none',
        })

    if
        lightbulb_winid ~= nil and vim.api.nvim_win_is_valid(lightbulb_winid)
    then
        vim.notify(
            'Created a new lightbulb with winid '
                .. vim.inspect(new_lightbulb_winid)
                .. ' when previous lightbulb with winid '
                .. vim.inspect(lightbulb_winid)
                .. ' has not yet been closed',
            vim.log.levels.ERROR
        )
    end

    vim.wo[new_lightbulb_winid].winhl = 'Normal:LightBulb'
    lightbulb_winid = new_lightbulb_winid
end

local function show_lightbulb()
    -- Check if the method textDocument/codeAction is supported
    local cur_bufnr = vim.api.nvim_get_current_buf()

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
        ---@type fun(client: vim.lsp.Client, bufnr: integer): table?
        function(client, _)
            local win = 0 --I can imagine this could cause race conditions but lets see how this goes

            local params =
                vim.lsp.util.make_range_params(win, client.offset_encoding)

            return {
                context = {
                    diagnostics = get_diagnostic_at_cursor(),
                },
                textDocument = params.textDocument,
                range = params.range,
            }
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
            if has_actions then draw_lightbulb() end
            -- If no actions, remove the bulb if it is existing
            if has_actions == false then remove_lightbulb() end
        end
    )
end

local is_enabled = false
function M.enable()
    if is_enabled then return end

    local augroup_lsp_lightbulb =
        vim.api.nvim_create_augroup('lsp_lightbulb', { clear = true })

    -- Show a lightbulb when code actions are available at the cursor position
    vim.api.nvim_create_autocmd({
        'BufEnter',
        'CursorHold',
        'CursorHoldI',
        'WinScrolled',
        'LspAttach',
        'LspDetach',
    }, {
        group = augroup_lsp_lightbulb,
        callback = show_lightbulb,
    })

    vim.api.nvim_create_autocmd({ 'BufLeave' }, {
        group = augroup_lsp_lightbulb,
        callback = remove_lightbulb,
    })
end

return M
