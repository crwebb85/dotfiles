vim.keymap.set(
    { 'x', 'o' },
    'ib', --Note I can't use more than two keys or `:MoltenEvaluateOperator<CR>i<extrakeys>b` won't work I don't know if it is a bug or something I don't understand about operators
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@block.inner',
            'textobjects'
        )
    end,
    {
        desc = 'Custom override: Select inner markdown codeblock',
    }
)

vim.keymap.set(
    { 'x', 'o' },
    'ab', --Note I can't use more than two keys or `:MoltenEvaluateOperator<CR>a<extrakeys>b` won't work I don't know if it is a bug or something I don't understand about operators
    function()
        require('nvim-treesitter-textobjects.select').select_textobject(
            '@block.outer',
            'textobjects'
        )
    end,
    {
        desc = 'Custom override: Select outer markdown codeblock',
    }
)
