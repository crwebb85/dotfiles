-------------------------------------------------------------------------------
--- Look and feel
vim.o.title = true
vim.o.titlestring = [[%t – %{fnamemodify(getcwd(), ':t')}]]
vim.o.colorcolumn = '80'
vim.o.relativenumber = true
vim.o.number = true
vim.opt.wrap = false -- It seems that `vim.o.wrap = false` doesn't work for some reason

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
--- Clipboard
vim.o.clipboard = 'unnamed,unnamedplus'

-------------------------------------------------------------------------------
--- Performance
vim.o.lazyredraw = true -- redraw only when required (will lazily redraw during macros)
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
--     local path_utils = require('utils.path')
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

-------------------------------------------------------------------------------
--- Search and replace
vim.o.inccommand = 'split' -- shows search in replace changes in a preview window
vim.o.hlsearch = false
vim.o.incsearch = true

-------------------------------------------------------------------------------
--- Filetype overrides
vim.filetype.add({
    extension = {
        json = 'jsonc', -- This ensures that I can comment lines in json configuration files even if the extension is .json
    },
})

-------------------------------------------------------------------------------
--- Error formats
-- Error format for nuget restore:
-- helloworld\helloworld.csproj : warning NU1901: Package 'my.helloworld' 1.0.0 has a known low severity vulnerability
vim.opt.errorformat:append([[%f:\ %tarning\ %m]])

-------------------------------------------------------------------------------
--- Terminal
vim.o.termguicolors = true

if require('utils.platform').is.win then
    vim.o.shell = vim.fn.executable('pwsh') == 1 and 'pwsh' or 'powershell'
    vim.o.shellcmdflag =
        '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::Default;'
    vim.o.shellredir = '-RedirectStandardOutput %s -NoNewWindow -Wait'
    vim.o.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
    vim.o.shellquote = ''
    vim.o.shellxquote = ''
end
