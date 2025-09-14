local M = {}

---@class MyLspLocationsNavigatorOptions
---@field namespace string

---@class MyLspLocationsNavigator
---@field mark_ns integer namespace used to refer to the item references
---@field mark_bufnr? integer
---@field mark_id? integer
---@field mark_text? string
---@field cur_index? integer index of current location
---@field get_locations_callback fun(on_list_callback: fun(opts: vim.lsp.LocationOpts.OnList))
local MyLspLocationsNavigator = setmetatable({}, {})
MyLspLocationsNavigator.__index = MyLspLocationsNavigator

function MyLspLocationsNavigator:reset()
    local mark_bufnr = self.mark_bufnr
    local mark_id = self.mark_id

    --Clear fields first in case deleting the extmark errors
    self.mark_bufnr = nil
    self.mark_id = nil
    self.mark_text = nil
    self.cur_index = nil

    if mark_bufnr ~= nil and mark_id ~= nil then
        vim.api.nvim_buf_del_extmark(mark_bufnr, self.mark_ns, mark_id)
    end
end

function MyLspLocationsNavigator:is_mark_valid()
    if self.mark_bufnr == nil and self.mark_id == nil then
        --if no mark is set we will return false with no error
        return false, nil
    elseif self.mark_bufnr == nil and self.mark_id ~= nil then
        return false, 'The bufnr was set but not the mark id'
    elseif self.mark_bufnr ~= nil and self.mark_id == nil then
        return false, 'The mark id was set but not the mark bufnr'
    elseif not vim.api.nvim_buf_is_valid(self.mark_bufnr) then
        return false, 'Buffer is no longer valid'
    elseif
        self.mark_id ~= nil
        and self.mark_bufnr ~= nil
        and vim.api.nvim_buf_is_valid(self.mark_bufnr)
    then
        local extmark = vim.api.nvim_buf_get_extmark_by_id(
            self.mark_bufnr,
            self.mark_ns,
            self.mark_id,
            {}
        )
        if #extmark == 0 then
            --empty list denotes invalid mark
            return false, 'Marked reference no longer exists'
        end

        --(0,0) indexing
        local mark_row = extmark[1]
        local mark_col = extmark[2]

        --TODO may have to deal with unloaded buffers
        local current_text = vim._with({ buf = self.mark_bufnr }, function()
            local win = 0
            local current_cursor = vim.api.nvim_win_get_cursor(win)
            --(1,0) indexing
            vim.api.nvim_win_set_cursor(0, { mark_row + 1, mark_col })
            local cword = vim.fn.expand('<cword>')
            vim.api.nvim_win_set_cursor(0, current_cursor)
            return cword
        end)

        if current_text ~= self.mark_text then
            vim.notify(
                string.format(
                    'Marked reference text has changed from `%s` to `%s`',
                    self.mark_text,
                    current_text
                ),
                vim.log.levels.WARN
            )

            local message = string.format(
                'Marked reference text has changed from `%s` to `%s`',
                self.mark_text,
                current_text
            )
            return false, message
        else
            return true, nil
        end
    end
    return true, nil
end

function MyLspLocationsNavigator:get_mark_text()
    if self.mark_bufnr == nil and self.mark_id == nil then
        --if no mark is set we will return false with no error
        return nil, 'No mark set'
    elseif self.mark_bufnr == nil and self.mark_id ~= nil then
        return nil, 'The bufnr was set but not the mark id'
    elseif self.mark_bufnr ~= nil and self.mark_id == nil then
        return nil, 'The mark id was set but not the mark bufnr'
    elseif not vim.api.nvim_buf_is_valid(self.mark_bufnr) then
        return nil, 'Buffer is no longer valid'
    elseif
        self.mark_id ~= nil
        and self.mark_bufnr ~= nil
        and vim.api.nvim_buf_is_valid(self.mark_bufnr)
    then
        local extmark = vim.api.nvim_buf_get_extmark_by_id(
            self.mark_bufnr,
            self.mark_ns,
            self.mark_id,
            {}
        )
        if #extmark == 0 then
            --empty list denotes invalid mark
            return nil, 'Marked reference no longer exists'
        end

        --(0,0) indexing
        local mark_row = extmark[1]
        local mark_col = extmark[2]

        --TODO may have to deal with unloaded buffers
        local current_text = vim._with({ buf = self.mark_bufnr }, function()
            local current_cursor = vim.api.nvim_win_get_cursor(0)
            --(1,0) indexing
            vim.api.nvim_win_set_cursor(0, { mark_row + 1, mark_col })
            local cword = vim.fn.expand('<cword>')
            -- local line_text = vim.api.nvim_get_current_line()
            -- vim.print(string.format('line text at mark: %s', line_text))
            vim.api.nvim_win_set_cursor(0, current_cursor)
            return cword
        end)

        if current_text ~= self.mark_text then
            local message = string.format(
                'Marked reference text has changed from `%s` to `%s`',
                self.mark_text,
                current_text
            )

            vim.notify(message, vim.log.levels.WARN)

            return current_text, message
        else
            return current_text, nil
        end
    end
    return nil, nil
