--vendored plugin from https://github.com/ThePrimeagen/harpoon/blob/87b1a3506211538f460786c23f98ec63ad9af4e5/lua/harpoon/config.lua
local Extensions = require('myconfig.harpoon.extensions')
local Logger = require('myconfig.harpoon.logger')
local function normalize_path(buf_name, root)
    --AI conversion of
    -- return require('plenary.path'):new(buf_name):make_relative(root)
    local path = vim.fn.fnamemodify(buf_name, ':p')
    local relative_path =
        vim.fn.fnamemodify(path, ':.' .. vim.fn.fnamemodify(root, ':p'))
    return relative_path
end
local function to_exact_name(value) return '^' .. value .. '$' end

local M = {}
local DEFAULT_LIST = '__harpoon_files'
M.DEFAULT_LIST = DEFAULT_LIST

---@alias MyHarpoonListItem {value: any, context: any}
---@alias MyHarpoonListFileItem {value: string, context: {row: number, col: number}}
---@alias MyHarpoonListFileOptions {split: boolean, vsplit: boolean, tabedit: boolean}

---@class MyHarpoonPartialConfigItem
---@field select_with_nil? boolean defaults to false
---@field encode? (fun(list_item: MyHarpoonListItem): string) | boolean
---@field decode? (fun(obj: string): any)
---@field display? (fun(list_item: MyHarpoonListItem): string)
---@field select? (fun(list_item?: MyHarpoonListItem, list: MyHarpoonList, options: any?): nil)
---@field equals? (fun(list_line_a: MyHarpoonListItem, list_line_b: MyHarpoonListItem): boolean)
---@field create_list_item? fun(config: MyHarpoonPartialConfigItem, item: any?): MyHarpoonListItem
---@field BufLeave? fun(evt: any, list: MyHarpoonList): nil
---@field VimLeavePre? fun(evt: any, list: MyHarpoonList): nil
---@field get_root_dir? fun(): string

---@class MyHarpoonSettings
---@field save_on_toggle boolean defaults to false
---@field sync_on_ui_close? boolean
---@field key (fun(): string)

---@class MyHarpoonPartialSettings
---@field save_on_toggle? boolean
---@field sync_on_ui_close? boolean
---@field key? (fun(): string)

---@class MyHarpoonConfig
---@field default MyHarpoonPartialConfigItem
---@field settings MyHarpoonSettings
---@field [string] MyHarpoonPartialConfigItem

---@class MyHarpoonPartialConfig
---@field default? MyHarpoonPartialConfigItem
---@field settings? MyHarpoonPartialSettings
---@field [string] MyHarpoonPartialConfigItem

---@return MyHarpoonPartialConfigItem
function M.get_config(config, name)
    return vim.tbl_extend('force', {}, config.default, config[name] or {})
end

