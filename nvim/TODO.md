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
- Add debuger buttons to heirline
- Add linter list element to heirline
- setup inlay hints (may require upgrading neovim version and configuring plugins) It shows parameter names when functions are used

Cool plugins:
- https://github.com/folke/trouble.nvim
- https://github.com/rmagatti/auto-session
- https://github.com/kevinhwang91/nvim-bqf
- https://github.com/CKolkey/ts-node-action Toggle formatting of code snippets (this is not about typescript) 
- https://github.com/ThePrimeagen/refactoring.nvim
- https://github.com/sudormrfbin/cheatsheet.nvim
- https://github.com/soulis-1256/hoverhints.nvim 
- https://github.com/rgroli/other.nvim
- https://github.com/jmederosalvarado/roslyn.nvim
