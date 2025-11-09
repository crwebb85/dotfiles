local Set = require('myconfig.utils.datastructure').Set

local M = {}

---@class DedupeEntriesOpts
---@field entries vim.quickfix.entry[]
---Different modes will be used to dedupe in different ways
---Modes
---  - file: removes entries so that there is only one entry per bufnr (invalid and entries using filename are ignored)
---@field mode 'buffer'

---@param opts DedupeEntriesOpts
---@return vim.quickfix.entry[]
function M.dedupe(opts)
    if opts.mode == 'buffer' then
        local seen_bufnrs = {}
        ---@type vim.quickfix.entry[]
        local filtered_entries = {}

        for _, entry in ipairs(opts.entries) do
            if
                entry.bufnr == nil
                or entry.bufnr == 0
                or entry.valid == nil
                or entry.valid == 0
            then
                table.insert(filtered_entries, entry)
            elseif not seen_bufnrs[entry.bufnr] then
                table.insert(filtered_entries, entry)
                seen_bufnrs[entry.bufnr] = true
            end
        end
        return filtered_entries
    else
        error('invalid mode')
    end
end

---@class FilterEntriesOpts
---@field entries vim.quickfix.entry[]
---the window number or the |window-ID| the list is for. When {win} is zero
---the current window's location list is used. When nil the quickfix list is used.
---@field filter fun(entry: vim.quickfix.entry): boolean run on each entry. If true the entry will be kept.

---Filters out the entries based on if they are valid or not
---@param opts FilterEntriesOpts
---@return vim.quickfix.entry[]
function M.filter_entries(opts) return vim.tbl_filter(opts.filter, opts.entries) end

---expands the multiline entry text with lines below entry
---@param entries vim.quickfix.entry[]
---@return vim.quickfix.entry[]
function M.expand_multiline_text_entries(entries)
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

---@class GetTreesitterCaptureEntriesOpts
---@field query_group string
---@field capture_names string[]
---@field bufnr? integer (default: 0)

---expands the multiline entry text with lines below entry
---@param opts GetTreesitterCaptureEntriesOpts
---@return vim.quickfix.entry[]
function M.treesitter_capture_entries(opts)
    local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
    if bufnr == 0 then vim.api.nvim_get_current_buf() end

    local capture_names_set = Set:new({})
    for _, capture_name in ipairs(opts.capture_names) do
        capture_names_set:insert(capture_name)
    end

    if capture_names_set.size == 0 then
        vim.notify('No captures selected', vim.log.levels.WARN)
        return {}
    end

    local buf_name = vim.api.nvim_buf_get_name(bufnr)
    local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
    local parser = vim.treesitter.get_parser(bufnr, lang)
    if parser == nil then error('No treesitter parser') end

    local ok_query, query =
        pcall(vim.treesitter.query.get, lang, opts.query_group)
    if not ok_query or query == nil then error('No query files are found') end

    local items = {}

    for capture, captured_node, _, _ in
        query:iter_captures(parser:trees()[1]:root(), bufnr)
    do
        local capture_name = query.captures[capture]
        if capture_names_set:has(capture_name) then
            local lnum, col, end_lnum, end_col = captured_node:range()

            local text = vim.api.nvim_buf_get_text(
                bufnr,
                lnum,
                col,
                end_lnum,
                end_col,
                {}
            )
            local line_text = vim.trim(vim.fn.getline(lnum + 1))

            local item = {
                buf = bufnr,
                lnum = lnum + 1,
                end_lnum = end_lnum + 1,
                col = col + 1,
                end_col = end_col,
                text = string.format(
                    'Query:%s\nNode:%s\nText:\n%s',
                    capture_name,
                    vim.trim(text[1]),
                    line_text
                ),
                valid = 1,
            }
            if buf_name ~= nil and buf_name ~= '' then
                item.filename = buf_name
            end
            table.insert(items, item)
            -- TODO remove duplicates
        end
    end
    return items
end

return M
