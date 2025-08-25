return {
    -- on_init = function(client)
    --     local path = client.workspace_folders[1].name
    --     -- if
    --     --     vim.loop.fs_stat(path .. '/.luarc.json')
    --     --     or vim.loop.fs_stat(path .. '/.luarc.jsonc')
    --     -- then
    --     --     return
    --     -- end
    --     vim.print('extend')
    --     vim.print(client.config.settings)
    --     client.config.settings.Lua =
    --         vim.tbl_deep_extend('force', client.config.settings.Lua, {
    --             runtime = {
    --                 -- Tell the language server which version of Lua you're using
    --                 -- (most likely LuaJIT in the case of Neovim)
    --                 version = 'LuaJIT',
    --             },
    --             -- Make the server aware of Neovim runtime files
    --             workspace = {
    --                 checkThirdParty = false,
    --                 -- library = {
    --                 --     vim.env.VIMRUNTIME,
    --                 --     -- Depending on the usage, you might want to add additional paths here.
    --                 --     -- "${3rd}/luv/library"
    --                 --     -- "${3rd}/busted/library",
    --                 -- },
    --                 -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
    --                 library = vim.api.nvim_get_runtime_file('', true),
    --             },
    --             diagnostics = {
    --                 -- Get the language server to recognize the `vim` global
    --                 globals = { 'vim' },
    --             },
    --         })
    --     vim.print(client.config.settings)
    -- end,
    settings = {
        Lua = {
            runtime = { version = 'LuaJIT' },
            hint = { enable = true },
            -- workspace = {
            --     checkThirdParty = false,
            --     library = {
            --         vim.env.VIMRUNTIME .. '/lua',
            --         --     -- Depending on the usage, you might want to add additional paths here.
            --         --     -- "${3rd}/luv/library"
            --         --     -- "${3rd}/busted/library",
            --     },
            --     -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
            --     -- library = vim.api.nvim_get_runtime_file('', true),
            -- },
            -- diagnostics = {
            --     -- Get the language server to recognize the `vim` global
            --     globals = { 'vim' },
            -- },
        },
    },
}
