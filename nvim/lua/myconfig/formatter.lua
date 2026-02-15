local M = {}

local P = {}

---@alias LspFormatStrategyEnum "NEVER" | "FALLBACK" | "PREFER" | "FIRST" | "LAST"

local LspFormatStrategyEnums = {
    NEVER = 'NEVER',
    FALLBACK = 'FALLBACK',
    PREFER = 'PREFER',
    FIRST = 'FIRST',
    LAST = 'LAST',
}
P.LspFormatStrategyEnums = LspFormatStrategyEnums

---@class FormatterState
---@field default_formatters {[string]:string[]} The map of filetypes to list of formatters that are default for the project. Used to for setting things back to default.
---@field project_formatters {[string]:string[]} The map of filetypes to list of formatters that are configured for the project
---@field project_disabled_formatters {[string]:boolean} map formatters disabled for the project
---@field additional_formatters {[string]:string[]} A map of filetypes to list of formatters that are not enabled by default but can be manually added with a command
---@field lsp_format_strategy_for_filetype {[string]:LspFormatStrategyEnum} A map of lsp format strategies for a filetype. The default strategy will always be "FALLBACK"
---@field is_project_autoformat_disabled boolean The property to determine if autoformat is disabled project-wide
---@field formatter_timeout_milliseconds integer The property to determine how long the formatter should run before switching to running after save
---@field format_after_save_filetypes {[string]:boolean} lookup table for filetypes to format after save asyncronously

---Setups the default settings for the formatter
---@return FormatterState
local function setup()
    --- The default timeout for how long the formatter should run before switching to running
    --- after save
    local DEFUALT_FORMATTING_TIMEOUT = 500

    ---@type { [string]: string[] }
    local default_formatters = {
        lua = { 'stylua' },
        python = { 'ruff' },
        typescript = { 'prettierd' },
        javascript = { 'prettierd' },
        typescriptreact = { 'prettierd' },
        javascriptreact = { 'prettierd' },
        css = { 'prettierd' },
        yaml = { 'prettierd' },
        json = { 'prettierd' },
        jsonc = { 'prettierd' },
        json5 = { 'prettierd' },
        ansible = { 'prettierd' },
        --use `:set ft=yaml.ansible` to get treesitter highlights for yaml,
        -- ansible lsp, and prettier formatting TODO set up autocmd to detect ansible
        ['yaml.ansible'] = { 'prettierd' },
        -- "inject" is a "special" formatter from conform.nvim, which
        -- formats treesitter-injected code. For example, conform.nvim will format
        -- any python codeblocks inside a markdown file.
        -- **Important** using prettier not prettierd because prettierd some
        -- reason can't handle frontmatter yaml at the top of a markdown file
        -- this may change in the future
        markdown = { 'prettier', 'injected' },
        xml = { 'prettierxml' },
        graphql = { 'prettierd' },
        sh = { 'shfmt' },
        c = { 'clang-format' },
    }

    ---@type FormatterState
    local state = {
        default_formatters = default_formatters,
        project_formatters = vim.deepcopy(default_formatters),
        project_disabled_formatters = {},
        additional_formatters = { --TODO add getter and setter
            xml = { 'xmlformat' },
        },
        lsp_format_strategy_for_filetype = {},
        is_project_autoformat_disabled = false,
        formatter_timeout_milliseconds = DEFUALT_FORMATTING_TIMEOUT,
        format_after_save_filetypes = {},
    }

    return state
end

---@type FormatterState
local config = setup()

-------------------------------------------------------------------------------

---Gets the project formatters (all items in this list will display in heirline even if disabled)
---@param filetype string
---@return string[] formatters for the project and filetype.
function P.get_project_formatters(filetype)
    if filetype == nil then return {} end
    local formatters = config.project_formatters[filetype]
    if formatters == nil then return {} end
    return formatters
end

---Sets the formatters for the filetype (all items in this list will display in heirline even if disabled)
---@param filetype string
---@param formatters string[]
function P.set_project_formatters(filetype, formatters)
    if #formatters == 0 then
        config.project_formatters = {}
    else
        config.project_formatters[filetype] = vim.deepcopy(formatters)
    end
    vim.api.nvim_exec_autocmds(
        'User',
        -- this change effects all buffers of the filetype so we will scope
        -- pattern to Project
        { pattern = 'FormatterChange.FormatterChange.Project' }
    )
end

