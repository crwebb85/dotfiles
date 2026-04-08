local apex_jar_path = vim.fs.joinpath(
    require('myconfig.utils.path').get_mason_base_path(),
    'share',
    'apex-language-server',
    'apex-jorje-lsp.jar'
)

---@type vim.lsp.Config
return {
    apex_jar_path = apex_jar_path,
}
