# Useful command

"$schema": "https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json",

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
- `:Git Difftool` adds all git changes to the quick fix list

- `gv` re-select last selection

- `vim.fn.expand('%')` get current path
- `:echo stdpath('data')` to find the path that neovim saves user data to

- `:wshada!` will fix most shada errors (I believe it overwrites the shada file)

You can pass arbitrary data to a User autocmd callback by doing

```lua
vim.api.nvim_exec_autocmds('User', {
    pattern = 'EventName>',
    data = {
        -- Data you want to send on event
    },
})
```

then receive it using

```lua
vim.api.nvim_create_autocmd('User', {
    pattern = '<event-name>',
    callback = function(event)
        -- event.data == <some-data>
    end,
})
```

- `o` create new line below current line and go to it
- `O` create new line above current line and go to it

- use `verbose` in front of a command to get verbose into such as `:verbose map`
- `:nmap` to see normal mode mappings
- `:vmap` to see visual mode mappings
- `:imap` to see insert mode mappings
- `:Man make` open the man page for program for this example it would be for `make`

- `help various-motions` - list useful movement motions
- `:h user-manual`

- `<c-f>` in command mode lets you edit commands as if you were in normal mode
- `q:` from normal mode will also open the same command prompt
- `<C-r><C-w>` used to copy cursor word into command window

### Split line

- `r<CR>` split line (will delete character cursor is on)
- `s<CR>` split line and will preserve indentation (will delete character cursor is on)

### Other

```
:lua = vim.lsp.handlers
:ScratchTab | :put =execute(':lua =vim.lsp.get_clients()[1].server_capabilities')
:verbose pwd
:Git rev-parse --show-toplevel
:lua= vim.fn.getcwd()
```

useful api functions:

- fnameescape()
- nvim_list_bufs()
- nvim_buf_is_loaded()
- nvim_list_wins()
- nvim_replace_termcodes()
- nvim_select_popupmenu_item()
- nvim_buf_is_loaded()
- nvim_win_get_buf()
- nvim_win_get_number()
- nvim_get_current_win()
- nvim_win_get_var()
- nvim_buf_get_var()
- https://neovim.io/doc/user/api.html#api-floatwin
- setreg() - used to set a register
- confirm({msg} [, {choices} [, {default} [, {type}]]]) - used to create confirmation dialog boxes

### Notes

The command buffer that opens with `q:` has:

- filetype = vim
- buftype nofile
- ':h cmdline.txt'

|CmdwinEnter| and |CmdwinLeave|
shellescape()

getcmdwintype() _getcmdwintype()_
Return the current |command-line-window| type. Possible return
values are the same as |getcmdtype()|. Returns an empty string
when not in the command-line window.

# Do more reading

- `:h shellslash`
- `:h completeslash`

# Useful resources

[Lua Type Checking Guide](https://mrcjkb.dev/posts/2023-08-17-lua-adts.html)
[Compile in Vim](https://learnvim.irian.to/basics/compile)

# Windows install

[Wezterm config help](https://gilbertsanchez.com/posts/my-terminal-wezterm/)

```ps1
# if pwsh is not a command
winget install --id Microsoft.Powershell --source winget

# Then install
choco install mingw
choco install ripgrep
winget install hpjansson.Chafa
choco install make
```

Other requirements:

- node
- npm
- python
- pip

Add Environment Variables:

- User variables
  - XDG_CONFIG_HOME=%USERPROFILE%\Documents\.config\
  - Path=%USERPROFILE%\AppData\Local\nvim-data\mason\bin
- System Variables:
  - Path=C:\Program Files\WezTerm
  - Path=C:\nvim-win64\bin
  - Path=C:\Program Files\nodejs
  - Path=C:\ProgramData\chocolatey\bin
  - Path=C:\Program Files\PowerShell\7

I also had issues with treesitter markdown support `Error in decoration provider treesitter/highlighter.win: Error executing lua: ...im`
I solved it by trying:

```
:TSUninstall markdown
:TSUninstall markdown_inline
```

Those commands failed for some reason but the error message told me the file path they
were downloaded at and I manually deleted them and it fixed the problem
