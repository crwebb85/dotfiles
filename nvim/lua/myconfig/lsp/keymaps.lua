M = {}

---Based on nvim runtime files
---Handle what to do if LSP returns a list of locations
---@param opts vim.lsp.LocationOpts.OnList
local function on_list_filter_dups(opts)
    local bufnr = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local from = vim.fn.getpos('.')
    from[1] = bufnr
    local tagname = vim.fn.expand('<cword>')
    local all_items = opts.items
    local title = opts.title
    local reuse_win = false -- Not sure if I want true or false

    local seen = {}
    local filtered_items = {}
    for i, item in ipairs(all_items) do
        local key = vim.inspect({
            col = item.col,
            end_col = item.end_col,
            end_lnum = item.end_lnum,
            filename = vim.fs.abspath(vim.fs.normalize(item.filename)),
            lnum = item.lnum,
        })
        if not seen[key] then
            -- vim.print(string.format('new: %s', i))
            seen[key] = true
            table.insert(filtered_items, item)
            -- else
            --     vim.print(string.format('old: %s', i))
        end
    end

    if #filtered_items == 1 then
        local item = filtered_items[1]
        local b = item.bufnr or vim.fn.bufadd(item.filename)

        -- Save position in jumplist
        vim.cmd("normal! m'")
        -- Push a new item into tagstack
        local tagstack = { { tagname = tagname, from = from } }
        vim.fn.settagstack(vim.fn.win_getid(win), { items = tagstack }, 't')

        vim.bo[b].buflisted = true
        local w = win
        if reuse_win then
            w = vim.fn.win_findbuf(b)[1] or w
            if w ~= win then vim.api.nvim_set_current_win(w) end
        end
        vim.api.nvim_win_set_buf(w, b)
        vim.api.nvim_win_set_cursor(w, { item.lnum, item.col - 1 })
        vim._with({ win = w }, function()
            -- Open folds under the cursor
            vim.cmd('normal! zv')
        end)
        return
    end

    -- if opts.loclist then
    --     vim.fn.setloclist(0, {}, ' ', { title = title, items = filtered_items })
    --     vim.cmd.lopen()
    -- else
    vim.fn.setqflist({}, ' ', { title = title, items = filtered_items })
    vim.cmd('botright copen')
    -- end
end

