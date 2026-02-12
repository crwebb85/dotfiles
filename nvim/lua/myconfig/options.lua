local config = require('myconfig.config')
-------------------------------------------------------------------------------

--- Look and feel
if config.use_extui then require('vim._core.ui2').enable({ enable = true }) end
vim.o.title = true
vim.o.titlestring = [[%t – %{fnamemodify(getcwd(), ':t')}]]
vim.o.colorcolumn = '80'
vim.o.relativenumber = true
vim.o.number = true
vim.opt.wrap = false -- It seems that `vim.o.wrap = false` doesn't work for some reason
vim.o.winborder = 'rounded' -- border around floating windows
vim.opt.diffopt = {
    -- Diff settings
    -- mostly from https://www.reddit.com/r/neovim/comments/1k24zgk/comment/mnx3u34/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
    'internal',
    'filler',
    'closeoff',
    'context:12',
    'algorithm:histogram',
    'linematch:200',
    'indent-heuristic',
    'inline:char', -- From https://www.reddit.com/r/neovim/comments/1k24zgk/comment/moj5kxj/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
}

vim.o.scrolloff = 8
vim.o.signcolumn = 'yes'
vim.opt.isfname:append('@-@')

--I added the cursor blink to distinguish vim normal mode and terminal normal mode
--Note: I had tried setting the terminal cursor shape/color/blink instead but
--I couldn't get the terminal cursor inside a terminal buffer to blink since
--nvim isn't passing through the ansi codes.
vim.o.guicursor =
    'n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175'

-------------------------------------------------------------------------------
--- Keymap timeout
--- These settings were picked to play nice with which key
--- Note: I have an autocommand to temporarily disable timeout during macro
--- recording since I try to slowly and carefully type my macros
vim.o.timeout = true
vim.o.timeoutlen = 300

-------------------------------------------------------------------------------
--- Clipboard
vim.o.clipboard = 'unnamed,unnamedplus'

-------------------------------------------------------------------------------
--- Performance
-- TODO temporarily removing lazy redraw because redraws now clear the selection window
-- so it was preventing me seeing which code actions I could pick
-- vim.o.lazyredraw = true -- redraw only when required (will lazily redraw during macros)
vim.o.updatetime = 50

-------------------------------------------------------------------------------
--- Tabs
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true

-------------------------------------------------------------------------------
--- Spell
vim.o.spell = true
vim.o.spelllang = 'en_us'
-- vim.g.spellfile_URL = 'https://ftp.nluug.nl/vim/runtime/spell'
-- local function get_spellfile_path()
--     local path_utils = require('myconfig.utils.path')
--     local data_path = vim.fn.stdpath('config')
--     if type(data_path) ~= 'string' then
--         error('something went wrong getting the datapath')
--     end
--     local path = path_utils.concat({
--         data_path,
--         'spell',
--         -- 'en.utf-8.spl',
--         'en.utf-8.add',
--     })
--     -- path = vim.fn.expand(path)
--     vim.print(path)
--     return path
-- end
-- get_spellfile_path()
-- vim.opt.spellfile = get_spellfile_path()
-- vim.cmd([[set spellfile="]] .. get_spellfile_path() .. [["]])

-------------------------------------------------------------------------------
--- Disable/Enable backups
vim.o.swapfile = false
vim.o.backup = false
vim.o.undofile = true

-------------------------------------------------------------------------------
--- Folding
vim.o.foldcolumn = '1'
vim.o.foldmethod = 'expr'
-- TODO fallback to different folding expr when treesitter folding is not available
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
-- Removing the below options prevent the cwd directory being stored in the view file which
-- as a results prevents it from changing on loading the view
vim.opt.viewoptions:remove('curdir')
-- Folds nested beyond foldlevelstart will start out closed
vim.o.foldlevelstart = 3

-------------------------------------------------------------------------------
--- Completion menu
vim.o.pumheight = 15 -- limits the size of the completion menu to only show 15 items at a time
vim.o.pumblend = 15 -- makes the completion menu slightly transparent
-- vim.o.completeopt = 'menu,menuone,noinsert,noselect,fuzzy,preview'
vim.o.completeopt = 'menu,menuone,noinsert,noselect,fuzzy,popup'

-------------------------------------------------------------------------------
--- Ex command completion
vim.o.wildmode = 'noselect'
vim.o.wildoptions = 'pum,fuzzy' -- makes ex-command completion fuzzy matching

-------------------------------------------------------------------------------
--- Search and replace

