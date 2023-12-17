TODO:

- the plugin mini-pairs is decent but I find getting annoyed when a it creates a pair I didn't want
  - I think I will replace this plugin with snippets and nvim-surround
- telescope spell_suggest currently overrides my paste register with my misspelling. I don't want it to do this.
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

Cool plugins:

- https://github.com/rockerBOO/awesome-neovim
- https://github.com/carbon-steel/detour.nvim/tree/main
- https://github.com/rmagatti/auto-session
- https://github.com/kevinhwang91/nvim-bqf
- https://github.com/CKolkey/ts-node-action Toggle formatting of code snippets (this is not about typescript)
- https://github.com/sudormrfbin/cheatsheet.nvim
- https://github.com/soulis-1256/hoverhints.nvim
- https://github.com/rgroli/other.nvim
- https://github.com/jmederosalvarado/roslyn.nvim
- emmet lsp - https://www.reddit.com/r/neovim/comments/17v1678/comment/k97ggs2/?utm_source=share&utm_medium=web2x&context=3
- https://github.com/iamcco/markdown-preview.nvim
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

Look into:

- :h dap-launch.json
- https://editorconfig.org/ support for neovim
- [cmp sources](https://github.com/hrsh7th/nvim-cmp/wiki/List-of-sources)
- [nvim-dap extensions](https://github.com/mfussenegger/nvim-dap/wiki/Extensions)

Interesting Articles/Posts:

- https://gist.github.com/lucasecdb/2baf6d328a10d7fea9ec085d868923a0
- [Find and replace custom keymaps](https://www.reddit.com/r/neovim/comments/18dvpe1/wanted_to_share_a_small_and_simple_mapping_for/?utm_medium=android_app&utm_source=share)
- [Moving text blocks plugins](https://www.reddit.com/r/neovim/comments/18dk9bp/alternative_to_vimtextmanip_plugin_move_selected/?utm_medium=android_app&utm_source=share)
- [Autorename a pair of tags](https://www.reddit.com/r/neovim/comments/18dpoq2/for_people_using_a_tag_autorename_plugin_such_as/?utm_medium=android_app&utm_source=share)
- [Keymap discussion](https://www.reddit.com/r/neovim/comments/18jcj0q/any_advice_on_general_keymapping_methodologies/?utm_medium=android_app&utm_source=share)
- [Telescope and Trouble QuickFix list](https://www.reddit.com/r/neovim/comments/18iyev5/enhancing_telescope_workflow_sending_marked_files/?utm_medium=android_app&utm_source=share)
- [Spell check](https://www.reddit.com/r/neovim/comments/18id6uu/how_to_get_riddisable_spellcheck_lines_not_from/?utm_medium=android_app&utm_source=share)
- [Keymap remapping trick](https://www.reddit.com/r/neovim/comments/18ieoqq/comment/kdcta80/?utm_medium=android_app&utm_source=share&context=3)
- [Setup linting video](https://www.youtube.com/watch?v=ybUE4D80XSk)
- [Setup Linting article](https://www.josean.com/posts/neovim-linting-and-formatting)
- [Undo in insert mode](https://vi.stackexchange.com/questions/4556/undo-in-insert-mode)
- [Java setup discussion](https://www.reddit.com/r/neovim/comments/18hfkh2/nvimjava_brand_new_plugin_for_java_development/?utm_medium=android_app&utm_source=share)
- [Java setup discussion](https://www.reddit.com/r/neovim/comments/18g2jgr/having_the_worst_time_trying_to_use_jdtls/)
- [Java setup article](https://medium.com/@chrisatmachine/lunarvim-as-a-java-ide-da65c4a77fb4)
- [JSON schemas](https://www.arthurkoziel.com/json-schemas-in-neovim/)
- [Discussion of editting visual selection within temp buffer](https://www.reddit.com/r/neovim/comments/18dhi3g/looking_for_a_plugin_to_do_markdown_hoisting/?utm_source=share&utm_medium=web2x&context=3)
- [Understanding Neovim Playlist](https://www.youtube.com/watch?v=87AXw9Quy9U&list=PLx2ksyallYzW4WNYHD9xOFrPRYGlntAft)
- [Explanation for wierd lsp error](https://www.reddit.com/r/neovim/comments/18cb9d8/comment/kc9lre2/?utm_medium=android_app&utm_source=share&context=3)

dotfiles to look into:

- https://github.com/NormTurtle/Windots/blob/main/vi/init.lua
- https://www.reddit.com/r/neovim/comments/18ecn8o/share_noplugin_configs/?utm_medium=android_app&utm_source=share
- https://github.com/boydaihungst/.config/tree/master/lvim
- https://github.com/steveclarke/dotfiles
- https://github.com/albingroen/quick.nvim/blob/main/init.lua
- https://github.com/swaykh/dotfiles
- https://github.com/joao-lobao/nvim/tree/master/after/plugin/lsp
- https://github.com/gonstoll/dotfiles/tree/master/nvim/ftplugin