end

---TODO replace dirction with a count
---@param direction string prev, next, first, last
function MyLspLocationsNavigator:jump(direction)
    vim.validate(
        'self.get_locations_callback',
        self.get_locations_callback,
        'function',
        true,
        'get_locations_callback should be set via the init method'
    )

    local valid, err = self:is_mark_valid()

    if not valid and err ~= nil then
        self:reset()
        vim.notify(err, vim.log.levels.WARN)
        return
    elseif valid then
        --Using vim._with buf to switch back to the mark and fetch the references
        --so that this temporary cursor movement isn't visible (fixes flickering)
        --we create the on_list outside of the vim._with so that the state of the
        --current window/buffer can be recorded
        vim._with({ buf = self.mark_bufnr }, function()
            local mark_row, mark_col, _ = unpack(
                vim.api.nvim_buf_get_extmark_by_id(
                    self.mark_bufnr,
                    self.mark_ns,
                    self.mark_id,
                    {}
                )
            )

            vim.api.nvim_set_current_buf(self.mark_bufnr)
            --(1,0) indexing
            vim.api.nvim_win_set_cursor(0, { mark_row + 1, mark_col })
            local on_list = self:create_on_list(direction)

            --TODO fix race condition when keymap is ran too quickly
            --and the on_lists get called out of order. Maybe use a field to
            --keep track of remaining jumps and the debounce on_list when not running
            --in a macro (would need to handle weird situations like mix matching
            --references and declarations or references to a different cword)
            self.get_locations_callback(on_list)
        end)
    else
        local on_list = self:create_on_list(direction)
        self.get_locations_callback(on_list)
    end
end

---Initializes the navigator by reseting the mark and changing the callback get_locations_callback
---@param get_locations_callback fun(on_list_callback: fun(opts: vim.lsp.LocationOpts.OnList))
function MyLspLocationsNavigator:init(get_locations_callback)
    self:reset()
    self.get_locations_callback = get_locations_callback

    local bufnr = vim.api.nvim_get_current_buf()

    local from = vim.fn.getpos('.')
    from[1] = bufnr --TODO figure out how I want to set this with changes

    -- (1,1) indexing
    local lnum = vim.fn.line('.')
    local col = vim.fn.col('.')

    self.mark_bufnr = bufnr
    self.mark_text = vim.fn.expand('<cword>')
    --(0,0) indexing
    self.mark_id =
        vim.api.nvim_buf_set_extmark(bufnr, self.mark_ns, lnum - 1, col - 1, {})
end

