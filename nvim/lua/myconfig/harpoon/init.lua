--vendored plugin from https://github.com/ThePrimeagen/harpoon/blob/87b1a3506211538f460786c23f98ec63ad9af4e5/lua/harpoon/init.lua
local Log = require('myconfig.harpoon.logger')
local Ui = require('myconfig.harpoon.ui')
local Data = require('myconfig.harpoon.data')
local Config = require('myconfig.harpoon.config')
local List = require('myconfig.harpoon.list')
local Extensions = require('myconfig.harpoon.extensions')
local HarpoonGroup = require('myconfig.harpoon.autocmd')

---@class MyHarpoon
---@field config MyHarpoonConfig
---@field ui MyHarpoonUI
---@field _extensions MyHarpoonExtensions
---@field data MyHarpoonData
---@field logger MyHarpoonLog
---@field lists {[string]: {[string]: MyHarpoonList}}
---@field hooks_setup boolean
local MyHarpoon = {}

MyHarpoon.__index = MyHarpoon

---@param harpoon MyHarpoon
local function sync_on_change(harpoon)
    local function sync(_)
        return function() harpoon:sync() end
    end

    Extensions.extensions:add_listener({
        ADD = sync('ADD'),
        REMOVE = sync('REMOVE'),
        REORDER = sync('REORDER'),
        LIST_CHANGE = sync('LIST_CHANGE'),
        POSITION_UPDATED = sync('POSITION_UPDATED'),
    })
end

---@return MyHarpoon
function MyHarpoon:new()
    local config = Config.get_default_config()

    local harpoon = setmetatable({
        config = config,
        data = Data.Data:new(config),
        logger = Log,
        ui = Ui:new(config.settings),
        _extensions = Extensions.extensions,
        lists = {},
        hooks_setup = false,
    }, self)
    sync_on_change(harpoon)

    return harpoon
end

---@param name string?
---@return MyHarpoonList
function MyHarpoon:list(name)
    name = name or Config.DEFAULT_LIST

    local key = self.config.settings.key()
    local lists = self.lists[key]

    if not lists then
        lists = {}
        self.lists[key] = lists
    end

    local existing_list = lists[name]

    if existing_list then
        self._extensions:emit(Extensions.event_names.LIST_READ, existing_list)
        return existing_list
    end

    local data = self.data:data(key, name)
    local list_config = Config.get_config(self.config, name)

    local list = List.decode(list_config, name, data)
    self._extensions:emit(Extensions.event_names.LIST_CREATED, list)
    lists[name] = list

    return list
end

---@param cb fun(list: HarpoonList, config: HarpoonPartialConfigItem, name: string)
function MyHarpoon:_for_each_list(cb)
    local key = self.config.settings.key()
    local lists = self.lists[key]
    if not lists then return end

    for name, list in pairs(lists) do
        local list_config = Config.get_config(self.config, name)
        cb(list, list_config, name)
    end
end

function MyHarpoon:sync()
    local key = self.config.settings.key()
    self:_for_each_list(function(list, _, list_name)
        if list.config.encode == false then return end

        local encoded = list:encode()
        self.data:update(key, list_name, encoded)
    end)
    self.data:sync()
end

--luacheck: ignore 212/self
function MyHarpoon:info()
    return {
        paths = Data.info(),
        default_list_name = Config.DEFAULT_LIST,
    }
end

--- PLEASE DONT USE THIS OR YOU WILL BE FIRED
function MyHarpoon:dump() return self.data._data end

---@param extension MyHarpoonExtension
function MyHarpoon:extend(extension) self._extensions:add_listener(extension) end

local the_harpoon = MyHarpoon:new()

---@param self MyHarpoon
---@param partial_config HarpoonPartialConfig?
---@return MyHarpoon
function MyHarpoon.setup(self, partial_config)
    if self ~= the_harpoon then
        ---@diagnostic disable-next-line: cast-local-type
        partial_config = self
        self = the_harpoon
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    self.config = Config.merge_config(partial_config, self.config)
    self.data = Data.Data:new(self.config)
    self.ui:configure(self.config.settings)
    self._extensions:emit(Extensions.event_names.SETUP_CALLED, self.config)

    ---TODO: should we go through every seen list and update its config?

    if self.hooks_setup == false then
        vim.api.nvim_create_autocmd({ 'BufLeave', 'VimLeavePre' }, {
            group = HarpoonGroup,
            pattern = '*',
            callback = function(ev)
                self:_for_each_list(function(list, config)
                    local fn = config[ev.event]
                    if fn ~= nil then fn(ev, list) end

                    if ev.event == 'VimLeavePre' then self:sync() end
                end)
            end,
        })

        self.hooks_setup = true
    end

    return self
end

return the_harpoon
