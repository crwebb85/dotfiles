local M = {}

--Returns a dot repeatable version of a function to be used in keymaps
--that pressing `.` will repeat the action.
--Example: `vim.keymap.set('n', 'ct', dot_repeat(function() print(os.clock()) end), { expr = true })`
--Setting expr = true in the keymap is required for this function to make the keymap repeatable
--based on gist: https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3
function M.dot_repeat(
    callback --[[Function]]
)
    return function()
        _G.dot_repeat_callback = callback
        vim.go.operatorfunc = 'v:lua.dot_repeat_callback'
        return 'g@l'
    end
end

-------------------------------------------------------------------------------
--- Navigator keymap helpers

---There are two ways to specify the description:
---* A table with the backward and forward descriptions:
---  `{ backward = 'move backward', forward = 'move forward' }`
---* Template string:
---  `'move {backward|forward}'`
---@alias MyListNavigatorDesc string | {backward: string, forward: string}

local function validate_navigator_desc(desc)
    local desc_type = type(desc)
    if desc_type == 'table' then
        if type(desc.backward) ~= 'string' then
            return false, '`backward` is missing or not a string'
        end
        if type(desc.forward) ~= 'string' then
            return false, '`forward` is missing or not a string'
        end
        return true
    elseif desc then
        return desc_type == 'string'
    else
        return true
    end
end

---@param desc MyListNavigatorDesc
---@param i integer
local function process_desc(desc, i)
    if type(desc) == 'table' then
        return desc[({ 'backward', 'forward' })[i]]
    elseif desc then
        vim.validate({
            desc = { desc, 'string' },
        })
        return desc:gsub('{(.-)}', function(m)
            local parts = vim.split(m, '|', { plain = true })
            if #parts == 2 then return parts[i] end
        end)
    end
end

---@class MyListNavigatorKeymapOpts
---@field key string
---@field mode string | table | nil keymap modes (overrides the default modes if defined)
---@field backward string|function
---@field forward string|function
---@field desc MyListNavigatorDesc?
---@field opts vim.keymap.set.Opts?

---@class MyListNavigatorKeymap
---@field default MyListNavigatorKeymapOpts
---@field extreme MyListNavigatorKeymapOpts?

---@class MyOperationsOptions
---@field forward_key string Leader keys for turning the operation backward
---@field backward_key string Leader keys for running the operation forward
---@field mode string | table Default mode for all keymaps defined by operations (can be overriden by keymap)

---@class MyOperations
---@field _opts MyOperationsOptions
---@field _repeat_backward_callback fun()
---@field _repeat_forward_callback fun()
---@field _repeat_extreme_backward_callback fun()
---@field _repeat_extreme_forward_callback fun()
---@field repeat_backward_callback fun()
---@field repeat_forward_callback fun()
---@field repeat_extreme_backward_callback fun()
---@field repeat_extreme_forward_callback fun()
local MyOperations = {
    _repeat_backward_callback = function()
        vim.notify('No callback set', vim.log.levels.WARN)
    end,
    _repeat_forward_callback = function()
        vim.notify('No callback set', vim.log.levels.WARN)
    end,
    _repeat_extreme_backward_callback = function()
        vim.notify('No callback set', vim.log.levels.WARN)
    end,
    _repeat_extreme_forward_callback = function()
        vim.notify('No callback set', vim.log.levels.WARN)
    end,
}

