local M = {}

local parsers = require('nvim-treesitter.parsers')
local install = require('nvim-treesitter.install')
local config = require('nvim-treesitter.config')
local util = require('nvim-treesitter.util')
local a = require('nvim-treesitter.async')

---Get the information about the installed parser
---
---Copied from https://github.com/nvim-treesitter/nvim-treesitter/blob/7aa24acae3a288e442e06928171f360bbdf75ba4/lua/nvim-treesitter/install.lua?plain=1#L118-L129
---because I needed this private function exposed
---@param lang string
---@return InstallInfo?
local function get_parser_install_info(lang)
    local parser_config = parsers[lang]

    if not parser_config then
        vim.notify(
            string.format('Parser not available for language "%s"', lang),
            vim.log.levels.ERROR
        )
        return
    end

    return parser_config.install_info
end

---Gets the revision number of the installed parser
---
---Copied from https://github.com/nvim-treesitter/nvim-treesitter/blob/7aa24acae3a288e442e06928171f360bbdf75ba4/lua/nvim-treesitter/install.lua?plain=1#L137-L142
---because I needed this private function exposed
---@param lang string
---@return string?
local function get_installed_revision(lang)
    local lang_file = vim.fs.joinpath(
        config.get_install_dir('parser-info'),
        lang .. '.revision'
    )

    return util.read_file(lang_file)
end

---Checks if the parser for the language needs to be updated
---
---Copied from https://github.com/nvim-treesitter/nvim-treesitter/blob/7aa24acae3a288e442e06928171f360bbdf75ba4/lua/nvim-treesitter/install.lua?plain=1#L144-L158
---because I needed this private function exposed
---
---@param lang string
---@return boolean
local function needs_update(lang)
    local info = get_parser_install_info(lang)
    if info and info.revision then
        return info.revision ~= get_installed_revision(lang)
    end

    -- No revision. Check the queries link to the same place

    local queries = vim.fs.joinpath(config.get_install_dir('queries'), lang)
    local queries_src = install.get_package_path('runtime', 'queries', lang)

    return vim.uv.fs_realpath(queries) ~= vim.uv.fs_realpath(queries_src)
end

local function get_installed()
    local installed = require('nvim-treesitter').get_installed()
    return vim.tbl_filter(function(value)
        -- Filter out items that look like 'vim.so7', 'json.so4', 'hurl.so1', 'html.so1', 'c.so4', 'python.so1'
        -- I think they might be the result of temporary files left over by the compiler
        return string.find(value, '%.so%d') == nil
    end, installed)
end

---Get the list of language names for the installed parsers that are outdated
---@return string[]
function M.get_outdated()
    local langs = {}
    local installed = get_installed()
    for _, lang in ipairs(installed) do
        if needs_update(lang) then table.insert(langs, lang) end
    end
    return langs
end

---Get the list of language names that do not have a parser installed for the list
---of parsers in ensure_installed
---
---@param ensure_installed string[]
---@return string[] parsers that have not yet been installed
function M.get_uninstalled(ensure_installed)
    local installed_parsers = get_installed()
    local installed_parsers_set =
        require('myconfig.utils.datastructure').dumb_set(installed_parsers)
    local parsers_to_install = {}
    for _, parser_name in ipairs(ensure_installed) do
        if installed_parsers_set[parser_name] == nil then
            table.insert(parsers_to_install, parser_name)
        end
    end
    return parsers_to_install
end

function M.print_important_paths_for_debuging_treesitter()
    vim.notify(
        vim.inspect({
            revisions = require('nvim-treesitter.config').get_install_dir(
                'parser-info'
            ),
            nvim_treesitter_queries = require('nvim-treesitter.config').get_install_dir(
                'queries'
            ),
            nvim_treesitter_install = require('nvim-treesitter.install').get_package_path(
                'runtime',
                'queries'
            ),
            nvim_treesitter_parsers = require('nvim-treesitter.config').get_install_dir(
                'parser'
            ),
        }),
        vim.log.levels.INFO
    )
end

function M.set_jsonc_parser_to_be_json_parser()
    -- Important: You would think if I set the jsonc parser equal to the json
    -- parser I wouldn't need to do it in the User autocmd but for some reason
    -- not having the autocmd causes the jsonc parser to never be installed however
    -- I also need to set jsonc value before my code that checks if parsers are installed
    -- otherwise that code won't know where to look for it. As a result I need to set it
    -- in both places. This is weird but I don't care to investigate any farther
    require('nvim-treesitter.parsers').jsonc =
        require('nvim-treesitter.parsers').json
    vim.api.nvim_create_autocmd('User', {
        pattern = 'TSUpdate',
        callback = function()
            require('nvim-treesitter.parsers').jsonc =
                require('nvim-treesitter.parsers').json
        end,
    })
end

---Prompts the user if they would like to install the parsers that have not
---yet been installed from the ensure_installed list and prompts the user
---if they want to update installed parsers
---@param ensure_installed string[]
function M.prompt_install_missing_and_update(ensure_installed)
    local parsers_to_install = M.get_uninstalled(ensure_installed)

    local task_install = nil
    if #parsers_to_install > 0 then
        local install_prompt = string.format(
            'Parsers to install: %s \n Would you like to install them?',
            table.concat(parsers_to_install, ', ')
        )
        if vim.fn.confirm(install_prompt, '&yes\n&no', 2) == 1 then
            task_install = a.async(function()
                local install_message = string.format(
                    'Installing parsers %s',
                    table.concat(parsers_to_install, ', ')
                )
                vim.notify(install_message, vim.log.levels.INFO)
                a.await(require('nvim-treesitter').install(parsers_to_install))
            end)
        else
            vim.notify('Skipping installation of parsers', vim.log.levels.INFO)
        end
    end

    local parsers_to_update = M.get_outdated()

    local task_update = nil
    if #parsers_to_update > 0 then
        local update_prompt = string.format(
            'Parsers to update: %s \n Would you like to update them?',
            table.concat(parsers_to_update, ', ')
        )
        if vim.fn.confirm(update_prompt, '&yes\n&no', 2) == 1 then
            task_update = a.async(function()
                local update_message = string.format(
                    'Installing parsers %s',
                    table.concat(parsers_to_update, ', ')
                )
                vim.notify(update_message, vim.log.levels.INFO)
                a.await(require('nvim-treesitter').update(parsers_to_update))
            end)
        else
            vim.notify('Skipping parser updates', vim.log.levels.INFO)
        end
    end

    a.arun(function()
        if task_install ~= nil then
            do
                a.await(task_install)
            end
            vim.notify('Finished installing parsers', vim.log.levels.INFO)
        end
        if task_update ~= nil then
            do
                a.await(task_update)
            end
            vim.notify('Finished updating parsers', vim.log.levels.INFO)
        end

        -- Use the json parser for jsonc filetypes if it is installed
        local task_set_jsonc_parser = a.async(function()
            local json_parser_file = vim.fs.joinpath(
                require('nvim-treesitter.config').get_install_dir('parser'),
                'json.so'
            )
            if
                require('myconfig.utils.path').is_existing_file(
                    json_parser_file
                )
            then
                vim.treesitter.language.add(
                    'jsonc',
                    { path = json_parser_file, symbol_name = 'json' }
                )
            end
        end)
        do
            a.await(task_set_jsonc_parser)
        end
    end)
end

return M
