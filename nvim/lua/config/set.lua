-------------------------------------------------------------------------------
--- Look and feel
vim.opt.title = true
vim.opt.titlestring = [[%t – %{fnamemodify(getcwd(), ':t')}]]
vim.opt.colorcolumn = '80'
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.wrap = false

vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.isfname:append('@-@')

-------------------------------------------------------------------------------
--- Performance
vim.opt.lazyredraw = true -- redraw only when required (will lazily redraw during macros)
vim.opt.updatetime = 50

-------------------------------------------------------------------------------
--- Tabs
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-------------------------------------------------------------------------------
--- Spell
vim.opt.spell = true
vim.opt.spelllang = 'en_us'
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
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

-------------------------------------------------------------------------------
--- Folding
vim.opt.foldcolumn = '1'
vim.opt.foldmethod = 'expr'
-- TODO fallback to different folding expr when treesitter folding is not available
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
-- Removing the below options prevent the cwd directory being stored in the view file which
-- as a results prevents it from changing on loading the view
vim.opt.viewoptions:remove('curdir')
-- Folds nested beyond foldlevelstart will start out closed
vim.opt.foldlevelstart = 3

-------------------------------------------------------------------------------
--- Completion menu
vim.opt.pumheight = 15 -- limits the size of the completion menu to only show 15 items at a time
vim.opt.pumblend = 15 -- makes the completion menu slightly transparent

-------------------------------------------------------------------------------
--- Search and replace
vim.opt.inccommand = 'split' -- shows search in replace changes in a preview window
vim.opt.hlsearch = false
vim.opt.incsearch = true

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
vim.cmd([[ set errorformat+=%f:\ %tarning\ %m ]])

-------------------------------------------------------------------------------
--- Terminal
vim.opt.termguicolors = true

if require('utils.platform').is.win then
    vim.opt.shell = vim.fn.executable('pwsh') == 1 and 'pwsh' or 'powershell'
    vim.opt.shellcmdflag =
        '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::Default;'
    vim.opt.shellredir = '-RedirectStandardOutput %s -NoNewWindow -Wait'
    vim.opt.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
    vim.opt.shellquote = ''
    vim.opt.shellxquote = ''
end
