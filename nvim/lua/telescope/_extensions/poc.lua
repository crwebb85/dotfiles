return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        poc = function(_)
            local conf = require('telescope.config').values

            local project_paths = require('utils.path').get_poc_paths()

            require('telescope.pickers')
                .new({}, {
                    prompt_title = 'My Projects',
                    finder = require('telescope.finders').new_table({
                        results = project_paths,
                    }),
                    sorter = conf.generic_sorter({}),
                    attach_mappings = function(buffer_number)
                        local actions = require('telescope.actions')
                        local action_state = require('telescope.actions.state')
                        actions.select_default:replace(function()
                            actions.close(buffer_number)
                            vim.cmd(
                                'e ' .. action_state.get_selected_entry()[1]
                            )
                        end)
                        return true
                    end,
                })
                :find()
        end,
    },
})
