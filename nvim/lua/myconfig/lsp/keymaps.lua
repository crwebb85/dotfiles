M = {}

local function pumvisible() return tonumber(vim.fn.pumvisible()) ~= 0 end

---@param keys string
local function feedkeys(keys)
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(keys, true, false, true),
        'n',
        true
    )
end

---Sets keymaps for the lsp buffer
---@param bufnr integer
---@param client vim.lsp.Client
function M.setup_lsp_keymaps(bufnr, client)
    vim.keymap.set('n', 'K', function()
        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.hover').hover()
        else
            vim.lsp.buf.hover()
        end
    end, {
        buffer = bufnr,
        desc = [[LSP: Displays hover information about the symbol under the cursor in a floating window. Calling the function twice will jump into the floating window.]],
    })
    vim.keymap.set('n', 'gd', function()
        -- vim.cmd([[norm! m']]) -- This adds the current location to the jumplist. There must be some change to how jumplists work that made me have to add this line and I should check the changelog.

        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.locations').goto_definition()
        elseif vim.bo.filetype == 'cs' then
            --I should probably be checking for if client is omnisharp but this is good enough
            require('omnisharp_extended').lsp_definition()
        else
            vim.lsp.buf.definition()
        end
    end, {
        buffer = bufnr,
        desc = 'LSP: Jumps to the definition of the symbol under the cursor.',
    })
    vim.keymap.set('n', 'gD', function()
        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.locations').goto_declaration()
        else
            vim.lsp.buf.declaration()
        end
    end, {
        buffer = bufnr,
        desc = 'LSP: Jumps to the declaration of the symbol under the cursor.',
    })
    vim.keymap.set('n', 'gi', function()
        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.locations').goto_implementation()
        elseif vim.bo.filetype == 'cs' then
            --I should probably be checking for if client is omnisharp but this is good enough
            require('omnisharp_extended').lsp_implementation()
        else
            vim.lsp.buf.implementation()
        end
    end, {
        buffer = bufnr,
        desc = 'LSP: Lists all the implementations for the symbol under the cursor in the quickfix window.',
    })
    vim.keymap.set('n', 'go', function()
        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.locations').goto_type_definition()
        elseif vim.bo.filetype == 'cs' then
            --I should probably be checking for if client is omnisharp but this is good enough
            require('omnisharp_extended').lsp_type_definition()
        else
            vim.lsp.buf.type_definition()
        end
    end, {
        buffer = bufnr,
        desc = 'LSP: Jumps to the definition of the type of the symbol under the cursor.',
    })

    vim.keymap.set('n', 'grr', function()
        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.locations').list_references()
        elseif vim.bo.filetype == 'cs' then
            --I should probably be checking for if client is omnisharp but this is good enough
            require('omnisharp_extended').lsp_references()
        else
            vim.lsp.buf.references()
        end
    end, {
        buffer = bufnr,
        desc = 'Remap LSP: Lists all the references to the symbol under the cursor in the quickfix window.',
    })

    vim.keymap.set('n', 'gs', function() vim.lsp.buf.signature_help() end, {
        buffer = bufnr,
        desc = 'LSP: Displays signature information about the symbol under the cursor in a floating window.',
    })
    vim.keymap.set('i', '<C-S>', function() vim.lsp.buf.signature_help() end, {
        --TODO think I like this better than cmp signature_help
        buffer = bufnr,
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
        buffer = bufnr,
        desc = 'Remap LSP: Renames all references to the symbol under the cursor.',
    })

    ---Code Action keymaps
    vim.keymap.set(
        { 'n', 'x' },
        'gra',
        function() vim.lsp.buf.code_action() end,
        {
            buffer = bufnr,
            desc = 'Remap LSP: Selects a code action available at the current cursor position.',
        }
    )

    vim.keymap.set(
        { 'v', 'n' },
        '<F3>',
        function() require('tiny-code-action').code_action({}) end,
        {
            buffer = bufnr,
            desc = 'LSP - Actions Preview: Code action preview menu',
        }
    )

    vim.keymap.set('n', 'gl', function() vim.diagnostic.open_float() end, {
        buffer = bufnr,
        desc = 'LSP Diagnostic: Show diagnostics in a floating window.',
    })

    vim.keymap.set(
        'n',
        '<leader>lr',
        function() require('myconfig.lsp.codelens').run() end,
        { desc = 'LSP: Run Codelens', buffer = bufnr }
    )

    if
        client:supports_method(
            vim.lsp.protocol.Methods.textDocument_documentLink
        )
    then
        -- TODO reevaluate how I remap the gx key there might be better options
        vim.keymap.set('n', 'gx', require('myconfig.lsp.lsplinks').gx, {
            desc = 'LSP Remap: Open lsp links if exists. Otherwise, fallback to default neovim functionality for open link',
            buffer = bufnr,
        })
    end

    if require('myconfig.config').use_native_completion then
        --Note I previously used the following cmp confirm behavior for <CR>
        --```lua
        -- cmp.confirm({
        --     behavior = cmp.ConfirmBehavior.Insert,
        --     select = false,
        -- })
        -- ```
        -- and the following for <C-y>
        -- ```lua
        -- cmp.confirm({
        --     behavior = cmp.ConfirmBehavior.Replace,
        --     select = false,
        -- })
        -- TODO try to replicate that old functionality
        -- ```
        require('myconfig.utils.mapping').map_fallback_keymap(
            'i',
            '<CR>',
            function(fallback)
                local is_entry_active = true
                if pumvisible() and is_entry_active then
                    ---setting the undolevels creates a new undo break
                    ---so by setting it to itself I can create an undo break
                    ---without side effects just before a comfirming a completion.
                    -- Use <c-u> in insert mode to undo the completion
                    vim.cmd([[let &g:undolevels = &g:undolevels]])
                    feedkeys('<C-y>')
                else
                    fallback()
                end
            end,
            {
                desc = 'Custom Remap: Select active completion item or fallback',
            }
        )

        require('myconfig.utils.mapping').map_fallback_keymap(
            'i',
            '<C-e>',
            function(fallback)
                if pumvisible() then
                    fallback()
                else
                    if vim.bo.omnifunc == '' then
                        feedkeys('<C-x><C-n>')
                    else
                        feedkeys('<C-x><C-o>')
                    end
                end
            end,
            { desc = 'Custom Remap: Toggle completion window' }
        )

        require('myconfig.utils.mapping').map_fallback_keymap(
            { 'i', 's' },
            '<C-n>',
            function(fallback)
                local luasnip = require('luasnip')
                if luasnip.expand_or_jumpable() then
                    luasnip.expand_or_jump()
                elseif vim.snippet.active({ direction = 1 }) then
                    vim.snippet.jump(1)
                else
                    fallback()
                end
            end,
            { desc = 'Custom Remap: Jump to next snippet location or fallback' }
        )

        require('myconfig.utils.mapping').map_fallback_keymap(
            { 'i', 's' },
            '<C-p>',
            function(fallback)
                local luasnip = require('luasnip')

                if luasnip.jumpable(-1) then
                    luasnip.jump(-1)
                elseif vim.snippet.active({ direction = -1 }) then
                    vim.snippet.jump(-1)
                else
                    fallback()
                end
            end,
            {
                desc = 'Custom Remap: Jump to previous snippet location or fallback',
            }
        )

        require('myconfig.utils.mapping').map_fallback_keymap(
            { 'i', 's' },
            '<C-u>',
            function(fallback)
                if pumvisible() then
                    require('myconfig.lsp.completion.documentation').scroll_docs(
                        -4
                    )
                else
                    fallback()
                end
            end,
            {
                desc = 'Custom Remap: Scroll up documentation window or fallback',
            }
        )

        require('myconfig.utils.mapping').map_fallback_keymap(
            { 'i', 's' },
            '<C-d>',
            function(fallback)
                if pumvisible() then
                    require('myconfig.lsp.completion.documentation').scroll_docs(
                        4
                    )
                else
                    fallback()
                end
            end,
            {
                desc = 'Custom Remap: Scroll down documentation window or fallback',
            }
        )

        vim.keymap.set({ 'i', 's' }, '<C-t>', function()
            local is_hidden =
                require('myconfig.lsp.completion.documentation').is_documentation_disabled()
            require('myconfig.lsp.completion.documentation').hide_docs(
                not is_hidden
            )
        end, {
            desc = 'Custom Remap: Toggle the completion docs',
        })
    end
end

return M
