local api = require('myconfig.quickfix.api')

local M = {}

---@class EntriesRange
---@field start_idx? integer
---@field end_idx? integer

---@class DedupeListEntriesOpts
---the window number or the |window-ID| the list is for. When {win} is zero
---the current window's location list is used. When nil the quickfix list is used.
---@field filewin? integer
---Different modes will be used to dedupe in different ways
---Modes
---  - file: removes entries so that there is only one entry per bufnr (invalid and entries using filename are ignored)
---@field mode 'buffer'
---@field range? EntriesRange

---@class ExpandMultilineTextListEntriesOpts
---the window number or the |window-ID| the list is for. When {win} is zero
---the current window's location list is used. When nil the quickfix list is used.
---@field filewin? integer

---@class SetDiagnosticListOpts : vim.diagnostic.setqflist.Opts, vim.diagnostic.setloclist.Opts
---the window number or the |window-ID| the list is for. When {win} is zero
---the current window's location list is used. When nil the quickfix list is used.
---@field filewin? integer

---@class SetBreakpointQueryListOpts
---the window number or the |window-ID| the list is for. When {win} is zero
---the current window's location list is used. When nil the quickfix list is used.
---@field filewin? integer

---@class SetTreesitterCaptureListOpts
---the window number or the |window-ID| the list is for. When {win} is zero
---the current window's location list is used. When nil the quickfix list is used.
---@field filewin? integer
---@field query_group string
---@field capture_names string[]
---@field bufnr? integer (default: 0)

---@param opts DedupeListEntriesOpts
function M.dedupe(opts)
    local entries = api.get_list_entries({ filewin = opts.filewin })
    entries = require('myconfig.quickfix.entries').dedupe({
        entries = entries or {},
        mode = opts.mode,
    })
    --TODO logic to only filter on the range selection (useful when selection entries
    --in visual mode)

    --Note 1: I don't change the title but maybe I should there are implications
    --around what item will be selected after the next update to the list
    --whether from this function or the original function that created the list
    --that I haven't thought through
    --
    --
    --Note 2: by updating I can't do colder to get previous results
    --
    --Note3: by using bar in commands like `:QFLspDiagnostics | QFRemoveDuplicateBuffers`
    --that might not be an issue
    api.set_list(opts.filewin, 'u', { items = entries })
end

---@class FilterValidListEntriesOpts
---the window number or the |window-ID| the list is for. When {win} is zero
---the current window's location list is used. When nil the quickfix list is used.
---@field filewin? integer
---@field inverse? boolean Inverses the filter so that only invalid entries are kept (default: false)

---@param opts FilterValidListEntriesOpts
function M.filter_valid_list_entries(opts)
    local entries = api.get_list_entries({ filewin = opts.filewin }) or {}

    local filter_func = function(item) return item.valid == 1 end
    if opts.inverse then
        filter_func = function(item) return item.valid == 0 end
    end

    local entries = require('myconfig.quickfix.entries').filter_entries({
        entries = entries,
        filter = filter_func,
    })
    api.set_list(opts.filewin, 'u', { items = entries })
end

---@param opts? ExpandMultilineTextListEntriesOpts
M.expand_multiline_text = function(opts)
    opts = opts or {}
    local entries = api.get_list_entries({ filewin = opts.filewin })
    if entries == nil then return end
    local expanded_entries =
        require('myconfig.quickfix.entries').expand_multiline_text_entries(
            entries
        )
    api.set_list(opts.filewin, 'u', { items = expanded_entries })
end

---@class CopyListOpts
---@field mode? 'replace' | 'append' (default: replace)

