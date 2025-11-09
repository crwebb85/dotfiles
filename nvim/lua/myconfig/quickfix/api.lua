local misc = require('myconfig.utils.misc')
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
---return when specifing to select all fields
---Note: we I don't define filewinid because it doesn't make sense in this context
---I will have a special function to fetch that information
---@class my.fn.getlist.result
---the total number of changes made to the list |quickfix-changedtick|
---@field changetick integer
---the |quickfix-context|
---@field context any (default response is an empty string "" and if set to nil this value will be an empty string)
---See |quickfix-ID|;
---@field id integer
---See |quickfix-index|
---@field idx integer idx
---quickfix list entries
---(Note: filename field of entry will always be nil)
---@field items vim.quickfix.entry[]
---The quickfix number
---@field nr integer
---number of the buffer displayed in the quickfix window. Returns 0 if the
---quickfix buffer is not present. See |quickfix-buffer|.
---@field qfbufnr integer
---the function used to display the quickfix text
---@field quickfixtextfunc string | fun(info: my.fn.quickfixtextfunc.info) : string[]
---number of entries in the quickfix list
---@field size integer
---the list title |quickfix-title|
---@field title string
---the quickfix |window-ID| for the current tab.
---@field winid number

---Information about the quickfix list based on
---values returned by vim.fn.getloclist and vim.fn.getqflist when
---all fields are returned but with better normalized output
---1. the default vimscript values of fields are converted to nil
---2. filewinid is determined by input rather than output since vim.fn.getloclist
---   filewinid is quirky
---@class GetListResult
---@field filewinid? integer the window that location list is linked to (nil for quickfix list)
---the total number of changes made to the list |quickfix-changedtick|
---@field changetick integer
---the |quickfix-context|
---@field context? any
---See |quickfix-ID|;
---@field id integer
---See |quickfix-index|
---@field idx integer idx
---quickfix list entries
---(Note: filename field of entry will always be nil)
---@field items vim.quickfix.entry[]
---The quickfix number
---@field nr integer
---number of the buffer displayed in the quickfix window. Returns nil if the
---quickfix buffer is not present (aka has never been openend). Once opened this
---bufnr won't change unless bufwipeout is called on the bufnr
---See |quickfix-buffer|.
---@field qfbufnr? integer
---the quickfix |window-ID| for the current tab.
---@field qfwinid? number nil if window not open in current tab
---the function used to display the quickfix text
---@field quickfixtextfunc? string | fun(info: my.fn.quickfixtextfunc.info) : string[]
---number of entries in the quickfix list
---@field size? integer
---the list title |quickfix-title|
---@field title? string

---@class GetListEntriesOpts : GetListOpts
---Get information for the quickfix entry at this index in the list specified
---by "id" or "nr". If set to zero, then uses the current entry. See |quickfix-index|
---If nil get all entries
---@field idx? number

---@class IsListOpenOpts : GetListOpts
---The tab id to check if the list is open in (default: 0)
---@field tabid? number

---@class OpenListOpts
---the window number or the |window-ID| the list is for. When {win} is zero
---the current window's location list is used. When nil the quickfix list is used.
---@field filewin? integer
---Enter the list window after open (Default: true)
---@field enter? boolean

---@class GetListOpts
---the window number or the |window-ID| the list is for. When {win} is zero
---the current window's location list is used. When nil the quickfix list is used.
---@field filewin? integer
---get information for the quickfix list with |quickfix-ID|; zero means the id
---for the current list or the list specified by "nr"
---@field id? number
---get information for this quickfix list; zero means the current quickfix list
---and "$" means the last quickfix list
---@field nr? number | string

---@class ResolveOverseerParserOpts
---An overseer parser https://github.com/stevearc/overseer.nvim/blob/master/doc/reference.md#parsers
---@field parser? table
---An overseer problem matcher
---@field problem_matcher? table
---An values used by overseer problem matcher
---@field precalculated_vars? table

---@class ParseListEntriesOpts
---The lines to parse using 'efm' and return the resulting entries.
---Only a |List| type is accepted. The current quickfix list is not modified.
---See |quickfix-parse|.
---@field lines string[] | string
---errorformat to used when parsing "lines". (default vim.o.errorformat)
---@field efm? string
---An overseer parser to parse the lines with. Cannot be used if efm is defined
---@field parser? overseer.Parser

