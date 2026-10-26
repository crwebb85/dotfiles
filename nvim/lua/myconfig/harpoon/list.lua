--vendored plugin from https://github.com/ThePrimeagen/harpoon/blob/87b1a3506211538f460786c23f98ec63ad9af4e5/lua/harpoon/list.lua
local Logger = require('myconfig.harpoon.logger')
local utils = require('myconfig.harpoon.utils')
local Extensions = require('myconfig.harpoon.extensions')

local function guess_length(arr)
    local last_known = #arr
    for i = 1, 20 do
        if arr[i] ~= nil and last_known < i then last_known = i end
    end

    return last_known
end

local function determine_length(arr, previous_length)
    local idx = 0
    for i = previous_length, 1, -1 do
        if arr[i] ~= nil then
            idx = i
            break
        end
    end
    return idx
end

--- @class MyHarpoonNavOptions
--- @field ui_nav_wrap? boolean

---@param items any[]
---@param element any
---@param config MyHarpoonPartialConfigItem?
local function index_of(items, length, element, config)
    local equals = config and config.equals or function(a, b) return a == b end
    local index = -1
    for i = 1, length do
        local item = items[i]
        if equals(element, item) then
            index = i
            break
        end
    end

    return index
end

---@param arr any[]
---@param value any
---@return number
local function prepend_to_array(arr, value)
    local idx = 1
    local prev = value
    while true do
        local curr = arr[idx]
        arr[idx] = prev
        if curr == nil then break end
        prev = curr
        idx = idx + 1
    end
    return idx
end

--- @class MyHarpoonItem
--- @field value string
--- @field context any

--- @class MyHarpoonList
--- @field config MyHarpoonPartialConfigItem
--- @field name string
--- @field _length number
--- @field _index number
--- @field items MyHarpoonItem[]
local MyHarpoonList = {}

MyHarpoonList.__index = MyHarpoonList
function MyHarpoonList:new(config, name, items)
    items = items or {}
    return setmetatable({
        items = items,
        config = config,
        name = name,
        _length = guess_length(items),
        _index = 1,
    }, self)
end

---@return number
function MyHarpoonList:length() return self._length end

function MyHarpoonList:clear()
    self.items = {}
    self._length = 0
end

---@param item? MyHarpoonListItem
---@return MyHarpoonList
function MyHarpoonList:append(item)
    print('APPEND IS DEPRECATED -- PLEASE USE `add`')
    return self:add(item)
end

---@param idx number
---@param item? MyHarpoonListItem
function MyHarpoonList:replace_at(idx, item)
    item = item or self.config.create_list_item(self.config)
    local current_idx = index_of(self.items, self._length, item, self.config)

    self.items[idx] = item

    if current_idx ~= idx then self.items[current_idx] = nil end

    if idx > self._length then
        self._length = idx
    else
        self._length = determine_length(self.items, self._length)
    end

    Extensions.extensions:emit(
        Extensions.event_names.REPLACE,
        { list = self, item = item, idx = idx }
    )
end

---@param item? MyHarpoonListItem
function MyHarpoonList:add(item)
    item = item or self.config.create_list_item(self.config)

    local index = index_of(self.items, self._length, item, self.config)
    Logger:log('MyHarpoonList:add', { item = item, index = index })

    if index == -1 then
        local idx = self._length + 1
        for i = 1, self._length + 1 do
            if self.items[i] == nil then
                idx = i
                break
            end
        end

        self.items[idx] = item
        if idx > self._length then self._length = idx end

        Extensions.extensions:emit(
            Extensions.event_names.ADD,
            { list = self, item = item, idx = idx }
        )
    end

    return self
end

---@return MyHarpoonList
function MyHarpoonList:prepend(item)
    item = item or self.config.create_list_item(self.config)
    local index = index_of(self.items, self._length, item, self.config)
    Logger:log('MyHarpoonList:prepend', { item = item, index = index })
    if index == -1 then
        local stop_idx = prepend_to_array(self.items, item)
        if stop_idx > self._length then self._length = stop_idx end

        Extensions.extensions:emit(
            Extensions.event_names.ADD,
            { list = self, item = item, idx = 1 }
        )
    end

    return self
