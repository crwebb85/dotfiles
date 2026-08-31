return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        find_files = function(_)
            require('telescope.builtin').find_files({
                cwd = require('myconfig.utils.path').get_nvim_plugins_dir(),
                prompt_title = 'Find Files (neovim plugin)',
            })
        end,
        find_plugin_dir = function(_)
            local conf = require('telescope.config').values

            require('telescope.pickers')
                .new({}, {
                    prompt_title = 'Plugin Directories',
                    finder = require('telescope.finders').new_table({
                        results = require('myconfig.utils.path').list_nvim_plugin_dirs(),
                        entry_maker = function(path)
                            return {
                                display = path,
                                ordinal = path,
                                filename = path,
                            }
                        end,
                    }),
                    sorter = conf.generic_sorter({}),
                })
                :find()
        end,

        live_grep = function(_)
            require('telescope.builtin').live_grep({
                cwd = require('myconfig.utils.path').get_nvim_plugins_dir(),
                prompt_title = 'Live Grep (neovim plugin)',
            })
        end,
    },
})
