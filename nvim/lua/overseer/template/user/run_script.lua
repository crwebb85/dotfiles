return {
    name = 'run script',
    builder = function()
        local file = vim.fn.expand('%:p')
        local cmd = { file }
        if vim.bo.filetype == 'go' then
            cmd = { 'go', 'run', file }
        elseif vim.bo.filetype == 'python' then
            --TODO integrate with venv-selector to use the currect virtual environment
            cmd = { 'python', file }
        elseif vim.bo.filetype == 'sh' then
            cmd = { file }
        else
            error('Invalid filetype')
        end
        return {
            cmd = cmd,
            components = {
                { 'on_output_quickfix', set_diagnostics = true },
                'on_result_diagnostics',
                'default',
            },
        }
    end,
    condition = {
        filetype = { 'sh', 'python', 'go' },
    },
}
