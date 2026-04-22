-- based on https://github.com/nvim-lua/plenary.nvim/blob/74b06c6c75e4eeb3108ec01852001636d85a932b/lua/plenary/window/float.lua
--- changes primarily involved fixing lsp warnings and depreciations
--- removed code related to borders
--- removed unused functions
local function apply_defaults(original, defaults)
    if original == nil then original = {} end

    original = vim.deepcopy(original)

    for k, v in pairs(defaults) do
        if original[k] == nil then original[k] = v end
    end

    return original
end

_AssociatedBufs = {}

local win_float = {}

win_float.default_options = {
    winblend = 15,
    percentage = 0.9,
}
function win_float.default_opts(options)
    options = apply_defaults(options, win_float.default_options)

    local width = math.floor(vim.o.columns * options.percentage)
    local height = math.floor(vim.o.lines * options.percentage)

    local top = math.floor(((vim.o.lines - height) / 2) - 1)
    local left = math.floor((vim.o.columns - width) / 2)

    local opts = {
        relative = 'editor',
        row = top,
        col = left,
        width = width,
        height = height,
        style = 'minimal',
    }

    return opts
end

--- Create window that takes up certain percentags of the current screen.
---
--- Works regardless of current buffers, tabs, splits, etc.
--@param col_range number | Table:
--                  If number, then center the window taking up this percentage of the screen.
--                  If table, first index should be start, second_index should be end
--@param row_range number | Table:
--                  If number, then center the window taking up this percentage of the screen.
--                  If table, first index should be start, second_index should be end
--@param win_opts Table
function win_float.percentage_range_window(col_range, row_range, win_opts)
    win_opts = apply_defaults(win_opts, win_float.default_options)

    local default_win_opts = win_float.default_opts(win_opts)
    default_win_opts.relative = 'editor'

    local height_percentage, row_start_percentage
    if type(row_range) == 'number' then
        assert(row_range <= 1)
        assert(row_range > 0)
        height_percentage = row_range
        row_start_percentage = (1 - height_percentage) / 2
    elseif type(row_range) == 'table' then
        height_percentage = row_range[2] - row_range[1]
        row_start_percentage = row_range[1]
    else
        error(string.format("Invalid type for 'row_range': %p", row_range))
    end

    default_win_opts.height = math.ceil(vim.o.lines * height_percentage)
    default_win_opts.row = math.ceil(vim.o.lines * row_start_percentage)

    local width_percentage, col_start_percentage
    if type(col_range) == 'number' then
        assert(col_range <= 1)
        assert(col_range > 0)
        width_percentage = col_range
        col_start_percentage = (1 - width_percentage) / 2
    elseif type(col_range) == 'table' then
        width_percentage = col_range[2] - col_range[1]
        col_start_percentage = col_range[1]
    else
        error(string.format("Invalid type for 'col_range': %p", col_range))
    end

    default_win_opts.col = math.floor(vim.o.columns * col_start_percentage)
    default_win_opts.width = math.floor(vim.o.columns * width_percentage)

    local bufnr = win_opts.bufnr or vim.api.nvim_create_buf(false, true)
    local win_id = vim.api.nvim_open_win(bufnr, true, default_win_opts)
    vim.api.nvim_win_set_buf(win_id, bufnr)

    vim.cmd('setlocal nocursorcolumn')
    vim.wo[win_id].winblend = win_opts.winblend

    _AssociatedBufs[bufnr] = {
        win_id,
    }

    vim.api.nvim_create_autocmd({ 'WinLeave', 'BufLeave', 'BufDelete' }, {
        buffer = bufnr,
        callback = function(event) win_float.clear(event.buf) end,
        nested = true,
        once = true,
    })

    return {
        bufnr = bufnr,
        win_id = win_id,
    }
end

function win_float.clear(bufnr)
    if _AssociatedBufs[bufnr] == nil then return end

    for _, win_id in ipairs(_AssociatedBufs[bufnr]) do
        if vim.api.nvim_win_is_valid(win_id) then
            vim.api.nvim_win_close(win_id, true)
        end
    end

    _AssociatedBufs[bufnr] = nil
end

return win_float
