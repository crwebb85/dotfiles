---This is based on https://github.com/someone-stole-my-name/yaml-companion.nvim/blob/131b0d67bd2e0f1a02e0daf2f3460482221ce3c0/lua/telescope/_extensions/yaml_schema_builtin.lua
---which got archived

--- gets or sets the schema in its context and lsp
---@param bufnr number
---@param new_schema MyYamlSchema | nil
local function set_schema(bufnr, new_schema)
    --Note: for this to work you also need to run the `yaml/supportSchemaSelection`
    --lsp notification to tell yamlls that we may select a schema. I do this in my
    --lsp attach autocmd.
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    if new_schema and new_schema.uri and new_schema.name then
        vim.b[bufnr].yaml_schema = new_schema

        local bufuri = vim.uri_from_bufnr(bufnr)

        local clients = vim.lsp.get_clients({
            bufnr = bufnr,
            name = 'yamlls',
        })
        if #clients < 1 then return end
        local client = clients[1]
        local settings = client.settings

        -- we don't want more than 1 schema per file
        -- Note: this is wierd and I think it may have issues
        -- when using more than one yaml file
        for key, _ in pairs(settings.yaml.schemas) do
            if settings.yaml.schemas[key] == bufuri then
                settings.yaml.schemas[key] = nil
            end
        end

        local override = {}
        override[new_schema.uri] = bufuri

        vim.notify(
            string.format(
                'file=%s schema=%s set new override',
                bufuri,
                new_schema.uri
            ),
            vim.log.levels.INFO
        )

        settings = vim.tbl_deep_extend(
            'force',
            settings,
            { yaml = { schemas = override } }
        )
        client.settings = vim.tbl_deep_extend(
            'force',
            settings,
            { yaml = { schemas = override } }
        )

        client:notify(
            vim.lsp.protocol.Methods.workspace_didChangeConfiguration,
            {
                settings = client.settings,
            }
        )
    end
end

---@return MyYamlSchema[]
local function get_schemas()
    local r = {}
    --schemastore strangely usees the .json.schemas() function to return the master
    --list of schemas which includes the schema name. Strangely .yaml.schemas()
    --does not have the schema name
    for _, schema in ipairs(require('schemastore').json.schemas()) do
        table.insert(r, { name = schema.name, uri = schema.url })
    end
    return r
end

return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        yaml_schema = function(_)
            local opts = require('telescope.themes').get_dropdown({})

            local conf = require('telescope.config').values

            require('telescope.pickers')
                .new(opts, {
                    prompt_title = 'Schema',
                    finder = require('telescope.finders').new_table({
                        results = get_schemas(),
                        entry_maker = function(entry)
                            return {
                                value = entry,
                                display = entry.name,
                                ordinal = entry.name,
                            }
                        end,
                    }),
                    sorter = conf.generic_sorter(opts),
                    attach_mappings = function(prompt_bufnr, _)
                        require('telescope.actions').select_default:replace(
                            function()
                                require('telescope.actions').close(prompt_bufnr)
                                local selection = require(
                                    'telescope.actions.state'
                                ).get_selected_entry()
                                local schema = {
                                    name = selection.value.name,
                                    uri = selection.value.uri,
                                }
                                set_schema(0, schema)
                            end
                        )
                        return true
                    end,
                })
                :find()
        end,
    },
})
