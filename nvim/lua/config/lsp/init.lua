require('config.lsp.lsp').enable()

vim.lsp.config('*', {
    capabilities = require('config.lsp.lsp').get_additional_default_capabilities(),
})
