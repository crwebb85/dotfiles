return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        find_files = function(_)
            require('telescope.builtin').find_files({
                cwd = require('myconfig.utils.path').get_my_notes_dir(),
                prompt_title = 'Find Files (Notes)',
            })
        end,

        live_grep = function(_)
            require('telescope.builtin').live_grep({
                cwd = require('myconfig.utils.path').get_my_notes_dir(),
                prompt_title = 'Live Grep (Notes)',
            })
        end,
    },
})
