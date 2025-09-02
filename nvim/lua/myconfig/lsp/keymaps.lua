M = {}

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
        elseif vim.bo.filetype == 'cs' then
            --I should probably be checking for if client is omnisharp but this is good enough
            require('omnisharp_extended').lsp_definition()
        else
            vim.lsp.buf.definition()
        end
    end, {
        desc = 'LSP: Jumps to the definition of the symbol under the cursor.',
    })
    vim.keymap.set('n', 'gD', function()
        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            require('mark-code-action.locations').goto_declaration()
        else
            vim.lsp.buf.declaration()
        end
    end, {
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
