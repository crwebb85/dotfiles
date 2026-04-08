return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        harpoon = function(_)
            local conf = require('telescope.config').values
            local harpoon = require('harpoon')

            local file_paths = {}
            for _, item in ipairs(harpoon:list().items) do
                --Decode dynamic harpoon items based on current date
                --for example "${test%Y-%m-%d.log}" would become "test2024-09-27.log"
                --if todays date was 2024-09-27 this allows adding current days log file
                --to the harpoon list without having to change it each day.
                local list_item_value, _ = string.gsub(
                    item.value,
                    '^%${(.*)}$',
                    function(n) return os.date(n) end
                )
                table.insert(file_paths, list_item_value)
            end

            require('telescope.pickers')
                .new({}, {
                    prompt_title = 'Harpoon',
                    finder = require('telescope.finders').new_table({
                        results = file_paths,
                        entry_maker = function(path)
                            return {
                                display = path,
                                ordinal = path,
                                filename = path,
                            }
                        end,
                    }),
                    previewer = conf.file_previewer({}),
                    sorter = conf.generic_sorter({}),
                })
                :find()
        end,
    },
})
