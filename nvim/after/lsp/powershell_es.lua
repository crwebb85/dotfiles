local function get_bundle_path()
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
    return bundle_path
end
return {
    bundle_path = get_bundle_path(),
}