---@param from_list_selector GetListEntriesOpts
---@param to_list_selector GetListOpts
---@param opts? CopyListOpts
function M.copy_list(from_list_selector, to_list_selector, opts)
    opts = opts or { mode = 'replace' }
    local from_list = api.get_list(from_list_selector)
    if from_list == nil then
        error('the list defined by the from_list_selector does not exist')
    end

    local what = {
        context = from_list.context,
        title = from_list.title,
        items = from_list.items,
        id = to_list_selector.id,
        nr = to_list_selector.nr,
    }
    if opts.mode == 'replace' then
        api.set_list(to_list_selector.filewin, 'u', what)
    elseif opts.mode == 'append' then
        local current_to_list = api.get_list({
            filewin = to_list_selector.filewin,
            id = to_list_selector.id,
            nr = to_list_selector.nr,
        }) or {}

        if
            current_to_list.title ~= nil
            and string.sub(current_to_list.title, -1) ~= '+'
        then
            --we want to keep previous list in history
            --and keep idx position

            what.title = current_to_list.title .. '+'
            what.idx = current_to_list.idx
            local items = current_to_list.items
            for _, entry in ipairs(from_list.items) do
                table.insert(items, entry)
            end
            what.items = items

            api.set_list(to_list_selector.filewin, ' ', what)
        else
            --we want to append without keeping previous list
            --we also want to keep idx position

            what.title = current_to_list.title
            --Note 'a' behaves similar to 'u' but appends to entries to the list
            api.set_list(to_list_selector.filewin, 'a', what)
        end
    else
        error('Invalid mode')
    end
end

---Note: I can never remember what marks work
---in commands versus in keymaps so Im going to make it
---easy on myself and say this function is only intended to
---be used to from within usercommands
---@param opts? GetListEntriesOpts
function M.add_cursor_from_command(opts)
    opts = opts or {}

    local cursor_entry = {
        bufnr = vim.api.nvim_get_current_buf(),
        lnum = vim.fn.line('.'),
        text = vim.fn.getline('.'),
        col = vim.fn.col('.'),
    }

    local current_list = api.get_list(opts) or {}

    if
        current_list.title ~= nil
        and string.sub(current_list.title, -1) ~= '+'
    then
        --we want to keep previous list in history
        --and keep idx position

        local items = current_list.items
        table.insert(items, cursor_entry)
        local what = {
            title = current_list.title .. '+',
            idx = current_list.idx,
            items = items,
        }

        api.set_list(opts.filewin, ' ', what)
    else
        --we want to append without keeping previous list
        --we also want to keep idx position

        --Note 'a' behaves similar to 'u' but appends the entries to the list
        --title is preserved
        api.set_list(opts.filewin, 'a', {
            items = { cursor_entry },
            title = current_list.title,
        })
    end
end

---@param opts? SetBreakpointQueryListOpts
function M.set_breakpoints_list(opts)
    opts = opts or {}
    local DAP_QUICKFIX_TITLE = 'DAP Breakpoints'
    local entries =
        require('dap.breakpoints').to_qf_list(require('dap.breakpoints').get())
    local current_list = api.get_list({ filewin = opts.filewin }) or {}
    local current_qflist_title = current_list.title
    local action = ' '
    if current_qflist_title == DAP_QUICKFIX_TITLE then action = 'u' end

    api.set_list(opts.filewin, action, {
        items = entries,
        title = DAP_QUICKFIX_TITLE,
    })
    if #entries == 0 then
        vim.notify('No breakpoints set!', vim.log.levels.INFO)
    end
end

---set the location or quickfix list with diagnostics
---@param opts SetDiagnosticListOpts
function M.set_diagnostic_list(opts)
    if opts.filewin == nil then
        vim.diagnostic.setqflist(opts)
    else
        --TODO ugh setloclist only sets the diagnostics for
        --the current buffer
        vim.diagnostic.setloclist(opts)
    end
end

---Sets the quickfix list with the treesitter captures
---@param opts SetTreesitterCaptureListOpts
function M.set_treesitter_capture_list(opts)
    local entries =
        require('myconfig.quickfix.entries').treesitter_capture_entries({
            query_group = opts.query_group,
            capture_names = opts.capture_names,
            bufnr = opts.bufnr,
        })

    local title = string.format('Treesitter Capture: %s', opts.query_group)
    local current_list = api.get_list({ filewin = opts.filewin }) or {}
    local current_qflist_title = current_list.title
    local action = ' '
    if current_qflist_title == title then action = 'u' end

    api.set_list(opts.filewin, action, {
        items = entries,
        title = title,
    })
    if #entries == 0 then
        vim.notify('No captures set!', vim.log.levels.INFO)
    end
end

return M
