local M = {
    ---@type boolean
    foldenable = true,

    ---@type boolean
    nerd_font_enabled = true,

    ---@type uinteger
    bigfile_filesize = 2, --MB

    ---@type string
    MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP = 'mycustomtextobjects',

    ---@type string[] list of mason programs that I don't want to automatically install on the machine I am running neovim on
    exclude_mason_install = {
        -- 'gopls',
        -- 'ruff-lsp',
        -- 'debugpy',
        -- 'markdown-oxide',
    },
}

return M
