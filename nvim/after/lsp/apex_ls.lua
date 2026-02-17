vim.lsp.config('apex_ls', {
    apex_jar_path = vim.fn.stdpath('data')
        .. '/mason/share/apex-language-server/apex-jorje-lsp.jar',
})
