local config = require('config.config')

local state = {
    is_folding_enable = true,
}
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
    path = vim.go.viewdir .. path
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

function M.setup_folding(is_folding_enable)
    state.is_folding_enable = is_folding_enable

    local remember_folds_group_name = 'remember_folds'
    local remember_folds_group =
        vim.api.nvim_create_augroup(remember_folds_group_name, { clear = true })
    if state.is_folding_enable then
        -- Apply folds to folder based on view file
        -- (Note) I think BufWritePost and the nested autocmd was causing performance issues.
        -- I am going to try without it
        vim.api.nvim_create_autocmd({
            'BufWinEnter',
            -- 'BufWritePost'
        }, {
            desc = 'Loads the view file for the buffer (reloads open/closed folds)',
            group = remember_folds_group,
            pattern = '?*',
            callback = function(args)
                -- vim.print(args)
                -- vim.print(vim.api.nvim_get_option_value('buftype', { buf = args.buf }))

                if
                    vim.b[args.buf].is_big_file == true
                    or vim.bo[args.buf].buftype ~= ''
                    or fold_excluded_filetypes[vim.bo[args.buf].filetype]
                        ~= nil
                then
                    return
                end

                --TODO may want to break the fold method reseting into a seperate the below into its own autocmd for
                if
                    not vim.wo.diff
                    and vim.wo.foldmethod == 'diff'
                    and vim.wo.foldexpr == 'v:lua.vim.treesitter.foldexpr()'
                then
                    -- Reset Folding back to using tresitter after no longer using diff mode
                    vim.wo.foldmethod = 'expr'
                    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                end

                if
                    vim.fn.reg_executing() ~= ''
                    or vim.fn.reg_recording() ~= ''
                then
                    --Open folds when entering a file while recording or executing a macro
                    vim.cmd([[silent! :%foldopen!]])
                else
                    local viewNumber = M.getBufferViewFileNumber()
                    --unfortunately scheduling loading the view with vim.schedule
                    --did not work well and resulted in moving my cursor to undesired
                    --locations when switching buffers
                    M.loadView(viewNumber)
                end
            end,
        })
        -- Save fold informatin in view file
        -- (Note) I think BufWritePost and the nested autocmd was causing performance issues.
        -- I am going to try without it
        vim.api.nvim_create_autocmd(
            -- bufleave but not bufwinleave captures closing 2nd tab
            -- BufHidden for compatibility with `set hidden`
            {
                'BufWinLeave',
                'BufLeave',
                -- 'BufWritePost',
                'BufHidden',
                'QuitPre',
            },
            {
                desc = 'Saves view file (saves information like open/closed folds)',
                group = remember_folds_group,
                pattern = '?*',
                -- nested is needed by bufwrite* (if triggered via other autocmd)
                -- nested = true,
                callback = function(args)
                    if
                        vim.fn.reg_executing() ~= ''
                        or vim.fn.reg_recording() ~= ''
                    then
                        return
                    end

                    if
                        vim.b[args.buf].is_big_file == true
                        or vim.bo[args.buf].buftype ~= ''
                        or fold_excluded_filetypes[vim.bo[args.buf].filetype]
                            ~= nil
                    then
                        return
                    end

                    local viewNumber = M.getBufferViewFileNumber()
                    --I can't use vim.schedule here because it results in a race condition where it uses
                    --saves it for the next buffer I navigate to
                    M.saveView(viewNumber)
                end,
            }
        )
    else
        vim.opt.foldenable = false
    end
end
-------------------------------------------------------------------------------
--- User commands

vim.api.nvim_create_user_command(
    'ViewOpen',
    function(opts) M.openView(tonumber(opts.args)) end,
    { nargs = '?', desc = 'Opens the view file for the buffer.' }
)
vim.api.nvim_create_user_command(
    'ViewPrintPath',
    function(opts) M.printViewPath(tonumber(opts.args)) end,
    { nargs = '?', desc = 'Prints the path to the view file' }
)
vim.api.nvim_create_user_command(
    'ViewReset',
    function(opts) M.resetView(tonumber(opts.args)) end,
    { nargs = '?', desc = 'Resets the view file' }
)
vim.api.nvim_create_user_command(
    'ViewDelete',
    function(opts) M.deleteView(tonumber(opts.args)) end,
    { nargs = '?', desc = 'Deletes the view file for the buffer' }
)
vim.api.nvim_create_user_command(
    'ViewToggle',
    function(_) M.setup_folding(not state.is_folding_enable) end,
    {
        desc = 'Toggles on and off the autocmds that save and load the view files',
    }
)

-------------------------------------------------------------------------------
--- Setup folding
M.setup_folding(config.foldenable)

return M
