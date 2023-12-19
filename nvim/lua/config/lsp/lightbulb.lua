--source https://github.com/rockyzhang24/dotfiles/blob/master/.config/nvim/lua/rockyz/lsp/lightbulb.lua
local M = {}

function M.get_diagnostic_at_cursor()
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
local bulb_bufnr = nil
local prev_lnum = nil
local prev_topline_num = nil
local prev_bufnr = nil
local code_action_support = false

function M.remove_bulb()
    if bulb_bufnr ~= nil and vim.fn.getcmdwintype() ~= '' then
        --Since we can't delete buffers while the command-window is open we have to schedule
        --The cleanup till after the command-window is closed
        vim.api.nvim_create_autocmd({ 'CmdwinLeave' }, {
            group = vim.api.nvim_create_augroup('CleanupLightbulb', {
                clear = true,
            }),
            callback = function()
                vim.api.nvim_create_autocmd({ 'BufEnter' }, {
                    group = vim.api.nvim_create_augroup('CleanupLightbulb', {
                        clear = true,
                    }),
                    callback = function()
                        vim.cmd(('noautocmd bwipeout %d'):format(bulb_bufnr))
                        bulb_bufnr = nil
                    end,
                    once = true,
                })
            end,
            once = true,
        })
        --Early return since we can't cleanup until the command-window is closed
        return
    elseif bulb_bufnr ~= nil then
        vim.cmd(('noautocmd bwipeout %d'):format(bulb_bufnr))
        bulb_bufnr = nil
    end
end

function M.show_lightbulb()
    -- Check if the method textDocument/codeAction is supported
    local cur_bufnr = vim.api.nvim_get_current_buf()
    if cur_bufnr ~= prev_bufnr then -- when entering to another buffer
        prev_bufnr = cur_bufnr
        code_action_support = false
    end
    if code_action_support == false then
        for _, client in pairs(vim.lsp.get_clients({ bufnr = cur_bufnr })) do
            if client then
                if client.supports_method('textDocument/codeAction') then
                    code_action_support = true
                end
            end
        end
    end
    if code_action_support == false then
        M.remove_bulb()
        return
    end
    local context = {
        -- Get the diagnostics at the cursor
        diagnostics = M.get_diagnostic_at_cursor(),
    }
    local params = vim.lsp.util.make_range_params()
    params.context = context
    -- Send request to the server to check if a code action is available at the
    -- cursor
    vim.lsp.buf_request_all(
        0,
        'textDocument/codeAction',
        params,
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
                    and bulb_bufnr ~= nil
                then
                    return
                end
                -- Remove the old bulb if necessary, and then create a new bulb
                M.remove_bulb()
                prev_lnum = cur_lnum
                prev_topline_num = cur_topline_num
                local icon = ''
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
                bulb_bufnr = vim.api.nvim_create_buf(false, true)
                local winid = vim.api.nvim_open_win(bulb_bufnr, false, {
                    relative = 'cursor',
                    width = 1,
                    height = 1,
                    row = row,
                    col = col,
                    style = 'minimal',
                    noautocmd = true,
                })
                vim.wo[winid].winhl = 'Normal:LightBulb'
                vim.api.nvim_buf_set_lines(bulb_bufnr, 0, 1, false, { icon })
                return
            end
            -- If no actions, remove the bulb if it is existing
            if has_actions == false then M.remove_bulb() end
        end
    )
end

return M
