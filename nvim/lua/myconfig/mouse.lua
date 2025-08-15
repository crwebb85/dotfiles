vim.cmd.aunmenu([[PopUp.How-to\ disable\ mouse]])
vim.cmd.amenu([[PopUp.:Inspect <Cmd>Inspect<CR>]])
vim.cmd.amenu([[PopUp.:Telescope <Cmd>Telescope<CR>]])
vim.cmd.amenu([[PopUp.Code\ action <Cmd>lua vim.lsp.buf.code_action()<CR>]])
vim.cmd.amenu([[PopUp.LSP\ Hover <Cmd>lua vim.lsp.buf.hover()<CR>]])
vim.cmd.amenu(
    [[PopUp.LSP\ Signature <Cmd>lua vim.lsp.buf.signature_help()<CR>]]
)
vim.cmd.amenu(
    [[PopUp.LSP\ Goto\ Type\ Definition <Cmd>lua vim.lsp.buf.type_definition()<CR>]]
)
