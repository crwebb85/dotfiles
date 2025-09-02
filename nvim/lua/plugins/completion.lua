local config = require('myconfig.config')

--TODO add something custom similar to https://github.com/petertriho/cmp-git

local luasnip_plugin = {
    'L3MON4D3/LuaSnip',
    lazy = true,
    dependencies = {
        'rafamadriz/friendly-snippets',
        {
            'benfowler/telescope-luasnip.nvim',
            dependencies = {
                'nvim-telescope/telescope.nvim',
            },
            config = function() require('telescope').load_extension('luasnip') end,
        },
    },
    config = function(_, opts)
        if opts then require('luasnip').config.setup(opts) end
        vim.tbl_map(
            function(type) require('luasnip.loaders.from_' .. type).lazy_load() end,
            { 'vscode', 'snipmate', 'lua' }
        )
        local config_path = vim.fn.stdpath('config')
        if config_path ~= nil and type(config_path) == 'string' then
            local luasnip_path = vim.fs.joinpath(config_path, 'LuaSnip/')
            require('luasnip.loaders.from_lua').load({
                paths = {
                    luasnip_path,
                },
            })
        end
        -- friendly-snippets - enable standardized comments snippets
        require('luasnip').filetype_extend('typescript', { 'tsdoc' })
        require('luasnip').filetype_extend('javascript', { 'jsdoc' })
        require('luasnip').filetype_extend('lua', { 'luadoc' })
        require('luasnip').filetype_extend('python', { 'pydoc' })
        require('luasnip').filetype_extend('rust', { 'rustdoc' })
        require('luasnip').filetype_extend('cs', { 'csharpdoc' })
        require('luasnip').filetype_extend('java', { 'javadoc' })
        require('luasnip').filetype_extend('c', { 'cdoc' })
        require('luasnip').filetype_extend('cpp', { 'cppdoc' })
        require('luasnip').filetype_extend('php', { 'phpdoc' })
        require('luasnip').filetype_extend('kotlin', { 'kdoc' })
        require('luasnip').filetype_extend('ruby', { 'rdoc' })
        require('luasnip').filetype_extend('sh', { 'shelldoc' })
    end,
}

local completion_plugins = {
    {
        --This is only used so that I don't have to create cmp file for monkey patching
        --cmp utilities when using cmp-buffer in native completion
        --TODO once I have fully converted to native completion consider
        --removing this
        'hrsh7th/nvim-cmp',
        lazy = true,
        config = function(_, _)
            --Monkey patch the functions that plugins depend on
            require('cmp').register_source = function(_, _) end
        end,
    },
    {
        -- Completion for words in buffer
        'hrsh7th/cmp-buffer',
        lazy = true,
    },
    luasnip_plugin,
    {
        'crwebb85/luasnip-lsp-server.nvim',
        dependencies = {
            { 'L3MON4D3/LuaSnip' },
        },
        -- dev = true,
        config = true,
    },
    --Including these plugins so that they stay in my lock file even when I have them disabled
    --remove once I remove nvim-cmp
    { 'hrsh7th/cmp-cmdline', lazy = true },
    { 'hrsh7th/cmp-nvim-lsp-signature-help', lazy = true },
    { 'hrsh7th/cmp-path', lazy = true },
    { 'saadparwaiz1/cmp_luasnip', lazy = true },
    { 'onsails/lspkind.nvim', lazy = true },
}
if not config.use_native_completion then
    completion_plugins = {
        {
            'hrsh7th/nvim-cmp',
            lazy = true,
            event = { 'InsertEnter', 'CmdlineEnter' },
            dependencies = {
                { 'L3MON4D3/LuaSnip' },
                { 'saadparwaiz1/cmp_luasnip' }, -- Completion for snippets
                { 'hrsh7th/cmp-buffer' }, -- Completion for words in buffer
                { 'hrsh7th/cmp-path' }, -- Completion for file paths
                { 'hrsh7th/cmp-cmdline' },
                { 'hrsh7th/cmp-nvim-lsp-signature-help' }, -- Provides signature info while typing function parameters
                { 'onsails/lspkind.nvim' }, -- Helps format the cmp selection items
            },

            config = function()
                local cmp = require('cmp')

                local cmdline_mappings = {
                    ['<C-z>'] = {
                        c = function()
                            if cmp.visible() then
                                cmp.select_next_item()
                            else
                                cmp.complete()
                            end
                        end,
                    },
                    ['<Tab>'] = {
                        c = function()
                            if cmp.visible() then
                                cmp.select_next_item()
                            else
                                cmp.complete()
                            end
                        end,
                    },
                    ['<S-Tab>'] = {
                        c = function()
                            if cmp.visible() then
                                cmp.select_prev_item()
                            else
                                cmp.complete()
                            end
                        end,
                    },
                    ['<C-n>'] = {
                        c = function(fallback)
                            if cmp.visible() then
                                cmp.select_next_item()
                            else
                                fallback()
                            end
                        end,
                    },
                    ['<C-p>'] = {
                        c = function(fallback)
                            if cmp.visible() then
                                cmp.select_prev_item()
                            else
                                fallback()
                            end
                        end,
                    },
                    --Toggle showing completion menu
                    ['<C-e>'] = cmp.mapping({
                        c = function()
                            if cmp.visible() then
                                cmp.close()
                            else
                                cmp.complete()
                            end
                        end,
                    }),
                }

                cmp.setup({
                    sources = cmp.config.sources({
                        { name = 'nvim_lsp' },
                        { name = 'nvim_lsp_signature_help' },
                        { name = 'nvim_lua' },
                        { name = 'luasnip' },
                        { name = 'buffer', keyword_length = 5 },
                        { name = 'path' },
                    }),
                    snippet = {
                        expand = function(args)
                            require('luasnip').lsp_expand(args.body)
                        end,
                    },
                    formatting = {
                        format = require('lspkind').cmp_format({
                            with_text = true,
                            menu = {
                                buffer = '[buf]',
                                nvim_lsp = '[LSP]',
                                path = '[path]',
                                luasnip = '[snip]',
                                git = '[git]',
                                cmdline = '[cmd]',
                                nvim_lsp_signature_help = '[info]',
                            },
                        }),
                    },
                    mapping = {}, --Clear default keymaps for buffer completion
                })

                cmp.setup.filetype('gitcommit', {
                    sources = cmp.config.sources({
                        { name = 'git' },
                        { name = 'luasnip' },
                        { name = 'buffer', keyword_length = 5 },
                    }),
                })

                -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
                cmp.setup.cmdline({ '/', '?' }, {
                    mapping = cmdline_mappings,
                    sources = {
                        { name = 'buffer', keyword_length = 3 },
                    },
                })

                -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
                cmp.setup.cmdline(':', {
                    mapping = cmdline_mappings,
                    sources = cmp.config.sources({
                        { name = 'path' },
                        { name = 'cmdline' },
                    }),
                })
            end,
        },

        {
            --This is only here so that it stays in my lazy lock file even when Im not using it because I am using cmp
            'crwebb85/luasnip-lsp-server.nvim',
            dependencies = {
                { 'L3MON4D3/LuaSnip' },
            },
            lazy = true,
        },
        luasnip_plugin,
    }
end

return completion_plugins
