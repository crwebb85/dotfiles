-- copied from https://github.com/nvim-lua/plenary.nvim/blob/74b06c6c75e4eeb3108ec01852001636d85a932b/lua/say.lua
-- which seems to be from https://github.com/lunarmodules/say/blob/9951aa8f1891d3eeb23e01151f328d47f35f2738/src/init.lua
local unpack = table.unpack or unpack

local registry = {}
local current_namespace
local fallback_namespace

local s = {

    _COPYRIGHT = 'Copyright (c) 2012 Olivine Labs, LLC.',
    _DESCRIPTION = 'A simple string key/value store for i18n or any other case where you want namespaced strings.',
    _VERSION = 'Say 1.2',

    set_namespace = function(self, namespace)
        current_namespace = namespace
        if not registry[current_namespace] then
            registry[current_namespace] = {}
        end
    end,

    set_fallback = function(self, namespace)
        fallback_namespace = namespace
        if not registry[fallback_namespace] then
            registry[fallback_namespace] = {}
        end
    end,

    set = function(self, key, value) registry[current_namespace][key] = value end,
}

local __meta = {
    __call = function(self, key, vars)
        vars = vars or {}

        local str = registry[current_namespace][key]
            or registry[fallback_namespace][key]

        if str == nil then return nil end
        str = tostring(str)
        local strings = {}

        for i, v in ipairs(vars) do
            table.insert(strings, tostring(v))
        end

        return #strings > 0 and str:format(unpack(strings)) or str
    end,

    __index = function(self, key) return registry[key] end,
}

s:set_fallback('en')
s:set_namespace('en')

s._registry = registry

return setmetatable(s, __meta)
