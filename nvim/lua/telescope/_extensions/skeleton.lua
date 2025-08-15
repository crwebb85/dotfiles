return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        find_files = function(_)
            local config_path = vim.fn.stdpath('config')
            if type(config_path) ~= 'string' then
                error('config path was not a string')
            end
            local skeleton_path = vim.fs.joinpath(config_path, 'skeletons')
            return require('telescope.builtin').find_files({
                cwd = skeleton_path,
                prompt_title = 'Find Files (skeletons)',
            })
        end,
        live_grep = function(_)
            local config_path = vim.fn.stdpath('config')
            if type(config_path) ~= 'string' then
                error('config path was not a string')
            end
            local skeleton_path = vim.fs.joinpath(config_path, 'skeletons')
            require('telescope.builtin').live_grep({
                cwd = skeleton_path,
                prompt_title = 'Live Grep (skeletons)',
            })
        end,
    },
})
