local library = { vim.fs.normalize('$VIMRUNTIME') }

local data_path = vim.fn.stdpath('data')
if data_path == nil then
    error('data path was nil but a string was expected')
elseif type(data_path) == 'table' then
    error('data path was an array but a string was expected')
end

local lazy_path = vim.fs.joinpath(data_path, 'lazy')

for name, type in vim.fs.dir(lazy_path, { depth = 1 }) do
    if type == 'directory' then
        local plugin_path = vim.fs.joinpath(lazy_path, name)
        table.insert(library, plugin_path)
    end
end

return {
    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT',
                requirePattern = {
                    'lua/?.lua',
                    'lua/?/init.lua',
                    '?/lua/?.lua',
                    '?/lua/?/init.lua',
                },
            },
            workspace = {
                library = library,
            },
            ignoreGlobs = { '**/*_spec.lua' },
            diagnostics = {
                globals = { 'vim' },
            },
        },
    },
}

--Some example emmylua_ls files I tried but need to try some more settings

-- {
--   "$schema": "https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/refs/heads/main/crates/emmylua_code_analysis/resources/schema.json",
--   "runtime": {
--     "version": "LuaJIT",
--     "requirePattern": [
--       "lua/?.lua",
--       "lua/?/init.lua",
--       "?/lua/?.lua",
--       "?/lua/?/init.lua"
--     ]
--   },
--   "workspace": {
--     "library": [
--       "C:\\nvim-win64\\share\\nvim\\runtime",
--       "C:\\Users\\crweb\\AppData\\Local\\nvim-data\\lazy\\"
--     ]
--   },
--   "diagnostics": {
--     "globals": ["vim"]
--   }
-- }

-- {
--   "$schema": "https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/refs/heads/main/crates/emmylua_code_analysis/resources/schema.json",
--   "runtime": {
--     "classDefaultCall": {
--         "forceNonColon": false,
--         "forceReturnSelf": false,
--         "functionName": ""
--     },
--     "extensions": [],
--     "frameworkVersions": [],
--     "nonstandardSymbol": [],
--     "requireLikeFunction": [],
--     "requirePattern": [],
--     "version": "LuaLatest"
--   }
--   "runtime": {
--     "version": "LuaJIT", // the version nvim uses
--     "requirePattern": [
--       "lua/?.lua",
--       "lua/?/init.lua",
--       "?/lua/?.lua", // this allows plugins to be loaded
--       "?/lua/?/init.lua"
--     ]
--   },
--   "workspace": {
--     "library": [
--       // "$VIMRUNTIME" // for vim.*
--       // "$LLS_Addons/luvit" // for vim.uv.*
--       // (should not be needed in future from what I hear.
--       // I just set $LLS_Addons in my .zshrc to the dir where I
--       // recursively cloned https://github.com/LuaLS/LLS-Addons)
--       //"$HOME/.local/share/nvim/lazy"   <--- plugins dir, change to something else if
--       //you don't use lazy.nvim
--     ]
--
--     // "ignoreGlobs": ["**/*_spec.lua"] // to avoid some weird type defs in a plugin
--   },
-- }
