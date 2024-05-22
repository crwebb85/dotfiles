local M = {}

function M.getBufferViewPath(viewNumber)
    local path = vim.fn.fnamemodify(vim.fn.bufname('%'), ':p')
    if path == nil then error('path to buffer is unexpectedly nil') end
    -- vim's odd =~ escaping for /
    path = vim.fn.substitute(path, '=', '==', 'g') or ''
    if vim.fn.has_key(vim.fn.environ(), 'HOME') then
        path = vim.fn.substitute(path, '^' .. os.getenv('HOME'), '\\~', '')
            or ''
    end
    path = vim.fn.substitute(path, '/', '=+', 'g') or ''
    path = path .. '='
    -- view directory
    path = vim.opt.viewdir:get() .. path
    if type(viewNumber) == 'number' and 0 < viewNumber and viewNumber <= 9 then
        path = path .. viewNumber .. '.vim'
    end
    return path
end

local TREESITTER_FOLDING_VIEW_FILE_NUMBER = 1
local DIFF_FOLDING_VIEW_FILE_NUMBER = 2
local OTHER_FOLDING_VIEW_FILE_NUMBER = 3

function M.getBufferViewFileNumber()
    if
        vim.api.nvim_get_option_value('foldmethod', {}) == 'expr'
        and vim.api.nvim_get_option_value('foldexpr', {})
            == 'v:lua.vim.treesitter.foldexpr()'
    then
        return TREESITTER_FOLDING_VIEW_FILE_NUMBER
    elseif vim.api.nvim_get_option_value('foldmethod', {}) == 'expr' then
        return OTHER_FOLDING_VIEW_FILE_NUMBER -- In case, I manually set the folding expr to something else
    elseif vim.api.nvim_get_option_value('diff', {}) then
        return DIFF_FOLDING_VIEW_FILE_NUMBER
    else
        return OTHER_FOLDING_VIEW_FILE_NUMBER
    end
end

-- If my folds get screwed up the following function can be used to delete
-- the view file. I think this should fix my folds but need to test it
function M.deleteView(viewNumber)
    local path = M.getBufferViewPath(viewNumber)
    vim.fn.delete(path)
    vim.notify('Deleted: ' .. path)
end

function M.openView(viewNumber)
    local path = M.getBufferViewPath(viewNumber)
    vim.cmd('e ' .. path)
end

function M.printViewPath(viewNumber)
    local path = M.getBufferViewPath(viewNumber)
    vim.notify(path)
end

function M.resetView(viewNumber)
    vim.cmd([[
        augroup remember_folds
           autocmd!
        augroup END
    ]])
    M.deleteView(viewNumber)
    print('Close and reopen nvim for to finish reseting the view file')
end

---saves the view
---@param viewNumber any
function M.saveView(viewNumber)
    -- view files are about 500 bytes
    if viewNumber == nil then viewNumber = M.getBufferViewFileNumber() end
    vim.cmd('silent! mkview!' .. viewNumber)
end

---loads the view
---@param viewNumber? integer
function M.loadView(viewNumber)
    if viewNumber == nil then viewNumber = M.getBufferViewFileNumber() end
    vim.cmd('silent! loadview ' .. viewNumber)
end

-------------------------------------------------------------------------------
--- Autocmds

local fold_excluded_filetypes = {
    gitcommit = true,
    oil = true,
}

local remember_folds_group = 'remember_folds'
vim.api.nvim_create_augroup(remember_folds_group, { clear = true })

-- Save fold informatin in view file
vim.api.nvim_create_autocmd(
    -- bufleave but not bufwinleave captures closing 2nd tab
    -- BufHidden for compatibility with `set hidden`
    { 'BufWinLeave', 'BufLeave', 'BufWritePost', 'BufHidden', 'QuitPre' },
    {
        desc = 'Saves view file (saves information like open/closed folds)',
        group = remember_folds_group,
        pattern = '?*',
        -- nested is needed by bufwrite* (if triggered via other autocmd)
        nested = true,
        callback = function(args)
            if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
                return
            end

            local buftype =
                vim.api.nvim_get_option_value('buftype', { buf = args.buf })
            local filetype =
                vim.api.nvim_get_option_value('filetype', { buf = args.buf })

            if buftype ~= '' or fold_excluded_filetypes[filetype] ~= nil then
                return
            end

            local viewNumber = M.getBufferViewFileNumber()
            --I can't use vim.schedule here because it results in a race condition where it uses
            --saves it for the next buffer I navigate to
            M.saveView(viewNumber)
        end,
    }
)

-- Apply folds to folder based on view file
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufWritePost' }, {
    desc = 'Loads the view file for the buffer (reloads open/closed folds)',
    group = remember_folds_group,
    pattern = '?*',
    callback = function(args)
        -- vim.print(args)
        -- vim.print(vim.api.nvim_get_option_value('buftype', { buf = args.buf }))

        local buftype =
            vim.api.nvim_get_option_value('buftype', { buf = args.buf })
        local filetype =
            vim.api.nvim_get_option_value('filetype', { buf = args.buf })

        if buftype ~= '' or fold_excluded_filetypes[filetype] ~= nil then
            return
        end

        if
            not vim.api.nvim_get_option_value('diff', {})
            and vim.api.nvim_get_option_value('foldmethod', {}) == 'diff'
            and vim.api.nvim_get_option_value('foldexpr', {})
                == 'v:lua.vim.treesitter.foldexpr()'
        then
            -- Reset Folding back to using tresitter after no longer using diff mode
            vim.api.nvim_set_option_value('foldmethod', 'expr', {})
            vim.api.nvim_set_option_value(
                'foldexpr',
                'v:lua.vim.treesitter.foldexpr()',
                {}
            )
        end
        if vim.fn.reg_executing() ~= '' or vim.fn.reg_recording() ~= '' then
            --Open folds when entering a file while recording or executing a macro
            vim.cmd([[silent! :%foldopen!]])
        else
            --Shedule loading the view so that it doesn't block opening the buffer
            --This does result in some flicker on the first open of a buffer but Im
            --okay with that
            vim.schedule(function()
                local viewNumber = M.getBufferViewFileNumber()
                M.loadView(viewNumber)
            end)
        end
    end,
})

-------------------------------------------------------------------------------
--- User commands

vim.api.nvim_create_user_command(
    'ViewOpen',
    function(opts) M.openView(tonumber(opts.args)) end,
    { nargs = '?' }
)
vim.api.nvim_create_user_command(
    'ViewPrintPath',
    function(opts) M.printViewPath(tonumber(opts.args)) end,
    { nargs = '?' }
)
vim.api.nvim_create_user_command(
    'ViewReset',
    function(opts) M.resetView(tonumber(opts.args)) end,
    { nargs = '?' }
)
vim.api.nvim_create_user_command(
    'ViewDelete',
    function(opts) M.deleteView(tonumber(opts.args)) end,
    { nargs = '?' }
)

return M
