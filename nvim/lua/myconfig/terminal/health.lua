local M = {}
M.check = function()
    vim.health.start('My Terminal Manager')
    local all_terminals = require('myconfig.terminal.terminal').list(
        function(_) return true end
    )
    for _, terminal in pairs(all_terminals) do
        vim.health.start('Terminal:')
        vim.health.info('id: ' .. terminal:get_id())
        if terminal:buf_valid() then
            vim.health.ok('bufnr: ' .. terminal:get_bufnr())
        else
            vim.health.error(
                'bufnr: '
                    .. terminal:get_bufnr()
                    .. ' (invalid bufnr implying the terminal did not get cleaned up properly)'
            )
        end

        for tabid, window_manager in pairs(terminal.window_managers) do
            local open_text = window_manager:is_open() and 'Window open'
                or 'Window closed'
            if vim.api.nvim_tabpage_is_valid(tabid) then
                vim.health.ok(
                    open_text
                        .. '\n    tabid: '
                        .. tabid
                        .. '\n    winid: '
                        .. (window_manager.winid or 'nil')
                        .. '\n    position: '
                        .. window_manager.position
                        .. '\n    augroup: '
                        .. (window_manager.augroup or 'nil')
                )
            else
                local winid_text = (window_manager.winid or 'nil')
                    .. (window_manager:is_valid() and '' or ' (invalid)')
                vim.health.error(
                    'Window manager did not get cleaned up for tab'
                        .. '\n    tabid: '
                        .. tabid
                        .. '\n    winid: '
                        .. winid_text
                        .. '\n    position: '
                        .. window_manager.position
                        .. '\n    augroup: '
                        .. (window_manager.augroup or 'nil')
                )
            end
        end
    end
end

return M
