--Parameters I like to change depending on the machine I am using
local M = {
    ---@type boolean
    foldenable = true,

    ---@type boolean
    nerd_font_enabled = true,
    -- nerd_font_enabled = false,

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

    enable_render_markdown = true,

    dev_plugins_path = 'C:\\Users\\crweb\\Documents\\projects\\',

    ---@type boolean
    -- use_native_completion = true,
    use_native_completion = false,

    use_overseer_strategy_hack = false,
    -- use_overseer_strategy_hack = true,
}

return M
