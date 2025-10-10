local M = {}

-- quickfixtextfunc example:
--
-- vim.fn.setqflist({}, ' ', {
--     title = 'Extended Quickfix',
--     items = {
--         {
--             filename = [[C:\Users\crweb\Documents\.config\nvim\lua\myconfig\quickfix.lua]],
--             lnum = 1,
--             text = 'hi'
--         }
--     },
--     quickfixtextfunc = function(info)
--         --info: {
--         --   end_idx = 1,
--         --   id = 242,
--         --   quickfix = 1,
--         --   start_idx = 1,
--         --   winid = 0
--         -- }
--
-- 	    local items = vim.fn.getqflist({id = info.id, items = 1}).items
--
--         local l = {}
--         for idx = info.start_idx, info.end_idx do
--             local name = vim.fn.fnamemodify(vim.fn.bufname(items[idx].bufnr), ':p:.')
--             table.insert(l, name )
--         end
--         return l
--     end
-- })

---@class my.fn.quickfixtextfunc.info
---@field end_idx integer
---@field id integer
---@field quickfix integer
---@field start_idx integer
---@field winid integer

---My custom type definition for
---what vim.fn.getloclist and vim.fn.getqflist
---return when specifing which fields to select
---@class my.fn.getlist.result
---the total number of changes made to the list |quickfix-changedtick|
---@field changetick? integer
---the |quickfix-context|
---@field context? string
---the filewinid for the location list
---only used by the location list (I can't find any
---way to get this to return anything but 0.) No idea
---what this is
---@field filewinid integer
---See |quickfix-ID|;
---@field id? integer
---See |quickfix-index|
---@field idx? integer idx
---quickfix list entries
---(Note: filename field of entry will always be nil)
---@field items? vim.quickfix.entry[]
---The quickfix number
---@field nr? integer
---number of the buffer displayed in the quickfix window. Returns 0 if the
---quickfix buffer is not present. See |quickfix-buffer|.
---@field qfbufnr? integer
---the function used to display the quickfix text
---@field quickfixtextfunc? string | fun(info: my.fn.quickfixtextfunc.info) : string[]
---number of entries in the quickfix list
---@field size? integer
---the list title |quickfix-title|
---@field title? string
---the quickfix |window-ID| for the current tab.
---@field winid? number

---@class GetListInfoFieldSelection
---changedtick get the total number of changes made to the list |quickfix-changedtick|
---@field changetick? boolean
---get the |quickfix-context|
---@field context? boolean
---get the  filewinid for the location list
---only used when fetching the location list (I can't find any
---way to create a location list with a value other than 0) No idea
---what this is.
---@field filewinid boolean
---quickfix list entries
---@field items? boolean
---number of the buffer displayed in the quickfix window. Returns nil if the
---quickfix buffer is not present. See |quickfix-buffer|.
---@field qfbufnr? boolean
---number of entries in the quickfix list
---@field size? boolean
---get the list title |quickfix-title|
---@field title? boolean
---get the quickfix |window-ID| for the current tab. Returns nil if the quickfix
---window is not open in the current tab
---@field winid? boolean

---@class GetListInfoOpts : GetListOpts
---@field selection? GetListInfoFieldSelection
---Get information for the quickfix entry at this index in the list specified
---by "id" or "nr". If set to zero, then uses the current entry. See |quickfix-index|
---@field idx? number

---@class GetListEntriesOpts : GetListOpts
---Get information for the quickfix entry at this index in the list specified
---by "id" or "nr". If set to zero, then uses the current entry. See |quickfix-index|
---@field idx? number

---@class GetListOpts
---the window number or the |window-ID| the list is for. When {win} is zero
---the current window's location list is used. When nil the quickfix list is used.
---@field winnr? integer
---get information for the quickfix list with |quickfix-ID|; zero means the id
---for the current list or the list specified by "nr"
---@field id? number
---get information for this quickfix list; zero means the current quickfix list
---and "$" means the last quickfix list
---@field nr? number | string

---@class SetDiagnosticListOpts : vim.diagnostic.setqflist.Opts, vim.diagnostic.setloclist.Opts
---the window number or the |window-ID| the list is for. When {win} is zero
---the current window's location list is used. When nil the quickfix list is used.
---@field winnr? integer

