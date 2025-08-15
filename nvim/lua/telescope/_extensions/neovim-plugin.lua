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
            local stat = vim.loop.fs_stat(lazy_path)
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

        live_grep = function(_)
            local data_path = vim.fn.stdpath('data')
            if data_path == nil then
                error('data path was nil but a string was expected')
            elseif type(data_path) == 'table' then
                error('data path was an array but a string was expected')
            end

            local lazy_path = vim.fs.joinpath(data_path, 'lazy')
            local stat = vim.loop.fs_stat(lazy_path)
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
