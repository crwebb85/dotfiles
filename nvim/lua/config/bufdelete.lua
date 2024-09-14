--Modified from https://github.com/famiu/bufdelete.nvim/blob/f6bcea78afb3060b198125256f897040538bcb81/lua/bufdelete/init.lua
--Main modifications include:
-- - Added type annotations
-- - Added return to buf_kill to return the set of buffers successfully killed
-- - Added path normalizing when search for buffer with a buffer name pattern to
--   hackily handle paths on Windows better (may screw up regex patterns)
-- - Added some more nil handling
-- - added function to close all inactive unsaved buffers

local M = {}

--- Returns buffer name. Returns "[No Name]" if buffer is empty
---@param bufnr uinteger
---@return string
local function bufname(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)

    if name == '' then return '[No Name]' end

    return name
end

---Prompt user for choice.
---This captures the first character inputted after the prompt is shown and returns it.
---@param text string
---@param choices string[]
---@return string
local function char_prompt(text, choices)
    local choice = vim.fn.confirm(text, table.concat(choices, '\n'), '', 'Q')
    if choice == 0 then
        return 'C' -- Cancel if no choice was made
    else
        return string.match(choices[choice], '&?(%a)')
    end
end

---Common kill function for Bdelete and Bwipeout.
---@param target_buffers uinteger[]
---@param switchable_buffers uinteger[]?
---@param force boolean?
---@param wipeout boolean?
---@return table<uinteger, boolean> -- buffer number set of buffers killed
local function buf_kill(target_buffers, switchable_buffers, force, wipeout)
    -- Target buffers. Stored in a set-like format to quickly check if buffer needs to be deleted.
    local buf_is_deleted = {}
    for _, v in ipairs(target_buffers) do
        buf_is_deleted[v] = true
    end

    -- If force is disabled, check for modified buffers in range.
    if not force then
        for bufnr, _ in pairs(buf_is_deleted) do
            -- If buffer is modified, prompt user for action.
            if vim.bo[bufnr].modified then
                local choice = char_prompt(
                    string.format(
                        'No write since last change for buffer %d (%s).',
                        bufnr,
                        bufname(bufnr)
                    ),
                    { '&Save', '&Ignore', '&Cancel' }
                )

                if choice == 's' or choice == 'S' then -- Save changes to the buffer.
                    vim.api.nvim_buf_call(bufnr, function() vim.cmd.write() end)
                elseif choice ~= 'i' and choice ~= 'I' then -- If not ignored, remove buffer from targets.
                    buf_is_deleted[bufnr] = nil
                end
            elseif
                vim.bo[bufnr].buftype == 'terminal'
                and vim.fn.jobwait({ vim.bo[bufnr].channel }, 0)[1] == -1
            then
                local choice = char_prompt(
                    string.format(
                        'Terminal buffer %d (%s) is still running.',
                        bufnr,
                        bufname(bufnr)
                    ),
                    { '&Ignore', '&Cancel' }
                )

                if choice ~= 'i' and choice ~= 'I' then
                    buf_is_deleted[bufnr] = nil
                end
            end
        end
    end

    if next(buf_is_deleted) == nil then
        -- No targets, do nothing
        vim.api.nvim_err_writeln('bufdelete.nvim: No buffers were deleted')
        return {}
    end

    -- Get list of windows IDs with the buffers to close.
    local windows = vim.tbl_filter(
        function(win)
            return buf_is_deleted[vim.api.nvim_win_get_buf(win)] ~= nil
        end,
        vim.api.nvim_list_wins()
    )

    -- If switchable_buffers is provided by user, use it.
    -- Otherwise, if vim.g.bufdelete_buf_filter is non-nil, use it to generate a buffer list.
    -- Otherwise, just use a list of all valid and listed buffers.
    if switchable_buffers ~= nil then
        -- Nothing to do.
    elseif vim.g.bufdelete_buf_filter ~= nil then
        switchable_buffers = vim.g.bufdelete_buf_filter()
    else
        -- Get list of valid and listed buffers.
        switchable_buffers = vim.tbl_filter(
            function(buf)
                return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
            end,
            vim.api.nvim_list_bufs()
        )
    end

    -- Filter buffers targeted for deletion from the buffer list.
    local undeleted_buffers = vim.tbl_filter(
        function(buf) return not buf_is_deleted[buf] end,
        switchable_buffers
    )

    -- Switch the windows containing the target buffers to a buffer that's not going to be closed.
    -- Create a new buffer if necessary.
    local switch_bufnr
    -- If there are buffers that are not going to be deleted, just switch all target windows to the
    -- most recently used undeleted buffer
    if #undeleted_buffers > 0 then
        local switch_bufnr_lastused = -1

        for _, bufnr in ipairs(undeleted_buffers) do
            local bufinfo = vim.fn.getbufinfo(bufnr)[1]
            if bufinfo.lastused > switch_bufnr_lastused then
                switch_bufnr = bufnr
                switch_bufnr_lastused = bufinfo.lastused
            end
        end
    -- Otherwise create a new buffer and switch all windows to it.
    else
        switch_bufnr = vim.api.nvim_create_buf(true, false)

        if switch_bufnr == 0 then
            vim.api.nvim_err_writeln('bufdelete.nvim: Failed to create buffer')
        end
    end

    -- Switch all target windows to the selected buffer.
    for _, win in ipairs(windows) do
        vim.api.nvim_win_set_buf(win, switch_bufnr)
    end

    -- Close all target buffers one by one.
    for bufnr, _ in pairs(buf_is_deleted) do
        -- Check if buffer is still valid and loaded as it may be deleted due to options like bufhidden=wipe.
        if vim.api.nvim_buf_is_loaded(bufnr) then
            -- Only use force if buffer is modified, is a terminal or if `force` is true.
            local use_force = force
                or vim.bo[bufnr].modified
                or vim.bo[bufnr].buftype == 'terminal'

            -- Trigger BDeletePre autocommand.
            vim.api.nvim_exec_autocmds(
                'User',
                { pattern = 'BDeletePre ' .. tostring(bufnr) }
            )

            if wipeout then
                vim.cmd.bwipeout({ count = bufnr, bang = use_force })
            else
                vim.cmd.bdelete({ count = bufnr, bang = use_force })
            end

            -- Trigger BDeletePost autocommand.
            vim.api.nvim_exec_autocmds(
                'User',
                { pattern = 'BDeletePost ' .. tostring(bufnr) }
            )
        end
    end
    return buf_is_deleted
