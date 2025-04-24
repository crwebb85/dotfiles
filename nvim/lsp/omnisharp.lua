local pid = vim.fn.getpid()
return {
    cmd = {
        require('utils.path').get_mason_tool_path('omnisharp'),
        '--languageserver',
        '--hostPID',
        tostring(pid),
    },
}
