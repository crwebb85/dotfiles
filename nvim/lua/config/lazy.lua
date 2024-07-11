vim.g.mapleader = ' '
local shellslash_hack = require('utils.misc').shellslash_hack

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
                    '<leader>ggo',
                    actions.goto_file_tab,
                    {
                        desc = 'Diffview: Open the file in a new tabpage',
                    },
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
                '<leader>fa',
                function() require('telescope.builtin').autocommands() end,
                desc = 'Telescope: autocmds',
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
                    n = {
                        ['<C-b>'] = function(args)
                            require('telescope.actions').delete_buffer(args)
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
        'theprimeagen/harpoon',
        lazy = true,
        config = true,
        keys = {
            {
                '<leader>a',
                function() require('harpoon.mark').add_file() end,
                desc = 'Harpoon: Add file',
            },
            {
                '<C-e>',
                function() require('harpoon.ui').toggle_quick_menu() end,
                desc = 'Harpoon: Toggle quick menu',
            },
            -- Protip: To reorder the entries in harpoon quick menu use `Vd` to cut the line and `P` to paste where you want it

            -- Harpoon quick navigation
            {
                '<leader>1',
                function() require('harpoon.ui').nav_file(1) end,
                desc = 'Harpoon: Go to file 1',
            },
            {
                '<leader>2',
                function() require('harpoon.ui').nav_file(2) end,
                desc = 'Harpoon: Go to file 2',
            },
            {
                '<leader>3',
                function() require('harpoon.ui').nav_file(3) end,
                desc = 'Harpoon: Go to file 3',
            },
            {
                '<leader>4',
                function() require('harpoon.ui').nav_file(4) end,
                desc = 'Harpoon: Go to file 4',
            },
            {
                '<leader>5',
                function() require('harpoon.ui').nav_file(5) end,
                desc = 'Harpoon: Go to file 5',
            },
            {
                '<leader>6',
                function() require('harpoon.ui').nav_file(6) end,
                desc = 'Harpoon: Go to file 6',
            },
            {
                '<leader>7',
                function() require('harpoon.ui').nav_file(7) end,
                desc = 'Harpoon: Go to file 7',
            },
            {
                '<leader>8',
                function() require('harpoon.ui').nav_file(8) end,
                desc = 'Harpoon: Go to file 8',
            },
            {
                '<leader>9',
                function() require('harpoon.ui').nav_file(9) end,
                desc = 'Harpoon: Go to file 9',
            },
            {
                '<leader>0',
                function() require('harpoon.ui').nav_file(0) end,
                desc = 'Harpoon: Go to file 0',
            },
        },
    },

    {
        'stevearc/oil.nvim',
        lazy = true,
        keys = {
            {
                '<leader>ol',
                '<CMD>Oil<CR>',
                desc = 'Oil: Open parent directory',
            },
        },
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        opts = {
            default_file_explorer = true,
            delete_to_trash = true,
            -- watch the filesystem for changes and reload oil
            watch_for_changes = true,
            view_options = {
                show_hidden = true,
                is_always_hidden = function(name, _)
                    return name == '...' or name == '.git'
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
        dependencies = { 'echasnovski/mini.icons' },
        lazy = true,
        event = 'VeryLazy',
        opts = {
            style = 'glyph',
            -- style = 'ascii',
        },
        config = true,
    },

    --Big file speed increases (by disabling features)
    {
        'LunarVim/bigfile.nvim',
        lazy = true,
        event = 'VeryLazy',
        config = true,
    },

    --Global notes
    {
        'backdround/global-note.nvim',
        lazy = true,
        cmd = { 'GlobalNote' },
        config = true,
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
        opts = {
            operators = {
                gc = 'Comment: line comment',
                ys = 'Surround: Add a surrounding pair',
            },
        },
        config = true,
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
    -- Clipboard support (copy from vim to the outside world)
    {
        'ojroques/nvim-osc52',
        event = 'BufReadPre',
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

                        --[[                          ]]
                        goto_next_start = {
                            [']f'] = {
                                query = '@call.outer',
                                desc = 'Next function call start',
                            },
                            [']m'] = {
                                query = '@function.outer',
                                desc = 'Remap: Next method/function def start',
                            },
                            [']c'] = {
                                query = '@class.outer',
                                desc = 'Next class start',
                            },
                            [']i'] = {
                                query = '@conditional.outer',
                                desc = 'Next conditional start',
                            },
                            [']o'] = {
                                query = '@loop.outer',
                                desc = 'Next loop start',
                            },
                            [']va'] = '@parameter.inner',
                        },
                        goto_next_end = {
                            [']F'] = {
                                query = '@call.outer',
                                desc = 'Next function call end',
                            },
                            [']M'] = {
                                query = '@function.outer',
                                desc = 'Remap: Next method/function def end',
                            },
                            [']C'] = {
                                query = '@class.outer',
                                desc = 'Next class end',
                            },
                            [']I'] = {
                                query = '@conditional.outer',
                                desc = 'Next conditional end',
                            },
                            [']O'] = {
                                query = '@loop.outer',
                                desc = 'Next loop end',
                            },
                            [']vA'] = '@parameter.inner',
                        },
                        goto_previous_start = {
                            ['[f'] = {
                                query = '@call.outer',
                                desc = 'Prev function call start',
                            },
                            ['[m'] = {
                                query = '@function.outer',
                                desc = 'Prev method/function def start',
                            },
                            ['[c'] = {
                                query = '@class.outer',
                                desc = 'Prev class start',
                            },
                            ['[i'] = {
                                query = '@conditional.outer',
                                desc = 'Prev conditional start',
                            },
                            ['[o'] = {
                                query = '@loop.outer',
                                desc = 'Prev loop start',
                            },
                            ['[va'] = '@parameter.inner',
                        },
                        goto_previous_end = {
                            ['[F'] = {
                                query = '@call.outer',
                                desc = 'Prev function call end',
                            },
                            ['[M'] = {
                                query = '@function.outer',
                                desc = 'Prev method/function def end',
                            },
                            ['[C'] = {
                                query = '@class.outer',
                                desc = 'Prev class end',
                            },
                            ['[I'] = {
                                query = '@conditional.outer',
                                desc = 'Prev conditional end',
                            },
                            ['[O'] = {
                                query = '@loop.outer',
                                desc = 'Prev loop end',
                            },
                            ['[vA'] = '@parameter.inner',
                        },
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
    -- Parser for syntax highlighting
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
        end,
    },

    -----------------------------------------------------------------------------
    -- -- PYTHON REPL
    -- -- A basic REPL that opens up as a horizontal split
    -- -- - use `<leader>i` to toggle the REPL
    -- -- - use `<leader>I` to restart the REPL
    -- -- - `+` serves as the "send to REPL" operator. That means we can use `++`
    -- -- to send the current line to the REPL, and `+j` to send the current and the
    -- -- following line to the REPL, like we would do with other vim operators.
    -- {
    --     'Vigemus/iron.nvim',
    --     keys = {
    --         { '<leader>i', vim.cmd.IronRepl, desc = 'Iron: Toggle REPL' },
    --         { '<leader>I', vim.cmd.IronRestart, desc = 'Iron: Restart REPL' },
    --
    --         -- these keymaps need no right-hand-side, since that is defined by the
    --         -- plugin config further below
    --         { '+', mode = { 'n', 'x' }, desc = 'Iron: Send-to-REPL Operator' },
    --         { '++', desc = 'Iron: Send Line to REPL' },
    --     },
    --
    --     -- since irons's setup call is `require("iron.core").setup`, instead of
    --     -- `require("iron").setup` like other plugins would do, we need to tell
    --     -- lazy.nvim which module to via the `main` key
    --     main = 'iron.core',
    --
    --     opts = {
    --         keymaps = {
    --             send_line = '++',
    --             visual_send = '+',
    --             send_motion = '+',
    --         },
    --         config = {
    --             -- this defined how the repl is opened. Here we set the REPL window
    --             -- to open in a horizontal split to a bottom, with a height of 10
    --             -- cells.
    --             repl_open_cmd = 'horizontal bot 10 split',
    --
    --             -- This defines which binary to use for the REPL. If `ipython` is
    --             -- available, it will use `ipython`, otherwise it will use `python3`.
    --             -- since the python repl does not play well with indents, it's
    --             -- preferable to use `ipython` or `bypython` here.
    --             -- (see: https://github.com/Vigemus/iron.nvim/issues/348)
    --             repl_definition = {
    --                 python = {
    --                     command = function()
    --                         local ipythonAvailable = vim.fn.executable(
    --                             'ipython'
    --                         ) == 1
    --                         local binary = ipythonAvailable and 'ipython'
    --                             or 'python3'
    --                         return { binary }
    --                     end,
    --                 },
    --             },
    --         },
    --     },
    -- },

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
                '<leader>dc',
                function() require('dap').continue() end,
                desc = 'Debug: Start/Continue Debugger',
            },
            {
                '<leader>db',
                function() require('dap').toggle_breakpoint() end,
                desc = 'Debug: Add Breakpoint',
            },
            {
                '<leader>dt',
                function() require('dap').terminate() end,
                desc = 'Debug: Terminate Debugger',
            },
            {
                '<leader>dC',
                function() require('dap').run_to_cursor() end,
                desc = 'Debug: Run to Cursor',
            },
            {
                '<leader>dg',
                function() require('dap').goto_() end,
                desc = 'Debug: Go to line (no execute)',
            },
            {
                '<leader>di',
                function() require('dap').step_into() end,
                desc = 'Debug: Step Into',
            },
            {
                '<leader>dj',
                function() require('dap').down() end,
                desc = 'Debug: Down',
            },
            {
                '<leader>dk',
                function() require('dap').up() end,
                desc = 'Debug: Up',
            },
            {
                '<leader>dl',
                function() require('dap').run_last() end,
                desc = 'Debug: Run Last',
            },
            {
                '<leader>do',
                function() require('dap').step_out() end,
                desc = 'Debug: Step Out',
            },
            {
                '<leader>dO',
                function() require('dap').step_over() end,
                desc = 'Debug: Step Over',
            },
            {
                '<leader>dp',
                function() require('dap').pause() end,
                desc = 'Debug: Pause',
            },
            {
                '<leader>dr',
                function() require('dap').repl.toggle() end,
                desc = 'Debug: Toggle REPL',
            },
            {
                '<leader>ds',
                function() require('dap').session() end,
                desc = 'Debug: Session',
            },
            {
                '<leader>dw',
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
                '<leader>du',
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
                -- icons = {
                --     pause = '||',
                --     play = '|>',
                --     step_into = 'v',
                --     step_over = '>',
                --     step_out = '^',
                --     step_back = '<',
                --     run_last = 'rl',
                --     terminate = '|=|',
                --     disconnect = 'x',
                -- },
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
            require('mason-tool-installer').setup({
                ensure_installed = {
                    -- LSPs
                    'pyright', -- LSP for python
                    'ruff-lsp', -- linter for python (includes flake8, pep8, etc.)
                    'marksman',
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
                    'black', -- python formatter
                    'isort', -- python organize imports
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
                },
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
                    tsserver = lsp.setup_tsserver,
                    yamlls = lsp.setup_yamlls,
                    jsonls = lsp.setup_jsonls,
                    taplo = lsp.setup_tablo,
                    omnisharp = lsp.setup_omnisharp,
                    powershell_es = lsp.setup_powershell_es,
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
            -- {
            --     'hrsh7th/cmp-nvim-lua', -- Completion for lua api
            --     lazy = true,
            --     ft = 'lua',
            -- },
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
            'nvim-telescope/telescope.nvim',
            'mfussenegger/nvim-dap-python',
        },
        config = function(_, _)
            require('venv-selector').setup({
                dap_enabled = true, -- makes the debugger work with venv
                name = { 'venv', '.venv' },
            })
            require('venv-selector').retrieve_from_cache()
        end,
    },

    -- LSP client extensions
    {
        'Hoffs/omnisharp-extended-lsp.nvim',
        lazy = true,
    },

    -- Code Action preview
    {
        'aznhe21/actions-preview.nvim',
        lazy = true,
        config = true,
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
    -- - configured to use black & isort in python
    -- - use the taplo-LSP for formatting in toml
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
                desc = 'Conform: Format buffer',
            },
        },
        init = function()
            vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
        end,
        config = function(_, _)
            require('conform').setup({
                formatters_by_ft = {
                    lua = { 'stylua' },
                    -- first use isort and then black
                    python = { 'isort', 'black' },
                    typescript = { { 'prettierd', 'prettier' } },
                    javascript = { { 'prettierd', 'prettier' } },
                    typescriptreact = { { 'prettierd', 'prettier' } },
                    javascriptreact = { { 'prettierd', 'prettier' } },
                    css = { { 'prettierd', 'prettier' } },
                    yaml = { { 'prettierd', 'prettier' } },
                    json = { { 'prettierd', 'prettier' } },
                    jsonc = { { 'prettierd', 'prettier' } },
                    json5 = { { 'prettierd', 'prettier' } },
                    ansible = { { 'prettierd', 'prettier' } },
                    --use `:set ft=yaml.ansible` to get treesitter highlights for yaml,
                    -- ansible lsp, and prettier formatting TODO set up autocmd to detect ansible
                    ['yaml.ansible'] = { { 'prettierd', 'prettier' } },
                    -- "inject" is a "special" formatter from conform.nvim, which
                    -- formats treesitter-injected code. In effect, hits will make
                    -- conform.nvim format any python codeblocks inside a markdown file.
                    markdown = { { 'prettierd', 'prettier' }, 'injected' },
                    xml = { 'xmlformat' },
                    graphql = { { 'prettierd', 'prettier' } },
                    sh = { 'shfmt' },
                },
                formatters = {
                    xmlformat = {
                        command = 'xmlformat',
                        args = { '--selfclose', '-' },
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
    dev = {
        -- Directory where you store your local plugin projects
        path = 'C:\\Users\\crweb\\Documents\\projects\\',
    },
})

vim.cmd.packadd('cfilter')