--- Based on https://github.com/idanarye/nvim-impairative modified to have repeat callbacks
--- and have combined functionality into a single navigator method
---@param args MyListNavigatorKeymap
---@return MyOperations
function MyOperations:navigator(args)
    vim.validate({
        default = { args.default, 'table', false },
        extreme = { args.extreme, 'table', true },
    })
    vim.validate({
        key = { args.default.key, 'string', false },
        mode = { args.default.mode, { 'string', 'table' }, true },
        backward = {
            args.default.backward,
            { 'string', 'function' },
            false,
        },
        forward = {
            args.default.forward,
            { 'string', 'function' },
            false,
        },
        desc = {
            args.default.desc,
            validate_navigator_desc,
            'MyListNavigatorDesc',
        },
        opts = { args.default.opts, 't', true },
    })

    if args.extreme ~= nil then
        vim.validate({
            key = { args.extreme.key, 'string', false },
            mode = { args.extreme.mode, { 'string', 'table' }, true },
            backward = {
                args.extreme.backward,
                { 'string', 'function' },
                false,
            },
            forward = {
                args.extreme.forward,
                { 'string', 'function' },
                false,
            },
            desc = {
                args.extreme.desc,
                validate_navigator_desc,
                'MyListNavigatorDesc',
            },
            opts = { args.extreme.opts, 't', true },
        })
    end
    -- create a copy of the options so I can modify it
    local default_keymap_opts =
        vim.tbl_deep_extend('keep', {}, args.default.opts or {})
    local function set_callbacks()
        self._repeat_backward_callback = function()
            if type(args.default.backward) == 'string' then
                vim.cmd(args.default.backward)
            else
                args.default.backward()
            end
        end
        self._repeat_forward_callback = function()
            if type(args.default.forward) == 'string' then
                vim.cmd(args.default.forward)
            else
                args.default.forward()
            end
        end
        if args.extreme ~= nil then
            self._repeat_extreme_backward_callback = function()
                if type(args.extreme.backward) == 'string' then
                    vim.cmd(args.extreme.backward)
                else
                    args.extreme.backward()
                end
            end

            self._repeat_extreme_forward_callback = function()
                if type(args.extreme.forward) == 'string' then
                    vim.cmd(args.extreme.forward)
                else
                    args.extreme.forward()
                end
            end
        else
            self._repeat_extreme_backward_callback = function()
                vim.notify('Not extreme enough', vim.log.levels.WARN)
            end
            self._repeat_extreme_forward_callback = function()
                vim.notify('Not extreme enough', vim.log.levels.WARN)
            end
        end
    end

    local backward = function()
        set_callbacks()
        if type(args.default.backward) == 'string' then
            local cmd = args.default.backward
            if 0 < vim.v.count then
                vim.cmd(vim.v.count .. cmd)
            else
                vim.cmd(cmd)
            end
        else
            args.default.backward()
        end
    end

    local forward = function()
        set_callbacks()
        if type(args.default.forward) == 'string' then
            local cmd = args.default.forward
            if 0 < vim.v.count then
                vim.cmd(vim.v.count .. cmd)
            else
                vim.cmd(cmd)
            end
        else
            args.default.forward()
        end
    end

    local default_keymap_mode = args.default.mode or self._opts.mode
    default_keymap_opts.desc = process_desc(args.default.desc, 1)
    vim.keymap.set(
        default_keymap_mode,
        self._opts.backward_key .. args.default.key,
        backward,
        default_keymap_opts
    )

    default_keymap_opts.desc = process_desc(args.default.desc, 2)
    vim.keymap.set(
        default_keymap_mode,
        self._opts.forward_key .. args.default.key,
        forward,
        default_keymap_opts
    )

    if args.extreme ~= nil then
        local extreme_keymap_opts =
            vim.tbl_deep_extend('keep', {}, args.extreme.opts or {})

        local extreme_backward = function()
            set_callbacks()
            if type(args.extreme.backward) == 'string' then
                local cmd = args.extreme.backward
                if 0 < vim.v.count then
                    vim.cmd(vim.v.count .. cmd)
                else
                    vim.cmd(cmd)
                end
            else
                args.extreme.backward()
            end
        end

        local extreme_forward = function()
            set_callbacks()
            if type(args.extreme.forward) == 'string' then
                local cmd = args.extreme.forward
                if 0 < vim.v.count then
                    vim.cmd(vim.v.count .. cmd)
                else
                    vim.cmd(cmd)
                end
            else
                args.extreme.forward()
            end
        end

        local extreme_keymap_mode = args.default.mode or self._opts.mode
        extreme_keymap_opts.desc = process_desc(args.extreme.desc, 1)
        vim.keymap.set(
            extreme_keymap_mode,
            self._opts.backward_key .. args.extreme.key,
            extreme_backward,
            extreme_keymap_opts
        )

        extreme_keymap_opts.desc = process_desc(args.extreme.desc, 2)
        vim.keymap.set(
            extreme_keymap_mode,
            self._opts.forward_key .. args.extreme.key,
            extreme_forward,
            extreme_keymap_opts
        )
    end
    return self
