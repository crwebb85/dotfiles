---@type overseer.TemplateFileDefinition
local hurl_template = {
    name = 'Run Hurl With Var File',
    builder = require('overseer.template.hurl.hurl').hurl_builder_builder({
        get_var_file_callback = function()
            return vim.fn.input(
                'Path to var_file: ',
                vim.fn.getcwd() .. '/',
                'file'
            )
        end,
    }),

    condition = {
        filetype = { 'hurl' },
    },
}

return hurl_template
