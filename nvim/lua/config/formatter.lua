local Set = require('utils.datastructure').Set

local M = {}

local P = {}

--List of User commands patterns
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

---Gets the buffer property disabled_formatters
---@param bufnr? number the buffer number
---@return string[]
function P.get_buffer_disabled_formatters(bufnr)
    if bufnr == nil then bufnr = 0 end
    if vim.b[bufnr].disabled_formatters == nil then return {} end
    return vim.b[bufnr].disabled_formatters
end

---Sets the buffer property disabled_formatters
---@param formatters string[]
---@param bufnr? number the buffer number
function P.set_buffer_disabled_formatters(formatters, bufnr)
    if bufnr == nil then bufnr = 0 end
    vim.b[bufnr].disabled_formatters = formatters

    -- Im not bothering to check if the new value has actually changed before
    -- trigering the user autocmd
    vim.api.nvim_exec_autocmds(
        'User',
        { pattern = 'FormatterChange.DisabledFormatters.Buffer' }
    )
end

---Gets the project property disabled_formatters
---@return string[]
function P.get_project_disabled_formatters()
    if vim.g.disabled_formatters == nil then return {} end
    return vim.g.disabled_formatters
end

---Sets the project property disabled_formatters
---@param formatters string[]
function P.set_project_disabled_formatters(formatters)
    vim.g.disabled_formatters = formatters
    -- Im not bothering to check if the new value has actually changed before
    -- trigering the user autocmd
    vim.api.nvim_exec_autocmds(
        'User',
        { pattern = 'FormatterChange.DisabledFormatters.Project' }
    )
end

---Getter for the project property is_project_autoformat_disabled
---@return boolean
function P.is_project_autoformat_disabled()
    if vim.g.is_project_autoformat_disabled == nil then return false end
    return vim.g.is_project_autoformat_disabled
end

---Setter for the project property is_project_autoformat_disabled
---Used to disable/enable autoformatting project wide
---@param is_autoformat_disabled boolean
function P.set_project_autoformat_disabled(is_autoformat_disabled)
    local old_is_autoformat_disabled = P.is_project_autoformat_disabled()
    vim.g.is_project_autoformat_disabled = is_autoformat_disabled
    if old_is_autoformat_disabled ~= P.is_project_autoformat_disabled() then
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
    if bufnr == nil then bufnr = 0 end
    if vim.b[bufnr].is_buffer_autoformat_disabled == nil then return false end
    return vim.b[bufnr].is_buffer_autoformat_disabled
end

---Setter for the buffer property is_buffer_autoformat_disabled
---@param is_autoformat_disabled boolean
---@param bufnr? number
function P.set_buffer_autoformat_disabled(is_autoformat_disabled, bufnr)
    if bufnr == nil then bufnr = 0 end
    local old_is_autoformat_disabled = P.is_buffer_autoformat_disabled(bufnr)
    vim.b[bufnr].is_buffer_autoformat_disabled = is_autoformat_disabled

    if old_is_autoformat_disabled ~= P.is_buffer_autoformat_disabled(bufnr) then
        vim.api.nvim_exec_autocmds(
            'User',
            { pattern = 'FormatterChange.AutoFormat.Buffer' }
        )
    end
end

---Sets the formatting timeout
---@param time_milliseconds number the time in milliseconds before the formatter times out
function P.set_formatting_timeout(time_milliseconds)
    if time_milliseconds <= 0 then
        error(
            'Cannot set formatting timeout to a value less than or equal to zero',
            2
        )
    end
    vim.g.formatter_timeout_milliseconds = time_milliseconds
end

---@private
---@type {string:boolean} lookup table for filetypes to format after save asyncronously
local format_after_save_filetypes = {}

---Setter for the filetypes to format after save
---@param filetype string
---@param is_format_after_save_enabled boolean
function P.set_format_after_save(filetype, is_format_after_save_enabled)
    local old_is_format_after_save_enabled =
        P.is_format_after_save_enabled(filetype)
    format_after_save_filetypes[filetype] = is_format_after_save_enabled
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
    if filetype == nil or format_after_save_filetypes[filetype] == nil then
        return false
    end
    return format_after_save_filetypes[filetype]
end

---@alias LspFormatStrategyEnum "NEVER" | "FALLBACK" | "PREFER" | "FIRST" | "LAST"

local LspFormatStrategyEnums = {
    NEVER = 'NEVER',
    FALLBACK = 'FALLBACK',
    PREFER = 'PREFER',
    FIRST = 'FIRST',
    LAST = 'LAST',
}
P.LspFormatStrategyEnums = LspFormatStrategyEnums

