vim.g.mapleader = ' '

local config = require('myconfig.config')
local plugin_setups = require('myconfig.plugin_setups')

local later_cache = {}
local execute_now = function(f, init_trace)
    local ok, err = xpcall(
        f,
        function(e) return debug.traceback(e .. '\n', 2) end
    )
    if ok then return true end
    init_trace = init_trace == nil and ''
        or ('\n\nTraceback of `later()` call:\n' .. init_trace)
    vim.notify(
        'Error during safe execution: ' .. err .. init_trace,
        vim.log.levels.WARN
    )
    return false
end
local execute_later = function()
    local timer = assert(vim.loop.new_timer())
    local f
    f = vim.schedule_wrap(function()
        local cb = later_cache[1]
        if cb == nil then
            if not timer:is_closing() then timer:close() end
            return
        end

        table.remove(later_cache, 1)
        execute_now(cb.f, cb.trace)
        timer:start(1, 0, f)
    end)
    -- Space out "later" executions to be sure that they don't block anything
    timer:start(1, 0, f)
end

--- Execute a function on a condition and warn on error
---
--- Input function is executed exactly once. Its possible error is captured and is
--- shown as a |vim.notify()| warning.
---
--- Useful to organize |init.lua| in fail-safe sections with simple lazy loading.
---
--- Queue the function to be executed soon without blocking the execution of next
--- code in file. Queued functions are executed in order they are added.
---
--- This is based on https://github.com/nvim-mini/mini.misc/blob/c72c90e083bcf24bfb2827d63b4752e414023f3e/lua/mini/misc.lua#L309
--- just with only the features I wanted

---@usage >lua
---   later(function()
---     vim.notify('This message was scheduled')
---   end)
local function later(f)
    -- TODO detect when the input is not a function and print a warning that I probably
    -- called the function directly not passed it in
    -- for example it should detect if I did `later(plugin_setups.setup_mark_code_action())`
    -- instead of `later(plugin_setups.setup_mark_code_action)`

    -- Compute traceback before delaying execution to provide more info
    local trace = debug.traceback('', 2)
    if #later_cache == 0 then vim.schedule(execute_later) end
    table.insert(later_cache, { f = f, trace = trace })
end

--- Execute a function on a condition and warn on error
---
--- Input function is executed exactly once. Its possible error is captured and is
--- shown as a |vim.notify()| warning.
---
--- This is based on https://github.com/nvim-mini/mini.misc/blob/c72c90e083bcf24bfb2827d63b4752e414023f3e/lua/mini/misc.lua#L309
--- just with only the features I wanted
---
---@usage >lua
---   now(function()
---     vim.notify('This will print now')
---   end)
local now = function(f)
    -- TODO detect when the input is not a function and print a warning that I probably
    -- called the function directly not passed it in
    -- for example it should detect if I did `now(plugin_setups.setup_mark_code_action())`
    -- instead of `now(plugin_setups.setup_mark_code_action)`

    -- Compute traceback before delaying execution to provide more info
    local init_trace = debug.traceback('', 2)

    local ok, err = xpcall(
        f,
        function(e) return debug.traceback(e .. '\n', 2) end
    )
    if ok then return true end
    init_trace = init_trace == nil and ''
        or ('\n\nTraceback of `now()` call:\n' .. init_trace)
    vim.notify(
        'Error during safe execution: ' .. err .. init_trace,
        vim.log.levels.WARN
    )
end

-------------------------------------------------------------------------------
---setup build step hooks
vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
        local name, kind = ev.data.spec.name, ev.data.kind
        if
            name == 'molten-nvim' and (kind == 'update' or kind == 'install')
        then
            if not ev.data.active then vim.cmd.packadd('molten-nvim') end
            later(
                function()
                    require('myconfig.notebook.notebook').my_update_remote_plugins()
                end
            )
        end
    end,
})

