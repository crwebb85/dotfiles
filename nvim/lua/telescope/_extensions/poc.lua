return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        poc = function(_)
            local conf = require('telescope.config').values

            require('telescope.pickers')
                .new({}, {
                    prompt_title = 'My Proof of Concepts',
                    finder = require('telescope.finders').new_table({
                        results = require('myconfig.utils.path').get_poc_paths(),
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