---@param win? integer winid or winnr or 0 for current win. (Default: 0)
---@return integer? winid the winid or nil if invalid winid was supplied
local function get_winid(win)
    if win == nil or win == 0 then return vim.api.nvim_get_current_win() end
    local possible_winid = vim.fn.win_getid(win)
    if possible_winid ~= 0 then return possible_winid end
    if not vim.api.nvim_win_is_valid(win) then return nil end
    return win
end

---Get all the fields for the the quickfix/location list info
---@param opts? GetListEntriesOpts the list opts
---TODO create a sanitized version of my.fn.getlist.result properly sets values to nil
---@return GetListResult? result
function M.get_list(opts)
    opts = opts or {}

    ---Note: we don't grab filewinid from getloclist since getloclist always returns 0
    ---unless the inputed nr (first parameter of getloclist) is the winnr/winid
    ---of the location list
    local filewinid = nil
    if opts.filewin ~= nil then
        filewinid = get_winid(opts.filewin)
        --if get_winid function is called with a win but get_winid can't convert
        --to a valid winid then the window doesn't exist and cannot have a location list
        if filewinid == nil then return nil end
    end

    local result
    if filewinid ~= nil then
        ---@type my.fn.getlist.result
        result = vim.fn.getloclist(filewinid, {
            id = opts.id,
            idx = opts.idx,
            nr = opts.nr,
            all = 1,
        })

        --If the result is an empty table then
        --that means the inputed win is no longer
        --a valid window so we return nil
        if next(result) == nil then return nil end
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

    if filewinid ~= nil and result.winid == filewinid then
        --lol so if the winid in the result is the winid that you are fetching
        --the location list for then that means you tried fetching the location list
        --for a window that is also a location list when that window doesn't
        --have a location list yet. (listception) If it did have one it would have
        --returned a different winid.
        --
        --"But how do you even get a location list window to have it's own location list?
        --Doesn't setloclist on the location list window winid just update that location list?"
        --
        --Answer: well yes that is correct but you can just change the buf in the location list window
        --to scratch buffer use setloclist and then change the buffer back to the
        --original location list buffer. Now you have a location list window
        --with own location list". So yeah this is a real edge-case.

        return nil
    end

    local context = result.context
    if context == '' then context = nil end

    ---@type integer?
    local idx = result.idx
    if idx == 0 then idx = nil end

    if result.nr == 0 then error('nr should not be 0') end

    ---@type integer?
    local qfbufnr = result.qfbufnr
    if qfbufnr == 0 then qfbufnr = nil end

    ---@type integer?
    local qfwinid = result.winid
    if qfwinid == 0 then qfwinid = nil end

    ---@type nil | string | fun(info: my.fn.quickfixtextfunc.info) : string[]
    local quickfixtextfunc = result.quickfixtextfunc
    if quickfixtextfunc == '' then quickfixtextfunc = nil end

    local qfwininfo
    if qfwinid ~= nil then qfwininfo = vim.fn.getwininfo(qfwinid) end

    local filewininfo
    if filewinid ~= nil then filewininfo = vim.fn.getwininfo(filewinid) end

    return {
        changetick = result.changetick,
        context = context,
        id = result.id,
        idx = idx,
        items = result.items,
        nr = result.nr,
        filewinid = filewinid,
        filewininfo = filewininfo,
        qfbufnr = qfbufnr,
        qfwinid = qfwinid,
        qfwininfo = qfwininfo,
        quickfixtextfunc = quickfixtextfunc,
        size = result.size,
        title = result.title,
    }
end

---Used to get the window that the location list from the window that the location
---list is displayed in.
---Quirks:
--- 1. If you change the buffer in the location list window to a non-location list bufnr this will return nil
--- 2. If you open the location list buffer in a non-location list window. This will return nil
--- 3. If you set the buffer for the location list window to a different location list buffer this will return the
---    winid that the original buffer would have returned
function M.get_filewinid(qfwin)
    local qfwinid = get_winid(qfwin)
    if qfwinid == nil then
        --if this function is called with a non-nil win but get_winid can't convert
        --to a valid winid then the window doesn't exist
        return nil
    end
    --TODO deal with wierdness when the location list has it's own location list
    local filewinid = vim.fn.getloclist(qfwinid, {
        filewinid = 0,
    }).filewinid
    if filewinid == 0 then return nil end
    return filewinid
end