---TODO replace dirction with a count
---@param direction string prev, next, first, last
---@return function
function MyLspLocationsNavigator:create_on_list(direction)
    --Edge I need to make sure still work if I ever make any changes to this
    -- - the list of lsp locations can contain items that you cannot repeat the lsp command on
    --   for example luals lsp references often times contains the comment type definition
    -- - make sure this works in macros
    --

    ---Based on nvim runtime files
    ---Handle what to do if LSP returns a list of locations
    ---@param opts vim.lsp.LocationOpts.OnList
    return function(opts)
        if not opts or not opts.items or #opts.items == 0 then
            vim.notify('No references found', vim.log.levels.WARN)
            self:reset()
            return
        end

        ---TODO this callback currently gets the correct bufnr/window state
        ---and not the state of the vim._with because get_locations_callback
        ---so far is using async callbacks. If the callbacks where sync I believe this would
        ---fail
        local bufnr = vim.api.nvim_get_current_buf()
        local win = vim.api.nvim_get_current_win()

        local from = vim.fn.getpos('.')
        from[1] = bufnr
        local tagname = vim.fn.expand('<cword>')

        local all_items = opts.items

        -- Filter out duplicates if we have multiple LSPs attached to the buffer
        -- that support the given lsp method
        local filtered_items = all_items
        if
            #vim.lsp.get_clients({
                bufnr = opts.context.bufnr,
                method = opts.context.method,
            }) > 1
        then
            local seen = {}
            filtered_items = {}
            for _, item in ipairs(all_items) do
                local key = vim.inspect({
                    col = item.col,
                    end_col = item.end_col,
                    end_lnum = item.end_lnum,
                    filename = vim.fs.abspath(vim.fs.normalize(item.filename)),
                    lnum = item.lnum,
                })
                if not seen[key] then
                    seen[key] = true
                    table.insert(filtered_items, item)
                end
            end
        end
        table.sort(filtered_items, function(a, b)
            if a.filename < b.filename then
                return true
            elseif a.filename == b.filename and a.lnum < b.lnum then
                return true
            elseif
                a.filename == b.filename
                and a.lnum == b.lnum
                and a.col < b.col
            then
                return true
            else
                return false
            end
        end)

        if self.cur_index == nil then
            -- Find the current reference based on cursor position
            local current_ref = self.mark_id == nil and 1 or nil
            local lnum = vim.fn.line('.')
            local col = vim.fn.col('.')
            for i, item in ipairs(filtered_items) do
                local lnum_matches = (
                    item.lnum == lnum and item.end_lnum == nil
                )
                    or (item.lnum <= lnum and lnum <= item.end_lnum)
                local col_matches = (
                    (item.col == col and item.end_col == nil)
                    or (item.col <= col and col <= item.end_col)
                )
                if lnum_matches and col_matches then
                    current_ref = i
                    break
                end
            end

            if current_ref == nil then
                vim.notify(
                    'Cannot find marked reference in locations returned by lsp'
                )
                self:reset()
                return
            end
            self.cur_index = current_ref
        end

        -- Calculate the adjacent reference based on direction
        local adjacent_ref = self.cur_index
        if direction == 'first' then
            adjacent_ref = 1
        elseif direction == 'last' then
            adjacent_ref = #filtered_items
        else
            local delta = direction == 'next' and 1 or -1
            adjacent_ref = math.min(#filtered_items, self.cur_index + delta)
            if adjacent_ref < 1 then adjacent_ref = 1 end
        end
        self.cur_index = adjacent_ref

        --Go to item
        local item = filtered_items[adjacent_ref]
        local b = item.bufnr or vim.fn.bufadd(item.filename)

        -- Save position in jumplist
        vim.cmd("normal! m'")
        -- Push a new item into tagstack
        local tagstack = { { tagname = tagname, from = from } }
        vim.fn.settagstack(vim.fn.win_getid(win), { items = tagstack }, 't')

        vim.bo[b].buflisted = true

        vim.api.nvim_win_set_buf(win, b)
        --(1,0)indexing
        vim.api.nvim_win_set_cursor(win, { item.lnum, item.col - 1 })
        vim._with({ win = win }, function()
            -- Open folds under the cursor
            vim.cmd('normal! zv')
        end)
    end
end

---@param opts MyLspLocationsNavigatorOptions
---@return MyLspLocationsNavigator
function M.create_lsp_locations_navigator(opts)
    local lsp_locations_navigator = setmetatable({
        mark_ns = vim.api.nvim_create_namespace(opts.namespace),
    }, {
        __index = MyLspLocationsNavigator,
    })
    return lsp_locations_navigator
end

---@param on_list_callback fun(opts: vim.lsp.LocationOpts.OnList)
M.references = function(on_list_callback)
    if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
        require('mark-code-action.locations').list_references({
            on_list = on_list_callback,
        })
    else
        vim.lsp.buf.references(nil, {
            on_list = on_list_callback,
        })
    end
end

-- ---An implementation that sends empty locations lists to the on_list_callback
-- ---since vim.lsp.buf.references doesn't
-- ---@param on_list_callback fun(opts: vim.lsp.LocationOpts.OnList)
-- M.references = function(on_list_callback)
--     local bufnr = vim.api.nvim_get_current_buf()
--     local win = vim.api.nvim_get_current_win()
--
--     vim.lsp.buf_request_all(
--         bufnr,
--         vim.lsp.protocol.Methods.textDocument_references,
--         function(client)
--             local params =
--                 vim.lsp.util.make_position_params(win, client.offset_encoding)
--             ---@diagnostic disable-next-line: inject-field
--             params.context = { includeDeclaration = true }
--             return params
--         end,
--         function(results)
--             local all_items = {}
--             local title = 'References'
--
--             for client_id, res in pairs(results) do
--                 local client = assert(vim.lsp.get_client_by_id(client_id))
--                 local items = vim.lsp.util.locations_to_items(
--                     res.result or {},
--                     client.offset_encoding
--                 )
--                 vim.list_extend(all_items, items)
--             end
--
--             local list = {
--                 title = title,
--                 items = all_items,
--                 context = {
--                     method = vim.lsp.protocol.Methods.textDocument_references,
--                     bufnr = bufnr,
--                 },
--             }
--             on_list_callback(list)
--         end
--     )
-- end

--gd
---@param on_list_callback fun(opts: vim.lsp.LocationOpts.OnList)
M.definition = function(on_list_callback)
    vim.lsp.buf.definition({
        on_list = on_list_callback,
    })
end

---gD
---@param on_list_callback fun(opts: vim.lsp.LocationOpts.OnList)
M.declaration = function(on_list_callback)
    vim.lsp.buf.declaration({
        on_list = on_list_callback,
    })
end

---gi
---@param on_list_callback fun(opts: vim.lsp.LocationOpts.OnList)
M.implementation = function(on_list_callback)
    vim.lsp.buf.implementation({
        on_list = on_list_callback,
    })
end

---go
---@param on_list_callback fun(opts: vim.lsp.LocationOpts.OnList)
M.type_definition = function(on_list_callback)
    vim.lsp.buf.type_definition({
        on_list = on_list_callback,
    })
end

return M
