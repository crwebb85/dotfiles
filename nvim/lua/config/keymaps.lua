vim.g.mapleader = " "

-- Navigation --
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

local mark = require("harpoon.mark")
local ui = require("harpoon.ui")
vim.keymap.set("n", "<leader>a", mark.add_file)
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)
-- Protip: To reorder the entries in harpoon quick menu use `Vd` to cut the line and `P` to paste where you want it

-- Harpoon quick navigation
vim.keymap.set("n", "<leader>1", function() ui.nav_file(1) end)
vim.keymap.set("n", "<leader>2", function() ui.nav_file(2) end)
vim.keymap.set("n", "<leader>3", function() ui.nav_file(3) end)
vim.keymap.set("n", "<leader>4", function() ui.nav_file(4) end)


-- Clipboard --
-- Now the '+' register will copy to system clipboard using OSC52
vim.keymap.set('n', '<leader>c', '"+y')
vim.keymap.set('n', '<leader>cc', '"+yy')
vim.keymap.set('v', '<leader>c', '"+y')


-- Other --
-- Select the last changed text or the text that was just pasted (does not work for multilined spaces)
vim.keymap.set('n', 'gp', '`[v`]') 

-- Remap key to enter visual block mode so it doesn't interfere with pasting shortcut
vim.keymap.set('n', '<A-v>', '<C-V>')

