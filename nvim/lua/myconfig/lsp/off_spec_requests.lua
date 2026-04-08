---@class MyYamlSchema
---@field name string
---@field uri string

local M = {}

local sync_timeout = 5000

--TODO jsonls has similar offspec apis and I would also like to fetch the
--name of the selected schema using it.

-- get all known schemas by the yamlls attached to {bufnr}
---@param bufnr number
--- @return {err: lsp.ResponseError?, result:SchemaEntry[]}? `result` and `err` from the |lsp-handler|. `nil` is the request was unsuccessful
--- @return string? err On timeout, cancel or error, where `err` is a string describing the failure reason.
M.yamlls_get_all_jsonschemas = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    local clients = vim.lsp.get_clients({
        bufnr = bufnr,
        name = 'yamlls',
    })
    if #clients < 1 then return end
    local client = clients[1]
    return client:request_sync(
        'yaml/get/all/jsonSchemas',
        { vim.uri_from_bufnr(bufnr) },
        sync_timeout,
        bufnr
    )
end

-- get schema used for {bufnr} from the yamlls attached to it
---@param bufnr number
---@return {result: MyYamlSchema[]} | nil
--- @return {err: lsp.ResponseError?, result:MyYamlSchema[]}? `result` and `err` from the |lsp-handler|. `nil` is the request was unsuccessful
--- @return string? err On timeout, cancel or error, where `err` is a string describing the failure reason.
M.yamlls_get_jsonschema = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    local clients = vim.lsp.get_clients({
        bufnr = bufnr,
        name = 'yamlls',
    })
    if #clients < 1 then return end
    local client = clients[1]
    return client:request_sync(
        'yaml/get/jsonSchema',
        { vim.uri_from_bufnr(bufnr) },
        sync_timeout,
        bufnr
    )
end

---The support schema selection notification is sent from a client to the server to
---inform server that client supports JSON Schema selection.
---@param bufnr number
---@return boolean success
M.yamlls_notify_supports_schema_selection = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    local clients = vim.lsp.get_clients({
        bufnr = bufnr,
        name = 'yamlls',
    })
    if #clients < 1 then return false end
    local client = clients[1]
    return client:notify('yaml/supportSchemaSelection', {})
end

-- The schema store initialized notification is sent from the server to a client
-- to inform client that server has finished initializing/loading schemas from
-- schema store, and client now can ask for schemas.
---@param bufnr number
---@return boolean success
M.yamlls_notify_schema_store_initialized = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    local clients = vim.lsp.get_clients({
        bufnr = bufnr,
        name = 'yamlls',
    })
    if #clients < 1 then return false end
    local client = clients[1]
    return client:notify('yaml/schema/store/initialized', {})
end

return M
