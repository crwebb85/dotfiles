local M = {}

---@class MyMemoryCacheEntry
---@field key string
---@field value any
---@field last_accessed_timestamp integer epoch time in seconds the entry was last accessed (get/set)
---@field sliding_expiration_timespan integer? the number of seconds the item must be unused before it will be evicted. If nil, the entry won't be expired based on time last accessed.
---@field absolute_expiration_timestamp integer? the epoch time in seconds that the entry will be expired regardless of last usage

---@class MyMemoryCacheItemPolicy
---@field absolute_expiration_timespan integer? the number of seconds that the cache entry will be evicted regardless how recently it was used. If  nil, the entry won't be expired based on an absolute time span.
---@field sliding_expiration_timespan integer? the number of seconds the item must be unused before it will be evicted. If nil, the entry won't be expired based on time last accessed.

---@class MyMemoryCache
---@field private cache table<string, MyMemoryCacheEntry>
local MyMemoryCache = setmetatable({}, {})
MyMemoryCache.__index = MyMemoryCache

---@param cache_item MyMemoryCacheEntry
---@return boolean
local function is_expired(cache_item)
    local timestamp = os.time()
    if
        cache_item.absolute_expiration_timestamp ~= nil
        and cache_item.absolute_expiration_timestamp <= timestamp
    then
        return true
    end
    if
        cache_item.sliding_expiration_timespan
        and cache_item.sliding_expiration_timespan
                + cache_item.last_accessed_timestamp
            <= timestamp
    then
        return true
    end
    return false
end

---Gets the value for the key if in the cache. If not in the cache it will run the
---create_callback to get the value and adds it to the cache based on the
---@param key string
---@param create_callback fun(): any
---@param opts MyMemoryCacheItemPolicy
---@return any
function MyMemoryCache:get_or_create(key, create_callback, opts)
    -- vim.print('get_or_create')
    -- TODO validate that
    -- opts.sliding_expiration_timespan > 0 or nil
    -- opts.absolute_expiration_timespan > 0 or nil
    -- opts.sliding_expiration_timespan <= opts.absolute_expiration_timespan if both not nil

    local cache_item = self.cache[key]
    if cache_item ~= nil and not is_expired(cache_item) then
        cache_item.last_accessed_timestamp = os.time()
        return cache_item.value
    end

    local value = create_callback()
    local timestamp = os.time()
    local new_cache_item = {
        key = key,
        value = value,
        last_accessed_timestamp = timestamp,
        sliding_expiration_timespan = opts.sliding_expiration_timespan,
        absolute_expiration_timestamp = timestamp
            + opts.absolute_expiration_timespan,
    }
    self.cache[key] = new_cache_item
    --TODO add a timer to cleanup expired cache items and a dispose function to cleanup
    --timer if the cache object is garbage collected

    return value
end

---Creates a new memory cache
---@return MyMemoryCache
function M.create_ttl_cache()
    local cache = setmetatable({ cache = {} }, {
        __index = MyMemoryCache,
    })

    return cache
end

return M
