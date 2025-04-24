local temp_path = vim.fn.stdpath('cache')
local function make_cmd()
    local data_path = vim.fn.stdpath('data')
    if data_path == nil then
        error('data path was nil but a string was expected')
    elseif type(data_path) == 'table' then
        error('data path was an array but a string was expected')
    end

    local bundle_path = vim.fs.joinpath(
        data_path,
        'mason',
        'packages',
        'powershell-editor-services'
    )
    local start_ps1_script_path = vim.fs.joinpath(
        bundle_path,
        'PowerShellEditorServices',
        'Start-EditorServices.ps1'
    )
    local command_fmt =
        [[& '%s' -BundledModulesPath '%s' -LogPath '%s/powershell_es.log' -SessionDetailsPath '%s/powershell_es.session.json' -FeatureFlags @() -AdditionalModules @() -HostName nvim -HostProfileId 0 -HostVersion 1.0.0 -Stdio -LogLevel Normal]]
    local command = command_fmt:format(
        start_ps1_script_path,
        bundle_path,
        temp_path,
        temp_path
    )
    return { 'pwsh', '-NoLogo', '-NoProfile', '-Command', command }
end

return {
    cmd = make_cmd(),
    filetypes = { 'ps1', 'psm1', 'psd1' },
    settings = { powershell = { codeFormatting = { Preset = 'OTBS' } } },
    init_options = {
        enableProfileLoading = false, --TODO see if this still disables profile loading
    },
    root_markers = { 'PSScriptAnalyzerSettings.psd1', '.git' },
    -- single_file_support = true, --TODO Figure out single file support
}