---Fetches the filewinid of the location list if win is a loclist window
---or returns back the inputed window. Intended to make location list user
---commands behave like native location list commands.
---@param win integer a filewin for a location list or a location list win
---@return integer filewinid
function M.determine_filewinid_for_user_command(win)
    return M.get_filewinid(win) or win
end

---Get the quickfix/location list entries
---@param opts? GetListEntriesOpts the list opts
---the current window's location list is used. When nil the quickfix list is used.
---@return vim.quickfix.entry[] | nil entries nil if no list specified by win, id, and nr exists (Note: filename field will always be nil)
function M.get_list_entries(opts)
    opts = opts or {}
    local result
    if type(opts.filewin) == 'number' then
        ---@type my.fn.getlist.result
        result = vim.fn.getloclist(opts.filewin, {
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

---Creates a parser based on the configuration
---based on https://github.com/stevearc/overseer.nvim/blob/fe7b2f9ba263e150ab36474dfc810217b8cf7400/lua/overseer/component/on_output_parse.lua?plain=1#L36-L97
---@param opts ResolveOverseerParserOpts?
---@return overseer.Parser?
function M.resolve_overseer_parser(opts)
    if opts == nil then return nil end

    local problem_matcher = require('overseer.template.vscode.problem_matcher')
    local parser = require('overseer.parser')

    if opts.parser and opts.problem_matcher then
        misc.notify(
            "cannot specify both 'parser' and 'problem_matcher'",
            vim.log.levels.ERROR
        )
        return nil
    elseif not opts.parser and not opts.problem_matcher then
        return nil
    end
    ---@type table?
    local parser_defn = opts.parser
    if opts.problem_matcher then
        local pm = problem_matcher.resolve_problem_matcher(opts.problem_matcher)
        if pm then
            parser_defn = problem_matcher.get_parser_from_problem_matcher(
                pm,
                opts.precalculated_vars
            )
            if parser_defn then parser_defn = { diagnostics = parser_defn } end
        end
    end
    if not parser_defn then
        misc.notify('no parser_defn', vim.log.levels.ERROR)
        return nil
    end

    local resolved_parser = parser.new(parser_defn)

    return resolved_parser
end

---Parses the lines into quickfix list entries
---@param opts ParseListEntriesOpts
---@return vim.quickfix.entry[] entries parsed from input
---@return string[] lines that were parsed after being sanitized
function M.parse_list_entries(opts)
    --TODO it would be kindof nice to be able to get the sanitized lines back as context
    if opts.efm ~= nil and opts.parser ~= nil then
        misc.notify(
            'Parser field cannot be used if efm field is supplied. The efm option will be used.',
            vim.log.levels.WARN
        )
    end

    local unsanitized_lines = opts.lines
    local lines
    if type(unsanitized_lines) == 'string' then
        local normalized_lines =
            unsanitized_lines:gsub('\r\n', '\n'):gsub('\r', '\n')
        lines = vim.split(normalized_lines, '\n')
    elseif type(unsanitized_lines) == 'table' then
        lines = unsanitized_lines
    else
        error('invalid lines field')
    end

    if opts.parser ~= nil then
        opts.parser:reset()
        opts.parser:ingest(lines)
        local result = opts.parser:get_result()
        --Note overseer has some extra logic to update the item file paths
        --to use different relative paths based on param options that im not doing
        --yet. May do it if I find I need it
        --https://github.com/stevearc/overseer.nvim/blob/fe7b2f9ba263e150ab36474dfc810217b8cf7400/lua/overseer/component/on_output_parse.lua?plain=1#L66-L73
        local items = result.diagnostics or {}
        return items, lines
    else
        local items = vim.fn.getqflist({
            lines = lines,
            efm = opts.efm,
        }).items
        return items, lines
    end
end

---Checks if the list specified by opts exists
---@param opts? GetListEntriesOpts the list opts
---@return boolean exists
function M.is_existing_list(opts)
    opts = opts or {}
    local result
    if type(opts.filewin) == 'number' then
        ---@type my.fn.getlist.result
        result = vim.fn.getloclist(opts.filewin, {
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
---@param filewin? integer the window number or the |window-ID|. When {win} is zero the current window's location list is used. When nil the quickfix list is used.
---@param what vim.fn.setqflist.what
---@return boolean success true if was successfully able to set the list
function M.set_list(filewin, action, what)
    --Notes: for a higheer level api:
    --when `what` has no dictionary entry the error  `E5108: Lua: Vim:E715: Dictionary required` will be thrown
    local response
    if filewin == nil then
        response = vim.fn.setqflist({}, action, what)
    else
        --TODO setloclist when winnr is the winnr of a location list
        --will not create a location list for that location list. Instead it
        --will just update the current list
        response = vim.fn.setloclist(filewin, {}, action, what)
    end
    return response == 0 -- 0 means success, -1 means failure
end

---Checks if the quickix list is open in the specified tab
---@param opts? IsListOpenOpts (default:quickfix list)
function M.is_open(opts)
    opts = opts or {}
    local list = M.get_list({
        filewin = opts.filewin,
        id = opts.id,
        nr = opts.nr,
    })

    if list == nil then return false end

    -- If the qfbufnr is nil then either the quickfix window
    -- has never been opened or the buffer was wipedout
    if list.qfbufnr == nil then return false end

    --We check that the list specified by id and nr is is the same as the
    --current list that would be visible in the list buffer
    local current_list = M.get_list({ filewin = opts.filewin })
    if current_list == nil then
        error(
            'Invalid assumption: wth how can the current list not exist if a previous list already exists'
        )
    end
    if list.id ~= current_list.id then
        return false --since the selected list isn't the list open we return false
    end

    --If the tab we are searching for the list window is the current tab then
    --we just need to check that the qfwinid exists that
    --the list window doesn't exist in the current tab.
    local tabid = opts.tabid or vim.api.nvim_get_current_tabpage()
    local tabnr = vim.api.nvim_tabpage_get_number(tabid)
    if
        tabnr
        == vim.api.nvim_tabpage_get_number(vim.api.nvim_get_current_tabpage())
    then
        return list.qfwinid ~= nil
    end

    -- If we are not searching for the list window in the current tab then we
    -- need to iterate over all the windows and check if the list is open in the
    -- tab we are searching in
    local loclist_search_value = opts.filewin ~= nil and 1 or 0
    for _, win in pairs(vim.fn.getwininfo()) do
        if
            win.tabnr == tabnr
            and win.bufnr == list.qfbufnr
            and win.quickfix == 1
            and win.loclist == loclist_search_value
        then
            return true
        end
    end
    return false
end

---Opens the list window
---Note: For now Im going to keep this simple and not try to deal
---with tabnr, nr, id, height, or an enter flag.
---Notes:
---@param opts OpenListOpts
function M.open_list_window(opts)
    if M.is_open({ filewin = opts.filewin }) then
        return --window is already open
    end

    local qfwinid

    --nvim_win_call allows two things
    --1. We can open the any location list not just the one for the current window
    --2. The active window will change back to the window before the opening the
    --   list since copen/lopen by default change the active window to the list window
    --
    --The downside of using nvim_win_call is that it causes a redraw flicker when
    --switching back to a original tab if enter=false
    vim.api.nvim_win_call(opts.filewin or 0, function()
        if M.get_list({ opts.filewin }) == nil then
            --Creates a dummy list because of quirks with lopen and copen
            -- - lopen: will error with E5108 if no list exists yet
            -- - copen: won't error but if setqflist has never been called then the
            --          the id will still be zero which get_list treats as the list
            --          not existing
            M.set_list(opts.filewin, ' ', { title = '' })
        end
        if opts.filewin ~= nil then
            vim.cmd.lopen()
        else
            vim.cmd.copen()
        end
        --We get the winnr from get_list because we want to make sure that the
        --we get the quickfix window id even if lopen/copen didn't change the
        --active window for some unexpected reason. We also do this check within
        --the nvim_win_call because otherwise M.get_list will return the qfwinid
        --for the tab used to call open_list_window which may not be the tab that
        --the location list was opened in.
        local list = M.get_list({ filewin = opts.filewin })
        -- vim.print(list)
        if list ~= nil and list.qfwinid ~= nil then qfwinid = list.qfwinid end
    end)

    if (opts.enter == nil or opts.enter) and qfwinid ~= nil then
        vim.api.nvim_set_current_win(qfwinid)
    end
end

function M.close_list_window(opts)
    if opts.winnr ~= nil then
        vim.api.nvim_win_call(opts.winnr, function() vim.cmd.lclose() end)
    else
        vim.cmd.cclose()
    end
end

function M.toggle_list_window(opts) end

return M
