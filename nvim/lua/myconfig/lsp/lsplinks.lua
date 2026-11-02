--Based on https://github.com/icholy/lsplinks.nvim/blob/master/lua/lsplinks.lua
--Neovim now has native lsp link support so I only kept the code that underlines
--the link (TODO there may be a more native way to do this remaining function)

local M = {}

---@type table<integer, lsp.DocumentLink[]>
local links_by_buf = {} --TODO handle memory leaks

---@type integer
local ns = vim.api.nvim_create_namespace('lsplinks')

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
function M.get_lsp_links_by_bufnr(bufnr)
    bufnr = bufnr or 0
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
    return links_by_buf[bufnr] or {}
end

--- Highlight links in the current buffer
function M.display()
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
    for _, link in ipairs(M.get_lsp_links_by_bufnr()) do
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
        local throttle = require('myconfig.utils.timers').throttle
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