---Sets the project disabled formatters
---@param formatters string[]
function P.set_project_disabled_formatters(formatters)
    if #formatters == 0 then
        config.project_disabled_formatters = {}
    else
        config.project_disabled_formatters = {}
        for _, formatter_name in ipairs(formatters) do
            config.project_disabled_formatters[formatter_name] = true
        end
    end
    -- Im not bothering to check if the new value has actually changed before
    -- trigering the user autocmd
    vim.api.nvim_exec_autocmds(
        'User',
        { pattern = 'FormatterChange.DisabledFormatters.Project' }
    )
end

---Gets the set of project disabled formatters
---@return {[string]:boolean} project_disabled_formatters_set
function P.get_project_disabled_formatters_set()
    return vim.deepcopy(config.project_disabled_formatters)
end

---Sets the buffer property disabled_formatters
---@param formatters string[]
---@param bufnr? number the buffer number
function P.set_buffer_disabled_formatters(formatters, bufnr)
    if bufnr == nil then bufnr = vim.api.nvim_get_current_buf() end
    if #formatters == 0 then
        vim.b[bufnr].disabled_formatters = nil
    else
        local disabled_formatters = {}
        for _, formatter_name in ipairs(formatters) do
            disabled_formatters[formatter_name] = true
        end
        vim.b[bufnr].disabled_formatters = disabled_formatters
    end

    -- Im not bothering to check if the new value has actually changed before
    -- trigering the user autocmd
    vim.api.nvim_exec_autocmds(
        'User',
        { pattern = 'FormatterChange.DisabledFormatters.Buffer' }
    )
end

---Gets the buffer property disabled_formatters
---@param bufnr? number the buffer number
---@return table<string, boolean> buffer_disabled_formatters_set
function P.get_buffer_disabled_formatters_set(bufnr)
    if bufnr == nil then bufnr = vim.api.nvim_get_current_buf() end
    if vim.b[bufnr].disabled_formatters == nil then return {} end
    return vim.b[bufnr].disabled_formatters
end

---Sets the lsp format strategy for the filetype
---@param filetype string
---@param lsp_format_strategy LspFormatStrategyEnum
function P.set_filetype_lsp_format_strategy(filetype, lsp_format_strategy)
    local old_format_strategy = P.get_filetype_lsp_format_strategy(filetype)
    config.lsp_format_strategy_for_filetype[filetype] = lsp_format_strategy
    if old_format_strategy ~= P.get_filetype_lsp_format_strategy(filetype) then
        vim.api.nvim_exec_autocmds(
            'User',
            -- this change effects all buffers of the filetype so we will scope
            -- pattern to Project
            { pattern = 'FormatterChange.LspFormatStrategy.Project' }
        )
    end
end

---Gets the lsp format strategy for the filetype
---@param filetype? string
---@return LspFormatStrategyEnum lsp_format_strategy for the filetype. Defaults to the enum "DEFAULT"
function P.get_filetype_lsp_format_strategy(filetype)
    if filetype == nil then return LspFormatStrategyEnums.FALLBACK end
    local lsp_format_strategy =
        config.lsp_format_strategy_for_filetype[filetype]
    if lsp_format_strategy == nil then
        return LspFormatStrategyEnums.FALLBACK
    end
    return lsp_format_strategy
end

---Gets a copy of the lsp format strategy for the filetype
---@return {[string]: LspFormatStrategyEnum}
function P.get_filetype_lsp_format_strategy_map()
    return vim.deepcopy(config.lsp_format_strategy_for_filetype)
end

---Sets the lsp format strategy for the buffer
---@param lsp_format_strategy LspFormatStrategyEnum
---@param bufnr? number the buffer number. Defaults to buffer 0.
function P.set_buffer_lsp_format_strategy(lsp_format_strategy, bufnr)
    if bufnr == nil then bufnr = vim.api.nvim_get_current_buf() end
    local old_format_strategy = P.get_buffer_lsp_format_strategy(bufnr)
    vim.b[bufnr].buffer_lsp_format_strategy = lsp_format_strategy
    if old_format_strategy ~= P.get_buffer_lsp_format_strategy(bufnr) then
        vim.api.nvim_exec_autocmds(
            'User',
            { pattern = 'FormatterChange.LspFormatStrategy.Buffer' }
        )
    end
end

