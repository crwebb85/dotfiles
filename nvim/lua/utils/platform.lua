-- Based on https://github.com/williamboman/mason.nvim/blob/main/lua/mason-core/platform.lua
-- The code I based this on had a custom functional programming library but I converted
-- it to just use standard lua. I may have made errors during that conversion.

local M = {}

local uname = vim.loop.os_uname()

-- Most of the code that calls into these functions executes outside of the main event loop, where API/fn functions are
-- disabled. We evaluate these immediately here to avoid issues with main loop synchronization.
local cached_features = {
    ['win'] = vim.fn.has('win32'),
    ['win32'] = vim.fn.has('win32'),
    ['win64'] = vim.fn.has('win64'),
    ['mac'] = vim.fn.has('mac'),
    ['darwin'] = vim.fn.has('mac'),
    ['unix'] = vim.fn.has('unix'),
    ['linux'] = vim.fn.has('linux'),
}

local function system(args)
    if vim.fn.executable(args[1]) == 1 then
        local ok, output = pcall(vim.fn.system, args)
        if ok and (vim.v.shell_error == 0 or vim.v.shell_error == 1) then
            return true, output
        end
        return false, output
    end
    return false, args[1] .. ' is not executable'
end

---@return ('"glibc"' | '"musl"')?
local get_libc = function()
    local getconf_ok, getconf_output = system({ 'getconf', 'GNU_LIBC_VERSION' })
    if
        getconf_ok
        and getconf_output ~= nil
        and getconf_output:find('glibc')
    then
        return 'glibc'
    end
    local ldd_ok, ldd_output = system({ 'ldd', '--version' })
    if ldd_ok then
        if ldd_output ~= nil and ldd_output:find('musl') then
            return 'musl'
        elseif
            ldd_output ~= nil
            and (
                ldd_output:find('GLIBC')
                or ldd_output:find('glibc')
                or ldd_output:find('GNU')
            )
        then
            return 'glibc'
        end
    end
end

--- Not sure if I wrote this correctly
---@param env string
---@return boolean
local function check_env(env)
    if env == 'musl' then
        return get_libc() == 'musl'
    elseif get_libc() == 'gnu' then
        return get_libc() == 'glibc'
    elseif env == 'openbsd' then
        return uname.sysname == 'OpenBSD'
    end
    return false
end

---Table that allows for checking whether the provided targets apply to the current system.
---Each key is a target tuple consisting of at most 3 targets, in the following order:
--- 1) OS (e.g. linux, unix, darwin, win) - Mandatory
--- 2) Architecture (e.g. arm64, x64) - Optional
--- 3) Environment (e.g. gnu, musl, openbsd) - Optional
---Each target is separated by a "_" character, like so: "linux_x64_musl".
---@type table<string, boolean>
M.is = setmetatable({}, {
    __index = function(_, key)
        local os, arch, env = unpack(vim.split(key, '_', { plain = true }))
        if not cached_features[os] or cached_features[os] ~= 1 then
            return false
        end
        if arch and arch ~= M.arch then return false end
        if env and not check_env(env) then return false end
        return true
    end,
})

return M
