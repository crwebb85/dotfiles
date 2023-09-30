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

-- Nearly the same keymaps
-- TODO determine which I like better
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- don't override paste buffer with the replaced text
-- when pasting over text
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Delete to the void register
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])


-- Undo Mistakes --
vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)


-- Other --
-- Select the last changed text or the text that was just pasted (does not work for multilined spaces)
vim.keymap.set('n', 'gp', '`[v`]')

-- Remap key to enter visual block mode so it doesn't interfere with pasting shortcut
vim.keymap.set('n', '<A-v>', '<C-V>')

-- Pull up netrw file explorer
vim.keymap.set("n", "<leader>fv", vim.cmd.Ex)

-- Move highlighted lines up and down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Move next line to the end of the current line
-- but without moving the cursor to the end of the line
vim.keymap.set("n", "J", "mzJ`z")

-- Page down or up but keep cursor in the middle of the page
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Go to next/previous search term
-- but keep cursor in the middle of page
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Disable the "execute last macro" shortcut
--TODO detemine if I want this
vim.keymap.set("n", "Q", "<nop>")

-- Format buffer
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

-- Quick fix navigation
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- Find and replace word cursor is on
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Make file executeable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
