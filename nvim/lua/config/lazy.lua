vim.g.mapleader = ' '
local shellslash_hack = require('utils.misc').shellslash_hack
local config = require('config.config')

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

local M = {}
M.lazygitTerminal = nil
M.lazytoggle = function()
    local Terminal = require('toggleterm.terminal').Terminal
    if M.lazygitTerminal == nil then
        M.lazygitTerminal = Terminal:new({
            cmd = 'lazygit',
            dir = 'git_dir',
            direction = 'tab',
            float_opts = {
                border = 'double',
            },
            -- function to run on opening the terminal
            on_open = function(term)
                vim.cmd('startinsert!')
                vim.api.nvim_buf_set_keymap(
                    term.bufnr,
                    'n',
                    'q',
                    '<cmd>close<CR>',
                    { noremap = true, silent = true }
                )
            end,
            -- function to run on closing the terminal
            on_close = function(_) vim.cmd('startinsert!') end,
        })
    end

    M.lazygitTerminal:toggle()
end

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
                    { desc = 'Stage / unstage the selected entry' },
                },
                {
                    'n',
                    'q',
                    '<cmd>DiffviewClose<CR>',
                    { silent = true },
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
                    if next(require('diffview.lib').views) == nil then
                        require('diffview').open({})
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
                            .. require('utils.misc').get_default_branch_name()
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
                            .. require('utils.misc').get_default_branch_name()
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
                '<leader>gvw',
                function() require('gitsigns').toggle_word_diff() end,
                desc = 'Gitsigns: Toggle word diff',
            },

            -- Highlight added lines.
            {
                '<leader>gvl',
                function() require('gitsigns').toggle_linehl() end,
                desc = 'Gitsigns: Toggle line highlight',
            },

            -- Highlight removed lines.
            {
                '<leader>gvd',
                function() require('gitsigns').toggle_deleted() end,
                desc = 'Gitsigns: Toggle deleted (all)',
            },
            {
                '<leader>gvh',
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
            {
                'crwebb85/telescope-media-files.nvim',
                -- dev = true,
            },
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
                    vim.print(root_dir)
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
                function() require('telescope.builtin').grep_string() end,
                desc = 'Telescope: grep at cursor/selection',
                mode = { 'n', 'v' },
            },
            {
                '<leader>fg',
                function() require('telescope.builtin').live_grep() end,
                desc = 'Telescope: live_grep',
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
                    -- based on https://github.com/nvim-telescope/telescope.nvim/issues/1923#issuecomment-1122642431
                    local function getVisualSelection()
                        vim.cmd('noau normal! "vy"')
                        local text = vim.fn.getreg('v')
                        vim.fn.setreg('v', {})

                        if type(text) ~= 'string' then return '' end

                        text = string.gsub(text, '\n', '')
                        if #text > 0 then
                            return text
                        else
                            return ''
                        end
                    end

                    local text = getVisualSelection()
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
                '<leader>fe',
                function()
                    local conf = require('telescope.config').values
                    local harpoon = require('harpoon')

                    local file_paths = {}
                    for _, item in ipairs(harpoon:list().items) do
                        --Decode dynamic harpoon items based on current date
                        --for example "${test%Y-%m-%d.log}" would become "test2024-09-27.log"
                        --if todays date was 2024-09-27 this allows adding current days log file
                        --to the harpoon list without having to change it each day.
                        local list_item_value, _ = string.gsub(
                            item.value,
                            '^%${(.*)}$',
                            function(n) return os.date(n) end
                        )
                        table.insert(file_paths, list_item_value)
                    end

                    require('telescope.pickers')
                        .new({}, {
                            prompt_title = 'Harpoon',
                            finder = require('telescope.finders').new_table({
                                results = file_paths,
                            }),
                            previewer = conf.file_previewer({}),
                            sorter = conf.generic_sorter({}),
                            attach_mappings = function(buffer_number)
                                local actions = require('telescope.actions')
                                local action_state =
                                    require('telescope.actions.state')
                                actions.select_default:replace(function()
                                    actions.close(buffer_number)
                                    vim.cmd(
                                        'e '
                                            .. action_state.get_selected_entry()[1]
                                    )
                                end)
                                return true
                            end,
                        })
                        :find()
                end,
                desc = 'Telescope: harpoon',
            },

            {
                '<leader>fn',
                function()
                    local note_path = vim.fs.normalize('$MY_NOTES')
                    if note_path == '$MY_NOTES' then
                        error(
                            "$MY_NOTES environment variable is not defined. Please create the environment variable in order to search it's directory."
                        )
                    end
                    require('telescope.builtin').find_files({
                        cwd = note_path,
                    })
                end,
                desc = 'Telescope: find files in note directory ',
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
                                    require('config.bufdelete').bufdelete,
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
            extensions = {
                media_files = {
                    -- file types white list
                    -- defaults to {"png", "jpg", "mp4", "webm", "pdf"}
                    filetypes = { 'png', 'webp', 'jpg', 'jpeg' },
                    -- find command (defaults to `fd`)
                    find_cmd = 'rg',
                },
            },
        },
        config = function(_, opts)
            require('telescope').setup(opts)
            require('telescope').load_extension('media_files')
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
                        vim.api.nvim_buf_get_lines(0, row - 1, row, false)
                    local col = #row_text[1]

                    if list_item.context.col > col then
                        list_item.context.col = col
                        edited = true
                    end

                    vim.api.nvim_win_set_cursor(0, {
                        list_item.context.row or 1,
                        list_item.context.col or 0,
                    })

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
        'stevearc/oil.nvim',
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
                desc = 'OIl replacement for Netrw',
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
        dependencies = { 'echasnovski/mini.icons' },
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
                            require('utils.image_preview').preview_image(
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
                        local entry = require('oil').get_cursor_entry()

                        local dir = require('oil').get_current_dir()

                        if not entry or entry.type ~= 'file' or not dir then
                            return
                        end

                        local file_path = dir .. entry.name
                        local items = vim.fn.getqflist()
                        table.insert(items, {
                            text = file_path,
                            filename = file_path,
                            row = 0,
                            col = 0,
                            valid = 1,
                        })

                        vim.fn.setqflist({}, ' ', {
                            title = 'Oil Appended Files',
                            items = items,
                        })
                    end,
                },
            },
        },
        config = function(_, opts) require('oil').setup(opts) end,
    },

    -- File search and replace
    {
        'nvim-pack/nvim-spectre',
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        lazy = true,
        cmd = { 'Spectre' },
        opts = {},
        config = true,
        keys = {
            {
                '<leader>st',
                function() require('spectre').toggle() end,
                mode = { 'n' },
                desc = 'Spectre: Toggle Spectre',
            },
            {
                '<leader>sw',
                function()
                    require('spectre').open_visual({ select_word = true })
                end,
                mode = { 'n' },
                desc = 'Spectre: Search current word',
            },
            {
                '<leader>sw',
                function() require('spectre').open_visual() end,
                mode = { 'v' },
                desc = 'Spectre: Search current word',
            },
            {
                '<leader>sp',
                function()
                    require('spectre').open_file_search({ select_word = true })
                end,
                mode = { 'n' },
                desc = 'Spectre: Search on current file',
            },
        },
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

    -- Keymap suggestions
    {
        'folke/which-key.nvim',
        lazy = true,
        event = 'VeryLazy',
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
        end,
        opts = {},
        config = function(_, opts)
            local default_opts = {

                -- https://github.com/folke/which-key.nvim/issues/648#issuecomment-2226881346
                -- delay >= vim.o.timeoutlen for conflicting keymaps to work
                -- By work I mean
                -- keymap <leader>f should activate if <leader>f is quickly pressed
                -- but keymap <leader>ff should activate if the keys are pressed a bit slower
                -- I may need to adjust these numbers so the delays feel right but that is how to make it work
                -- with that said descriptions aren't necessary correct and it still
                -- doesn't behave exactly like it used to
                delay = vim.o.timeoutlen,
            }
            opts = vim.tbl_deep_extend('keep', opts, default_opts)
            require('which-key').setup(opts)

            local wk = require('which-key')
            -- Note don't forget to update this if I change the mapping namespaces
            wk.add({
                { '[', mode = { 'x' }, group = 'Prev node mappings' },
                { ']', mode = { 'x' }, group = 'Next node mappings' },
                { '[gc', mode = { 'x', 'n' }, group = 'Prev comment mappings' },
                { ']gc', mode = { 'x', 'n' }, group = 'Next comment mappings' },
                { '[h', mode = { 'x', 'n' }, group = 'Prev git hunk mappings' },
                { ']h', mode = { 'x', 'n' }, group = 'Next git hunk mappings' },
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
                    mode = { 'n' },
                    group = 'Debugger mappings',
                },
                {
                    '<leader>f',
                    mode = { 'n' },
                    group = 'Telescope mappings',
                },
                {
                    '<leader>g',
                    mode = { 'n' },
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
                    '<leader>gv',
                    mode = { 'n' },
                    group = 'Git signs/blame mappings',
                },
                {
                    '<leader>s',
                    mode = { 'n' },
                    group = 'Search (Spectre) mappings',
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
                    mode = { 'n' },
                    group = 'Multicursor mappings',
                },
                --
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

    -- Open terminal within neovim
    {
        'akinsho/toggleterm.nvim',
        lazy = true,
        cmd = { 'ToggleTerm' },
        keys = {
            {
                '<leader>tt',
                '<cmd>exe v:count1 . "ToggleTerm"<CR>',
                desc = 'Toggleterm: Toggle',
            },
            {

                [[<C-\>]],
                '<cmd>exe v:count1 . "ToggleTerm"<CR>',
                desc = 'ToggleTerm: Toggle',
                mode = { 'n', 'i' },
            },
            {
                '<leader>gs',
                function() M.lazytoggle() end,
                desc = 'LazyGit',
            },
        },
        config = function(_, opts) require('toggleterm').setup(opts) end,
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
            if require('utils.platform').is.win then
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
                require('utils.mapping').dot_repeat(
                    function() require('utils.mapping').flip_flop_comment() end
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
        -- branch = "1.0",
        lazy = true,
        event = 'BufReadPre',
        config = function()
            local mc = require('multicursor-nvim')

            mc.setup()

            -- Add cursors above/below the main cursor.
            vim.keymap.set(
                { 'n', 'v' },
                '<up>',
                function() mc.addCursor('k') end,
                { desc = 'Custom Multicursor: Add cursor above' }
            )
            vim.keymap.set(
                { 'n', 'v' },
                '<down>',
                function() mc.addCursor('j') end,
                { desc = 'Custom Multicursor: Add cursor below' }
            )

            -- Add a cursor and jump to the next word under cursor.
            vim.keymap.set(
                { 'n', 'v' },
                '<c-n>',
                function() mc.addCursor('*') end,
                {
                    desc = 'Custom Multicursor: Add cursor and jump to next word under cursor.',
                }
            )

            -- Jump to the next word under cursor but do not add a cursor.
            vim.keymap.set(
                { 'n', 'v' },
                '<c-s>',
                function() mc.skipCursor('*') end,
                {
                    desc = 'Custom Multicursor: Jump to next word under cursor but do not add a cursor.',
                }
            )

            -- Rotate the main cursor.
            vim.keymap.set(
                { 'n', 'v' },
                '<left>',
                mc.nextCursor,
                { desc = 'Custom Multicursor: Cycle main cursor left.' }
            )
            vim.keymap.set(
                { 'n', 'v' },
                '<right>',
                mc.prevCursor,
                { desc = 'Custom Multicursor: Cycle main cursor right.' }
            )

            -- Add and remove cursors with control + left click.
            vim.keymap.set(
                'n',
                '<c-leftmouse>',
                mc.handleMouse,
                { desc = 'Custom Multicursor: Add a cursor with the mouse.' }
            )

            vim.keymap.set({ 'n', 'v' }, '<c-q>', function()
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

            vim.keymap.set('n', '<esc>', function()
                if not mc.cursorsEnabled() then
                    mc.enableCursors()
                elseif mc.hasCursors() then
                    mc.clearCursors()
                else
                    -- Default <esc> handler.
                end
            end, {
                desc = 'Custom Multicursor: Re-enable multi cursors or clear cursors',
            })

            -- Delete the main cursor.
            vim.keymap.set(
                { 'n', 'v' },
                '<leader>wx',
                mc.deleteCursor,
                { desc = 'Custom Multicursor: Delete the main cursor.' }
            )

            -- Align cursor columns.
            vim.keymap.set(
                'n',
                '<leader>wa',
                mc.alignCursors,
                { desc = 'Custom Multicursor: Align cursor columns.' }
            )

            -- Split visual selections by regex.
            vim.keymap.set(
                'v',
                '<leader>ws',
                mc.splitCursors,
                { desc = 'Custom Multicursor: Split visual slection by regex' }
            )

            -- Append/insert for each line of visual selections.
            vim.keymap.set(
                'v',
                '<leader>wi', -- I don't use 'I' because it conflicts with visual block mode 'I'
                mc.insertVisual,
                {
                    desc = 'Custom Multicursor: Add cursor to beginning of each line of visual selection and enter insert mode with "I"',
                }
            )
            vim.keymap.set(
                'v',
                '<leader>wa', -- I don't use 'A' because it conflicts with visual block mode 'A'
                mc.appendVisual,
                {
                    desc = 'Custom Multicursor: Add cursor to end of each line of visual selection and enter insert mode with "A"',
                }
            )

            -- match new cursors within visual selections by regex.
            vim.keymap.set('v', '<leader>wm', mc.matchCursors, {
                desc = 'Custom Multicursor: Add new cursors to visual selection by regex.',
            })

            -- Rotate visual selection contents.
            vim.keymap.set(
                'v',
                '<leader>wt',
                function() mc.transposeCursors(1) end,
                { desc = 'Custom Multicursor: Transpose cursors' }
            )
            vim.keymap.set(
                'v',
                '<leader>wT',
                function() mc.transposeCursors(-1) end,
                { desc = 'Custom Multicursor: Transpose cursors (reverse)' }
            )

            -- Customize how cursors look.
            vim.api.nvim_set_hl(0, 'MultiCursorCursor', { link = 'Cursor' })
            vim.api.nvim_set_hl(0, 'MultiCursorVisual', { link = 'Visual' })
            vim.api.nvim_set_hl(
                0,
                'MultiCursorDisabledCursor',
                { link = 'Visual' }
            )
            vim.api.nvim_set_hl(
                0,
                'MultiCursorDisabledVisual',
                { link = 'Visual' }
            )
        end,
    },

    ---------------------------------------------------------------------------
    -- Treesitter Parsers and Parser Utils
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = true,
        event = 'VeryLazy',
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter.configs').setup({
                modules = {},
                -- A list of parser names, or "all"
                ensure_installed = {
                    'diff',
                    'javascript',
                    'typescript',
                    'tsx',
                    'css',
                    'json',
                    'jsonc',
                    'html',
                    'xml',
                    'yaml',
                    'c',
                    'lua',
                    'rust',
                    'vim',
                    'vimdoc',
                    'query',
                    'markdown',
                    'markdown_inline',
                    'python',
                    'toml',
                    'regex',
                    'c_sharp',
                },

                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,

                -- Automatically install missing parsers when entering buffer
                -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
                auto_install = true,

                -- List of parsers to ignore installing (or "all")
                ignore_install = {},

                ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
                -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

                highlight = {
                    enable = true,

                    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
                    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
                    -- Using this option may slow down your editor, and you may see some duplicate highlights.
                    -- Instead of true it can also be a list of languages
                    additional_vim_regex_highlighting = false,
                },
            })
            local query = [[
                (cast_expression
                  (
                    ("(") @start 
                    .
                    type: (predefined_type)  @cast.inner
                    .
                    ")" @end
                    (#make-range! "cast.outer" @start @end)
                    )
                  ) 
            ]]
            vim.treesitter.query.set(
                'c_sharp',
                config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP,
                query
            )
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
        config = function(_)
            local lang_utils = require('treesj.langs.utils')
            local opts = {
                use_default_keymaps = false,
                langs = {
                    c_sharp = {
                        argument_list = lang_utils.set_preset_for_args(),
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
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        lazy = true,
        event = 'BufReadPre',
        config = function(_, _)
            local opts = {
                textobjects = {
                    select = {
                        enable = true,

                        -- Automatically jump forward to textobj, similar to targets.vim
                        lookahead = true,

                        keymaps = {
                            -- You can also use captures from other query groups like `locals.scm`
                            -- ['as'] = {
                            --     query = '@scope',
                            --     query_group = 'locals',
                            --     desc = 'Select language scope',
                            -- },

                            ['a='] = {
                                query = '@assignment.outer',
                                desc = 'Select outer part of an assignment',
                            },
                            ['i='] = {
                                query = '@assignment.inner',
                                desc = 'Select inner part of an assignment',
                            },
                            ['il='] = {
                                query = '@assignment.lhs',
                                desc = 'Select left hand side of an assignment',
                            },
                            ['ir='] = {
                                query = '@assignment.rhs',
                                desc = 'Select right hand side of an assignment',
                            },

                            ['aa'] = {
                                query = '@parameter.outer',
                                desc = 'Select outer part of a parameter/argument',
                            },
                            ['ia'] = {
                                query = '@parameter.inner',
                                desc = 'Select inner part of a parameter/argument',
                            },

                            ['ai'] = {
                                query = '@conditional.outer',
                                desc = 'Select outer part of a conditional',
                            },
                            ['ii'] = {
                                query = '@conditional.inner',
                                desc = 'Select inner part of a conditional',
                            },

                            ['ao'] = {
                                query = '@loop.outer',
                                desc = 'Select outer part of a loop',
                            },
                            ['io'] = {
                                query = '@loop.inner',
                                desc = 'Select inner part of a loop',
                            },

                            ['af'] = {
                                query = '@call.outer',
                                desc = 'Select outer part of a function call',
                            },
                            ['if'] = {
                                query = '@call.inner',
                                desc = 'Select inner part of a function call',
                            },

                            ['am'] = {
                                query = '@function.outer',
                                desc = 'Select outer part of a method/function definition',
                            },
                            ['im'] = {
                                query = '@function.inner',
                                desc = 'Select inner part of a method/function definition',
                            },

                            ['ac'] = {
                                query = '@class.outer',
                                desc = 'Select outer part of a class',
                            },
                            ['ic'] = {
                                query = '@class.inner',
                                desc = 'Select inner part of a class',
                            },
                            ['a<leader>c'] = {
                                -- I plan to replace this with a smarter version of the keymap
                                query = '@comment.outer',
                                desc = 'Select outer part of a comment',
                            },
                            ['i<leader>c'] = {
                                -- I plan to replace this with a smarter version of the keymap
                                query = '@comment.inner',
                                desc = 'Select inner part of a comment',
                            },
                            ['agt'] = {
                                query = '@cast.outer',
                                query_group = config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP,
                                desc = 'Select outer part of a type cast',
                            },
                            ['igt'] = {
                                query = '@cast.inner',
                                query_group = config.MY_CUSTOM_TREESITTER_TEXTOBJECT_GROUP,
                                desc = 'Select inner part of a type cast',
                            },
                        },
                        -- You can choose the select mode (default is charwise 'v')
                        --
                        -- Can also be a function which gets passed a table with the keys
                        -- * query_string: eg '@function.inner'
                        -- * method: eg 'v' or 'o'
                        -- and should return the mode ('v', 'V', or '<c-v>') or a table
                        -- mapping query_strings to modes.
                        selection_modes = {
                            -- ['@parameter.outer'] = 'v', -- charwise
                            -- ['@function.outer'] = 'V', -- linewise
                            -- ['@class.outer'] = '<c-v>', -- blockwise
                        },
                        -- If you set this to `true` (default is `false`) then any textobject is
                        -- extended to include preceding or succeeding whitespace. Succeeding
                        -- whitespace has priority in order to act similarly to eg the built-in
                        -- `ap`.
                        --
                        -- Can also be a function which gets passed a table with the keys
                        -- * query_string: eg '@function.inner'
                        -- * selection_mode: eg 'v'
                        -- and should return true or false
                        -- include_surrounding_whitespace = true,
                    },
                    swap = {
                        enable = true,
                        swap_next = {
                            ['<leader>vna'] = '@parameter.inner',
                            ['<leader>vn:'] = '@property.outer', -- swap object property with next
                            ['<leader>vnm'] = '@function.outer', -- swap function with next
                        },
                        swap_previous = {
                            ['<leader>vpa'] = '@parameter.inner',
                            ['<leader>vp:'] = '@property.outer', -- swap object property with next
                            ['<leader>vpm'] = '@function.outer', -- swap function with previous
                        },
                    },
                    move = {
                        enable = true,
                        set_jumps = true, -- whether to set jumps in the jumplist
                        --I setup the move keymaps up manually in my keymaps.lua file
                    },
                },
            }
            require('nvim-treesitter.configs').setup(opts)
        end,
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
            --adapters
            'rouge8/neotest-rust',
            'nvim-neotest/neotest-python',
            {
                'Issafalcon/neotest-dotnet',
                -- dev = true
            },
        },
        lazy = true,
        cmd = 'Neotest',
        keys = {
            {
                '<leader>tr',
                function() require('neotest').run.run() end,
                desc = 'Neotest: Run the nearest test',
            },
            {
                '<leader>tc',
                function() require('neotest').run.run(vim.fn.expand('%')) end,
                desc = 'Neotest: Run the current file',
            },
            {
                '<leader>td',
                function()
                    shellslash_hack()
                    require('neotest').run.run({ strategy = 'dap' })
                end,
                desc = 'Neotest: Debug the nearest test',
            },
            {
                '<leader>ts',
                function() require('neotest').run.stop() end,
                desc = 'Neotest: Stop the nearest test',
            },
            {
                '<leader>ta',
                function() require('neotest').run.attach() end,
                desc = 'Neotest: Attach to the nearest test',
            },
        },
        config = function(_, _)
            require('neotest').setup({
                adapters = {
                    require('neotest-python')({
                        dap = { justMyCode = false },
                    }),
                    require('neotest-rust')({
                        -- args = { '--no-capture' },
                        -- dap_adapter = 'lldb',
                    }),
                    require('neotest-dotnet')({
                        dap = {
                            -- Extra arguments for nvim-dap configuration
                            -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
                            args = { justMyCode = false },
                            -- Enter the name of your dap adapter, the default value is netcoredbg
                            adapter_name = 'netcoredbg',
                        },
                        -- Let the test-discovery know about your custom attributes (otherwise tests will not be picked up)
                        -- Note: Only custom attributes for non-parameterized tests should be added here. See the support note about parameterized tests
                        -- custom_attributes = {
                        --     xunit = { 'MyCustomFactAttribute' },
                        --     nunit = { 'MyCustomTestAttribute' },
                        --     mstest = { 'MyCustomTestMethodAttribute' },
                        -- },
                        -- Provide any additional "dotnet test" CLI commands here. These will be applied to ALL test runs performed via neotest. These need to be a table of strings, ideally with one key-value pair per item.
                        -- dotnet_additional_args = {
                        --     '--verbosity detailed',
                        -- },
                        -- Tell neotest-dotnet to use either solution (requires .sln file) or project (requires .csproj or .fsproj file) as project root
                        -- Note: If neovim is opened from the solution root, using the 'project' setting may sometimes find all nested projects, however,
                        --       to locate all test projects in the solution more reliably (if a .sln file is present) then 'solution' is better.
                        -- discovery_root = 'project', -- Default
                        discovery_root = 'solution',
                    }),
                },
            })
        end,
    },

    ---------------------------------------------------------------------------
    -- DEBUGGING

    -- DAP Client for nvim
    {
        'mfussenegger/nvim-dap',
        lazy = true,
        config = function(_, _)
            local dap = require('dap')

            --Adapters
            dap.adapters.codelldb = {
                type = 'server',
                port = '${port}',
                executable = {
                    command = require('utils.path').get_mason_tool_path(
                        'codelldb'
                    ),
                    -- command = vim.fn.stdpath('data') .. '/mason/bin/codelldb',
                    args = { '--port', '${port}' },

                    -- On windows you may have to uncomment this:
                    -- detached = false,
                },
            }
            dap.adapters.executable = {
                type = 'executable',
                command = require('utils.path').get_mason_tool_path('codelldb'),
                -- command = vim.fn.stdpath('data') .. '/mason/bin/codelldb',
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
            --

            --- I was having problems with using the cmd file mason creates when installing netcoredbg on windows
            --- where using the cmd file for debugging wouldn't work. Instead I had to use the exe file directly
            ---@return string
            local function get_mason_tool_netcoredbg_path()
                local data_path = vim.fn.stdpath('data')
                if data_path == nil then
                    error('data path was nil but a string was expected')
                elseif type(data_path) == 'table' then
                    error('data path was an array but a string was expected')
                end

                if require('utils.platform').is.win then
                    return require('utils.path').concat({
                        data_path,
                        'mason',
                        'packages',
                        'netcoredbg',
                        'netcoredbg',
                        'netcoredbg.exe',
                    })
                else
                    return require('utils.path').get_mason_tool_path(
                        'netcoredbg'
                    )
                end
            end

            dap.adapters.coreclr = {
                type = 'executable',
                command = get_mason_tool_netcoredbg_path(),
                -- command = require('utils.path').get_mason_tool_path(
                --     'netcoredbg'
                -- ),
                args = { '--interpreter=vscode' },
                options = {
                    --https://github.com/Wiebesiek/ZeoVim
                    detached = false, -- Will put the output in the REPL. #CloseEnough
                },
            }

            -- Neotest Test runner looks at this table
            dap.adapters.netcoredbg = {
                type = 'executable',
                command = get_mason_tool_netcoredbg_path(),
                args = { '--interpreter=vscode' },
                options = {
                    --https://github.com/Wiebesiek/ZeoVim
                    detached = false, -- Will put the output in the REPL. #CloseEnough
                },
            }

            --configurations
            dap.configurations.rust = {
                {
                    name = 'Launch file',
                    type = 'codelldb',
                    request = 'launch',
                    program = function()
                        return vim.fn.input(
                            'Path to executable: ',
                            vim.fn.getcwd() .. '/',
                            'file'
                        )
                    end,
                    cwd = '${workspaceFolder}',
                    stopOnEntry = false,
                },
            }
            local dotnet_build_project = function()
                local default_path = vim.fn.getcwd() .. '/'
                if vim.g['dotnet_last_proj_path'] ~= nil then
                    default_path = vim.g['dotnet_last_proj_path']
                end
                local path = vim.fn.input(
                    'Path to your *proj file',
                    default_path,
                    'file'
                )
                vim.g['dotnet_last_proj_path'] = path
                local cmd = 'dotnet build -c Debug ' .. path .. ' > /dev/null'
                print('')
                print('Cmd to execute: ' .. cmd)
                local f = os.execute(cmd)
                if f == 0 then
                    print('\nBuild: ✔️ ')
                else
                    print('\nBuild: ❌ (code: ' .. f .. ')')
                end
            end

            local dotnet_get_dll_path = function()
                local request = function()
                    return vim.fn.input(
                        'Path to dll',
                        vim.fn.getcwd() .. '/bin/Debug/',
                        'file'
                    )
                end

                if vim.g['dotnet_last_dll_path'] == nil then
                    vim.g['dotnet_last_dll_path'] = request()
                else
                    if
                        vim.fn.confirm(
                            'Do you want to change the path to dll?\n'
                                .. vim.g['dotnet_last_dll_path'],
                            '&yes\n&no',
                            2
                        ) == 1
                    then
                        vim.g['dotnet_last_dll_path'] = request()
                    end
                end

                return vim.g['dotnet_last_dll_path']
            end

            dap.configurations.cs = {
                {
                    type = 'coreclr',
                    name = 'build and launch - netcoredbg',
                    request = 'launch',
                    program = function()
                        shellslash_hack()
                        if
                            vim.fn.confirm(
                                'Should I recompile first?',
                                '&yes\n&no',
                                2
                            ) == 1
                        then
                            dotnet_build_project()
                        end
                        return dotnet_get_dll_path()
                    end,
                },
                {
                    type = 'coreclr',
                    name = 'launch via telescope - netcoredbg',
                    request = 'launch',
                    console = 'integratedTerminal',
                    program = function()
                        shellslash_hack()
                        local pickers = require('telescope.pickers')
                        local finders = require('telescope.finders')
                        local conf = require('telescope.config').values
                        local actions = require('telescope.actions')
                        local action_state = require('telescope.actions.state')
                        return coroutine.create(function(coro)
                            local opts = {}
                            pickers
                                .new(opts, {
                                    prompt_title = 'Path to executable/dll',
                                    finder = finders.new_oneshot_job({
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
                                    }, {}),
                                    sorter = conf.generic_sorter(opts),
                                    attach_mappings = function(buffer_number)
                                        actions.select_default:replace(
                                            function()
                                                actions.close(buffer_number)
                                                coroutine.resume(
                                                    coro,
                                                    action_state.get_selected_entry()[1]
                                                )
                                            end
                                        )
                                        return true
                                    end,
                                })
                                :find()
                        end)
                    end,
                },
                {
                    type = 'coreclr',
                    name = 'launch via input - netcoredbg',
                    request = 'launch',
                    program = function()
                        shellslash_hack()
                        return vim.fn.input(
                            'Path to dll',
                            vim.fn.getcwd() .. '/bin/Debug/',
                            'file'
                        )
                    end,
                },
                {
                    type = 'coreclr',
                    name = 'attach - netcoredbg',
                    request = 'attach',
                    processId = require('dap.utils').pick_process,
                },
                --TODO - possibly useful snippet https://www.reddit.com/r/csharp/comments/15ktebq/comment/ks2dvb0/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
                -- local dir = vim.loop.cwd() .. '/' .. vim.fn.glob 'bin/Debug/net*/linux-x64/'
                -- local name = dir .. vim.fn.glob('*.csproj'):gsub('%.csproj$', '.dll')
                -- if not exists(name) then os.execute 'dotnet build -r linux-x64' end
                -- return name

                -- {
                --     type = 'coreclr',
                --     name = 'launch - netcoredbg',
                --     request = 'launch',
                --     env = 'ASPNETCORE_ENVIRONMENT=Development',
                --     args = {
                --         '/p:EnvironmentName=Development', -- this is a msbuild jk
                --         --  this is set via environment variable ASPNETCORE_ENVIRONMENT=Development
                --         '--urls=http://localhost:5002',
                --         '--environment=Development',
                --     },
                --     program = function()
                --         local get_root_dir = function ()
                --             vim.fn.getcwd()
                --         end
                --         -- return vim.fn.getcwd() .. "/bin/Debug/net8.0/FlareHotspotServer.dll"
                --         local files = ls_dir(get_root_dir() .. '/bin/Debug/')
                --         if #files == 1 then
                --             local dotnet_dir = get_root_dir()
                --                 .. '/bin/Debug/'
                --                 .. files[1]
                --             files = ls_dir(dotnet_dir)
                --             for _, file in ipairs(files) do
                --                 if file:match('.*%.dll') then
                --                     return dotnet_dir .. '/' .. file
                --                 end
                --             end
                --         end
                --         return vim.fn.input({
                --             prompt = 'Path to dll',
                --             default = get_root_dir() .. '/bin/Debug/',
                --         })
                --     end,
                -- },
            }

            dap.configurations.fsharp = {
                {
                    type = 'coreclr',
                    name = 'launch - netcoredbg',
                    request = 'launch',
                    program = function()
                        if
                            vim.fn.confirm(
                                'Should I recompile first?',
                                '&yes\n&no',
                                2
                            ) == 1
                        then
                            dotnet_build_project()
                        end
                        return dotnet_get_dll_path()
                    end,
                },
            }
        end,
        keys = {
            {
                '<leader>xc',
                function() require('dap').continue() end,
                desc = 'Debug: Start/Continue Debugger',
            },
            {
                '<leader>xb',
                function() require('dap').toggle_breakpoint() end,
                desc = 'Debug: Add Breakpoint',
            },
            {
                '<leader>xt',
                function() require('dap').terminate() end,
                desc = 'Debug: Terminate Debugger',
            },
            {
                '<leader>xC',
                function() require('dap').run_to_cursor() end,
                desc = 'Debug: Run to Cursor',
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
                '<leader>xw',
                function() require('dap.ui.widgets').hover() end,
                desc = 'Debug: Widgets',
            },
        },
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
        },
        opts = {
            controls = {
                icons = {
                    pause = '',
                    play = '',
                    step_into = '',
                    step_over = '',
                    step_out = '',
                    step_back = '',
                    run_last = '',
                    terminate = '',
                    disconnect = '',
                },
            },
        },
        -- automatically open/close the DAP UI when starting/stopping the debugger
        config = function(_, opts)
            if not config.nerd_font_enabled then
                opts.controls.icons = {
                    pause = '||',
                    play = '|>',
                    step_into = 'v',
                    step_over = '>',
                    step_out = '^',
                    step_back = '<',
                    run_last = 'rl',
                    terminate = '|=|',
                    disconnect = 'x',
                }
            end
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
            local debugpyPythonPath = require('mason-registry')
                .get_package('debugpy')
                :get_install_path() .. '/venv/bin/python3'
            require('dap-python').setup(debugpyPythonPath, {})
        end,
    },

    ---------------------------------------------------------------------------
    --- LSP's and more

    {
        'folke/lazydev.nvim',
        ft = 'lua', -- only load on lua files
        opts = {
            library = {
                { path = 'wezterm-types', mods = { 'wezterm' } },
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = 'luvit-meta/library', words = { 'vim%.uv' } },
            },
        },
    },
    { 'Bilal2453/luvit-meta', lazy = true }, -- optional `vim.uv` lua typings
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

    -- Manager for external tools (LSPs, linters, debuggers, formatters)
    -- auto-install of those external tools
    {
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        lazy = true,
        event = 'VeryLazy',
        dependencies = {
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },
        },
        config = function(_, _)
            local Set = require('utils.datastructure').Set

            local ensure_installed = Set:new({
                -- LSPs
                'pyright', -- LSP for python
                'ruff-lsp', -- linter for python (includes flake8, pep8, etc.)
                'marksman', -- Markdown
                'markdown-oxide', -- Markdown notes
                'lua-language-server', -- (lua_ls) LSP for lua files
                'typescript-language-server', -- tsserver LSP (keywords: typescript, javascript)
                'eslint-lsp', -- eslint Linter (implemented as a standalone lsp to improve speed)(keywords: javascript, typescript)
                'ansible-language-server',
                'omnisharp', -- C#
                'gopls', -- go lang
                'rust-analyzer',
                'yamlls', -- (yaml-language-server)
                'jsonls', -- (json-lsp)
                'taplo', -- LSP for toml (for pyproject.toml files)
                'powershell-editor-services', -- powershell

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
            })
                :difference(Set:new(config.exclude_mason_install))
                :to_array()

            require('mason-tool-installer').setup({
                ensure_installed = ensure_installed,
            })
            require('mason-tool-installer').run_on_start() -- Fix Issue: https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim/issues/37
        end,
    },

    {
        'williamboman/mason.nvim',
        lazy = true,
        config = true,
    },
    {
        'williamboman/mason-lspconfig.nvim',
        lazy = true,
        config = function()
            local lsp = require('config.lsp.lsp')
            require('mason-lspconfig').setup({
                handlers = {
                    --my handler requires neovim/lspconfig and hrsh7th/cmp-nvim-lsp
                    --so those dependencies will get lazily loaded when the lsp attaches
                    --if they haven't already been loaded
                    lsp.default_lsp_server_setup,
                    lua_ls = lsp.setup_lua_ls,
                    pyright = lsp.setup_pyright,
                    ts_ls = lsp.setup_tsserver,
                    yamlls = lsp.setup_yamlls,
                    jsonls = lsp.setup_jsonls,
                    taplo = lsp.setup_tablo,
                    omnisharp = lsp.setup_omnisharp,
                    powershell_es = lsp.setup_powershell_es,
                    markdown_oxide = lsp.setup_markdown_oxide,
                    marksman = lsp.setup_marksman,
                },
            })
        end,
    },

    {
        'neovim/nvim-lspconfig',
        lazy = true,
        dependencies = {
            {
                -- cmp-nvim-lsp provides a list of lsp capabilities to that cmp adds to neovim
                -- I must have cmp-nvim-lsp load before nvim-lspconfig for
                -- lua snips to show up in cmp
                'hrsh7th/cmp-nvim-lsp',
            },
        },
    },

    -- Auto completion
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
            { 'hrsh7th/cmp-nvim-lsp' }, -- Provides a list of lsp capabilities to that cmp adds to neovim
            { 'hrsh7th/cmp-nvim-lsp-signature-help' }, -- Provides signature info while typing function parameters
            { 'onsails/lspkind.nvim' }, -- Helps format the cmp selection items
            {
                'petertriho/cmp-git', -- Provides info about git repo
                lazy = true,
                ft = 'gitcommit',
                dependencies = { 'nvim-lua/plenary.nvim' },
            },
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

            local buffer_mappings = {
                ['<Down>'] = {
                    i = cmp.mapping.select_next_item({
                        behavior = 'select',
                    }),
                },
                ['<Up>'] = {
                    i = cmp.mapping.select_prev_item({
                        behavior = 'select',
                    }),
                },
                --Toggle showing completion menu
                ['<C-e>'] = cmp.mapping({
                    i = function()
                        if cmp.visible() then
                            cmp.abort()
                        else
                            cmp.complete()
                        end
                    end,
                }),
                -- `Enter` key to confirm completion
                ['<CR>'] = cmp.mapping({
                    i = function(fallback)
                        if cmp.visible() and cmp.get_active_entry() then
                            ---setting the undolevels creates a new undo break
                            ---so by setting it to itself I can create an undo break
                            ---without side effects just before a comfirming a completion.
                            -- Use <c-u> in insert mode to undo the completion
                            vim.cmd([[let &g:undolevels = &g:undolevels]])
                            cmp.confirm({
                                behavior = cmp.ConfirmBehavior.Insert,
                                select = false,
                            })
                        else
                            fallback()
                        end
                    end,
                }),
                ['<c-y>'] = cmp.mapping({
                    i = function(fallback)
                        if cmp.visible() and cmp.get_active_entry() then
                            ---setting the undolevels creates a new undo break
                            ---so by setting it to itself I can create an undo break
                            ---without side effects just before a comfirming a completion.
                            -- Use <c-u> in insert mode to undo the completion
                            vim.cmd([[let &g:undolevels = &g:undolevels]])
                            cmp.confirm({
                                behavior = cmp.ConfirmBehavior.Replace,
                                select = false,
                            })
                        else
                            fallback()
                        end
                    end,
                }),
                ['<C-t>'] = cmp.mapping(function()
                    if cmp.visible_docs() then
                        cmp.close_docs()
                    else
                        cmp.open_docs()
                    end
                end, { 'i', 's' }),
                -- Scroll up and down in the completion documentation
                ['<C-u>'] = cmp.mapping(function(falback)
                    if cmp.visible() then
                        cmp.mapping.scroll_docs(-4)
                    else
                        falback()
                    end
                end, { 'i', 's' }),
                ['<C-d>'] = cmp.mapping(function(falback)
                    if cmp.visible() then
                        cmp.mapping.scroll_docs(4)
                    else
                        falback()
                    end
                end, { 'i', 's' }),
                ['<C-n>'] = cmp.mapping(function(fallback)
                    local luasnip = require('luasnip')
                    if luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, { 'i', 's' }),

                ['<C-p>'] = cmp.mapping(function(fallback)
                    local luasnip = require('luasnip')

                    if luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
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
                mapping = buffer_mappings,
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

    -- Snippets
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
                local luasnip_path = require('utils.path').concat({
                    config_path,
                    'LuaSnip/',
                })
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
        branch = 'regexp', -- This is the regexp branch, use this for the new version
        config = function() require('venv-selector').setup() end,
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

    -- Code Action preview
    -- {
    --     'aznhe21/actions-preview.nvim',
    --     lazy = true,
    --     config = true,
    -- },
    {
        'rachartier/tiny-code-action.nvim',
        lazy = true,
        dependencies = {
            { 'nvim-lua/plenary.nvim' },
            { 'nvim-telescope/telescope.nvim' },
        },
        -- event = 'LspAttach',
        config = function() require('tiny-code-action').setup() end,
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
                        require('config.formatter').construct_conform_formatting_params()
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
            require('conform').setup({
                formatters_by_ft = {
                    lua = require('config.formatter').get_buffer_enabled_formatter_list,
                    python = require('config.formatter').get_buffer_enabled_formatter_list,
                    typescript = require('config.formatter').get_buffer_enabled_formatter_list,
                    javascript = require('config.formatter').get_buffer_enabled_formatter_list,
                    typescriptreact = require('config.formatter').get_buffer_enabled_formatter_list,
                    javascriptreact = require('config.formatter').get_buffer_enabled_formatter_list,
                    css = require('config.formatter').get_buffer_enabled_formatter_list,
                    yaml = require('config.formatter').get_buffer_enabled_formatter_list,
                    json = require('config.formatter').get_buffer_enabled_formatter_list,
                    jsonc = require('config.formatter').get_buffer_enabled_formatter_list,
                    json5 = require('config.formatter').get_buffer_enabled_formatter_list,
                    ansible = require('config.formatter').get_buffer_enabled_formatter_list,
                    --use `:set ft=yaml.ansible` to get treesitter highlights for yaml,
                    -- ansible lsp, and prettier formatting TODO set up autocmd to detect ansible
                    ['yaml.ansible'] = require('config.formatter').get_buffer_enabled_formatter_list,
                    markdown = require('config.formatter').get_buffer_enabled_formatter_list,
                    xml = require('config.formatter').get_buffer_enabled_formatter_list,
                    graphql = require('config.formatter').get_buffer_enabled_formatter_list,
                    sh = require('config.formatter').get_buffer_enabled_formatter_list,
                },
                formatters = {
                    xmlformat = {
                        command = 'xmlformat',
                        args = { '--selfclose', '-' },
                    },
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

                            return require('utils.path').concat({
                                config_path,
                                'cli-tools',
                                'prettier',
                            })
                        end,
                    },
                },
                -- enable format-on-save
                format_on_save = require('config.formatter').format_on_save,
                format_after_save = require('config.formatter').format_after_save,
            })
            -- -- Set this value to true to silence errors when formatting a block fails
            -- require('conform.formatters.injected').options.ignore_errors = false
        end,
    },

    ---------------------------------------------------------------------------
    --- Task Runner

    { -- The task runner we use
        'stevearc/overseer.nvim',
        lazy = true,
        cmd = {
            'OverseerOpen',
            'OverseerClose',
            'OverseerToggle',
            'OverseerSaveBundle',
            'OverseerLoadBundle',
            'OverseerDeleteBundle',
            'OverseerRunCmd',
            'OverseerRun',
            'OverseerInfo',
            'OverseerBuild',
            'OverseerQuickAction',
            'OverseerTaskAction',
            'OverseerClearCache',
        },
        opts = {
            task_list = {
                direction = 'bottom',
                min_height = 25,
                max_height = 25,
                default_detail = 1,
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
        path = 'C:\\Users\\crweb\\Documents\\projects\\',
    },
})

vim.cmd.packadd('cfilter')
