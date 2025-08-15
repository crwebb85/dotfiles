return require('telescope').register_extension({
    setup = function(_) end,
    exports = {
        find_files = function(_)
            local runtime_path = vim.fs.normalize('$VIMRUNTIME')
            local stat = vim.loop.fs_stat(runtime_path)
            if stat and stat.type ~= 'directory' then
                local template =
                    "Path %s already exists and it's not a directory!"
                error(template:format(runtime_path))
            end

            require('telescope.builtin').find_files({
                cwd = runtime_path,
                prompt_title = 'Find Files (neovim runtime)',
            })
        end,

        live_grep = function(_)
            local runtime_path = vim.fs.normalize('$VIMRUNTIME')
            local stat = vim.loop.fs_stat(runtime_path)
            if stat and stat.type ~= 'directory' then
                local template =
                    "Path %s already exists and it's not a directory!"
                error(template:format(runtime_path))
            end

            require('telescope.builtin').live_grep({
                cwd = runtime_path,
                prompt_title = 'Live Grep (neovim runtime)',
            })
        end,
    },
})
