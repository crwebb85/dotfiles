---@type vim.lsp.Config
return {
    bundle_path = require('myconfig.utils.path').get_lsp_powershell_editor_services_bundle_path(),
    -- TODO this doesn't yet work for conform.nvim need to do some more experiments
    -- capabilities = {
    --     -- disable formatter because it is very inconsistent whether it works
    --     -- and I can't stand that it puts the opening curly bracket on a new line
    --     textDocument = {
    --         formatting = {
    --             dynamicRegistration = false,
    --         },
    --         rangeFormatting = {
    --             dynamicRegistration = false,
    --         },
    --     },
    -- },
}
