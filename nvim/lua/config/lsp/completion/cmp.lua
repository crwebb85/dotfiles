---Based on https://github.com/benlubas/cmp2lsp/tree/bf7304aca1f5a0ff873816670d9aab60f6bdafaa/lua/cmp2lsp
local M = {}

M.create_abstracted_context = function(request)
    local line_num = request.position.line
    local col_num = request.position.character
    local buf = vim.uri_to_bufnr(request.textDocument.uri)
    local full_line =
        vim.api.nvim_buf_get_lines(buf, line_num, line_num + 1, false)[1]
    local before_char = (request.context and request.context.triggerCharacter)
        or full_line:sub(col_num, col_num + 1)
    return {
        context = {
            cursor = {
                row = request.position.line,
                col = col_num + 1,
            },
            line = full_line,
            line_before_cursor = full_line:sub(1, col_num),
            bufnr = buf,
            before_char = before_char,
            -- throwaway values to appease some plugins that expect them (neorg)
            prev_context = {
                cursor = {
                    row = request.position.line,
                    col = col_num + 1,
                },
                line = full_line,
                line_before_cursor = full_line:sub(1, col_num + 1),
                bufnr = buf,
                before_char = before_char,
            },
        },
        completion_context = {
            triggerKind = 0,
        },
    }
end

-- track all the sources
M.sources = {}

M.add_source = function(s) table.insert(M.sources, s) end

function M.register_source(name, cmp_source)
    cmp_source.name = name
    cmp_source.display_name = name .. ' (cmp)'
    if not cmp_source.is_available then
        cmp_source.is_available = function() return true end
    end

    local old_complete = cmp_source.complete
    cmp_source.complete = function(self, completion_context, callback)
        local cursor = {
            completion_context.context.cursor.row,
            completion_context.context.cursor.col,
        }
        local cursor_line = completion_context.context.line
        local cmp_context = {
            option = {
                reason = completion_context.completion_context.triggerKind == 1
                        and 'manual'
                    or 'auto',
            },
            filetype = vim.api.nvim_get_option_value('filetype', {
                buf = 0,
            }),
            time = vim.uv.now(),
            bufnr = completion_context.context.bufnr,
            cursor_line = completion_context.context.line,
            cursor = {
                row = cursor[1],
                col = cursor[2] - 1,
                line = cursor[1] - 1,
                character = cursor[2] - 1,
            },
            prev_context = completion_context.context.prev_context,
            get_reason = function(self_) return self_.option.reason end,
            cursor_before_line = completion_context.context.line_before_cursor,
            line_before_cursor = completion_context.context.line_before_cursor,
            cursor_after_line = string.sub(cursor_line, cursor[2] - 1),
        }

        -- yeah, maybe cache these? cmp does
        local offset = (function()
            if self.get_keyword_pattern then
                local pat = self:match_keyword_pattern(
                    completion_context.context.line_before_cursor
                )
                if pat then return pat end
            end
            return cursor[2]
        end)()

        old_complete(cmp_source, {
            context = cmp_context,
            offset = offset,
            completion_context = completion_context.completion_context,
            option = {},
        }, function(response)
            if not response then
                callback({})
                return
            end
            if response.isIncomplete ~= nil then
                callback(response.items or {}, response.isIncomplete == true)
                return
            end
            callback(response.items or response)
        end)
    end
    local old_get_keyword_pattern = cmp_source.get_keyword_pattern
    if old_get_keyword_pattern then
        cmp_source.get_keyword_pattern = function(self, _)
            return old_get_keyword_pattern(self, { option = {} })
        end
    end
    cmp_source.match_keyword_pattern = function(self, line_before_cursor)
        return vim.regex([[\%(]] .. self:get_keyword_pattern() .. [[\)\m$]])
            :match_str(line_before_cursor)
    end
    -- local old_execute = cmp_source.execute
    -- if old_execute then
    --   cmp_source.execute = function(self, entry, _)
    --     old_execute(self, entry.completion_item, function() end)
    --   end
    -- end

    M.add_source(cmp_source)
end
---Sort sources into configuration order
M.sort_sources = function(config)
    local sorted = {}

    local source_by_name = function(name)
        for _, source in ipairs(M.sources) do
            if source.name == name then return source end
        end
    end

    for _, group in ipairs(config) do
        for _, name in ipairs(group) do
            local source = source_by_name(name)
            if not source then
                vim.notify(
                    ('[cmp] invalid source name: `%s`'):format(name),
                    vim.log.levels.WARN,
                    {}
                )
                return
            end

            table.insert(sorted, source)
        end

        table.insert(sorted, 'group separator') -- yeah this is horribly hacky. it's a small plugin okay.
    end

    M.sources = sorted
end

local handlers = {
    ---@diagnostic disable-next-line: unused-local
    ['initialize'] = function(_params, callback, _notify_reply_callback)
        local initializeResult = {
            capabilities = {
                completionProvider = {
                    triggerCharacters = {
                        '{',
                        '(',
                        '[',
                        ' ',
                        '}',
                        ')',
                        ']',
                    },
                    resolveProvider = false,
                    completionItem = {
                        labelDetailsSupport = true,
                    },
                },
            },
            serverInfo = {
                name = 'cmp',
                version = '0.0.2',
            },
        }

        callback(nil, initializeResult)
    end,

    ['textDocument/completion'] = function(request, callback, _)
        local abstracted_context = M.create_abstracted_context(request)
        local response = {
            -- --For testing
            -- {
            --     detail = 'testing',
            --     documentation = 'a red fruit',
            --     label = 'apple',
            -- },
            -- {
            --     detail = 'testing',
            --     documentation = 'an orange fruit',
            --     label = 'orange',
            -- },
            -- {
            --     detail = 'fruit',
            --     documentation = 'a fruit',
            --     label = 'a fruit',
            -- },
            -- {
            --     detail = 'for',
            --     documentation = 'plaintext for',
            --     label = 'for',
            -- },
        }
        for _, source in ipairs(M.sources) do
            if type(source) == 'string' then
                if #response > 0 then
                    break
                else
                    goto continue
                end
            end

            if
                source:is_available()
                and (
                    not source.get_trigger_characters
                    or vim.tbl_contains(
                        source:get_trigger_characters(),
                        abstracted_context.context.before_char
                    )
                )
            then
                source:complete(abstracted_context, function(items)
                    for _, item in ipairs(items) do
                        item.detail = source.name
                        table.insert(response, item)
                    end
                end)
            end
            ::continue::
        end

        callback(nil, response)
    end,
}

M.start_cmp_lsp = function()
    local dispatchers = {
        on_exit = function(code, signal)
            vim.notify(
                'Server exited with code ' .. code .. ' and signal ' .. signal,
                vim.log.levels.ERROR
            )
        end,
    }
    local client_id = vim.lsp.start({
        name = 'cmp',
        filetypes = { '*' },
        root_dir = vim.fn.getcwd(),
        cmd = function(_)
            local members = {
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
                    else
                        -- fail silently
                    end
                end,
                ---@diagnostic disable-next-line: unused-local
                notify = function(_method, _params) end,
                is_closing = function() end,
                terminate = function() end,
            }
            M.register_source('buffer', require('cmp_buffer'))

            return members
        end,
        on_init = function(_)
            vim.notify('cmp LSP server initialized', vim.log.levels.INFO)
        end,
    }, dispatchers)
    if client_id == nil then error('Something went wrong') end
    return client_id
end

return M
