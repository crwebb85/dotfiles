local M = {}

-- --- Throttles a function. Automatically `schedule_wrap()`s.
-- --- This runs on both edges of a sequence of calls so that you always get
-- --- immediant feedback on the leading edge but also prevents the last call
-- --- in the sequence from getting skipped.
-- ---
-- ---@param fn (function) Function to throttle. fn can take any number of arguments
-- ---@param timeout (number) Timeout in ms
-- ---@returns (function, timer) Throttled function and timer. Remember to call
-- ---`timer:close()` at the if you are done with the throttled function or you
-- ---will leak memory!
-- function M.throttle(fn, timeout)
--     local Deque = require('myconfig.utils.datastructure').Deque
--     local running = false
--     local arg_queue = Deque.new()
--     local timer = vim.uv.new_timer()
--     if timer == nil then error('Somehow the new timer was nil ... wtf') end
--     local wrapped_fn = function(...)
--         -- vim.print('hi')
--         local argv = { ... }
--         local argc = select('#', ...)
--
--         if not timer:is_active() then
--             vim.schedule(function()
--                 running = true
--                 local ok, err = pcall(fn, unpack(argv, 1, argc))
--                 running = false
--                 if not ok and err ~= nil then error(err) end
--             end)
--
--             timer:start(timeout, timeout, function()
--                 if Deque.size(arg_queue) <= 0 then
--                     timer:stop()
--                     return
--                 end
--                 if not running then
--                     local argv_next, argc_next =
--                         unpack(Deque.popleft(arg_queue))
--                     running = true
--                     local ok, err = pcall(fn, unpack(argv_next, 1, argc_next))
--                     running = false
--                     if not ok and err ~= nil then error(err) end
--                 end
--             end)
--         elseif Deque.size(arg_queue) < 1 then
--             Deque.pushright(arg_queue, { argv, argc })
--         elseif Deque.size(arg_queue) == 1 then
--             Deque.popright(arg_queue) -- discard last arguments queued
--             Deque.pushright(arg_queue, { argv, argc }) --replace with new arguments
--         end
--     end
--     return wrapped_fn, timer
-- end

--- Throttles a function. Automatically `schedule_wrap()`s.
--- This runs on both edges of a sequence of calls so that you always get
--- immediate feedback on the leading edge but also prevents the last call
--- in the sequence from getting skipped.
---
---@param fn function Function to throttle. fn can take any number of arguments
---@param timeout integer Timeout in ms
---@returns (function, timer) Throttled function and timer. Remember to call
---`timer:close()` at the if you are done with the throttled function or you
---will leak memory!
function M.throttle(fn, timeout)
    local Deque = require('myconfig.utils.datastructure').Deque
    local running = false
    local arg_queue = Deque.new()
    local timer = vim.uv.new_timer()
    if timer == nil then error('Somehow the new timer was nil ... wtf') end
    local wrapped_fn = function(...)
        -- vim.print('hi')
        local argv = { ... }
        local argc = select('#', ...)

        if not timer:is_active() then
            running = true
            vim.schedule(function()
                local ok, err = pcall(fn, unpack(argv, 1, argc))
                running = false
                if not ok and err ~= nil then error(err) end
            end)

            timer:start(timeout, timeout, function()
                if Deque.size(arg_queue) <= 0 then
                    timer:stop()
                    return
                end
                ---@diagnostic disable-next-line: unknown-diag-code
                ---@diagnostic disable-next-line: unnecessary-if
                if not running then
                    running = true
                    vim.schedule(function()
                        if Deque.size(arg_queue) <= 0 then return end
                        local argv_next, argc_next =
                            unpack(Deque.popleft(arg_queue))
                        local ok, err =
                            pcall(fn, unpack(argv_next, 1, argc_next))
                        running = false
                        if not ok and err ~= nil then error(err) end
                    end)
                end
            end)
        elseif Deque.size(arg_queue) < 1 then
            Deque.pushright(arg_queue, { argv, argc })
        elseif Deque.size(arg_queue) == 1 then
            Deque.popright(arg_queue) -- discard last arguments queued
            Deque.pushright(arg_queue, { argv, argc }) --replace with new arguments
        end
    end
    return wrapped_fn, timer
end

return M