---@class MyTreesitterPackData
---@field location? string the relative path from the repo directory to the parsers source code (if nil assume the repo directory is the directory of the parser's source code)
---@field requires? string[] list of query names that the query files of the current parser require
---@field versioning_type 'HEAD'|'SEMVER' HEAD means the parser version goes by commit hash while SEMVER means the version follows semver tags
---@field filetypes? string[] additional filetypes to register the parser for
---@field generate? boolean Repo does not contain a `parser.c`; must be generated from grammar first
---@field generate_from_json? boolean Generate parser from `grammar.json` instead of `grammar.js` (default true)
---@field readme_note? string

---@class MyPackData
---@field load? boolean (defualt true)
---@field runtimepath? boolean (default true)
---@field dev? boolean (default false)
---@field treesitter? { [string]: MyTreesitterPackData }

---@class MyPackSpec : vim.pack.Spec
---@field data? MyPackData

---loads the plugin
---@param plugin_data {spec: MyPackSpec, path: string}
local function load_plugins(plugin_data)
    local data = plugin_data.spec.data or {}

    local load = vim.F.if_nil(data.load, true)
    local enable_runtimepath = vim.F.if_nil(data.runtimepath, true)
    local use_dev = vim.F.if_nil(data.dev, false)
    local plugin_path = plugin_data.path
    local plugin_name = plugin_data.spec.name

    if plugin_name == nil then
        error('plugin_name should not be nil on resolved plugin data')
    end

    if use_dev and load then
        local dev_plugin_base_path = config.dev_plugins_path
        local dev_path = vim.fs.joinpath(dev_plugin_base_path, plugin_name)
        if not require('myconfig.utils.path').is_directory(dev_path) then
            error(
                string.format(
                    'Cannot load dev plugin %s because directory does not exist: %s',
                    plugin_name,
                    dev_path
                )
            )
        end
        vim.opt.runtimepath:append(dev_path)
    end

    -- NOTE: The `:packadd` specifically seems to not handle spaces in dir name
    if enable_runtimepath and not use_dev then
        vim.cmd.packadd({
            vim.fn.escape(plugin_name, ' '),
            bang = not load,
            magic = { file = false },
        })
    end

    -- The `:packadd` only sources plain 'plugin/' files. Execute 'after/' scripts
    -- if not during startup (when they will be sourced later, even if
    -- `vim.pack.add` is inside user's 'plugin/')
    -- See https://github.com/vim/vim/issues/15584
    -- Deliberately do so after executing all currently known 'plugin/' files.
    if vim.v.vim_did_enter == 1 and load then
        local after_paths = vim.fn.glob(
            vim.fs.joinpath(plugin_path, 'after', 'plugin') .. '/**/*.{vim,lua}',
            false,
            true
        )
        vim.tbl_map(
            --- @param path string
            function(path) vim.cmd.source({ path, magic = { file = false } }) end,
            after_paths
        )
    end

    local treesitter = data.treesitter
    if treesitter ~= nil then
        for name, parser_info in pairs(treesitter) do
            local parser_source_path = plugin_path
            if parser_info.location ~= nil then
                parser_source_path =
                    vim.fs.joinpath(plugin_path, parser_info.location)
            end
            require('myconfig.treesitter').add_parser({
                requires = parser_info.requires,
                versioning_type = parser_info.versioning_type,
                readme_note = parser_info.readme_note,
                path = parser_source_path,
                generate = parser_info.generate_from_json,
                generate_from_json = vim.F.if_nil(
                    parser_info.generate_from_json,
                    true
                ),
                name = name,
                version = plugin_data.spec.version,
                filetypes = parser_info.filetypes,
            })
        end
    end
end

-------------------------------------------------------------------------------
---setup config
now(function()
    now(function() require('myconfig.options') end)
    now(function() require('myconfig.autocmd') end)
    now(function() require('myconfig.folding') end)
    now(function() require('myconfig.lsp') end)
    now(function() require('myconfig.mouse') end)
    now(function() require('myconfig.user_commands') end)
    now(function() require('myconfig.keymaps') end)
    now(function() require('myconfig.overrides') end)
    now(function() require('myconfig.test_harness') end)

    now(function()
        vim.cmd.packadd('cfilter')
        vim.cmd.packadd('nvim.difftool')
        ---Added the new native undo tree. I kindof like the old
        ---plugin better so Im going keep the old one and try this
        ---out on the side
        vim.cmd.packadd('nvim.undotree')
    end)

    ---@type (string|MyPackSpec)[] List of plugin specifications. String item
    local specs = {
        ---------------------------------------------------------------------------
        --- Color scheme
        { src = 'https://github.com/folke/tokyonight.nvim' }, -- we want colorscheme to install first

        ---------------------------------------------------------------------------
        -- Util plugins used by other plugins

        -- plenary is used by:
        --  - nvim-telescope/telescope.nvim
        --  - nvim-neotest/neotest
        { src = 'https://github.com/nvim-lua/plenary.nvim' },
        -- nvim-tree/nvim-web-devicons is used by:
        --  - sindrets/diffview.nvim
        { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
        -- nvim-mini/mini.icons is used by:
        --  - nvim-telescope/telescope.nvim
        --  - MeanderingProgrammer/render-markdown.nvim
        { src = 'https://github.com/nvim-mini/mini.icons' },

        -- nvim-treesitter/nvim-treesitter is used by:
        --  - MeanderingProgrammer/render-markdown.nvim
        --  - nvim-treesitter/nvim-treesitter-context
        --  - Wansmer/treesj
        --  - nvim-treesitter/nvim-treesitter-textobjects
        {
            src = 'https://github.com/nvim-treesitter/nvim-treesitter',
            version = 'main',
        },

        -- lewis6991/async.nvim is used by:
        -- - ThePrimeagen/refactoring.nvim
        { src = 'https://github.com/lewis6991/async.nvim' },

        -- nvim-neotest/nvim-nio is used by nvim-neotest/neotest
        { src = 'https://github.com/nvim-neotest/nvim-nio' },

        -- antoinemadec/FixCursorHold.nvim is used by:
        --  - nvim-neotest/neotest
        { src = 'https://github.com/antoinemadec/FixCursorHold.nvim' },

        -- nvim-lspconfig is used by/must run before:
        -- - williamboman/mason.nvim
        { src = 'https://github.com/neovim/nvim-lspconfig' },

        -- williamboman/mason.nvim is used by:
        -- - lsp plugins
        -- - testing plugins,
        -- - debugging plugins
        -- - conform.nvim
        { src = 'https://github.com/williamboman/mason.nvim' },

        -- b0o/schemastore.nvim is used by
        -- - .config\nvim\after\lsp\yamlls.lua
        -- - .config\nvim\after\lsp\jsonls.lua
        -- - my setup_mason_nvim function since that is what triggers enabling the lsps
        --   TODO may move the enabling lsps out of setup_mason_nvim
        --
        -- Helps configure which json and yaml schemas to use for the corresponding lsp
        -- Catalog of general schemas: https://www.schemastore.org/api/json/catalog.json
        -- Catalog of kubernetes schemas: https://github.com/datreeio/CRDs-catalog/tree/main
        -- Note: The setup for this plugin is in the lspconfig plugin's setup function
        { src = 'https://github.com/b0o/schemastore.nvim' },
        ---------------------------------------------------------------------------
        ---replacement for netrw
        {
            -- src = 'https://github.com/stevearc/oil.nvim',
            src = 'https://github.com/crwebb85/oil.nvim',
        },

        ---------------------------------------------------------------------------
        ---key map behavior
        { src = 'https://github.com/folke/which-key.nvim' },
        { src = 'https://github.com/max397574/better-escape.nvim' },

        ---------------------------------------------------------------------------
        ---misc

        { src = 'https://github.com/brianhuster/unnest.nvim' },
        { src = 'https://github.com/stevearc/profile.nvim' },

        ---------------------------------------------------------------------------
        --- HTTP testing
        {
            src = 'https://github.com/mistweaverco/kulala.nvim',
            data = {
                --This plugin ships with it's own treesitter parser that needs to be
                --built
                treesitter = {
                    kulala_http = {
                        location = 'lua/tree-sitter',
                        versioning_type = 'HEAD',
                    },
                },
            },
        },

        ---------------------------------------------------------------------------
        -- Git integration

        -- Adds Git commands
        { src = 'https://github.com/tpope/vim-fugitive' },
        -- Adds git diffview
        { src = 'https://github.com/sindrets/diffview.nvim' },
        -- Adds an API wrapper around git which I use in my heirline setup
        -- Adds Git blame
        -- Adds sidebar showing lines changed
        -- Add hunk navigation
        { src = 'https://github.com/lewis6991/gitsigns.nvim' },
        -- Easily get and goto git permalinks
        { src = 'https://github.com/linrongbin16/gitlinker.nvim' },
        -- Adds commands for handling git conflicts
        { src = 'https://github.com/akinsho/git-conflict.nvim' },

        ---------------------------------------------------------------------------
        -- File Navigation

        -- Fuzzy finder (for many things not just file finder)
        { src = 'https://github.com/nvim-telescope/telescope.nvim' },
        -- Harpoon (fast file navigation between pinned files)
        {
            src = 'https://github.com/ThePrimeagen/harpoon',
            version = 'harpoon2',
        },

        ---------------------------------------------------------------------------
        -- Undotree the solution to screw ups
        { src = 'https://github.com/mbbill/undotree' },

        ---------------------------------------------------------------------------
        --- Buffer operations

        -- Comment toggling
        { src = 'https://github.com/numToStr/Comment.nvim' },

        -- Adds motions to wrap text in quotes/brackets/tags/etc
        -- using the same motions I use to yank text
        { src = 'https://github.com/kylechui/nvim-surround' },

        -- Multicursor support
        { src = 'https://github.com/jake-stewart/multicursor.nvim' },

        -- Shows as virtual text the scope context when things like the function
        -- signature when it is outside the current windows view
        { src = 'https://github.com/nvim-treesitter/nvim-treesitter-context' },

        -- adds keymaps to split and join lines based on treesitter nodes
        { src = 'https://github.com/Wansmer/treesj' },

        -- adds textobjects for treesitter parsers
        {
            src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
            version = 'main',
        },
        -- adds substitution keymaps that act like paste keymaps but don't
        -- replace the * register
        { src = 'https://github.com/gbprod/substitute.nvim' },

        -- Adds refactor commands
        -- TODO I don't really use this but I would like to. I think I should create
        -- a custom lsp to supply these as code actions
        { src = 'https://github.com/ThePrimeagen/refactoring.nvim' },

        ---------------------------------------------------------------------------
        -- Testing

        { src = 'https://github.com/nvim-neotest/neotest' },

        -- Test adapters
        { src = 'https://github.com/rouge8/neotest-rust' }, -- TODO replace neotest-rust because it is archived
        { src = 'https://github.com/nvim-neotest/neotest-python' },
        { src = 'https://github.com/nsidorenco/neotest-vstest' },

        ---------------------------------------------------------------------------
        -- DEBUGGING

        -- DAP Client for nvim
        { src = 'https://github.com/mfussenegger/nvim-dap' },

        -- UI for the debugger
        -- - the debugger UI is also automatically opened when starting/stopping the debugger
        -- - toggle debugger UI manually with `<leader>du`
        { src = 'https://github.com/rcarriga/nvim-dap-ui' },

        -- Configuration for the python debugger
        { src = 'https://github.com/mfussenegger/nvim-dap-python' },

        ---------------------------------------------------------------------------
        --- LSP's and more
        { src = 'https://github.com/jmbuhr/otter.nvim' },
        { src = 'https://github.com/quarto-dev/quarto-nvim' },
        {
            src = 'https://github.com/benlubas/molten-nvim',
            version = 'v1.9.2',
        },
        --TODO use willothy/wezterm.nvim for image support for jupyter notebooks

        -- Configure snippets
        { src = 'https://github.com/L3MON4D3/LuaSnip' },
        { src = 'https://github.com/rafamadriz/friendly-snippets' },
        { src = 'https://github.com/benfowler/telescope-luasnip.nvim' },
        { src = 'https://github.com/crwebb85/luasnip-lsp-server.nvim' },

        -- Virtual Environments
        -- select virtual environments
        -- - makes pyright and debugpy aware of the selected virtual environment
        -- - Select a virtual environment with `:VenvSelect`
        {
            src = 'https://github.com/linux-cultist/venv-selector.nvim',
            version = 'main',
        },

        -- LSP client extensions
        { src = 'https://github.com/Decodetalkers/csharpls-extended-lsp.nvim' },

        -- A more robust code action menu
        -- depends on telescope.nvim
        { src = 'https://github.com/rachartier/tiny-code-action.nvim' },

        -- Code Action Macros
        {
            src = 'https://github.com/crwebb85/mark-code-action.nvim',
            data = {
                -- dev = true,
            },
        },

        ---------------------------------------------------------------------------
        --- Formatter
        { src = 'https://github.com/stevearc/conform.nvim' },

        ---------------------------------------------------------------------------
        --- Task Runner
        { src = 'https://github.com/stevearc/overseer.nvim' },

        ---------------------------------------------------------------------------
        --- Status line
        { src = 'https://github.com/rebelot/heirline.nvim' },

        -- NOTE iamcco/markdown-preview.nvim has a build step and the
        -- plugin hasn't been updated in a long time so Im not going to
        -- include it at the moment
        -- {
        --     src = 'https://github.com/iamcco/markdown-preview.nvim',
        --     data = {
        --         load = false,
        --         runtimepath = false,
        --     },
        -- },

        {
            src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim',
            data = {
                load = config.load_markdown_preview_plugins,
                runtimepath = config.load_markdown_preview_plugins,
            },
        },

        -------------------------------------------------------------------------------
        ---treesitter parsers
        {
            src = 'https://github.com/dlvandenberg/tree-sitter-angular',
            version = 'f0d0685701b70883fa2dfe94ee7dc27965cab841',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    angular = {
                        requires = { 'html', 'html_tags' },
                        versioning_type = 'HEAD',
                        filetypes = { 'htmlangular' },
                    },
                },
            },
        },
        {
            src = 'https://github.com/aheber/tree-sitter-sfapex',
            version = '3597575a429766dd7ecce9f5bb97f6fec4419d5d',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    apex = { location = 'apex', versioning_type = 'HEAD' },
                    sflog = {
                        location = 'sflog',
                        readme_note = 'Salesforce debug log',
                        versioning_type = 'HEAD',
                    },
                    soql = { location = 'soql', versioning_type = 'HEAD' },
                    sosl = { location = 'sosl', versioning_type = 'HEAD' },
                },
            },
        },
        {
            src = 'https://github.com/Beaglefoot/tree-sitter-awk',
            version = '34bbdc7cce8e803096f47b625979e34c1be38127',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { awk = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-bash',
            version = 'a06c2e4415e9bc0346c6b86d401879ffb44058f7',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { bash = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-c',
            version = 'ae19b676b13bdcc13b7665397e6d9b14975473dd',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { c = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-c-sharp',
            version = '88366631d598ce6595ec655ce1591b315cffb14c',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { c_sharp = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/uyha/tree-sitter-cmake',
            version = 'c7b2a71e7f8ecb167fad4c97227c838439280175',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { cmake = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/stsewd/tree-sitter-comment',
            version = '66272d2b6c73fb61157541b69dd0a7ce7b42a5ad',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { comment = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-cpp',
            version = '8b5b49eb196bec7040441bee33b2c9a4838d6967',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    cpp = { requires = { 'c' }, versioning_type = 'HEAD' },
                },
            },
        },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-css',
            version = 'dda5cfc5722c429eaba1c910ca32c2c0c5bb1a3f',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { css = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-csv',
            version = 'f6bf6e35eb0b95fbadea4bb39cb9709507fcb181',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    csv = {
                        location = 'csv',
                        requires = { 'tsv' },
                        versioning_type = 'HEAD',
                    },
                    tsv = { location = 'tsv', versioning_type = 'HEAD' },
                    psv = {
                        location = 'psv',
                        requires = { 'tsv' },
                        versioning_type = 'HEAD',
                    },
                },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-diff',
            version = '2520c3f934b3179bb540d23e0ef45f75304b5fed',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { diff = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/camdencheek/tree-sitter-dockerfile',
            version = '971acdd908568b4531b0ba28a445bf0bb720aba5',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { dockerfile = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/ValdezFOmar/tree-sitter-editorconfig',
            version = 'v2.0.0',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { editorconfig = { versioning_type = 'SEMVER' } },
            },
        },
        {
            src = 'https://github.com/the-mikedavis/tree-sitter-git-config',
            version = '0fbc9f99d5a28865f9de8427fb0672d66f9d83a5',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { git_config = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/the-mikedavis/tree-sitter-git-rebase',
            version = '760ba8e34e7a68294ffb9c495e1388e030366188',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { git_rebase = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-gitattributes',
            version = '1b7af09d45b579f9f288453b95ad555f1f431645',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { gitattributes = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/gbprod/tree-sitter-gitcommit',
            version = '33fe8548abcc6e374feaac5724b5a2364bf23090',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { gitcommit = { versioning_type = 'HEAD' } },
            },
        },
        -- {
        --     src = 'https://github.com/shunsambongi/tree-sitter-gitignore',
        --     version = 'f4685bf11ac466dd278449bcfe5fd014e94aa504',
        --     data = {
        --         load = false,
        --         runtimepath = false,
        --         treesitter = { gitignore = { versioning_type = 'HEAD' } },
        --     },
        -- },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-go',
            version = '2346a3ab1bb3857b48b29d779a1ef9799a248cd7',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { go = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/bkegley/tree-sitter-graphql',
            version = '5e66e961eee421786bdda8495ed1db045e06b5fe',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { graphql = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/rest-nvim/tree-sitter-http',
            version = 'db8b4398de90b6d0b6c780aba96aaa2cd8e9202c',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { http = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/pfeiferj/tree-sitter-hurl',
            version = '597efbd7ce9a814bb058f48eabd055b1d1e12145',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { hurl = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/justinmk/tree-sitter-ini',
            version = 'e4018b5176132b4f3c5d6e61cea383f42288d0f5',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { ini = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-java',
            version = 'e10607b45ff745f5f876bfa3e94fbcc6b44bdc11',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { java = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/rmuir/tree-sitter-javadoc',
            version = 'e2f56b4d0df08f6ed5df8bae266f9e75b340a9ab',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { javadoc = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-javascript',
            version = '58404d8cf191d69f2674a8fd507bd5776f46cb11',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    javascript = {
                        requires = { 'ecma', 'jsx' },
                        versioning_type = 'HEAD',
                    },
                },
            },
        },
        {
            src = 'https://github.com/cathaysia/tree-sitter-jinja',
            version = '413dba9fea354b62f6adada1815b2f504e32ffb5',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    jinja = {
                        location = 'tree-sitter-jinja',
                        readme_note = 'basic highlighting',
                        requires = { 'jinja_inline' },
                        versioning_type = 'HEAD',
                    },
                    jinja_inline = {
                        location = 'tree-sitter-jinja_inline',
                        readme_note = 'needed for full highlighting',
                        versioning_type = 'HEAD',
                    },
                },
            },
        },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-jsdoc',
            version = '658d18dcdddb75c760363faa4963427a7c6b52db',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { jsdoc = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-json',
            version = '001c28d7a29832b06b0e831ec77845553c89b56d',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    json = {
                        versioning_type = 'HEAD',
                        filetypes = { 'jsonc' },
                    },
                },
            },
        },
        {
            src = 'https://github.com/Joakker/tree-sitter-json5',
            version = 'aa630ef48903ab99e406a8acd2e2933077cc34e1',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { json5 = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-lua',
            version = '10fe0054734eec83049514ea2e718b2a56acd0c9',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { lua = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-luap',
            version = 'c134aaec6acf4fa95fe4aa0dc9aba3eacdbbe55a',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    luap = {
                        versioning_type = 'HEAD',
                        readme_note = 'Lua patterns',
                    },
                },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-luau',
            version = 'a8914d6c1fc5131f8e1c13f769fa704c9f5eb02f',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    luau = {
                        versioning_type = 'HEAD',
                        requires = { 'lua' },
                    },
                },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-luadoc',
            version = '873612aadd3f684dd4e631bdf42ea8990c57634e',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { luadoc = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-make',
            version = '70613f3d812cbabbd7f38d104d60a409c4008b43',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { make = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-markdown',
            version = 'f969cd3ae3f9fbd4e43205431d0ae286014c05b5',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    markdown = {
                        location = 'tree-sitter-markdown',
                        readme_note = 'basic highlighting',
                        requires = { 'markdown_inline' },
                        versioning_type = 'HEAD',
                    },
                    markdown_inline = {
                        location = 'tree-sitter-markdown-inline',
                        readme_note = 'needed for full highlighting',
                        versioning_type = 'HEAD',
                    },
                },
            },
        },
        {
            src = 'https://github.com/monaqa/tree-sitter-mermaid',
            version = '90ae195b31933ceb9d079abfa8a3ad0a36fee4cc',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { mermaid = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/airbus-cert/tree-sitter-powershell',
            version = '73800ecc8bddeee8f1079a5a2e0c13c3d00269bb',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    powershell = { versioning_type = 'HEAD', filetype = 'ps1' },
                },
            },
        },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-python',
            version = 'v0.25.0',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    python = {
                        versioning_type = 'SEMVER',
                        filetypes = { 'py', 'gyp' },
                    },
                },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-query',
            version = 'fc5409c6820dd5e02b0b0a309d3da2bfcde2db17',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    query = {
                        readme_note = 'Tree-sitter query language',
                        versioning_type = 'HEAD',
                    },
                },
            },
        },
        {
            src = 'https://github.com/tris203/tree-sitter-razor',
            version = 'fe46ce5ea7d844e53d59bc96f2175d33691c61c5',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { razor = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-regex',
            version = 'b2ac15e27fce703d2f37a79ccd94a5c0cbe9720b',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { regex = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-requirements',
            version = 'caeb2ba854dea55931f76034978de1fd79362939',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    requirements = {
                        versioning_type = 'HEAD',
                    },
                },
            },
        },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-rust',
            version = '77a3747266f4d621d0757825e6b11edcbf991ca5',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { rust = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/derekstride/tree-sitter-sql',
            version = '851e9cb257ba7c66cc8c14214a31c44d2f1e954e',
            -- branch = 'gh-pages',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { sql = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-ssh-config',
            version = '71d2693deadaca8cdc09e38ba41d2f6042da1616',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    ssh_config = {
                        versioning_type = 'HEAD',
                        filetypes = { 'sshconfig' },
                    },
                },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-ssh-config',
            version = '71d2693deadaca8cdc09e38ba41d2f6042da1616',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { ssh_config = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/sigmaSd/tree-sitter-strace',
            version = 'ac874ddfcc08d689fee1f4533789e06d88388f29',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { strace = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-hcl',
            version = '64ad62785d442eb4d45df3a1764962dafd5bc98b',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    terraform = {
                        location = 'dialects/terraform',
                        requires = { 'hcl' },
                        versioning_type = 'HEAD',
                        filetypes = { 'terraform-vars' },
                    },
                    hcl = { location = nil, versioning_type = 'HEAD' },
                },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-toml',
            version = '64b56832c2cffe41758f28e05c756a3a98d16f41',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { toml = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter/tree-sitter-typescript',
            version = '75b3874edb2dc714fb1fd77a32013d0f8699989f',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    tsx = {
                        location = 'tsx',
                        requires = { 'ecma', 'jsx', 'typescript' },
                        versioning_type = 'HEAD',
                        filetypes = { 'typescriptreact', 'typescript.tsx' },
                    },
                    typescript = {
                        location = 'typescript',
                        requires = { 'ecma' },
                        versioning_type = 'HEAD',
                        filetypes = { 'ts' },
                    },
                },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-vim',
            version = '3092fcd99eb87bbd0fc434aa03650ba58bd5b43b',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { vim = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/neovim/tree-sitter-vimdoc',
            version = 'f061895a0eff1d5b90e4fb60d21d87be3267031a',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { vimdoc = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-vue',
            version = 'ce8011a414fdf8091f4e4071752efc376f4afb08',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    vue = {
                        requires = { 'html_tags' },
                        versioning_type = 'HEAD',
                    },
                },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-xml',
            version = '5000ae8f22d11fbe93939b05c1e37cf21117162d',
            data = {
                load = false,
                runtimepath = false,
                treesitter = {
                    xml = {
                        location = 'xml',
                        requires = { 'dtd' },
                        versioning_type = 'HEAD',
                        filetypes = { 'xsd', 'xslt', 'svg' },
                    },
                    dtd = { location = 'dtd', versioning_type = 'HEAD' },
                },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-yaml',
            version = '4463985dfccc640f3d6991e3396a2047610cf5f8',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { yaml = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-yaml',
            version = '4463985dfccc640f3d6991e3396a2047610cf5f8',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { yaml = { versioning_type = 'HEAD' } },
            },
        },
        {
            src = 'https://github.com/tree-sitter-grammars/tree-sitter-zig',
            version = '6479aa13f32f701c383083d8b28360ebd682fb7d',
            data = {
                load = false,
                runtimepath = false,
                treesitter = { zig = { versioning_type = 'HEAD' } },
            },
        },
    }

    now(function() vim.pack.add(specs, { load = load_plugins }) end)

    -- setup tokyonight.nvim
    now(plugin_setups.setup_tokyonight)

    -- setup echasnovski/mini.icons
    now(plugin_setups.setup_mini_icons)

    -- setup stevearc/oil.nvim
    now(plugin_setups.setup_oil)

    -- setup folke/which-key.nvim
    now(plugin_setups.which_key)

    -- setup max397574/better-escape.nvim
    now(plugin_setups.better_escape)

    -- setup nvim-treesitter/nvim-treesitter
    -- now(plugin_setups.setup_nvim_treesitter)

    -- setup treesitter without nvim-treesitter
    now(require('myconfig.treesitter').setup_treesitter)

    -- setup neovim/nvim-lspconfig
    now(plugin_setups.setup_nvim_lspconfig)

    -- setup williamboman/mason.nvim
    now(plugin_setups.setup_mason_nvim)
end)

later(function()
    -- setup mistweaverco/kulala.nvim
    later(plugin_setups.setup_kulala)

    -- setup sindrets/diffview.nvim
    later(plugin_setups.setup_diffview)

    -- setup lewis6991/gitsigns.nvim
    later(plugin_setups.setup_gitsigns)

    -- setup linrongbin16/gitlinker.nvim
    later(plugin_setups.setup_gitlinker)

    -- setup akinsho/git-conflict.nvim
    later(plugin_setups.setup_git_conflict)

    -- setup nvim-telescope/telescope.nvim
    later(plugin_setups.setup_telescope)

    -- setup ThePrimeagen/harpoon
    later(plugin_setups.setup_harpoon)

    -- setup mbbill/undotree
    later(plugin_setups.setup_undotree)

    -- setup numToStr/Comment.nvim
    later(plugin_setups.setup_comment_nvim)

    -- setup jake-stewart/multicursor.nvim
    later(plugin_setups.setup_multicursor_nivm)

    -- setup nvim-treesitter/nvim-treesitter-context
    later(plugin_setups.setup_nvim_treesitter_context)

    -- setup Wansmer/treesj
    later(plugin_setups.setup_treesj)

    -- setup gbprod/substitute.nvim
    later(plugin_setups.setup_substitute_nvim)

    --setup nvim-neotest/neotest
    later(plugin_setups.setup_neotest)

    -- setup mfussenegger/nvim-dap
    later(plugin_setups.setup_nvim_dap)

    -- setup rcarriga/nvim-dap-ui
    later(plugin_setups.setup_nvim_dap_ui)

    -- setup mfussenegger/nvim-dap-python
    later(plugin_setups.setup_nvim_dap_python)

    -- setup quarto-dev/quarto-nvim
    later(plugin_setups.setup_quarto)

    -- setup benlubas/molten-nvim
    later(plugin_setups.setup_molten_nvim)

    -- setup L3MON4D3/LuaSnip
    later(plugin_setups.setup_luasnip)

    -- setup linux-cultist/venv-selector.nvim
    later(plugin_setups.setup_venv_selector)

    -- setup Decodetalkers/csharpls-extended-lsp.nvim
    later(plugin_setups.setup_csharpls_extended_lsp_nvim)

    -- setup rachartier/tiny-code-action.nvim
    later(plugin_setups.setup_tiny_code_action_nvim)

    -- setup crwebb85/mark-code-action.nvim
    later(plugin_setups.setup_mark_code_action)

    -- setup stevearc/conform.nvim
    later(plugin_setups.setup_conform_nvim)

    -- setup stevearc/overseer.nvim
    later(plugin_setups.setup_overseer_nvim)

    -- setup rebelot/heirline.nvim
    later(require('myconfig.heirline').setup_heirline)

    -- setup MeanderingProgrammer/render-markdown.nvim
    later(plugin_setups.setup_render_markdown)

    later(plugin_setups.setup_profile_nvim)
end)

-- TODO
-- {
--     'folke/lazydev.nvim',
--     ft = 'lua', -- only load on lua files
--     lazy = true,
--     opts = {
--         library = {
--             { path = 'wezterm-types', mods = { 'wezterm' } },
--         },
--     },
-- },
-- { 'justinsgithub/wezterm-types', lazy = true }, -- optional wezterm lua types