---Gets the lsp format strategy for the buffer
---@param bufnr? number the buffer number. Defaults to buffer 0
---@return LspFormatStrategyEnum lsp_format_strategy for the buffer. Defaults to the enum "DEFAULT"
function P.get_buffer_lsp_format_strategy(bufnr)
    if bufnr == nil then bufnr = vim.api.nvim_get_current_buf() end
    if vim.b[bufnr].buffer_lsp_format_strategy == nil then
        return LspFormatStrategyEnums.FALLBACK
    end
    return vim.b[bufnr].buffer_lsp_format_strategy
end

---Getter for the project property is_project_autoformat_disabled
---@return boolean
function P.is_project_autoformat_disabled()
    return config.is_project_autoformat_disabled
end

---Setter for the project property is_project_autoformat_disabled
---Used to disable/enable autoformatting project wide
---@param is_autoformat_disabled boolean
function P.set_project_autoformat_disabled(is_autoformat_disabled)
    local old_is_autoformat_disabled = config.is_project_autoformat_disabled
    config.is_project_autoformat_disabled = is_autoformat_disabled
    if old_is_autoformat_disabled ~= config.is_project_autoformat_disabled then
        vim.api.nvim_exec_autocmds(
            'User',
            { pattern = 'FormatterChange.AutoFormat.Project' }
        )
    end
end

---Getter for the buffer property is_buffer_autoformat_disabled
---@param bufnr? number
---@return boolean true if autoformatting is disabled on the buffer
function P.is_buffer_autoformat_disabled(bufnr)
    if bufnr == nil then bufnr = vim.api.nvim_get_current_buf() end
    if vim.b[bufnr].is_buffer_autoformat_disabled == nil then return false end
    return vim.b[bufnr].is_buffer_autoformat_disabled
end

---Setter for the buffer property is_buffer_autoformat_disabled
---@param is_autoformat_disabled boolean
---@param bufnr? number
function P.set_buffer_autoformat_disabled(is_autoformat_disabled, bufnr)
    if bufnr == nil then bufnr = vim.api.nvim_get_current_buf() end
    local old_is_autoformat_disabled = P.is_buffer_autoformat_disabled(bufnr)
    vim.b[bufnr].is_buffer_autoformat_disabled = is_autoformat_disabled

    if old_is_autoformat_disabled ~= P.is_buffer_autoformat_disabled(bufnr) then
        vim.api.nvim_exec_autocmds(
            'User',
            { pattern = 'FormatterChange.AutoFormat.Buffer' }
        )
    end
end

---Getter for the formatter timeout in milliseconds
---@return integer timeout value in milliseconds.Defaults to 500 milliseconds.
function P.get_formatting_timeout() return config.formatter_timeout_milliseconds end

---Sets the formatting timeout
---@param time_milliseconds integer the time in milliseconds before the formatter times out
function P.set_formatting_timeout(time_milliseconds)
    if time_milliseconds <= 0 then
        error(
            'Cannot set formatting timeout to a value less than or equal to zero',
            2
        )
    end
    config.formatter_timeout_milliseconds = time_milliseconds
end

---Setter for the filetypes to format after save
---@param filetype string
---@param is_format_after_save_enabled boolean
function P.set_format_after_save(filetype, is_format_after_save_enabled)
    local old_is_format_after_save_enabled =
        P.is_format_after_save_enabled(filetype)
    config.format_after_save_filetypes[filetype] = is_format_after_save_enabled
    if old_is_format_after_save_enabled ~= is_format_after_save_enabled then
        vim.api.nvim_exec_autocmds(
            'User',
            -- this change effects all buffers of the filetype so we will scope
            -- pattern to Project
            { pattern = 'FormatterChange.SavingFormatStrategy.Project' }
        )
    end
end

---Getter for the property is_format_after_save_enabled
---@param filetype string
---@return boolean
function P.is_format_after_save_enabled(filetype)
    if
        filetype == nil
        or config.format_after_save_filetypes[filetype] == nil
    then
        return false
    end
    return config.format_after_save_filetypes[filetype]
end

--List of old User commands patterns
--
-- FormatterChange.DisabledFormatters.Buffer
-- FormatterChange.DisabledFormatters.Project
--
-- FormatterChange.AutoFormat.Project
-- FormatterChange.AutoFormat.Buffer
--
-- FormatterChange.SavingFormatStrategy.Project
--
-- FormatterChange.LspFormatStrategy.Project
-- FormatterChange.LspFormatStrategy.Buffer
--
-- FormatterChange.Lsp.Buffer
--
-- FormatterChange.FileType.Buffer

