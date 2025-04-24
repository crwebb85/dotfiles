-- yamlls config is based on article https://www.arthurkoziel.com/json-schemas-in-neovim/
local yamlls_cfg = require('yaml-companion').setup({
    -- detect k8s schemas based on file content
    builtin_matchers = {
        kubernetes = { enabled = true },
    },

    -- schemas available in Telescope picker
    -- :Telescope yaml_schema
    -- Catalog of general schemas: https://www.schemastore.org/api/json/catalog.json
    -- Catalog of kubernetes schemas: https://github.com/datreeio/CRDs-catalog/tree/main
    schemas = {
        {
            name = 'Argo CD Application',
            uri = 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/argoproj.io/application_v1alpha1.json',
        },
        {
            name = 'SealedSecret',
            uri = 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/bitnami.com/sealedsecret_v1alpha1.json',
        },
        {
            name = 'Kustomization',
            uri = 'https://json.schemastore.org/kustomization.json',
        },
        {
            name = 'GitHub Workflow',
            uri = 'https://json.schemastore.org/github-workflow.json',
        },
        {
            name = 'Ansible Execution Environment',
            uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/execution-environment.json',
        },
        {
            name = 'Ansible Meta',
            url = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/meta.json',
        },
        {
            name = 'Ansible Meta Runtime',
            uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/meta-runtime.json',
        },
        {
            name = 'Ansible Argument Specs',
            uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/role-arg-spec.json',
        },
        {
            name = 'Ansible Requirements',
            uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/requirements.json',
        },
        {
            name = 'Ansible Vars File',
            uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/vars.json',
        },
        {
            name = 'Ansible Tasks File',
            uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/tasks',
        },
        {
            name = 'Ansible Playbook',
            uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/playbook',
        },
        {
            name = 'Ansible Rulebook',
            uri = 'https://raw.githubusercontent.com/ansible/ansible-rulebook/main/ansible_rulebook/schema/ruleset_schema.json',
        },
        {
            name = 'Ansible Inventory',
            uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/inventory.json',
        },
        {
            name = 'Ansible Collection Galaxy',
            uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/galaxy.json',
        },
        {
            name = 'Ansible-lint Configuration',
            uri = 'https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible-lint-config.json',
        },
        {
            name = 'Ansible Navigator Configuration',
            uri = 'https://raw.githubusercontent.com/ansible/ansible-navigator/main/src/ansible_navigator/data/ansible-navigator.json',
        },
        {
            name = 'OpenAPI 3.0',
            uri = 'https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.0/schema.json',
        },
        {
            name = 'OpenAPI 3.1',
            uri = 'https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json',
        },
        {
            name = 'Swagger API 2.0',
            uri = 'https://json.schemastore.org/swagger-2.0.json',
        },
    },

    lspconfig = {
        settings = {
            yaml = {
                validate = true,
                schemaStore = {
                    enable = false,
                    url = '',
                },

                -- schemas from store, matched by filename
                -- loaded automatically
                -- Catalog of general schemas: https://www.schemastore.org/api/json/catalog.json
                schemas = require('schemastore').yaml.schemas({
                    select = {
                        'kustomization.yaml',
                        'GitHub Workflow',
                        'Ansible Execution Environment',
                        'Ansible Meta',
                        'Ansible Meta Runtime',
                        'Ansible Argument Specs',
                        'Ansible Requirements',
                        'Ansible Vars File',
                        'Ansible Tasks File',
                        'Ansible Playbook',
                        'Ansible Rulebook',
                        'Ansible Inventory',
                        'Ansible Collection Galaxy',
                        'Ansible-lint Configuration',
                        'Ansible Navigator Configuration',
                        'openapi.json',
                        'Swagger API 2.0',
                    },
                }),
            },
        },
    },
})

return yamlls_cfg
