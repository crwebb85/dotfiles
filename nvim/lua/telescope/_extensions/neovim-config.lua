return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        find_files = function(_)
            local config_path = vim.fn.stdpath('config')
            if type(config_path) ~= 'string' then
                error('config path was not a string')
            end
            local stat = vim.uv.fs_stat(config_path)
            if stat and stat.type ~= 'directory' then
                local template =
                    "Path %s already exists and it's not a directory!"
                error(template:format(config_path))
            end

            require('telescope.builtin').find_files({
                cwd = config_path,
                prompt_title = 'Find Files (neovim config)',
            })
        end,

        live_grep = function(_)
            local config_path = vim.fn.stdpath('config')
            if type(config_path) ~= 'string' then
                error('config path was not a string')
            end
            local stat = vim.uv.fs_stat(config_path)
            if stat and stat.type ~= 'directory' then
                local template =
                    "Path %s already exists and it's not a directory!"
                error(template:format(config_path))
            end

            require('telescope.builtin').live_grep({
                cwd = config_path,
                prompt_title = 'Live Grep (neovim config)',
            })
        end,
    },
})