end

---@return MyHarpoonList
function MyHarpoonList:remove(item)
    item = item or self.config.create_list_item(self.config)
    for i = 1, self._length do
        local v = self.items[i]
        if self.config.equals(v, item) then
            Logger:log('MyHarpoonList:remove', { item = item, index = i })
            self.items[i] = nil
            if i == self._length then
                self._length = determine_length(self.items, self._length)
            end
            Extensions.extensions:emit(
                Extensions.event_names.REMOVE,
                { list = self, item = item, idx = i }
            )
            break
        end
    end
    return self
end

---@return MyHarpoonList
function MyHarpoonList:remove_at(index)
    if self.items[index] then
        Logger:log(
            'MyHarpoonList:removeAt',
            { item = self.items[index], index = index }
        )
        self.items[index] = nil
        if index == self._length then
            self._length = determine_length(self.items, self._length)
        end
        Extensions.extensions:emit(
            Extensions.event_names.REMOVE,
            { list = self, item = self.items[index], idx = index }
        )
    end
    return self
end

function MyHarpoonList:get(index) return self.items[index] end

function MyHarpoonList:get_by_value(value)
    local index = index_of(self.items, self._length, value, {
        equals = function(element, item)
            if item == nil then return false end
            return element == item.value
        end,
    })
    if index == -1 then return nil end
    return self.items[index], index
end

--- much inefficiencies.  dun care
---@param displayed string[]
---@param length number
function MyHarpoonList:resolve_displayed(displayed, length)
    local new_list = {}

    local list_displayed = self:display()

    local change = 0
    for i = 1, self._length do
        local v = self.items[i]
        local index = index_of(displayed, self._length, v)
        if index == -1 then change = change + 1 end
    end

    for i = 1, length do
        local v = displayed[i]
        local index = index_of(list_displayed, self._length, v)
        if utils.is_white_space(v) then
            new_list[i] = nil
        elseif index == -1 then
            new_list[i] = self.config.create_list_item(self.config, v)
            change = change + 1
        else
            local index_in_new_list =
                index_of(new_list, length, self.items[index], self.config)

            if index_in_new_list == -1 then new_list[i] = self.items[index] end

            if index ~= i then change = change + 1 end
        end
    end

    self.items = new_list
    self._length = length
    if change > 0 then
        Extensions.extensions:emit(Extensions.event_names.LIST_CHANGE)
    end
end

function MyHarpoonList:select(index, options)
    local item = self.items[index]
    if item or self.config.select_with_nil then
        Extensions.extensions:emit(
            Extensions.event_names.SELECT,
            { list = self, item = item, idx = index }
        )
        self.config.select(item, self, options)
    end
end

---
--- @param opts? MyHarpoonNavOptions
function MyHarpoonList:next(opts)
    opts = opts or {}

    self._index = self._index + 1
    if self._index > self._length then
        if opts.ui_nav_wrap then
            self._index = 1
        else
            self._index = self._length
        end
    end

    self:select(self._index)
end

---
--- @param opts? MyHarpoonNavOptions
function MyHarpoonList:prev(opts)
    opts = opts or {}

    self._index = self._index - 1
    if self._index < 1 then
        if opts.ui_nav_wrap then
            self._index = #self.items
        else
            self._index = 1
        end
    end

    self:select(self._index)
end

--- @return string[]
function MyHarpoonList:display()
    local out = {}
    for i = 1, self._length do
        local v = self.items[i]
        out[i] = v == nil and '' or self.config.display(v)
    end

    return out
end

--- @return string[]
function MyHarpoonList:encode()
    local out = {}
    for k, v in pairs(self.items) do
        out[k] = self.config.encode(v)
    end

    return out
end

--- @return MyHarpoonList
--- @param list_config MyHarpoonPartialConfigItem
--- @param name string
--- @param items string[]
function MyHarpoonList.decode(list_config, name, items)
    local list_items = {}
    for k, item in pairs(items) do
        list_items[k] = item ~= vim.NIL and list_config.decode(item) or nil
    end

    return MyHarpoonList:new(list_config, name, list_items)
end

return MyHarpoonList
