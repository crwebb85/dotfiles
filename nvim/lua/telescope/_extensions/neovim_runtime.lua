return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        find_files = function(_)
            require('telescope.builtin').find_files({
                cwd = require('myconfig.utils.path').get_vimruntime_dir(),
                prompt_title = 'Find Files (neovim runtime)',
            })
        end,

        live_grep = function(_)
            require('telescope.builtin').live_grep({
                cwd = require('myconfig.utils.path').get_vimruntime_dir(),
                prompt_title = 'Live Grep (neovim runtime)',
            })
        end,
    },
})
