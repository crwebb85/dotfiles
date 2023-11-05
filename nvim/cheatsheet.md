# Useful command
- `:help <a neovim api function/object>` opens help for the function
- `:help motions.txt` opens help page for learning vim motions
- `:help vim-diff.txt` list differences between vim

- `:Inspect` to show the highlight groups under the cursor
- `:InspectTree` to show the parsed syntax tree
- `:EditQuery` to open the Live Query Editor

- `:DiffviewOpen` to open the git diff for current changes

- `:Mason` to open the package manager for LSPs, linters, formatters, and debugers.


- `:lua= vim.lsp.get_active_clients({ name = "lua_ls" })[1].config.settings.Lua` to print info about the lua lsp config
- `:Gitsigns toggle_current_line_blame` to toggle git blame

- `shift-K` shows hover diagnostics
 
