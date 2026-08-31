return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        find_files = function(_)
            return require('telescope.builtin').find_files({
                cwd = require('myconfig.utils.path').get_skeleton_dir(),
                prompt_title = 'Find Files (skeletons)',
            })
        end,
        live_grep = function(_)
            require('telescope.builtin').live_grep({
                cwd = require('myconfig.utils.path').get_skeleton_dir(),
                prompt_title = 'Live Grep (skeletons)',
            })
        end,
    },
})