--Need to proxy the LspAttach and LspDetach user events so that my statusline
--component can pattern match on the User pattern (I was having preformance
--issues without a good pattern)
vim.api.nvim_create_autocmd({ 'LspAttach', 'LspDetach' }, {
    group = vim.api.nvim_create_augroup(
        'trigger_formatter_update_user_command',
        { clear = true }
    ),
    callback = function(_)
        vim.api.nvim_exec_autocmds(
            'User',
            { pattern = 'FormatterChange.Lsp.Buffer' }
        )
    end,
})
--Need to proxy the FileType event as user event so that my statusline component can pattern
--match on the User pattern (I was having preformance issues without a good pattern)
vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = vim.api.nvim_create_augroup(
        'trigger_formatter_update_user_command',
        { clear = true }
    ),
    callback = function(_)
        vim.api.nvim_exec_autocmds(
            'User',
            { pattern = 'FormatterChange.FileType.Buffer' }
        )
    end,
})

---Gets the formatting information about the buffer for debugging
---@param bufnr? integer
---@return table
function M.get_buffer_formatting_details(bufnr)
    if bufnr == nil then bufnr = vim.api.nvim_get_current_buf() end
    local filetype = vim.bo[bufnr].filetype
    return {
        is_buffer_autoformat_disabled = P.is_buffer_autoformat_disabled(bufnr),
        is_project_autoformat_disabled = P.is_project_autoformat_disabled(),
        is_format_after_save_enabled = P.is_format_after_save_enabled(filetype),
        formatting_timeout_ms = P.get_formatting_timeout(),
        buffer_disabled_formatters = P.get_buffer_disabled_formatters_set(
            bufnr
        ),
        project_disabled_formatters = P.get_project_disabled_formatters_set(),
        buffer_lsp_format_strategy = P.get_buffer_lsp_format_strategy(bufnr),
        lsp_format_for_filetype = P.get_filetype_lsp_format_strategy(filetype),
        buffer_conform_lsp_fallback_value = M.determine_conform_lsp_fallback(
            bufnr
        ),
        lsp_format_for_filetype_map = P.get_filetype_lsp_format_strategy_map(),
        buffer_formatters = M.get_buffer_enabled_formatter_list(bufnr),
    }
end

---Gets the list of enabled formatters to pass to conform
---@param bufnr? integer
---@return string[] list of formatters
function M.get_buffer_enabled_formatter_list(bufnr)
    if bufnr == nil then bufnr = vim.api.nvim_get_current_buf() end
    local filetype = vim.bo[bufnr].filetype
    local project_formatters = P.get_project_formatters(filetype)
    local project_disabled_formatters_set =
        P.get_project_disabled_formatters_set()
    local buffer_disabled_formatters_set =
        P.get_buffer_disabled_formatters_set()

    local formatters = {}
    for _, formatter in ipairs(project_formatters) do
        if
            not project_disabled_formatters_set[formatter]
            and not buffer_disabled_formatters_set[formatter]
        then
            table.insert(formatters, formatter)
        end
    end
    return formatters
end

---@class (exact) LspFormatterDetails
---@field name string
---@field client_id integer

---@param bufnr? integer the buffer number. Defaults to buffer 0.
---@return LspFormatterDetails[] lsp_formatter_details that can be used for the buffer
function M.get_buffer_lsp_formatters(bufnr)
    ---@type LspFormatterDetails[]
    local lsp_formatters = {}
    if bufnr == nil then bufnr = vim.api.nvim_get_current_buf() end
    for _, lsp_client in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if
            lsp_client:supports_method(
                vim.lsp.protocol.Methods.textDocument_formatting
            )
        then
            local lsp_formatter_details = {
                name = lsp_client.name,
                client_id = lsp_client.id,
            }
            table.insert(lsp_formatters, lsp_formatter_details)
        end
    end
    return lsp_formatters
end

---Determines the lsp_fallback value to use for Conform plugin's lsp_fallback option
---based on my formatting properties. Prioritizes the buffer settings over filetype settings
---@param bufnr uinteger?
---@return conform.LspFormatOpts
function M.determine_conform_lsp_fallback(bufnr)
    local lsp_format_strategy = P.get_buffer_lsp_format_strategy(bufnr)
    if lsp_format_strategy == LspFormatStrategyEnums.FALLBACK then
        local filetype = vim.bo[bufnr].filetype
        if filetype == nil then
            lsp_format_strategy = LspFormatStrategyEnums.FALLBACK
        else
            lsp_format_strategy = P.get_filetype_lsp_format_strategy(filetype)
        end
    end

    if lsp_format_strategy == LspFormatStrategyEnums.FALLBACK then
        return 'fallback'
    elseif lsp_format_strategy == LspFormatStrategyEnums.NEVER then
        return 'never'
    elseif lsp_format_strategy == LspFormatStrategyEnums.FIRST then
        return 'first'
    elseif lsp_format_strategy == LspFormatStrategyEnums.LAST then
        return 'last'
    else
        return 'fallback'
    end
