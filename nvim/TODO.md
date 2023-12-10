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
- to diff navigation with `[c` and `]c` dot-repeatable
- fix my Git commit remap to start cursor at top of the buffer
- fix lsp progress info from getting visually stuck (seems to happen either when using diffview or Git commit)
- lookinto functions from cmp_actions from lsp-zero

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


Interesting Articles/Posts:
- https://gist.github.com/lucasecdb/2baf6d328a10d7fea9ec085d868923a0
- [Find and replace custom keymaps](https://www.reddit.com/r/neovim/comments/18dvpe1/wanted_to_share_a_small_and_simple_mapping_for/?utm_medium=android_app&utm_source=share)
- [Moving text blocks plugins](https://www.reddit.com/r/neovim/comments/18dk9bp/alternative_to_vimtextmanip_plugin_move_selected/?utm_medium=android_app&utm_source=share)
- [Autorename a pair of tags](https://www.reddit.com/r/neovim/comments/18dpoq2/for_people_using_a_tag_autorename_plugin_such_as/?utm_medium=android_app&utm_source=share)
Interesting dotfiles:
- https://github.com/NormTurtle/Windots/blob/main/vi/init.lua


lookinto functions from lsp-zero
```lua
function M.nvim_workspace(opts)
    local runtime_path = vim.split(package.path, ';')
    table.insert(runtime_path, 'lua/?.lua')
    table.insert(runtime_path, 'lua/?/init.lua')

    local config = {
        settings = {
            Lua = {
                -- Disable telemetry
                telemetry = { enable = false },
                runtime = {
                    -- Tell the language server which version of Lua you're using
                    -- (most likely LuaJIT in the case of Neovim)
                    version = 'LuaJIT',
                    path = runtime_path,
                },
                diagnostics = {
                    -- Get the language server to recognize the `vim` global
                    globals = { 'vim' },
                },
                workspace = {
                    checkThirdParty = false,
                    library = {
                        -- Make the server aware of Neovim runtime files
                        vim.fn.expand('$VIMRUNTIME/lua'),
                        vim.fn.stdpath('config') .. '/lua',
                    },
                },
            },
        },
    }

    return vim.tbl_deep_extend('force', config, opts or {})
end
```
