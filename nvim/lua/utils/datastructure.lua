-- Based on set implementation from https://www.lua.org/pil/13.1.html and https://github.com/EvandroLG/set-lua/tree/master
local M = {}

---@class Set
---@field new fun(self, list:table):Set Constructs a new set that lets you store unique values of any type
---@field to_array fun(self): table Converts the set to an array
---@field to_string fun(self): string Stringifies the set
---@field print fun(self) Prints the set
---@field insert fun(self, value:any) Appends value to the Set object
---@field has fun(self, value:any): boolean Checks if value is present in the Set object or not
---@field clear fun(self) Removes all items from the Set object
---@field delete fun(self, value: any): boolean Removes item from the Set object and returns a boolean value asserting whether item was removed or not
---@field each fun(self, callback: fun(value:any)) Executes callback once for each item present in the Set object without preserve insertion order
---@field every fun(self, callback: (fun(value:any):boolean)): boolean Returns true if all items pass the test provided by the callback function
---@field union fun(self, set:Set): Set Returns a new Set that contains all items from the original Set and all items from the specified Sets
---@field union_in_place fun(self, set:Set) Unions the set in place
---@field intesection fun(self, set:Set): Set Returns a new Set that contains all elements that are common between the two sets
---@field difference fun(self, set:Set): Set Returns a new Set that contains the items that only exist in the original Set
---@field symmetric_difference fun(self, set:Set): Set Returns a symetric difference of two Sets
---@field is_superset fun(self, subset: Set): boolean Returns true if set has all items present in the subset
local Set = {}

-- Constructs a new set that lets you store unique values of any type
--- @param list table
--- @returns Set
function Set:new(list)
    local o = {} -- create object if user does not provide one
    local instance = setmetatable(o, {
        __index = self,
    })

    -- Items presented in Set
    ---@type table
    instance.items = {}

    -- Current Set length
    ---@type integer
    instance.size = 0

    if type(list) == 'table' then
        for _, value in ipairs(list) do
            instance.items[value] = true
            instance.size = instance.size + 1
        end
    end

    return o
end

---Converts the list to an array
---@return table
function Set:to_array()
    local output = {}

    for key in pairs(self.items) do
        table.insert(output, key)
    end

    return output
end

function Set:to_string()
    local s = '{'
    local sep = ''
    for e in pairs(self.items) do
        s = s .. sep .. e
        sep = ', '
    end
    return s .. '}'
end

function Set:print() print(self:to_string()) end

---Appends value to the Set object
---@param value any
function Set:insert(value)
    if self.items[value] == nil or not self.items[value] then
        self.items[value] = true
        self.size = self.size + 1
    end
end

---Checks if value is present in the Set object or not
---@param value any
---@returns boolean
function Set:has(value) return self.items[value] == true end

---Removes all items from the Set object
function Set:clear()
    self.items = {}
    self.size = 0
end

---Removes item from the Set object and returns a boolean value asserting whether item was removed or not
---@param value any
---@returns boolean
function Set:delete(value)
    if self.items[value] then
        self.items[value] = nil
        self.size = self.size - 1
        return true
    end

    return false
end

---Calls function once for each item present in the Set object without preserve insertion order
---@param callback fun(value: any)
---@returns void
function Set:each(callback)
    for key in pairs(self.items) do
        callback(key)
    end
end

---Returns true whether all items pass the test provided by the callback function
---@param callback fun(value: any): boolean
---@returns boolean
function Set:every(callback)
    for key in pairs(self.items) do
        if not callback(key) then return false end
    end

    return true
end

---Returns a new Set that contains all items from the original Set and all items from the specified Sets
---@param set Set
---@returns Set
function Set:union(set)
    local values = {}

    for key in pairs(self.items) do
        table.insert(values, key)
    end

    local result = Set:new(self:to_array())
    set:each(function(key) result:insert(key) end)

    return result
end

---Unions the set in place
---@param set Set
function Set:union_in_place(set)
    set:each(function(value) self:insert(value) end)
end

---Returns a new Set that contains all elements that are common between the two sets
---@param set Set
---@returns Set
function Set:intersection(set)
    local result = Set:new({})

    self:each(function(value)
        if set:has(value) then result:insert(value) end
    end)

    return result
end

---Returns a new Set that contains the items that only exist in the original Set
---@param set Set
---@returns Set
function Set:difference(set)
    local result = Set:new({})

    self:each(function(value)
        if not set:has(value) then result:insert(value) end
    end)

    return result
end

---Returns a symetric difference of two Sets
---@param set Set
---@returns Set
function Set:symmetric_difference(set)
    local difference = Set(self:to_array())

    set:each(function(value)
        if difference:has(value) then
            difference:delete(value)
        else
            difference:insert(value)
        end
    end)

    return difference
end

---Returns true if set has all items present in the subset
---@param subset Set
---@returns boolean
function Set:is_superset(subset)
    return self:every(function(value) return subset:has(value) end)
end

-- local a = Set:new({ 'test', 'temp' })
-- a:print()
-- vim.print(a:to_string())
-- -- vim.print(a)
-- vim.print('a has test')
-- vim.print(a:has('test'))
-- vim.print(a:to_array())
-- a:each(function(item) print(item) end)
-- local b = Set:new({ 'b', 'temp' })
--
-- vim.print(a:to_string())
-- vim.print(b:to_string())
-- local c = Set:new(a:to_array())
-- vim.print(a:to_string())
-- vim.print(b:to_string())
-- vim.print(c:to_string())
-- vim.print(c:has('test'))
-- vim.print(a:union(b):to_string())
-- vim.print(a:to_string())
-- vim.print(b:to_string())
--
-- vim.print(a:intersection(b):to_string())
-- vim.print(a:to_string())
-- vim.print(b:to_string())
M.Set = Set
return M
