### Unorganized TODO:

- look into skeleton (file template) plugins/configuration
- try out new features:
  - winfixbuf
  - vim.ringbuf
  - getregion()
  - |gx| now uses |vim.ui.open()| and not netrw. To customize, you can redefine
    `vim.ui.open` or remap `gx`. To continue using netrw (deprecated): >vim
- try out basedpyright lsp [example](https://www.reddit.com/r/neovim/comments/1cpkeqd/comment/l3ux37y/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
- Use counts on telescope pickers to where each count corresponds to a subfolder in the project to narrow the search scope
- Use counts on harpoon for multiple lists
- Use counts with gf to open file in the winnr
- investigate preformance improvements
  - https://www.reddit.com/r/neovim/comments/1cjn94h/fully_eliminate_o_delay/
  - https://www.reddit.com/r/neovim/comments/1cjnf0m/fully_eliminate_gds_delay/
  - https://www.reddit.com/r/neovim/comments/1ch6yfz/smart_indent_with_treesitter_indent_fallback/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
- [registers improvements](https://gist.github.com/MyyPo/569de2bff5644d2c351d54a0d42ad09f)
- make file buffers not in current directory slightly redder
- look into overseer docker templates https://github.com/LoricAndre/dotfiles/blob/main/dot_config/nvim/lua/overseer/template/docker/build.lua
- clean up powershell profile
- add powershell fzf shortcut to search for projects
- add a powershell fzf shortcut to search for poc's
- add telescope picker to search for projects (automatically set lcd on splits)
- add telescope picker shortcut to search for poc's (automatically set lcd on splits)

### Bugs

- spelling errors highlight as red squigly line in neovim does not display when using wezterm. It does display in powershell
- `<leader>gd` does not open git diff tab if the tab is already open
- when in wezterm and I open my `nvim ./` from my .config directory then new wezterm tab the cwd will be .config/nvim instead of .config
- 'gC' keymap doesn't invert correctly when comments have nested comments
- fix my_on_output_quickfix.lua file as invalid characters added are added to
  the begining of items when using tail = true and append = true at the same time
  (this has been confirmed to happen with my GrepAdd command)
- fix python formatters
- Bug heirline: new upstaged files say main the git branch and new files staged preview doesn't show git branch
- my keymap for running neotest on files marks succeeded test as failed if any test failed in the file
  on old versions of windows (but works correctly on windows 11)
- overseer hurl opens the quickfix window in all tabs not just the tab that was I used to run the overseer command
- when going into a big file (only tested when using gd (goto definition)) the first line gets added to the jump list
- something is causing my cmdheight to increase in size (vim.go.cmdheight or vim.o.cmdheight) it is rare but does happen
- when using a editorconfig file my code that replaces netrw with oil will throw an error saying the buffer is unmodified.
  Both the end_of_line and charset will cause the error.
- fix non-navigation treesitter keymaps

```editorconfig
root = true

[*]
end_of_line = lf
charset = utf-8
```

The error message

```log
Error executing vim.schedule lua callback: ...b/AppData/Local/nvim-data/lazy/oil.nvim/lua/oil/init.lua:385: Vim:E37: No write since last change (add ! to override)
stack traceback:
	[C]: in function 'edit'
	...b/AppData/Local/nvim-data/lazy/oil.nvim/lua/oil/init.lua:385: in function 'open'
	.config\nvim/lua/config/lazy.lua:942: in function <.config\nvim/lua/config/lazy.lua:932>
```

### Neovim bugs

- redraw cmd and lazyredraw option now clear the selection messages so it was preventing me seeing which code actions I could pick
- regression: LspStop no longer clears diagnostics

```lua

            {
                '<leader>tc',
                function() require('neotest').run.run(vim.fn.expand('%')) end,
                desc = 'Neotest: Run the current file',
            },

```

- Bug Telescope: plugin documentation now shows up in Telescope even if not yet loaded.
  When you select it in telescope you will get the following error:

```

E5108: Error executing lua: vim/_editor.lua:439: nvim_exec2(): Vim(help):E661: Sorry, no 'en' help for Overseer
stack traceback:
	[C]: in function 'nvim_exec2'
	vim/_editor.lua:439: in function 'cmd'
	...lazy/telescope.nvim/lua/telescope/builtin/__internal.lua:806: in function 'run_replace_or_original'
	...im-data/lazy/telescope.nvim/lua/telescope/actions/mt.lua:65: in function 'run_replace_or_original'
	...im-data/lazy/telescope.nvim/lua/telescope/actions/mt.lua:65: in function 'select_default'
	C:\Users\crweb\Documents\.config\nvim/lua/config/lazy.lua:617: in function 'key_func'
	...nvim-data/lazy/telescope.nvim/lua/telescope/mappings.lua:293: in function <...nvim-data/lazy/telescope.nvim/lua/telescope/mappings.lua:292>
```

the workaround is to make sure the plugin is loaded

### TODO and Workflows that need improvements

- [ ] project specific configuration
  - [ ] improve exrc
    1. Move this to the beginning of config
    2. Add user autocommands for when parts of my config are ran so that my
       .nvim.lua file can pinpoint configuration overrid using autocommands to occur
       at the exact spot it needs to run. (i.e. PreSet, Set, PreConfig, Config, PreLsp, PostLsp)
    3. Create a .nvim.lua skeleton file with the autocommands templates prepopulated
- [ ] lsp
  - [ ] keymaps like grr should notify when the no results were found
  - [ ] try a newer dotnet lsp
  - [ ] create a way to disable/enable lsp's and formatters on a project level using .nvim.lua file
  - [ ] add debugger for older dotnet projects
- [ ] terminal
  - [ ] add a keymap to toggle on/off following the text printed in the terminal
  - [ ] add terminal resurrection
  - [ ] add yanking last command output
  - [ ] add yanking terminals cd path (use the count when not in the terminal buffer)
  - [ ] add repeat last command (with confirmation)
  - [ ] creating a top terminal and then a different left terminal causes the left
        one to take up half of the screen horizontally. I think this is due to the
        equalize function (this may be a sacrifice worth keeping if there isn't a clear fix)
- [ ] Window navigation
  - create a hydra like keymaps for <C-W> keys
  - add <leader>w as an alias for <C-W> keymaps (move multicursor keymaps to a different namespace)
  - Add harpoon list for reruning overseer tasks
- [ ] Settings
  - [ ] match tabs with what my formatters use for various file types
  - [ ] add a local leader to start replacing keymaps from plugins with UI buffers like telescope, diffview, fugitive
  - [ ] try out cspell or harper lsp instead of vim spell check
- [ ] Snippets and Skeletons
  - [x] Add keymap to select snippets with telescope (should help with discovering snippets from friendly-snippets)
  - [ ] Add t-sql snippets
    - [ ] update
    - [ ] insert
    - [ ] update or insert
  - [ ]Add mermaid snippets (at a minimum include the examples on the mermaid website for each diagram type[ ] )
  - [ ] Add markdown snippets
    - [x] code block snippet (friendly-snippets adds the prefix `codeblock`)
  - [ ] Add C# snippets
    - [ ] unit tests
    - [x] class (friendly-snippets adds the prefix `class`)
    - [ ] test class
  - [ ] hurl
    - [ ] get request
    - [ ] post request
    - [ ] delete request
    - [ ] put request
    - [ ] oauth request
    - [ ] ntlm auth request
  - [ ] add snippets using pythons faker library to generate fake data
- [ ] Requests
  - [x] Commands for interacting with hurl files (may use plugin)
  - [ ] wsdl support with code completion for fields
  - [ ] add a proxy that can log the requests as hurl files
  - [ ] telescope navigation for hurl files
  - [ ] add keymap to telescope navigation to create a duplicate of an existing hurl file
  - [ ] add a keymap to oil.nvim that lets me select a hurl file via telescope to create a duplicate of
  - [ ] add hurl completion
- [ ] Log files
  - [ ] make log files read only
  - [ ] searching
  - [ ] filtering
  - [ ] live-update/pausing
  - [ ] highlights
  - [ ] remote/cloud logs
  - [ ] (if my new harpoon parameterized dates is not sufficient) make telescope picker for log file folders using a harpoon list to control the log file locations
  - [ ] add StackTrace resume and StackTrace restart commands
- [ ] QuickFix
  - [ ] keep track of commands that generated quickfix/loc lists so that I can reload them with a keybinding or go to a previous list
  - [ ] make quickfix/loc list editable
  - [ ] add Add version of quickfix commands similar to vimgrepadd
  - [ ] exclude `Time Elapsed 00|1| 01.52` from error format (at least in overseer tasks)
  - [ ] add location list as an option for overseer output
  - [ ] integrate overseer with neotest
  - [ ] add buffer and path completion to Grep and GrepAdd commands
- [ ] SQL
  - [ ] tsql treesitter
  - [ ] tsql formatter
  - [ ] running sql queries
  - [ ] lsp https://github.com/sqls-server/sqls
- [ ] XML
  - [ ] Add xml lsp
  - [ ] Get xml schemas working similar to how I have it with json schemas or yaml schemas
- [ ] Markdown
  - [ ] special treesitter keymaps/text objexts
    - [ ] add `` i` and a` `` text objexts for inner and arround backticks (if in a markdown file use exclude the filetype when doing inner selection by using treesitter)
  - [x] try out https://github.com/MeanderingProgrammer/render-markdown.nvim
  - [ ] possibly replace the markdown viewer I am using
- [ ] Notetaking
  - [x] add some lsp/plugin for notetaking compatible with obsidian/dendron or other some other note taking app
  - [x] https://github.com/Feel-ix-343/markdown-oxide
  - [ ] daily notes
  - [ ] people references
  - [ ] note templates using dendron format
- [ ] Notebook support
  - [ ] jupyter notebooks
- [ ] Debugging
  - [ ] setup debugger for .net46 projects https://www.reddit.com/r/neovim/comments/1k7egep/using_a_custom_lua_mason_registry/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
  - [ ] pid telescope picker for processes
- [ ] Heirline
  - [ ] Add a heirline component for python virtual environment. There is an example in the docs for venv-selector.nvim
  - [ ] Add a heirline component for harpoon
  - [ ] show workspace diagnostic counts in heirline
  - [ ] add a symbol when I have any unsaved buffers
  - [ ] if an lsp diagnostics are hidden the lsp should appear orange in heirline
- [ ] CLI
  - [ ] add ripgrep completion to my powershell profile https://github.com/BurntSushi/ripgrep/blob/master/FAQ.md#complete
  - [ ] Create a bash completion script for attaching zellij session (https://opensource.com/article/18/3/creating-bash-completion-script)
  - [ ] fix powershell profile to not display tab completion for failed commands
- [ ] Config
  - [x] add list of mason items to not install automatically
  - [x] configure heirline nerdfonts to use ascii when nerd_font_enabled config value equals false
- [ ] Refactor
  - [x] properly use setqflist action parameter for appending to an existing list.
  - [x] refactor my windows check to use `vim.fn.has('win32') == 1`
  - [ ] refactor telescope keymap `<leader>fh` to no longer use a register in visual mode
  - [ ] refactor uses of vim.lsp.util.make_range_params() to use the character encoding parameter
- [ ] Formatting
  - [ ] Formatting mode to only format git changes
  - [ ] add html formatter
- [ ] Movement/TextObjects keymaps
  - [ ] re-evaluate keymaps after upgrading to nightly based on keymaps added in https://github.com/neovim/neovim/commit/bb7604eddafb31cd38261a220243762ee013273a
  - [ ] add ]r and [r for navigating lsp references
  - [x] add a substitute operation that uses text objects for pasting similar to [substitute.nvim](https://github.com/gbprod/substitute.nvim)
  - [ ] add keymap for next/previous partial word for navigating within snake-case and camel-case variables similar to [chrisgrieser/nvim-spider](https://github.com/chrisgrieser/nvim-spider)
  - [ ] maybe use some prefix like g for my navigation keymaps to move the cursor to the end
        of the item like how gp works. For example if ]m navigates to the begining of
        the next method then ]gm should go to the end of the next method. That way I can
        reserve capital letters for the first and last extremes
  - [ ] for my treesitter text objects I am finding how they work with spacing annoying as deleting
        an pasting results in a lot of extra lines (maybe play around with settings to there are more intuitive options)
  - [ ] comments navigation/textobjects
    - gc
      - operate exactly over the range of text that the gc operator would have commented
    - igc
      - operate over text inside comment when single line comment
      - operate over text inside block comment
      - operate over text inside comment forcing block select for line comments when multiple lines
    - agc
      - operate over text around comment when single line comment
      - operate over text around comment when multiple single line comment
      - operate over text around comment block comments
  - [ ] I want to improve my indent text objec igi and agi based on [vim-indent-object](https://github.com/michaeljsmith/vim-indent-object)
  - [ ] modify visual and around keymaps to extend current selection (some care may be needed for how to handle whitespace)
  - [ ] text objexts I want to try out [chrisgrieser/nvim-various-textobjs](https://github.com/chrisgrieser/nvim-various-textobjs)
  - [ ] try out [matze/vim-move](https://github.com/matze/vim-move)
  - [ ] try out [custom surrounds](https://github.com/kylechui/nvim-surround/discussions/53)
  - [ ] try out https://www.reddit.com/r/neovim/comments/1ckd1rs/helpful_treesitter_node_motion/?utm_medium=android_app&utm_source=share
- [ ] Prune Plugins (plugins I might want to create my own version of or see if I still need it)
  - iamcco/markdown-preview.nvim (replace with maybe my own version)
  - nvim-tree/nvim-web-devicons (replace with echasnovski/mini.icons)
  - hrsh7th/nvim-cmp (replace with native completion and https://www.reddit.com/r/neovim/comments/1fwhhp0/new_plugin_cmp2lsp/?utm_medium=android_app&utm_source=share)

### Vim Practice

- research table based navigation using `set virtualedit=all`

### Cool plugins:

- https://github.com/rockerBOO/awesome-neovim
- https://github.com/carbon-steel/detour.nvim/tree/main
- https://github.com/rmagatti/auto-session
- https://github.com/kevinhwang91/nvim-bqf
- https://github.com/CKolkey/ts-node-action Toggle formatting of code snippets (this is not about typescript)
- https://github.com/sudormrfbin/cheatsheet.nvim
- https://github.com/soulis-1256/hoverhints.nvim
- https://github.com/rgroli/other.nvim
- https://github.com/jmederosalvarado/roslyn.nvim
- https://github.com/anuvyklack/hydra.nvim
- https://github.com/AndrewRadev/inline_edit.vim
- https://github.com/HakonHarnes/img-clip.nvim
- https://github.com/AndrewRadev/multichange.vim
- https://www.reddit.com/r/neovim/comments/18jqw0l/introducing_tinygit_a_lightweight_bundle_of_git/?utm_medium=android_app&utm_source=share
- https://github.com/crate-ci/typos (spellcheck)
- https://github.com/smjonas/inc-rename.nvim (maybe inline this plugin in my lsp config)
- https://github.com/nvim-java/nvim-java
- https://github.com/FabianWirth/search.nvim
- https://github.com/fdschmidt93/telescope-egrepify.nvim
- https://github.com/mfussenegger/nvim-jdtls
- https://github.com/vxpm/ferris.nvim
- https://github.com/dmitmel/cmp-cmdline-history
- https://github.com/motosir/skel-nvim
- https://github.com/cvigilv/esqueleto.nvim
- https://github.com/xeluxee/competitest.nvim
- https://github.com/MunifTanjim/nui.nvim#popup
- https://github.com/nvim-java/nvim-java
- https://github.com/ronakg/quickr-preview.vim/tree/master
- https://github.com/NicholasMata/nvim-dap-cs

### Cool LSPs

- https://github.com/mattn/efm-langserver
- emmet lsp - https://www.reddit.com/r/neovim/comments/17v1678/comment/k97ggs2/?utm_source=share&utm_medium=web2x&context=3

### Look into:

- `:h dap-launch.json`
- https://editorconfig.org/ support for neovim
- [lua async tutorial](https://github.com/ms-jpq/lua-async-await)
- [git message guide](https://www.freecodecamp.org/news/how-to-write-better-git-commit-messages/)
- `:h skeleton` - for info about file templates
- `:h win_gettype()`

### Interesting Articles/Posts:

- https://gist.github.com/lucasecdb/2baf6d328a10d7fea9ec085d868923a0
- [Find and replace custom keymaps](https://www.reddit.com/r/neovim/comments/18dvpe1/wanted_to_share_a_small_and_simple_mapping_for/?utm_medium=android_app&utm_source=share)
- [Moving text blocks plugins](https://www.reddit.com/r/neovim/comments/18dk9bp/alternative_to_vimtextmanip_plugin_move_selected/?utm_medium=android_app&utm_source=share)
- [Autorename a pair of tags](https://www.reddit.com/r/neovim/comments/18dpoq2/for_people_using_a_tag_autorename_plugin_such_as/?utm_medium=android_app&utm_source=share)
- [Keymap discussion](https://www.reddit.com/r/neovim/comments/18jcj0q/any_advice_on_general_keymapping_methodologies/?utm_medium=android_app&utm_source=share)
- [Telescope and Trouble QuickFix list](https://www.reddit.com/r/neovim/comments/18iyev5/enhancing_telescope_workflow_sending_marked_files/?utm_medium=android_app&utm_source=share)
- [Telescope and quick fix list](https://www.reddit.com/r/neovim/comments/17ux1nf/comment/k996vs0/?utm_source=share&utm_medium=web2x&context=3)
- [Quick fix list and diagnostics discussion](https://www.reddit.com/r/neovim/comments/187pdop/comment/kbgdm0y/?utm_medium=android_app&utm_source=share&context=3)
- [Spell check](https://www.reddit.com/r/neovim/comments/18id6uu/how_to_get_riddisable_spellcheck_lines_not_from/?utm_medium=android_app&utm_source=share)
- [Spell check discussion](https://www.reddit.com/r/neovim/comments/185wem5/comment/kb46r3g/?utm_medium=android_app&utm_source=share&context=3)
- [Setup linting video](https://www.youtube.com/watch?v=ybUE4D80XSk)
- [Setup Linting article](https://www.josean.com/posts/neovim-linting-and-formatting)
- [Java setup discussion](https://www.reddit.com/r/neovim/comments/18hfkh2/nvimjava_brand_new_plugin_for_java_development/?utm_medium=android_app&utm_source=share)
- [Java setup discussion](https://www.reddit.com/r/neovim/comments/18g2jgr/having_the_worst_time_trying_to_use_jdtls/)
- [Java setup discussion](https://www.reddit.com/r/neovim/comments/18bmpfd/java_lombok_plugin/?utm_medium=android_app&utm_source=share)
- [Java setup article](https://medium.com/@chrisatmachine/lunarvim-as-a-java-ide-da65c4a77fb4)
- [Maven cli generate project command](https://www.reddit.com/r/neovim/comments/18kwpuv/comment/kdv5d29/?utm_source=share&utm_medium=web2x&context=3)
- [Discussion of editting visual selection within temp buffer](https://www.reddit.com/r/neovim/comments/18dhi3g/looking_for_a_plugin_to_do_markdown_hoisting/?utm_source=share&utm_medium=web2x&context=3)
- [Understanding Neovim Playlist](https://www.youtube.com/watch?v=87AXw9Quy9U&list=PLx2ksyallYzW4WNYHD9xOFrPRYGlntAft)
- [Explanation for wierd lsp error](https://www.reddit.com/r/neovim/comments/18cb9d8/comment/kc9lre2/?utm_medium=android_app&utm_source=share&context=3)
- [AtroNvim code folding config](https://github.com/AstroNvim/AstroNvim/blob/271c9c3f71c2e315cb16c31276dec81ddca6a5a6/lua/astronvim/autocmds.lua#L98-L120)
- [AI integration discussion](https://www.reddit.com/r/neovim/comments/18lxe4a/comment/ke0z1kn/?utm_medium=android_app&utm_source=share&context=3)
- [Slowness discussion](https://www.reddit.com/r/neovim/comments/18l75ng/comment/kdwn5h9/?utm_source=share&utm_medium=web2x&context=3)
- [Testing neovim discussion](https://www.reddit.com/r/neovim/comments/k99fvl/comment/gf3ufez/?utm_medium=android_app&utm_source=share&context=3)
- [Autoreloading files + tmux integration discussion](https://www.reddit.com/r/neovim/comments/18k3ii5/solution_autoreloading_files_in_a_tmux_session/?utm_medium=android_app&utm_source=share)
- [SSH Tunneling when developing on remote server](https://askubuntu.com/a/112180)
- [Testing and Neotest discussion](https://www.reddit.com/r/neovim/comments/18hdo4a/show_function_as_test_or_runnable_in_gutter/?utm_medium=android_app&utm_source=share)
- [Indenting config examples/discussion](https://www.reddit.com/r/neovim/comments/18d6yb6/use_the_builtin_listchars_option_to_implement/?utm_medium=android_app&utm_source=share)
- [Competitive Programming discussion](https://www.reddit.com/r/neovim/comments/18cwrmp/competitive_programming_setup/?utm_source=share&utm_medium=web2x&context=3)
- [Treesitter injection discussion](https://www.reddit.com/r/neovim/comments/18cdgc7/what_are_your_custom_treesitter_language/?utm_medium=android_app&utm_source=share)
- [dapui better variables discussion](https://www.reddit.com/r/neovim/comments/18b8wch/can_you_get_better_dapui_varibles/)
- [Devcontain discussion](https://www.reddit.com/r/neovim/comments/18bzy6z/devcontainer_neovim_how_to_use_neovim_inside_a/?utm_medium=android_app&utm_source=share)
- [Database UI discussion](https://www.reddit.com/r/neovim/comments/18bjsql/contributors_on_nvimdbee_are_doing_a_great_job/?utm_medium=android_app&utm_source=share)
- [Building a neovim plugin for extra codelens information (Video)](https://www.youtube.com/watch?v=RtBh8-nSUvw)
- [Multiple Neovim Configs discussion](https://www.reddit.com/r/neovim/comments/18ahduw/can_you_have_two_neovim_configurations_at_once/?utm_medium=android_app&utm_source=share)
- [Typescript lsp bug solution](https://www.reddit.com/r/neovim/comments/189wtrz/opening_files_with_telescope_will_not_trigger_lsp/)
- [Better Typescript error messages discussion](https://www.reddit.com/r/neovim/comments/189rqq7/comment/kbul7oh/?utm_medium=android_app&utm_source=share&context=3)
- [Keymap discussion](https://www.reddit.com/r/neovim/comments/18a7d8i/comment/kbxcbx1/?utm_source=share&utm_medium=web2x&context=3)
- [Keymap discussion](https://www.reddit.com/r/neovim/comments/18a7d8i/comment/kbw8kd3/?utm_medium=android_app&utm_source=share&context=3)
- [Plugins that you can't live without discussion](https://www.reddit.com/r/neovim/comments/1890v0e/what_are_some_plugins_that_you_cant_live_without/)
- [Average size of configs discussion (has links to interesting configs)](https://www.reddit.com/r/neovim/comments/187geww/i_want_to_find_the_average_size_of_a_neovim/)
- [Folding config discussion](https://www.reddit.com/r/neovim/comments/187atwy/comment/kbeb5eu/?utm_medium=android_app&utm_source=share&context=3)
- [JS Dap discussion](https://www.reddit.com/r/neovim/comments/186ntnw/does_anyone_have_a_working_dap_for_js_please/?utm_medium=android_app&utm_source=share)
- [JS Dap discussion](https://www.reddit.com/r/neovim/comments/1861hzm/i_finally_configured_nvimdap_to_debug_nodejs_apps/?utm_medium=android_app&utm_source=share)
- [Java discussion](https://www.reddit.com/r/neovim/comments/1862kxo/is_it_help_to_bring_more_java_devs_to_nvim/?utm_medium=android_app&utm_source=share)
- [Cool config](https://evantravers.com/articles/2024/09/17/making-my-nvim-act-more-like-helix-with-mini-nvim/)

### Jupyter notebook support

- [Best Jupyter noebook discussion](https://www.reddit.com/r/neovim/comments/17ynpg2/how_to_edit_jupyter_notebooks_in_neovim_with_very/)
  - I wasn't able to get this working yet and wanted to move on but it seems that the plugin [quarto-nvim](https://github.com/quarto-dev/quarto-nvim) is what I need to figure out next
  - [Dotfiles from Author of molten plugin](https://github.com/benlubas/.dotfiles/tree/main)
  - I found the some plugins don't support windows like [3rd/image.nvim](https://github.com/3rd/image.nvim)
  - The author of molten also uses his own fork of image.nvim [benlubas/image.nvim](https://github.com/benlubas/image.nvim)
- [Jupyter notebook discussion](https://www.reddit.com/r/neovim/comments/185uv3f/announcing_jupytextnvim/?utm_medium=android_app&utm_source=share)

### Interesting Distros

[Neovim::M Λ C R O](https://github.com/Bekaboo/nvim)

### External Tools

- https://eza.rocks/
- https://pandoc.org/
- https://github.com/Wilfred/difftastic
