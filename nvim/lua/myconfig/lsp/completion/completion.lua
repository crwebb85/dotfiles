local M = {}

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
        if vim.bo.filetype == 'TelescopePrompt' then
            --TODO probably move this to a filetype autocmd
            vim.b[bufnr].no_completion_auto_trigger = true
        end
        vim.api.nvim_create_autocmd('InsertCharPre', {
            group = group,
            buffer = bufnr,
            callback = function()
                if
                    -- guarding against state 'm' prevent this from running in dot-repeats
                    -- which as the feedkeys had a weird sideeffect of clearing the repeat
                    vim.fn.state('m') ~= 'm'
                    and require('myconfig.lsp.completion.completion_state').completion_auto_trigger_enabled
                    and not vim.b[bufnr].no_completion_auto_trigger
                then
                    if vim.bo.omnifunc == '' then
                        --Triggers buffer completion
                        vim.api.nvim_feedkeys(
                            vim.api.nvim_replace_termcodes(
                                '<C-x><C-n>',
                                true,
                                false,
                                true
                            ),
                            'n',
                            true
                        )
                    else
                        --Can't remember why I stopped using the function vim.lsp.completion.get()

                        --Triggers vim.bo.omnifunc which is normally lsp completion
                        vim.api.nvim_feedkeys(
                            vim.api.nvim_replace_termcodes(
                                '<C-x><C-o>',
                                true,
                                false,
                                true
                            ),
                            'n',
                            true
                        )
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
