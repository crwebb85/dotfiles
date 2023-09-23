local init_group = 'init'

vim.api.nvim_create_augroup(init_group, {clear = true})
vim.api.nvim_create_autocmd('TextYankPost', {group = init_group, callback = function() vim.highlight.on_yank() end })

