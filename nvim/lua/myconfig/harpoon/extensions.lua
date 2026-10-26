--vendored plugin from https://github.com/ThePrimeagen/harpoon/blob/87b1a3506211538f460786c23f98ec63ad9af4e5/lua/harpoon/extensions/init.lua

---@class MyHarpoonExtensions
---@field listeners MyHarpoonExtension[]
local MyHarpoonExtensions = {}

---@class MyHarpoonExtension
---@field ADD? fun(...): nil
---@field SELECT? fun(...): nil
---@field REMOVE? fun(...): nil
---@field REORDER? fun(...): nil
---@field UI_CREATE? fun(...): nil
---@field SETUP_CALLED? fun(...): nil
---@field LIST_CREATED? fun(...): nil
---@field LIST_READ? fun(...): nil
---@field NAVIGATE? fun(...): nil
---@field POSITION_UPDATED? fun(...): nil

MyHarpoonExtensions.__index = MyHarpoonExtensions

function MyHarpoonExtensions:new()
    return setmetatable({
        listeners = {},
    }, self)
end

---@param extension MyHarpoonExtension
function MyHarpoonExtensions:add_listener(extension)
    table.insert(self.listeners, extension)
end

function MyHarpoonExtensions:clear_listeners() self.listeners = {} end

---@param type string
---@param ... any
function MyHarpoonExtensions:emit(type, ...)
    for _, cb in ipairs(self.listeners) do
        if cb[type] then cb[type](...) end
    end
end

local extensions = MyHarpoonExtensions:new()
local Builtins = {}

function Builtins.command_on_nav(cmd)
    return {
        NAVIGATE = function() vim.cmd(cmd) end,
    }
end

function Builtins.navigate_with_number()
    return {
        UI_CREATE = function(cx)
            for i = 1, 9 do
                vim.keymap.set(
                    'n',
                    '' .. i,
                    function() require('myconfig.harpoon'):list():select(i) end,
                    { buffer = cx.bufnr }
                )
            end
        end,
    }
end

function Builtins.highlight_current_file()
    return {
        UI_CREATE = function(cx)
            for line_number, file in pairs(cx.contents) do
                if string.find(cx.current_file, file, 1, true) then
                    -- highlight the harpoon menu line that corresponds to the current buffer
                    vim.api.nvim_buf_add_highlight(
                        cx.bufnr,
                        -1,
                        'CursorLineNr',
                        line_number - 1,
                        0,
                        -1
                    )
                    -- set the position of the cursor in the harpoon menu to the start of the current buffer line
                    vim.api.nvim_win_set_cursor(cx.win_id, { line_number, 0 })
                end
            end
        end,
    }
end

return {
    builtins = Builtins,
    extensions = extensions,
    event_names = {
        REPLACE = 'REPLACE',
        ADD = 'ADD',
        SELECT = 'SELECT',
        REMOVE = 'REMOVE',
        POSITION_UPDATED = 'POSITION_UPDATED',

        --- This exists because the ui can change the list in dramatic ways
        --- so instead of emitting a REMOVE, then an ADD, then a REORDER, we
        --- instead just emit LIST_CHANGE
        LIST_CHANGE = 'LIST_CHANGE',

        REORDER = 'REORDER',
        UI_CREATE = 'UI_CREATE',
        SETUP_CALLED = 'SETUP_CALLED',
        LIST_CREATED = 'LIST_CREATED',
        NAVIGATE = 'NAVIGATE',
        LIST_READ = 'LIST_READ',
    },
}
