return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        find_files = function(_)
            local data_path = vim.fn.stdpath('data')
            if data_path == nil then
                error('data path was nil but a string was expected')
            elseif type(data_path) == 'table' then
                error('data path was an array but a string was expected')
            end

            local lazy_path = vim.fs.joinpath(data_path, 'lazy')
            local stat = vim.uv.fs_stat(lazy_path)
            if stat and stat.type ~= 'directory' then
                local template =
                    "Path %s already exists and it's not a directory!"
                error(template:format(lazy_path))
            end

            require('telescope.builtin').find_files({
                cwd = lazy_path,
                prompt_title = 'Find Files (neovim plugin)',
            })
        end,
        find_plugin_dir = function(_)
            local conf = require('telescope.config').values

            local data_path = vim.fn.stdpath('data')
            if data_path == nil then
                error('data path was nil but a string was expected')
            elseif type(data_path) == 'table' then
                error('data path was an array but a string was expected')
            end

            local lazy_path = vim.fs.joinpath(data_path, 'lazy')
            local stat = vim.uv.fs_stat(lazy_path)
            if stat and stat.type ~= 'directory' then
                local template =
                    "Path %s already exists and it's not a directory!"
                error(template:format(lazy_path))
            end

            local plugin_paths = {}
            for name, type in vim.fs.dir(lazy_path, { depth = 1 }) do
                if type == 'directory' then
                    local plugin_path = vim.fs.joinpath(lazy_path, name)
                    table.insert(plugin_paths, plugin_path)
                end
            end

            require('telescope.pickers')
                .new({}, {
                    prompt_title = 'Plugin Directories',
                    finder = require('telescope.finders').new_table({
                        results = plugin_paths,
                    }),
                    sorter = conf.generic_sorter({}),
                    attach_mappings = function(buffer_number)
                        local actions = require('telescope.actions')
                        local action_state = require('telescope.actions.state')
                        actions.select_default:replace(function()
                            actions.close(buffer_number)
                            vim.cmd(
                                'e ' .. action_state.get_selected_entry()[1]
                            )
                        end)
                        return true
                    end,
                })
                :find()
        end,

        live_grep = function(_)
            local data_path = vim.fn.stdpath('data')
            if data_path == nil then
                error('data path was nil but a string was expected')
            elseif type(data_path) == 'table' then
                error('data path was an array but a string was expected')
            end

            local lazy_path = vim.fs.joinpath(data_path, 'lazy')
            local stat = vim.uv.fs_stat(lazy_path)
            if stat and stat.type ~= 'directory' then
                local template =
                    "Path %s already exists and it's not a directory!"
                error(template:format(lazy_path))
            end

            require('telescope.builtin').live_grep({
                cwd = lazy_path,
                prompt_title = 'Live Grep (neovim plugin)',
            })
        end,
    },
})
