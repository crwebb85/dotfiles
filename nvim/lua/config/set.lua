vim.opt.title = true
vim.opt.titlestring = [[%t – %{fnamemodify(getcwd(), ':t')}]]

vim.opt.relativenumber = true
vim.opt.number = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

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

-- vim.g.spellfile_URL = 'https://ftp.nluug.nl/vim/runtime/spell'
vim.opt.spell = true
vim.opt.spelllang = 'en_us'
-- vim.opt.spellfile = get_spellfile_path()

-- vim.cmd([[set spellfile="]] .. get_spellfile_path() .. [["]])

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.isfname:append('@-@')

vim.opt.updatetime = 50

vim.opt.colorcolumn = '80'

vim.opt.foldcolumn = '1'
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

vim.opt.pumheight = 15 -- limits the size of the completion menu to only show 15 items at a time
vim.opt.pumblend = 15 -- makes the completion menu slightly transparent

vim.filetype.add({
    extension = {
        json = 'jsonc', -- This ensures that I can comment lines in json configuration files even if the extension is .json
    },
})

-- Error format for nuget restore:
-- helloworld\helloworld.csproj : warning NU1901: Package 'my.helloworld' 1.0.0 has a known low severity vulnerability
vim.cmd([[ set errorformat+=%f:\ %tarning\ %m ]])
