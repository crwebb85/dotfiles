return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        projects = function(_)
            local conf = require('telescope.config').values

            require('telescope.pickers')
                .new({}, {
                    prompt_title = 'My Projects',
                    finder = require('telescope.finders').new_table({
                        results = require('myconfig.utils.path').get_project_paths(),
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
    },
})
