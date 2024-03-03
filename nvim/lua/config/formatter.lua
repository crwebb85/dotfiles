local Set = require('utils.datastructure').Set

local M = {}

local P = {}

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
    vim.g.is_project_autoformat_disabled = is_autoformat_disabled
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
    vim.b[bufnr].is_buffer_autoformat_disabled = is_autoformat_disabled
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

---@alias LspFormatStrategyEnum "DEFAULT" | "DISABLED" | "FALLBACK" | "ALWAYS"

local LspFormatStrategyEnums = {
    DEFAULT = 'DEFAULT',
    DISABLED = 'DISABLED',
    FALLBACK = 'FALLBACK',
    ALWAYS = 'ALWAYS',
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
    -- vim.print(filetype, lsp_format_strategy)
    lsp_format_strategy_for_filetype[filetype] = lsp_format_strategy
    -- vim.print(lsp_format_strategy_for_filetype)
    vim.g.lsp_format_strategy_for_filetype = lsp_format_strategy_for_filetype
    -- vim.print(vim.g.lsp_format_strategy_for_filetype)
end

---Gets the lsp format strategy for the filetype
---@param filetype any
---@return LspFormatStrategyEnum lsp_format_strategy for the filetype. Defaults to the enum "DEFAULT"
function P.get_filetype_lsp_format_strategy(filetype)
    if vim.g.lsp_format_strategy_for_filetype == nil then
        return LspFormatStrategyEnums.DEFAULT
    end
    local lsp_format_strategy = vim.g.lsp_format_strategy_for_filetype[filetype]
    if lsp_format_strategy == nil then return LspFormatStrategyEnums.DEFAULT end
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
    vim.b[bufnr].buffer_lsp_format_strategy = lsp_format_strategy
end

---Gets the lsp format strategy for the buffer
---@param bufnr? number the buffer number. Defaults to buffer 0
---@return LspFormatStrategyEnum lsp_format_strategy for the buffer. Defaults to the enum "DEFAULT"
function P.get_buffer_lsp_format_strategy(bufnr)
    if bufnr == nil then bufnr = 0 end
    if vim.b[bufnr].buffer_lsp_format_strategy == nil then
        return LspFormatStrategyEnums.DEFAULT
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
    local lsp_format_strategy_for_filetype = LspFormatStrategyEnums.DEFAULT
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
        lsp_fromat_for_filetype_map = P.get_filetype_lsp_format_strategy_map(),
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
---@return string[] lsp_formatter_names that can be used for the buffer
function M.get_buffer_lsp_formatters(bufnr)
    ---@type string[]
    local lsp_formatters = {}
    if bufnr == nil then bufnr = 0 end
    for _, lsp_client in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if lsp_client.supports_method('textDocument/formatting') then
            table.insert(lsp_formatters, lsp_client.name)
        end
    end
    return lsp_formatters
end

---Determines the lsp_fallback value to use for Conform plugin's lsp_fallback option
---based on my formatting properties. Prioritizes the buffer settings over filetype settings
---@param bufnr any
---@return boolean | "always"
function M.determine_conform_lsp_fallback(bufnr)
    local lsp_format_strategy = P.get_buffer_lsp_format_strategy(bufnr)
    if lsp_format_strategy == LspFormatStrategyEnums.DEFAULT then
        local filetype = vim.bo[bufnr].filetype
        if filetype == nil then
            lsp_format_strategy = LspFormatStrategyEnums.DEFAULT
        else
            lsp_format_strategy = P.get_filetype_lsp_format_strategy(filetype)
        end
    end

    if lsp_format_strategy == LspFormatStrategyEnums.DEFAULT then
        return true
    elseif lsp_format_strategy == LspFormatStrategyEnums.FALLBACK then
        return true
    elseif lsp_format_strategy == LspFormatStrategyEnums.DISABLED then
        return false
    elseif lsp_format_strategy == LspFormatStrategyEnums.ALWAYS then
        return 'always'
    else
        return true
    end
end

---@param bufnr? integer the buffer number. Defaults to buffer 0.
function M.construct_conform_formatting_params(bufnr)
    if bufnr == nil then bufnr = 0 end
    local project_disabled_formatters = P.get_project_disabled_formatters()
    local buffer_disabled_formatters = P.get_buffer_disabled_formatters(bufnr)
    if #project_disabled_formatters > 0 or #buffer_disabled_formatters > 0 then
        if #project_disabled_formatters > 0 then
            vim.print('Project disabled formatters:')
            vim.print(project_disabled_formatters)
        end
        if #buffer_disabled_formatters > 0 then
            vim.print('Buffer disabled formatters:')
            vim.print(buffer_disabled_formatters)
        end

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
        vim.print('Formatting with the formatters:', formatter_names)

        return {
            timeout_ms = P.get_formatting_timeout(),
            formatters = formatter_names,
            lsp_fallback = M.determine_conform_lsp_fallback(bufnr),
        }
    end
    return {
        timeout_ms = P.get_formatting_timeout(),
        lsp_fallback = M.determine_conform_lsp_fallback(bufnr),
    }
end

---Used by formatter to auto format files on save
---If auto formatting is disabled for the project or the buffer then this function
---will skip formating the buffer
---@param bufnr? number the buffer number to autoformat. Defaults to buffer 0
function M.construct_conform_autoformat_params(bufnr)
    if bufnr == nil then bufnr = 0 end
    if
        P.is_project_autoformat_disabled()
        or P.is_buffer_autoformat_disabled(bufnr)
    then
        return
    end
    return M.construct_conform_formatting_params(bufnr)
end

M.properties = P
return M

