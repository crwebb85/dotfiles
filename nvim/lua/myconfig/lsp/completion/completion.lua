local M = {}

---@param keys string
local function feedkeys(keys)
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(keys, true, false, true),
        'n',
        true
    )
end

function M.enable(enable, client_id, bufnr)
    -- Enable native completion.
    if require('myconfig.config').use_native_completion then
        vim.lsp.completion.enable(enable, client_id, bufnr, {
            -- Disabled autotrigger because I want to handle it myself
            -- so it will trigger on all characters not just the
            -- LSP `triggerCharacters
            autotrigger = false,
        })

        --Auto trigger on each keypress
        -- TODO:
        --  - [x] add a way to toggle this (probably use my <c-e> remap)
        --  - [ ] add debounce logic
        local group = vim.api.nvim_create_augroup(
            string.format('my.lsp.completion_%d', bufnr),
            { clear = true }
        )

        vim.api.nvim_create_autocmd('InsertCharPre', {
            group = group,
            buffer = bufnr,
            callback = function()
                if
                    require('myconfig.lsp.completion.completion_state').completion_auto_trigger_enabled
                then
                    if vim.bo.omnifunc == '' then
                        feedkeys('<C-x><C-n>') --Triggers buffer completion
                    else
                        -- vim.lsp.completion.get()
                        feedkeys('<C-x><C-o>') --Triggers vim.bo.omnifunc which is normally lsp completion
                    end
                end
            end,
        })

        -- require('myconfig.lsp.completion.omnifunc')
        -- vim.bo[event.buf].omnifunc = 'v:lua.MyOmnifunc'

        require('myconfig.lsp.completion.documentation').show_complete_documentation(
            bufnr
        )
    end
end

return M