---Get all the fields for the the quickfix/location list info
---@param opts? GetListEntriesOpts the list opts
---@return my.fn.getlist.result? result
function M.get_list(opts)
    opts = opts or {}
    local result
    if type(opts.winnr) == 'number' then
        ---@type my.fn.getlist.result
        result = vim.fn.getloclist(opts.winnr, {
            id = opts.id,
            idx = opts.idx,
            nr = opts.nr,
            all = 1,
        })
    else
        ---@type my.fn.getlist.result
        result = vim.fn.getqflist({
            id = opts.id,
            idx = opts.idx,
            nr = opts.nr,
            all = 1,
        })
    end
    if result.id == 0 then
        ---if id is nil that means the quickfix list doesn't exist
        ---for the specified win, id, or nr
        return nil
    end
    return result
end

---Get the quickfix/location list entries
---@param opts? GetListEntriesOpts the list opts
---the current window's location list is used. When nil the quickfix list is used.
---@return vim.quickfix.entry[] | nil entries nil if no list specified by win, id, and nr exists (Note: filename field will always be nil)
function M.get_list_entries(opts)
    opts = opts or {}
    local result
    if type(opts.winnr) == 'number' then
        ---@type my.fn.getlist.result
        result = vim.fn.getloclist(opts.winnr, {
            id = opts.id or 0, -- or zero so that id will be returned back
            idx = opts.idx,
            nr = opts.nr,
            items = 0, -- zero means select items
        })
    else
        ---@type my.fn.getlist.result
        result = vim.fn.getqflist({
            id = opts.id or 0, -- or zero so that id will be returned back
            idx = opts.idx,
            nr = opts.nr,
            items = 0, -- zero means select items
        })
    end
    if result.id == 0 then
        ---if id is nil that means the quickfix list doesn't exist
        ---for the specified win, id, or nr
        return nil
    end

    if result.items == nil then
        error('Invalid assumption: qf/loc list should have an items list')
    end

    return result.items
end

---Checks if the list specified by opts exists
---@param opts? GetListInfoOpts when nil or opts.selection == nil or opts.selection has no selected fields return all properties
---@return boolean exists
function M.is_existing_list(opts)
    opts = opts or {}
    local result
    if type(opts.winnr) == 'number' then
        ---@type my.fn.getlist.result
        result = vim.fn.getloclist(opts.winnr, {
            id = opts.id or 0, -- or zero so that id will be returned back
            nr = opts.nr,
        })
    else
        ---@type my.fn.getlist.result
        result = vim.fn.getqflist({
            id = opts.id or 0, -- or zero so that id will be returned back
            nr = opts.nr,
        })
    end
    if result.id == 0 then
        return false
    else
        return true
    end
end

---Create/replace/add to the quickfix list.
---@param action string
---@param winnr? integer the window number or the |window-ID|. When {win} is zero the current window's location list is used. When nil the quickfix list is used.
---@param what vim.fn.setqflist.what
---@return integer
function M.set_list(winnr, action, what)
    if winnr == nil then
        return vim.fn.setqflist({}, action, what)
    else
        return vim.fn.setloclist(winnr, {}, action, what)
    end
end

---set the location or quickfix list with diagnostics
---@param opts SetDiagnosticListOpts
function M.set_diagnostic_list(opts)
    if opts.winnr == nil then
        vim.diagnostic.setqflist(opts)
    else
        vim.diagnostic.setloclist(opts)
    end
end

---expands the multiline entry text with lines below entry
---@param entries vim.quickfix.entry[]
---@return vim.quickfix.entry[]
M.expand_multiline_text_entries = function(entries)
    local expanded_entries = {}
    local idx = 0
    for _, entry in ipairs(entries) do
        if
            type(entry.user_data) == 'table'
            and entry.user_data.is_multiline_display
        then
            --skip existing multiline dipslayed entries because we will
            --regenerate them
        elseif entry.text and string.find(entry.text, '\n') ~= nil then
            table.insert(expanded_entries, entry)
            idx = idx + 1

            local lines = vim.split(entry.text, '\n')
            for _, line in ipairs(lines) do
                local text_entry = {
                    text = line,
                    valid = 0,
                    user_data = {
                        is_multiline_display = true,
                        multiline_display_idx = idx,
                    },
                }
                table.insert(expanded_entries, text_entry)
            end
            idx = idx + #lines
        else
            table.insert(expanded_entries, entry)
            idx = idx + 1
        end
    end
    return expanded_entries
end

---@param opts? GetListEntriesOpts when nil or opts.selection == nil or opts.selection has no selected fields return all properties
M.expand_multiline_text_in_list = function(opts)
    opts = opts or {}
    local entries = M.get_list_entries(opts)
    if entries == nil then return end
    local expanded_entries = M.expand_multiline_text_entries(entries)
    M.set_list(opts.winnr, 'u', { items = expanded_entries })
end

return M
