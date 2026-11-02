local data_dir = require('myconfig.utils.path').get_nvim_data_dir()
local data_site_dir = vim.fs.joinpath(data_dir, 'site')

---Checks if the path is a loaded plugin path
---@param plugin_path string
---@return boolean
local function is_base_dev_plugin_path(plugin_path)
    local dev_plugin_dir = require('myconfig.config').dev_plugins_path
    local rel_dev_plugin_dir = vim.fs.relpath(dev_plugin_dir, plugin_path)
    if rel_dev_plugin_dir == nil then return false end
    local ok, err_or_plugin = pcall(
        vim.pack.get,
        --rel_dev_plugin_dir should just be the plugin name if it was in fact a plugin
        --else this will error and be caught by the pcall
        { rel_dev_plugin_dir },
        { info = false } --info needs to be false or this will be very slow
    )
    if not ok then return false end
    local plugin = err_or_plugin[1]
    return plugin and plugin.spec and plugin.spec.data and plugin.spec.data.dev
        or false
end

---Checks if the path is a loaded plugin path
---Note: returns false if this is a sub folder so that we can exclude after folders
---@param plugin_path string
---@return boolean
local function is_base_plugin_path(plugin_path)
    local plugin_dir = require('myconfig.utils.path').get_nvim_plugins_dir()

    local rel_plugin_dir = vim.fs.relpath(plugin_dir, plugin_path)

    if rel_plugin_dir == nil then return false end
    local ok, err_or_plugin = pcall(
        vim.pack.get,
        --rel_plugin_dir should just be the plugin name if it was in fact a plugin
        --else this will error and be caught by the pcall
        { rel_plugin_dir },
        { info = false } --info needs to be false or this will be very slow
    )
    if not ok then return false end
    local plugin = err_or_plugin[1]
    return plugin ~= nil
end

local function get_runtime_path_workspace_libraries_for_myconfig()
    -- filetype.lua	filetypes |new-filetype|
    -- autoload/	automatically loaded scripts |autoload-functions|
    -- colors/	color scheme files |:colorscheme|
    -- compiler/	compiler files |:compiler|
    -- doc/		documentation |write-local-help|
    -- ftplugin/	filetype plugins |write-filetype-plugin|
    -- indent/	indent scripts |indent-expression|
    -- keymap/	key mapping files |mbyte-keymap|
    -- lang/		menu translations |:menutrans|
    -- lsp/		LSP client configurations |lsp-config|
    -- lua/		|Lua| plugins
    -- menu.vim	GUI menus |menu.vim|
    -- pack/		packages |:packadd|
    -- parser/	|treesitter| syntax parsers
    -- plugin/	plugin scripts |write-plugin|
    -- queries/	|treesitter| queries
    -- rplugin/	|remote-plugin| scripts
    -- spell/	spell checking files |spell|
    -- syntax/	syntax files |mysyntaxfile|
    -- tutor/	tutorial files |:Tutor|
    local file_name_set = require('myconfig.utils.datastructure').dumb_set({
        'filetype.lua',
        'autoload',
        'colors',
        -- "compiler",
        -- "doc",
        'ftplugin',
        -- "indent",
        -- "keymap",
        -- "lang",
        'lsp',
        'lua',
        -- 'menu.vim',
        -- "pack",
        -- "parser",
        'plugin',
        -- "queries",
        'rplugin',
        -- "spell",
        'syntax',
        -- "tutor",
    })

    local expanded_runtime_paths = {}
    local base_runtime_paths = vim.api.nvim_get_runtime_file('', true)
    for _, path in ipairs(base_runtime_paths) do
        if path == data_site_dir then
            --filter out the site directory from the runtime paths
            --since having it would undo all the careful cleanup we are
            --about to do for plugin paths
        elseif path:match(vim.fn.stdpath('config') .. '/?a?f?t?e?r?') then
            --skip my config directory and my config's after directory
            --since those are not libraries but rather my actual config
            --TODO this match looks dumb and came from AI. I don't like it but
            --that cleanup if for another day xD!
        elseif is_base_plugin_path(path) or is_base_dev_plugin_path(path) then
            local child_paths =
                vim.fn.glob(vim.fs.joinpath(path, '/*'), false, true)
            for _, child_path in ipairs(child_paths) do
                local child_file_name = vim.fs.basename(child_path)
                if file_name_set[child_file_name] ~= nil then
                    table.insert(expanded_runtime_paths, child_path)
                end
            end
        else
            table.insert(expanded_runtime_paths, path)
        end
    end
    return expanded_runtime_paths
end

local function get_runtime_path_workspace_libraries_for_plugins()
    --TODO we really only need to include plugins if they are dependencies
    --of the plugin we are working on. Not sure the best way to handle
    --this.
    --
    -- We should include the nvim lua runtime
    -- We should include dependency plugins
    -- We should not include the plugin or other versions of it if the version running is different
    return get_runtime_path_workspace_libraries_for_myconfig()
end

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if not client or client.name ~= 'lua_ls' then return end

        local additional_config_settings = {}
        if client.root_dir == vim.fn.stdpath('config') then
            additional_config_settings = {
                Lua = {
                    diagnostics = {
                        globals = { 'vim' },
                    },
                    path = {
                        '?.lua',
                        '?/init.lua',
                        'lua/?.lua',
                        'lua/?/init.lua',
                    },
                    runtime = {
                        version = 'LuaJIT',
                    },
                    workspace = {
                        checkThirdParty = false,
                        library = get_runtime_path_workspace_libraries_for_myconfig(),
                    },
                },
            }
        elseif
                --Detect plugins
            vim.fs.relpath(
                    require('myconfig.utils.path').get_nvim_plugins_dir(),
                    client.root_dir
                )
                ~= nil
            --Most plugins end in .nvim so this hopefully will be a decent way to detect it
            --for plugins I'm developing/creating bug fixes for
            or require('myconfig.utils.misc').string_ends_with(
                client.root_dir,
                '.nvim'
            )
        then
            additional_config_settings = {
                Lua = {
                    diagnostics = {
                        globals = { 'vim' },
                    },
                    path = {
                        '?.lua',
                        '?/init.lua',
                        'lua/?.lua',
                        'lua/?/init.lua',
                    },
                    runtime = {
                        version = 'LuaJIT',
                    },
                    workspace = {
                        checkThirdParty = false,
                        library = get_runtime_path_workspace_libraries_for_plugins(),
                    },
                },
            }
        end

        client.settings = vim.tbl_deep_extend(
            'force',
            client.settings,
            additional_config_settings
        )

        client:notify(
            'workspace/didChangeConfiguration',
            { settings = client.settings }
        )
    end,
})

---@type vim.lsp.Config
return {

    ---@type lspconfig.settings.lua_ls
    settings = {
        Lua = {
            runtime = { version = 'LuaJIT' },
            path = {
                '?.lua',
                '?/init.lua',
                'lua/?.lua',
                'lua/?/init.lua',
            },
            hint = { enable = true },
        },
    },
}
