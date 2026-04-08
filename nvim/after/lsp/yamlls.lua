---@type vim.lsp.Config
return {
    ---@type lspconfig.settings.yamlls
    settings = {
        redhat = {
            telemetry = {
                enabled = false,
            },
        },
        yaml = {
            format = {
                enable = true,
            },
            hover = true,
            schemaDownload = {
                enable = true,
            },
            schemaStore = {
                enable = false,
                url = '',
            },

            -- TODO maybe switch back to using specific ones
            -- schemas from store, matched by filename
            -- loaded automatically
            -- Catalog of general schemas: https://www.schemastore.org/api/json/catalog.json
            -- schemas = require('schemastore').yaml.schemas({
            --     select = {
            --         'kustomization.yaml',
            --         'GitHub Workflow',
            --         'Ansible Execution Environment',
            --         'Ansible Meta',
            --         'Ansible Meta Runtime',
            --         'Ansible Argument Specs',
            --         'Ansible Requirements',
            --         'Ansible Vars File',
            --         'Ansible Tasks File',
            --         'Ansible Playbook',
            --         'Ansible Rulebook',
            --         'Ansible Inventory',
            --         'Ansible Collection Galaxy',
            --         'Ansible-lint Configuration',
            --         'Ansible Navigator Configuration',
            --         'openapi.json',
            --         'Swagger API 2.0',
            --     },
            -- }),

            schemas = require('schemastore').yaml.schemas(),
            validate = true,
        },
    },
}
