vim.g.mapleader = ' '
local config = require('myconfig.config')
local get_icon = require('myconfig.icons').get_icon

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- local function init_python_environment()
--     local config_env = os.getenv('XDG_CONFIG_HOME')
--     if config_env == nil then
--         error('cannot find XDG_CONFIG_HOME environment variable')
--     end
--     local config_path = vim.fn.expand(config_env)
--     vim.g.python3_host_prog = vim.fn.expand(
--         vim.fs.joinpath(
--             config_path,
--             'cli-tools',
--             'jupyter_notebook_venv',
--             'venv',
--             'Scripts',
--             'python.exe'
--         )
--     )
--     vim.print(vim.g.python3_host_prog)
-- end
-- init_python_environment()

require('lazy').setup({

    {
        'stevearc/profile.nvim',
        lazy = true,
        keys = {
            {
                '<f6>',
                function()
                    local prof = require('profile')
                    if prof.is_recording() then
                        prof.stop()
                        vim.ui.input({
                            prompt = 'Save profile to:',
                            completion = 'file',
                            default = 'profile.json',
                        }, function(filename)
                            if filename then
                                prof.export(filename)
                                vim.notify(string.format('Wrote %s', filename))
                            end
                        end)
                    else
                        prof.start('*')
                    end
                end,
                desc = 'Profile.nvim: Start/Stop profiling',
                -- To create a flame graph from the profile.json file
                -- first convert it to the proper format for FlameGraph
                -- with the command `python ./cli-tools/stackcollapse-chrome-tracing/stackcollapse-chrome-tracing.py profile.json > profile.log`
                -- where stackcollapse-chrome-tracing.py is a python file in my config repo
                --
                -- Then use flamegraph <path to build folder>/inferno-flamegraph.exe profile.log > flame.svg
                -- Note: I had to build flamegraph from source from the repo https://github.com/jonhoo/inferno
            },
        },
    },

    --Used to unnest neovim instances (like if a git command opened a child neovim instance)
    {
        'brianhuster/unnest.nvim',
    },
    -- {
    --     'cossonleo/dirdiff.nvim',
    -- },
    ---------------------------------------------------------------------------
    -- Colorscheme
    {
        'folke/tokyonight.nvim',
        lazy = false,
        priority = 1000,
        config = function()
            require('tokyonight.colors').setup()
            local color = 'tokyonight'
            vim.cmd.colorscheme(color)
        end,
    },

    ---------------------------------------------------------------------------
    -- Git integration

    -- Adds Git commands
    {
        'tpope/vim-fugitive',
        version = '*',
        lazy = true,
        cmd = { 'Git' },
    },

    -- Adds git diffview
    {
        'sindrets/diffview.nvim',
        lazy = true,
        config = function()
            local actions = require('diffview.actions')
            local diffview_keymaps = {
                {
                    'n',
                    '<leader>ggT',
                    actions.goto_file_tab,
                    {
                        desc = 'Diffview: Open the file in a new tabpage',
                    },
                },
                {
                    'n',
                    '<leader>ggs',
                    actions.toggle_stage_entry,
                    { desc = 'Diffview: Stage / unstage the selected entry' },
                },
                {
                    'n',
                    'q',
                    '<cmd>DiffviewClose<CR>',
                    {
                        silent = true,
                        desc = 'Diffview: close',
                    },
                },
                {
                    'n',
                    'cc',
                    ':tab Git commit <CR>',
                    {
                        desc = 'Diffview: Open commit message with Vim Fugitive',
                    },
                },
            }

            require('diffview').setup({
                keymaps = {
                    view = diffview_keymaps,
                    --TODO deal with my keymap conflict of <leader>e between diffview and harpoon
                    file_panel = diffview_keymaps,
                    file_history_panel = diffview_keymaps,
                },
            })
        end,
        keys = {
            {
                '<leader>gd',
                function()
                    local diffview = nil
                    for _, view in ipairs(require('diffview.lib').views) do
                        if view.class.__name == 'DiffView' then
                            diffview = view
                            break
                        end
                    end

                    if diffview == nil then
                        require('diffview').open({})
                    elseif
                        diffview.tabpage ~= vim.api.nvim_get_current_tabpage()
                    then
                        vim.api.nvim_set_current_tabpage(diffview.tabpage)
                    else
                        require('diffview').close()
                    end
                end,
                desc = 'Diffview: Toggle',
            },
            {
                '<leader>ghh',
                '<cmd>DiffviewFileHistory<cr>',
                desc = 'Diffview: Open Git Repo history',
            },

            {
                '<leader>ghf',
                '<cmd>DiffviewFileHistory --follow %<cr>',
                desc = 'Diffview: Open Git File history',
            },

            {
                '<leader>ghl',
                "<Esc><Cmd>'<,'>DiffviewFileHistory --follow<CR>",
                mode = 'v',
                desc = 'Diffview: Open Git File history over selected text',
            },

            {
                '<leader>ghl',
                '<Cmd>.DiffviewFileHistory --follow<CR>',
                desc = 'Diffview: Open Git history for the line',
            },

            -- Diff against local master branch
            {
                '<leader>ghm',
                function()
                    vim.cmd(
                        'DiffviewOpen '
                            .. require('myconfig.utils.misc').get_default_branch_name()
                    )
                end,
                desc = 'Diffview: Diff against master',
            },

            -- Diff against remote master branch
            {
                '<leader>ghM',
                function()
                    vim.cmd(
                        'DiffviewOpen HEAD..origin/'
                            .. require('myconfig.utils.misc').get_default_branch_name()
                    )
                end,
                desc = 'Diffview: Diff against origin/master',
            },
        },
    },

    -- Adds an API wrapper around git which I use in my heirline setup
    -- Adds Git blame
    -- Adds sidebar showing lines changed
    -- Add hunk navigation
    {
        'lewis6991/gitsigns.nvim',
        lazy = true,
        event = 'BufReadPre',
        opts = {
            -- Disable trouble plugin for :Gitsigns setqflist and :Gitsigns setloclist
            trouble = false,
        },
        config = true,
        keys = {

            -- Highlight changed words.
            {
                '<leader>gbw',
                function() require('gitsigns').toggle_word_diff() end,
                desc = 'Gitsigns: Toggle word diff',
            },

            -- Highlight added lines.
            {
                '<leader>gbl',
                function() require('gitsigns').toggle_linehl() end,
                desc = 'Gitsigns: Toggle line highlight',
            },
            {
                '<leader>gbh',
                function() require('gitsigns').preview_hunk() end,
                desc = 'Gitsigns: Preview hunk',
            },
        },
    },

    --- Easily get and goto git permalinks
    {
        'linrongbin16/gitlinker.nvim',
        cmd = 'GitLink',
        lazy = true,
        opts = {},
        keys = {

            {
                '<leader>gll',
                '<cmd>GitLink<cr>',
                mode = { 'n', 'v' },
                silent = true,
                desc = 'Git: Yank git permlink',
            },
            {
                '<leader>glL',
                '<cmd>GitLink!<cr>',
                mode = { 'n', 'v' },
                silent = true,
                desc = 'Git: Open git permlink',
            },
            {
                '<leader>glb',
                '<cmd>GitLink blame<cr>',
                mode = { 'n', 'v' },
                silent = true,
                desc = 'Git: Yank git blame link',
            },
            {
                '<leader>glB',
                '<cmd>GitLink! blame<cr>',
                mode = { 'n', 'v' },
                silent = true,
                desc = 'Git: Open git blame link',
            },
            {
                '<leader>gld',
                '<cmd>GitLink default_branch<cr>',
                mode = { 'n', 'v' },
                silent = true,
                desc = 'Git: Copy default branch link',
            },
            {
                '<leader>glD',
                '<cmd>GitLink! default_branch<cr>',
                mode = { 'n', 'v' },
                silent = true,
                desc = 'Git: Open default branch link',
            },
            {
                '<leader>glc',
                '<cmd>GitLink current_branch<cr>',
                mode = { 'n', 'v' },
                silent = true,
                desc = 'Git: Copy current branch link',
            },
            {
                '<leader>glD',
                '<cmd>GitLink! current_branch<cr>',
                mode = { 'n', 'v' },
                silent = true,
                desc = 'Git: Open current branch link',
            },
        },
    },

    -- Adds commands for handling git conflicts
    {
        'akinsho/git-conflict.nvim',
        lazy = true,
        event = 'VeryLazy',
        config = function(_, opts)
            local git_conflict = require('git-conflict')
            git_conflict.setup(opts)
            vim.api.nvim_create_autocmd('User', {
                pattern = 'GitConflictDetected',
                callback = function()
                    vim.notify(
                        'Git conflict detected in ' .. vim.fn.expand('<afile>')
                    )
                end,
            })
        end,
    },

    ---------------------------------------------------------------------------
    -- File Navigation

    -- Fuzzy finder (for many things not just file finder)
    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim', -- telescope uses plenary to create the UI
            'nvim-tree/nvim-web-devicons',
        },
        lazy = true,
        cmd = { 'Telescope' },
        keys = {

            {
                '<leader>ff',
                function() require('telescope.builtin').find_files() end,
                desc = 'Telescope: find files (supports line number and col `path:line:col`) ',
                mode = { 'n' },
            },
            {
                '<leader>ff',
                function()
                    local opts = {}
                    --
                    local start_pos = vim.fn.getpos('v')
                    -- vim.print(start_pos)
                    local end_pos = vim.fn.getpos('.')
                    -- vim.print(end_pos)
                    local text_lines = vim.fn.getregion(start_pos, end_pos)
                    for index, text_line in ipairs(text_lines) do
                        text_lines[index] = vim.fn.trim(text_line)
                    end

                    local text = vim.fn.join(text_lines, '')

                    local root_dir = vim.fn.getcwd()
                    if root_dir ~= nil then
                        --escape special regex characters
                        local root_dir_regex = root_dir
                        root_dir_regex =
                            string.gsub(root_dir_regex, '%(', '%%%(')
                        root_dir_regex =
                            string.gsub(root_dir_regex, '%)', '%%%)')
                        root_dir_regex =
                            string.gsub(root_dir_regex, '%.', '%%%.')
                        root_dir_regex =
                            string.gsub(root_dir_regex, '%%', '%%%%')
                        root_dir_regex =
                            string.gsub(root_dir_regex, '%+', '%%%+')
                        root_dir_regex =
                            string.gsub(root_dir_regex, '%-', '%%%-')
                        root_dir_regex =
                            string.gsub(root_dir_regex, '%*', '%%%*')
                        root_dir_regex =
                            string.gsub(root_dir_regex, '%?', '%%%?')
                        root_dir_regex =
                            string.gsub(root_dir_regex, '%[', '%%%[')
                        root_dir_regex =
                            string.gsub(root_dir_regex, '%^', '%%%^')
                        root_dir_regex =
                            string.gsub(root_dir_regex, '%$', '%%%$')

                        --replace path seperators with a char-set
                        root_dir_regex =
                            string.gsub(root_dir_regex, '[\\/]+', '[\\/]+')

                        text = string.gsub(text, root_dir_regex, '')
                    end

                    -- remove leading slashes and backslashes
                    text = vim.fn.substitute(text, '^[\\/]*', '', '')

                    opts.default_text = text
                    require('telescope.builtin').find_files(opts)
                end,
                desc = 'Telescope: find files (supports line number and col `path:line:col`) ',
                mode = { 'v' },
            },
            {
                '<leader>fs',
                function()
                    require('telescope').load_extension('luasnip').luasnip()
                end,
                desc = 'Telescope Luasnip: Select a snippet',
                mode = { 'n' },
            },
            {
                '<leader>fl',
                function()
                    local mode = vim.api.nvim_get_mode().mode
                    if mode == 'v' then
                        -- First greps for the visual selection then lets you grep those results with a new grep
                        --
                        -- Note: while I used to have telescope grep_string as a different keymap so that I could
                        -- also use it in normal mode to search the <cword> (word under cursor) I just never remembered
                        -- to use it that way so I decided to free up that keymap namespace for other uses
                        require('telescope.builtin').grep_string()
                    else
                        require('telescope.builtin').live_grep()
                    end
                end,
                desc = 'Telescope: live_grep',
                mode = { 'n', 'v' },
            },
            {
                '<leader>fgd',
                function()
                    require('telescope.builtin').lsp_definitions({
                        jump_type = 'never',
                    })
                end,
                desc = 'Telescope: LSP definition',
                mode = { 'n' },
            },
            -- {
            --     '<leader>fgD',
            --     function()
            --         require('telescope.builtin').lsp_declarations({ --This builtin doesn't exist
            --             jump_type = 'never',
            --         })
            --     end,
            --     desc = 'Telescope: LSP declaration',
            --     mode = { 'n' },
            -- },
            {
                '<leader>fgi',
                function()
                    require('telescope.builtin').lsp_implementations({
                        jump_type = 'never',
                    })
                end,
                desc = 'Telescope: LSP implementation',
                mode = { 'n' },
            },
            {
                '<leader>fgo',
                function()
                    require('telescope.builtin').lsp_type_definitions({
                        jump_type = 'never',
                    })
                end,
                desc = 'Telescope: LSP type definition',
                mode = { 'n' },
            },
            {
                '<leader>fgrr',
                function()
                    require('telescope.builtin').lsp_references({
                        jump_type = 'never',
                    })
                end,
                desc = 'Telescope: LSP references',
                mode = { 'n' },
            },
            {
                '<leader>fb',
                function() require('telescope.builtin').buffers() end,
                desc = 'Telescope: open buffers',
            },
            {
                '<leader>fh',
                function() require('telescope.builtin').help_tags() end,
                desc = 'Telescope: help tags',
                mode = { 'n' },
            },
            {
                '<leader>fh',
                function()
                    local start_pos = vim.fn.getpos('v')
                    local end_pos = vim.fn.getpos('.')
                    local text_lines = vim.fn.getregion(start_pos, end_pos)

                    local text = table.concat(text_lines, '\n')
                    text = string.gsub(text, '\n', '')
                    text = vim.trim(text)

                    require('telescope.builtin').help_tags({
                        default_text = text,
                    })
                end,
                desc = 'Telescope: help tags',
                mode = { 'v' },
            },
            {
                '<leader>fk',
                function() require('telescope.builtin').keymaps() end,
                desc = 'Telescope: keymaps',
            },
            {
                '<leader>fd',
                function() require('telescope.builtin').spell_suggest() end,
                desc = 'Telescope: suggest spelling (search dictionary)',
            },
            {
                '<leader>fm',
                function() require('telescope.builtin').marks() end,
                desc = 'Telescope: marks',
            },
            {
                '<leader>fo',
                function() require('telescope.builtin').oldfiles() end,
                desc = 'Telescope: old files',
            },
            {
                '<leader>fc',
                function() require('telescope.builtin').git_status() end,
                desc = 'Telescope: git status',
            },
            {
                '<leader>fr',
                function() require('telescope.builtin').resume() end,
                desc = 'Telescope: resume',
            },
            {
                '<leader>fe',
                function()
                    --My custom picker defined in .config\nvim\lua\telescope\_extensions
                    require('telescope').load_extension('harpoon').harpoon()
                end,
                desc = 'Telescope: harpoon',
            },
            {
                '<leader>fnf',
                function()
                    --My custom picker defined in .config\nvim\lua\telescope\_extensions
                    require('telescope').load_extension('notes').find_files()
                end,
                desc = 'Telescope: find files in note directory ',
                mode = { 'n' },
            },
            {
                '<leader>fng',
                function()
                    --My custom picker defined in .config\nvim\lua\telescope\_extensions
                    require('telescope').load_extension('notes').live_grep()
                end,
                desc = 'Telescope: grep files in note directory ',
                mode = { 'n' },
            },
            {
                '<leader>fzz',
                function()
                    --My custom picker defined in .config\nvim\lua\telescope\_extensions
                    require('telescope').load_extension('skeleton').find_files()
                end,
                desc = 'Telescope: find skeletons (file templates) ',
                mode = { 'n' },
            },
            {
                '<leader>fzp',
                function()
                    --My custom picker defined in .config\nvim\lua\telescope\_extensions
                    require('telescope').load_extension('projects').projects()
                end,
                desc = 'Telescope: find project directory',
                mode = { 'n' },
            },
            {
                '<leader>fzc',
                function()
                    --My custom picker defined in .config\nvim\lua\telescope\_extensions
                    require('telescope').load_extension('poc').poc()
                end,
                desc = 'Telescope: find poc directory',
                mode = { 'n' },
            },
        },
        opts = {
            defaults = {
                -- path_display = { 'filename_first' },
                dynamic_preview_title = true,
                mappings = {
                    i = {

                        ['<CR>'] = function(...)
                            require('telescope.actions').select_default(...)

                            local escape_key = vim.api.nvim_replace_termcodes(
                                '<ESC>',
                                true,
                                false,
                                true
                            )
                            vim.api.nvim_feedkeys(escape_key, 'm', false) -- Set mode to normal mode
                        end,
                        ['<A-v>'] = function(...)
                            require('telescope.actions').select_vertical(...)
                        end,
                        ['<A-x>'] = function(...)
                            require('telescope.actions').select_horizontal(...)
                        end,
                        ['<C-b>'] = function(prompt_bufnr)
                            --Using my bufdelete (modified version of famiu/bufdelete.nvim)
                            --instead of require('telescope.actions').delete_buffer since this
                            --version will preserve window layout and give me a prompt to save buffers
                            local current_picker = require(
                                'telescope.actions.state'
                            ).get_current_picker(
                                prompt_bufnr
                            )
                            current_picker:delete_selection(function(selection)
                                local ok, result = pcall(
                                    require('myconfig.bufdelete').bufdelete,
                                    selection.bufnr
                                )
                                return ok and result[selection.bufnr] == true
                            end)
                        end,
                    },
                },
            },
            pickers = {
                find_files = {
                    find_command = {
                        'rg',
                        '--files',
                        '--hidden',
                        '--glob',
                        '!.git',
                        '--glob',
                        '!node_modules',
                        '--glob',
                        '!venv',
                        '--glob',
                        '!.venv',
                    },
                },
            },
        },
        config = function(_, opts)
            require('telescope').setup(opts)
            require('telescope').load_extension('media_files')
            require('telescope').load_extension('skeleton')
            require('telescope').load_extension('notes')
            require('telescope').load_extension('harpoon')
            require('telescope').load_extension('neovim_runtime')
            require('telescope').load_extension('neovim_data')
            require('telescope').load_extension('neovim_plugin')
            require('telescope').load_extension('neovim_config')
            require('telescope').load_extension('projects')
            require('telescope').load_extension('poc')

            -- I believe the hotfix below is no longer needed becauseht the plenary PR was merged
            -- -- TODO tempory hack based on https://github.com/nvim-telescope/telescope.nvim/issues/3436#issuecomment-2756267300
            -- -- until plenary PR https://github.com/nvim-lua/plenary.nvim/pull/649 is merged
            -- vim.api.nvim_create_autocmd('User', {
            --     pattern = 'TelescopeFindPre',
            --     callback = function()
            --         vim.o.winborder = 'none'
            --         vim.api.nvim_create_autocmd('WinLeave', {
            --             once = true,
            --             callback = function() vim.o.winborder = 'rounded' end,
            --         })
            --     end,
            -- })
        end,
    },

    -- Harpoon (fast file navigation between pinned files)
    {
        'ThePrimeagen/harpoon',
        branch = 'harpoon2',
        dependencies = { 'nvim-lua/plenary.nvim' },
        lazy = true,
        keys = {

            {
                '<leader>ea',
                function() require('harpoon'):list():add() end,
                desc = 'Harpoon: Add file',
            },
            {
                '<leader>et',
                function()
                    local harpoon = require('harpoon')
                    harpoon.ui:toggle_quick_menu(harpoon:list())
                end,
                desc = 'Harpoon: Toggle quick menu',
            },
            {
                '<leader>eo',
                function() require('harpoon'):list():select(vim.v.count1) end,
                desc = 'Harpoon: Go to file using count1',
            },
            -- Protip: To reorder the entries in harpoon quick menu use `Vd` to cut the line and `P` to paste where you want it

            -- Harpoon quick navigation
            {
                '<leader>1',
                function() require('harpoon'):list():select(1) end,
                desc = 'Harpoon: Go to file 1',
            },
            {
                '<leader>2',
                function() require('harpoon'):list():select(2) end,
                desc = 'Harpoon: Go to file 2',
            },
            {
                '<leader>3',
                function() require('harpoon'):list():select(3) end,
                desc = 'Harpoon: Go to file 3',
            },
            {
                '<leader>4',
                function() require('harpoon'):list():select(4) end,
                desc = 'Harpoon: Go to file 4',
            },
            {
                '<leader>5',
                function() require('harpoon'):list():select(5) end,
                desc = 'Harpoon: Go to file 5',
            },
            {
                '<leader>6',
                function() require('harpoon'):list():select(6) end,
                desc = 'Harpoon: Go to file 6',
            },
            {
                '<leader>7',
                function() require('harpoon'):list():select(7) end,
                desc = 'Harpoon: Go to file 7',
            },
            {
                '<leader>8',
                function() require('harpoon'):list():select(8) end,
                desc = 'Harpoon: Go to file 8',
            },
            {
                '<leader>9',
                function() require('harpoon'):list():select(9) end,
                desc = 'Harpoon: Go to file 9',
            },
            {
                '<leader>0',
                function() require('harpoon'):list():select(10) end,
                desc = 'Harpoon: Go to file 10',
            },
        },
        opts = {
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = true,
            },
        },
        config = function(_, opts)
            local harpoon = require('harpoon')

            local function to_exact_name(value) return '^' .. value .. '$' end

            --- the select function is called when a user selects an item from
            --- the corresponding list and can be nil if select_with_nil is true
            ---
            --- Also decodes dynamic file names base on the current date
            --- denoted by ${filname_goes_here}
            --- When a dynamic name is detected the file name is decoded using
            --- the os.date function in the lua standard library
            --- for example "${test%Y-%m-%d.log}" would become "test2024-09-27.log"
            --- if todays date was 2024-09-27 this allows adding current days log file
            --- to the harpoon list without having to change it each day.
            ---
            --- Based on the default select in harpoon2 but modified to allow dynamic dates
            --- in the file name
            ---@param list_item? HarpoonListFileItem
            ---@param list HarpoonList
            ---@param options HarpoonListFileOptions
            local function my_select(list_item, list, options)
                local Logger = require('harpoon.logger')
                local Extensions = require('harpoon.extensions')
                Logger:log(
                    'config_defaut#select',
                    list_item,
                    list.name,
                    options
                )
                if list_item == nil then return end

                options = options or {}

                --Decode dynamic harpoon items based on current date
                --for example "${test%Y-%m-%d.log}" would become "test2024-09-27.log"
                --if todays date was 2024-09-27 this allows adding current days log file
                --to the harpoon list without having to change it each day.
                local list_item_value, _ = string.gsub(
                    list_item.value,
                    '^%${(.*)}$',
                    function(n) return os.date(n) end
                )
                local bufnr = vim.fn.bufnr(to_exact_name(list_item_value))
                local set_position = false
                if bufnr == -1 then -- must create a buffer!
                    set_position = true
                    -- bufnr = vim.fn.bufnr(list_item.value, true)
                    bufnr = vim.fn.bufadd(list_item_value)
                end
                if not vim.api.nvim_buf_is_loaded(bufnr) then
                    vim.fn.bufload(bufnr)
                    vim.api.nvim_set_option_value('buflisted', true, {
                        buf = bufnr,
                    })
                end

                if options.vsplit then
                    vim.cmd('vsplit')
                elseif options.split then
                    vim.cmd('split')
                elseif options.tabedit then
                    vim.cmd('tabedit')
                end

                vim.api.nvim_set_current_buf(bufnr)

                if set_position then
                    local lines = vim.api.nvim_buf_line_count(bufnr)

                    local edited = false
                    if list_item.context.row > lines then
                        list_item.context.row = lines
                        edited = true
                    end

                    local row = list_item.context.row
                    local row_text =
                        vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)
                    local col = #row_text[1]

                    if list_item.context.col > col then
                        list_item.context.col = col
                        edited = true
                    end

                    local new_pos = {
                        list_item.context.row or 1,
                        list_item.context.col or 0,
                    }
                    vim.api.nvim_win_set_cursor(0, new_pos)

                    if edited then
                        Extensions.extensions:emit(
                            Extensions.event_names.POSITION_UPDATED,
                            {
                                list_item = list_item,
                            }
                        )
                    end
                end

                Extensions.extensions:emit(Extensions.event_names.NAVIGATE, {
                    buffer = bufnr,
                })
            end
            opts.default = {
                select = my_select,
            }
            harpoon:setup(opts)
        end,
    },

    {
        -- 'stevearc/oil.nvim',
        'crwebb85/oil.nvim',
        -- dev = true,
        cmd = { 'Oil' },
        keys = {
            {
                '<leader>ol',
                '<CMD>Oil<CR>',
                desc = 'Oil: Open parent directory',
            },
        },
        init = function(_)
            --From https://www.reddit.com/r/neovim/comments/1egmpag/comment/lg2epw8/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

            local group_id = vim.api.nvim_create_augroup(
                'oil_open_on_start',
                { clear = true }
            )
            vim.api.nvim_create_autocmd('BufEnter', {
                group = group_id,
                desc = 'OIL replacement for Netrw',
                pattern = '*',
                once = true,
                callback = function()
                    vim.schedule(function()
                        local buffer_name = vim.api.nvim_buf_get_name(0)
                        if vim.fn.isdirectory(buffer_name) == 0 then return end

                        -- Ensure no buffers remain with the directory name
                        vim.api.nvim_set_option_value(
                            'bufhidden',
                            'wipe',
                            { buf = 0 }
                        )
                        require('oil').open(vim.fn.expand('%:p:h'))
                    end)
                end,
            })
        end,
        dependencies = { 'nvim-mini/mini.icons' },
        opts = {
            default_file_explorer = true,
            delete_to_trash = true,
            -- watch the filesystem for changes and reload oil
            watch_for_changes = true,
            view_options = {
                show_hidden = true,
                is_always_hidden = function(name, _)
                    return name == '...' or name == '..' or name == '.git'
                end,
            },
            keymaps = {
                ['<leader>gf'] = {
                    callback = function()
                        local oil = require('oil')
                        local entry = oil.get_cursor_entry()

                        if entry == nil then return end
                        if entry['type'] == 'file' then
                            local dir = oil.get_current_dir()
                            local fileName = entry['name']
                            local fullName = dir .. fileName
                            require('myconfig.utils.image_preview').preview_image(
                                vim.fs.normalize(fullName)
                            )
                        end
                    end,
                    desc = 'Oil: Open image preview',
                    mode = 'n',
                },
                ['yp'] = {
                    -- from https://www.reddit.com/r/neovim/comments/1czp9zr/comment/l5hv900/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
                    desc = 'Oil: Copy filepath to system clipboard',
                    callback = function()
                        require('oil.actions').copy_entry_path.callback()
                        vim.fn.setreg('+', vim.fn.getreg(vim.v.register))
                    end,
                    mode = 'n',
                },
                ['yP'] = {
                    -- from https://www.reddit.com/r/neovim/comments/1czp9zr/comment/l5ke7fv/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
                    desc = 'Oil: Copy relative filepath to system clipboard',
                    callback = function()
                        local entry = require('oil').get_cursor_entry()
                        local dir = require('oil').get_current_dir()
                        if not entry or not dir then return end

                        local relpath = vim.fn.fnamemodify(dir, ':.')
                        vim.fn.setreg('+', relpath .. entry.name)
                    end,
                    mode = 'n',
                },
                ['<C-q>'] = {
                    desc = 'Oil: Append file to quick fix list',
                    callback = function()
                        local dir = require('oil').get_current_dir()
                        if not dir then return end

                        local items = vim.fn.getqflist()

                        local start_line = vim.api.nvim_win_get_cursor(0)[1]
                        local end_line = start_line
                        if vim.tbl_contains({ 'v', 'V' }, vim.fn.mode()) then
                            local start_pos = vim.fn.getpos('v')
                            local end_pos = vim.fn.getpos('.')
                            start_line = start_pos[2]
                            end_line = end_pos[2]
                            if end_line < start_line then
                                start_line, end_line = end_line, start_line
                            end
                        end

                        for lnum = start_line, end_line do
                            local entry =
                                require('oil').get_entry_on_line(0, lnum)
                            if entry and entry.type == 'file' then
                                local file_path = dir .. entry.name
                                table.insert(items, {
                                    text = file_path,
                                    filename = file_path,
                                    row = 0,
                                    col = 0,
                                    valid = 1,
                                })
                            end
                        end

                        vim.fn.setqflist({}, ' ', {
                            title = 'Oil Appended Files',
                            items = items,
                        })
                    end,
                    mode = { 'n', 'x' },
                },
            },
        },
        config = function(_, opts) require('oil').setup(opts) end,
    },

    ---------------------------------------------------------------------------
    -- Utils

    {
        'echasnovski/mini.icons',
        lazy = true,
        event = 'VeryLazy',
        opts = {
            style = 'glyph',
        },
        config = function(_, opts)
            if not config.nerd_font_enabled then opts.style = 'ascii' end
            require('mini.icons').setup(opts)
        end,
    },

    -- A util library
    {
        'nvim-lua/plenary.nvim',
        lazy = true,
    },

    {
        'max397574/better-escape.nvim',
        opts = {
            -- i for insert
            i = {
                j = {
                    -- These can all also be functions
                    k = '<Esc>',
                },
            },
            c = {
                j = {
                    k = '<C-c>',
                },
            },
            t = {
                j = {
                    k = '<C-\\><C-n>',
                },
            },
            v = {
                j = {
                    k = '<Esc>',
                },
            },
            s = {
                j = {
                    k = '<Esc>',
                },
            },
        },
        config = function(opts) require('better_escape').setup(opts) end,
    },
    -- Keymap suggestions
    {
        'folke/which-key.nvim',
        lazy = true,
        event = 'VeryLazy',
        -- Note: decided to set timeout in the set.lua file
        -- init = function()
        --     vim.o.timeout = true
        --     vim.o.timeoutlen = 300
        -- end,
        opts = {},
        config = function(_, opts)
            ---@type wk.Opts
            local default_opts = {

                -- https://github.com/folke/which-key.nvim/issues/648#issuecomment-2226881346
                -- delay >= vim.o.timeoutlen for conflicting keymaps to work
                -- By work I mean
                -- keymap <leader>f should activate if <leader>f is quickly pressed
                -- but keymap <leader>ff should activate if the keys are pressed a bit slower
                -- I may need to adjust these numbers so the delays feel right but that is how to make it work
                -- with that said descriptions aren't necessary correct and it still
                -- doesn't behave exactly like it used to

                -- delay = vim.o.timeoutlen,
                delay = 1000,
            }
            ---@type wk.Opts
            opts = vim.tbl_deep_extend('keep', opts, default_opts)
            require('which-key').setup(opts)

            local wk = require('which-key')
            -- Note don't forget to update this if I change the mapping namespaces
            wk.add({
                {
                    '[gc',
                    mode = { 'x', 'n' },
                    group = 'Prev comment mappings',
                },
                {
                    ']gc',
                    mode = { 'x', 'n' },
                    group = 'Next comment mappings',
                },
                {
                    '[h',
                    mode = { 'x', 'n' },
                    group = 'Prev git hunk mappings',
                },
                {
                    ']h',
                    mode = { 'x', 'n' },
                    group = 'Next git hunk mappings',
                },
                {
                    '[d',
                    mode = { 'x', 'n' },
                    group = 'Prev diagnostics mappings',
                },
                {
                    '[D',
                    mode = { 'x', 'n' },
                    group = 'Prev diagnostics extreme mappings',
                },
                {
                    ']D',
                    mode = { 'x', 'n' },
                    group = 'Next diagnostics extreme mappings',
                },
                {
                    '<leader>x',
                    mode = { 'n', 'x' },
                    group = 'Debugger mappings',
                },
                {
                    '<leader>f',
                    mode = { 'n', 'x' },
                    group = 'Telescope mappings',
                },
                {
                    '<leader>g',
                    mode = { 'n', 'x' },
                    group = 'Git mappings',
                },
                {
                    '<leader>gh',
                    mode = { 'n' },
                    group = 'Git history mappings',
                },
                {
                    '<leader>gl',
                    mode = { 'n' },
                    group = 'Git repo link mappings',
                },
                {
                    '<leader>gb',
                    mode = { 'n' },
                    group = 'Git signs/blame mappings',
                },
                {
                    '<leader>s',
                    mode = { 'n' },
                    group = 'Substitute.nvim',
                },
                {
                    '<leader>t',
                    mode = { 'n' },
                    group = 'Neotest mappings',
                },
                {
                    '<leader>vn',
                    mode = { 'n' },
                    group = 'Swap next treesitter node mappings',
                },
                {
                    '<leader>vp',
                    mode = { 'n' },
                    group = 'Swap previous treesitter node mappings',
                },
                {
                    '<leader>vo',
                    mode = { 'n' },
                    group = 'Add lines above/below mappings',
                },
                {
                    '<leader>vt',
                    mode = { 'n' },
                    group = 'Treesj mappings',
                },
                {
                    '<leader>v',
                    mode = { 'n' },
                    group = 'Misc mappings',
                },
                {
                    '<leader>w',
                    mode = { 'n', 'x' },
                    group = 'Multicursor mappings',
                },
                {
                    '<leader>i',
                    mode = { 'n', 'x' },
                    group = 'Molten mappings',
                },
            })
        end,
    },

    -- Adds markdown preview (opens in browser)
    {
        'iamcco/markdown-preview.nvim',
        cmd = {
            'MarkdownPreviewToggle',
            'MarkdownPreview',
            'MarkdownPreviewStop',
        },
        build = function() vim.fn['mkdp#util#install']() end,
        lazy = true,
    },
    {
        'MeanderingProgrammer/render-markdown.nvim',
        lazy = true,
        -- ft = 'markdown',
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            'echasnovski/mini.icons',
        },
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {
            enabled = config.enable_render_markdown,
        },
    },

    ---------------------------------------------------------------------------
    -- Undotree the solution to screw ups
    {
        'mbbill/undotree',
        lazy = true,
        cmd = { 'UndotreeToggle', 'UndotreeShow' },
        keys = {
            {
                '<leader>u',
                vim.cmd.UndotreeToggle,
                desc = 'Undotree: Toggle Undotree',
            },
        },
        config = function(_, _)
            if vim.fn.has('win32') == 1 then
                vim.g.undotree_DiffCommand = 'FC'
            end
        end,
    },

    ---------------------------------------------------------------------------
    --- Buffer operations

    -- Comment toggling
    {
        'numToStr/Comment.nvim',
        lazy = true,
        keys = {
            {
                'gc',
                mode = { 'n', 'x' },
            },
            {
                'gb',
                mode = { 'n', 'x' },
            },
            {
                'gC',
                require('myconfig.utils.mapping').dot_repeat(
                    function()
                        require('myconfig.utils.mapping').flip_flop_comment()
                    end
                ),
                mode = { 'n', 'x' },
                desc = 'Comment.nvim: Invert comments (dot repeatable)',
                expr = true,
            },
        },
        opts = {},
        config = true,
    },

    -- Adds motions to wrap text in quotes/brackets/tags/etc
    -- using the same motions I use to yank text
    {
        'kylechui/nvim-surround',
        lazy = true,
        event = 'BufReadPre',
        config = true,
    },

    -- Multicursor support
    {
        'jake-stewart/multicursor.nvim',
        lazy = true,
        event = 'BufReadPre',
        config = function()
            local mc = require('multicursor-nvim')

            mc.setup()

            vim.keymap.set(
                { 'n', 'x' },
                '<up>',
                function() mc.addCursor('k') end,
                { desc = 'Custom Multicursor: Add cursor above' }
            )

            vim.keymap.set(
                { 'n', 'x' },
                '<down>',
                function() mc.addCursor('j') end,
                { desc = 'Custom Multicursor: Add cursor below' }
            )

            vim.keymap.set('n', '<c-leftmouse>', mc.handleMouse, {
                desc = 'Custom Multicursor: Add a cursor with the mouse.',
            })

            vim.keymap.set('x', '<leader>ws', mc.splitCursors, {
                desc = 'Custom Multicursor: Split visual slection by regex',
            })

            vim.keymap.set('x', '<leader>wm', mc.matchCursors, {
                desc = 'Custom Multicursor: Add new cursors to visual selection by regex.',
            })

            vim.keymap.set(
                'x',
                '<leader>wt',
                function() mc.transposeCursors(1) end,
                {
                    desc = 'Custom Multicursor: Transpose cursors (Rotate visual selection contents.)',
                }
            )
            vim.keymap.set(
                'x',
                '<leader>wT',
                function() mc.transposeCursors(-1) end,
                {
                    desc = 'Custom Multicursor: Transpose cursors (reverse rotate visual selection contents.)',
                }
            )

            vim.keymap.set('x', '<leader>wi', mc.insertVisual, {
                desc = 'Custom Multicursor: Add cursor to beginning of each line of visual selection and enter insert mode with "I"',
            })
            vim.keymap.set('x', '<leader>wa', mc.appendVisual, {
                desc = 'Custom Multicursor: Add cursor to end of each line of visual selection and enter insert mode with "A"',
            })

            vim.keymap.set({ 'n', 'x' }, '<c-q>', function()
                if mc.cursorsEnabled() then
                    -- Stop other cursors from moving.
                    -- This allows you to reposition the main cursor.
                    mc.disableCursors()
                else
                    mc.addCursor()
                end
            end, {
                desc = 'Custom Multicursor: Either disable cursors (for repositioning main cursor) or add cursor.',
            })

            vim.keymap.set(
                { 'n', 'x' },
                '<leader>w<c-q>',
                mc.duplicateCursors,
                {
                    desc = 'Custom Multicursor: Clone every cursor and disable the originals.',
                }
            )

            vim.keymap.set('n', '<leader>wgv', mc.restoreCursors, {
                desc = 'Custom Multicursor: restore multicursor.',
            })

            vim.keymap.set('n', '<leader>wga', mc.addCursorOperator, {
                desc = 'Custom Multicursor: Pressing `gaip` will add a cursor on each line of a paragraph.',
            })

            vim.keymap.set({ 'n', 'x' }, '<leader>A', mc.matchAllAddCursors, {
                desc = 'Custom Multicursor: Add a cursor for all matches of cursor word/selection in the document.',
            })

            vim.keymap.set(
                { 'n', 'x' },
                '<leader>wg<c-a>',
                mc.sequenceIncrement,
                {
                    desc = 'Custom Multicursor: Increment sequences, treaing all cursors as one sequence.',
                }
            )
            vim.keymap.set(
                { 'n', 'x' },
                '<leader>wg<c-x>',
                mc.sequenceDecrement,
                {
                    desc = 'Custom Multicursor: Decrement sequences, treaing all cursors as one sequence.',
                }
            )

            vim.keymap.set(
                'n',
                '<leader>w/n',
                function() mc.searchAddCursor(1) end,
                {
                    desc = 'Custom Multicursor: Add a cursor and jump to the next search result.',
                }
            )
            vim.keymap.set(
                'n',
                '<leader>w/N',
                function() mc.searchAddCursor(-1) end,
                {
                    desc = 'Custom Multicursor: Add a cursor and jump to the previous search result.',
                }
            )

            vim.keymap.set(
                'n',
                '<leader>w/s',
                function() mc.searchSkipCursor(1) end,
                {
                    desc = 'Custom Multicursor: Jump to the next search result without adding a cursor.',
                }
            )
            vim.keymap.set(
                'n',
                '<leader>w/S',
                function() mc.searchSkipCursor(-1) end,
                {
                    desc = 'Custom Multicursor: Jump to the previous search result without adding a cursor.',
                }
            )

            vim.keymap.set('n', '<leader>w/A', mc.searchAllAddCursors, {
                desc = 'Custom Multicursor: Add a cursor to every search result in the buffer.',
            })

            vim.keymap.set('n', '<leader>w/A', mc.searchAllAddCursors, {
                desc = 'Custom Multicursor: Add a cursor to every search result in the buffer.',
            })

            vim.keymap.set(
                { 'n', 'x' },
                ']wd',
                function() mc.diagnosticAddCursor(1) end,
                {
                    desc = 'Custom Multicursor: Add  new cursor for next diagnostics.',
                }
            )
            vim.keymap.set(
                { 'n', 'x' },
                '[wd',
                function() mc.diagnosticAddCursor(-1) end,
                {
                    desc = 'Custom Multicursor: Add new cursor for previous diagnostics.',
                }
            )
            vim.keymap.set(
                { 'n', 'x' },
                ']ws',
                function() mc.diagnosticSkipCursor(1) end,
                {
                    desc = 'Custom Multicursor: Skip adding a new cursor for next diagnostics.',
                }
            )
            vim.keymap.set(
                { 'n', 'x' },
                '[wS',
                function() mc.diagnosticSkipCursor(-1) end,
                {
                    desc = 'Custom Multicursor: Skip adding a new cursor for previous diagnostics.',
                }
            )

            vim.keymap.set({ 'n', 'x' }, '<leader>wmd', function()
                -- See `:h vim.diagnostic.GetOpts`.
                mc.diagnosticMatchCursors({
                    severity = vim.diagnostic.severity.ERROR,
                })
            end, {
                desc = 'Custom Multicursor: Press `mdip` to add a cursor for every error diagnostic in the range `ip`.',
            })

            vim.keymap.set({ 'n', 'x' }, '<leader>wx', mc.deleteCursor, {
                desc = 'Custom Multicursor: delete main cursor',
            })

            mc.addKeymapLayer(function(layerSet)
                -- Select a different cursor as the main one. (Rotate the main cursor.)
                layerSet(
                    { 'n', 'v' },
                    '<left>',
                    mc.nextCursor,
                    { desc = 'Custom Multicursor: Cycle main cursor left.' }
                )
                layerSet(
                    { 'n', 'v' },
                    '<right>',
                    mc.prevCursor,
                    { desc = 'Custom Multicursor: Cycle main cursor right.' }
                )

                -- Delete the main cursor.
                -- TODO I would like to have this work but this causes the
                -- keymap to wait because of my debuging keymap namespace
                -- is also <leader>x
                -- layerSet({ 'n', 'x' }, '<leader>x', mc.deleteCursor)

                -- Enable and clear cursors using escape.
                layerSet('n', '<esc>', function()
                    if not mc.cursorsEnabled() then
                        mc.enableCursors()
                    else
                        mc.clearCursors()
                    end
                end, {
                    desc = 'Custom Multicursor: Re-enable multi cursors or clear cursors',
                })

                -- Add a cursor and jump to the next word under cursor.
                layerSet(
                    { 'n', 'x' },
                    '<c-n>',
                    function() mc.addCursor('*') end,
                    {
                        desc = 'Custom Multicursor: Add cursor and jump to next word under cursor.',
                    }
                )

                -- Jump to the next word under cursor but do not add a cursor.
                layerSet(
                    { 'n', 'x' },
                    '<c-s>',
                    function() mc.skipCursor('*') end,
                    {
                        desc = 'Custom Multicursor: Jump to next word under cursor but do not add a cursor.',
                    }
                )
            end)

            -- Customize how cursors look.
            vim.api.nvim_set_hl(0, 'MultiCursorCursor', { reverse = true })
            vim.api.nvim_set_hl(0, 'MultiCursorVisual', { link = 'Visual' })
            vim.api.nvim_set_hl(0, 'MultiCursorSign', { link = 'SignColumn' })
            vim.api.nvim_set_hl(
                0,
                'MultiCursorMatchPreview',
                { link = 'Search' }
            )
            vim.api.nvim_set_hl(
                0,
                'MultiCursorDisabledCursor',
                { reverse = true }
            )
            vim.api.nvim_set_hl(
                0,
                'MultiCursorDisabledVisual',
                { link = 'Visual' }
            )
            vim.api.nvim_set_hl(
                0,
                'MultiCursorDisabledSign',
                { link = 'SignColumn' }
            )
        end,
    },

    ---------------------------------------------------------------------------
    -- Treesitter Parsers and Parser Utils
    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'main',
        config = function()
            --TODO detect when there is an available query for a filetype that isn't in my ensure installed

            -- Make sure we are not running in headless or embedded mode
            local is_ui_visible = #vim.api.nvim_list_uis() > 0
            if is_ui_visible then
                local ensure_installed = config.treesiter_ensure_installed
                require('myconfig.treesitter').prompt_install_missing_and_update(
                    ensure_installed
                )
            end

            local custom_csharp_queries = [[
                (cast_expression
                  (
                    "(" @cast.outer
                    .
                    type: (_)  @cast.inner
                    .
                    ")" @cast.outer 
                  ) 
                )

                (method_declaration
                    name: (_) @function_declaration_name.inner)

                (constructor_declaration
                    name: (_) @function_declaration_name.inner)
            ]]
            local custom_lua_queries = [[
              ; function M.is_dict() ... end
                  (function_declaration
                    name: (dot_index_expression
                      field: (_) @function_declaration_name.inner
                    )
                  )

              ;local is_dict = function() ... end
              local_declaration: (variable_declaration
                (assignment_statement
                  (variable_list
                    name: (identifier) @function_declaration_name.inner )
                  (expression_list
                    value: (function_definition))
                )
              )

              ; M.is_dict = function() ... end
              (assignment_statement
                (variable_list
                  name: (dot_index_expression
                      field: (_) @function_declaration_name.inner))
                (expression_list
                  value: (function_definition))
                )

              ; local function is_dict() ... end
              local_declaration: (function_declaration
                name: (identifier) @function_declaration_name.inner
              )


            ]]
            vim.treesitter.query.set(
                'c_sharp',
                config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP,
                custom_csharp_queries
            )

            vim.treesitter.query.set(
                'lua',
                config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP,
                custom_lua_queries
            )
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-context',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function(_, _)
            require('treesitter-context').setup({
                enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
                multiwindow = false, -- Enable multiwindow support.
                max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
                min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
                line_numbers = true,
                multiline_threshold = 20, -- Maximum number of lines to show for a single context
                trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
                mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
                -- Separator between context and content. Should be a single character string, like '-'.
                -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
                separator = nil,
                zindex = 20, -- The Z-index of the context window
                on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
            })
        end,
    },

    --tressiter split and join nodes
    {
        'Wansmer/treesj',
        lazy = true,
        keys = {
            {
                '<leader>vtt',
                function() require('treesj').toggle() end,
                mode = { 'n' },
                desc = 'treesj: Toggle splitting and joining treesitter node',
            },
            {
                '<leader>vtj',
                function() require('treesj').join() end,
                mode = { 'n' },
                desc = 'treesj: Joining treesitter node',
            },
            {
                '<leader>vts',
                function() require('treesj').split() end,
                mode = { 'n' },
                desc = 'treesj: Split treesitter node',
            },
        },
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function(_, _)
            local lang_utils = require('treesj.langs.utils')
            local opts = {
                use_default_keymaps = false,
                ---@type number If line after join will be longer than max value, node will not be formatted
                max_join_length = 2000,
                langs = {
                    c_sharp = {
                        argument_list = lang_utils.set_preset_for_args(),
                        initializer_expression = lang_utils.set_preset_for_dict(),
                        formal_parameters = lang_utils.set_preset_for_args(),
                        block = lang_utils.set_preset_for_statement(),
                        constructor_body = lang_utils.set_preset_for_statement(),
                        array_initializer = lang_utils.set_preset_for_list(),
                        annotation_argument_list = lang_utils.set_preset_for_args(),
                        enum_body = lang_utils.set_preset_for_dict(),
                        enum_declaration = {
                            target_nodes = { 'enum_body' },
                        },
                        if_statement = {
                            target_nodes = { 'block' },
                        },
                        annotation = {
                            target_nodes = { 'annotation_argument_list' },
                        },
                        method_declaration = {
                            target_nodes = { 'block' },
                        },
                        object_creation_expression = {
                            target_nodes = { 'initializer_expression' },
                        },
                        variable_declarator = {
                            target_nodes = { 'array_initializer' },
                        },
                        constructor_declaration = {
                            target_nodes = { 'constructor_body' },
                        },
                        element_binding_expression = lang_utils.set_preset_for_list(),
                    },
                },
            }
            require('treesj').setup(opts)
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        lazy = true,
        -- event = 'BufReadPre',
        config = function(_, _)
            ---@type TSTextObjects.UserConfig
            local opts = {
                select = {
                    -- Automatically jump forward to textobj, similar to targets.vim
                    lookahead = true,
                    -- You can choose the select mode (default is charwise 'v')
                    --
                    -- Can also be a function which gets passed a table with the keys
                    -- * query_string: eg '@function.inner'
                    -- * method: eg 'v' or 'o'
                    -- and should return the mode ('v', 'V', or '<c-v>') or a table
                    -- mapping query_strings to modes.
                    -- selection_modes = {
                    --     ['@parameter.outer'] = 'v', -- charwise
                    --     ['@function.outer'] = 'V', -- linewise
                    --     ['@class.outer'] = '<c-v>', -- blockwise
                    -- },
                    -- If you set this to `true` (default is `false`) then any textobject is
                    -- extended to include preceding or succeeding whitespace. Succeeding
                    -- whitespace has priority in order to act similarly to eg the built-in
                    -- `ap`.
                    --
                    -- Can also be a function which gets passed a table with the keys
                    -- * query_string: eg '@function.inner'
                    -- * selection_mode: eg 'v'
                    -- and should return true of false
                    include_surrounding_whitespace = false,
                },
            }
            require('nvim-treesitter-textobjects').setup(opts)
        end,
    },

    {
        'gbprod/substitute.nvim',
        keys = {
            {
                '<leader>s',
                function() require('substitute').operator() end,
                desc = 'Substitute: operator',
            },
            {
                '<leader>ss',
                function() require('substitute').line() end,
                desc = 'Substitute: line',
            },
            {
                '<leader>S',
                function() require('substitute').eol() end,
                desc = 'Substitute: eol',
            },
            {
                '<leader>s',
                function() require('substitute').visual() end,
                mode = { 'x' },
                desc = 'Substitute: visual',
            },
        },
        opts = {
            on_substitute = nil,
            yank_substituted_text = false,
            preserve_cursor_position = false,
            modifiers = nil,
            highlight_substituted_text = {
                enabled = true,
                timer = 500,
            },
            range = {
                prefix = 's',
                prompt_current_text = false,
                confirm = false,
                complete_word = false,
                subject = nil,
                range = nil,
                suffix = '',
                auto_apply = false,
                cursor_position = 'end',
            },
            exchange = {
                motion = false,
                use_esc_to_cancel = true,
                preserve_cursor_position = false,
            },
        },
    },

    -- Adds refactor commands
    {
        'ThePrimeagen/refactoring.nvim',
        lazy = true,
        config = true,
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
        },
        cmd = { 'Refactor' },
    },

    ---------------------------------------------------------------------------
    -- Testing

    {
        'nvim-neotest/neotest',
        dependencies = {
            'nvim-neotest/nvim-nio',
            'nvim-lua/plenary.nvim',
            'antoinemadec/FixCursorHold.nvim',
            'nvim-treesitter/nvim-treesitter',
            -- adapters
            -- TODO replace neotest-rust because it is archived
            'rouge8/neotest-rust',
            'nvim-neotest/neotest-python',
            'nsidorenco/neotest-vstest',
            -- 'Issafalcon/neotest-dotnet',
        },
        lazy = true,
        cmd = 'Neotest',
        keys = {
            {
                '<leader>tr',
                function() require('neotest').run.run({}) end,
                desc = 'Neotest: Run the nearest test',
            },
            {
                '<leader>tc',
                function()
                    require('neotest').run.run({
                        vim.fn.expand('%'),
                    })
                end,
                desc = 'Neotest: Run the current file',
            },
            {
                '<leader>tm',
                function()
                    require('neotest').run.run({
                        vim.fn.getcwd(),
                    })
                end,
                desc = 'Neotest: Run all tests in cwd',
            },
            {
                '<leader>td',
                function()
                    require('myconfig.dap').shellslash_hack()
                    require('neotest').run.run({
                        strategy = 'dap',
                        suite = false, --TODO haven't tested if this needs to be false or true
                    })
                end,
                desc = 'Neotest: Debug the nearest test',
            },
            {
                '<leader>tq',
                function() require('neotest').run.stop() end,
                desc = 'Neotest: Stop the nearest test',
            },
            {
                '<leader>ta',
                function() require('neotest').run.attach() end,
                desc = 'Neotest: Attach to the nearest test',
            },
            {
                '<leader>ts',
                function() require('neotest').summary.toggle() end,
                mode = 'n',
                desc = 'Neotest: Toggle Summary',
            },
            {
                '<leader>tp',
                function() require('neotest').myoutput_panel.toggle() end,
                mode = 'n',
                desc = 'Neotest: toggle output-panel',
            },
            {
                '<leader>to',
                function() require('neotest').myoutput.open() end,
                mode = 'n',
                desc = 'Neotest: toggle output floating window',
            },
        },
        config = function(_, _)
            ---@type neotest.Config
            local opts = {
                dap = false, --I will manually enable so that dap can be lazy loaded
                -- putting custom consumers here is need to properly initialize
                -- the consumer and adds it to the neotest metatable so that
                -- custom consumers can be used like `require('neotest').myoutput.open()`
                --
                -- Note: it does not add them to the Neotest user command
                -- but monkey patching could be used to replace some sub-commands
                consumers = {
                    myoutput = require('neotest.consumers.myoutput'),
                    myoutput_panel = require(
                        'neotest.consumers.myoutput_panel'
                    ),
                    myquickfix = require('neotest.consumers.myquickfix'),
                },
                custom_consumer_config = {
                    myquickfix = {
                        open = true,
                        problem_matcher = {
                            pattern = {
                                -- "vim_regexp": "^%s+at%s(.*)%sin%s(.+%.cs):line%s([0-9]+)%s*$",
                                regexp = '^\\s+at\\s(.*)\\sin\\s(.+\\.cs):line\\s([0-9]+)\\s*$',
                                message = 1,
                                file = 2,
                                line = 3,
                            },
                        },
                    },
                },
                quickfix = {
                    --disabling default quickfix consumer because I'm going to use my own
                    enabled = false,
                },
                adapters = {
                    require('neotest-python')({
                        dap = { justMyCode = false },
                    }),
                    require('neotest-rust')({
                        -- args = { '--no-capture' },
                        -- dap_adapter = 'lldb',
                    }),
                    require('neotest-vstest')({
                        -- Path to dotnet sdk path.
                        -- Used in cases where the sdk path cannot be auto discovered.
                        -- sdk_path = "/usr/local/dotnet/sdk/9.0.101/",
                        sdk_path = 'C:\\Program Files\\dotnet\\sdk',

                        -- table is passed directly to DAP when debugging tests.
                        dap_settings = {
                            type = 'netcoredbg',
                        },

                        -- If multiple solutions exists the adapter will ask you to choose one.
                        -- If you have a different heuristic for choosing a solution you can provide a function here.
                        -- solution_selector = function(solutions)
                        --     return nil -- return the solution you want to use or nil to let the adapter choose.
                        -- end,
                    }),
                    -- require('neotest-dotnet')({
                    --     dap = {
                    --         -- Extra arguments for nvim-dap configuration
                    --         -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
                    --         args = { justMyCode = false },
                    --         -- Enter the name of your dap adapter, the default value is netcoredbg
                    --         adapter_name = 'netcoredbg',
                    --     },
                    --     dotnet_additional_args = {
                    --         '--logger "console;verbosity=detailed"',
                    --     },
                    --     -- Let the test-discovery know about your custom attributes (otherwise tests will not be picked up)
                    --     -- Note: Only custom attributes for non-parameterized tests should be added here. See the support note about parameterized tests
                    --     -- custom_attributes = {
                    --     --     xunit = { 'MyCustomFactAttribute' },
                    --     --     nunit = { 'MyCustomTestAttribute' },
                    --     --     mstest = { 'MyCustomTestMethodAttribute' },
                    --     -- },
                    --     -- Provide any additional "dotnet test" CLI commands here. These will be applied to ALL test runs performed via neotest. These need to be a table of strings, ideally with one key-value pair per item.
                    --     -- dotnet_additional_args = {
                    --     --     '--verbosity detailed',
                    --     -- },
                    --     -- Tell neotest-dotnet to use either solution (requires .sln file) or project (requires .csproj or .fsproj file) as project root
                    --     -- Note: If neovim is opened from the solution root, using the 'project' setting may sometimes find all nested projects, however,
                    --     --       to locate all test projects in the solution more reliably (if a .sln file is present) then 'solution' is better.
                    --     -- discovery_root = 'project', -- Default
                    --     discovery_root = 'solution',
                    -- }),
                },
                icons = {
                    child_indent = get_icon('neotest_child_indent'),
                    child_prefix = get_icon('neotest_child_prefix'),
                    collapsed = get_icon('neotest_collapsed'),
                    expanded = get_icon('neotest_expanded'),
                    failed = get_icon('neotest_failed'),
                    final_child_indent = get_icon('neotest_final_child_indent'),
                    final_child_prefix = get_icon('neotest_final_child_prefix'),
                    non_collapsible = get_icon('neotest_non_collapsible'),
                    notify = get_icon('neotest_notify'),
                    passed = get_icon('neotest_passed'),
                    running = get_icon('neotest_running'),
                    skipped = get_icon('neotest_skipped'),
                    unknown = get_icon('neotest_unknown'),
                    watching = get_icon('neotest_watching'),
                },
            }
            require('neotest').setup(opts)
        end,
    },

    ---------------------------------------------------------------------------
    -- DEBUGGING

    -- DAP Client for nvim
    {
        'mfussenegger/nvim-dap',
        lazy = true,
        keys = {
            {
                '<leader>xb',
                function() require('dap').toggle_breakpoint() end,
                desc = 'Debug: Add Breakpoint',
            },
            {
                '<leader>xB',
                function()
                    require('dap').set_breakpoint(
                        vim.fn.input('Breakpoint condition: ')
                    )
                end,
                desc = 'Debug: Breakpoint Condition',
            },
            {
                '<leader>xc',
                function() require('dap').continue() end,
                desc = 'Debug: Start/Continue Debugger',
            },
            -- {
            --     '<leader>xa',
            --     function()
            --         require('dap').continue({
            --             ---From https://github.com/LazyVim/LazyVim/blob/2c37492461bf6af09a3e940f8b3ea0a123608bfd/lua/lazyvim/plugins/extras/dap/core.lua#L1C1-L17C4
            --             ---I haven't tested this yet. TODO remove this note once I have tried this out
            --             ---@type fun(before_args: {type?:string, args?:string[]|fun():string[]?}):any
            --             before = function(before_args)
            --                 local args = type(before_args.args) == 'function'
            --                         and (before_args.args() or {})
            --                     or before_args.args
            --                     or {} --[[@as string[] | string ]]
            --                 local args_str = type(args) == 'table'
            --                         and table.concat(args, ' ')
            --                     or args --[[@as string]]
            --
            --                 before_args = vim.deepcopy(before_args)
            --                 ---@cast args string[]
            --                 before_args.args = function()
            --                     local new_args = vim.fn.expand(
            --                         vim.fn.input('Run with args: ', args_str)
            --                     ) --[[@as string]]
            --                     if
            --                         before_args.type
            --                         and before_args.type == 'java'
            --                     then
            --                         ---@diagnostic disable-next-line: return-type-mismatch
            --                         return new_args
            --                     end
            --                     return require('dap.utils').splitstr(new_args)
            --                 end
            --                 return before_args
            --             end,
            --         })
            --     end,
            --     desc = 'Debug: Run with Args',
            -- },
            {
                '<leader>xC',
                function() require('dap').run_to_cursor() end,
                desc = 'Debug: Run to Cursor',
            },
            {
                '<leader>xt',
                function() require('dap').terminate() end,
                desc = 'Debug: Terminate Debugger',
            },
            {
                '<leader>xg',
                function() require('dap').goto_() end,
                desc = 'Debug: Go to line (no execute)',
            },
            {
                '<leader>xi',
                function() require('dap').step_into() end,
                desc = 'Debug: Step Into',
            },
            {
                '<leader>xj',
                function() require('dap').down() end,
                desc = 'Debug: Down',
            },
            {
                '<leader>xk',
                function() require('dap').up() end,
                desc = 'Debug: Up',
            },
            {
                '<leader>xl',
                function() require('dap').run_last() end,
                desc = 'Debug: Run Last',
            },
            {
                '<leader>xo',
                function() require('dap').step_out() end,
                desc = 'Debug: Step Out',
            },
            {
                '<leader>xO',
                function() require('dap').step_over() end,
                desc = 'Debug: Step Over',
            },
            {
                '<leader>xp',
                function() require('dap').pause() end,
                desc = 'Debug: Pause',
            },
            {
                '<leader>xr',
                function() require('dap').repl.toggle() end,
                desc = 'Debug: Toggle REPL',
            },
            {
                '<leader>xs',
                function() require('dap').session() end,
                desc = 'Debug: Session',
            },
            {
                '<leader>xt',
                function() require('dap').terminate() end,
                desc = 'Debug: Terminate',
            },
            {
                '<leader>xw',
                function() require('dap.ui.widgets').hover() end,
                desc = 'Debug: Widgets',
            },

            {
                '<leader>xf',
                function() require('dap').focus_frame() end,
                desc = 'Debug: Focus Frame',
            },
        },
        config = function(_, _)
            local dap = require('dap')
            require('overseer').enable_dap()

            --Adapters
            dap.adapters.codelldb = {
                type = 'server',
                port = '${port}',
                executable = {
                    command = require('myconfig.utils.path').get_mason_tool_path(
                        'codelldb'
                    ),
                    args = { '--port', '${port}' },

                    -- On windows you may have to uncomment this:
                    -- detached = false,
                },
            }
            dap.adapters.executable = {
                type = 'executable',
                command = require('myconfig.utils.path').get_mason_tool_path(
                    'codelldb'
                ),
                name = 'lldb1',
                host = '127.0.0.1',
                port = 13000,
            }

            --Things that make dotnet debugging work
            --```csproj
            -- <Project Sdk="Microsoft.NET.Sdk">
            --   <PropertyGroup>
            --     <OutputType>Exe</OutputType>
            --     <TargetFramework>net8.0</TargetFramework>
            --     <ImplicitUsings>enable</ImplicitUsings>
            --     <Nullable>enable</Nullable>
            --     <DebugSymbols>true</DebugSymbols>
            --     <DebugType>portable</DebugType>
            --   </PropertyGroup>
            -- </Project>
            -- ```
            --
            -- DebugType must be set to portable
            --
            -- Then set the vim option `set noshellslash` setting it in the dap.configurations.cs.program function was the most consistent
            -- maybe it is getting overwritten somewhere else in my config
            --
            -- Then directly use the netcoredbg.exe not the netcoredbg.cmd that mason downloads
            dap.adapters.coreclr = {
                type = 'executable',
                command = require('myconfig.dap').get_mason_tool_netcoredbg_path(),
                args = { '--interpreter=vscode' },
                options = {
                    --https://github.com/Wiebesiek/ZeoVim
                    detached = false, -- Will put the output in the REPL. #CloseEnough
                },
            }

            -- Neotest Test runner looks at this table
            dap.adapters.netcoredbg = {
                type = 'executable',
                command = require('myconfig.dap').get_mason_tool_netcoredbg_path(),
                args = { '--interpreter=vscode' },
                options = {
                    --https://github.com/Wiebesiek/ZeoVim
                    detached = false, -- Will put the output in the REPL. #CloseEnough
                },
            }

            --configurations
            dap.configurations.rust = {
                {
                    name = 'codelldb: Launch file',
                    type = 'codelldb',
                    request = 'launch',
                    program = require('myconfig.dap').input_executable,
                    cwd = '${workspaceFolder}',
                    stopOnEntry = false,
                },
            }

            dap.configurations.cs = {
                {
                    type = 'coreclr',
                    name = 'netcoredbg: build and launch',
                    request = 'launch',
                    program = require('myconfig.dap').dotnet_build_and_pick_executable,
                },
                {
                    type = 'coreclr',
                    name = 'netcoredbg: launch (fuzzy pick executable)',
                    request = 'launch',
                    console = 'integratedTerminal',
                    program = require('myconfig.dap').fuzzy_pick_executable,
                },
                {
                    type = 'coreclr',
                    name = 'netcoredbg: launch via input',
                    request = 'launch',
                    program = require('myconfig.dap').input_executable,
                },
                {
                    type = 'coreclr',
                    name = 'netcoredbg: attach (fuzzy pick process)',
                    request = 'attach',
                    processId = require('myconfig.dap').fuzzy_pick_process,
                },
                --TODO - possibly useful snippet to automatically find the dll
                --https://www.reddit.com/r/csharp/comments/15ktebq/comment/ks2dvb0/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
                -- local dir = vim.loop.cwd() .. '/' .. vim.fn.glob 'bin/Debug/net*/linux-x64/'
                -- local name = dir .. vim.fn.glob('*.csproj'):gsub('%.csproj$', '.dll')
                -- if not exists(name) then os.execute 'dotnet build -r linux-x64' end
                -- return name
            }

            dap.configurations.fsharp = {
                {
                    type = 'coreclr',
                    name = 'netcoredbg: launch',
                    request = 'launch',
                    program = require('myconfig.dap').dotnet_build_and_pick_executable,
                },
            }
        end,
    },

    -- UI for the debugger
    -- - the debugger UI is also automatically opened when starting/stopping the debugger
    -- - toggle debugger UI manually with `<leader>du`
    {
        'rcarriga/nvim-dap-ui',
        lazy = true,
        dependencies = 'mfussenegger/nvim-dap',
        keys = {
            {
                '<leader>xu',
                function() require('dapui').toggle() end,
                desc = 'Debug: Toggle debugger UI',
            },
            {
                '<leader>xe',
                function() require('dapui').eval() end,
                desc = 'Debug: Eval',
                mode = { 'n', 'v' },
            },
        },
        opts = {
            controls = {
                icons = {
                    pause = get_icon('debug_pause'),
                    play = get_icon('debug_play'),
                    step_into = get_icon('debug_step_into'),
                    step_over = get_icon('debug_step_over'),
                    step_out = get_icon('debug_step_out'),
                    step_back = get_icon('debug_step_back'),
                    run_last = get_icon('debug_run_last'),
                    terminate = get_icon('debug_terminate'),
                    disconnect = get_icon('debug_disconnect'),
                },
            },
        },
        -- automatically open/close the DAP UI when starting/stopping the debugger
        config = function(_, opts)
            require('dapui').setup(opts)
            local listener = require('dap').listeners
            listener.after.event_initialized['dapui_config'] = function()
                require('dapui').open()
            end
        end,
    },

    -- Configuration for the python debugger
    {
        'mfussenegger/nvim-dap-python',
        lazy = true,
        ft = 'python',
        dependencies = 'mfussenegger/nvim-dap',
        config = function()
            -- configures debugpy
            -- uses the debugypy installation by mason
            local debugpy_package =
                require('mason-registry').get_package('debugpy')
            local debugpyPythonPackagePath = debugpy_package:get_install_path()
            local debugpyPythonPath = debugpyPythonPackagePath
                .. '/venv/bin/python3'
            require('dap-python').setup(debugpyPythonPath, {})
        end,
    },

    ---------------------------------------------------------------------------
    --- LSP's and more

    {
        'benlubas/molten-nvim',
        version = '^1.0.0',
        -- build = ':UpdateRemotePlugins',
        dependencies = 'willothy/wezterm.nvim',
        lazy = true,
        keys = {
            {
                '<leader>ip',
                function()
                    local venv = os.getenv('VIRTUAL_ENV')
                        or os.getenv('CONDA_PREFIX')
                    vim.print(venv)
                    if venv ~= nil then
                        -- in the form of /home/benlubas/.virtualenvs/VENV_NAME
                        venv = string.match(venv, '/.+/(.+)')
                        vim.cmd(('MoltenInit %s'):format(venv))
                    else
                        vim.cmd('MoltenInit python3')
                    end
                end,

                desc = 'Initialize Molten for python3',
                silent = true,
            },
        },
        init = function()
            vim.g.molten_auto_open_output = false -- cannot be true if molten_image_provider = "wezterm"
            vim.g.molten_output_show_more = true
            vim.g.molten_image_provider = 'wezterm'
            vim.g.molten_output_virt_lines = true
            vim.g.molten_split_direction = 'right' --direction of the output window, options are "right", "left", "top", "bottom"
            vim.g.molten_split_size = 40 --(0-100) % size of the screen dedicated to the output window
            vim.g.molten_virt_text_output = true
            vim.g.molten_use_border_highlights = true
            vim.g.molten_virt_lines_off_by_1 = true
            vim.g.molten_auto_image_popup = false
        end,
        -- config = true,
    },
    {
        'folke/lazydev.nvim',
        ft = 'lua', -- only load on lua files
        lazy = true,
        opts = {
            library = {
                { path = 'wezterm-types', mods = { 'wezterm' } },
            },
        },
    },
    { 'justinsgithub/wezterm-types', lazy = true }, -- optional wezterm lua types
    -- Helps configure which json and yaml schemas to use for the corresponding lsp
    -- Catalog of general schemas: https://www.schemastore.org/api/json/catalog.json
    -- Catalog of kubernetes schemas: https://github.com/datreeio/CRDs-catalog/tree/main
    -- Note: The setup for this plugin is in the lspconfig plugin's setup function
    {
        'b0o/schemastore.nvim',
        lazy = true, -- my setup for lspconfig will lazy load this plugin
    },

    -- A frontend for yaml schemas to use
    -- Adds a telescope picker via `Telescope yaml_schema`
    -- Adds a hook to determine which shema is selected (useful for statusline)
    -- Enhances auto-completion descriptions
    -- Adds detection mechanism for kubernetes files as they are context dependent rather the file name dependent
    -- Note: Most of the setup for this is in the lspconfig plugin's setup function
    {
        'someone-stole-my-name/yaml-companion.nvim',
        lazy = true, -- my setup for lspconfig will lazy load this plugin
        dependencies = {
            { 'neovim/nvim-lspconfig' },
            { 'nvim-lua/plenary.nvim' },
            { 'nvim-telescope/telescope.nvim' },
        },
        config = function() require('telescope').load_extension('yaml_schema') end,
    },

    {
        'L3MON4D3/LuaSnip',
        lazy = true,
        dependencies = {
            'rafamadriz/friendly-snippets',
            {
                'benfowler/telescope-luasnip.nvim',
                dependencies = {
                    'nvim-telescope/telescope.nvim',
                },
                config = function()
                    require('telescope').load_extension('luasnip')
                end,
            },
        },
        config = function(_, opts)
            if opts then require('luasnip').config.setup(opts) end
            vim.tbl_map(
                function(type)
                    require('luasnip.loaders.from_' .. type).lazy_load()
                end,
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
    },

    {
        'crwebb85/luasnip-lsp-server.nvim',
        dependencies = {
            { 'L3MON4D3/LuaSnip' },
        },
        -- dev = true,
        config = true,
    },

    {
        'williamboman/mason.nvim',
        lazy = true,
        event = 'VeryLazy',
        dependencies = {
            -- Need to require nvim-lspconfig so that the configurations are loaded
            -- before we run vim.lsp.enable
            { 'neovim/nvim-lspconfig' },
        },
        config = function(_, opts)
            require('mason').setup(opts)

            --Mark down lsp comparison
            --
            -- Completion
            -- - markdown_oxide - keeps periods in note references and also completes headers (better completion)
            -- - marksman - removes periods by default (can be configured to keep periods) in note references and does not complete headers
            --
            -- Hover
            -- - markdown_oxide - hover always preview the current note (can be disabled in .moxide.toml)
            -- - marksman - hover over note references previews the note
            --
            -- Go To Definition
            -- - markdown_oxide - not supported
            -- - marksman - goes to note reference
            --
            -- Code References
            -- - marksman
            --   - create table of contents
            --   - create note for note reference that does not exist
            --
            -- Diagnostics
            -- - marksman - errors for non existent document links
            --
            -- Rename
            -- - markdown_oxide
            --   header rename - did not update links containing the header
            --
            -- Note: create a .moxide.toml file in note folder to get full
            -- capabilities https://oxide.md/v0/References/v0+Configuration+Reference
            --
            -- Note: create a .marksman.toml file in note folder to get full
            -- capabilities https://github.com/artempyanykh/marksman/blob/main/docs/configuration.md

            local ensure_installed = {
                -- LSPs
                --Go to https://github.com/williamboman/mason-lspconfig.nvim to find translations
                --between the mason name and the lspconfig name
                ['pyright'] = 'pyright', -- LSP for python
                ['ruff'] = 'ruff',
                ['marksman'] = 'marksman', -- Markdown
                ['markdown-oxide'] = 'markdown_oxide', -- Markdown notes
                ['lua-language-server'] = 'lua_ls', -- (lua_ls) LSP for lua files
                ['emmylua_ls'] = 'emmylua_ls', --lua
                ['typescript-language-server'] = 'ts_ls', -- tsserver LSP (keywords: typescript, javascript)
                ['eslint-lsp'] = 'eslint', -- eslint Linter (implemented as a standalone lsp to improve speed)(keywords: javascript, typescript)
                ['ansible-language-server'] = 'ansiblels',
                ['omnisharp'] = 'omnisharp', -- C#
                ['gopls'] = 'gopls', -- go lang
                ['rust-analyzer'] = 'rust_analyzer',
                ['yaml-language-server'] = 'yamlls', -- (yamlls) (keywords: yaml)
                ['json-lsp'] = 'jsonls', --(jsonls) (keywords: json)
                ['taplo'] = 'taplo', -- LSP for toml (for pyproject.toml files)
                ['powershell-editor-services'] = 'powershell_es', -- powershell
                ['lemminx'] = 'lemminx', -- xml
                ['sqls'] = 'sqls', -- sql

                -- Formatters
                'stylua', -- Formatter for lua files
                'prettier', -- Formatter typescript (keywords: angular, css, flow, graphql, html, json, jsx, javascript, less, markdown, scss, typescript, vue, yaml
                'prettierd', --Uses a daemon for faster formatting (keywords: angular, css, flow, graphql, html, json, jsx, javascript, less, markdown, scss, typescript, vue, yaml)
                'xmlformatter',
                'jq', --json formatter
                'shfmt',

                -- 'fixjson', -- json fixer, fixes invalid json like trailing commas

                -- Debuggers
                'codelldb',
                'debugpy', -- python debugger
                'netcoredbg',
            }

            ---based on https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim/blob/1255518cb067e038a4755f5cb3e980f79b6ab89c/lua/mason-tool-installer/init.lua#L20
            local mason_registry = require('mason-registry')

            ---Installs the mason package
            ---@param mason_package_name string
            ---@param lspconfig_name? string
            local function install_package(mason_package_name, lspconfig_name)
                local mason_package =
                    mason_registry.get_package(mason_package_name)
                if not mason_package:is_installed() then
                    vim.notify(
                        string.format('%s: installing', mason_package.name),

                        vim.log.levels.INFO,
                        { title = 'my-mason-tool-installer' }
                    )
                    mason_package:once('install:success', function()
                        vim.schedule(function()
                            vim.notify(
                                string.format(
                                    '%s: successfully installed',
                                    mason_package.name
                                ),
                                vim.log.levels.INFO,
                                { title = 'my-mason-tool-installer' }
                            )
                            if lspconfig_name ~= nil then
                                vim.lsp.enable(lspconfig_name)
                            end
                        end)
                    end)

                    mason_package:once('install:failed', function()
                        vim.schedule(
                            function()
                                vim.notify(
                                    string.format(
                                        '%s: failed to install',
                                        mason_package.name
                                    ),
                                    vim.log.levels.ERROR,
                                    { title = 'my-mason-tool-installer' }
                                )
                            end
                        )
                    end)
                    mason_package:install({ version = nil })
                elseif lspconfig_name ~= nil then
                    vim.lsp.enable(lspconfig_name)
                end
            end

            local function install_packages()
                local Set = require('myconfig.utils.datastructure').Set
                local mason_install_exclusion_package_names =
                    Set:new(config.exclude_mason_install)

                for key, value in pairs(ensure_installed) do
                    local package_name
                    local lspconfig_name = nil
                    if type(key) == 'string' then
                        package_name = key
                        lspconfig_name = value
                    else
                        package_name = value
                    end

                    if
                        not mason_install_exclusion_package_names:has(
                            package_name
                        )
                    then
                        install_package(package_name, lspconfig_name)
                    end
                end
            end
            mason_registry.refresh(install_packages)
        end,
    },

    {
        'neovim/nvim-lspconfig',
        lazy = true,
        config = function(_, _)
            ---Removing lspconfigs version of these autocmds and reenable my own
            vim.api.nvim_del_user_command('LspStart')
            vim.api.nvim_del_user_command('LspRestart')
            vim.api.nvim_del_user_command('LspStop')
            require('myconfig.lsp.lsp').setup_user_commands()

            local default_root_pattern = require('lspconfig.util').root_pattern

            require('lspconfig.util').root_pattern = function(...)
                local pattern_func = default_root_pattern(...)
                return function(start_path)
                    local path
                    if
                        require('myconfig.utils.misc').string_starts_with(
                            start_path,
                            'diffview:'
                        )
                    then
                        -- vim.print('starts with diffview')
                        path = assert(vim.uv.cwd())
                    else
                        path = pattern_func(start_path)
                    end
                    if path == '.' or path == './' or path == '/.' then
                        path = assert(vim.uv.cwd())
                    end

                    local normalized_root_path = vim.fs.normalize(path)
                    if
                        require('myconfig.utils.path').is_directory(
                            normalized_root_path
                        )
                    then
                        return vim.fs.abspath(normalized_root_path)
                    end
                    return path
                end
            end
        end,
    },

    -- Virtual Environments
    -- select virtual environments
    -- - makes pyright and debugpy aware of the selected virtual environment
    -- - Select a virtual environment with `:VenvSelect`
    {
        'linux-cultist/venv-selector.nvim',
        lazy = true,
        ft = 'python',
        dependencies = {
            'neovim/nvim-lspconfig',
            'mfussenegger/nvim-dap',
            'mfussenegger/nvim-dap-python', --optional
            'nvim-telescope/telescope.nvim',
        },
        branch = 'main',
        config = function() require('venv-selector').setup({}) end,
        --My old setup but haven't retested since upgrading to this newer version
        -- config = function(_, _)
        --     require('venv-selector').setup({
        --         dap_enabled = true, -- makes the debugger work with venv
        --         name = { 'venv', '.venv' },
        --     })
        --     require('venv-selector').retrieve_from_cache()
        -- end,
    },

    -- LSP client extensions
    {
        'Hoffs/omnisharp-extended-lsp.nvim',
        lazy = true,
    },

    {
        'rachartier/tiny-code-action.nvim',
        lazy = true,
        dependencies = {
            { 'nvim-lua/plenary.nvim' },
            { 'nvim-telescope/telescope.nvim' },
        },
        config = function(_, opts) require('tiny-code-action').setup(opts) end,
    },
    -- Code Action Macros
    {
        'crwebb85/mark-code-action.nvim',
        lazy = true,
        event = 'BufReadPre',
        opts = {

            marks = {
                DisableDiagnostic = {
                    client_name = 'lua_ls',
                    kind = 'quickfix',
                    title = 'Disable diagnostics on this line (undefined-field).',
                },
                CleanImports = {
                    client_name = 'omnisharp',
                    kind = 'quickfix',
                    title = 'Remove unnecessary usings',
                },
            },
            lsp_timeout_ms = 10000,
        },
        config = true,
        -- dev = true,
    },

    ---------------------------------------------------------------------------
    --- Formatter

    -- Formatting client: conform.nvim
    -- - Formatting is triggered via `<leader>f`, but also automatically on save
    {
        'stevearc/conform.nvim',
        event = 'BufWritePre', -- load the plugin before saving
        keys = {
            {
                -- '<leader>f',
                'grf',
                function()
                    local params =
                        require('myconfig.formatter').construct_conform_formatting_params()
                    require('conform').format(params)
                end,
                mode = { 'n', 'x' },
                desc = 'Conform: Format buffer',
            },
        },
        init = function()
            vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
        end,
        config = function(_, _)
            ---@type conform.setupOpts
            local opts = {
                formatters_by_ft = {
                    lua = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    python = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    typescript = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    javascript = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    typescriptreact = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    javascriptreact = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    css = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    yaml = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    json = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    jsonc = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    json5 = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    ansible = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    --use `:set ft=yaml.ansible` to get treesitter highlights for yaml,
                    -- ansible lsp, and prettier formatting TODO set up autocmd to detect ansible
                    ['yaml.ansible'] = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    markdown = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    xml = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    graphql = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                    sh = require('myconfig.formatter').get_buffer_enabled_formatter_list,
                },
                formatters = {
                    ---@type conform.FileFormatterConfig
                    xmlformat = {
                        command = 'xmlformat',
                        args = { '--selfclose', '-' },
                    },
                    ---@type conform.FileFormatterConfig
                    prettierxml = {
                        command = 'npm',
                        args = {
                            '--silent',
                            'run',
                            'format',
                            '--stdin-filepath',
                            '$FILENAME',
                        },
                        cwd = function(_, _)
                            local config_env = os.getenv('XDG_CONFIG_HOME')
                            if config_env == nil then
                                error(
                                    'cannot find XDG_CONFIG_HOME environment variable'
                                )
                            end
                            local config_path = vim.fn.expand(config_env)

                            return vim.fs.joinpath(
                                config_path,
                                'cli-tools',
                                'prettier'
                            )
                        end,
                    },
                },
                -- enable format-on-save
                format_on_save = require('myconfig.formatter').format_on_save,
                format_after_save = require('myconfig.formatter').format_after_save,
            }
            require('conform').setup(opts)
            -- -- Set this value to true to silence errors when formatting a block fails
            -- require('conform.formatters.injected').options.ignore_errors = false
        end,
    },

    ---------------------------------------------------------------------------
    --- Task Runner

    { -- The task runner we use
        'stevearc/overseer.nvim',
        lazy = true,
        --Overseer claims to lazy load by default so Im just going to use
        --the VeryLazy event
        event = 'VeryLazy',
        keys = {
            {
                '<leader>oo',
                '<cmd>OverseerToggle!<CR>',
                mode = 'n',
                desc = 'Overseer: Toggle',
            },
            {
                '<leader>or',
                '<cmd>OverseerRun<CR>',
                mode = 'n',
                desc = 'Overseer: Run',
            },
            {
                '<leader>oc',
                '<cmd>OverseerRunCmd<CR>',
                mode = 'n',
                desc = 'Overseer: Run command',
            },
            {
                '<leader>oj',
                '<cmd>OverseerLoadBundle<CR>',
                mode = 'n',
                desc = 'Overseer: Load',
            },
            {
                '<leader>od',
                '<cmd>OverseerQuickAction<CR>',
                mode = 'n',
                desc = 'Overseer: Do quick action',
            },
            {
                '<leader>os',
                '<cmd>OverseerTaskAction<CR>',
                mode = 'n',
                desc = 'Overseer: Select task action',
            },
            {
                '<leader>ox',
                '<cmd>OverseerClearCache<CR>',
                mode = 'n',
                desc = 'Overseer: Clear Cache',
            },
            {
                '<leader>og',
                '<cmd>OverseerRestartLast<CR>',
                mode = 'n',
                desc = 'Overseer: Restart Last',
            },
            {
                '<leader>oq',
                '<cmd>OverseerQuickAction open output in quickfix<CR>',
                mode = 'n',
                desc = 'Overseer: put the diagnostics results into quickfix',
            },
            -- {
            --     '<leader>ow',
            --     '<cmd>OverseerQuickAction open output in loclist<CR>',
            --     mode = 'n',
            --     desc = 'Overseer: put the diagnostics results into loclist',
            -- },
        },
        opts = {
            strategy = config.use_overseer_strategy_hack
                    and {
                        --Old versions of windows/powershell won't emit all the characters needed
                        --to determine if the line feed at the end of the line was from the
                        --source program or from line wrapping. When that happens it becomes impossible
                        --to parse things like file paths from the terminal output. To fix this we
                        --disable fetching the output from the terminal.
                        --The trade off is we loose ansi color sequences so all output will display
                        --without color.
                        'jobstart',
                        use_terminal = false,
                    }
                or 'terminal',
            task_list = {
                direction = 'bottom',
                min_height = 25,
                max_height = 25,
                default_detail = 1,
            },
            templates = {
                'builtin',
                'hurl.hurl_run',
                'hurl.hurl_run_with_var_file',
                'user.run_script',
            },
            component_aliases = {
                default_neotest = {
                    {
                        'on_output_parse',
                        parser = {
                            diagnostics = {
                                {
                                    'extract',
                                    '^%s+at%s(.*)%sin%s(.+%.cs):line%s([0-9]+)%s*$',
                                    'message',
                                    'filename',
                                    'lnum',
                                },
                            },
                        },
                    },
                    'on_result_diagnostics',
                    --Im going to try out disabling on_result_diagnostics_quickfix
                    --since I can just OverseerQuickAction to add them to the quick fix list
                    -- {
                    --     'on_result_diagnostics_quickfix',
                    --     open = true,
                    -- },
                    'on_output_summarize',
                    'on_exit_set_status',
                    'on_complete_notify',
                    'on_complete_dispose',
                },
            },
        },
    },

    ---------------------------------------------------------------------------
    -- Import plugins defined in the plugins folder
    { import = 'plugins' },
}, {
    performance = {
        rtp = {
            disabled_plugins = {
                'netrwPlugin',
                -- etc.
            },
        },
    },
    dev = {
        -- Directory where you store your local plugin projects
        path = config.dev_plugins_path,
    },
})

vim.cmd.packadd('cfilter')
vim.cmd.packadd('nvim.difftool')