end

---Create an |ImpairativeOperations| helper to define mappings with
---@param opts MyOperationsOptions See |ImpairativeOperationsOptions|
---@return MyOperations
function M.operations(opts)
    vim.validate({
        forward_key = { opts.forward_key, 'string', false },
        backward_key = { opts.backward_key, 'string', false },
        mode = { opts.mode, { 'string', 'table' }, false },
    })
    local operations = setmetatable({
        _opts = opts,

        _repeat_backward_callback = function()
            vim.notify('No backward callback set', vim.log.levels.WARN)
        end,
        _repeat_forward_callback = function()
            vim.notify('No forward callback set', vim.log.levels.WARN)
        end,
    }, {
        __index = MyOperations,
    })
    operations.repeat_backward_callback = function()
        operations._repeat_backward_callback()
    end
    operations.repeat_forward_callback = function()
        operations._repeat_forward_callback()
    end
    operations.repeat_extreme_backward_callback = function()
        operations._repeat_extreme_backward_callback()
    end
    operations.repeat_extreme_forward_callback = function()
        operations._repeat_extreme_forward_callback()
    end
    return operations
end

-------------------------------------------------------------------------------
---Comment keymap helpers

function M.flip_flop_comment()
    --From https://github.com/numToStr/Comment.nvim/issues/17#issuecomment-1268650042
    local U = require('Comment.utils')
    local s = vim.api.nvim_buf_get_mark(0, '[')
    local e = vim.api.nvim_buf_get_mark(0, ']')
    local range = { srow = s[1], scol = s[2], erow = e[1], ecol = e[2] }
    local ctx = {
        ctype = U.ctype.linewise,
        range = range,
    }
    local cstr = require('Comment.ft').calculate(ctx) or vim.bo.commentstring
    local ll, rr = U.unwrap_cstr(cstr)
    local padding = true
    local is_commented = U.is_commented(ll, rr, padding)

    local rcom = {} -- ranges of commented lines
    local cl = s[1] -- current line
    local rs, re = nil, nil -- range start and end
    local lines = U.get_lines(range)
    for _, line in ipairs(lines) do
        if #line == 0 or not is_commented(line) then -- empty or uncommented line
            if rs ~= nil then
                table.insert(rcom, { rs, re })
                rs, re = nil, nil
            end
        else
            rs = rs or cl -- set range start if not set
            re = cl -- update range end
        end
        cl = cl + 1
    end
    if rs ~= nil then table.insert(rcom, { rs, re }) end

    local cursor_position = vim.api.nvim_win_get_cursor(0)
    local vmark_start = vim.api.nvim_buf_get_mark(0, '<')
    local vmark_end = vim.api.nvim_buf_get_mark(0, '>')

    ---Toggle comments on a range of lines
    ---@param sl integer: starting line
    ---@param el integer: ending line
    local toggle_lines = function(sl, el)
        vim.api.nvim_win_set_cursor(0, { sl, 0 }) -- idk why it's needed to prevent one-line ranges from being substituted with line under cursor
        vim.api.nvim_buf_set_mark(0, '[', sl, 0, {})
        vim.api.nvim_buf_set_mark(0, ']', el, 0, {})
        require('Comment.api').locked('toggle.linewise')('')
    end

    toggle_lines(s[1], e[1])
    for _, r in ipairs(rcom) do
        toggle_lines(r[1], r[2]) -- uncomment lines twice to remove previous comment
        toggle_lines(r[1], r[2])
    end

    vim.api.nvim_win_set_cursor(0, cursor_position)
    vim.api.nvim_buf_set_mark(0, '<', vmark_start[1], vmark_start[2], {})
    vim.api.nvim_buf_set_mark(0, '>', vmark_end[1], vmark_end[2], {})
end
return M
