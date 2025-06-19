--Based on https://github.com/icholy/lsplinks.nvim/blob/master/lua/lsplinks.lua

local M = {}

---@type table<integer, lsp.DocumentLink[]>
local links_by_buf = {} --TODO handle memory leaks

---@type integer
local ns = vim.api.nvim_create_namespace('lsplinks')

---@return lsp.Position
local function get_cursor_pos()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1 -- adjust line number for 0-indexing
    local character = vim.lsp.util.character_offset(0, line, cursor[2], 'utf-8')
    return { line = line, character = character }
end

---@param pos lsp.Position
---@param range lsp.Range
---@return boolean
local function in_range(pos, range)
    if pos.line > range.start.line and pos.line < range['end'].line then
        return true
    elseif pos.line == range.start.line and pos.line == range['end'].line then
        return pos.character >= range.start.character
            and pos.character <= range['end'].character
    elseif pos.line == range.start.line then
        return pos.character >= range.start.character
    elseif pos.line == range['end'].line then
        return pos.character <= range['end'].character
    else
        return false
    end
end

--- Return the link under the cursor.
---
---@return string | nil
function M.current()
    local cursor = get_cursor_pos()
    for _, link in ipairs(M.get()) do
        if in_range(cursor, link.range) then return link.target end
    end
    return nil
end

--- Return the uri without the fragment
---
---@param uri string
---@return string
local function remove_uri_fragment(uri)
    local fragment_index = uri:find('#')
    if fragment_index ~= nil then uri = uri:sub(1, fragment_index - 1) end
    return uri
end

--- Open the link under the cursor if one exists.
--- The return value indicates if a link was found.
---
---@param uri string | nil
---@return boolean
function M.open(uri)
    uri = uri or M.current()
    if not uri then return false end
    if uri:find('^file:/') then
        vim.lsp.util.show_document(
            { uri = remove_uri_fragment(uri) },
            'utf-8',
            {
                reuse_win = true,
                focus = true,
            }
        )
        local line_no, col_no = uri:match('.-#(%d+),(%d+)')
        if line_no then
            vim.api.nvim_win_set_cursor(
                0,
                { tonumber(line_no), tonumber(col_no) - 1 }
            )
        end
    else
        vim.ui.open(uri)
    end
    return true
end

--- Convenience function which opens current link with fallback
--- to default gx behaviour
function M.gx()
    local uri = M.current() or vim.fn.expand('<cfile>')
    M.open(uri)
end

-- Refresh the links for the current buffer
function M.refresh()
    local cur_bufnr = vim.api.nvim_get_current_buf()

    local clients = vim.lsp.get_clients({
        bufnr = cur_bufnr,
        method = vim.lsp.protocol.Methods.textDocument_documentLink,
    })
    if #clients <= 0 then return end

    local params = { textDocument = vim.lsp.util.make_text_document_params() }
    vim.lsp.buf_request(
        0,
        vim.lsp.protocol.Methods.textDocument_documentLink,
        params,
        function(err, result, ctx)
            if err then
                vim.lsp.log.error('lsplinks', err)
                return
            end
            if not links_by_buf[ctx.bufnr] then
                vim.api.nvim_buf_attach(ctx.bufnr, false, {
                    on_detach = function(b) links_by_buf[b] = nil end,
                    on_lines = function(_, b, _, first_lnum, last_lnum)
                        vim.api.nvim_buf_clear_namespace(
                            b,
                            ns,
                            first_lnum,
                            last_lnum
                        )
                    end,
                })
            end
            links_by_buf[ctx.bufnr] = result
            M.display()
        end
    )
end

--- Get links for bufnr
---@param bufnr integer | nil
---@return lsp.DocumentLink[]
function M.get(bufnr)
    bufnr = bufnr or 0
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
    return links_by_buf[bufnr] or {}
end

--- Highlight links in the current buffer
function M.display()
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
    for _, link in ipairs(M.get()) do
        -- sometimes the buffer is changed before we get here and the link
        -- ranges are invalid, so we ignore the error.
        pcall(
            vim.api.nvim_buf_set_extmark,
            0,
            ns,
            link.range.start.line,
            link.range.start.character,
            {
                end_row = link.range['end'].line,
                end_col = link.range['end'].character,
                hl_group = 'Underlined',
            }
        )
    end
end

-- If I ever modify the code to enable/disable I will probably also
-- need to close the timer or I may have a memory leak.
local refresh_timer
local throttled_refresh_lsplink
local is_autocmds_setup = false
function M.enable()
    if is_autocmds_setup then return end
    is_autocmds_setup = true

    if throttled_refresh_lsplink == nil then
        local throttle = require('utils.timers').throttle
        throttled_refresh_lsplink, refresh_timer = throttle(M.refresh, 30)
    end

    vim.api.nvim_create_autocmd(
        { 'InsertLeave', 'BufEnter', 'CursorHold', 'LspAttach' },
        {
            group = vim.api.nvim_create_augroup('lsplinks', { clear = true }),
            callback = throttled_refresh_lsplink,
        }
    )
end

return M
