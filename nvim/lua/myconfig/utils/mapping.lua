local M = {}

-------------------------------------------------------------------------------
---Dot repeat

---Vim operator-mode motion enum. Read |:map-operator|
---@alias OpMotionMode
---| '"line"' # The operation motion was linewise (virtical)
---| '"char"' # The operation motion was charwise (horizontal)
---| '"block"' # The operation motion was blockwise-visual

--- Returns a dot repeatable version of a function to be used in keymaps
--- that pressing `.` will repeat the action.
--- Example: `vim.keymap.set('n', 'ct', dot_repeat(function() print(os.clock()) end), { expr = true })`
--- Setting expr = true in the keymap is required for this function to make the keymap repeatable
--- based on gist: https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3
--- @param callback fun(op_motion_mode:OpMotionMode) The callback to run when dot repeating.
--- @param expr string? The expr to return (default 'g@l') must have g@ followed by a motion in it
--- @return fun(): string dot-repeatable version of the function. Returns expr when called
--- @example This allows you to make a dotrepeatable function to be used in a keymap
--- ```lua
--- vim.keymap.set(
---     'n',
---     '<leader>vs',
---    require('myconfig.utils.mapping').dot_repeat(
---        function()
---            print(os.clock())
---        end,
---        'g@l'
---    ),
---     { expr = true }
--- )
--- ```
function M.dot_repeat(callback, expr)
    if expr == nil then expr = 'g@l' end
    return function()
        -- Note: we can now us lua functions directly for operatorfunc
        -- without the whole reference a global function rodeo
        --
        -- Example of old way:
        -- ```lua
        --     _G.dot_repeat_callback = debug_callback
        --     vim.go.operatorfunc = 'v:lua.dot_repeat_callback'
        -- ```

        vim.go.operatorfunc = callback
        return expr
    end
end

--- Returns a dot repeatable version of a function to be used in keymaps
--- that pressing `.` will repeat the action.
--- Setting expr = true in the keymap is required for this function to make the keymap repeatable
--- based on gist: https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3
--- @param callback fun(motion:string) The callback to run when dot repeating. Motion is the motion after the g@ in expr
--- @param expr string? The expr to return (default 'g@l') must have g@ followed by a motion in it
--- @return string expression to return to the keymap after running
--- @example This allows you to make a dotrepeatable function with configuration
--- determined at the time the keymap was first ran like below
--- ```lua
--- vim.keymap.set(
---     'n',
---     '<leader>vs',
---     function()
---         local time = os.clock()
---         return require('myconfig.utils.mapping').make_dot_repeat_and_run(function() print(time) end)
---     end,
---     { expr = true }
--- )
--- ```
function M.make_dot_repeat_and_run(callback, expr)
    local dot_repeatable_fn = M.dot_repeat(callback, expr)
    return dot_repeatable_fn()
end

-------------------------------------------------------------------------------
--- smart navigation