vim.o.inccommand = 'split' -- shows search in replace changes in a preview window
vim.o.hlsearch = false
vim.o.incsearch = true
vim.o.wildignore =
    '*/node_modules/**,*/.git/**,*/venv/**,*/.venv/**,*/obj/**,*/bin/**'
vim.o.grepprg =
    [[rg --glob "!.git" --glob "!venv" --glob "!.venv" --no-heading --vimgrep --follow $*]]
-- [[rg --glob "!.git" --no-heading --vimgrep --follow $*]]
vim.opt.grepformat = vim.opt.grepformat ^ { '%f:%l:%c:%m' }

-------------------------------------------------------------------------------
--- Filetype overrides
vim.filetype.add({
    extension = {
        json = 'jsonc', -- This ensures that I can comment lines in json configuration files even if the extension is .json
        cls = 'apex', -- Detect salesforce apex files
    },
})

-------------------------------------------------------------------------------
--- Error formats
-- Error format for nuget restore:
-- helloworld\helloworld.csproj : warning NU1901: Package 'my.helloworld' 1.0.0 has a known low severity vulnerability
vim.opt.errorformat:append([[%f:\ %tarning\ %m]])
--dotnet tests often output filenames in the form C:\Users\crweb\Documents\poc\hello-world-dotnet-console\HelloWorldTestNunit\UnitTest1.cs:line 19
vim.opt.errorformat:append([[%f:line\ %l]])
-- vim.opt.errorformat:append([[%f:line\ %l:%c]])
-- vim.opt.errorformat:append([[Source:\ %f:%m]])
local is_nerd_font_enabled = require('myconfig.config').nerd_font_enabled
vim.diagnostic.config({
    float = { border = 'rounded' },
    signs = {

        text = {
            [vim.diagnostic.severity.INFO] = is_nerd_font_enabled and ''
                or 'I',
            [vim.diagnostic.severity.HINT] = is_nerd_font_enabled and ''
                or 'H',
            [vim.diagnostic.severity.WARN] = is_nerd_font_enabled and ''
                or 'W',
            [vim.diagnostic.severity.ERROR] = is_nerd_font_enabled and ''
                or 'E',
        },
    },
})

-------------------------------------------------------------------------------
--- Terminal
vim.o.termguicolors = true

if vim.fn.has('win32') == 1 then
    -- vim.o.shell = vim.fn.executable('pwsh') == 1 and 'pwsh' or 'powershell'
    -- vim.o.shellcmdflag =
    --     '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::Default;'
    -- vim.o.shellredir = '-RedirectStandardOutput %s -NoNewWindow -Wait'
    -- vim.o.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
    -- vim.o.shellquote = ''
    -- vim.o.shellxquote = ''

    -- https://github.com/neovim/neovim/issues/32921
    vim.o.shell = vim.fn.executable('pwsh') == 1 and 'pwsh' or 'powershell'
    vim.cmd([[
	   set noshelltemp
	   let &shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command '
	   let &shellcmdflag .= '[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();'
	   let &shellcmdflag .= '$PSDefaultParameterValues[''Out-File:Encoding'']=''utf8'';'
	   let &shellpipe  = '> %s 2>&1'
	   set shellquote= shellxquote=
    ]])
    if vim.fn.executable('pwsh') == 1 then
        vim.cmd([[
            let &shellcmdflag .= '$PSStyle.OutputRendering = ''PlainText'';'
            let $__SuppressAnsiEscapeSequences = 1
        ]])
    end
end

-------------------------------------------------------------------------------
-- Enable project local configuration using .nvim.lua file in the project directory
-- When the .nvim.lua file changes, you will be prompted to confirm if you trust the
-- file before it will be executed.
-- I also tested what happens when running `nvim --headless +qa` with a `.nvim.lua`
-- that hadn't yet been trusted and it didn't get hung up on the confimation and just
-- didn't run the `.nvim.lua` file. I'm glad it functions that way since I don't need
-- extra logic to turn off exrc for when running headless.
-- TODO
-- 1. Move this to the beginning of config
-- 2. Add user autocommands for when parts of my config are ran so that my
--  .nvim.lua file can pinpoint configuration overrid using autocommands to occur
--  at the exact spot it needs to run. (i.e. PreSet, Set, PreConfig, Config, PreLsp, PostLsp)
-- 3. Create a .nvim.lua skeleton file with the autocommands templates prepopulated
vim.o.exrc = true