---Sets the lsp format strategy for the filetype
---@param filetype string
---@param lsp_format_strategy LspFormatStrategyEnum
function P.set_filetype_lsp_format_strategy(filetype, lsp_format_strategy)
    local lsp_format_strategy_for_filetype =
        vim.g.lsp_format_strategy_for_filetype
    if vim.g.lsp_format_strategy_for_filetype == nil then
        lsp_format_strategy_for_filetype = {}
    end
    local old_format_strategy = P.get_filetype_lsp_format_strategy(filetype)
    -- vim.print(filetype, lsp_format_strategy)
    lsp_format_strategy_for_filetype[filetype] = lsp_format_strategy
    -- vim.print(lsp_format_strategy_for_filetype)
    vim.g.lsp_format_strategy_for_filetype = lsp_format_strategy_for_filetype
    -- vim.print(vim.g.lsp_format_strategy_for_filetype)
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
---@param filetype any
---@return LspFormatStrategyEnum lsp_format_strategy for the filetype. Defaults to the enum "DEFAULT"
function P.get_filetype_lsp_format_strategy(filetype)
    if vim.g.lsp_format_strategy_for_filetype == nil then
        return LspFormatStrategyEnums.FALLBACK
    end
    local lsp_format_strategy = vim.g.lsp_format_strategy_for_filetype[filetype]
    if lsp_format_strategy == nil then
        return LspFormatStrategyEnums.FALLBACK
    end
    return lsp_format_strategy
end

---Gets the lsp format strategy for the filetype
function P.get_filetype_lsp_format_strategy_map()
    if vim.g.lsp_format_strategy_for_filetype == nil then return {} end
    return vim.g.lsp_format_strategy_for_filetype
end

---Sets the lsp format strategy for the buffer
---@param lsp_format_strategy LspFormatStrategyEnum
---@param bufnr? number the buffer number. Defaults to buffer 0.
function P.set_buffer_lsp_format_strategy(lsp_format_strategy, bufnr)
    if bufnr == nil then bufnr = 0 end
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
    if bufnr == nil then bufnr = 0 end
    if vim.b[bufnr].buffer_lsp_format_strategy == nil then
        return LspFormatStrategyEnums.FALLBACK
    end
    return vim.b[bufnr].buffer_lsp_format_strategy
end

---Getter for the formatter timeout in milliseconds
---@return integer timeout value in milliseconds.Defaults to 500 milliseconds.
function P.get_formatting_timeout()
    if vim.g.formatter_timeout_milliseconds == nil then
        local DEFUALT_FORMATTING_TIMEOUT = 500
        return DEFUALT_FORMATTING_TIMEOUT
    end
    return vim.g.formatter_timeout_milliseconds
end

function P.get_buffer_formatting_details(bufnr)
    if bufnr == nil then bufnr = 0 end
    local lsp_format_strategy_for_filetype = LspFormatStrategyEnums.FALLBACK
    local filetype = vim.bo[bufnr].filetype
    -- vim.print(filetype)
    if filetype ~= nil then
        lsp_format_strategy_for_filetype =
            P.get_filetype_lsp_format_strategy(filetype)
    end
    return {
        is_buffer_autoformat_disabled = P.is_buffer_autoformat_disabled(bufnr),
        is_project_autoformat_disabled = P.is_project_autoformat_disabled(),
        buffer_disabled_formatters = P.get_buffer_disabled_formatters(bufnr),
        project_disabled_formatters = P.get_project_disabled_formatters(),
        buffer_lsp_format_strategy = P.get_buffer_lsp_format_strategy(bufnr),
        lsp_format_for_filetype = lsp_format_strategy_for_filetype,
        buffer_conform_lsp_fallback_value = M.determine_conform_lsp_fallback(
            bufnr
        ),
        lsp_format_for_filetype_map = P.get_filetype_lsp_format_strategy_map(),
        buffer_formatters = M.get_buffer_formatter_details(bufnr),
    }
end

---@class (exact) FormatterDetails
---@field name string
---@field available boolean
---@field available_msg? string
---@field buffer_disabled boolean
---@field project_disabled boolean
---@field is_lsp boolean

---@class (exact) LspFormatterDetails
---@field name string
---@field client_id integer

