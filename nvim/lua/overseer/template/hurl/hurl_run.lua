---@type overseer.TemplateFileDefinition
local hurl_template = {
    name = 'Run Hurl',
    builder = require('overseer.template.hurl.hurl').hurl_builder_builder(),

    condition = {
        filetype = { 'hurl' },
    },
}

return hurl_template