---Runs the callback or cmd and if the cursor has changed it will vertically
---center the window and open the folds so that you can see the cursor
---
---Note: I check that the cursor actually moves rather than running it zz and zO on all
---executions since I want to be able to use this in places like my MyOperations metatable
---below that may be used with things that don't move the cursor
---@param nav_callback string|function
---@param prepend_count boolean? Append vim.v.count1 to command if nav_callback is a command. Default is true
function M.smart_nav(nav_callback, prepend_count)
    if prepend_count == nil then prepend_count = true end
    local original_winnr = vim.api.nvim_get_current_win()
    local original_bufnr = vim.api.nvim_get_current_buf()
    local original_cursor = vim.api.nvim_win_get_cursor(original_winnr)

    if type(nav_callback) == 'string' then
        if prepend_count then
            vim.cmd(vim.v.count1 .. nav_callback)
        else
            vim.cmd(nav_callback)
        end
    else
        nav_callback()
    end

    local new_bufnr = vim.api.nvim_get_current_buf()
    local new_winnr = vim.api.nvim_get_current_win()
    local new_cursor = vim.api.nvim_win_get_cursor(new_winnr)
    if
        original_bufnr ~= new_bufnr --need to compare bufnr not winnr
        or original_cursor[1] ~= new_cursor[1]
        or original_cursor[2] ~= new_cursor[2]
    then
        --open folds if the cursor is within a fold and the cursor has moved
        local new_cursor_line_number = new_cursor[1]
        if
            vim.wo.foldenable
            --need to check if the fold is closed to prevent throwing errors when trying to open a non-existent fold
            and vim.fn.foldclosed(new_cursor_line_number) >= 0
        then
            vim.cmd('normal! zO')
        end
        --center cursor vertically if the cursor has moved
        vim.cmd('normal! zz')
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
        vim.validate('desc', desc, 'string')
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
---@field backward_repeat string|function|nil (default: value of backward field)
---@field forward_repeat string|function|nil (default: value of forward field)
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
---@field isLastCallbackExtreme boolean
---@field repeat_backward_callback fun()
---@field repeat_forward_callback fun()
---@field repeat_extreme_backward_callback fun()
---@field repeat_extreme_forward_callback fun()
local MyOperations = {
    isLastCallbackExtreme = false,
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
    vim.validate('args', args, 'table', false)
    vim.validate('args.default', args.default, 'table', false)
    vim.validate('args.extreme', args.extreme, 'table', true)
    vim.validate('args.default.key', args.default.key, 'string', false)
    vim.validate(
        'args.default.mode',
        args.default.mode,
        { 'string', 'table' },
        true
    )
    vim.validate(
        'args.default.backward',
        args.default.backward,
        { 'string', 'function' },
        false
    )
    vim.validate(
        'args.default.forward',
        args.default.forward,
        { 'string', 'function' },
        false
    )

    vim.validate(
        'args.default.backward_repeat',
        args.default.backward_repeat,
        { 'string', 'function' },
        true
    )
    vim.validate(
        'args.default.forward_repeat',
        args.default.forward_repeat,
        { 'string', 'function' },
        true
    )

    vim.validate(
        'args.default.desc',
        args.default.desc,
        validate_navigator_desc,
        false,
        'MyListNavigatorDesc'
    )
    vim.validate('args.default.opts', args.default.opts, 'table', true)

    if args.extreme ~= nil then
        vim.validate('args.extreme.key', args.extreme.key, 'string', false)
        vim.validate(
            'args.extreme.mode',
            args.extreme.mode,
            { 'string', 'table' },
            true
        )
        vim.validate(
            'args.extreme.backward',
            args.extreme.backward,
            { 'string', 'function' },
            false
        )
        vim.validate(
            'args.extreme.forward',
            args.extreme.forward,
            { 'string', 'function' },
            false
        )
        vim.validate(
            'args.extreme.desc',
            args.extreme.desc,
            validate_navigator_desc,
            false,
            'MyListNavigatorDesc'
        )
        vim.validate('args.extreme.opts', args.extreme.opts, 'table', true)
    end
    -- create a copy of the options so I can modify it
    local default_keymap_opts =
        vim.tbl_deep_extend('keep', {}, args.default.opts or {})

    local function set_callbacks(isLastCallbackExtreme)
        self.isLastCallbackExtreme = isLastCallbackExtreme
        self._repeat_backward_callback = function()
            local backward = args.default.backward_repeat
                or args.default.backward
            if type(backward) == 'string' then
                vim.cmd(backward)
            else
                backward()
            end
        end
        self._repeat_forward_callback = function()
            local forward = args.default.forward_repeat or args.default.forward
            if type(forward) == 'string' then
                vim.cmd(forward)
            else
                forward()
            end
        end
        if args.extreme ~= nil then
            self._repeat_extreme_backward_callback = function()
                local extreme_backward = args.extreme.backward_repeat
                    or args.extreme.backward
                if type(extreme_backward) == 'string' then
                    vim.cmd(extreme_backward)
                else
                    extreme_backward()
                end
            end

            self._repeat_extreme_forward_callback = function()
                local extreme_forward = args.extreme.forward_repeat
                    or args.extreme.forward
                if type(extreme_forward) == 'string' then
                    vim.cmd(extreme_forward)
                else
                    extreme_forward()
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

    local default_keymap_mode = args.default.mode or self._opts.mode
    default_keymap_opts.desc = process_desc(args.default.desc, 1)
    vim.keymap.set(
        default_keymap_mode,
        self._opts.backward_key .. args.default.key,
        function()
            set_callbacks(false)
            M.smart_nav(args.default.backward)
        end,
        default_keymap_opts
    )

    default_keymap_opts.desc = process_desc(args.default.desc, 2)
    vim.keymap.set(
        default_keymap_mode,
        self._opts.forward_key .. args.default.key,
        function()
            set_callbacks(false)
            M.smart_nav(args.default.forward)
        end,
        default_keymap_opts
    )

    if args.extreme ~= nil then
        local extreme_keymap_opts =
            vim.tbl_deep_extend('keep', {}, args.extreme.opts or {})

        local extreme_keymap_mode = args.default.mode or self._opts.mode
        extreme_keymap_opts.desc = process_desc(args.extreme.desc, 1)
        vim.keymap.set(
            extreme_keymap_mode,
            self._opts.backward_key .. args.extreme.key,
            function()
                set_callbacks(true)
                M.smart_nav(args.default.backward)
            end,
            extreme_keymap_opts
        )

        extreme_keymap_opts.desc = process_desc(args.extreme.desc, 2)
        vim.keymap.set(
            extreme_keymap_mode,
            self._opts.forward_key .. args.extreme.key,
            function()
                set_callbacks(true)
                M.smart_nav(args.default.forward)
            end,
            extreme_keymap_opts
        )
    end
    return self
end

---Create an |ImpairativeOperations| helper to define mappings with
---@param opts MyOperationsOptions See |ImpairativeOperationsOptions|
---@return MyOperations
function M.operations(opts)
    vim.validate('opts', opts, 'table', false)
    vim.validate('opts.forward_key', opts.forward_key, 'string', false)
    vim.validate('backward_key', opts.backward_key, 'string', false)
    vim.validate('mode', opts.mode, { 'string', 'table' }, false)
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
---Operators

function M.select_indent(around)
    local start_indent = vim.fn.indent(vim.fn.line('.'))
    local blank_line_pattern = '^%s*$'

    if string.match(vim.fn.getline('.'), blank_line_pattern) then return end

    if vim.v.count > 0 then
        start_indent = start_indent - vim.o.shiftwidth * (vim.v.count - 1)
        if start_indent < 0 then start_indent = 0 end
    end

    local prev_line = vim.fn.line('.') - 1
    local prev_blank_line = function(line)
        return string.match(vim.fn.getline(line), blank_line_pattern)
    end
    while
        prev_line > 0
        and (
            prev_blank_line(prev_line)
            or vim.fn.indent(prev_line) >= start_indent
        )
    do
        vim.cmd('-')
        prev_line = vim.fn.line('.') - 1
    end
    if around then vim.cmd('-') end

    vim.cmd('normal! 0V')

    local next_line = vim.fn.line('.') + 1
    local next_blank_line = function(line)
        return string.match(vim.fn.getline(line), blank_line_pattern)
    end
    local last_line = vim.fn.line('$')
    while
        next_line <= last_line
        and (
            next_blank_line(next_line)
            or vim.fn.indent(next_line) >= start_indent
        )
    do
        vim.cmd('+')
        next_line = vim.fn.line('.') + 1
    end
    if around then vim.cmd('+') end
end

return M