---@param bufnr integer?
---@return (FormatterDetails | LspFormatterDetails)[]
function M.get_buffer_lsp_and_formatter_details(bufnr)
    if bufnr == nil then bufnr = 0 end

    ---@type (FormatterDetails | LspFormatterDetails)[]
    local all_formatters = {}

    local formatters = M.get_buffer_formatter_details(bufnr)
    local lsp_formatters = M.get_buffer_lsp_formatters(bufnr)
    local lsp_format_strategy = P.get_buffer_lsp_format_strategy(bufnr)

    if #lsp_formatters == 0 or lsp_format_strategy == 'NEVER' then
        return formatters
    end

    if lsp_format_strategy == 'FALLBACK' and #formatters > 0 then
        return formatters
    elseif lsp_format_strategy == 'FALLBACK' then
        return lsp_formatters
    end

    if lsp_format_strategy == 'PREFER' and #lsp_formatters > 0 then
        return lsp_formatters
    elseif lsp_format_strategy == 'PREFER' then
        return formatters
    end

    if lsp_format_strategy == 'FIRST' then
        for _, lsp_formatter in ipairs(lsp_formatters) do
            table.insert(all_formatters, lsp_formatter)
        end
        for _, formatter in ipairs(formatters) do
            table.insert(all_formatters, formatter)
        end
    elseif lsp_format_strategy == 'LAST' then
        for _, formatter in ipairs(formatters) do
            table.insert(all_formatters, formatter)
        end
        for _, lsp_formatter in ipairs(lsp_formatters) do
            table.insert(all_formatters, lsp_formatter)
        end
    end

    return all_formatters
end

---@param bufnr? integer the buffer number. Defaults to buffer 0.
---@return FormatterDetails[]
function M.get_buffer_formatter_details(bufnr)
    ---@type FormatterDetails[]
    local all_info = {}
    if bufnr == nil then bufnr = 0 end
    local buffer_disabled_formatters = P.get_buffer_disabled_formatters(bufnr)
    local project_disabled_formatters = P.get_project_disabled_formatters()

    local buffer_disabled_formatters_set = Set:new(buffer_disabled_formatters)
    local project_disabled_formatters_set = Set:new(project_disabled_formatters)

    local names = require('conform').list_formatters_for_buffer()
    for _, name in ipairs(names) do
        if type(name) == 'string' then
            local info = require('conform').get_formatter_info(name, bufnr)
            ---@type FormatterDetails
            local details = {
                name = info.name,
                available = info.available,
                available_msg = info.available_msg,
                buffer_disabled = buffer_disabled_formatters_set:has(name),
                project_disabled = project_disabled_formatters_set:has(name),
            }
            table.insert(all_info, details)
        else
            -- If this is an alternation, take the first one that's available
            for _, alternation_name in ipairs(name) do
                local info = require('conform').get_formatter_info(
                    alternation_name,
                    bufnr
                )
                if info.available then
                    ---@type FormatterDetails
                    local details = {
                        name = info.name,
                        available = info.available,
                        available_msg = info.available_msg,
                        buffer_disabled = buffer_disabled_formatters_set:has(
                            info.name
                        ),
                        project_disabled = project_disabled_formatters_set:has(
                            info.name
                        ),
                    }
                    table.insert(all_info, details)
                    break
                end
            end
        end
    end

    -- vim.print(all_info)
    return all_info
end

---@param bufnr? integer the buffer number. Defaults to buffer 0.
---@return LspFormatterDetails[] lsp_formatter_details that can be used for the buffer
function M.get_buffer_lsp_formatters(bufnr)
    ---@type string[]
    local lsp_formatters = {}
    if bufnr == nil then bufnr = 0 end
    for _, lsp_client in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if lsp_client.supports_method('textDocument/formatting') then
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
---TODO determine if I want to make any changes because of the new lsp format strategies added by conform
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
    local project_disabled_formatters = P.get_project_disabled_formatters()
    local buffer_disabled_formatters = P.get_buffer_disabled_formatters(bufnr)
    if #project_disabled_formatters > 0 or #buffer_disabled_formatters > 0 then
        local buffer_formatters = M.get_buffer_formatter_details(bufnr)

        local formatter_names = {}
        for _, formatter_info in pairs(buffer_formatters) do
            if
                not formatter_info.buffer_disabled
                and not formatter_info.project_disabled
            then
                table.insert(formatter_names, formatter_info.name)
            end
        end

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
        if err and err:match('timeout$') then
            if P.is_format_after_save_enabled(filetype) then --In case of some wierd race condition I only want one notification
                vim.notify(
                    'Auto-formatting on save for filetype `'
                        .. filetype
                        .. '` was changed to formatting after save'
                )
            end
            P.set_format_after_save(filetype, true)
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