end

---@param bufnr? integer the buffer number. Defaults to buffer 0.
---@return conform.FormatOpts
function M.construct_conform_formatting_params(bufnr)
    if bufnr == nil then bufnr = vim.api.nvim_get_current_buf() end
    local project_disabled_formatters = P.get_project_disabled_formatters_set()
    local buffer_disabled_formatters =
        P.get_buffer_disabled_formatters_set(bufnr)
    if
        next(project_disabled_formatters) ~= nil
        or next(buffer_disabled_formatters) ~= nil
    then
        local formatter_names = M.get_buffer_enabled_formatter_list(bufnr)

        return {
            timeout_ms = P.get_formatting_timeout(),
            formatters = formatter_names,
            lsp_format = M.determine_conform_lsp_fallback(bufnr),
        }
    end
    return {
        timeout_ms = P.get_formatting_timeout(),
        lsp_format = M.determine_conform_lsp_fallback(bufnr),
    }
end

---Used by formatter to auto format files on save
---If auto formatting is disabled for the project or the buffer then this function
---will skip formating the buffer
---@param bufnr? integer the buffer number to autoformat. Defaults to buffer 0
---@return conform.FormatOpts?
function M.construct_conform_autoformat_params(bufnr)
    if bufnr == nil then bufnr = vim.api.nvim_get_current_buf() end
    if
        P.is_project_autoformat_disabled()
        or P.is_buffer_autoformat_disabled(bufnr)
    then
        return
    end
    return M.construct_conform_formatting_params(bufnr)
end

---The callback used by conform to syncronously format the file on save.
---If formatting timesout the formatter will switch to formatting after save
---asyncronously for that file type
---@param bufnr integer
---@return conform.FormatOpts? options conform will use to format on save
---@return nil | fun(err: string): boolean err_callback used to change from formatting on save to formatting after save for the buffer file type if a timeout occured
function M.format_on_save(bufnr)
    local filetype = vim.bo[bufnr].filetype
    if P.is_format_after_save_enabled(filetype) then return end
    local function on_format(err)
        if err == nil then return end
        if type(err) == 'string' and err:match('timeout$') then
            if P.is_format_after_save_enabled(filetype) then --In case of some wierd race condition I only want one notification
                vim.notify(
                    'Auto-formatting on save for filetype `'
                        .. filetype
                        .. '` was changed to formatting after save (triggered by old if branch)',
                    vim.log.levels.INFO
                )
            end
            P.set_format_after_save(filetype, true)
        elseif
            type(err) == 'string'
            and err:find('No formatters available for buffer')
        then
            -- Since I don't know how to change the displayed log level I am commenting this out
            -- vim.notify(err, vim.log.levels.DEBUG) --This is an expected error so I just want to log during debug mode
        elseif
            type(err) == 'table'
            and err.code == require('conform.errors').ERROR_CODE.TIMEOUT
        then
            if P.is_format_after_save_enabled(filetype) then --In case of some wierd race condition I only want one notification
                vim.notify(
                    'Auto-formatting on save for filetype `'
                        .. filetype
                        .. '` was changed to formatting after save (triggered by new if branch)',
                    vim.log.levels.INFO
                )
            end
            P.set_format_after_save(filetype, true)
        elseif
            type(err) == 'table'
            and err.code == require('conform.errors').ERROR_CODE.RUNTIME
            and type(err.message) == 'string'
            and err.message:find('No parser could be inferred for file')
        then
            vim.notify(err.message, vim.log.levels.DEBUG) --This is an expected error so I just want to log during debug mode
        else
            vim.notify(
                'Error during formatting: ' .. vim.inspect(err),
                vim.log.levels.ERROR
            )
        end
    end

    return M.construct_conform_autoformat_params(bufnr), on_format
end

---The callback used by conform to asyncronously format files after save
---@param bufnr integer
---@return conform.FormatOpts? format_opts to pass to conform
function M.format_after_save(bufnr)
    if not P.is_format_after_save_enabled(vim.bo[bufnr].filetype) then
        return
    end
    return M.construct_conform_autoformat_params(bufnr)
end

M.properties = P
return M