---@return MyHarpoonConfig
function M.get_default_config()
    return {

        settings = {
            save_on_toggle = false,
            sync_on_ui_close = false,

            key = function() return vim.loop.cwd() end,
        },

        default = {

            --- select_with_nill allows for a list to call select even if the provided item is nil
            select_with_nil = false,

            ---@param obj MyHarpoonListItem
            ---@return string
            encode = function(obj) return vim.json.encode(obj) end,

            ---@param str string
            ---@return MyHarpoonListItem
            decode = function(str) return vim.json.decode(str) end,

            ---@param list_item MyHarpoonListItem
            display = function(list_item) return list_item.value end,

            --- the select function is called when a user selects an item from
            --- the corresponding list and can be nil if select_with_nil is true
            ---
            --- Also decodes dynamic file names base on the current date
            --- denoted by ${filname_goes_here}
            --- When a dynamic name is detected the file name is decoded using
            --- the os.date function in the lua standard library
            --- for example "${test%Y-%m-%d.log}" would become "test2024-09-27.log"
            --- if todays date was 2024-09-27 this allows adding current days log file
            --- to the harpoon list without having to change it each day.
            ---
            --- Based on the default select in harpoon2 but modified to allow dynamic dates
            --- in the file name
            ---@param list_item? MyHarpoonListFileItem
            ---@param list MyHarpoonList
            ---@param options MyHarpoonListFileOptions
            select = function(list_item, list, options)
                local Logger = require('myconfig.harpoon.logger')
                local Extensions = require('myconfig.harpoon.extensions')
                Logger:log(
                    'config_defaut#select',
                    list_item,
                    list.name,
                    options
                )
                if list_item == nil then return end

                options = options or {}

                --Decode dynamic harpoon items based on current date
                --for example "${test%Y-%m-%d.log}" would become "test2024-09-27.log"
                --if todays date was 2024-09-27 this allows adding current days log file
                --to the harpoon list without having to change it each day.
                local list_item_value, _ = string.gsub(
                    list_item.value,
                    '^%${(.*)}$',
                    function(n) return os.date(n) end
                )
                local bufnr = vim.fn.bufnr(to_exact_name(list_item_value))
                local set_position = false
                if bufnr == -1 then -- must create a buffer!
                    set_position = true
                    -- bufnr = vim.fn.bufnr(list_item.value, true)
                    bufnr = vim.fn.bufadd(list_item_value)
                end
                if not vim.api.nvim_buf_is_loaded(bufnr) then
                    vim.fn.bufload(bufnr)
                    vim.api.nvim_set_option_value('buflisted', true, {
                        buf = bufnr,
                    })
                end

                if options.vsplit then
                    vim.cmd('vsplit')
                elseif options.split then
                    vim.cmd('split')
                elseif options.tabedit then
                    vim.cmd('tabedit')
                end

                vim.api.nvim_set_current_buf(bufnr)

                if set_position then
                    local lines = vim.api.nvim_buf_line_count(bufnr)

                    local edited = false
                    if list_item.context.row > lines then
                        list_item.context.row = lines
                        edited = true
                    end

                    local row = list_item.context.row
                    local row_text =
                        vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)
                    local col = #row_text[1]

                    if list_item.context.col > col then
                        list_item.context.col = col
                        edited = true
                    end

                    local new_pos = {
                        list_item.context.row or 1,
                        list_item.context.col or 0,
                    }
                    vim.api.nvim_win_set_cursor(0, new_pos)

                    if edited then
                        Extensions.extensions:emit(
                            Extensions.event_names.POSITION_UPDATED,
                            {
                                list_item = list_item,
                            }
                        )
                    end
                end

                Extensions.extensions:emit(Extensions.event_names.NAVIGATE, {
                    buffer = bufnr,
                })
            end,

            ---@param list_item_a MyHarpoonListItem
            ---@param list_item_b MyHarpoonListItem
            equals = function(list_item_a, list_item_b)
                if list_item_a == nil and list_item_b == nil then
                    return true
                elseif list_item_a == nil or list_item_b == nil then
                    return false
                end

                return list_item_a.value == list_item_b.value
            end,

            get_root_dir = function() return vim.loop.cwd() end,

            ---I modified this for better path handling
            ---
            ---@param config MyHarpoonPartialConfigItem
            ---@param name? any
            ---@return MyHarpoonListItem
            create_list_item = function(config, name)
                name = name
                    --TODO maybe we should only normalize the file name if it is actually
                    --a filename
                    or vim.fs.normalize(
                        vim.api.nvim_buf_get_name(
                            vim.api.nvim_get_current_buf()
                        )
                    )

                --Make the path relative to the root dir if it is in the root dir
                name = vim.fs.relpath(
                    vim.fs.normalize(config.get_root_dir()),
                    name
                ) or name

                local bufnr = vim.fn.bufnr(name, false)

                local pos = { 1, 0 }
                if bufnr ~= -1 then pos = vim.api.nvim_win_get_cursor(0) end

                return {
                    value = name,
                    context = {
                        row = pos[1],
                        col = pos[2],
                    },
                }
            end,

            ---@param arg {buf: number}
            ---@param list MyHarpoonList
            BufLeave = function(arg, list)
                local bufnr = arg.buf
                local bufname = normalize_path(
                    vim.api.nvim_buf_get_name(bufnr),
                    list.config.get_root_dir()
                )
                local item = list:get_by_value(bufname)

                if item then
                    local pos = vim.api.nvim_win_get_cursor(0)

                    Logger:log(
                        'config_default#BufLeave updating position',
                        bufnr,
                        bufname,
                        item,
                        'to position',
                        pos
                    )

                    item.context.row = pos[1]
                    item.context.col = pos[2]

                    Extensions.extensions:emit(
                        Extensions.event_names.POSITION_UPDATED,
                        item
                    )
                end
            end,

            autocmds = { 'BufLeave' },
        },
    }
end

---@param partial_config MyHarpoonPartialConfig?
---@param latest_config MyHarpoonConfig?
---@return MyHarpoonConfig
function M.merge_config(partial_config, latest_config)
    partial_config = partial_config or {}
    local config = latest_config or M.get_default_config()
    for k, v in pairs(partial_config) do
        if k == 'settings' then
            config.settings = vim.tbl_extend('force', config.settings, v)
        elseif k == 'default' then
            config.default = vim.tbl_extend('force', config.default, v)
        else
            config[k] = vim.tbl_extend('force', config[k] or {}, v)
        end
    end
    return config
end

---@param settings MyHarpoonPartialSettings
function M.create_config(settings)
    local config = M.get_default_config()
    for k, v in ipairs(settings) do
        config.settings[k] = v
    end
    return config
end

return M
