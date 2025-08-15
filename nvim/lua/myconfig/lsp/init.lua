require('myconfig.lsp.lsp').enable()

vim.lsp.config('*', {
    capabilities = require('myconfig.lsp.lsp').get_additional_default_capabilities(),
})
