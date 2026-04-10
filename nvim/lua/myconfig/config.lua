--Parameters I like to change depending on the machine I am using
local M = {
    ---@type boolean
    foldenable = true,

    ---@type boolean
    nerd_font_enabled = true,
    -- nerd_font_enabled = false,

    ---@type uinteger
    bigfile_filesize = 2, --MB

    ---@type boolean
    enable_render_markdown = true,
    -- enable_render_markdown = false,

    dev_plugins_path = 'C:\\Users\\crweb\\Documents\\projects\\',

    ---@type boolean
    use_overseer_strategy_hack = false,
    -- use_overseer_strategy_hack = true,

    ---This is weird for some reason I sometime need to add the cwd to my overseer
    ---riggrep usercommand and it is related to the use_overseer_strategy_hack
    ---however it is not consistent between machines as to when I should use this
    ---base on the use_overseer_strategy_hack value. As a result I need to toggle this
    ---base on how my machine behaves
    ---@type boolean
    -- use_cwd_in_overseer_grep_hack = true,
    use_cwd_in_overseer_grep_hack = false,

    ---@type boolean
    use_telescope_for_vim_ui_select = false,
    -- use_telescope_for_vim_ui_select = true,

    ---@type boolean
    use_extui = true,
    -- use_extui = false,

    ---@type boolean
    use_experimental_gf = true,
    -- use_experimental_gf = false,

    ---@type string[] list of mason programs that I don't want to automatically install on the machine I am running neovim on
    exclude_mason_install = {
        -- 'gopls',
        -- 'ruff-lsp',
        -- 'debugpy',
        -- 'markdown-oxide',
        -- 'lua-language-server',
        'emmylua_ls',
    },

    ---@type string[]
    treesiter_ensure_installed = {
        'c',
        'lua',
        'vim',
        'vimdoc',
        'markdown',

        'markdown_inline',
        'diff',
        'javascript',
        'typescript',
        'tsx',
        'css',
        'json',
        'html',
        'xml',
        'yaml',
        'rust',
        'query',
        'python',
        'toml',
        'regex',
        'c_sharp',
        'razor',
        'hurl',
        'powershell',
        'git_config',
        'git_rebase',
        'gitattributes',
        'gitcommit',
        'gitignore',
        'apex',
    },
}

return M
