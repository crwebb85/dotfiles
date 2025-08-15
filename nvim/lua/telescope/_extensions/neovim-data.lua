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

            local stat = vim.loop.fs_stat(data_path)
            if stat and stat.type ~= 'directory' then
                local template =
                    "Path %s already exists and it's not a directory!"
                error(template:format(data_path))
            end

            require('telescope.builtin').find_files({
                cwd = data_path,
                prompt_title = 'Find Files (neovim data)',
            })
        end,

        live_grep = function(_)
            local data_path = vim.fn.stdpath('data')
            if data_path == nil then
                error('data path was nil but a string was expected')
            elseif type(data_path) == 'table' then
                error('data path was an array but a string was expected')
            end

            local stat = vim.loop.fs_stat(data_path)
            if stat and stat.type ~= 'directory' then
                local template =
                    "Path %s already exists and it's not a directory!"
                error(template:format(data_path))
            end

            require('telescope.builtin').live_grep({
                cwd = data_path,
                prompt_title = 'Live Grep (neovim data)',
            })
        end,
    },
})
