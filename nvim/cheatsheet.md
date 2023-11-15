# Useful command
- `:help <a neovim api function/object>` opens help for the function
- `:help motions.txt` opens help page for learning vim motions
- `:help vim-diff.txt` list differences between vim
- `:help nvim-surround.txt` readme for nvim-surround plugin

- `:Inspect` to show the highlight groups under the cursor
- `:InspectTree` to show the parsed syntax tree
- `:EditQuery` to open the Live Query Editor
- `ConformInfo` check if formatters are working and picking up config files
- `LspInfo` check info about lsps for buffer
- `Telescope luasnip` check list of snippets for buffer

- `:DiffviewOpen` to open the git diff for current changes

- `:Mason` to open the package manager for LSPs, linters, formatters, and debugers.


- `:lua= vim.lsp.get_active_clients({ name = "lua_ls" })[1].config.settings.Lua` to print info about the lua lsp config
- `:Gitsigns toggle_current_line_blame` to toggle git blame

- `:redir @a | silent scriptnames | redir END` redirect output of script to register https://vi.stackexchange.com/a/18833
- `:put =execute(':scriptnames')` directly paste output of script into the current buffer https://vi.stackexchange.com/a/18834

- `:Telescope lsp_document_symbols` find symbols in buffer

- `<C-k>` opens information in popup about the symbol using the lsp (press again to move cursor into the popup and q to leave the popup)
- `shift-K` opens hover diagnostics in popup about the symbol (press again to move cursor into the popup and q to leave the popup)

- `:vimgrep "\%^" **/*.md` add all files with md extension to quick fix list (`\%^` is the regex for the first line of a file)
