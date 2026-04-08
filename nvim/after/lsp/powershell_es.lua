local bundle_path = vim.fs.joinpath(
    require('myconfig.utils.path').get_mason_base_path(),
    'packages',
    'powershell-editor-services'
)

---@type vim.lsp.Config
return {
    bundle_path = bundle_path,
}
