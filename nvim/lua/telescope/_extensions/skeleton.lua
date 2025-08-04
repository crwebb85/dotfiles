return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        skeleton = function(_)
            local config_path = vim.fn.stdpath('config')
            if type(config_path) ~= 'string' then
                error('config path was not a string')
            end
            local skeleton_path = vim.fs.joinpath(config_path, 'skeletons')
            return require('telescope.builtin').find_files({
                cwd = skeleton_path,
            })
        end,
    },
})
