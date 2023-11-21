TODO:
- create telescope finder for keymaps searching by discription rather than key
- the plugin mini-pairs is decent but I find getting annoyed when a it creates a pair I didn't want
    - I think I will replace this plugin with snippets and nvim-surround 
- telescope spell_suggest currently overrides my paste register with my misspelling. I don't want it to do this.
- Figure out how to adjust bash theme to match neovim
- Adjust nvim-cmp suggest comparators https://www.reddit.com/r/neovim/comments/17nmp47/snippet_workflow/
- Investigate advanced features of conform.nvim https://github.com/stevearc/conform.nvim 
- Create a fileencoding picker heirline element https://stackoverflow.com/questions/16507777/set-encoding-and-fileencoding-to-utf-8-in-vim
```
:lua= vim.api.nvim_get_option_value('encoding', {})
:lua= vim.api.nvim_get_option_value('fileencoding', {})
:lua= vim.api.nvim_get_option_value('fileencodings', {})
```
- figure out how to create custom keymaps that use motions for example a custom yank function that lets me also use the motion commands to select what to yank
- setup code lens to show number of variable/function references https://www.reddit.com/r/neovim/comments/12hf3k3/comment/jfom79l/?utm_medium=android_app&utm_source=share&context=3
- https://www.reddit.com/r/neovim/comments/17ux1nf/comment/k996vs0/?utm_source=share&utm_medium=web2x&context=3
- interesting cmp and luasnip config https://www.reddit.com/r/neovim/comments/wmkf9o/comment/ik0mcwk/?utm_source=share&utm_medium=web2x&context=3
- add a way to read programming docs from neovim https://www.brow.sh/ and https://github.com/lalitmee/browse.nvim
- add add keymap to navigate to next/previous item int trouble diagnostics menu
- had an error when saving changes made within diffview
```log
Error detected while processing BufWriteCmd Autocommands for "<buffer=31>":
Error executing lua callback: ...azy/diffview.nvim/lua/diffview/vcs/adapters/git/init.lua:1629: vim/_editor.lua:0: BufWriteCmd Autocommands for "<buffer=31>"..script nvim_exec2() called at BufWriteCmd Autocommands for "<buffer=31>":0: Vim(write):E19:
 Mark has invalid line number: silent noautocmd keepalt '[,']write /tmp/nvim.chris/0QWTdw/0
stack traceback:
        [C]: in function 'error'
        ...azy/diffview.nvim/lua/diffview/vcs/adapters/git/init.lua:1629: in function 'stage_index_file'
        .../share/nvim/lazy/diffview.nvim/lua/diffview/vcs/file.lua:275: in function <.../share/nvim/lazy/diffview.nvim/lua/diffview/vcs/file.lua:274>
Error detected while processing BufWriteCmd Autocommands for "<buffer=37>":
Error executing lua callback: ...azy/diffview.nvim/lua/diffview/vcs/adapters/git/init.lua:1629: vim/_editor.lua:0: BufWriteCmd Autocommands for "<buffer=37>"..script nvim_exec2() called at BufWriteCmd Autocommands for "<buffer=37>":0: Vim(write):E19:
 Mark has invalid line number: silent noautocmd keepalt '[,']write /tmp/nvim.chris/0QWTdw/1
stack traceback:
        [C]: in function 'error'
        ...azy/diffview.nvim/lua/diffview/vcs/adapters/git/init.lua:1629: in function 'stage_index_file'
        .../share/nvim/lazy/diffview.nvim/lua/diffview/vcs/file.lua:275: in function <.../share/nvim/lazy/diffview.nvim/lua/diffview/vcs/file.lua:274>
```

Cool plugins:
- https://github.com/rockerBOO/awesome-neovim
- https://github.com/carbon-steel/detour.nvim/tree/main
- https://github.com/rmagatti/auto-session
- https://github.com/kevinhwang91/nvim-bqf
- https://github.com/CKolkey/ts-node-action Toggle formatting of code snippets (this is not about typescript) 
- https://github.com/ThePrimeagen/refactoring.nvim
- https://github.com/sudormrfbin/cheatsheet.nvim
- https://github.com/soulis-1256/hoverhints.nvim 
- https://github.com/rgroli/other.nvim
- https://github.com/jmederosalvarado/roslyn.nvim
- emmet lsp - https://www.reddit.com/r/neovim/comments/17v1678/comment/k97ggs2/?utm_source=share&utm_medium=web2x&context=3
- https://github.com/iamcco/markdown-preview.nvim
