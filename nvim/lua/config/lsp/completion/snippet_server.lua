local M = {}

---@type {[string]: lsp.CompletionItem[] }
local completion_cache_by_filetype = {}

---@type {[uinteger]: lsp.CompletionItem }
local completion_by_snip_id = {}

function M.clear_cache()
    completion_cache_by_filetype = {}
    completion_by_snip_id = {}
end

local DOC_TEMPLATE = [[
${name} _ `[${filetype}]`
---
${description}

```${filetype}
${codeblock}
```
]]

local function interpolate(s, items)
    return string.gsub(s, '${(%w+)}', function(n) return items[n] end)
end

local function build_snip_documentation(snip, data)
    ---@type string|string[]
    local codeblock = snip:get_docstring() or ''
    if type(codeblock) == 'table' then
        codeblock = vim.fn.join(codeblock, '\n')
    end

    ---@type string|string[]
    local description = snip.dscr or ''
    if type(description) == 'table' then
        description = vim.fn.join(description, '\n')
    end

    local documentation_str = interpolate(DOC_TEMPLATE, {
        name = snip.name or '',
        filetype = data.filetype or '',
        description = description,
        codeblock = codeblock,
    })
    local documentation_lines =
        vim.lsp.util.convert_input_to_markdown_lines({ documentation_str })
    local documentation = table.concat(documentation_lines, '\n')
    return documentation
end

local handlers = {

    ---@type lsp.Handler
    [vim.lsp.protocol.Methods.initialize] = function(_, callback, _)
        local initializeResult = {
            capabilities = {
                completionProvider = {
                    resolveProvider = true,
                    completionItem = {
                        labelDetailsSupport = true,
                    },
                },
            },
            serverInfo = {
                name = 'luasnip',
                version = '0.0.1',
            },
        }

        callback(nil, initializeResult)
    end,

    ---@type lsp.Handler
    [vim.lsp.protocol.Methods.textDocument_completion] = function(
        _,
        callback,
        _
    )
        ---@type lsp.CompletionItem[]
        local completion_items_result = {}

        ---@type string[]
        local filetypes = require('luasnip.util.util').get_snippet_filetypes()

        for _, filetype in ipairs(filetypes) do
            if not completion_cache_by_filetype[filetype] then
                ---@type lsp.CompletionItem[]
                local ft_completion_items = {}

                local snippets = require('luasnip').get_snippets(
                    filetype,
                    { type = 'snippets' }
                )
                for _, snip in ipairs(snippets) do
                    if not snip.hidden then
                        local data = {
                            filetype = filetype,
                            snip_id = snip.id,
                        }
                        local completion_item = {
                            detail = 'luasnip',
                            label = snip.trigger,
                            kind = vim.lsp.protocol.CompletionItemKind.Snippet,
                            insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
                            insertText = snip.trigger,
                            data = data,
                            cmd = 'luasnip.expand',
                            command = {
                                arguments = data,
                                command = 'luasnip.expand',
                                title = 'expandLuasnip',
                            },
                        }
                        table.insert(ft_completion_items, completion_item)
                        completion_by_snip_id[snip.id] = completion_item
                    end
                end

                completion_cache_by_filetype[filetype] = ft_completion_items
            end
            vim.list_extend(
                completion_items_result,
                completion_cache_by_filetype[filetype]
            )
        end

        callback(nil, completion_items_result)
    end,

    ---@type lsp.Handler
    [vim.lsp.protocol.Methods.completionItem_resolve] = function(
        request,
        callback,
        _
    )
        local snip_id = request.data.snip_id
        local snip = require('luasnip').get_id_snippet(snip_id)
        local completion_item = completion_by_snip_id[snip_id]

        if completion_item == nil then
            ---@type lsp.ResponseError
            local err = {
                code = 0,
                message = 'Could not find snippet in cache.',
            }
            callback(err, nil)
            return
        end

        if completion_item.documentation == nil then
            vim.notify(
                'Creating cached documentation for snippet ' .. snip_id,
                vim.log.levels.DEBUG
            )
            --Side-effect: modifies cache to include the documentation
            completion_item.documentation = {
                kind = vim.lsp.protocol.MarkupKind.Markdown,
                value = build_snip_documentation(snip, request.data),
            }
        end

        callback(nil, completion_item)
    end,
}

vim.lsp.commands['luasnip.expand'] = function(params)
    local arguments = params.arguments
    if arguments == nil then return end

    local snip_id = arguments.snip_id
    if snip_id == nil then return end

    local snip = require('luasnip').get_id_snippet(snip_id)

    local line = require('luasnip.util.util').get_current_line_to_cursor()
    local expand_params = snip:matches(line)
    if expand_params ~= nil and expand_params.clear_region ~= nil then
        require('luasnip').snip_expand(snip, {
            clear_region = expand_params.clear_region,
            expand_params = expand_params,
        })
        return
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1 --convert to 0 based index
    local col = cursor[2]

    local col_offset = expand_params ~= nil and #expand_params.trigger
        or #snip.trigger

    local clear_region = {
        from = {
            row,
            col - col_offset,
        },
        to = { row, col },
    }

    require('luasnip').snip_expand(snip, {
        clear_region = clear_region,
        expand_params = expand_params,
    })
end

M.start_snippet_lsp = function()
    local client_id = vim.lsp.start({
        name = 'luasnip',
        filetypes = { '*' },
        root_dir = vim.fn.getcwd(),
        cmd = function(_)
            return {
                trace = 'messages',
                request = function(
                    method,
                    params,
                    callback,
                    notify_reply_callback
                )
                    if handlers[method] then
                        handlers[method](
                            params,
                            callback,
                            notify_reply_callback
                        )
                    end
                end,
                notify = function(_, _) end,
                is_closing = function() end,
                terminate = function() end,
            }
        end,
        on_init = function(_)
            vim.notify('Snippet LSP server initialized', vim.log.levels.DEBUG)
        end,
    }, {
        on_exit = function(code, signal)
            vim.notify(
                'Server exited with code ' .. code .. ' and signal ' .. signal,
                vim.log.levels.DEBUG
            )
        end,
    })
    if client_id == nil then error('Something went wrong') end

    return client_id
end

return M
