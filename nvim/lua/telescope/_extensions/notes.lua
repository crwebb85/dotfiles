return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        notes = function(_)
            local note_path = vim.fs.normalize('$MY_NOTES')
            if note_path == '$MY_NOTES' then
                error(
                    "$MY_NOTES environment variable is not defined. Please create the environment variable in order to search it's directory."
                )
            end
            require('telescope.builtin').find_files({
                cwd = note_path,
            })
        end,
    },
})
