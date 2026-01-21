return {
    cmd = {
        require('myconfig.utils.path').get_mason_tool_path('omnisharp'),
        '-z', -- https://github.com/OmniSharp/omnisharp-vscode/pull/4300
        '--hostPID',
        tostring(vim.fn.getpid()),
        'DotNet:enablePackageRestore=false',
        '--encoding',
        'utf-8',
        '--languageserver',
    },
    root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local util = require('lspconfig.util')
        local root = util.root_pattern('*.sln')(fname)
            or util.root_pattern('*.csproj')(fname)
            or util.root_pattern('omnisharp.json')(fname)
            or util.root_pattern('function.json')(fname)

        root = root:gsub('/', '\\')
        on_dir(root)
    end,
}