---Sets keymaps for the lsp buffer
function M.setup_lsp_keymaps()
    vim.keymap.set('n', 'K', function()
        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.hover').hover()
        else
            vim.lsp.buf.hover()
        end
    end, {
        desc = [[LSP: Displays hover information about the symbol under the cursor in a floating window. Calling the function twice will jump into the floating window.]],
    })
    vim.keymap.set('n', 'gd', function()
        -- vim.cmd([[norm! m']]) -- This adds the current location to the jumplist. There must be some change to how jumplists work that made me have to add this line and I should check the changelog.

        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.locations').goto_definition()
        -- elseif vim.bo.filetype == 'cs' then
        --     --I should probably be checking for if client is omnisharp but this is good enough
        --     require('omnisharp_extended').lsp_definition()
        elseif
            #vim.lsp.get_clients({
                bufnr = 0,
                method = vim.lsp.protocol.Methods.textDocument_definition,
            }) > 1
        then
            --TODO change on_list to telescope on list for definition
            vim.lsp.buf.definition({ on_list = on_list_filter_dups })
        else
            --TODO change on_list to telescope on list for definition
            vim.lsp.buf.definition()
        end
    end, {
        desc = 'LSP: Jumps to the definition of the symbol under the cursor.',
    })
    vim.keymap.set('n', 'gD', function()
        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.locations').goto_declaration()
        elseif
            #vim.lsp.get_clients({
                bufnr = 0,
                method = vim.lsp.protocol.Methods.textDocument_declaration,
            }) > 1
        then
            --TODO change on_list to telescope on list for declaration
            vim.lsp.buf.declaration({ on_list = on_list_filter_dups })
        else
            --TODO change on_list to telescope on list for declaration
            vim.lsp.buf.declaration({})
        end
    end, {
        desc = 'LSP: Jumps to the declaration of the symbol under the cursor.',
    })
    vim.keymap.set('n', 'gi', function()
        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.locations').goto_implementation()
        -- elseif vim.bo.filetype == 'cs' then
        --     --I should probably be checking for if client is omnisharp but this is good enough
        --     require('omnisharp_extended').lsp_implementation()
        elseif
            #vim.lsp.get_clients({
                bufnr = 0,
                method = vim.lsp.protocol.Methods.textDocument_implementation,
            }) > 1
        then
            --TODO change on_list to telescope on list for implementation
            vim.lsp.buf.implementation({ on_list = on_list_filter_dups })
        else
            --TODO change on_list to telescope on list for implementation
            vim.lsp.buf.implementation({})
        end
    end, {
        desc = 'LSP: Lists all the implementations for the symbol under the cursor in the quickfix window.',
    })
    vim.keymap.set('n', 'go', function()
        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.locations').goto_type_definition()
        -- elseif vim.bo.filetype == 'cs' then
        --     --I should probably be checking for if client is omnisharp but this is good enough
        --     require('omnisharp_extended').lsp_type_definition()
        elseif
            #vim.lsp.get_clients({
                bufnr = 0,
                method = vim.lsp.protocol.Methods.textDocument_typeDefinition,
            }) > 1
        then
            --TODO change on_list to telescope on list for type_definition
            vim.lsp.buf.type_definition({ on_list = on_list_filter_dups })
        else
            --TODO change on_list to telescope on list for type_definition
            vim.lsp.buf.type_definition({})
        end
    end, {
        desc = 'LSP: Jumps to the definition of the type of the symbol under the cursor.',
    })

    vim.keymap.set('n', 'grr', function()
        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.locations').list_references()
        -- elseif vim.bo.filetype == 'cs' then
        --     --I should probably be checking for if client is omnisharp but this is good enough
        --     require('omnisharp_extended').lsp_references()
        elseif
            #vim.lsp.get_clients({
                bufnr = 0,
                method = vim.lsp.protocol.Methods.textDocument_references,
            }) > 1
        then
            vim.lsp.buf.references(nil, { on_list = on_list_filter_dups })
        else
            vim.lsp.buf.references(nil, {})
        end
    end, {
        desc = 'Remap LSP: Lists all the references to the symbol under the cursor in the quickfix window.',
    })

    vim.keymap.set('n', 'gs', function() vim.lsp.buf.signature_help() end, {
        desc = 'LSP: Displays signature information about the symbol under the cursor in a floating window.',
    })
    vim.keymap.set('i', '<C-S>', function() vim.lsp.buf.signature_help() end, {
        --TODO think I like this better than cmp signature_help
        desc = 'Remap LSP: Displays signature information about the symbol under the cursor in a floating window.',
    })

    --- Rename keymaps
    vim.keymap.set('n', 'grn', function()
        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.renamer').rename()
        else
            vim.lsp.buf.rename()
        end
    end, {
        desc = 'Remap LSP: Renames all references to the symbol under the cursor.',
    })

    ---Code Action keymaps
    vim.keymap.set(
        { 'n', 'x' },
        'gra',
        function() vim.lsp.buf.code_action() end,
        {
            desc = 'Remap LSP: Selects a code action available at the current cursor position.',
        }
    )

    vim.keymap.set(
        { 'v', 'n' },
        '<F3>',
        function() require('tiny-code-action').code_action({}) end,
        {
            desc = 'LSP - Actions Preview: Code action preview menu',
        }
    )

    vim.keymap.set('n', 'gl', function() vim.diagnostic.open_float() end, {
        desc = 'LSP Diagnostic: Show diagnostics in a floating window.',
    })

    vim.keymap.set(
        'n',
        '<leader>lr',
        function() require('myconfig.lsp.codelens').run() end,
        { desc = 'LSP: Run Codelens' }
    )
end

return M