end

---Find the first buffer whose name matches the provided pattern. Returns buffer handle.
---Errors if buffer is not found.
---@param pat string pattern used to pick buffer by its name
---@return integer bufnr
local function find_buffer_with_pattern(pat)
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if
            vim.api.nvim_buf_is_valid(bufnr)
            -- I have to normalize buffer names since on Windows OS it sometimes has issues with 
            -- back slashes and forward slashes. This fix could have issues if I actually 
            -- have a use case of using a buffer name pattern instead of the relative file path
            -- but I will deal with that only if I actually ever have that use case
            and vim.fs
                .normalize(vim.api.nvim_buf_get_name(bufnr))
                :match(vim.fs.normalize(pat))
            -- and vim.api.nvim_buf_get_name(bufnr):match(pat)
        then
            return bufnr
        end
    end
    error('Buffer not found')
end

---Get buffer handle from buffer name or handle
---@param buffer_or_pat uinteger | string | nil buffer number or buffer name pattern
---@return uinteger?
local function get_buffer_handle(buffer_or_pat)
    local bufnr

    if buffer_or_pat == nil then
        bufnr = 0
    elseif type(buffer_or_pat) == 'number' then
        bufnr = buffer_or_pat
    elseif type(buffer_or_pat) == 'string' then
        bufnr = tonumber(buffer_or_pat)

        if bufnr ~= nil and math.floor(bufnr) == bufnr then
            bufnr = bufnr
        else
            bufnr = find_buffer_with_pattern(buffer_or_pat)
        end
    end

    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    if bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr) then return bufnr end
end

---@param left uinteger
---@param right uinteger
---@return uinteger[]
local function get_target_buffers_from_range(left, right)
    local target_buffers = {}

    for i = left, right do
        if vim.api.nvim_buf_is_valid(i) then
            target_buffers[#target_buffers + 1] = i
        end
    end

    return target_buffers
end

---Get array-like table containing a list of buffer handles from a list of buffer names and handles.
---@param buffers uinteger | string | (string | uinteger)[] the buffer number, the buffer pattern, or an array of buffer numbers and patterns
---@return uinteger[]
local function get_target_buffers(buffers)
    if type(buffers) ~= 'table' then
        local bufnr = get_buffer_handle(buffers)
        if bufnr == nil then return {} end
        return { bufnr }
    end

    local target_buffers = {}

    for _, v in ipairs(buffers) do
        local bufnr = get_buffer_handle(v)
        if bufnr ~= nil then target_buffers[#target_buffers + 1] = bufnr end
    end

    return target_buffers
end

---Kill the target buffer(s) (or the current one if 0/nil) while retaining window layout.
---Can accept a list of buffers numbers or name patterns to kill multiple buffers.
---@param buffers uinteger | string | (string | uinteger)[] the buffer number, the buffer pattern, or an array of buffer numbers and patterns
---@param force boolean?
---@param switchable_buffers uinteger[]?
---@return table<integer, boolean>
function M.bufdelete(buffers, force, switchable_buffers)
    return buf_kill(
        get_target_buffers(buffers),
        switchable_buffers,
        force,
        false
    )
end

---Wipe the target buffer(s) (or the current one if 0/nil) while retaining window layout.
---Can accept a list of buffers numbers or name patterns to wipe multiple buffers.
---@param buffers uinteger | string | (string | uinteger)[] the buffer number, the buffer pattern, or an array of buffer numbers and patterns
---@param force boolean?
---@param switchable_buffers uinteger[]?
---@return table<integer, boolean>
function M.bufwipeout(buffers, force, switchable_buffers)
    return buf_kill(
        get_target_buffers(buffers),
        switchable_buffers,
        force,
        true
    )
end

-- Wrapper around buf_kill for use with vim commands.
function M._buf_kill_cmd(opts, wipeout)
    local target_buffers = get_target_buffers(opts.fargs)

    if #opts.fargs == 0 or opts.range > 0 then
        local range_left = opts.range == 2 and opts.line1 or opts.line2
        local range_right = opts.line2

        local new_targets =
            get_target_buffers_from_range(range_left, range_right)

        for _, v in ipairs(new_targets) do
            target_buffers[#target_buffers + 1] = v
        end
    end

    buf_kill(target_buffers, nil, opts.bang, wipeout)
end

local function is_file_buffer(bufnr)
    return vim.bo[bufnr].buftype == ''
        and vim.fs.normalize(vim.api.nvim_buf_get_name(0)) ~= ''
end

function M.close_inactive_file_buffers()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if
            vim.api.nvim_buf_is_valid(bufnr)
            and not vim.bo[bufnr].modified
            and #vim.fn.win_findbuf(bufnr) == 0
            and is_file_buffer(bufnr)
        then
            M.bufdelete(bufnr)
        end
    end
end

return M
