### Unorganized TODO:

- look into skeleton (file template) plugins/configuration
- try out new features:
  - winfixbuf
  - vim.ringbuf
  - getregion()
  - |gx| now uses |vim.ui.open()| and not netrw. To customize, you can redefine
    `vim.ui.open` or remap `gx`. To continue using netrw (deprecated): >vim
- try out basedpyright lsp [example](https://www.reddit.com/r/neovim/comments/1cpkeqd/comment/l3ux37y/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
- Use toggle term on_stderr callback to store the last error to use in my StackTrace cmd
- Use counts on telescope pickers to where each count corresponds to a subfolder in the project to narrow the search scope
- Use counts on harpoon for multiple lists
- Use counts with gf to open file in the winnr
- investigate preformance improvements
  - https://www.reddit.com/r/neovim/comments/1cjn94h/fully_eliminate_o_delay/
  - https://www.reddit.com/r/neovim/comments/1cjnf0m/fully_eliminate_gds_delay/
  - https://www.reddit.com/r/neovim/comments/1ch6yfz/smart_indent_with_treesitter_indent_fallback/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
- [registers improvements](https://gist.github.com/MyyPo/569de2bff5644d2c351d54a0d42ad09f)
- maybe change clipboard so that yanks don't get automatically saved to the clipboard
- make file buffers not in current directory slightly redder

### Bugs

- Lightbulb still doesn't get removed in some case like when opening help docs with telescope
- spelling errors highlight as red squigly line in neovim does not display when using wezterm. It does display in powershell
- fix cmp completion in the terminal for arguments. For some reason when my cursor
  moves (using the left arrow key) from the end of the current argument the suggestions
  will have an incorrect prefix of the current argument up to the cursor
  (or at least that was happening in the past but I can't replicate it at this moment.)
- `<leader>gd` does not open git diff tab if the tab is already open
- conform throws an error when the formatter times out

### TODO and Workflows that need improvements

- [ ] Settings
  - [ ] match tabs with what my formatters use for various file types
- [ ] Requests
  - [ ] Commands for interacting with hurl files (may use plugin)
  - [ ] templates/snippets
  - [ ] wsdl support with code completion for fields
  - [ ] add a proxy that can log the requests as hurl files
  - [ ] telescope navigation for hurl files
  - [ ] add keymap to telescope navigation to create a duplicate of an existing hurl file
  - [ ] add a keymap to oil.nvim that lets me select a hurl file via telescope to create a duplicate of
  - [ ] add snippets using pythons faker library to generate fake data
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
- [ ] SQL
  - [ ] tsql treesitter
  - [ ] tsql formatter
  - [ ] running sql queries
- [ ] Markdown
  - [ ] special treesitter keymaps/text objexts
    - [ ] add `` i` and a` `` text objexts for inner and arround backticks (if in a markdown file use exclude the filetype when doing inner selection by using treesitter)
  - [ ] try out https://github.com/MeanderingProgrammer/render-markdown.nvim
  - [ ] possibly replace the markdown viewer I am using
- [ ] Notetaking
  - [ ] add some lsp/plugin for notetaking compatible with obsidian or other some other note taking app
  - [ ] https://github.com/Feel-ix-343/markdown-oxide
  - [ ] daily notes
  - [ ] people references
  - [ ] note templates
- [ ] Notebook support
  - [ ] jupyter notebooks
- [ ] Debugging
  - [ ] I would like a way to convert old pdb files to portable format for older build processes
  - [ ] pid telescope picker for processes
- [ ] Heirline
  - [ ] Add a heirline component for python virtual environment. There is an example in the docs for venv-selector.nvim
  - [ ] Add a heirline component for harpoon
  - [ ] show workspace diagnostic counts in heirline
  - [ ] add a save and save all button to heirline so I know when I have unsaved buffers
- [ ] CLI
  - [ ] add ripgrep completion to my powershell profile https://github.com/BurntSushi/ripgrep/blob/master/FAQ.md#complete
  - [ ] Create a bash completion script for attaching zellij session (https://opensource.com/article/18/3/creating-bash-completion-script)
- [ ] Config
  - [x] add list of mason items to not install automatically
  - [ ] configure heirline nerdfonts to use ascii when nerd_font_enabled config value equals false
- [ ] Refactor
  - [ ] replace client.supports_method with client.server_capabilities
  - [ ] cleanup deprecated code
- [ ] Formatting
  - [ ] Formatting mode to only format git changes
  - [ ] add html formatter
- [ ] Movement/TextObjects keymaps
  - [ ] re-evaluate keymaps after upgrading to nightly based on keymaps added in https://github.com/neovim/neovim/commit/bb7604eddafb31cd38261a220243762ee013273a
  - [ ] add ]r and [r for navigating lsp references
  - [ ] add a substitute operation that uses text objects for pasting similar to [substitute.nvim](https://github.com/gbprod/substitute.nvim)
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
  - akinsho/toggleterm.nvim (replace with custom code)
  - iamcco/markdown-preview.nvim (replace with maybe my own version)
  - nvim-tree/nvim-web-devicons (replace with echasnovski/mini.icons)
  - WhoIsSethDaniel/mason-tool-installer.nvim (replace with custom code)

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
- https://github.com/kamalsacranie/nvim-mapper
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
