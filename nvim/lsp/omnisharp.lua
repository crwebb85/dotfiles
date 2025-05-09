return {
    cmd = {
        require('utils.path').get_mason_tool_path('omnisharp'),
        '-z', -- https://github.com/OmniSharp/omnisharp-vscode/pull/4300
        '--hostPID',
        tostring(vim.fn.getpid()),
        'DotNet:enablePackageRestore=false',
        '--encoding',
        'utf-8',
        '--languageserver',
    },
}
