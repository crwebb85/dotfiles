return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        find_files = function(_)
            local note_path = vim.fs.normalize('$MY_NOTES')
            if note_path == '$MY_NOTES' then
                error(
                    "$MY_NOTES environment variable is not defined. Please create the environment variable in order to search it's directory."
                )
            end
            local stat = vim.loop.fs_stat(note_path)
            if stat and stat.type ~= 'directory' then
                local template =
                    "Path %s already exists and it's not a directory!"
                error(template:format(note_path))
            end

            require('telescope.builtin').find_files({
                cwd = note_path,
                prompt_title = 'Find Files (Notes)',
            })
        end,

        live_grep = function(_)
            local note_path = vim.fs.normalize('$MY_NOTES')
            if note_path == '$MY_NOTES' then
                error(
                    "$MY_NOTES environment variable is not defined. Please create the environment variable in order to search it's directory."
                )
            end
            local stat = vim.loop.fs_stat(note_path)
            if stat and stat.type ~= 'directory' then
                local template =
                    "Path %s already exists and it's not a directory!"
                error(template:format(note_path))
            end

            require('telescope.builtin').live_grep({
                cwd = note_path,
                prompt_title = 'Live Grep (Notes)',
            })
        end,
    },
})
